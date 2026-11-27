const std = @import("std");

// The first race. Constants: they never change while the program runs.
const course_name = "Compile Pass";
const distance_km: f64 = 12.5;
const riders: u32 = 8;

// Each rider's speed on a flat road, in metres per second: rider A is the first, H the last.
const field_speeds_mps = [_]f64{ 10.0, 10.4, 9.8, 10.1, 9.6, 10.2, 9.9, 10.3 };
// ...and on a climb: the strongest climbers aren't the fastest on the flat (E climbs best, B worst).
const field_climb_mps = [_]f64{ 6.2, 5.6, 6.4, 6.0, 6.8, 5.8, 6.3, 5.9 };

// How far the race moves on each tick of the clock, in seconds.
const dt_s: f64 = 1.0;

/// One rider: everything about it in one place, instead of spread over parallel arrays.
const Rider = struct {
    name: u8, // its letter, A to H
    speed_mps: f64,
    climb_mps: f64 = 6.0, // its speed on a climb
    position_m: f64 = 0, // a default: every rider starts at the line

    /// Moves this rider on by `dt` seconds. It changes the rider, so it takes `*Rider`.
    fn advance(self: *Rider, dt: f64) void {
        self.position_m = advance_m(self.position_m, self.speed_mps, dt);
    }

    /// This rider's speed on `terrain`: a switch picks one for each kind.
    fn speedOn(self: Rider, terrain: Terrain) f64 {
        return switch (terrain) {
            .flat => self.speed_mps,
            .climb => self.climb_mps,
            .descent => self.speed_mps * 1.4,
        };
    }

    /// Has this rider crossed the line? It only reads the rider, so it takes a `Rider`.
    fn finished(self: Rider, distance_m: f64) bool {
        return self.position_m >= distance_m;
    }
};

