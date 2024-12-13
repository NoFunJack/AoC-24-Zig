const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("data/day11.txt");

pub fn main() !void {
    print("part1: {any}\n", .{countStones(data, 25)});
    print("part2: {any}\n", .{countStones(data, 75)});
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

fn countStones(input: []const u8, blinks: u16) !u64 {
    var map = Map(u64, u64).init(gpa);

    {
        var itLine = tokenizeSca(u8, input, '\n');
        var it = tokenizeSca(u8, itLine.next().?, ' ');
        while (it.next()) |numStr| {
            if (util.readUnsign(numStr)) |num| {
                if (map.contains(num)) {
                    const val = map.getPtr(num).?;
                    val.* += 1;
                } else {
                    try map.put(num, 1);
                }
            } else |err| {
                print("{any}", .{err});
            }
        }
    }
    printMap(map);
    var currentBlinks = blinks;
    while (currentBlinks > 0) {
        currentBlinks -= 1;
        print("\n\n**Blinks left: {d}\n", .{currentBlinks});
        var nextMap = Map(u64, u64).init(gpa);
        var it = map.iterator();
        while (it.next()) |kv| {
            const k = kv.key_ptr.*;
            const v = kv.value_ptr.*;
            // print("kv: {d},{d}\n", .{ k, v });
            if (k == 0) {
                try addEntry(&nextMap, 1, v);
            } else if (@mod(std.math.log10_int(k) + 1, 2) == 0) {
                const new = split(k);

                for (new) |n| {
                    try addEntry(&nextMap, n, v);
                }
            } else {
                const mult = k * 2024;
                // print("mult {d}->{d}\n", .{ k, mult });
                try addEntry(&nextMap, mult, v);
            }
            //printMap(nextMap);
        }
        map.deinit();
        // printMap(nextMap);
        map = nextMap;
    }

    return sum(map);
}

fn sum(map: Map(u64, u64)) u64 {
    var re: u64 = 0;
    var vIt = map.valueIterator();
    while (vIt.next()) |v| {
        re += v.*;
    }
    return re;
}

fn split(num: u64) [2]u64 {
    const len = (std.math.log10_int(num) + 1) / 2;

    const pow = std.math.pow(u64, 10, len);
    const r = num / pow;
    const l = @mod(num, r * pow);
    // print("split({d}):  {d}->{d},{d}\n", .{ len, num, r, l });
    return .{ r, l };
}

fn addEntry(map: *Map(u64, u64), k: u64, v: u64) !void {
    if (map.contains(k)) {
        const p = map.getPtr(k).?;
        p.* += v;
    } else {
        try map.put(k, v);
    }
}

fn printMap(map: Map(u64, u64)) void {
    print("---\n", .{});
    var it = map.iterator();
    while (it.next()) |kv| {
        print("{d}: {d}\n", .{ kv.key_ptr.*, kv.value_ptr.* });
    }
    print("sum: {d}\n", .{sum(map)});
    print("---\n", .{});
}

const exampleInput = "125 17";

test "part1 example" {
    try std.testing.expectEqual(55312, countStones(exampleInput, 25));
}
