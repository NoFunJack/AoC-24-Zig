const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("data/day03.txt");

pub fn main() !void {
    print("\npart1: {any}\n", .{calc_input(data)});
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

fn calc_input(input: []const u8) !u64 {
    print("\n\n{s}\n", .{input});
    var calc: Caluclator = .{};

    for (input) |c| {
        calc.read(c);
    }
    print("\n", .{});
    return calc.sum;
}

const Caluclator = struct {
    sum: u64 = 0,
    state: CalcState = CalcState.init,
    i: usize = 0,
    first: NumBuffer = .{},
    second: NumBuffer = .{},
    enabled: bool = true,

    const prefix = "mul(";
    const do = "do";
    const par = "()";
    const nt = "n't()";

    pub fn read(self: *Caluclator, char: u8) void {
        switch (self.state) {
            .init => {
                if (prefix[self.i] == char) {
                    print("p", .{});
                    self.i += 1;
                    self.state = CalcState.prefix_mul;
                    return;
                } else if (do[self.i] == char) {
                    print("d", .{});
                    self.i += 1;
                    self.state = CalcState.prefix_do;
                    return;
                } else {
                    print("_", .{});
                    self.reset(char);
                    return;
                }
            },
            .prefix_mul => {
                if (prefix[self.i] == char) {
                    self.i += 1;
                    if (self.i == prefix.len) {
                        self.state = CalcState.first_num;
                    }
                    print("p", .{});
                    return;
                } else {
                    print("_", .{});
                    self.reset(char);
                    return;
                }
            },
            .prefix_do => {
                if (self.i == do.len) {
                    self.i = 0;
                    if (par[0] == char) {
                        self.state = CalcState.prefix_do_par;
                        self.i = 1;
                        print("y", .{});
                        return;
                    }
                    if (nt[0] == char) {
                        self.state = CalcState.prefix_do_not;
                        self.i = 1;
                        print("n", .{});
                        return;
                    }
                }
                if (do[self.i] == char) {
                    self.i += 1;
                    print("d", .{});
                    return;
                } else {
                    print("_", .{});
                    self.reset(char);
                    return;
                }
            },
            .prefix_do_par => {
                if (par[self.i] == char) {
                    self.i += 1;
                    if (self.i == par.len) {
                        self.enabled = true;
                        self.reset(char);
                        print("Y", .{});
                    } else {
                        print("y", .{});
                    }
                    return;
                } else {
                    print("_", .{});
                    self.reset(char);
                    return;
                }
            },
            .prefix_do_not => {
                if (nt[self.i] == char) {
                    self.i += 1;
                    if (self.i == nt.len) {
                        self.enabled = false;
                        self.reset(char);
                        print("N", .{});
                    } else {
                        print("n", .{});
                    }
                    return;
                } else {
                    print("_", .{});
                    self.reset(char);
                    return;
                }
            },

            .first_num => {
                if (self.first.addChar(char)) {
                    print("1", .{});
                    return;
                } else |err| switch (err) {
                    NaNError.nan => {
                        if (char == ',') {
                            print("K", .{});
                            self.state = CalcState.second_num;
                            return;
                        } else {
                            self.reset(char);
                        }
                    },
                    NaNError.bufferFull => self.reset(char),
                }
            },
            .second_num => {
                if (self.second.addChar(char)) {
                    print("2", .{});
                    return;
                } else |err| switch (err) {
                    NaNError.nan => {
                        if (char == ')') {
                            print("s", .{});
                            try self.multi();
                            self.reset(char);
                            return;
                        } else {
                            self.reset(char);
                        }
                    },
                    NaNError.bufferFull => self.reset(char),
                }
            },
        }

        print("{c}", .{char});
    }

    fn reset(self: *Caluclator, c: u8) void {
        self.state = CalcState.init;
        self.i = 0;
        self.first = .{};
        self.second = .{};
        if (c == prefix[0]) self.read(c);
    }

    fn multi(self: *Caluclator) !void {
        if (self.enabled) {
            const a = self.first.val() * self.second.val();
            //print("[{d}]", .{a});
            self.sum += a;
        }
    }
};

const CalcState = enum {
    init,
    prefix_mul,
    prefix_do,
    prefix_do_par,
    prefix_do_not,
    first_num,
    second_num,
};

const NumBuffer = struct {
    buff: [3]u8 = .{ 0, 0, 0 },
    i: usize = 0,

    fn addChar(self: *NumBuffer, c: u8) NaNError!void {
        if (util.charIsNum(c)) {
            self.buff[self.i] = c;
            self.i += 1;
        } else {
            return NaNError.nan;
        }
    }

    fn val(self: *NumBuffer) u64 {
        return std.fmt.parseUnsigned(u64, self.buff[0..self.i], 10) catch unreachable;
    }
};

const NaNError = error{
    nan,
    bufferFull,
};

test "single multi" {
    try std.testing.expectEqual(2024, calc_input("mul(44,46)"));
}
test "part1 example" {
    const in = "xmul(2,4)%&mul[3,7]!@^do_not_mul(5,5)+mul(32,64]then(mul(11,8)mul(8,5))";
    try std.testing.expectEqual(161, calc_input(in));
}
test "part2 example" {
    const in = "xmul(2,4)&mul[3,7]!^don't()_mul(5,5)+mul(32,64](mul(11,8)undo()?mul(8,5))";
    try std.testing.expectEqual(48, calc_input(in));
}
