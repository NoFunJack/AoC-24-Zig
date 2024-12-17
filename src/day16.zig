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

fn findBestPath(map: []const u8) !u64 {
    const width = indexOf(u8, map, '\n').? + 1;
    const root = Node{
        .pos = indexOf(u8, map, 'S').?,
        .dir = Dir.l,
        .cost = 0,
        .hist = List(Node).init(gpa),
    };

    var nodes = try NodeList.init(root);

    while (try nodes.popSmallest()) |n| {
        // print("\n", .{});
        // if (n.cost > 3000) unreachable;
        // print("bestNode pos: {d} dir:{any} cost:{d}\n", .{ n.pos, n.dir, n.cost });
        // hook
        if (map[n.pos] == 'E') {
            printPos(n, map);
            return n.cost;
        }

        // move
        const next = n.nextPos(width);
        if (map[next] == '.' or map[next] == 'E') {
            // print("can move to {d}\n", .{next});

            var hist = try n.hist.clone();
            try hist.append(n);
            try nodes.appendIfNew(Node{
                .pos = next,
                .dir = n.dir,
                .cost = n.cost + 1,
                .hist = hist,
            });
        }

        // turn right
        var hist = try n.hist.clone();
        try hist.append(n);
        const right = Node{
            .pos = n.pos,
            .dir = n.dir.right(),
            .cost = n.cost + 1000,
            .hist = hist,
        };
        if (map[right.nextPos(width)] == '.' or map[right.nextPos(width)] == 'E') try nodes.appendIfNew(right);
        // turn left
        hist = try n.hist.clone();
        try hist.append(n);
        const left = Node{
            .pos = n.pos,
            .dir = n.dir.left(),
            .cost = n.cost + 1000,
            .hist = hist,
        };
        if (map[left.nextPos(width)] == '.' or map[left.nextPos(width)] == 'E') try nodes.appendIfNew(left);
    }

    unreachable; // no path found
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
            if (n.pos == v.pos and n.dir == v.dir) {
                n.hist.deinit(); // node will be gone
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

    pub fn nextPos(self: *const Node, width: usize) usize {
        return switch (self.dir) {
            Dir.u => self.pos - width,
            Dir.r => self.pos + 1,
            Dir.d => self.pos + width,
            Dir.l => self.pos - 1,
        };
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
    try std.testing.expectEqual(7036, findBestPath(firstEx));
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
    try std.testing.expectEqual(11048, findBestPath(secondEx));
}
