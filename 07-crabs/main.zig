const std = @import("std");
const pr = std.debug.print;

pub fn main() !void {
    var stdin = std.io.bufferedReader(std.io.getStdIn().reader());
    var stream = stdin.reader();

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var alloc = arena.allocator();

    var hist = std.AutoArrayHashMap(u16, u16).init(alloc);
    defer hist.deinit();

    var buf: [16]u8 = undefined;
    while (try stream.readUntilDelimiterOrEof(&buf, ',')) |str| {
        const pos = try std.fmt.parseUnsigned(u16, std.mem.trim(u8, str, "\n "), 10);
        var kv = try hist.getOrPutValue(pos, 0);
        kv.value_ptr.* += 1;
    }

    var sum: u32 = std.math.maxInt(u32);
    var posBest: u32 = 0;
    for (hist.keys()) |target| {
        var tmp: u32 = 0;
        for (hist.keys()) |pos| {
            const offset = try std.math.absInt(@intCast(i32, target) - pos);
            tmp += @intCast(u32, offset) * hist.get(pos).?;
        }
        if (sum > tmp) {
            sum = tmp;
            posBest = target;
        }
    }

    pr("best pos: {}, fuel sum: {}\n", .{posBest, sum});
}
