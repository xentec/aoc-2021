const std = @import("std");
const pr = std.debug.print;

const Point = struct {
    const Type = i16;
    const Self = @This();

    x: Type,
    y: Type,

    fn parse(str: []const u8) !Self {
        var tok = std.mem.tokenize(u8, str, ",");
        return Self {
            .x = try std.fmt.parseInt(Type, tok.next() orelse return error.BadInput, 10),
            .y = try std.fmt.parseInt(Type, tok.next() orelse return error.BadInput, 10),
        };
    }
};

pub fn main() !void {
    var stdin = std.io.bufferedReader(std.io.getStdIn().reader());
    var input = stdin.reader();
    var buf: [128]u8 = undefined;

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var alloc = arena.allocator();

    var paper = std.AutoArrayHashMap(Point, void).init(alloc);

    while (try input.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (line.len == 0)
            break;

        try paper.put(try Point.parse(line), {});
    }
    while (try input.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        const eq_pos = std.mem.indexOfPosLinear(u8, line, 0, "=").?;
        const offset = try std.fmt.parseInt(i16, line[eq_pos+1..], 10);
        var tmp = std.ArrayList(Point).init(alloc);
        switch(line[eq_pos-1]) {
            'x' => {
                for (paper.keys()) |p| {
                    if (p.x > offset)
                        try tmp.append(p);
                }
                for (tmp.items) |p| {
                    _ = paper.swapRemove(p);
                    try paper.put(.{.x=offset-(p.x-offset), .y=p.y}, {});
                }
            },
            'y' => {
                for (paper.keys()) |p| {
                    if (p.y > offset)
                        try tmp.append(p);
                }
                for (tmp.items) |p| {
                    _ = paper.swapRemove(p);
                    try paper.put(.{.y=offset-(p.y-offset), .x=p.x}, {});
                }
            },
            else => unreachable,
        }
    }
    var output: usize = paper.count();
    var y: i16 = 0;
    while (y<10):(y+=1) {
        var x: i16 = 0;
        while (x<50):(x+=1) {
            if(paper.contains(.{.x=x,.y=y})) {
                pr("#", .{});
            } else {
                pr(".", .{});
            }
        }
        pr("\n", .{});
    }
    std.fmt.format(std.io.getStdOut().writer(), "{}\n", .{output}) catch unreachable;
}
