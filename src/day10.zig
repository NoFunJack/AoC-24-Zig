const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("data/day10.txt");

pub fn main() !void {
    print("part1: {any}\n", .{scoreMap(data)});
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

fn scoreMap(mapStr: []const u8) !u64 {
    var map = List(u8).init(gpa);
    defer map.deinit();
    var it = tokenizeSca(u8, mapStr, '\n');
    const width = it.peek().?.len;
    while (it.next()) |line| {
        try map.appendSlice(line);
    }

    const score = try gpa.alloc(u64, map.items.len);
    defer gpa.free(score);
    for (score, 0..) |_, ri| {
        score[ri] = 0;
    }

    for (map.items, 0..) |h, i| {
        if (h == '9') {
            var reachables = try gpa.alloc(bool, map.items.len);
            defer gpa.free(reachables);
            for (reachables, 0..) |_, ri| {
                reachables[ri] = false;
            }
            markReachable(map.items, &reachables, i, width);

            for (reachables, 0..) |r, ri| {
                if (r) score[ri] += 1;
            }
        }
    }

    var totalScore: u64 = 0;
    for (map.items, 0..) |h, hi| {
        if (@mod(hi, width) == 0) print("\n", .{});
        print("[{c}:{any}]", .{ h, score[hi] });
        if (h == '0') totalScore += score[hi];
    }
    return totalScore;
}

fn markReachable(map: []const u8, reachable: *[]bool, start: usize, width: usize) void {
    // hook
    if (reachable.*[start]) return else reachable.*[start] = true;

    // >
    var next = start + 1;
    if (@mod(next, width) != 0) {
        if (map[start] - 1 == map[next])
            markReachable(map, reachable, next, width);
    }
    // v
    next = start + width;
    if (next < map.len) {
        if (map[start] - 1 == map[next])
            markReachable(map, reachable, next, width);
    }
    // <
    if (start >= 1 and @mod(start, width) != 0) {
        next = start - 1;
        if (map[start] - 1 == map[next])
            markReachable(map, reachable, next, width);
    }
    // ^
    if (start >= width) {
        next = start - width;
        if (map[start] - 1 == map[next])
            markReachable(map, reachable, next, width);
    }
}

const exampleMap =
    \\89010123
    \\78121874
    \\87430965
    \\96549874
    \\45678903
    \\32019012
    \\01329801
    \\10456732
;

test "part1 example" {
    try std.testing.expectEqual(36, scoreMap(exampleMap));
}

test "split example" {
    const split =
        \\...0...
        \\...1...
        \\...2...
        \\6543456
        \\7.....7
        \\8.....8
        \\9.....9
    ;
    try std.testing.expectEqual(2, scoreMap(split));
}
