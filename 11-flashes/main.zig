const std = @import("std");
const pr = std.debug.print;

const Map = struct {
    const Self = @This();
    const FieldType = struct { e: u4, flashing: bool };

    field: std.ArrayList(FieldType),
    width: usize,

    fn init(alloc: std.mem.Allocator, width: usize) !Self {
        var full_width = width+2; // walls
        var self = Self {
            .field = try std.ArrayList(FieldType).initCapacity(alloc, full_width*10),
            .width = full_width,
        };
        try self.appendWall();
        try self.appendWall();
        return self;
    }

    fn appendWall(self: *Self) !void {
        try self.field.ensureUnusedCapacity(self.width);
        var idx: usize = 0;
        while (idx < self.width) : (idx += 1)
            self.field.appendAssumeCapacity(FieldType{.e=10,.flashing=false});
    }

    fn appendAsciiRow(self: *Self, line: []const u8) !void {
        const start = self.field.items.len - self.width + 1;
        for (line) |char, idx| {
            self.field.items[start+idx] = FieldType{.e=@intCast(u4, char - '0'), .flashing=false};
        }
        try self.appendWall();
    }

    fn print(self: *Self) void {
        for (self.field.items) |cell, idx| {
            if (idx > 0 and idx % (self.width) == 0)
                pr("\n", .{});
            if (cell < 10)
                pr("{}", .{cell});
        }
        pr("\n", .{});
    }

    fn posPtr(self: *Self, x: isize, y: isize) *FieldType {
        return &self.field.items[self.width*@intCast(usize, y+1)+@intCast(usize, x+1)];
    }
    fn posVal(self: *Self, x: isize, y: isize) FieldType {
        return self.posPtr(x,y).*;
    }

    fn flash(self: *Self, x: isize, y: isize) !usize {
        const P = struct {x: isize, y: isize,};
        var stack = try std.ArrayList(P).initCapacity(self.field.allocator, 100);
        defer stack.deinit();

        var count: usize = 0;
        try stack.append(P {.x=x,.y=y});
        while (stack.popOrNull()) |pos| {
            var cell = self.posPtr(pos.x, pos.y);
            if (cell.e == 10 or cell.flashing)
                continue;

            cell.e += 1;
            if (cell.e < 10)
                continue;

            cell.e = 0;
            cell.flashing = true;
            count += 1;
            const adjacents = [_]P{
                .{.x=pos.x-1, .y=pos.y},
                .{.x=pos.x-1, .y=pos.y-1},
                .{.x=pos.x, .y=pos.y-1},
                .{.x=pos.x+1, .y=pos.y-1},
                .{.x=pos.x+1, .y=pos.y},
                .{.x=pos.x+1, .y=pos.y+1},
                .{.x=pos.x, .y=pos.y+1},
                .{.x=pos.x-1, .y=pos.y+1},
            };
            try stack.appendSlice(&adjacents);
        }
        return count;
    }

    fn clean_flashes(self: *Self) void {
        const width: isize = @intCast(isize, self.width - 2);
        const height: isize = @intCast(isize, self.field.items.len / self.width - 2);
        var y: isize = 0;
        while (y < height) : (y+=1) {
            var x: isize = 0;
            while (x < width) : (x+=1) {
                self.posPtr(x, y).flashing = false;
            }
        }
    }

    fn tick(self: *Self) !usize {
        const width: isize = @intCast(isize, self.width - 2);
        const height: isize = @intCast(isize, self.field.items.len / self.width - 2);
        var flashes: usize = 0;
        var y: isize = 0;
        while (y < height) : (y+=1) {
            var x: isize = 0;
            while (x < width) : (x+=1) {
                var cell = self.posPtr(x, y);
                if (cell.flashing)
                    continue;

                if (cell.e == 9) {
                    flashes += try self.flash(x, y);
                } else {
                    cell.e += 1;
                }
            }
        }
        self.clean_flashes();
        return flashes;
    }
};

pub fn main() !void {
    var stdin = std.io.bufferedReader(std.io.getStdIn().reader());
    var input = stdin.reader();
    var buf: [128]u8 = undefined;

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var alloc = arena.allocator();

    var first_line = (try input.readUntilDelimiterOrEof(&buf, '\n')).?;
    var map = try Map.init(alloc, first_line.len);
    try map.appendAsciiRow(first_line);

    while (try input.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        try map.appendAsciiRow(line);
    }

    var output: usize = 0;
    var steps: usize = 0;
    while (steps < 100) : (steps += 1)
        output += try map.tick();

    std.fmt.format(std.io.getStdOut().writer(), "{}\n", .{output}) catch unreachable;
}
