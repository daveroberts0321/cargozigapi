const std = @import("std");
const utils = @import("utils");
const models = @import("models");
const Point = utils.Point;
const Cargo = models.Cargo;
const SegmentedRoute = models.SegmentedRoute;

pub const RouteHandler = struct {
    pub const MAX_ALLOWED_DEVIATION: f64 = 200; // km

    pub fn qualifyCargoForRoute(cargo: *const Cargo, route: *const SegmentedRoute) utils.RouteQualification {
        var min_pickup_deviation = std.math.inf(f64);
        var min_dropoff_deviation = std.math.inf(f64);

        for (route.segments) |segment| {
            const pickup_dev = utils.pointToSegmentDistance(cargo.pickup, segment.start, segment.end);
            const dropoff_dev = utils.pointToSegmentDistance(cargo.dropoff, segment.start, segment.end);

            min_pickup_deviation = @min(min_pickup_deviation, pickup_dev);
            min_dropoff_deviation = @min(min_dropoff_deviation, dropoff_dev);
        }

        const max_deviation = @max(min_pickup_deviation, min_dropoff_deviation);
        const total_distance = utils.haversineDistance(cargo.pickup, cargo.dropoff);

        return utils.RouteQualification{
            .max_deviation = max_deviation,
            .total_distance = total_distance,
            .pickup_deviation = min_pickup_deviation,
            .dropoff_deviation = min_dropoff_deviation,
            .is_qualified = max_deviation <= MAX_ALLOWED_DEVIATION,
        };
    }
};
