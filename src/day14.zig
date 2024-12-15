const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("data/day14.txt");

pub fn main() !void {
    print("part1: {any}\n", .{safetyFactor(data, 101, 103)});
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

fn safetyFactor(posl: []const u8, wide: i64, high: i64) !u64 {
    const len: u64 = @intCast(wide * high);
    const botMap = try gpa.alloc(u64, len);
    const seconds: u8 = 100;
    for (botMap, 0..) |_, i| {
        botMap[i] = 0;
    }
    var lineIt = splitSca(u8, posl, '\n');
    while (lineIt.next()) |line| {
        if (line.len < 2) continue;
        print("{s}\n", .{line});
        var wordIt = splitSca(u8, line, ' ');
        var posStr = wordIt.next().?;
        const start_x = try parseInt(i64, posStr[2..indexOf(u8, posStr, ',').?], 10);
        const start_y = try parseInt(i64, posStr[indexOf(u8, posStr, ',').? + 1 ..], 10);
        //print("start: [{d},{d}] ", .{ start_x, start_y });
        const velStr = wordIt.next().?;
        const vel_x_str = velStr[2..indexOf(u8, velStr, ',').?];
        const vel_x = try parseInt(i64, vel_x_str, 10);
        const vel_y_str = velStr[indexOf(u8, velStr, ',').? + 1 ..];
        const vel_y = try parseInt(i64, vel_y_str, 10);

        const end_x = @mod(start_x + (vel_x * seconds), wide);
        const end_y = @mod(start_y + (vel_y * seconds), high);
        const pos: usize = @intCast(end_x + (wide * end_y));
        //print("-> end[{d},{d}](pos:{d})\n", .{ end_x, end_y, pos });
        botMap[pos] += 1;
    }
    printMap(&botMap, wide);

    var secNums = std.mem.zeroes([4]u64);

    const uwide: usize = @intCast(wide);
    const x_mid = uwide / 2;
    const y_mid = @divFloor(high, 2);
    print("D[{d}|{d}]\n", .{ x_mid, y_mid });
    for (botMap, 0..) |c, i| {
        if (c == 0) {
            continue;
        }
        const y = @divFloor(i, uwide);
        const x = i - y * uwide;
        if (x < x_mid) {
            if (y < y_mid) {
                print("sec0: [{d}]({d},{d})+{d}\n", .{ i, x, y, c });
                secNums[0] += c;
            }
            if (y > y_mid) {
                print("sec2: [{d}]({d},{d})+{d}\n", .{ i, x, y, c });
                secNums[2] += c;
            }
        }
        if (x > x_mid) {
            if (y < y_mid) {
                print("sec1: [{d}]({d},{d})+{d}\n", .{ i, x, y, c });
                secNums[1] += c;
            }
            if (y > y_mid) {
                print("sec3: [{d}]({d},{d})+{d}\n", .{ i, x, y, c });
                secNums[3] += c;
            }
        }
    }

    const sec = secNums[0] * secNums[1] * secNums[2] * secNums[3];
    print("sec:{any}->{d}\n", .{ secNums, sec });

    return sec;
}

fn printMap(map: *const []u64, wide: i64) void {
    for (map.*, 0..) |m, i| {
        const ii: i64 = @intCast(i);
        if (@mod(ii, wide) == 0) {
            print("\n", .{});
        }
        if (m == 0) {
            print(".", .{});
        } else {
            print("{d}", .{m});
        }
    }
}

const example =
    \\p=0,4 v=3,-3
    \\p=6,3 v=-1,-3
    \\p=10,3 v=-1,2
    \\p=2,0 v=2,-1
    \\p=0,0 v=1,3
    \\p=3,0 v=-2,-2
    \\p=7,6 v=-1,-3
    \\p=3,0 v=-1,-2
    \\p=9,3 v=2,3
    \\p=7,3 v=-1,2
    \\p=2,4 v=2,-3
    \\p=9,5 v=-3,-3
;

test "part1 example" {
    try std.testing.expectEqual(12, safetyFactor(example, 11, 7));
}
