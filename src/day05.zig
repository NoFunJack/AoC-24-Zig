const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("data/day05.txt");

pub fn main() !void {
    print("part1: {any}", .{validate(data, false)});
    print("\npart2: {any}", .{validate(data, true)});
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

fn validate(input: []const u8, fix: bool) !u64 {
    var it = std.mem.splitAny(u8, input, "\n");
    // read rules
    var rules = std.ArrayList([2]u64).init(gpa);
    defer rules.deinit();

    while (it.next()) |line| {
        if (std.mem.eql(u8, "", line)) {
            break;
        }
        var numIt = std.mem.tokenizeAny(u8, line, "|");
        try rules.append([_]u64{ try std.fmt.parseUnsigned(u64, numIt.next().?, 10), try std.fmt.parseUnsigned(u64, numIt.next().?, 10) });
    }
    print("{any}\n", .{rules.items});
    var sum: u64 = 0;
    while (it.next()) |line| {
        const list = try readSections(line);
        if (list.items.len == 0) {
            break;
        }

        if (fix) {
            if (!isValid(list, rules)) {
                fixList(list, rules);
                print("\n{any} < fixed\n", .{list.items});
                const a = list.items[list.items.len / 2];
                print("ADD(fixed):{any}\n", .{a});
                sum += a;
            }
        } else {
            if (isValid(list, rules)) {
                const a = list.items[list.items.len / 2];
                print("\n ADD:{any}\n", .{a});
                sum += a;
            }
        }

        print("\n", .{});
    }
    return sum;
}

fn readSections(line: []const u8) !std.ArrayList(u64) {
    print("{s}\n", .{line});
    var it = std.mem.tokenizeAny(u8, line, ",");
    var list = std.ArrayList(u64).init(gpa);
    while (it.next()) |s| {
        try list.append(try util.readUnsign(s));
    }
    return list;
}

fn isValid(input: List(u64), rules: List([2]u64)) bool {
    for (input.items, 0..) |num, in| {
        print("{d} ", .{num});
        for (rules.items) |r| {
            if (r[1] == num) {
                if (contains(input.items[in..], r[0])) {
                    print("breaks rule {d}|{d}\n", .{ r[0], r[1] });
                    return false;
                }
            }
        }
    }
    return true;
}

fn fixList(input: List(u64), rules: List([2]u64)) void {
    for (input.items, 0..) |num, in| {
        print("{d} ", .{num});
        for (rules.items) |r| {
            if (r[1] == num) {
                if (idxOf(input.items[in..], r[0])) |j| {
                    print("swap rule {d}|{d} [{d},{d}]\n", .{ r[0], r[1], in, in + j });
                    input.items[in] = r[0];
                    input.items[in + j] = r[1];
                    fixList(input, rules);
                    return;
                }
            }
        }
    }
}

fn contains(nums: []u64, needle: u64) bool {
    for (nums) |num| {
        if (num == needle) return true;
    }
    return false;
}
fn idxOf(nums: []u64, needle: u64) ?usize {
    for (nums, 0..) |num, i| {
        if (num == needle) return i;
    }
    return null;
}

const exStr =
    \\47|53
    \\97|13
    \\97|61
    \\97|47
    \\75|29
    \\61|13
    \\75|53
    \\29|13
    \\97|29
    \\53|29
    \\61|53
    \\97|53
    \\61|29
    \\47|13
    \\75|47
    \\97|75
    \\47|61
    \\75|61
    \\47|29
    \\75|13
    \\53|13
    \\
    \\75,47,61,53,29
    \\97,61,53,29,13
    \\75,29,13
    \\75,97,47,61,53
    \\61,13,29
    \\97,13,75,29,47
;

test "part1 example" {
    try std.testing.expectEqual(143, validate(exStr, false));
}
test "part2 example" {
    try std.testing.expectEqual(123, validate(exStr, true));
}
