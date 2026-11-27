const std = @import("std");

// The first race. Constants: they never change while the program runs.
const course_name = "Compile Pass";
const distance_km: f64 = 12.5;
const riders: u32 = 8;

// Each rider's speed on a flat road, in metres per second: rider A is the first, H the last.
const field_speeds_mps = [_]f64{ 10.0, 10.4, 9.8, 10.1, 9.6, 10.2, 9.9, 10.3 };

// How far the race moves on each tick of the clock, in seconds.
const dt_s: f64 = 1.0;

pub fn main(init: std.process.Init) !void {
    // Text goes to the terminal through a writer. It collects text in a buffer...
    var buffer: [1024]u8 = undefined;
    var stdout: std.Io.File.Writer = .init(.stdout(), init.io, &buffer);
    const out = &stdout.interface;

    try raceCard(out);

    // The road decides how fast you go.
    try out.print("flat road:  {d:.0} m/s\n", .{speedFor(0)});
    try out.print("5% climb:   {d:.0} m/s\n", .{speedFor(5)});
    try out.print("5% descent: {d:.0} m/s\n", .{speedFor(-5)});

    // Eight riders, A to H, each with its own speed: one array of speeds, one of positions.
    const distance_m = distance_km * 1000;
    var positions_m: [field_speeds_mps.len]f64 = @splat(0); // one position per rider, all at the start
    var seconds: u32 = 0;
    var next_km_m: f64 = 1000;
    while (!finished(positions_m[leader(&positions_m)], distance_m)) {
        advanceAll(&positions_m, &field_speeds_mps, dt_s);
        seconds += 1;
        if (positions_m[leader(&positions_m)] >= next_km_m) {
            try out.print("km {d:.0} at ", .{next_km_m / 1000});
            try printTime(out, seconds);
            try out.print(": leader is {c}\n", .{riderName(leader(&positions_m))});
            next_km_m += 1000;
        }
    }
    try out.print("{c} wins in ", .{riderName(leader(&positions_m))});
    try printTime(out, seconds);
    try out.print("\n", .{});

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

/// How many whole seconds a rider at `speed_mps` needs to cover `distance_m` (a part-second counts).
fn secondsToFinish(distance_m: f64, speed_mps: f64) u32 {
    var position_m: f64 = 0;
    var seconds: u32 = 0;
    while (!finished(position_m, distance_m)) {
        position_m = advance(position_m, speed_mps, dt_s);
        seconds += 1;
    }
    return seconds;
}

/// Prints `seconds` as minutes and seconds, like 1:40. It writes through `w`, so a test can read what it wrote.
fn printTime(w: *std.Io.Writer, seconds: u32) !void {
    const minutes = seconds / 60; // whole minutes: integer division drops the rest
    const rest = seconds % 60; // what's left over
    try w.print("{d}:{d:0>2}", .{ minutes, rest });
}

/// Moves every rider on by `dt` seconds at its own speed. `positions_m` is a slice it can change.
fn advanceAll(positions_m: []f64, speeds_mps: []const f64, dt: f64) void {
    for (positions_m, speeds_mps) |*position_m, speed_mps| {
        position_m.* = advance(position_m.*, speed_mps, dt);
    }
}

/// Which rider is furthest along (its index: 0 is A).
fn leader(positions_m: []const f64) usize {
    var best: usize = 0;
    for (positions_m, 0..) |position_m, i| {
        if (position_m > positions_m[best]) best = i;
    }
    return best;
}

/// A rider's letter: 0 is A, 1 is B, and so on.
fn riderName(i: usize) u8 {
    return 'A' + @as(u8, @intCast(i));
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

test "12.5 km at 10 m/s takes 1250 s" {
    try std.testing.expectEqual(@as(u32, 1250), secondsToFinish(12_500, 10));
}

test "a part-second still counts as a second" {
    try std.testing.expectEqual(@as(u32, 4), secondsToFinish(100, 30));
}

test "times print as minutes and seconds" {
    var buf: [32]u8 = undefined;
    var w: std.Io.Writer = .fixed(&buf);
    try printTime(&w, 100);
    try std.testing.expectEqualStrings("1:40", w.buffered());
    w = .fixed(&buf);
    try printTime(&w, 65);
    try std.testing.expectEqualStrings("1:05", w.buffered());
    w = .fixed(&buf);
    try printTime(&w, 3605);
    try std.testing.expectEqualStrings("60:05", w.buffered());
}

test "everyone moves at their own speed" {
    var positions = [_]f64{ 0, 0 };
    const speeds = [_]f64{ 10, 12 };
    advanceAll(&positions, &speeds, 1);
    try std.testing.expectEqualSlices(f64, &.{ 10, 12 }, &positions);
}

test "the leader is the furthest along" {
    try std.testing.expectEqual(@as(usize, 1), leader(&.{ 3, 9, 4 }));
}
