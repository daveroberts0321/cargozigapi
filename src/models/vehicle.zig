const std = @import("std");

pub const VehicleType = enum {
    DryVan,
    Reefer,
    Flatbed,
};

pub const VehicleConstraints = struct {
    max_weight_kg: f64,
    max_volume_m3: f64,
    vehicle_type: VehicleType,
};

pub const VehicleStatus = struct {
    current_weight_kg: f64 = 0,
    current_volume_m3: f64 = 0,
    constraints: VehicleConstraints,

    pub fn hasCapacityFor(self: *const VehicleStatus, cargo: anytype) bool {
        return (self.current_weight_kg + cargo.weight_kg <= self.constraints.max_weight_kg) and
            (self.current_volume_m3 + cargo.volume_m3 <= self.constraints.max_volume_m3);
    }

    pub fn addCargo(self: *VehicleStatus, cargo: anytype) void {
        self.current_weight_kg += cargo.weight_kg;
        self.current_volume_m3 += cargo.volume_m3;
    }

    pub fn removeCargo(self: *VehicleStatus, cargo: anytype) void {
        self.current_weight_kg -= cargo.weight_kg;
        self.current_volume_m3 -= cargo.volume_m3;
    }
};
