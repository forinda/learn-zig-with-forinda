const std = @import("std");

// The first race. Constants: they never change while the program runs.
const course_name = "Compile Pass";
const distance_km: f64 = 12.5;
const riders: u32 = 8;

// Each rider's speed on a flat road, in metres per second: rider A is the first, H the last.
const field_speeds_mps = [_]f64{ 10.0, 10.4, 9.8, 10.1, 9.6, 10.2, 9.9, 10.3 };

// How far the race moves on each tick of the clock, in seconds.
const dt_s: f64 = 1.0;

// #region rider
/// One rider: everything about it in one place, instead of spread over parallel arrays.
const Rider = struct {
    name: u8, // its letter, A to H
    speed_mps: f64,
    position_m: f64 = 0, // a default: every rider starts at the line

    /// Moves this rider on by `dt` seconds. It changes the rider, so it takes `*Rider`.
    fn advance(self: *Rider, dt: f64) void {
        self.position_m = advance_m(self.position_m, self.speed_mps, dt);
    }

    /// Has this rider crossed the line? It only reads the rider, so it takes a `Rider`.
    fn finished(self: Rider, distance_m: f64) bool {
        return self.position_m >= distance_m;
    }
};
// #endregion rider

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

    // #region main
    // Eight riders, A to H: one array of riders, each one knowing its own name, speed and position.
    const distance_m = distance_km * 1000;
    var field: [field_speeds_mps.len]Rider = undefined;
    for (&field, field_speeds_mps, 0..) |*rider, speed_mps, i| {
        rider.* = .{ .name = riderName(i), .speed_mps = speed_mps };
    }
    var seconds: u32 = 0;
    var next_km_m: f64 = 1000;
    var road: [50]u8 = undefined; // the road as a line of text, 50 characters wide
    while (!field[leader(&field)].finished(distance_m)) {
        advanceAll(&field, dt_s);
        seconds += 1;
        if (field[leader(&field)].position_m >= next_km_m) {
            try out.print("km {d:.0} at ", .{next_km_m / 1000});
            try printTime(out, seconds);
            try out.print(": leader is {c}\n", .{field[leader(&field)].name});
            try out.print("  {s}\n", .{drawRoad(&road, &field, distance_m)});
            next_km_m += 1000;
        }
    }
    try out.print("{c} wins in ", .{field[leader(&field)].name});
    try printTime(out, seconds);
    try out.print("\n", .{});
    // #endregion main

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
fn advance_m(position_m: f64, speed_mps: f64, dt: f64) f64 {
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
        position_m = advance_m(position_m, speed_mps, dt_s);
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

// #region field
/// Moves every rider on by `dt` seconds, each at its own speed. `field` is a slice it can change.
fn advanceAll(field: []Rider, dt: f64) void {
    for (field) |*rider| rider.advance(dt);
}

/// Which rider is furthest along (its index: 0 is A).
fn leader(field: []const Rider) usize {
    var best: usize = 0;
    for (field, 0..) |rider, i| {
        if (rider.position_m > field[best].position_m) best = i;
    }
    return best;
}
// #endregion field

/// A rider's letter: 0 is A, 1 is B, and so on.
fn riderName(i: usize) u8 {
    return 'A' + @as(u8, @intCast(i));
}

// #region draw
/// Draws the road into `buf`: dashes, with each rider's letter where it is along the course. Returns the line.
fn drawRoad(buf: []u8, field: []const Rider, distance_m: f64) []const u8 {
    @memset(buf, '-');
    const last: f64 = @floatFromInt(buf.len - 1);
    // Riders close together share a column, and the last letter written there is the one you see:
    // the rest of the field first, then the player (rider A, index 0), then the leader, so you always
    // see the race's leader, and yourself unless you're in the leader's column.
    const first = leader(field);
    for (field, 0..) |rider, i| {
        if (i != first and i != 0) buf[columnOf(rider.position_m, distance_m, last)] = rider.name;
    }
    if (first != 0) buf[columnOf(field[0].position_m, distance_m, last)] = field[0].name;
    buf[columnOf(field[first].position_m, distance_m, last)] = field[first].name;
    return buf;
}
// #endregion draw

/// The column (0 to `last`) for a rider at `position_m` of `distance_m`.
fn columnOf(position_m: f64, distance_m: f64, last: f64) usize {
    const along = @min(position_m / distance_m, 1.0); // 0 at the start, 1 at the line
    return @intFromFloat(along * last);
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
    try std.testing.expectEqual(@as(f64, 10), advance_m(0, 10, 1));
}

test "advance adds to where the rider already is" {
    try std.testing.expectEqual(@as(f64, 125), advance_m(100, 12.5, 2));
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

// #region helper
/// Test helper: riders named A, B, ... at these positions (in `buf`).
fn ridersAt(buf: []Rider, positions_m: []const f64) []Rider {
    for (buf[0..positions_m.len], positions_m, 0..) |*rider, position_m, i| {
        rider.* = .{ .name = riderName(i), .speed_mps = 10, .position_m = position_m };
    }
    return buf[0..positions_m.len];
}

test "everyone moves at their own speed" {
    var field = [_]Rider{ .{ .name = 'A', .speed_mps = 10 }, .{ .name = 'B', .speed_mps = 12 } };
    advanceAll(&field, 1);
    try std.testing.expectEqual(@as(f64, 10), field[0].position_m);
    try std.testing.expectEqual(@as(f64, 12), field[1].position_m);
}

test "the leader is the furthest along" {
    var buf: [8]Rider = undefined;
    try std.testing.expectEqual(@as(usize, 1), leader(ridersAt(&buf, &.{ 3, 9, 4 })));
}

test "a rider at the start is at column 0" {
    var road: [8]u8 = undefined;
    var buf: [8]Rider = undefined;
    const line = drawRoad(&road, ridersAt(&buf, &.{0}), 100);
    try std.testing.expectEqual(@as(u8, 'A'), line[0]);
}

test "a rider at the line is at the last column" {
    var road: [8]u8 = undefined;
    var buf: [8]Rider = undefined;
    const line = drawRoad(&road, ridersAt(&buf, &.{100}), 100);
    try std.testing.expectEqual(@as(u8, 'A'), line[7]);
}

test "two riders, two letters" {
    var road: [8]u8 = undefined;
    var buf: [8]Rider = undefined;
    const line = drawRoad(&road, ridersAt(&buf, &.{ 0, 50 }), 100);
    try std.testing.expectEqual(@as(u8, 'A'), line[0]);
    try std.testing.expectEqual(@as(u8, 'B'), line[3]); // halfway along 8 columns (0..7): 3.5, rounded down
    try std.testing.expectEqual(@as(u8, '-'), line[1]);
}

test "when riders share a column, the leader's letter shows" {
    var road: [8]u8 = undefined;
    var buf: [8]Rider = undefined;
    const line = drawRoad(&road, ridersAt(&buf, &.{ 10.5, 10 }), 100); // both in column 0; A is ahead
    try std.testing.expectEqual(@as(u8, 'A'), line[0]);
}

test "the player (rider A) shows when the leader is elsewhere" {
    var road: [8]u8 = undefined;
    var buf: [8]Rider = undefined;
    const line = drawRoad(&road, ridersAt(&buf, &.{ 10, 10.5, 90 }), 100); // A and B share column 0; C leads
    try std.testing.expectEqual(@as(u8, 'A'), line[0]);
}
// #endregion helper

// #region tests
test "a rider moves at its own speed" {
    var rider: Rider = .{ .name = 'A', .speed_mps = 10.4 };
    rider.advance(1);
    try std.testing.expectEqual(@as(f64, 10.4), rider.position_m);
}

test "a new rider starts at the line" {
    const rider: Rider = .{ .name = 'B', .speed_mps = 9.8 };
    try std.testing.expectEqual(@as(f64, 0), rider.position_m);
    try std.testing.expect(!rider.finished(12_500));
}
// #endregion tests
