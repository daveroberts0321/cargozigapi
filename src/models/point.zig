const std = @import("std");

pub const Point = struct {
    name: []const u8,
    lat: f64,
    lon: f64,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, name: []const u8, lat: f64, lon: f64) !*Point {
        const point = try allocator.create(Point);
        point.* = .{
            .name = try allocator.dupe(u8, name),
            .lat = lat,
            .lon = lon,
            .allocator = allocator,
        };
        return point;
    }

    pub fn deinit(self: *Point) void {
        self.allocator.free(self.name);
        self.allocator.destroy(self);
    }
};
