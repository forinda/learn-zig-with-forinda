// Not an error, a surprise (lesson: Values and types). Run it: zig run int-division.zig
const std = @import("std");

pub fn main() void {
    const laps: u32 = 7;
    const half = laps / 2;
    std.debug.print("half of {d} laps is {d}\n", .{ laps, half });
}
