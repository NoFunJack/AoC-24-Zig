const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("data/day01.txt");

pub fn main() void {
    std.debug.print("part1: {any}", .{part1(data)});
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

fn part1(strLists: []const u8) !u64 {
    //std.debug.print("Read file: {s}", .{strLists});

    var listA = std.ArrayList(u64).init(gpa);
    var listB = std.ArrayList(u64).init(gpa);
    defer listA.deinit();
    defer listB.deinit();

    var it = std.mem.tokenizeAny(u8, strLists, "\n");
    while (it.next()) |line| {
        var itNum = std.mem.tokenizeAny(u8, line, "  ");
        const numA = itNum.next().?;
        const numB = itNum.next().?;

        //print("\n{s}: numA: {?s} numB: {?s}", .{ line, numA, numB });

        try listA.append(try std.fmt.parseUnsigned(u64, numA, 10));
        try listB.append(try std.fmt.parseUnsigned(u64, numB, 10));
    }
    //print("\nList A: {any}", .{listA.items});
    //print("\nList B: {any}", .{listB.items});

    std.mem.sort(u64, listA.items, {}, std.sort.asc(u64));
    std.mem.sort(u64, listB.items, {}, std.sort.asc(u64));
    //print("\nsorted List A: {any}", .{listA.items});
    //print("\nsorted List B: {any}", .{listB.items});

    var sum: u64 = 0;
    for (listA.items, listB.items) |a, b| {
        if (a > b) {
            sum += a - b;
        } else {
            sum += b - a;
        }
    }

    return sum;
}

test "example" {
    const input =
        \\3   4
        \\4   3
        \\2   5
        \\1   3
        \\3   9
        \\3   3
    ;
    try std.testing.expectEqual(11, part1(input));
}
