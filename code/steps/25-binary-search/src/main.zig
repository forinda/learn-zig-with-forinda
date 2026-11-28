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
    full_name: []const u8 = "", // its name on the roster (owned by whoever loaded the roster)
    last_m: f64 = 0, // where it was before the latest step (to see who has just crossed the line)

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

    // What the player types comes in through a reader, with its own buffer: one answer at a time.
    var in_buffer: [64]u8 = undefined;
    var stdin: std.Io.File.Reader = .init(.stdin(), init.io, &in_buffer);
    const in = &stdin.interface;
    // Problems go to stderr, not stdout: the race is the program's output, a note about your answer isn't.
    var err_buffer: [256]u8 = undefined;
    var stderr: std.Io.File.Writer = .init(.stderr(), init.io, &err_buffer);
    const err = &stderr.interface;

    try raceCard(out);

    // The player's name can be any length, so it can't live in a fixed buffer: it's allocated, and
    // whoever allocates frees. `init.gpa` is the program's general-purpose allocator.
    const gpa = init.gpa;
    const typed_name = try askLineAlloc(gpa, in, out, "Your name? ");
    defer if (typed_name) |n| gpa.free(n); // runs when main ends, however it ends
    const player = if (typed_name) |n| (if (n.len > 0) n else "Player") else "Player";

    // Which rider is the player? No answer (or one too long for the buffer) means rider A.
    const answer = askLine(in, out, "Which rider are you (A-H)? ") catch |e| switch (e) {
        error.StreamTooLong => blk: {
            try err.print("note: that answer is too long for {d} bytes; you're rider A\n", .{in_buffer.len});
            try err.flush();
            break :blk null;
        },
        else => return e,
    };
    const you = pickRider(answer);
    const you_index: usize = you - 'A';
    // Positional arguments: {0s} is the first value, used twice; {1c} the second.
    try out.print("Good luck, {0s}! {0s} rides as {1c} today.\n", .{ player, you });

    // The road decides how fast you go.
    try out.print("flat road:  {d:.0} m/s\n", .{speedFor(Terrain.of(0))});
    try out.print("5% climb:   {d:.0} m/s\n", .{speedFor(Terrain.of(5))});
    try out.print("5% descent: {d:.0} m/s\n", .{speedFor(Terrain.of(-5))});

    // Wins per rider name, kept across races: a hash map from name to count. It owns copies of the names,
    // because each race's field (and the names in it) is freed when the race ends.
    var standings: Standings = .empty;
    defer freeStandings(gpa, &standings);

    var race_no: usize = 0;
    while (true) : (race_no += 1) {
        const plan = courses[race_no % courses.len];
        try out.print("\nrace {d}: {s}\n", .{ race_no + 1, plan.name });
        try playRace(gpa, out, &standings, plan, you_index);
        try printStandings(gpa, out, &standings);
        const again = askLine(in, out, "Race again? (y/n) ") catch |e| switch (e) {
            error.StreamTooLong => null, // an answer that long isn't "y"
            else => return e,
        };
        if (!wantsMore(again)) break;
    }

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

/// Prints `question`, then reads one line of the answer, without the spaces or `\r` around it.
/// `null` when there's nothing more to read (the input ended); `error.StreamTooLong` when the line
/// doesn't fit in the reader's buffer.
fn askLine(in: *std.Io.Reader, out: *std.Io.Writer, question: []const u8) !?[]const u8 {
    try out.print("{s}", .{question});
    try out.flush(); // the question must be on screen before we wait for the answer
    const line = in.takeDelimiter('\n') catch |e| switch (e) {
        error.StreamTooLong => {
            // Throw away the rest of that line, so the next question reads the next line, not its end.
            _ = in.discardDelimiterInclusive('\n') catch 0;
            return e;
        },
        else => return e,
    } orelse {
        try out.print("\n", .{}); // nobody typed Enter, so end the question's line ourselves
        return null;
    };
    return std.mem.trim(u8, line, " \t\r");
}

/// Like `askLine`, but the answer can be any length: it's collected in memory from `gpa`, which grows as
/// needed. The caller owns the answer and frees it with `gpa.free`. `null` when the input has ended.
fn askLineAlloc(gpa: std.mem.Allocator, in: *std.Io.Reader, out: *std.Io.Writer, question: []const u8) !?[]u8 {
    try out.print("{s}", .{question});
    try out.flush();
    var line: std.Io.Writer.Allocating = .init(gpa);
    defer line.deinit(); // the growing buffer goes, whatever happens; the answer is a copy
    const n = try in.streamDelimiterEnding(&line.writer, '\n');
    if (in.bufferedLen() > 0) {
        in.toss(1); // the '\n' that ended the line
    } else if (n == 0) {
        try out.print("\n", .{});
        return null; // the input ended before anything was typed
    }
    return try gpa.dupe(u8, std.mem.trim(u8, line.written(), " \t\r"));
}

