const std = @import("std");

pub fn main(init: std.process.Init) !void {
    // Text goes to the terminal through a writer. It collects text in a buffer...
    var buffer: [1024]u8 = undefined;
    var stdout: std.Io.File.Writer = .init(.stdout(), init.io, &buffer);
    const out = &stdout.interface;

    try out.print("{s}\n", .{title()});

    // ...and flush sends what's in the buffer to the screen.
    try out.flush();
}

/// The game's name, in one place: the screen and the test both use it.
fn title() []const u8 {
    return "Terminal Tour";
}

test "the game has a title" {
    try std.testing.expectEqualStrings("Terminal Tour", title());
}
