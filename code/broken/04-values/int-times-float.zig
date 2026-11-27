// Broken on purpose (lesson: Values and types). Run it: zig run int-times-float.zig
const std = @import("std");

/// How far all the riders have gone between them, each at the same speed for one second.
/// (`u64`: a u32 would work, because every u32 fits exactly in an f64. A u64 doesn't.)
fn totalDistance(riders: u64, speed_mps: f64) f64 {
    return riders * speed_mps;
}

pub fn main() void {
    std.debug.print("{d} m\n", .{totalDistance(8, 10.0)});
}
