const std = @import("std");
const utils = @import("utils");
const Point = utils.Point;

pub const Segment = struct {
    start: *const Point,
    end: *const Point,

    pub fn init(start: *const Point, end: *const Point) Segment {
        return .{ .start = start, .end = end };
    }
};

pub const SegmentedRoute = struct {
    segments: []Segment,
    total_distance: f64,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, waypoints: []const *const Point) !SegmentedRoute {
        if (waypoints.len < 2) {
            return error.InsufficientWaypoints;
        }

        var segments = try allocator.alloc(Segment, waypoints.len - 1);
        var total_distance: f64 = 0;

        for (waypoints[0 .. waypoints.len - 1], 0..) |waypoint, i| {
            segments[i] = Segment.init(waypoint, waypoints[i + 1]);
            total_distance += utils.haversineDistance(waypoint, waypoints[i + 1]);
        }

        return .{
            .segments = segments,
            .total_distance = total_distance,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *SegmentedRoute) void {
        self.allocator.free(self.segments);
    }
};