/// The rider letter in an answer: one letter A to H, either case. Anything else means rider A.
fn pickRider(answer: ?[]const u8) u8 {
    const text = answer orelse return 'A';
    if (text.len != 1) return 'A';
    const letter = std.ascii.toUpper(text[0]);
    return if (letter >= 'A' and letter <= 'H') letter else 'A';
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

    // #region search
    /// The terrain at `position_m`: that of the segment it's on (flat before the first).
    fn terrainAt(self: Course, position_m: f64) Terrain {
        const i = self.segmentAt(position_m) orelse return .flat;
        return Terrain.of(self.segments[i].gradient_pct);
    }

    /// Which segment `position_m` is on: the last one that starts at or before it, or `null` before the
    /// first. The segments are in order of where they start, so a binary search finds it: `partitionPoint`
    /// returns how many segments start at or before `position_m`.
    fn segmentAt(self: Course, position_m: f64) ?usize {
        const starts_before = std.sort.partitionPoint(Segment, self.segments, position_m, startsAtOrBefore);
        return if (starts_before == 0) null else starts_before - 1;
    }

    fn startsAtOrBefore(position_m: f64, segment: Segment) bool {
        return segment.start_m <= position_m;
    }
    // #endregion search
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

/// Compile Pass as text, one segment a line: the terrain, its length in metres, and (for climbs and
/// descents) its gradient in percent. A multiline string: each line starts with `\\`.
const compile_pass_text =
    \\flat 4000
    \\climb 2000 6
    \\descent 2000 -6
    \\flat 4500
;

/// Everything that can be wrong with a course's text: an error set.
const ParseError = error{ UnknownTerrain, MissingNumber, BadNumber, OutOfMemory };

/// Reads a course from `text` into `buf`. Returns the course, or an error saying what was wrong with the text.
fn parseCourse(gpa: std.mem.Allocator, name: []const u8, text: []const u8) ParseError!Course {
    var segments: std.ArrayList(Segment) = .empty; // starts with no memory, grows as segments are added
    errdefer segments.deinit(gpa);
    var start_m: f64 = 0;
    var lines = std.mem.tokenizeScalar(u8, text, '\n');
    while (lines.next()) |line| {
        var words = std.mem.tokenizeScalar(u8, line, ' ');
        const kind = words.next() orelse continue; // an empty line: skip it
        const length_m = try number(words.next());
        const gradient_pct: f64 = if (std.mem.eql(u8, kind, "flat"))
            0
        else if (std.mem.eql(u8, kind, "climb") or std.mem.eql(u8, kind, "descent"))
            try number(words.next())
        else
            return error.UnknownTerrain;
        try segments.append(gpa, .{ .start_m = start_m, .gradient_pct = gradient_pct });
        start_m += length_m;
    }
    // The list's memory becomes the course's: the caller frees `course.segments`.
    return .{ .name = name, .distance_m = start_m, .segments = try segments.toOwnedSlice(gpa) };
}

/// The field as text, one rider a line: speed on the flat, speed on a climb (m/s), and its name.
/// Rider A is the first line, B the second, and so on.
const roster_text =
    \\10.0 6.2 Alloc
    \\10.4 5.6 Buffer
    \\9.8 6.4 Comptime
    \\10.1 6.0 Defer
    \\9.6 6.8 Errdefer
    \\10.2 5.8 Flush
    \\9.9 6.3 Generic
    \\10.3 5.9 Heap
;

/// What can go wrong loading a roster: a bad number, a line with no name, or running out of memory.
const RosterError = ParseError || error{ MissingName, OutOfMemory };

/// Loads the riders in `text`. Allocates the field and each rider's name: free it all with `freeField`.
fn loadField(gpa: std.mem.Allocator, text: []const u8) RosterError![]Rider {
    var field: std.ArrayList(Rider) = .empty; // grows one rider at a time: no need to count first
    errdefer field.deinit(gpa); // only if we return an error: on success the caller owns the riders
    errdefer for (field.items) |rider| gpa.free(rider.full_name); // runs first: last in, first out

    var lines = std.mem.tokenizeScalar(u8, text, '\n');
    while (lines.next()) |line| {
        var words = std.mem.tokenizeScalar(u8, line, ' ');
        const speed_mps = try number(words.next());
        const climb_mps = try number(words.next());
        const full_name = std.mem.trim(u8, words.rest(), " \t\r");
        if (full_name.len == 0) return error.MissingName;
        const owned_name = try gpa.dupe(u8, full_name); // a copy: the field mustn't depend on `text`
        errdefer gpa.free(owned_name); // if the append below fails, this name isn't in the list yet
        try field.append(gpa, .{
            .name = riderName(field.items.len),
            .speed_mps = speed_mps,
            .climb_mps = climb_mps,
            .full_name = owned_name,
        });
    }
    return field.toOwnedSlice(gpa); // the list's memory, exactly as long as the field, now the caller's
}

/// Frees what `loadField` allocated: each name, then the field.
fn freeField(gpa: std.mem.Allocator, field: []Rider) void {
    for (field) |rider| gpa.free(rider.full_name);
    gpa.free(field);
}

/// A second course, flatter: the riders who are fastest on the flat should do better here.
const linker_loop_text =
    \\flat 5000
    \\climb 1000 4
    \\flat 6000
;

/// The courses, raced in turn.
/// A course to race: its name and its road as text.
const CoursePlan = struct { name: []const u8, text: []const u8 };

const courses = [_]CoursePlan{
    .{ .name = course_name, .text = compile_pass_text },
    .{ .name = "Linker Loop", .text = linker_loop_text },
};

/// One line of the race feed: when it happened and what, as text in a fixed buffer.
const FeedLine = struct {
    pub const max_len = 48;
    clock_s: u32,
    text_buf: [max_len]u8 = undefined,
    len: usize = 0,

    fn text(self: *const FeedLine) []const u8 {
        return self.text_buf[0..self.len];
    }
};

/// How many lines the feed keeps.
const feed_size = 6;

/// The race feed: the last few lines, in a ring buffer. When it's full, a new line pushes out the oldest.
const Feed = struct {
    lines: std.Deque(FeedLine),

    /// A feed that keeps as many lines as `buf` has room for (no allocation: the ring is `buf`).
    fn init(buf: []FeedLine) Feed {
        return .{ .lines = .initBuffer(buf) };
    }

    /// Adds a line, written with `fmt` and `args`; text too long for a line is cut.
    fn push(self: *Feed, clock_s: u32, comptime fmt: []const u8, args: anytype) void {
        var line: FeedLine = .{ .clock_s = clock_s };
        var w: std.Io.Writer = .fixed(&line.text_buf);
        w.print(fmt, args) catch {}; // full: keep what fits
        line.len = w.buffered().len;
        if (self.lines.len == self.lines.buffer.len) _ = self.lines.popFront(); // drop the oldest
        self.lines.pushBackAssumeCapacity(line);
    }
};

/// Sorting order for rider indexes: further along first; level riders in letter order (so the order
/// never flickers between riders on the same metre).
fn aheadOf(field: []const Rider, a: usize, b: usize) bool {
    if (field[a].position_m != field[b].position_m) return field[a].position_m > field[b].position_m;
    return a < b;
}

/// The results, in race order: the place, the rider, and the time for those who finished or the gap to
/// the line for those who didn't.
fn printResults(w: *std.Io.Writer, race: *const Race) !void {
    try w.print("results:\n", .{});
    for (race.order, 1..) |index, place| {
        const rider = race.riders[index];
        try w.print("{d:>4}  {c}  {s:<10}", .{ place, rider.name, rider.full_name });
        if (rider.finished(race.course.distance_m)) {
            try printTime(w, race.clock_s);
        } else {
            try w.print("+{d:.0} m", .{race.course.distance_m - rider.position_m});
        }
        try w.print("\n", .{});
    }
}

/// The kinds of mark on a course, in the order they're announced when two share a metre.
const MarkKind = enum { km, climb_start, climb_top, to_go };

/// A point on the course worth announcing when the leader reaches it.
const Mark = struct {
    at_m: f64,
    kind: MarkKind,

    /// What the mark says, written into `buf`.
    fn label(self: Mark, buf: []u8) []const u8 {
        return switch (self.kind) {
            .km => std.fmt.bufPrint(buf, "km {d:.0}", .{self.at_m / 1000}) catch "km",
            .climb_start => "foot of the climb",
            .climb_top => "top of the climb",
            .to_go => "1 km to go",
        };
    }

    /// Queue order: nearer first; at the same metre, by kind.
    fn nearer(_: void, a: Mark, b: Mark) std.math.Order {
        const by_distance = std.math.order(a.at_m, b.at_m);
        if (by_distance != .eq) return by_distance;
        return std.math.order(@backingInt(a.kind), @backingInt(b.kind));
    }
};

/// Marks waiting to be reached, nearest first.
const MarkQueue = std.PriorityQueue(Mark, void, Mark.nearer);

/// Every mark on `course`: each whole km, the foot and top of each climb, and 1 km to go. Pushed in
/// whatever order is easiest to find them; the queue sorts them out.
fn planMarks(gpa: std.mem.Allocator, course: Course) !MarkQueue {
    var marks: MarkQueue = .empty;
    errdefer marks.deinit(gpa);
    var km_m: f64 = 1000;
    while (km_m < course.distance_m) : (km_m += 1000) try marks.push(gpa, .{ .at_m = km_m, .kind = .km });
    for (course.segments, 0..) |segment, i| {
        if (Terrain.of(segment.gradient_pct) != .climb) continue;
        const end_m = if (i + 1 < course.segments.len) course.segments[i + 1].start_m else course.distance_m;
        try marks.push(gpa, .{ .at_m = segment.start_m, .kind = .climb_start });
        try marks.push(gpa, .{ .at_m = end_m, .kind = .climb_top });
    }
    if (course.distance_m > 1000) try marks.push(gpa, .{ .at_m = course.distance_m - 1000, .kind = .to_go });
    return marks;
}

/// One race on `plan`'s course, printed to `out`, its winner added to `standings`.
fn playRace(gpa: std.mem.Allocator, out: *std.Io.Writer, standings: *Standings, plan: CoursePlan, you_index: usize) !void {
    // Everything this race allocates comes from an arena: no frees one by one, one `deinit` for the lot
    // when the race is over. What must outlive the race (the standings) uses `gpa` itself.
    var arena: std.heap.ArenaAllocator = .init(gpa);
    defer arena.deinit();
    const race_gpa = arena.allocator();
    const course = try parseCourse(race_gpa, plan.name, plan.text);
    const field = try loadField(race_gpa, roster_text); // fresh riders, all at the start
    // The race is one value: the loop steps it and prints what it says happened.
    var race = try Race.fromField(course, field);
    race.marks = try planMarks(race_gpa, course); // in the race's arena, gone with it
    try race.trackOrder(race_gpa);
    var road: [50]u8 = undefined; // the road as a line of text, 50 characters wide
    var events: [16]Event = undefined;
    // The feed remembers the race's last few moments: a ring buffer of `feed_size` lines, no allocation.
    var feed_lines: [feed_size]FeedLine = undefined;
    var feed: Feed = .init(&feed_lines);
    while (!race.done()) {
        for (race.step(&events)) |event| switch (event) {
            .mark => |mark| {
                var label_buf: [24]u8 = undefined;
                const label = mark.label(&label_buf);
                feed.push(race.clock_s, "{s}: {s} leads", .{ label, race.riders[race.leader()].full_name });
                if (mark.kind != .km) { // the climb and the finale get a line of their own, no road
                    try out.print("  {s} at ", .{label});
                    try printTime(out, race.clock_s);
                    try out.print("\n", .{});
                    continue;
                }
                try out.print("{s} at ", .{label});
                try printTime(out, race.clock_s);
                try out.print(": leader is {c}", .{race.riders[race.leader()].name});
                if (race.order.len >= 3) {
                    try out.print(", then {c}, {c}", .{ race.riders[race.order[1]].name, race.riders[race.order[2]].name });
                }
                try out.print("\n", .{});
                try out.print("  {s}\n", .{drawRoad(&road, race.riders, race.course.distance_m, you_index)});
            },
            .new_leader => |name| {
                try out.print("  {c} takes the lead\n", .{name});
                feed.push(race.clock_s, "{s} takes the lead", .{race.riderNamed(name).?.full_name});
            },
            .finished => |name| {
                feed.push(race.clock_s, "{s} crosses the line", .{race.riderNamed(name).?.full_name});
                try out.print("{c} crosses the line in ", .{name});
                try printTime(out, race.clock_s);
                try out.print("\n", .{});
            },
        };
    }

    // The last moments, oldest first: everything older has been pushed out of the ring.
    try out.print("the finale:\n", .{});
    var lines = feed.lines.iterator();
    while (lines.next()) |line| {
        try out.print("  ", .{});
        try printTime(out, line.clock_s);
        try out.print("  {s}\n", .{line.text()});
    }
    try printResults(out, &race);

    // An optional has to be unwrapped before it's used. `orelse` gives a value to use when there's none...
    if (race.winner) |w| {
        try out.print("winner: {c} ({s})\n", .{ w, race.riderNamed(w).?.full_name });
    } else {
        try out.print("winner: ?\n", .{});
    }
    // ...and `if` with a capture runs only when there is one.
    // Named arguments: each hole says which value it wants, so the text reads like the sentence it prints.
    if (race.riderNamed(riderName(you_index))) |rider| {
        if (rider.finished(race.course.distance_m)) {
            try out.print("you ({[name]c}) crossed the line!\n", .{ .name = rider.name });
        } else {
            try out.print("you ({[name]c}) were {[gap]d:.0} m from the line\n", .{
                .name = rider.name,
                .gap = race.course.distance_m - rider.position_m,
            });
        }
    }
    if (race.winner) |w| try recordWin(gpa, standings, race.riderNamed(w).?.full_name);
}

/// Wins per rider name. The map owns its keys: each is a copy, freed by `freeStandings`.
const Standings = std.StringHashMapUnmanaged(u32);

/// One more win for `name`.
fn recordWin(gpa: std.mem.Allocator, standings: *Standings, name: []const u8) !void {
    if (standings.getPtr(name)) |wins| {
        wins.* += 1; // a name we've seen: change its count where it is
        return;
    }
    const key = try gpa.dupe(u8, name); // a name we haven't: the map gets its own copy
    errdefer gpa.free(key);
    try standings.put(gpa, key, 1);
}

/// Frees every key the standings own, then the map itself.
fn freeStandings(gpa: std.mem.Allocator, standings: *Standings) void {
    var keys = standings.keyIterator();
    while (keys.next()) |key| gpa.free(key.*);
    standings.deinit(gpa);
}

/// One line of the standings table.
const Row = struct {
    name: []const u8,
    wins: u32,

    /// Sorting order: most wins first, then by name.
    fn before(_: void, a: Row, b: Row) bool {
        if (a.wins != b.wins) return a.wins > b.wins;
        return std.mem.lessThan(u8, a.name, b.name);
    }
};

/// Prints the standings, most wins first. A map has no order of its own, so the rows go into a list
/// that can be sorted.
fn printStandings(gpa: std.mem.Allocator, w: *std.Io.Writer, standings: *const Standings) !void {
    var rows: std.ArrayList(Row) = .empty;
    defer rows.deinit(gpa);
    var entries = standings.iterator();
    while (entries.next()) |entry| try rows.append(gpa, .{ .name = entry.key_ptr.*, .wins = entry.value_ptr.* });
    std.mem.sort(Row, rows.items, {}, Row.before);
    try w.print("standings:\n", .{});
    for (rows.items) |row| try w.print("  {d}  {s}\n", .{ row.wins, row.name });
}

/// Does this answer mean "yes, race again"? Anything starting with y or Y does.
fn wantsMore(answer: ?[]const u8) bool {
    const text = answer orelse return false;
    return text.len > 0 and std.ascii.toLower(text[0]) == 'y';
}

/// A word as a number: `MissingNumber` when there's no word, `BadNumber` when it isn't one.
fn number(word: ?[]const u8) ParseError!f64 {
    const w = word orelse return error.MissingNumber;
    return std.fmt.parseFloat(f64, w) catch error.BadNumber; // the library's own error becomes ours
}

/// Something that happened in the race. One value, one of several kinds, each with its own data:
/// a tagged union. A `switch` on it says what to do with each kind.
const Event = union(enum) {
    mark: Mark, // the leader passed a mark on the course
    new_leader: u8, // this rider took the lead
    finished: u8, // this rider crossed the line
};

/// A race: a course, eight riders and a clock. Everything the race loop needs, in one value.
const Race = struct {
    course: Course,
    riders: []Rider, // the field: not the race's own memory, a view of the caller's
    clock_s: u32 = 0,
    marks: MarkQueue = .empty, // the course's marks still ahead, nearest first
    order: []usize = &.{}, // rider indexes, leader first (once `trackOrder` has made room for them)
    last_leader: usize = 0, // who led after the last step
    winner: ?u8 = null, // nobody yet: an optional is a value or null

    /// A race on `course` with these riders: any number, as long as there's one. The race changes them
    /// (they move), and the caller keeps owning them.
    fn fromField(course: Course, field: []Rider) error{NoRiders}!Race {
        if (field.len == 0) return error.NoRiders;
        return .{ .course = course, .riders = field };
    }

    /// A race on `course` with a rider in each place of `field`, at these speeds on the flat and on
    /// climbs (riders without speeds of their own ride at 10 m/s on the flat and 6 m/s on climbs).
    fn init(field: []Rider, course: Course, speeds_mps: []const f64, climbs_mps: []const f64) Race {
        for (field, 0..) |*rider, i| {
            const speed_mps = if (i < speeds_mps.len) speeds_mps[i] else 10.0;
            const climb_mps = if (i < climbs_mps.len) climbs_mps[i] else 6.0;
            rider.* = .{ .name = riderName(i), .speed_mps = speed_mps, .climb_mps = climb_mps };
        }
        return .{ .course = course, .riders = field };
    }

    /// One tick of the clock: everyone moves on at its own speed for the terrain under its wheels.
    /// Returns what happened, written into `events` (the caller's buffer; a slice of it comes back).
    fn step(self: *Race, events: []Event) []Event {
        var n: usize = 0;
        for (self.riders) |*rider| {
            rider.last_m = rider.position_m;
            const speed_mps = rider.speedOn(self.course.terrainAt(rider.position_m));
            rider.position_m = advance_m(rider.position_m, speed_mps, dt_s);
        }
        self.clock_s += 1;
        // Riders rarely swap places in one second, so the order is nearly sorted already: insertion sort
        // only has to move the few who changed places.
        std.sort.insertion(usize, self.order, self.riders, aheadOf);
        const first = self.leader();
        if (first != self.last_leader and n < events.len) {
            events[n] = .{ .new_leader = self.riders[first].name };
            n += 1;
            self.last_leader = first;
        }
        // Every mark the leader has reached, nearest first: the queue always hands out the smallest.
        while (self.marks.peek()) |mark| {
            if (mark.at_m > self.riders[first].position_m or n == events.len) break;
            events[n] = .{ .mark = self.marks.pop().? };
            n += 1;
        }
        for (self.riders) |rider| {
            if (rider.last_m < self.course.distance_m and rider.finished(self.course.distance_m)) {
                if (self.winner == null) self.winner = rider.name; // the first across the line
                if (n < events.len) {
                    events[n] = .{ .finished = rider.name };
                    n += 1;
                }
            }
        }
        return events[0..n];
    }

    /// Starts keeping the race order: room for one index per rider, in letter order to begin with.
    fn trackOrder(self: *Race, gpa: std.mem.Allocator) !void {
        self.order = try gpa.alloc(usize, self.riders.len);
        for (self.order, 0..) |*place, i| place.* = i;
    }

    /// Which rider is furthest along.
    fn leader(self: *const Race) usize {
        return leaderOf(self.riders);
    }

    /// The rider with this letter, or null if there's none. A pointer, so the caller can change it.
    fn riderNamed(self: *Race, name: u8) ?*Rider {
        for (self.riders) |*rider| {
            if (rider.name == name) return rider;
        }
        return null;
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
fn drawRoad(buf: []u8, field: []const Rider, distance_m: f64, you: usize) []const u8 {
    @memset(buf, '-');
    const last: f64 = @floatFromInt(buf.len - 1);
    // Riders close together share a column, and the last letter written there is the one you see:
    // the rest of the field first, then you (the rider at index `you`), then the leader, so you always
    // see the race's leader, and yourself unless you're in the leader's column.
    const first = leaderOf(field);
    for (field, 0..) |rider, i| {
        if (i != first and i != you) buf[columnOf(rider.position_m, distance_m, last)] = rider.name;
    }
    if (first != you) buf[columnOf(field[you].position_m, distance_m, last)] = field[you].name;
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
    const line = drawRoad(&road, ridersAt(&buf, &.{0}), 100, 0);
    try std.testing.expectEqual(@as(u8, 'A'), line[0]);
}

test "a rider at the line is at the last column" {
    var road: [8]u8 = undefined;
    var buf: [8]Rider = undefined;
    const line = drawRoad(&road, ridersAt(&buf, &.{100}), 100, 0);
    try std.testing.expectEqual(@as(u8, 'A'), line[7]);
}

test "two riders, two letters" {
    var road: [8]u8 = undefined;
    var buf: [8]Rider = undefined;
    const line = drawRoad(&road, ridersAt(&buf, &.{ 0, 50 }), 100, 0);
    try std.testing.expectEqual(@as(u8, 'A'), line[0]);
    try std.testing.expectEqual(@as(u8, 'B'), line[3]); // halfway along 8 columns (0..7): 3.5, rounded down
    try std.testing.expectEqual(@as(u8, '-'), line[1]);
}

test "when riders share a column, the leader's letter shows" {
    var road: [8]u8 = undefined;
    var buf: [8]Rider = undefined;
    const line = drawRoad(&road, ridersAt(&buf, &.{ 10.5, 10 }), 100, 0); // both in column 0; A is ahead
    try std.testing.expectEqual(@as(u8, 'A'), line[0]);
}

test "the player (rider A) shows when the leader is elsewhere" {
    var road: [8]u8 = undefined;
    var buf: [8]Rider = undefined;
    const line = drawRoad(&road, ridersAt(&buf, &.{ 10, 10.5, 90 }), 100, 0); // A and B share column 0; C leads
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
    var field: [8]Rider = undefined;
    const race = Race.init(&field, test_course, &field_speeds_mps, &field_climb_mps);
    for (race.riders) |rider| try std.testing.expectEqual(@as(f64, 0), rider.position_m);
    try std.testing.expectEqual(@as(u32, 0), race.clock_s);
}

test "after one step everyone has moved by their speed" {
    var field: [8]Rider = undefined;
    var race = Race.init(&field, test_course, &.{ 10, 12 }, &.{});
    var buf: [16]Event = undefined;
    _ = race.step(&buf);
    try std.testing.expectEqual(@as(f64, 10), race.riders[0].position_m);
    try std.testing.expectEqual(@as(f64, 12), race.riders[1].position_m);
    try std.testing.expectEqual(@as(u32, 1), race.clock_s);
}

test "the race is done when the leader is exactly on the line" {
    var field: [8]Rider = undefined;
    var race = Race.init(&field, test_course, &.{ 10, 12 }, &.{});
    race.riders[1].position_m = 100;
    try std.testing.expect(race.done());
    race.riders[1].position_m = 99.9;
    try std.testing.expect(!race.done());
}

test "riders without speeds of their own ride at 10 m/s, and climb at 6" {
    var field: [8]Rider = undefined;
    const race = Race.init(&field, test_course, &.{12}, &.{});
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

/// Test helper: does `events` hold `want`?
fn hasEvent(events: []const Event, want: Event) bool {
    for (events) |event| {
        if (std.meta.eql(event, want)) return true;
    }
    return false;
}

test "a step that passes a km marker reports it" {
    var field: [8]Rider = undefined;
    const course: Course = .{ .name = "Test Loop", .distance_m = 2500 };
    var race = Race.init(&field, course, &.{1000}, &.{});
    race.marks = try planMarks(std.testing.allocator, course);
    defer race.marks.deinit(std.testing.allocator);
    var buf: [16]Event = undefined;
    try std.testing.expect(hasEvent(race.step(&buf), .{ .mark = .{ .at_m = 1000, .kind = .km } }));
}

test "a new leader is reported once" {
    var field: [8]Rider = undefined;
    var race = Race.init(&field, test_course, &.{ 10, 12 }, &.{});
    var buf: [16]Event = undefined;
    try std.testing.expect(hasEvent(race.step(&buf), .{ .new_leader = 'B' }));
    try std.testing.expect(!hasEvent(race.step(&buf), .{ .new_leader = 'B' }));
}

test "a finisher is reported once" {
    var field: [8]Rider = undefined;
    var race = Race.init(&field, .{ .name = "Short", .distance_m = 15 }, &.{10}, &.{});
    var buf: [16]Event = undefined;
    try std.testing.expect(!hasEvent(race.step(&buf), .{ .finished = 'A' }));
    try std.testing.expect(hasEvent(race.step(&buf), .{ .finished = 'A' }));
    try std.testing.expect(!hasEvent(race.step(&buf), .{ .finished = 'A' }));
}

test "no winner until someone finishes" {
    var field: [8]Rider = undefined;
    var race = Race.init(&field, .{ .name = "Short", .distance_m = 15 }, &.{10}, &.{});
    var buf: [16]Event = undefined;
    _ = race.step(&buf);
    try std.testing.expectEqual(@as(?u8, null), race.winner);
    _ = race.step(&buf);
    try std.testing.expectEqual(@as(?u8, 'A'), race.winner);
}

test "an unknown rider name gives null" {
    var field: [8]Rider = undefined;
    var race = Race.init(&field, test_course, &.{}, &.{});
    try std.testing.expect(race.riderNamed('Z') == null);
}

test "a known name finds that rider" {
    var field: [8]Rider = undefined;
    var race = Race.init(&field, test_course, &.{ 10, 12, 9 }, &.{});
    const rider = race.riderNamed('C') orelse return error.TestExpectedRider;
    try std.testing.expectEqual(@as(f64, 9), rider.speed_mps);
}

test "Compile Pass parses into four segments" {
    const course = try parseCourse(std.testing.allocator, "Compile Pass", compile_pass_text);
    defer std.testing.allocator.free(course.segments);
    try std.testing.expectEqual(@as(usize, 4), course.segments.len);
    try std.testing.expectEqual(@as(f64, 12_500), course.distance_m);
    try std.testing.expectEqual(@as(f64, 4000), course.segments[1].start_m);
    try std.testing.expectEqual(@as(f64, 6), course.segments[1].gradient_pct);
    try std.testing.expectEqual(Terrain.descent, course.terrainAt(7000));
}

test "an unknown terrain is an error" {
    try std.testing.expectError(error.UnknownTerrain, parseCourse(std.testing.allocator, "x", "gravel 100"));
}

test "a missing number is an error" {
    try std.testing.expectError(error.MissingNumber, parseCourse(std.testing.allocator, "x", "flat"));
    try std.testing.expectError(error.MissingNumber, parseCourse(std.testing.allocator, "x", "climb 2000"));
}

test "a number that isn't one is an error" {
    try std.testing.expectError(error.BadNumber, parseCourse(std.testing.allocator, "x", "flat far"));
}

test "the player picks a rider by letter, either case" {
    try std.testing.expectEqual(@as(u8, 'B'), pickRider("b"));
    try std.testing.expectEqual(@as(u8, 'H'), pickRider("H"));
}

test "anything else, or no answer, makes you rider A" {
    try std.testing.expectEqual(@as(u8, 'A'), pickRider("Z"));
    try std.testing.expectEqual(@as(u8, 'A'), pickRider("bob"));
    try std.testing.expectEqual(@as(u8, 'A'), pickRider(""));
    try std.testing.expectEqual(@as(u8, 'A'), pickRider(null));
}

test "an answer is trimmed of spaces and a Windows \\r" {
    var in: std.Io.Reader = .fixed("  c \r\nnext line\n");
    var buf: [64]u8 = undefined;
    var out: std.Io.Writer = .fixed(&buf);
    const answer = try askLine(&in, &out, "Which rider? ");
    try std.testing.expectEqualStrings("c", answer.?);
    try std.testing.expectEqualStrings("Which rider? ", out.buffered());
}

test "after an answer too long, the next question reads the next line" {
    var small: [8]u8 = undefined; // a reader with an 8-byte buffer, like stdin's 64, only smaller
    var reader: std.testing.Reader = .init(&small, &.{.{ .buffer = "far too long an answer\nb\n" }});
    var buf: [128]u8 = undefined;
    var out: std.Io.Writer = .fixed(&buf);
    try std.testing.expectError(error.StreamTooLong, askLine(&reader.interface, &out, "? "));
    try std.testing.expectEqualStrings("b", (try askLine(&reader.interface, &out, "? ")).?);
}

test "no input at all is no answer" {
    var in: std.Io.Reader = .fixed("");
    var buf: [64]u8 = undefined;
    var out: std.Io.Writer = .fixed(&buf);
    try std.testing.expect(try askLine(&in, &out, "Which rider? ") == null);
}

test "the road shows you, whichever rider you are" {
    var road: [8]u8 = undefined;
    var buf: [8]Rider = undefined;
    const line = drawRoad(&road, ridersAt(&buf, &.{ 10.5, 10, 90 }), 100, 1); // A and B share column 0; you are B
    try std.testing.expectEqual(@as(u8, 'B'), line[0]);
}

test "a name of any length comes back whole" {
    var long: [211]u8 = @splat('a'); // 210 letters and a newline: more than any fixed buffer we'd pick
    long[210] = '\n';
    var in: std.Io.Reader = .fixed(&long);
    var buf: [64]u8 = undefined;
    var out: std.Io.Writer = .fixed(&buf);
    const name = (try askLineAlloc(std.testing.allocator, &in, &out, "Your name? ")).?;
    defer std.testing.allocator.free(name);
    try std.testing.expectEqual(@as(usize, 210), name.len);
}

test "a name is trimmed, and the last line counts without a newline" {
    var in: std.Io.Reader = .fixed("  Ada Lovelace \r\nGrace");
    var buf: [64]u8 = undefined;
    var out: std.Io.Writer = .fixed(&buf);
    const first = (try askLineAlloc(std.testing.allocator, &in, &out, "? ")).?;
    defer std.testing.allocator.free(first);
    const second = (try askLineAlloc(std.testing.allocator, &in, &out, "? ")).?;
    defer std.testing.allocator.free(second);
    try std.testing.expectEqualStrings("Ada Lovelace", first);
    try std.testing.expectEqualStrings("Grace", second);
}

test "no input is no name, and nothing to free" {
    var in: std.Io.Reader = .fixed("");
    var buf: [64]u8 = undefined;
    var out: std.Io.Writer = .fixed(&buf);
    try std.testing.expect(try askLineAlloc(std.testing.allocator, &in, &out, "Your name? ") == null);
}

test "the roster loads eight riders, each with a name of its own" {
    const field = try loadField(std.testing.allocator, roster_text);
    defer freeField(std.testing.allocator, field);
    try std.testing.expectEqual(@as(usize, 8), field.len);
    try std.testing.expectEqual(@as(u8, 'E'), field[4].name);
    try std.testing.expectEqualStrings("Errdefer", field[4].full_name);
    try std.testing.expectEqual(@as(f64, 6.8), field[4].climb_mps);
}

test "a bad line is an error, and what was made before it is freed" {
    // std.testing.allocator fails the test if anything allocated here isn't freed.
    try std.testing.expectError(error.BadNumber, loadField(std.testing.allocator, "10 6 Alloc\n10 x Buffer"));
    try std.testing.expectError(error.MissingName, loadField(std.testing.allocator, "10 6 Alloc\n10 6"));
}

fn loadAndFree(gpa: std.mem.Allocator, text: []const u8) !void {
    const field = try loadField(gpa, text);
    freeField(gpa, field);
}

test "whichever allocation fails, loadField leaks nothing" {
    try std.testing.checkAllAllocationFailures(std.testing.allocator, loadAndFree, .{roster_text});
}

test "a roster of twelve riders races" {
    const text = roster_text ++ "\n10.0 6.0 Iterator\n9.7 6.6 Join\n10.5 5.5 Keyword\n9.9 6.1 Lambda";
    const field = try loadField(std.testing.allocator, text);
    defer freeField(std.testing.allocator, field);
    try std.testing.expectEqual(@as(usize, 12), field.len);
    var race = try Race.fromField(.{ .name = "Flat Kilometre", .distance_m = 1000 }, field);
    var events: [16]Event = undefined;
    while (!race.done()) _ = race.step(&events);
    try std.testing.expectEqual(@as(?u8, 'K'), race.winner); // Keyword is the fastest on the flat
}

test "a course can have any number of segments" {
    var text: [20 * 9]u8 = undefined; // "flat 100\n" twenty times
    for (0..20) |i| @memcpy(text[i * 9 ..][0..9], "flat 100\n");
    const course = try parseCourse(std.testing.allocator, "Long", &text);
    defer std.testing.allocator.free(course.segments);
    try std.testing.expectEqual(@as(usize, 20), course.segments.len);
    try std.testing.expectEqual(@as(f64, 2000), course.distance_m);
}

test "a race needs at least one rider" {
    var none: [0]Rider = .{};
    try std.testing.expectError(error.NoRiders, Race.fromField(test_course, &none));
}

test "two wins for the same name count two" {
    const gpa = std.testing.allocator;
    var standings: Standings = .empty;
    defer freeStandings(gpa, &standings);
    try recordWin(gpa, &standings, "Heap");
    try recordWin(gpa, &standings, "Heap");
    try std.testing.expectEqual(@as(?u32, 2), standings.get("Heap"));
}

test "a name with no wins isn't in the standings" {
    const gpa = std.testing.allocator;
    var standings: Standings = .empty;
    defer freeStandings(gpa, &standings);
    try recordWin(gpa, &standings, "Heap");
    try std.testing.expectEqual(@as(?u32, null), standings.get("Buffer"));
}

test "the standings keep their own copy of each name" {
    const gpa = std.testing.allocator;
    var standings: Standings = .empty;
    defer freeStandings(gpa, &standings);
    var line = "Heap".*; // a name in a buffer that gets reused, like a field freed after its race
    try recordWin(gpa, &standings, &line);
    line = "Junk".*;
    try std.testing.expectEqual(@as(?u32, 1), standings.get("Heap"));
}

test "the standings print most wins first" {
    const gpa = std.testing.allocator;
    var standings: Standings = .empty;
    defer freeStandings(gpa, &standings);
    try recordWin(gpa, &standings, "Buffer");
    try recordWin(gpa, &standings, "Heap");
    try recordWin(gpa, &standings, "Heap");
    var buf: [128]u8 = undefined;
    var w: std.Io.Writer = .fixed(&buf);
    try printStandings(gpa, &w, &standings);
    try std.testing.expectEqualStrings("standings:\n  2  Heap\n  1  Buffer\n", w.buffered());
}

test "yes means race again" {
    try std.testing.expect(wantsMore("y"));
    try std.testing.expect(wantsMore("Yes"));
    try std.testing.expect(!wantsMore("n"));
    try std.testing.expect(!wantsMore(""));
    try std.testing.expect(!wantsMore(null));
}

test "a whole race leaks nothing, and its winner is in the standings" {
    const gpa = std.testing.allocator; // fails the test if anything allocated isn't freed
    var standings: Standings = .empty;
    defer freeStandings(gpa, &standings);
    var buf: [8192]u8 = undefined;
    var out: std.Io.Writer = .fixed(&buf);
    try playRace(gpa, &out, &standings, courses[0], 7);
    try playRace(gpa, &out, &standings, courses[1], 7);
    try std.testing.expectEqual(@as(?u32, 1), standings.get("Heap"));
    try std.testing.expectEqual(@as(?u32, 1), standings.get("Buffer"));
}

test "a feed under its size keeps every line, in order" {
    var buf: [3]FeedLine = undefined;
    var feed: Feed = .init(&buf);
    feed.push(1, "{s}", .{"one"});
    feed.push(2, "{s}", .{"two"});
    var lines = feed.lines.iterator();
    try std.testing.expectEqualStrings("one", lines.next().?.text());
    try std.testing.expectEqualStrings("two", lines.next().?.text());
    try std.testing.expect(lines.next() == null);
}

test "a full feed drops the oldest line, and keeps the newest, oldest first" {
    var buf: [3]FeedLine = undefined;
    var feed: Feed = .init(&buf);
    for (1..6) |i| feed.push(@intCast(i), "line {d}", .{i}); // five lines into three places
    try std.testing.expectEqual(@as(usize, 3), feed.lines.len);
    var lines = feed.lines.iterator();
    try std.testing.expectEqualStrings("line 3", lines.next().?.text());
    try std.testing.expectEqualStrings("line 4", lines.next().?.text());
    try std.testing.expectEqualStrings("line 5", lines.next().?.text());
}

test "a line too long for the feed is cut, not overflowed" {
    var buf: [1]FeedLine = undefined;
    var feed: Feed = .init(&buf);
    const long: [100]u8 = @splat('x');
    feed.push(2, "{s}", .{&long});
    var lines = feed.lines.iterator();
    try std.testing.expectEqual(@as(usize, FeedLine.max_len), lines.next().?.text().len);
}

test "marks come out in distance order, whatever order they went in" {
    const gpa = std.testing.allocator;
    var marks: MarkQueue = .empty;
    defer marks.deinit(gpa);
    try marks.push(gpa, .{ .at_m = 3000, .kind = .km });
    try marks.push(gpa, .{ .at_m = 6000, .kind = .climb_top });
    try marks.push(gpa, .{ .at_m = 1000, .kind = .km });
    try std.testing.expectEqual(@as(f64, 1000), marks.pop().?.at_m);
    try std.testing.expectEqual(@as(f64, 3000), marks.pop().?.at_m);
    try std.testing.expectEqual(@as(f64, 6000), marks.pop().?.at_m);
    try std.testing.expect(marks.pop() == null);
}

test "two marks at the same metre come out in a fixed order" {
    const gpa = std.testing.allocator;
    var marks: MarkQueue = .empty;
    defer marks.deinit(gpa);
    try marks.push(gpa, .{ .at_m = 4000, .kind = .climb_start });
    try marks.push(gpa, .{ .at_m = 4000, .kind = .km });
    try std.testing.expectEqual(MarkKind.km, marks.pop().?.kind);
    try std.testing.expectEqual(MarkKind.climb_start, marks.pop().?.kind);
}

test "Compile Pass is marked: every km, the climb, and 1 km to go" {
    const gpa = std.testing.allocator;
    const course = try parseCourse(gpa, "Compile Pass", compile_pass_text);
    defer gpa.free(course.segments);
    var marks = try planMarks(gpa, course);
    defer marks.deinit(gpa);
    try std.testing.expectEqual(@as(usize, 12 + 2 + 1), marks.count());
}

test "a step past two marks reports both" {
    var field: [8]Rider = undefined;
    const course: Course = .{ .name = "Test Loop", .distance_m = 5000 };
    var race = Race.init(&field, course, &.{2100}, &.{});
    race.marks = try planMarks(std.testing.allocator, course);
    defer race.marks.deinit(std.testing.allocator);
    var buf: [16]Event = undefined;
    const events = race.step(&buf);
    try std.testing.expect(hasEvent(events, .{ .mark = .{ .at_m = 1000, .kind = .km } }));
    try std.testing.expect(hasEvent(events, .{ .mark = .{ .at_m = 2000, .kind = .km } }));
}

test "a mark's label says what it is" {
    var buf: [24]u8 = undefined;
    try std.testing.expectEqualStrings("km 7", (Mark{ .at_m = 7000, .kind = .km }).label(&buf));
    try std.testing.expectEqualStrings("1 km to go", (Mark{ .at_m = 11500, .kind = .to_go }).label(&buf));
}

test "the race order is right after every step of a whole race" {
    const gpa = std.testing.allocator;
    const course = try parseCourse(gpa, "Compile Pass", compile_pass_text);
    defer gpa.free(course.segments);
    const field = try loadField(gpa, roster_text);
    defer freeField(gpa, field);
    var race = try Race.fromField(course, field);
    try race.trackOrder(gpa);
    defer gpa.free(race.order);
    var expected: [8]usize = undefined;
    var events: [16]Event = undefined;
    while (!race.done()) {
        _ = race.step(&events);
        for (&expected, 0..) |*e, i| e.* = i;
        std.mem.sort(usize, &expected, race.riders, aheadOf); // a fresh, full sort to compare with
        try std.testing.expectEqualSlices(usize, &expected, race.order);
    }
}

test "riders level on the road keep letter order" {
    var field: [8]Rider = undefined;
    var race = Race.init(&field, test_course, &.{ 10, 10, 12 }, &.{});
    try race.trackOrder(std.testing.allocator);
    defer std.testing.allocator.free(race.order);
    var events: [16]Event = undefined;
    _ = race.step(&events);
    try std.testing.expectEqual(@as(usize, 2), race.order[0]); // C, at 12 m/s, leads
    try std.testing.expectEqual(@as(usize, 0), race.order[1]); // then A and B, level, A first
    try std.testing.expectEqual(@as(usize, 1), race.order[2]);
}

test "the results list every rider once, leader first" {
    var field: [8]Rider = undefined;
    var race = Race.init(&field, test_course, &.{ 10, 12, 9 }, &.{});
    try race.trackOrder(std.testing.allocator);
    defer std.testing.allocator.free(race.order);
    var events: [16]Event = undefined;
    while (!race.done()) _ = race.step(&events);
    var buf: [1024]u8 = undefined;
    var w: std.Io.Writer = .fixed(&buf);
    try printResults(&w, &race);
    try std.testing.expect(std.mem.startsWith(u8, w.buffered(), "results:\n   1  B "));
    try std.testing.expectEqual(@as(usize, 1 + 8), std.mem.count(u8, w.buffered(), "\n"));
}

// #region tests
/// The old way, one segment at a time: what binary search must agree with.
fn terrainAtLinear(course: Course, position_m: f64) Terrain {
    var gradient_pct: f64 = 0;
    for (course.segments) |segment| {
        if (segment.start_m <= position_m) gradient_pct = segment.gradient_pct;
    }
    return Terrain.of(gradient_pct);
}

test "binary search agrees with a linear scan at every boundary of Compile Pass" {
    const gpa = std.testing.allocator;
    const course = try parseCourse(gpa, "Compile Pass", compile_pass_text);
    defer gpa.free(course.segments);
    for ([_]f64{ -1, 0, 1, 3999.9, 4000, 4000.1, 5999.9, 6000, 7999.9, 8000, 12_499, 12_500, 20_000 }) |at_m| {
        try std.testing.expectEqual(terrainAtLinear(course, at_m), course.terrainAt(at_m));
    }
}

test "binary search agrees with a linear scan on a course of 1000 segments" {
    var segments: [1000]Segment = undefined;
    for (&segments, 0..) |*segment, i| {
        const gradients = [_]f64{ 0, 6, -6, 2 };
        segment.* = .{ .start_m = @floatFromInt(i * 10), .gradient_pct = gradients[i % 4] };
    }
    const course: Course = .{ .name = "Long", .distance_m = 10_000, .segments = &segments };
    var at_m: f64 = -5;
    while (at_m < 10_010) : (at_m += 2.5) {
        try std.testing.expectEqual(terrainAtLinear(course, at_m), course.terrainAt(at_m));
    }
}

test "the segment index: none before the start, the last past the end" {
    const segments = [_]Segment{ .{ .start_m = 0, .gradient_pct = 0 }, .{ .start_m = 100, .gradient_pct = 5 } };
    const course: Course = .{ .name = "Two", .distance_m = 200, .segments = &segments };
    try std.testing.expectEqual(@as(?usize, null), course.segmentAt(-1));
    try std.testing.expectEqual(@as(?usize, 0), course.segmentAt(99.9));
    try std.testing.expectEqual(@as(?usize, 1), course.segmentAt(100));
    try std.testing.expectEqual(@as(?usize, 1), course.segmentAt(500));
}
// #endregion tests
