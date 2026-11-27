const std = @import("std");

// The first race. Constants: they never change while the program runs.
const course_name = "Compile Pass";
const distance_km: f64 = 12.5;
const riders: u32 = 8;

// How far the race moves on each tick of the clock, in seconds.
const dt_s: f64 = 1.0;

pub fn main(init: std.process.Init) !void {
    // Text goes to the terminal through a writer. It collects text in a buffer...
    var buffer: [1024]u8 = undefined;
    var stdout: std.Io.File.Writer = .init(.stdout(), init.io, &buffer);
    const out = &stdout.interface;

    try raceCard(out);

    // One rider. Its speed never changes, so it's a constant; its position does, so it's a variable.
    const speed_mps: f64 = 10.0;
    var position_m: f64 = 0;
    position_m = advance(position_m, speed_mps, dt_s);
    try out.print("after 1 s: {d:.1} m\n", .{position_m});
    position_m = advance(position_m, speed_mps, dt_s);
    try out.print("after 2 s: {d:.1} m\n", .{position_m});
    position_m = advance(position_m, speed_mps, dt_s);
    try out.print("after 3 s: {d:.1} m\n", .{position_m});

    // The road decides how fast you go.
    try out.print("flat road:  {d:.0} m/s\n", .{speedFor(0)});
    try out.print("5% climb:   {d:.0} m/s\n", .{speedFor(5)});
    try out.print("5% descent: {d:.0} m/s\n", .{speedFor(-5)});

    // ...and flush sends what's in the buffer to the screen.
    try out.flush();
}

/// The game's name, in one place: the screen and the test both use it.
fn title() []const u8 {
    return "Terminal Tour";
}

/// The race card: the game's title and what today's race is, in a box.
fn raceCard(w: *std.Io.Writer) !void {
    try w.print("+------------------------------+\n", .{});
    try w.print("| {s:<28} |\n", .{title()});
    try w.print("|                              |\n", .{});
    try w.print("| Course:   {s:<18} |\n", .{course_name});
    try w.print("| Distance: {d:>5.1} km{s:<10} |\n", .{ distance_km, "" });
    try w.print("| Field:    {d} riders{s:<10} |\n", .{ riders, "" });
    try w.print("+------------------------------+\n", .{});
}

/// Where a rider is after `dt` seconds more at `speed_mps`.
fn advance(position_m: f64, speed_mps: f64, dt: f64) f64 {
    return position_m + speed_mps * dt;
}

/// Has a rider at `position_m` crossed the line at `distance_m`?
fn finished(position_m: f64, distance_m: f64) bool {
    return position_m >= distance_m;
}

/// How fast a rider goes on a road this steep (percent: up is positive, down is negative).
fn speedFor(gradient_pct: f64) f64 {
    if (gradient_pct > 3) {
        return 6.0; // climbing
    } else if (gradient_pct < -3) {
        return 14.0; // descending
    } else {
        return 10.0; // flat enough
    }
}

test "the game has a title" {
    try std.testing.expectEqualStrings("Terminal Tour", title());
}

test "race card lists the course, distance and riders" {
    var buf: [512]u8 = undefined;
    var w: std.Io.Writer = .fixed(&buf);
    try raceCard(&w);
    const card = w.buffered();
    try std.testing.expect(std.mem.indexOf(u8, card, "Compile Pass") != null);
    try std.testing.expect(std.mem.indexOf(u8, card, "12.5 km") != null);
    try std.testing.expect(std.mem.indexOf(u8, card, "8 riders") != null);
}

test "a rider at 10 m/s covers 10 m in a second" {
    try std.testing.expectEqual(@as(f64, 10), advance(0, 10, 1));
}

test "advance adds to where the rider already is" {
    try std.testing.expectEqual(@as(f64, 125), advance(100, 12.5, 2));
}

test "a rider at the line has finished" {
    try std.testing.expect(finished(12_500, 12_500));
    try std.testing.expect(!finished(12_499.9, 12_500));
}

test "climbs are slow, descents fast" {
    try std.testing.expectEqual(@as(f64, 6), speedFor(5));
    try std.testing.expectEqual(@as(f64, 14), speedFor(-5));
    try std.testing.expectEqual(@as(f64, 10), speedFor(0));
    try std.testing.expectEqual(@as(f64, 10), speedFor(3));
}
