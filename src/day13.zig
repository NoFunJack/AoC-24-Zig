const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("data/day13.txt");

pub fn main() !void {
    print("total tickets: {any}\n", .{sumCheapMashines(data, 0)});
    print("total tickets plus: {any}\n", .{sumCheapMashines(data, 10000000000000)});
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

fn sumCheapMashines(dataStr: []const u8, plus: i64) !i64 {
    var lineIt = tokenizeSca(u8, dataStr, '\n');
    var sum: i64 = 0;
    while (lineIt.next()) |buttonALine| {
        const ba = try readButtonLine(buttonALine);
        const bb = try readButtonLine(lineIt.next().?);
        var r = try readResultLine(lineIt.next().?);
        r[0] += plus;
        r[1] += plus;

        const num_y = (ba[1] * r[0]) - (ba[0] * r[1]);
        const div_y = (bb[0] * ba[1]) - (ba[0] * bb[1]);
        print("{d}/{d}=", .{ num_y, div_y });
        if (std.math.divExact(i64, num_y, div_y)) |y| {
            print("{d}\n", .{y});
            if (std.math.divExact(i64, r[0] - (y * bb[0]), ba[0])) |x| {
                print("-> x={d}\n", .{x});
                const cost = (y + (3 * x));
                print("-> cost={d}\n", .{cost});
                sum += cost;
            } else |err| {
                print("divX: {any}\n", .{err});
            }
        } else |err| {
            print("divY: {any}\n", .{err});
        }
    }
    return sum;
}

fn readButtonLine(str: []const u8) ![2]i64 {
    const xstr = str[12..14];
    const ystr = str[18..20];
    return .{
        try parseInt(i64, xstr, 10),
        try parseInt(i64, ystr, 10),
    };
}
fn readResultLine(str: []const u8) ![2]i64 {
    const xstr = str[indexOf(u8, str, 'X').? + 2 .. indexOf(u8, str, ',').?];
    const ystr = str[indexOf(u8, str, 'Y').? + 2 ..];
    return .{
        try parseInt(i64, xstr, 10),
        try parseInt(i64, ystr, 10),
    };
}

const example =
    \\Button A: X+94, Y+34
    \\Button B: X+22, Y+67
    \\Prize: X=8400, Y=5400
    \\
    \\Button A: X+26, Y+66
    \\Button B: X+67, Y+21
    \\Prize: X=12748, Y=12176
    \\
    \\Button A: X+17, Y+86
    \\Button B: X+84, Y+37
    \\Prize: X=7870, Y=6450
    \\
    \\Button A: X+69, Y+23
    \\Button B: X+27, Y+71
    \\Prize: X=18641, Y=10279
;

test "part1 example" {
    try std.testing.expectEqual(480, sumCheapMashines(example, 0));
}
