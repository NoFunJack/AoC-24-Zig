const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("data/day16.txt");

pub fn main() !void {
    print("part1: {any}\n", .{findBestPath(data)});
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

fn findBestPath(map: []const u8) ![2]u64 {
    const width = indexOf(u8, map, '\n').? + 1;
    const root = Node{
        .pos = indexOf(u8, map, 'S').?,
        .dir = Dir.r,
        .cost = 0,
        .hist = List(Node).init(gpa),
    };

    var nodes = try NodeList.init(root);

    var bestPathScore: u64 = 100000;
    var bestPaths = List(Node).init(gpa);

    while (try nodes.popSmallest()) |n| {
        if (n.cost > bestPathScore) {
            break;
        }
        // print("\n", .{});
        // if (n.cost > 3000) unreachable;
        // print("DEBUG: {d}\n", .{nodes.nodes.items.len});
        print("bestNode pos: {d} dir:{any} cost:{d}\n", .{ n.pos, n.dir, n.cost });
        // hook
        if (map[n.pos] == 'E') {
            if (n.cost <= bestPathScore) {
                printPos(n, map);
                bestPathScore = n.cost;
                try bestPaths.append(n);
                continue;
            }
        }

        // move
        var branchNode = n;
        while (true) {
            var isBranch = false;

            if (branchNode.rightSpaceFree(map, width)) {
                try nodes.appendIfNew(try branchNode.nextRight());
                isBranch = true;
            }
            if (branchNode.leftSpaceFree(map, width)) {
                try nodes.appendIfNew(try branchNode.nextLeft());
                isBranch = true;
            }

            if (isBranch) {
                const nextNode = try branchNode.nextNode(width);
                if (map[nextNode.pos] == '.' or map[nextNode.pos] == 'E') {
                    try nodes.appendIfNew(nextNode);
                }
                break;
            } else {
                if (branchNode.nextSpaceFree(map, width)) {
                    branchNode = try branchNode.nextNode(width);
                } else {
                    break;
                }
                if (map[branchNode.pos] == 'E') {
                    try nodes.appendIfNew(branchNode);
                }
            }
        }

        n.deinit();
    }

    return .{ bestPathScore, try countUniqueHist(bestPaths) + 1 };
}

fn printPos(n: Node, map: []const u8) void {
    for (map, 0..) |m, i| {
        if (i == n.pos) {
            print("{c}", .{n.dir.toString()});
        } else if (n.getHist(i)) |h| {
            print("{c}", .{h.dir.toString()});
        } else {
            print("{c}", .{m});
        }
    }
}

fn countUniqueHist(nodes: List(Node)) !u64 {
    var uniqes = List(usize).init(gpa);
    defer uniqes.deinit();

    for (nodes.items) |end| {
        nodes: for (end.hist.items) |n| {
            for (uniqes.items) |u| {
                if (u == n.pos) {
                    continue :nodes;
                }
            }
            try uniqes.append(n.pos);
        }
    }

    return uniqes.items.len;
}

const NodeList = struct {
    nodes: List(Node),
    known: List(Node),
    pub fn init(root: Node) !NodeList {
        var list = List(Node).init(gpa);
        try list.append(root);
        return NodeList{ .nodes = list, .known = List(Node).init(gpa) };
    }

    pub fn popSmallest(self: *NodeList) !?Node {
        if (self.nodes.items.len == 0) {
            return null;
        }
        var smallest = self.nodes.items[0];
        var smallest_idx: usize = 0;

        for (self.nodes.items, 0..) |n, i| {
            if (n.cost < smallest.cost) {
                smallest = n;
                smallest_idx = i;
            }
        }

        return self.nodes.swapRemove(smallest_idx);
    }

    pub fn appendIfNew(self: *NodeList, n: Node) !void {
        for (self.known.items) |v| {
            if (n.pos == v.pos and n.dir == v.dir and n.cost > v.cost) {
                n.deinit(); // node will be gone
                return;
            }
        }
        try self.known.append(n);

        try self.nodes.append(n);
    }
};

const Node = struct {
    pos: usize,
    dir: Dir,
    cost: u64,
    hist: List(Node),

    pub fn deinit(self: *const Node) void {
        self.hist.deinit();
    }

    pub fn nextPos(self: *const Node, width: usize) usize {
        return nextPosDir(self, self.dir, width);
    }

    fn nextPosDir(self: *const Node, dir: Dir, width: usize) usize {
        return switch (dir) {
            Dir.u => self.pos - width,
            Dir.r => self.pos + 1,
            Dir.d => self.pos + width,
            Dir.l => self.pos - 1,
        };
    }

    pub fn nextNode(self: Node, width: usize) !Node {
        var hist = try self.hist.clone();
        try hist.append(self);
        return Node{
            .pos = self.nextPos(width),
            .dir = self.dir,
            .cost = self.cost + 1,
            .hist = hist,
        };
    }

    pub fn nextRight(self: Node) !Node {
        var hist = try self.hist.clone();
        try hist.append(self);
        return Node{
            .pos = self.pos,
            .dir = self.dir.right(),
            .cost = self.cost + 1000,
            .hist = hist,
        };
    }
    pub fn nextLeft(self: Node) !Node {
        var hist = try self.hist.clone();
        try hist.append(self);
        return Node{
            .pos = self.pos,
            .dir = self.dir.left(),
            .cost = self.cost + 1000,
            .hist = hist,
        };
    }

    pub fn nextSpaceFree(self: *const Node, map: []const u8, width: usize) bool {
        return map[self.nextPos(width)] == '.' or map[self.nextPos(width)] == 'E';
    }
    pub fn leftSpaceFree(self: *const Node, map: []const u8, width: usize) bool {
        const d = self.dir.left();
        const pos = self.nextPosDir(d, width);
        return map[pos] == '.' or map[pos] == 'E';
    }
    pub fn rightSpaceFree(self: *const Node, map: []const u8, width: usize) bool {
        const d = self.dir.right();
        const pos = self.nextPosDir(d, width);
        return map[pos] == '.' or map[pos] == 'E';
    }

    pub fn getHist(self: *const Node, pos: usize) ?Node {
        var i = self.hist.items.len;
        while (i > 0) {
            i -= 1;
            if (self.hist.items[i].pos == pos) return self.hist.items[i];
        }
        return null;
    }
};

const Dir = enum {
    u,
    r,
    d,
    l,
    pub fn right(self: Dir) Dir {
        return switch (self) {
            Dir.u => Dir.r,
            Dir.r => Dir.d,
            Dir.d => Dir.l,
            Dir.l => Dir.u,
        };
    }
    pub fn left(self: Dir) Dir {
        return switch (self) {
            Dir.u => Dir.l,
            Dir.r => Dir.u,
            Dir.d => Dir.r,
            Dir.l => Dir.d,
        };
    }
    pub fn toString(self: Dir) u8 {
        return switch (self) {
            Dir.u => '^',
            Dir.r => '>',
            Dir.d => 'v',
            Dir.l => '<',
        };
    }
};

const firstEx =
    \\###############
    \\#.......#....E#
    \\#.#.###.#.###.#
    \\#.....#.#...#.#
    \\#.###.#####.#.#
    \\#.#.#.......#.#
    \\#.#.#####.###.#
    \\#...........#.#
    \\###.#.#####.#.#
    \\#...#.....#.#.#
    \\#.#.#.###.#.#.#
    \\#.....#...#.#.#
    \\#.###.#.#.#.#.#
    \\#S..#.....#...#
    \\###############
;

test "part1 first" {
    const result = try findBestPath(firstEx);
    try std.testing.expectEqual(7036, result[0]);
    try std.testing.expectEqual(45, result[1]);
}

const secondEx =
    \\#################
    \\#...#...#...#..E#
    \\#.#.#.#.#.#.#.#.#
    \\#.#.#.#...#...#.#
    \\#.#.#.#.###.#.#.#
    \\#...#.#.#.....#.#
    \\#.#.#.#.#.#####.#
    \\#.#...#.#.#.....#
    \\#.#.#####.#.###.#
    \\#.#.#.......#...#
    \\#.#.###.#####.###
    \\#.#.#...#.....#.#
    \\#.#.#.#####.###.#
    \\#.#.#.........#.#
    \\#.#.#.#########.#
    \\#S#.............#
    \\#################
;

test "part1 second" {
    const result = try findBestPath(secondEx);
    try std.testing.expectEqual(11048, result[0]);
    try std.testing.expectEqual(64, result[1]);
}
