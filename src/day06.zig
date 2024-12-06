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

    // find start
    var pos = indexOfAny(u8, map, "^").?;
    var dir = Dir.u;

    loop: while (pos >= 0 and pos < log.touched.len) {
        log.touched[pos] = dir;
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
        } else {
            pos = next;
        }
    }
    log.printMap(map);
    print("\n[pos:{d} dir: {any}]", .{ pos, dir });
    return log.count();
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
