const std = @import("std");

const Point = struct {
    const Type = i16;
    const Self = @This();

    x: Type,
    y: Type,

    fn parse(str: []const u8) !Self {
        var tok = std.mem.tokenize(u8, str, ",");
        return Self {
            .x = try std.fmt.parseInt(Type, tok.next().?, 10),
            .y = try std.fmt.parseInt(Type, tok.next().?, 10),
        };
    }

    fn eql(self: *const Self, other: *const Self) bool {
        return self.x == other.x and self.y == other.y;
    }

    fn move(self: *const Self, vec: *const Point) Point {
        return Point { .x = self.x + vec.x, .y = self.y + vec.y };
    }
};
const Vector = struct {
    const Self = @This();

    start: Point,
    end: Point,

    fn parse(str: []const u8) !Self {
        var tok = std.mem.tokenize(u8, str, " -> ");
        return Self {
            .start = try Point.parse(tok.next() orelse return error.BadInput),
            .end = try Point.parse(tok.next() orelse return error.BadInput),
        };
    }

    fn dir(self: *const Self) Point {
        return Point {
            .x = std.math.clamp(self.end.x-self.start.x, -1, 1),
            .y = std.math.clamp(self.end.y-self.start.y, -1, 1),
        };
    }
};

pub fn main() !void {
    var stdin = std.io.bufferedReader(std.io.getStdIn().reader());
    var stream = stdin.reader();

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var alloc = arena.allocator();

    var map = std.AutoArrayHashMap(Point, u8).init(alloc);
    try map.ensureTotalCapacity(5000);

    // Read lines
    var buf: [64]u8 = undefined;
    while (try stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        const vec = try Vector.parse(line);
        var v = vec.dir();
        if (v.x != 0 and v.y != 0) continue;

        var p = vec.start;
        var over = false;
        while (!over) : (p = p.move(&v)) {
            var entry = try map.getOrPut(p);
            if(entry.found_existing) {
                entry.value_ptr.* += 1;
            } else {
                entry.value_ptr.* = 1;
            }
            if (p.eql(&vec.end))
                over = true;
        }
    }

    var sum: u32 = 0;
    for (map.values()) |n| {
        if (n>=2)
            sum += 1;
    }
    std.debug.print("{}\n", .{sum});
}
