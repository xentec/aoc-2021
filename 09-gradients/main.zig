const std = @import("std");
const pr = std.debug.print;

const Map = struct {
    const Self = @This();
    const FieldType = u4;

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
            self.field.appendAssumeCapacity(9);
    }

    fn appendAsciiRow(self: *Self, line: []const u8) !void {
        const start = self.field.items.len - self.width + 1;
        for (line) |char, idx| {
            self.field.items[start+idx] = @intCast(u4, char - '0');
        }
        try self.appendWall();
    }

    fn print(self: *Self) void {
        for (self.field.items) |cell, idx| {
            if (idx > 0 and idx % (self.width) == 0)
                pr("\n", .{});
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

    fn isLowest(self: *Self, x: isize, y: isize) bool {
        const cell = self.posVal(x, y);
        return cell < self.posVal(x-1, y) and cell < self.posVal(x, y-1)
           and cell < self.posVal(x+1, y) and cell < self.posVal(x, y+1);
    }
};

pub fn main() !void {
    var stdin = std.io.bufferedReader(std.io.getStdIn().reader());
    var stream = stdin.reader();
    var buf: [128]u8 = undefined;

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var alloc = arena.allocator();

    var first_line = (try stream.readUntilDelimiterOrEof(&buf, '\n')).?;
    const width: usize = first_line.len;
    var map = try Map.init(alloc, first_line.len);
    try map.appendAsciiRow(first_line);

    var lines: usize = 1; // first line counted
    while (try stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        try map.appendAsciiRow(line);
        lines += 1;
    }
    const heigth = lines;

    var output: usize = 0;
    var y: isize = 0;
    while (y < heigth) : (y+=1) {
        var x: isize = 0;
        while (x < width) : (x+=1) {
            if (map.isLowest(x, y))
                output += map.posVal(x, y) + 1;
        }
    }

    pr("{}\n", .{output});
}
