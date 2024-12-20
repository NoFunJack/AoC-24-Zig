const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("data/day17.txt");

pub fn main() !void {
    var c = Comp.init(34615120, 0, 0);
    var input = [_]u3{ 2, 4, 1, 5, 7, 5, 1, 6, 0, 3, 4, 3, 5, 5, 3, 0 };
    const out = try c.compute(&input);
    print("part1: {any}\n", .{out.items});

    var i: u64 = 0;
    while (i < 0o1) {
        if (@mod(i, 8) == 0) print("\n", .{});
        var c2 = Comp.init(i, 0, 0);
        const out2 = try c2.compute(&input);

        print("{o}: {any}:", .{ i, out2.items });
        i += 1;
    }

    var x: u64 = 0;
    var y: u64 = 0;
    while (x <= 64) {
        y = 0;
        while (y < 7) {
            y += 1;
            print("{o}/{o}={o}\n", .{ x, y, try std.math.divTrunc(u64, x, y) });
        }
        x += 1;
    }

    const solution = 0o1;
    var c3 = Comp.init(solution, 0, 0);
    const out3 = try c3.compute(&input);

    print("\npart2:\nexp: {any}\nact: {any}\na:{d}", .{ input, out3.items, solution });
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

const Comp = struct {
    regA: u64,
    regB: u64,
    regC: u64,
    ptr: usize = 0,

    pub fn init(a: u64, b: u64, c: u64) Comp {
        return Comp{
            .regA = a,
            .regB = b,
            .regC = c,
        };
    }

    pub fn compute(self: *Comp, programm: []const u3) !List(u3) {
        var outl = List(u3).init(gpa);

        // print("COMP: {any}\n", .{self});
        while (self.ptr + 1 < programm.len) {
            const instrId = programm[self.ptr];
            const opId = programm[self.ptr + 1];
            // print("COMP: {any} OUT: {any}\n", .{ self, outl.items });
            // print("IntrId: {d}, opId: {d}\n", .{ instrId, opId });
            self.ptr += 2;

            const combiVal = self.readComboVal(opId);
            // print("-> val: {d}\n", .{combiVal});
            try self.do(instrId, &outl, combiVal, opId);
        }

        return outl;
    }

    fn readComboVal(self: *Comp, opId: u3) u64 {
        return switch (opId) {
            0, 1, 2, 3 => opId,
            4 => self.regA,
            5 => self.regB,
            6 => self.regC,
            7 => 99999,
        };
    }

    fn do(self: *Comp, iId: u3, out: *List(u3), combiVal: u64, litVal: u3) !void {
        switch (iId) {
            0 => self.adv(combiVal),
            1 => self.bxl(litVal),
            2 => self.bst(combiVal),
            3 => self.jnz(litVal),
            4 => self.xbc(),
            5 => try outFn(&out.*, combiVal),
            7 => self.cdv(combiVal),
            else => unreachable,
        }
    }

    fn adv(self: *Comp, val: u64) void {
        const re = @divTrunc(self.regA, exp2(val));
        self.regA = re;
    }
    fn cdv(self: *Comp, val: u64) void {
        const re = @divTrunc(self.regA, exp2(val));
        // print("DEBUG: {d}/{d}={d}\n", .{ self.regA, val, re });
        self.regC = re;
    }

    fn bst(self: *Comp, val: u64) void {
        self.regB = @mod(val, 8);
    }
    fn bxl(self: *Comp, val: u64) void {
        self.regB = self.regB ^ val;
    }
    fn jnz(self: *Comp, val: u64) void {
        if (self.regA != 0) {
            self.ptr = val;
            // print("Pointer to: {d}\n", .{self.ptr});
        }
    }
    fn xbc(self: *Comp) void {
        const result = self.regB ^ self.regC;
        // print("{b}\n{b}\n{b}", .{ self.regB, self.regB, result });
        self.regB = result;
    }
    fn outFn(out: *List(u3), val: u64) !void {
        const mod: u3 = @intCast(@mod(val, 8));
        try out.append(mod);
    }
};

fn exp2(e: u64) u64 {
    var re: u64 = 1;
    var c = e;
    while (c > 0) {
        re *= 2;
        c -= 1;
    }
    return re;
}
fn eigenProgramm(prog: []const u3) !u64 {
    var x: u64 = 1;
    var a: u64 = 0;
    while (true) {
        print("\n", .{});

        const matches = try eigenscore(a, prog, true);
        const mLen = matches.len;
        print("a: {b}[{d}] x: {b}[{d}] matches: {any}\n", .{ a, a, x, std.math.log2_int(u64, x), matches });
        if (mLen == prog.len) {
            return a;
        }

        // find bigest save bit
        {
            if (mLen >= 2) {
                var shift: u64 = 0;
                var y: u64 = undefined;
                const abits = mLen * 3 + 1;
                while (shift <= mLen * 3) {
                    shift += 3;
                    y = exp2(abits - shift);
                    const a1 = y ^ a;
                    const shiftMatches = try eigenscore(a1, prog, false);
                    print("Find save: y:{b} a1: {b} sm: {any}\n", .{ y, a1, shiftMatches });
                    if (shiftMatches.len != mLen) {
                        break;
                    }
                    if (shiftMatches[mLen - 1] == matches[mLen - 1]) {
                        if (shiftMatches[mLen - 2] != matches[mLen - 2]) {
                            x = y;
                            break;
                        }
                    }
                }
                //if (y > x * 2)
            }
        }

        a += x;
        if (a > 400) unreachable;
    }
    unreachable;
}

fn eigenscore(a: u64, prog: []const u3, dbg: bool) ![]const u3 {
    var c = Comp.init(a, 0, 0);
    const out = try c.compute(prog);

    return listEqualItems(prog, out.items, dbg);
}

fn listEqualItems(a: []const u3, b: []const u3, dbg: bool) []const u3 {
    if (dbg) print("compare: \n{any}\n{any}\n", .{ a, b });
    if (a.len < b.len) unreachable;
    for (a, 0..) |_, i| {
        if (i >= b.len) {
            return a[0..i];
        }
        if (a[i] != b[i]) {
            return a[0..i];
        }
    }
    return a;
}

test "part1 examples mod c->b" {
    var c = Comp.init(0, 0, 9);
    var input = [_]u3{ 2, 6 };
    _ = try c.compute(&input);
    try std.testing.expectEqual(1, c.regB);
}
test "part1 examples out" {
    var c = Comp.init(10, 0, 0);
    var input = [_]u3{ 5, 0, 5, 1, 5, 4 };
    const out = try c.compute(&input);
    const expected = [_]u3{ 0, 1, 2 };
    try std.testing.expectEqualSlices(u3, &expected, out.items);
}
test "part1 examples intr pointer" {
    var c = Comp.init(2024, 0, 0);
    var input = [_]u3{ 0, 1, 5, 4, 3, 0 };
    const out = try c.compute(&input);
    const expected = [_]u3{ 4, 2, 5, 6, 7, 7, 7, 7, 3, 1, 0 };
    try std.testing.expectEqualSlices(u3, &expected, out.items);
    try std.testing.expectEqual(0, c.regA);
}

test "part1 examples xor B" {
    var c = Comp.init(0, 29, 0);
    var input = [_]u3{ 1, 7 };
    _ = try c.compute(&input);
    try std.testing.expectEqual(26, c.regB);
}
test "part1 examples xor C" {
    var c = Comp.init(0, 2024, 43690);
    var input = [_]u3{ 4, 0 };
    _ = try c.compute(&input);
    try std.testing.expectEqual(44354, c.regB);
}
test "part1 example" {
    var c = Comp.init(729, 0, 0);
    var input = [_]u3{ 0, 1, 5, 4, 3, 0 };
    const out = try c.compute(&input);
    const expected = [_]u3{ 4, 6, 3, 5, 6, 3, 5, 2, 1, 0 };
    try std.testing.expectEqualSlices(u3, &expected, out.items);
}

test "part2 example" {
    const input = [_]u3{ 0, 3, 5, 4, 3, 0 };
    try std.testing.expectEqual(117440, eigenProgramm(&input));
}

test "part2 debug" {
    var c = Comp.init(117440, 0, 0);
    const input = [_]u3{ 0, 3, 5, 4, 3, 0 };
    const out = try c.compute(&input);
    try std.testing.expectEqualSlices(u3, &input, out.items);
}
