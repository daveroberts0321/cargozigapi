const std = @import("std");

pub const TimeOfDay = struct {
    hour: u8,
    minute: u8,

    pub fn fromTimestamp(timestamp: i64) TimeOfDay {
        const minutes = @divFloor(timestamp, 60);
        const hours = @divFloor(minutes, 60);
        return .{
            .hour = @intCast(@mod(hours, 24)),
            .minute = @intCast(@mod(minutes, 60)),
        };
    }

    pub fn toMinutes(self: TimeOfDay) u32 {
        return self.hour * 60 + self.minute;
    }
};

pub const ScheduleDate = struct {
    year: u16,
    month: u8,
    day: u8,
    time: TimeOfDay,

    pub fn toTimestamp(self: ScheduleDate) i64 {
        // Simple conversion - not handling all edge cases for brevity
        const days_since_epoch = (@as(i64, self.year) - 1970) * 365 +
            @as(i64, self.month - 1) * 30 +
            @as(i64, self.day - 1);

        const seconds = days_since_epoch * 86400 +
            @as(i64, self.time.hour) * 3600 +
            @as(i64, self.time.minute) * 60;

        return seconds;
    }
};

pub const TimeWindow = struct {
    earliest: i64,
    latest: i64,

    pub fn fromSchedule(start: ScheduleDate, end: ScheduleDate) TimeWindow {
        return .{
            .earliest = start.toTimestamp(),
            .latest = end.toTimestamp(),
        };
    }

    pub fn fromTimeOfDay(date: ScheduleDate, start_time: TimeOfDay, end_time: TimeOfDay) TimeWindow {
        var start_date = date;
        var end_date = date;
        start_date.time = start_time;
        end_date.time = end_time;

        return TimeWindow.fromSchedule(start_date, end_date);
    }

    pub fn isWithinWindow(self: TimeWindow, timestamp: i64) bool {
        return timestamp >= self.earliest and timestamp <= self.latest;
    }

    pub fn formatTime(timestamp: i64, buffer: []u8) ![]const u8 {
        const time = TimeOfDay.fromTimestamp(timestamp);
        return std.fmt.bufPrint(buffer, "{d:0>2}:{d:0>2}", .{
            time.hour,
            time.minute,
        });
    }
};

pub const TravelParameters = struct {
    average_speed_kmh: f64 = 80.0,
    service_time_mins: f64 = 30.0,
    break_time_mins: f64 = 45.0,
    max_driving_hours: f64 = 11.0,
    start_time: i64,
    schedule_date: ScheduleDate,

    pub fn calculateArrivalTime(self: TravelParameters, distance_km: f64, departure_time: i64) i64 {
        const travel_hours = distance_km / self.average_speed_kmh;
        const travel_seconds: i64 = @intFromFloat(travel_hours * 3600.0);

        // Add mandatory breaks if needed
        const breaks_needed = @floor(travel_hours / self.max_driving_hours);
        const break_seconds: i64 = @intFromFloat(breaks_needed * self.break_time_mins * 60.0);

        return departure_time + travel_seconds + break_seconds;
    }

    pub fn isValidStartTime(self: TravelParameters) bool {
        const scheduled_start = self.schedule_date.toTimestamp();
        return self.start_time >= scheduled_start;
    }
};
