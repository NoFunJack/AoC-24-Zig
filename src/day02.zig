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
    print("\n\npart1: {any}\n", .{count_reports(data, 0)});
    print("part2: {any}\n", .{count_reports(data, 1)});
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
fn count_reports(strLists: []const u8, damp: u64) !u64 {
    var it = std.mem.tokenizeAny(u8, strLists, "\n");
    var save_count: u64 = 0;
    line_loop: while (it.next()) |line| {
        print("\n", .{});
        var numIt = tokenizeAny(u8, line, " ");
        // load line
        var nums = std.ArrayList(u64).init(gpa);
        defer nums.deinit();

        while (numIt.next()) |numStr| {
            const num = try std.fmt.parseUnsigned(u64, numStr, 10);
            try nums.append(num);
        }
        if (validate(nums.items)) {
            save_count += 1;
            continue;
        }
        if (damp > 0) {
            for (0..nums.items.len) |i| {
                print("\n >", .{});

                var damp_nums = try nums.clone();
                _ = damp_nums.orderedRemove(i);
                if (validate(damp_nums.items)) {
                    save_count += 1;
                    continue :line_loop;
                }
            }
        }
    }
    print("\n", .{});

    return save_count;
}

fn validate(nums: []u64) bool {
    const up = nums[0] < nums[1];

    for (0..nums.len - 1) |i| {
        print("{d}[{d}] ", .{ nums[i], nums[i + 1] });
        if (diff_ok(nums[i], nums[i + 1])) {
            if (nums[i] < nums[i + 1] and !up) {
                print("{d}⚡^", .{nums[i + 1]});
                return false;
            }
            if (nums[i] > nums[i + 1] and up) {
                print("{d}⚡v", .{nums[i + 1]});
                return false;
            }
        } else {
            print("{d}⚡d", .{nums[i + 1]});
            return false;
        }
    }
    print("OK", .{});
    return true;
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
;
test "part1 example" {
    try std.testing.expectEqual(2, count_reports(testInput, 0));
}
test "part2 example" {
    try std.testing.expectEqual(4, count_reports(testInput, 1));
}