pub fn main(init: std.process.Init) !void {
    // Text goes to the terminal through a writer. It collects text in a buffer...
    var buffer: [1024]u8 = undefined;
    var stdout: std.Io.File.Writer = .init(.stdout(), init.io, &buffer);
    const out = &stdout.interface;

    try raceCard(out);

    // The road decides how fast you go.
    try out.print("flat road:  {d:.0} m/s\n", .{speedFor(Terrain.of(0))});
    try out.print("5% climb:   {d:.0} m/s\n", .{speedFor(Terrain.of(5))});
    try out.print("5% descent: {d:.0} m/s\n", .{speedFor(Terrain.of(-5))});

    // #region main
    // The race is one value: the loop steps it and prints what it says happened.
    var race = Race.init(compile_pass, &field_speeds_mps, &field_climb_mps);
    var road: [50]u8 = undefined; // the road as a line of text, 50 characters wide
    var events: [16]Event = undefined;
    while (!race.done()) {
        for (race.step(&events)) |event| switch (event) {
            .km => |km| {
                try out.print("km {d} at ", .{km});
                try printTime(out, race.clock_s);
                try out.print(": leader is {c}\n", .{race.riders[race.leader()].name});
                try out.print("  {s}\n", .{drawRoad(&road, &race.riders, race.course.distance_m)});
            },
            .new_leader => |name| try out.print("  {c} takes the lead\n", .{name}),
            .finished => |name| {
                try out.print("{c} crosses the line in ", .{name});
                try printTime(out, race.clock_s);
                try out.print("\n", .{});
            },
        };
    }
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

/// The kinds of road: one name for each, instead of remembering what a gradient means.
const Terrain = enum {
    flat,
    climb,
    descent,

    /// The terrain of a road this steep (percent: up is positive, down is negative).
    fn of(gradient_pct: f64) Terrain {
        if (gradient_pct > 3) return .climb;
        if (gradient_pct < -3) return .descent;
        return .flat;
    }
};

/// How fast a 10 m/s rider goes on this terrain. A switch must cover every kind of terrain.
fn speedFor(terrain: Terrain) f64 {
    return switch (terrain) {
        .flat => 10.0,
        .climb => 6.0,
        .descent => 14.0,
    };
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

/// A stretch of road: where it starts and how steep it is, until the next one starts.
const Segment = struct {
    start_m: f64,
    gradient_pct: f64,
};

/// A course: its name, how long it is, and its road, segment by segment.
const Course = struct {
    name: []const u8,
    distance_m: f64,
    segments: []const Segment = &.{}, // no segments: flat all the way

    /// The terrain at `position_m`: the last segment that starts at or before it.
    fn terrainAt(self: Course, position_m: f64) Terrain {
        var gradient_pct: f64 = 0;
        for (self.segments) |segment| {
            if (segment.start_m <= position_m) gradient_pct = segment.gradient_pct;
        }
        return Terrain.of(gradient_pct);
    }
};

const compile_pass: Course = .{
    .name = course_name,
    .distance_m = distance_km * 1000,
    .segments = &.{
        .{ .start_m = 0, .gradient_pct = 0 },
        .{ .start_m = 4000, .gradient_pct = 6 }, // the climb
        .{ .start_m = 6000, .gradient_pct = -6 }, // the descent
        .{ .start_m = 8000, .gradient_pct = 0 },
    },
};

// #region event
/// Something that happened in the race. One value, one of several kinds, each with its own data:
/// a tagged union. A `switch` on it says what to do with each kind.
const Event = union(enum) {
    km: u32, // the leader passed this kilometre marker
    new_leader: u8, // this rider took the lead
    finished: u8, // this rider crossed the line
};
// #endregion event

/// A race: a course, eight riders and a clock. Everything the race loop needs, in one value.
const Race = struct {
    course: Course,
    riders: [8]Rider,
    clock_s: u32 = 0,
    next_km_m: f64 = 1000, // the next kilometre marker to report
    last_leader: usize = 0, // who led after the last step

    /// A race on `course` with riders A to H at these speeds on the flat and on climbs (riders without
    /// speeds of their own ride at 10 m/s on the flat and 6 m/s on climbs).
    fn init(course: Course, speeds_mps: []const f64, climbs_mps: []const f64) Race {
        var race: Race = .{ .course = course, .riders = undefined };
        for (&race.riders, 0..) |*rider, i| {
            const speed_mps = if (i < speeds_mps.len) speeds_mps[i] else 10.0;
            const climb_mps = if (i < climbs_mps.len) climbs_mps[i] else 6.0;
            rider.* = .{ .name = riderName(i), .speed_mps = speed_mps, .climb_mps = climb_mps };
        }
        return race;
    }

    // #region step
    /// One tick of the clock: everyone moves on at its own speed for the terrain under its wheels.
    /// Returns what happened, written into `events` (the caller's buffer; a slice of it comes back).
    fn step(self: *Race, events: []Event) []Event {
        var n: usize = 0;
        var before_m: [8]f64 = undefined;
        for (&self.riders, 0..) |*rider, i| {
            before_m[i] = rider.position_m;
            const speed_mps = rider.speedOn(self.course.terrainAt(rider.position_m));
            rider.position_m = advance_m(rider.position_m, speed_mps, dt_s);
        }
        self.clock_s += 1;
        const first = self.leader();
        if (first != self.last_leader and n < events.len) {
            events[n] = .{ .new_leader = self.riders[first].name };
            n += 1;
            self.last_leader = first;
        }
        if (self.riders[first].position_m >= self.next_km_m and n < events.len) {
            events[n] = .{ .km = @intFromFloat(self.next_km_m / 1000) };
            n += 1;
            self.next_km_m += 1000;
        }
        for (self.riders, before_m) |rider, was_m| {
            if (was_m < self.course.distance_m and rider.finished(self.course.distance_m) and n < events.len) {
                events[n] = .{ .finished = rider.name };
                n += 1;
            }
        }
        return events[0..n];
    }
    // #endregion step

    /// Which rider is furthest along.
    fn leader(self: *const Race) usize {
        return leaderOf(&self.riders);
    }

    /// The race is over when the leader crosses the line.
    fn done(self: *const Race) bool {
        return self.riders[self.leader()].finished(self.course.distance_m);
    }
};

/// Moves every rider on by `dt` seconds, each at its own speed. `field` is a slice it can change.
fn advanceAll(field: []Rider, dt: f64) void {
    for (field) |*rider| rider.advance(dt);
}

/// Which rider is furthest along (its index: 0 is A).
fn leaderOf(field: []const Rider) usize {
    var best: usize = 0;
    for (field, 0..) |rider, i| {
        if (rider.position_m > field[best].position_m) best = i;
    }
    return best;
}

/// A rider's letter: 0 is A, 1 is B, and so on.
fn riderName(i: usize) u8 {
    return 'A' + @as(u8, @intCast(i));
}

/// Draws the road into `buf`: dashes, with each rider's letter where it is along the course. Returns the line.
fn drawRoad(buf: []u8, field: []const Rider, distance_m: f64) []const u8 {
    @memset(buf, '-');
    const last: f64 = @floatFromInt(buf.len - 1);
    // Riders close together share a column, and the last letter written there is the one you see:
    // the rest of the field first, then the player (rider A, index 0), then the leader, so you always
    // see the race's leader, and yourself unless you're in the leader's column.
    const first = leaderOf(field);
    for (field, 0..) |rider, i| {
        if (i != first and i != 0) buf[columnOf(rider.position_m, distance_m, last)] = rider.name;
    }
    if (first != 0) buf[columnOf(field[0].position_m, distance_m, last)] = field[0].name;
    buf[columnOf(field[first].position_m, distance_m, last)] = field[first].name;
    return buf;
}

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
    try std.testing.expectEqual(@as(f64, 6), speedFor(Terrain.of(5)));
    try std.testing.expectEqual(@as(f64, 14), speedFor(Terrain.of(-5)));
    try std.testing.expectEqual(@as(f64, 10), speedFor(Terrain.of(0)));
    try std.testing.expectEqual(@as(f64, 10), speedFor(Terrain.of(3)));
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
    try std.testing.expectEqual(@as(usize, 1), leaderOf(ridersAt(&buf, &.{ 3, 9, 4 })));
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

const test_course: Course = .{ .name = "Test Loop", .distance_m = 100 };

test "a new race has everyone at the start" {
    const race = Race.init(test_course, &field_speeds_mps, &field_climb_mps);
    for (race.riders) |rider| try std.testing.expectEqual(@as(f64, 0), rider.position_m);
    try std.testing.expectEqual(@as(u32, 0), race.clock_s);
}

test "after one step everyone has moved by their speed" {
    var race = Race.init(test_course, &.{ 10, 12 }, &.{});
    var buf: [16]Event = undefined;
    _ = race.step(&buf);
    try std.testing.expectEqual(@as(f64, 10), race.riders[0].position_m);
    try std.testing.expectEqual(@as(f64, 12), race.riders[1].position_m);
    try std.testing.expectEqual(@as(u32, 1), race.clock_s);
}

test "the race is done when the leader is exactly on the line" {
    var race = Race.init(test_course, &.{ 10, 12 }, &.{});
    race.riders[1].position_m = 100;
    try std.testing.expect(race.done());
    race.riders[1].position_m = 99.9;
    try std.testing.expect(!race.done());
}

test "riders without speeds of their own ride at 10 m/s, and climb at 6" {
    const race = Race.init(test_course, &.{12}, &.{});
    try std.testing.expectEqual(@as(f64, 12), race.riders[0].speed_mps);
    try std.testing.expectEqual(@as(f64, 10), race.riders[7].speed_mps);
    try std.testing.expectEqual(@as(f64, 6), race.riders[7].climb_mps);
}

test "gradients map to terrain" {
    try std.testing.expectEqual(Terrain.descent, Terrain.of(-5));
    try std.testing.expectEqual(Terrain.flat, Terrain.of(0));
    try std.testing.expectEqual(Terrain.flat, Terrain.of(3));
    try std.testing.expectEqual(Terrain.climb, Terrain.of(5));
}

test "the course knows its terrain" {
    try std.testing.expectEqual(Terrain.flat, compile_pass.terrainAt(1000));
    try std.testing.expectEqual(Terrain.climb, compile_pass.terrainAt(5000));
    try std.testing.expectEqual(Terrain.descent, compile_pass.terrainAt(7000));
    try std.testing.expectEqual(Terrain.flat, compile_pass.terrainAt(9000));
}

test "each rider climbs at its own speed" {
    const rider: Rider = .{ .name = 'E', .speed_mps = 9.6, .climb_mps = 6.8 };
    try std.testing.expectEqual(@as(f64, 9.6), rider.speedOn(.flat));
    try std.testing.expectEqual(@as(f64, 6.8), rider.speedOn(.climb));
    try std.testing.expectApproxEqAbs(@as(f64, 13.44), rider.speedOn(.descent), 1e-9);
}

// #region tests
/// Test helper: does `events` hold `want`?
fn hasEvent(events: []const Event, want: Event) bool {
    for (events) |event| {
        if (std.meta.eql(event, want)) return true;
    }
    return false;
}

test "a step that passes a km marker reports it" {
    var race = Race.init(.{ .name = "Test Loop", .distance_m = 2500 }, &.{1000}, &.{});
    var buf: [16]Event = undefined;
    try std.testing.expect(hasEvent(race.step(&buf), .{ .km = 1 }));
}

test "a new leader is reported once" {
    var race = Race.init(test_course, &.{ 10, 12 }, &.{});
    var buf: [16]Event = undefined;
    try std.testing.expect(hasEvent(race.step(&buf), .{ .new_leader = 'B' }));
    try std.testing.expect(!hasEvent(race.step(&buf), .{ .new_leader = 'B' }));
}

test "a finisher is reported once" {
    var race = Race.init(.{ .name = "Short", .distance_m = 15 }, &.{10}, &.{});
    var buf: [16]Event = undefined;
    try std.testing.expect(!hasEvent(race.step(&buf), .{ .finished = 'A' }));
    try std.testing.expect(hasEvent(race.step(&buf), .{ .finished = 'A' }));
    try std.testing.expect(!hasEvent(race.step(&buf), .{ .finished = 'A' }));
}
// #endregion tests
