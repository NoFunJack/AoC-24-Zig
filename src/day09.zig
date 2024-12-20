const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("data/day09.txt");

pub fn main() !void {
    print("part1 {any}\n", .{checksumCompressed(data)});
    print("part2 {any}\n", .{checksumDefrag(data)});
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

fn checksumCompressed(input: []const u8) !u64 {
    //print("Input: {c}\n", .{input});
    // string to nums
    var map = try gpa.alloc(u8, input.len);
    defer gpa.free(map);
    for (input, 0..) |c, i| {
        print("i: {d} c:{d}\n", .{ i, c });
        if (c >= 48 and c <= 58)
            map[i] = c - 48;
    }

    var checksum: u64 = 0;
    var lowP: usize = 0;
    var upP: usize = map.len - 1;
    for (map, 0..) |e, i| {
        print("lowP: {d}\n", .{lowP});
        if (@mod(i, 2) == 0) {
            print("Inital Data: {d}\n", .{e});
            print("value {d}\n", .{i / 2});
            // data
            checksum += blockSum(lowP, e) * (i / 2);
            lowP += e;
            // printBlock(map, i, upP);
            // printBlockRaw(map);
        } else {
            if (@mod(upP, 2) == 1) {
                upP -= 1;
            }
            print("upper data: {d}\n", .{map[upP]});
            while (map[i] > 0) {
                print("value {d}\n", .{upP / 2});
                if (map[i] > map[upP]) {
                    print("fits-in-space {d}<-{d}\n", .{ map[i], map[upP] });
                    checksum += blockSum(lowP, map[upP]) * (upP / 2);
                    map[i] -= map[upP];
                    lowP += map[upP];
                    map[upP] = 0;
                    upP -= 2;
                    if (i >= upP) break;
                } else {
                    print("overflow-space {d}<-{d}\n", .{ map[i], map[upP] });
                    map[upP] -= map[i];
                    checksum += blockSum(lowP, map[i]) * (upP / 2);
                    lowP += map[i];
                    map[i] = 0;
                }
                print("sub-checksum: {d}\n", .{checksum});
                // printBlock(map, i, upP);
                // printBlockRaw(map);
            }
        }
        print("checksum: {d}\n\n", .{checksum});
        if (i >= upP) break;
    }

    return checksum;
}

fn checksumDefrag(input: []const u8) !u64 {
    // string to nums
    var map = try gpa.alloc(u8, input.len);
    defer gpa.free(map);
    var cap: usize = 0;
    for (input, 0..) |c, i| {
        //print("i: {d} c:{d}\n", .{ i, c });
        if (c >= 48 and c <= 58) {
            map[i] = c - 48;
            cap += map[i];
        }
    }

    // calc intial checksum
    var checksums = try gpa.alloc(u64, input.len);
    var lowP: usize = 0;
    for (map, 0..) |e, i| {
        if (@mod(i, 2) == 0) {
            // print("Inital Data: {d}\n", .{e});
            // print("value {d}\n", .{i / 2});
            // data
            checksums[i] = blockSum(lowP, e) * (i / 2);
        } else {
            checksums[i] = 0;
        }
        lowP += e;
    }
    print("{any}\n\n", .{checksums});

    // push files down
    var up = map.len - 1;
    const added = try gpa.alloc(u64, input.len);
    @memcpy(added, checksums);
    defer gpa.free(added);
    const org = try gpa.alloc(u8, input.len);
    @memcpy(org, map);
    defer gpa.free(org);
    while (up > 0) {
        if (@mod(up, 2) == 0) {
            if (getFirstFreeSpaceForBlock(map, up)) |to| {
                checksums[up] = 0; // remove from top
                map[to] -= map[up]; // remove free space bottom
                const startIdx = getStartIdx(org, to) + added[to];
                checksums[to] += blockSum(startIdx, map[up]) * (up / 2);
                added[to] += map[up];
            }
        }
        up -= 1;
    }

    var checksum: u64 = 0;
    for (checksums) |a| {
        checksum += a;
    }
    print("{any}", .{checksums});

    return checksum;
}

fn getFirstFreeSpaceForBlock(map: []u8, max: usize) ?usize {
    for (map, 0..) |e, i| {
        if (i >= max) {
            break;
        }
        if (@mod(i, 2) == 1 and e >= map[max]) {
            print("Space found for {d} after {d}\n", .{ max / 2, i / 2 });
            return i;
        }
    }

    print("No Space found for {d}\n", .{max / 2});
    return null;
}

fn getStartIdx(map: []u8, i: usize) usize {
    var idx: usize = 0;

    for (map, 0..) |m, mc| {
        if (mc >= i) break;
        idx += m;
        //print("m: {d} idx:{d} ", .{ m, idx });
    }

    return idx;
}

fn printBlock(input: []u8, d: usize, u: usize) void {
    for (input) |c| {
        print("{d}", .{c});
    }
    print("\n", .{});
    for (input, 0..) |_, i| {
        if (i == d) {
            print("d", .{});
        } else if (i == u) {
            print("u", .{});
        } else {
            print("_", .{});
        }
    }
    print("\n", .{});
}

fn printBlockRaw(input: []u8) void {
    var c: u8 = '0';
    for (input, 0..) |v, i| {
        if (@mod(i, 2) == 0) {
            var j = v;
            while (j > 0) {
                print("{c}", .{c});
                j -= 1;
            }
            c += 1;
        } else {
            var j = v;
            while (j > 0) {
                print(".", .{});
                j -= 1;
            }
        }
    }
    print("\n", .{});
}

fn blockSum(start: usize, length: u8) u64 {
    var re: u64 = 0;
    var i = start;
    while (i < start + length) {
        re += i;
        print("{d}-", .{i});
        i += 1;
    }
    print("base {d} \n", .{re});
    return re;
}

const exampleMap = "2333133121414131402";

// test "example part1" {
//     try std.testing.expectEqual(1928, checksumCompressed(exampleMap));
// }
test "example part2" {
    try std.testing.expectEqual(2858, checksumDefrag(exampleMap));
}
