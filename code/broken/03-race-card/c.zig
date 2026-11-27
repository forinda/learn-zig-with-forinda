// Broken on purpose (lesson: Reading compiler errors). Run it: zig run c.zig
const std = @import("std");

pub fn main(init: std.process.Init) !void {
    var buffer: [1024]u8 = undefined;
    var stdout: std.Io.File.Writer = .init(.stdout(), init.io, &buffer);
    const out = &stdout.interface;
    out.print("Terminal Tour\n", .{});
    try out.flush();
}
