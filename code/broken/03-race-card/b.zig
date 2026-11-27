// Broken on purpose (lesson: Reading compiler errors). Run it: zig run b.zig
const std = @import("std");

pub fn main() void {
    const riders: u32 = 8.5;
    std.debug.print("{d} riders\n", .{riders});
}
