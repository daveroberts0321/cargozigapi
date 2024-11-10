const std = @import("std");
const utils = @import("utils");
const models = @import("models");
const handlers = @import("handlers");
const Point = utils.Point;
const SegmentedRoute = models.SegmentedRoute;
const Cargo = models.Cargo;
const RouteHandler = handlers.RouteHandler;
const RouteOptimizer = handlers.RouteOptimizer;
const VehicleConstraints = models.VehicleConstraints;
const VehicleType = models.VehicleType;
const TimeWindow = models.TimeWindow;
const TravelParameters = models.TravelParameters;
const OptimizedStop = handlers.OptimizedStop;
const ScheduleDate = models.ScheduleDate;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Create waypoints for main route
    const memphis = try Point.init(allocator, "Memphis", 35.1495, -90.0490);
    defer memphis.deinit();
    const nashville = try Point.init(allocator, "Nashville", 36.1627, -86.7816);
    defer nashville.deinit();
    const chattanooga = try Point.init(allocator, "Chattanooga", 35.0456, -85.3097);
    defer chattanooga.deinit();
    const atlanta = try Point.init(allocator, "Atlanta", 33.7490, -84.3880);
    defer atlanta.deinit();

    // Create schedule for tomorrow
    const schedule_date = ScheduleDate{
        .year = 2024,
        .month = 11,
        .day = 11, // Tomorrow
        .time = .{ .hour = 8, .minute = 0 }, // Start at 8 AM
    };

    // Create main route
    const waypoints = [_]*const Point{ memphis, nashville, chattanooga, atlanta };
    var route = try SegmentedRoute.init(allocator, &waypoints);
    defer route.deinit();

    // Print route information
    std.debug.print("\nMain Route from {s} to {s}:\n", .{
        waypoints[0].name,
        waypoints[waypoints.len - 1].name,
    });
    std.debug.print("Total distance: {d:.2} km\n\n", .{route.total_distance});

    // Create some example cargo loads with time windows
    var cargo1 = try Cargo.init(allocator, .{
        .name = "Automotive Parts",
        .pickup = try Point.init(allocator, "Birmingham", 33.5186, -86.8104),
        .dropoff = try Point.init(allocator, "Chattanooga", 35.0456, -85.3097),
        .weight_kg = 2500,
        .volume_m3 = 12,
        .pickup_window = TimeWindow.fromTimeOfDay(
            schedule_date,
            .{ .hour = 9, .minute = 0 }, // 9 AM
            .{ .hour = 11, .minute = 0 }, // 11 AM
        ),
        .delivery_window = TimeWindow.fromTimeOfDay(
            schedule_date,
            .{ .hour = 13, .minute = 0 }, // 1 PM
            .{ .hour = 16, .minute = 0 }, // 4 PM
        ),
    });
    defer cargo1.deinit();

    var cargo2 = try Cargo.init(allocator, .{
        .name = "Electronics",
        .pickup = try Point.init(allocator, "Huntsville", 34.7304, -86.5861),
        .dropoff = try Point.init(allocator, "Augusta", 33.4735, -82.0105),
        .weight_kg = 1500,
        .volume_m3 = 8,
        .pickup_window = TimeWindow.fromTimeOfDay(
            schedule_date,
            .{ .hour = 10, .minute = 0 }, // 10 AM
            .{ .hour = 12, .minute = 0 }, // 12 PM
        ),
        .delivery_window = TimeWindow.fromTimeOfDay(
            schedule_date,
            .{ .hour = 14, .minute = 0 }, // 2 PM
            .{ .hour = 18, .minute = 0 }, // 6 PM
        ),
    });
    defer cargo2.deinit();

    // Print cargo information and qualification status
    std.debug.print("Available Cargo:\n", .{});
    try printCargoInfo(cargo1, &route);
    try printCargoInfo(cargo2, &route);

    // Create qualified cargo list
    var qualified_cargo = std.ArrayList(*const Cargo).init(allocator);
    defer qualified_cargo.deinit();

    // Add qualified cargo
    if (RouteHandler.qualifyCargoForRoute(cargo1, &route).is_qualified) {
        try qualified_cargo.append(cargo1);
    }
    if (RouteHandler.qualifyCargoForRoute(cargo2, &route).is_qualified) {
        try qualified_cargo.append(cargo2);
    }

    // Define vehicle constraints
    const vehicle_constraints = VehicleConstraints{
        .max_weight_kg = 4000,
        .max_volume_m3 = 40,
        .vehicle_type = .DryVan,
    };

    const travel_params = TravelParameters{
        .start_time = schedule_date.toTimestamp(),
        .schedule_date = schedule_date,
        .average_speed_kmh = 80.0,
        .service_time_mins = 30.0,
        .break_time_mins = 45.0,
        .max_driving_hours = 11.0,
    };

    // Optimize route
    var optimized = try RouteOptimizer.optimizeRoute(
        allocator,
        &route,
        qualified_cargo.items,
        vehicle_constraints,
        travel_params,
    );
    defer optimized.deinit();

    // Print optimized route
    std.debug.print("\nOptimized Route:\n", .{});
    std.debug.print("Total distance: {d:.2} km\n", .{optimized.total_distance});
    for (optimized.stops, 0..) |stop, i| {
        std.debug.print("{d}. {s}: {s} ({s})\n", .{
            i + 1,
            if (stop.is_pickup) "Pickup" else "Dropoff",
            stop.point.name,
            stop.cargo.name,
        });
        std.debug.print("   Distance from previous: {d:.2} km\n", .{stop.distance_from_prev});
        std.debug.print("   Current load: {d:.2} kg / {d:.2} m³\n", .{
            stop.current_weight,
            stop.current_volume,
        });
        try printStopTime(stop);
    }
}

