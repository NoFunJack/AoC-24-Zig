const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("data/day15.txt");

pub fn main() !void {
    print("part1: {any}\n", .{boxHash(data)});
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

fn boxHash(instr: []const u8) !u64 {
    var blockIter = splitSeq(u8, instr, "\n\n");

    // load map
    var map = List(u8).init(gpa);
    defer map.deinit();
    var lineIt = splitSca(u8, blockIter.next().?, '\n');
    const width = lineIt.peek().?.len * 2;
    print("WIDTH: {d}", .{width});
    {
        while (lineIt.next()) |line| {
            for (line) |c| {
                switch (c) {
                    '#' => try map.appendSlice("##"),
                    'O' => try map.appendSlice("[]"),
                    '@' => try map.appendSlice("@."),
                    '.' => try map.appendSlice(".."),
                    else => {},
                }
            }
        }
    }
    var pos = indexOf(u8, map.items, '@').?;
    map.items[pos] = '.';
    printMap(map.items, width, pos);

    // move stuff
    {
        const moves = blockIter.next().?;
        const iwidth: i8 = @intCast(width);
        for (moves) |move| {
            print("move: {c}\n", .{move});
            switch (move) {
                '<' => pos = try changeMap(&map.items, width, pos, -1),
                '^' => pos = try changeMap(&map.items, width, pos, -iwidth),
                '>' => pos = try changeMap(&map.items, width, pos, 1),
                'v' => pos = try changeMap(&map.items, width, pos, iwidth),
                else => {},
            }
            // printMap(map.items, width, pos);
        }
    }

    printMap(map.items, width, pos);
    return calcHash(&map.items, width);
}

fn changeMap(map: *[]u8, width: usize, pos: usize, dir: i8) !usize {
    const next = pos +% @as(usize, @bitCast(@as(isize, dir)));
    switch (map.*[next]) {
        '#' => return pos,
        '.' => return next,
        '[', ']' => {
            var s = next;
            if (dir == -1 or dir == 1) {
                var stack = List(u8).init(gpa);
                defer stack.deinit();
                while (map.*[s] != '#') {
                    try stack.append(map.*[s]);
                    s = s +% @as(usize, @bitCast(@as(isize, dir)));
                    if (map.*[s] == '.') {
                        map.*[next] = '.';
                        var p = next;
                        for (stack.items) |n| {
                            p = p +% @as(usize, @bitCast(@as(isize, dir)));
                            map.*[p] = n;
                        }
                        return next;
                    }
                }
                return pos;
            } else {
                if (trianglePush(map, next, dir, width, false)) {
                    _ = trianglePush(map, next, dir, width, true);
                    return next;
                } else {
                    return pos;
                }
            }
        },
        else => unreachable,
    }
}

fn trianglePush(map: *[]u8, pos: usize, dir: i8, width: usize, dopush: bool) bool {
    // print("TESTING:({any}) {d}\n", .{ dopush, pos });
    // rec hook
    if (map.*[pos] == '.') {
        // print("hook\n", .{});
        return true;
    }
    if (map.*[pos] == '#') return false;

    var l = pos;
    if (map.*[pos] == ']') {
        l = pos - 1;
    }
    // print("l: {d}\n", .{l});
    //printMap(map.*, width, pos);
    const ln = l +% @as(usize, @bitCast(@as(isize, dir)));
    if (trianglePush(map, ln, dir, width, dopush) and trianglePush(map, ln + 1, dir, width, dopush)) {
        // print("crating box {d}->{d}\n", .{ l, ln });
        // pushable
        if (dopush) {
            map.*[ln] = '[';
            map.*[ln + 1] = ']';
            map.*[l] = '.';
            map.*[l + 1] = '.';
        }
        return true;
    } else if (map.*[ln] == '#' and map.*[ln + 1] == '#') {
        return false;
    } else {
        return false;
    }
}

fn calcHash(map: *[]u8, width: usize) u64 {
    var sum: u64 = 0;
    for (map.*, 0..) |m, i| {
        if (m == '[') {
            const l = @rem(i, width);
            const t = @divTrunc(i, width);
            sum += t * 100 + l;
        }
    }
    return sum;
}

fn printMap(map: []u8, width: usize, pos: usize) void {
    for (map, 0..) |m, i| {
        if (i == pos) {
            print("@", .{});
        } else {
            if (@mod(i, width) == 0) {
                print("\n", .{});
            }
            print("{c}", .{m});
        }
    }
    print("\n\n", .{});
}

const example =
    \\########
    \\#..O.O.#
    \\##@.O..#
    \\#...O..#
    \\#.#.O..#
    \\#...O..#
    \\#......#
    \\########
    \\
    \\<^^>>>vv<v>>v<<
;

// test "part1 example small" {
// try std.testing.expectEqual(9021, boxHash(example));
// }
test "situation" {
    const sit =
        \\#######
        \\#...#.#
        \\#.....#
        \\#..OO@#
        \\#..O..#
        \\#.....#
        \\#######
        \\
        \\<vv<<^^<<^^
    ;
    try std.testing.expectEqual(0, boxHash(sit));
}
const exampleBig =
    \\##########
    \\#..O..O.O#
    \\#......O.#
    \\#.OO..O.O#
    \\#..O@..O.#
    \\#O#..O...#
    \\#O..O..O.#
    \\#.OO.O.OO#
    \\#....O...#
    \\##########
    \\
    \\<vv>^<v^>v>^vv^v>v<>v^v<v<^vv<<<^><<><>>v<vvv<>^v^>^<<<><<v<<<v^vv^v>^
    \\vvv<<^>^v^^><<>>><>^<<><^vv^^<>vvv<>><^^v>^>vv<>v<<<<v<^v>^<^^>>>^<v<v
    \\><>vv>v^v^<>><>>>><^^>vv>v<^^^>>v^v^<^^>v^^>v^<^v>v<>>v^v^<v>v^^<^^vv<
    \\<<v<^>>^^^^>>>v^<>vvv^><v<<<>^^^vv^<vvv>^>v<^^^^v<>^>vvvv><>>v^<<^^^^^
    \\^><^><>>><>^^<<^^v>>><^<v>^<vv>>v>>>^v><>^v><<<<v>>v<v<v>vvv>^<><<>^><
    \\^>><>^v<><^vvv<^^<><v<<<<<><^v<<<><<<^^<v<^^^><^>>^<v^><<<^>>^v<v^v<v^
    \\>^>>^v>vv>^<<^v<>><<><<v<<v><>v<^vv<<<>^^v^>^^>>><<^v>>v^v><^^>>^<>vv^
    \\<><^^>^^^<><vvvvv^v<v<<>^v<v>v<<^><<><<><<<^^<<<^<<>><<><^^^>^^<>^>v<>
    \\^^>vv<^v^v<vv>^<><v<^v>^^^>>>^^vvv^>vvv<>>>^<^>>>>>^<<^v>^vvv<>^<><<v>
    \\v^^>>><<^^<>>^v^<v^vv<>v^<<>^<^v^v><^<<<><<^<v><v<>vv>>v><v^<vv<>v^<<^
;

test "part1 example big" {
    try std.testing.expectEqual(9021, boxHash(exampleBig));
}
