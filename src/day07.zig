const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("data/day07.txt");

pub fn main() !void {
    print("part1 {any}\n", .{countSolvable(data)});
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
fn countSolvable(list: []const u8) !u64 {
    var sum: u64 = 0;
    var lineIt = tokenizeAny(u8, list, "\n");
    line_loop: while (lineIt.next()) |line| {
        // read result
        const colPos = indexOf(u8, line, ':') orelse unreachable;
        const result = try util.readUnsign(line[0..colPos]);
        print("r: {d}\n", .{result});

        // read params
        var paramIt = tokenizeAny(u8, line[colPos + 1 ..], " ");
        var params = List(u64).init(gpa);
        defer params.deinit();
        while (paramIt.next()) |p| {
            try params.append(try util.readUnsign(p));
        }
        print("p: {any}\n", .{params.items});

        // try find operand combi
        var opIt = try OpIt.init(params.items.len - 1);
        while (opIt.next()) |ops| {
            const calcResult = calc(params.items, ops);
            if (calcResult == result) {
                print("found: {any}\n\n", .{ops});
                sum += result;
                continue :line_loop;
            }
        }
        print("no combi\n\n", .{});
    }

    return sum;
}

fn calc(params: []u64, ops: []Op) u64 {
    assert(params.len - 1 == ops.len);
    var x = params[0];
    for (ops, 1..) |o, i| {
        switch (o) {
            .plus => x += params[i],
            .mult => x *= params[i],
        }
    }
    return x;
}

const OpIt = struct {
    ops: []Op,
    first: bool = true,
    pub fn init(len: usize) !OpIt {
        const ops = gpa.alloc(Op, len) catch unreachable;
        for (ops, 0..) |_, i| {
            ops[i] = Op.plus;
        }
        return OpIt{
            .ops = ops,
        };
    }

    pub fn deinit(self: *OpIt) !void {
        gpa.free(self.ops);
    }

    pub fn next(self: *OpIt) ?[]Op {
        if (self.first) {
            self.first = false;
            return self.ops;
        }

        for (self.ops, 0..) |o, i| {
            if (o.next()) |n| {
                self.ops[i] = n;
                return self.ops;
            } else {
                if (i == self.ops.len - 1) {
                    return null;
                }
                self.ops[i] = Op.plus;
            }
        }
        unreachable;
    }
};

const Op = enum {
    plus,
    mult,

    pub fn next(self: Op) ?Op {
        return switch (self) {
            .plus => Op.mult,
            .mult => null,
        };
    }
};

const exImput =
    \\190: 10 19
    \\3267: 81 40 27
    \\83: 17 5
    \\156: 15 6
    \\7290: 6 8 6 15
    \\161011: 16 10 13
    \\192: 17 8 14
    \\21037: 9 7 18 13
    \\292: 11 6 16 20
;

test "part1 example" {
    try std.testing.expectEqual(3749, countSolvable(exImput));
}

test "op-Iterator" {
    var it = try OpIt.init(3);

    try std.testing.expectEqualSlices(Op, &[_]Op{ .plus, .plus, .plus }, it.next().?);
    try std.testing.expectEqualSlices(Op, &[_]Op{ .mult, .plus, .plus }, it.next().?);
    try std.testing.expectEqualSlices(Op, &[_]Op{ .plus, .mult, .plus }, it.next().?);
    try std.testing.expectEqualSlices(Op, &[_]Op{ .mult, .mult, .plus }, it.next().?);
    try std.testing.expectEqualSlices(Op, &[_]Op{ .plus, .plus, .mult }, it.next().?);
    try std.testing.expectEqualSlices(Op, &[_]Op{ .mult, .plus, .mult }, it.next().?);
    try std.testing.expectEqualSlices(Op, &[_]Op{ .plus, .mult, .mult }, it.next().?);
    try std.testing.expectEqualSlices(Op, &[_]Op{ .mult, .mult, .mult }, it.next().?);
    try std.testing.expectEqual(null, it.next());
}
