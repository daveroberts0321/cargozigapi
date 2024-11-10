const std = @import("std");
const utils = @import("utils");
const Point = utils.Point;
const TimeWindow = @import("time_window.zig").TimeWindow;

pub const CargoError = error{
    InvalidCoordinates,
    InvalidDistance,
    TimeWindowViolation,
};

pub const Cargo = struct {
    name: []const u8,
    pickup: *Point,
    dropoff: *Point,
    allocator: std.mem.Allocator,
    weight_kg: f64,
    volume_m3: f64,
    pickup_window: TimeWindow,
    delivery_window: TimeWindow,

    pub fn init(allocator: std.mem.Allocator, options: struct {
        name: []const u8,
        pickup: *Point,
        dropoff: *Point,
        weight_kg: f64 = 0,
        volume_m3: f64 = 0,
        pickup_window: TimeWindow,
        delivery_window: TimeWindow,
    }) !*Cargo {
        const cargo = try allocator.create(Cargo);
        cargo.* = .{
            .name = try allocator.dupe(u8, options.name),
            .pickup = options.pickup,
            .dropoff = options.dropoff,
            .allocator = allocator,
            .weight_kg = options.weight_kg,
            .volume_m3 = options.volume_m3,
            .pickup_window = options.pickup_window,
            .delivery_window = options.delivery_window,
        };
        return cargo;
    }

    pub fn deinit(self: *Cargo) void {
        self.allocator.free(self.name);
        self.pickup.deinit();
        self.dropoff.deinit();
        self.allocator.destroy(self);
    }

    pub fn calculateDistance(self: *const Cargo) f64 {
        return utils.haversineDistance(self.pickup, self.dropoff);
    }
};
