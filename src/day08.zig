const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("data/day08.txt");

pub fn main() !void {
    print("par1: {any}\n", .{countAntiNodes(data)});
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

fn countAntiNodes(mapStr: []const u8) !u64 {
    var map = List(u8).init(gpa);
    defer map.deinit();
    var lineIt = tokenizeSca(u8, mapStr, '\n');
    const width = lineIt.peek().?.len;

    // read map to get rid of \n
    while (lineIt.next()) |line| {
        try map.appendSlice(line);
    }

    var antiNodeMap = try gpa.alloc(bool, map.items.len);
    defer gpa.free(antiNodeMap);
    for (antiNodeMap, 0..) |_, i| {
        antiNodeMap[i] = false;
    }

    // loops over pairs
    for (map.items, 0..) |c, i| {
        if (c != '.') {
            print("scanning[{c}]\n", .{c});
            for (map.items[(i + 1)..], (i + 1)..) |p, j| {
                if (c == p) {
                    addNodesForPair(i, j, &antiNodeMap, width);
                    debugPrint(&map.items, &antiNodeMap, width);
                    print("count: {d}\n", .{countNodes(&antiNodeMap)});
                }
            }
        }
    }

    return countNodes(&antiNodeMap);
}

fn addNodesForPair(iu: usize, ju: usize, antiNodeMap: *[]bool, width_u: usize) void {
    const i: i128 = iu;
    const j: i128 = ju;
    const width: i128 = width_u;
    print("i:{d} j:{d} width:{d}\n", .{ i, j, width });
    const ix = @mod(i, width);
    const iy = @divFloor(i, width);
    const jx = @mod(j, width);
    const jy = @divFloor(j, width);
    const dx: i128 = jx - ix;
    const dy: i128 = jy - iy;

    // negative vector
    if (ix >= dx and iy >= dy) {
        const idx: usize = @intCast((ix - dx) + (width * (iy - dy)));
        antiNodeMap.*[idx] = true;
    }

    // positive vector
    if (jx + dx < width and (jy + dy) * width < antiNodeMap.len) {
        const idx: usize = @intCast((width * (jy + dy)) + jx + dx);
        antiNodeMap.*[idx] = true;
    }
}

fn debugPrint(map: *[]u8, nodes: *[]bool, width: usize) void {
    for (map.*, nodes.*, 0..) |m, n, i| {
        if (@mod(i, width) == 0) {
            print("\n", .{});
        }
        if (n) {
            print("#", .{});
        } else {
            print("{c}", .{m});
        }
    }
    print("\n", .{});
}

fn countNodes(map: *[]bool) u64 {
    var sum: u64 = 0;
    for (map.*) |b| {
        if (b) sum += 1;
    }
    return sum;
}

const testInput =
    \\............
    \\........0...
    \\.....0......
    \\.......0....
    \\....0.......
    \\......A.....
    \\............
    \\............
    \\........A...
    \\.........A..
    \\............
    \\............
;

test "part1 example" {
    try std.testing.expectEqual(14, countAntiNodes(testInput));
}
test "left" {
    const in =
        \\.......
        \\x..x...
        \\.......
    ;

    try std.testing.expectEqual(1, countAntiNodes(in));
}
test "right" {
    const in =
        \\.......
        \\...x..x
        \\.......
    ;

    try std.testing.expectEqual(1, countAntiNodes(in));
}
test "end" {
    const in =
        \\.......
        \\...x...
        \\......x
    ;

    try std.testing.expectEqual(1, countAntiNodes(in));
}
test "start" {
    const in =
        \\x......
        \\...x...
        \\.......
    ;

    try std.testing.expectEqual(1, countAntiNodes(in));
}
test "lcorner" {
    const in =
        \\......x
        \\...x...
        \\.......
    ;

    try std.testing.expectEqual(1, countAntiNodes(in));
}
test "close" {
    const in =
        \\.......
        \\..xx...
        \\.......
    ;

    try std.testing.expectEqual(2, countAntiNodes(in));
}
test "lost top" {
    const in =
        \\..x....
        \\.......
        \\..x....
        \\.......
    ;

    try std.testing.expectEqual(0, countAntiNodes(in));
}
test "lost lr" {
    const in =
        \\....
        \\.x.x
        \\....
    ;

    try std.testing.expectEqual(0, countAntiNodes(in));
}
test "example two" {
    const in =
        \\..........
        \\..........
        \\..........
        \\....a.....
        \\..........
        \\.....a....
        \\..........
        \\..........
        \\..........
        \\.......... 
    ;

    try std.testing.expectEqual(2, countAntiNodes(in));
}
test "alternating" {
    const in =
        \\...........
        \\.xyxyx.....
        \\..........
    ;

    try std.testing.expectEqual(6, countAntiNodes(in));
}
