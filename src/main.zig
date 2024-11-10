const std = @import("std");
const Point = @import("models").Point;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const memphis = try Point.init(allocator, "Memphis", 35.1495, -90.0490);
    defer memphis.deinit();

    std.debug.print("Created point: {s} at ({d}, {d})\n", .{
        memphis.name,
        memphis.lat,
        memphis.lon,
    });
}
