const std = @import("std");


pub fn main() !void {
    var stdin = std.io.bufferedReader(std.io.getStdIn().reader());
    var stream = stdin.reader();

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var alloc = arena.allocator();

    var list = std.ArrayList(u4).init(alloc);
    defer list.deinit();
    try list.ensureTotalCapacity(5000);

    // Read lines
    var buf: [16]u8 = undefined;
    while (try stream.readUntilDelimiterOrEof(&buf, ',')) |str| {
        const num = try std.fmt.parseUnsigned(u4, std.mem.trim(u8, str, "\n "), 8);
        try list.append(num);
    }

    var day: usize = 0;
    while (day < 80) : (day += 1) {
        var newborn = std.ArrayList(u4).init(alloc);
        defer newborn.deinit();
        try newborn.ensureTotalCapacity(100);

        for (list.items) |*fish| {
            if (fish.* == 0) {
                try newborn.append(8);
                fish.* = 6;
            } else
                fish.* -= 1;
        }
        try list.appendSlice(newborn.items);
    }
    std.debug.print("{}\n", .{list.items.len});
}
