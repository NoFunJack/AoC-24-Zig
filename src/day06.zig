const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("data/day06.txt");

pub fn main() !void {
    print("part1: {any}\n", .{countSteps(data)});
    print("part2: {any}\n", .{countLoops(data)});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const tokenizeSeq = std.mem.tokenizeSequence;
const tokenizeSca = std.mem.tokenizeScalar;
const splitAny = std.mem.splitAny;
const splitSeq = std.mem.splitSequence;
const splitSca = std.mem.splitScalar;
const indexOf = std.mem.indexOfScalar;
const indexOfAny = std.mem.indexOfAny;
const indexOfStr = std.mem.indexOfPosLinear;
const lastIndexOf = std.mem.lastIndexOfScalar;
const lastIndexOfAny = std.mem.lastIndexOfAny;
const lastIndexOfStr = std.mem.lastIndexOfLinear;
const trim = std.mem.trim;
const sliceMin = std.mem.min;
const sliceMax = std.mem.max;

const parseInt = std.fmt.parseInt;
const parseFloat = std.fmt.parseFloat;

const print = std.debug.print;
const assert = std.debug.assert;

const sort = std.sort.block;
const asc = std.sort.asc;
const desc = std.sort.desc;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.

fn countSteps(map: []const u8) !u64 {
    // init log
    var it = splitAny(u8, map, "\n");
    var log = LocLog.init(map.len, it.peek().?.len + 1);
    defer log.deinit();

    // find start
    var pos = indexOfAny(u8, map, "^").?;
    var dir = Dir.u;

    loop: while (pos >= 0 and pos < log.touched.len and map[pos] != '\n') {
        //print("\npos: {d} prev: {any} next: {any}", .{ pos, log.touched[pos], dir });
        try log.log(pos, dir);
        var next: usize = 0;
        switch (dir) {
            .u => next = std.math.sub(usize, pos, log.width) catch break :loop,
            .r => next = pos + 1,
            .d => next = pos + log.width,
            .l => next = pos - 1,
            else => unreachable,
        }
        if (next < log.touched.len and map[next] == '#') {
            dir = dir.turnRight();
            //print("\nturn-pos: {d} prev: {any} next: {any}", .{ pos, log.touched[pos], dir });
            if (log.touched[pos] == dir) {
                return LogError.loop;
            }
        } else {
            pos = next;
        }
    }
    return log.count();
}
fn countLoops(map: []const u8) !u64 {
    var loops: u64 = 0;
    for (map, 0..) |start, i| {
        if (start != '.') continue;
        var mapWithObst = try gpa.alloc(u8, map.len);
        defer gpa.free(mapWithObst);
        std.mem.copyForwards(u8, mapWithObst, map);
        mapWithObst[i] = '#';

        //print("\nADDED {d}\n", .{i});
        //print("\nADDED\n {s}\n", .{mapWithObst});
        if (countSteps(mapWithObst)) |ignore| {
            _ = ignore;
        } else |err| switch (err) {
            LogError.loop => loops += 1,
            else => unreachable,
        }
    }

    return loops;
}

const LocLog = struct {
    touched: []Dir,
    width: u64,

    pub fn init(size: u64, width: u64) LocLog {
        var t = gpa.alloc(Dir, size) catch unreachable;
        for (t, 0..) |_, i| {
            t[i] = Dir.x;
        }
        return LocLog{
            .touched = t,
            .width = width,
        };
    }

    pub fn deinit(self: *LocLog) void {
        gpa.free(self.touched);
    }

    pub fn printMap(self: LocLog, map: []const u8) void {
        print("\n", .{});
        for (self.touched, 0..) |t, i| {
            switch (t) {
                .u => print("^", .{}),
                .d => print("v", .{}),
                .l => print("<", .{}),
                .r => print(">", .{}),
                .x => print("{c}", .{map[i]}),
            }
        }
    }

    pub fn log(self: LocLog, pos: usize, dir: Dir) !void {
        //print("pos: {d} prev: {any} next: {any}", .{ pos, self.touched[pos], dir });
        if (pos < self.touched.len and self.touched[pos] == dir) {
            return LogError.loop;
        } else {
            if (self.touched[pos] == Dir.x) {
                self.touched[pos] = dir;
            }
        }
    }

    pub fn count(self: LocLog) u64 {
        var re: u64 = 0;
        for (self.touched) |t| {
            if (t != Dir.x) {
                re += 1;
            }
        }
        return re;
    }
};

const LogError = error{loop};

const Dir = enum {
    u,
    d,
    l,
    r,
    x,

    pub fn turnRight(self: Dir) Dir {
        switch (self) {
            .u => return Dir.r,
            .d => return Dir.l,
            .l => return Dir.u,
            .r => return Dir.d,
            .x => unreachable,
        }
    }
};

const exampleMap =
    \\....#.....
    \\.........#
    \\..........
    \\..#.......
    \\.......#..
    \\..........
    \\.#..^.....
    \\........#.
    \\#.........
    \\......#...
;

test "part1 example" {
    try std.testing.expectEqual(41, countSteps(exampleMap));
}
test "part2 example" {
    try std.testing.expectEqual(6, countLoops(exampleMap));
}

test "detect small loop" {
    const loopy =
        \\.#...
        \\...#.
        \\#....
        \\.^#..
    ;
    try std.testing.expectError(LogError.loop, countSteps(loopy));
}
