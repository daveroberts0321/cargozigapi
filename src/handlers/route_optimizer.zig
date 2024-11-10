const std = @import("std");
const utils = @import("utils");
const models = @import("models");
const Point = utils.Point;
const Cargo = models.Cargo;
const SegmentedRoute = models.SegmentedRoute;
const VehicleStatus = models.VehicleStatus;
const TravelParameters = models.TravelParameters;
const TimeWindow = models.TimeWindow;

pub const OptimizedStop = struct {
    point: *const Point,
    is_pickup: bool,
    cargo: *const Cargo,
    distance_from_prev: f64,
    current_weight: f64,
    current_volume: f64,
    arrival_time: i64,
    departure_time: i64,
};

pub const OptimizedRoute = struct {
    stops: []OptimizedStop,
    total_distance: f64,
    total_time: i64,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) OptimizedRoute {
        return .{
            .stops = &[_]OptimizedStop{},
            .total_distance = 0,
            .total_time = 0,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *const OptimizedRoute) void {
        self.allocator.free(self.stops);
    }
};

pub const RouteOptimizer = struct {
    const CargoStop = struct {
        point: *const Point,
        is_pickup: bool,
        cargo: *const Cargo,
        added: bool = false,
    };

    const StopFeasibility = struct {
        is_feasible: bool,
        arrival_time: i64,
        departure_time: i64,
        distance: f64,
    };

    pub fn optimizeRoute(
        allocator: std.mem.Allocator,
        main_route: *const SegmentedRoute,
        cargos: []const *const Cargo,
        vehicle_constraints: models.VehicleConstraints,
        travel_params: TravelParameters,
    ) !OptimizedRoute {
        // Create all possible stops
        var all_stops = std.ArrayList(CargoStop).init(allocator);
        defer all_stops.deinit();

        // Add pickup and delivery points for each cargo
        for (cargos) |cargo| {
            try all_stops.append(.{
                .point = cargo.pickup,
                .is_pickup = true,
                .cargo = cargo,
            });
            try all_stops.append(.{
                .point = cargo.dropoff,
                .is_pickup = false,
                .cargo = cargo,
            });
        }

        var result = std.ArrayList(OptimizedStop).init(allocator);
        defer result.deinit();

        const start_point = main_route.segments[0].start;
        var current_point = start_point;
        var current_time = travel_params.start_time;
        var total_distance: f64 = 0;
        var vehicle_status = VehicleStatus{
            .constraints = vehicle_constraints,
        };

        // Main optimization loop
        while (true) {
            var best_stop: ?StopFeasibility = null;
            var best_index: ?usize = null;

            // Evaluate each potential next stop
            for (all_stops.items, 0..) |stop, i| {
                if (stop.added) continue;

                const feasibility = checkStopFeasibility(
                    stop,
                    current_point,
                    current_time,
                    &vehicle_status,
                    travel_params,
                );

                if (!feasibility.is_feasible) continue;

                if (best_stop == null or feasibility.distance < best_stop.?.distance) {
                    best_stop = feasibility;
                    best_index = i;
                }
            }

            // No more feasible stops found
            if (best_index == null) break;

            const chosen_stop = all_stops.items[best_index.?];
            const feasibility = best_stop.?;

            // Update vehicle status
            if (chosen_stop.is_pickup) {
                vehicle_status.addCargo(chosen_stop.cargo.*);
            } else {
                vehicle_status.removeCargo(chosen_stop.cargo.*);
            }

            // Add stop to result
            try result.append(.{
                .point = chosen_stop.point,
                .is_pickup = chosen_stop.is_pickup,
                .cargo = chosen_stop.cargo,
                .distance_from_prev = feasibility.distance,
                .current_weight = vehicle_status.current_weight_kg,
                .current_volume = vehicle_status.current_volume_m3,
                .arrival_time = feasibility.arrival_time,
                .departure_time = feasibility.departure_time,
            });

            // Update current state
            all_stops.items[best_index.?].added = true;
            current_point = chosen_stop.point;
            current_time = feasibility.departure_time;
            total_distance += feasibility.distance;
        }

        // Add final leg to endpoint
        const final_point = main_route.segments[main_route.segments.len - 1].end;
        const final_distance = utils.haversineDistance(current_point, final_point);
        const final_arrival = travel_params.calculateArrivalTime(final_distance, current_time);
        total_distance += final_distance;

        return OptimizedRoute{
            .stops = try result.toOwnedSlice(),
            .total_distance = total_distance,
            .total_time = final_arrival - travel_params.start_time,
            .allocator = allocator,
        };
    }

    fn checkStopFeasibility(
        stop: CargoStop,
        current_point: *const Point,
        current_time: i64,
        vehicle_status: *const VehicleStatus,
        travel_params: TravelParameters,
    ) StopFeasibility {
        // These values are used once for calculation only, should be const
        const distance = utils.haversineDistance(current_point, stop.point);
        const arrival_time = travel_params.calculateArrivalTime(distance, current_time);
        const departure_time = arrival_time + @as(i64, @intFromFloat(travel_params.service_time_mins * 60));

        // Check capacity constraints for pickups
        if (stop.is_pickup) {
            if (!vehicle_status.hasCapacityFor(stop.cargo.*)) {
                return .{
                    .is_feasible = false,
                    .arrival_time = arrival_time,
                    .departure_time = departure_time,
                    .distance = distance,
                };
            }
            // Check pickup time window
            if (!stop.cargo.pickup_window.isWithinWindow(arrival_time)) {
                return .{
                    .is_feasible = false,
                    .arrival_time = arrival_time,
                    .departure_time = departure_time,
                    .distance = distance,
                };
            }
        } else {
            // Check delivery time window
            if (!stop.cargo.delivery_window.isWithinWindow(arrival_time)) {
                return .{
                    .is_feasible = false,
                    .arrival_time = arrival_time,
                    .departure_time = departure_time,
                    .distance = distance,
                };
            }
        }

        return .{
            .is_feasible = true,
            .arrival_time = arrival_time,
            .departure_time = departure_time,
            .distance = distance,
        };
    }
};