fn printCargoInfo(cargo: *const Cargo, route: *const SegmentedRoute) !void {
    const qualification = RouteHandler.qualifyCargoForRoute(cargo, route);

    std.debug.print("\nCargo: {s}\n", .{cargo.name});
    std.debug.print("  Pickup: {s} ({d:.4}, {d:.4})\n", .{
        cargo.pickup.name,
        cargo.pickup.lat,
        cargo.pickup.lon,
    });
    std.debug.print("  Dropoff: {s} ({d:.4}, {d:.4})\n", .{
        cargo.dropoff.name,
        cargo.dropoff.lat,
        cargo.dropoff.lon,
    });
    std.debug.print("  Distance: {d:.2} km\n", .{cargo.calculateDistance()});
    std.debug.print("  Weight: {d:.2} kg\n", .{cargo.weight_kg});
    std.debug.print("  Volume: {d:.2} m³\n", .{cargo.volume_m3});

    // Print scheduled time windows
    var buf: [64]u8 = undefined;

    const pickup_start = try TimeWindow.formatTime(cargo.pickup_window.earliest, &buf);
    std.debug.print("  Pickup Window: {s}", .{pickup_start});

    const pickup_end = try TimeWindow.formatTime(cargo.pickup_window.latest, &buf);
    std.debug.print(" - {s}\n", .{pickup_end});

    const delivery_start = try TimeWindow.formatTime(cargo.delivery_window.earliest, &buf);
    std.debug.print("  Delivery Window: {s}", .{delivery_start});

    const delivery_end = try TimeWindow.formatTime(cargo.delivery_window.latest, &buf);
    std.debug.print(" - {s}\n", .{delivery_end});

    std.debug.print("  Qualification:\n", .{});
    std.debug.print("    Max Deviation: {d:.2} km\n", .{qualification.max_deviation});
    std.debug.print("    Is Qualified: {}\n", .{qualification.is_qualified});
}

fn printStopTime(stop: OptimizedStop) !void {
    // Create a human-readable format for the timestamps
    const arrival_sec = @divFloor(stop.arrival_time, 60);
    var arrival_min = @divFloor(arrival_sec, 60);
    const arrival_hour = @divFloor(arrival_min, 60);
    arrival_min = @mod(arrival_min, 60);

    const departure_sec = @divFloor(stop.departure_time, 60);
    var departure_min = @divFloor(departure_sec, 60);
    const departure_hour = @divFloor(departure_min, 60);
    departure_min = @mod(departure_min, 60);

    std.debug.print("   Arrival: {d:0>2}:{d:0>2}\n", .{
        @mod(arrival_hour, 24),
        arrival_min,
    });
    std.debug.print("   Departure: {d:0>2}:{d:0>2}\n", .{
        @mod(departure_hour, 24),
        departure_min,
    });
}
