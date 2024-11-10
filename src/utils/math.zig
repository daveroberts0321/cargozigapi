const std = @import("std");
const Point = @import("geotypes.zig").Point;

pub const EARTH_RADIUS: f64 = 6371; // km

pub fn toRadians(degrees: f64) f64 {
    return degrees * std.math.pi / 180.0;
}

pub fn sphericalToCartesian(lat: f64, lon: f64) struct { x: f64, y: f64, z: f64 } {
    const x = std.math.cos(lat) * std.math.cos(lon);
    const y = std.math.cos(lat) * std.math.sin(lon);
    const z = std.math.sin(lat);
    return .{ .x = x, .y = y, .z = z };
}

pub fn haversineDistance(p1: *const Point, p2: *const Point) f64 {
    const lat1 = toRadians(p1.lat);
    const lon1 = toRadians(p1.lon);
    const lat2 = toRadians(p2.lat);
    const lon2 = toRadians(p2.lon);

    const dlat = lat2 - lat1;
    const dlon = lon2 - lon1;

    const a = std.math.sin(dlat / 2) * std.math.sin(dlat / 2) +
        std.math.cos(lat1) * std.math.cos(lat2) * std.math.sin(dlon / 2) * std.math.sin(dlon / 2);
    const c = 2 * std.math.atan2(std.math.sqrt(a), std.math.sqrt(1 - a));

    return EARTH_RADIUS * c;
}

pub const RouteQualification = struct {
    max_deviation: f64,
    total_distance: f64,
    pickup_deviation: f64,
    dropoff_deviation: f64,
    is_qualified: bool,
};

pub fn pointToSegmentDistance(p: *const Point, start: *const Point, end: *const Point) f64 {
    const lat = toRadians(p.lat);
    const lon = toRadians(p.lon);
    const lat1 = toRadians(start.lat);
    const lon1 = toRadians(start.lon);
    const lat2 = toRadians(end.lat);
    const lon2 = toRadians(end.lon);

    const cart = sphericalToCartesian(lat, lon);
    const cart1 = sphericalToCartesian(lat1, lon1);
    const cart2 = sphericalToCartesian(lat2, lon2);

    const crossX = (cart2.y - cart1.y) * (cart.z - cart1.z) - (cart2.z - cart1.z) * (cart.y - cart1.y);
    const crossY = (cart2.z - cart1.z) * (cart.x - cart1.x) - (cart2.x - cart1.x) * (cart.z - cart1.z);
    const crossZ = (cart2.x - cart1.x) * (cart.y - cart1.y) - (cart2.y - cart1.y) * (cart.x - cart1.x);

    const crossMag = std.math.sqrt(crossX * crossX + crossY * crossY + crossZ * crossZ);
    const lineMag = std.math.sqrt((cart2.x - cart1.x) * (cart2.x - cart1.x) +
        (cart2.y - cart1.y) * (cart2.y - cart1.y) +
        (cart2.z - cart1.z) * (cart2.z - cart1.z));

    const distance = std.math.atan2(crossMag, lineMag);
    return distance * EARTH_RADIUS;
}
