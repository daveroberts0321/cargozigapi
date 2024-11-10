const std = @import("std");
const utils = @import("utils");
const models = @import("models");
const handlers = @import("handlers");
const Point = utils.Point;
const SegmentedRoute = models.SegmentedRoute;
const Cargo = models.Cargo;
const RouteHandler = handlers.RouteHandler;

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

    // Create some example cargo loads
    var cargo1 = try Cargo.init(allocator, .{
        .name = "Automotive Parts",
        .pickup = try Point.init(allocator, "Birmingham", 33.5186, -86.8104),
        .dropoff = try Point.init(allocator, "Chattanooga", 35.0456, -85.3097),
        .weight_kg = 2500,
        .volume_m3 = 12,
    });
    defer cargo1.deinit();

    var cargo2 = try Cargo.init(allocator, .{
        .name = "Electronics",
        .pickup = try Point.init(allocator, "Huntsville", 34.7304, -86.5861),
        .dropoff = try Point.init(allocator, "Augusta", 33.4735, -82.0105),
        .weight_kg = 1500,
        .volume_m3 = 8,
    });
    defer cargo2.deinit();

    // Print cargo information and qualification status
    std.debug.print("Available Cargo:\n", .{});
    printCargoInfo(cargo1, &route);
    printCargoInfo(cargo2, &route);
}

fn printCargoInfo(cargo: *const Cargo, route: *const SegmentedRoute) void {
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
    std.debug.print("  Qualification:\n", .{});
    std.debug.print("    Max Deviation: {d:.2} km\n", .{qualification.max_deviation});
    std.debug.print("    Is Qualified: {}\n", .{qualification.is_qualified});
}
