const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("data/day02.txt");

pub fn main() !void {
    print("\n\npart1: {any}\n", .{part1(data)});
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
    var it = std.mem.tokenizeAny(u8, strLists, "\n");
    var save_count: u64 = 0;
    line_loop: while (it.next()) |line| {
        print("\n", .{});
        var numIt = tokenizeAny(u8, line, " ");
        const first = try std.fmt.parseUnsigned(u64, numIt.next().?, 10);
        const second = try std.fmt.parseUnsigned(u64, numIt.next().?, 10);
        if (!diff_ok(first, second)) {
            continue :line_loop;
        }
        var prev: u64 = second;
        const up = first < second;
        print("{s} ", .{if (up) "u" else "d"});
        print("{d} {d} ", .{ first, second });
        while (numIt.next()) |numStr| {
            const num = try std.fmt.parseUnsigned(u64, numStr, 10);
            print("{d} ", .{num});
            if (prev < num) {
                print("^", .{});
                if (!up or !diff_ok(prev, num)) {
                    print("invalidU: {d},{d}", .{ prev, num });
                    continue :line_loop;
                }
            } else {
                print("v", .{});
                if (up or !diff_ok(prev, num)) {
                    print("invalidD: {d},{d}", .{ prev, num });
                    continue :line_loop;
                }
            }
            prev = num;
        }
        print("✓", .{});
        save_count += 1;
    }

    return save_count;
}

fn diff_ok(prev: u64, curr: u64) bool {
    var diff: u64 = 0;
    if (prev < curr) {
        diff = curr - prev;
    } else {
        diff = prev - curr;
    }

    return diff >= 1 and diff <= 3;
}

const testInput =
    \\7 6 4 2 1
    \\1 2 7 8 9
    \\9 7 6 2 1
    \\1 3 2 4 5
    \\8 6 4 4 1
    \\1 3 6 7 9
    \\1 3 2 1
;
test "part1 example" {
    try std.testing.expectEqual(2, part1(testInput));
}
test "part2 example" {
    //   try std.testing.expectEqual(31, part2(testInput));
}
