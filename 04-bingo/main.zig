const std = @import("std");

const Board = struct {
    const Size = 5;
    const NumType = u7;
    const PosType = std.meta.Int(.unsigned, std.math.log2_int_ceil(u8, Size));
    const Map = std.AutoArrayHashMap(NumType, struct { row: PosType, col: PosType, marked: bool });
    const Score = struct { row: [Size]PosType, col: [Size]PosType, };
    const Self = @This();

    map: Map,
    scores: Score,
    finished: bool,

    fn init(alloc: std.mem.Allocator) !Self {
        var scores = std.mem.zeroes(Score);
        var map = Map.init(alloc);
        try map.ensureTotalCapacity(Size*Size);
        return Self {
            .scores = scores,
            .map = map,
            .finished = false,
        };
    }

    fn print(self: Self) void {
        var printMap: [Size][Size]struct {num:NumType,marked:bool,} = undefined;
        for (self.map.keys()) |num| {
            var field = self.map.getPtr(num).?;
            printMap[field.row][field.col] = .{.num = num,.marked = field.marked};
        }

        for (printMap) |row| {
            for (row) |field| {
                if (!field.marked) {
                    std.debug.print(" {:2}", .{field.num});
                } else
                    std.debug.print(">{:2}", .{field.num});
            }
            std.debug.print("\n", .{});
        }
    }
};

pub fn main() !void {
    var stdin = std.io.bufferedReader(std.io.getStdIn().reader());
    var stream = stdin.reader();

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    var alloc = arena.allocator();

    var deck = try std.ArrayList(Board.NumType).initCapacity(alloc, 512);
    defer deck.deinit();

    { // Read first line: deck
        var buf: [512]u8 = undefined;
        const line = try stream.readUntilDelimiterOrEof(&buf, '\n');
        var splitter = std.mem.split(u8, line.?, ",");
        while (splitter.next()) |numStr| {
            const num = try std.fmt.parseUnsigned(Board.NumType, numStr, 10);
            try deck.append(num);
        }
    }

    var boardList = try std.ArrayList(Board).initCapacity(alloc, 128);
    defer boardList.deinit();

    // Read boards
    var brd: *Board = undefined;
    var brdRow: u3 = 0;
    var buf: [64]u8 = undefined;
    while (try stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (line.len == 0) {
            brd = try boardList.addOne();
            brd.* = try Board.init(alloc);
            brdRow = 0;
            continue;
        }
        var brdCol: u3 = 0;
        var tokenizer = std.mem.tokenize(u8, line, " ");
        while (tokenizer.next()) |numStr| {
            const num = try std.fmt.parseUnsigned(Board.NumType, numStr, 10);
            try brd.map.put(num, .{.row = brdRow, .col = brdCol, .marked = false});
            brdCol += 1;
        }
        brdRow += 1;
    }

    var numWinning: Board.NumType = undefined;
    for (deck.items) |num| {
        for (boardList.items) |*board, boardIdx| {
            if (board.finished) continue;
            var field = board.map.getPtr(num) orelse continue;
            field.marked = true;
            var ls = &board.scores;
            var lsRow = &ls.row[field.row];
            var lsCol = &ls.col[field.col];
            lsRow.* += 1;
            lsCol.* += 1;
            if(std.math.max(lsRow.*, lsCol.*) == 5) {
                numWinning = num;
                brd = board;
                brd.finished = true;
            }
        }
    }

    var sum: u32 = 0;
    for (brd.map.keys()) |num| {
        const field = brd.map.getPtr(num).?;
        if (!field.marked)
            sum += num;
    }
    std.debug.print("win num: {}; sum {} => {}\n", .{numWinning, sum, sum * numWinning});
}
