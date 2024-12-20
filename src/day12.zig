const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("data/day12.txt");

pub fn main() !void {
    print("par1: {any}\n", .{calcCost(data)});
    print("par2: {any}\n", .{calcCostBulk(data)});
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
fn calcCost(mapStr: []const u8) !u64 {
    const plotmap = try buildPlotMap(mapStr);
    defer plotmap.deinit();
    var sum: u64 = 0;
    for (plotmap.items) |p| {
        sum += p.getCost();
    }
    return sum;
}

fn calcCostBulk(mapStr: []const u8) !u64 {
    const plotmap = try buildPlotMap(mapStr);
    defer plotmap.deinit();
    var sum: u64 = 0;
    for (plotmap.items) |p| {
        sum += try p.getCostBulk();
    }
    return sum;
}

fn buildPlotMap(mapStr: []const u8) !List(PlotCluster) {
    var mapList = List(u8).init(gpa);
    var lineIt = splitSca(u8, mapStr, '\n');
    const width = lineIt.peek().?.len;
    while (lineIt.next()) |line| {
        try mapList.appendSlice(line);
    }
    const map = mapList.items;

    var pcl = List(PlotCluster).init(gpa);
    plotLoop: for (map, 0..) |p, i| {
        for (pcl.items) |pc| {
            if (pc.isInPlot(p, i)) continue :plotLoop;
        }
        //print("---New Plot {c} at {d}\n", .{ p, i });

        const plot = try PlotCluster.init(width, p, i, &map);
        try pcl.append(plot);
    }

    return pcl;
}

const PlotCluster = struct {
    plots: []Plot,
    width: usize,
    letter: u8,
    map: *const []u8,

    pub fn init(width: usize, letter: u8, start: usize, map: *const []u8) !PlotCluster {
        const plots = try gpa.alloc(Plot, map.len);
        for (plots, 0..) |_, i| {
            plots[i] = .{};
        }

        var re = PlotCluster{ .plots = plots, .width = width, .letter = letter, .map = map };
        re.build(start);
        return re;
    }

    fn build(self: *PlotCluster, start: usize) void {
        self.buildInternal(start);
        //self.printMe();
    }

    fn buildInternal(self: *PlotCluster, pos: usize) void {
        const pp = &self.plots[pos];
        pp.*.exists = true;

        // >
        var next = pos + 1;
        if (@mod(next, self.width) != 0 and pp.*.hasR and self.map.*[next] == self.letter) {
            pp.*.hasR = false;
            self.plots[next].hasL = false;
            self.buildInternal(next);
        }
        // v
        next = pos + self.width;
        if (next < self.map.len and pp.*.hasD and self.map.*[next] == self.letter) {
            pp.*.hasD = false;
            self.plots[next].hasU = false;
            self.buildInternal(next);
        }
        // <
        if (pos > 1 and @mod(pos, self.width) != 0 and
            pp.*.hasL and self.map.*[pos - 1] == self.letter)
        {
            next = pos - 1;
            pp.*.hasL = false;
            self.plots[next].hasR = false;
            self.buildInternal(next);
        }
        // ^
        if (pp.*.hasU and pos > self.width and self.map.*[pos - self.width] == self.letter) {
            next = pos - self.width;
            pp.*.hasU = false;
            self.plots[next].hasD = false;
            self.buildInternal(next);
        }
    }

    fn printMe(self: *PlotCluster) void {
        for (self.plots, 0..) |p, i| {
            if (@mod(i, self.width) == 0) print("\n", .{});
            if (p.exists) {
                print("{c}", .{self.letter});
            } else {
                print(".", .{});
            }
        }
        print("\n", .{});
    }

    pub fn isInPlot(self: *const PlotCluster, letter: u8, pos: usize) bool {
        return letter == self.letter and self.plots[pos].exists;
    }

    pub fn getCost(self: *const PlotCluster) u64 {
        var area: u64 = 0;
        var fence: u64 = 0;
        for (self.plots) |p| {
            if (p.exists) {
                fence += p.fences();
                area += 1;
            }
        }
        const re = area * fence;
        print("Result Plot[{c}] {d} * {d} = {d}\n", .{ self.letter, area, fence, re });
        return re;
    }
    pub fn getCostBulk(self: *const PlotCluster) !u64 {
        var area: u64 = 0;
        for (self.plots) |p| {
            if (p.exists) {
                area += 1;
            }
        }
        const sides = try self.countSides();
        const re = area * sides;
        print("Result Plot[{c}] {d} * {d} = {d}\n", .{ self.letter, area, sides, re });
        return re;
    }

    fn countSides(self: *const PlotCluster) !u64 {
        var sides: u64 = 0;

        while (self.findFirstWithWall()) |start| {
            sides += 1;
            var pos = start;
            if (self.plots[pos].hasU) {
                while (pos < self.plots.len and self.plots[pos].exists and self.plots[pos].hasU) {
                    //print("[^{d}]", .{pos});
                    self.plots[pos].hasU = false; //remove scanned wall
                    pos += 1;
                }
            } else if (self.plots[pos].hasD) {
                while (pos < self.plots.len and self.plots[pos].exists and self.plots[pos].hasD) {
                    //print("[v{d}]", .{pos});
                    self.plots[pos].hasD = false; //remove scanned wall
                    pos += 1;
                }
            } else if (self.plots[pos].hasL) {
                while (pos < self.plots.len and self.plots[pos].exists and self.plots[pos].hasL) {
                    //print("[<{d}]", .{pos});
                    self.plots[pos].hasL = false; //remove scanned wall
                    pos += self.width;
                }
            } else if (self.plots[pos].hasR) {
                while (pos < self.plots.len and self.plots[pos].exists and self.plots[pos].hasR) {
                    //print("[>{d}]", .{pos});
                    self.plots[pos].hasR = false; //remove scanned wall
                    pos += self.width;
                }
            }
            //print("\n", .{});
        }

        return sides;
    }

    // result sould be top-and left most
    fn findFirstWithWall(self: *const PlotCluster) ?usize {
        for (self.plots, 0..) |p, i| {
            if (p.exists and (p.hasU or p.hasD or p.hasL or p.hasR)) return i;
        }
        return null;
    }
};

const Plot = struct {
    exists: bool = false,
    hasU: bool = true,
    hasL: bool = true,
    hasD: bool = true,
    hasR: bool = true,

    pub fn fences(self: *const Plot) u64 {
        return @as(u64, @intFromBool(self.hasU)) +
            @intFromBool(self.hasL) +
            @intFromBool(self.hasD) +
            @intFromBool(self.hasR);
    }
};

const smallMap =
    \\AAAA
    \\BBCD
    \\BBCC
    \\EEEC
;

test "part1 small" {
    try std.testing.expectEqual(140, calcCost(smallMap));
}
test "part2 small" {
    try std.testing.expectEqual(80, calcCostBulk(smallMap));
}

const xoMap =
    \\OOOOO
    \\OXOXO
    \\OOOOO
    \\OXOXO
    \\OOOOO
;
test "part1 xo" {
    try std.testing.expectEqual(772, calcCost(xoMap));
}
test "part2 xo" {
    try std.testing.expectEqual(436, calcCostBulk(xoMap));
}

const bigMap =
    \\RRRRIICCFF
    \\RRRRIICCCF
    \\VVRRRCCFFF
    \\VVRCCCJFFF
    \\VVVVCJJCFE
    \\VVIVCCJJEE
    \\VVIIICJJEE
    \\MIIIIIJJEE
    \\MIIISIJEEE
    \\MMMISSJEEE
;
test "part1 big" {
    try std.testing.expectEqual(1930, calcCost(bigMap));
}
test "part2 big" {
    try std.testing.expectEqual(1206, calcCostBulk(bigMap));
}
