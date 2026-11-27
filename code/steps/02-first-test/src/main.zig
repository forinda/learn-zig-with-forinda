const std = @import("std");

pub fn main(init: std.process.Init) !void {
    // Text goes to the terminal through a writer. It collects text in a buffer...
    var buffer: [1024]u8 = undefined;
    var stdout: std.Io.File.Writer = .init(.stdout(), init.io, &buffer);
    const out = &stdout.interface;

    // #region print
    try out.print("{s}\n", .{title()});
    // #endregion print

    // ...and flush sends what's in the buffer to the screen.
    try out.flush();
}

// #region title
/// The game's name, in one place: the screen and the test both use it.
fn title() []const u8 {
    return "Terminal Tour";
}
// #endregion title

// #region test
test "the game has a title" {
    try std.testing.expectEqualStrings("Terminal Tour", title());
}
// #endregion test
