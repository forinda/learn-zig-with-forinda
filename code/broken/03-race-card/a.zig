// Broken on purpose (lesson: Reading compiler errors). Run it: zig run a.zig
const std = @import("std");

pub fn main() void {
    const riders: u32 = 8;
    std.debug.print("Terminal Tour\n", .{});
}
