const std = @import("std");
const pr = std.debug.print;

pub fn main() !void {
    var stdin = std.io.bufferedReader(std.io.getStdIn().reader());
    var input = stdin.reader();

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var alloc = arena.allocator();

    const input_buf = try input.readAllAlloc(alloc, 4096);
    var lines = std.mem.tokenize(u8, input_buf, "\n");

    var rules = std.StringHashMap(u8).init(alloc);
    var polymer = std.ArrayList(u8).init(alloc);

    try polymer.appendSlice(lines.next().?);

    while (lines.next()) |line| {
        if (line.len == 0) continue;

        var pair = std.mem.tokenize(u8, line, "->");
        const pattern = std.mem.trim(u8, pair.next().?, " ");
        const insert = std.mem.trim(u8, pair.next().?, " ");
        try rules.put(pattern, insert[0]);
    }

    var step: usize = 0;
    while (step < 10) : (step += 1) {
        var new_polymer = std.ArrayList(u8).init(alloc);
        try new_polymer.append(polymer.items[0]);
        for (polymer.items[0..polymer.items.len-1]) |_, i| {
            const pair = polymer.items[i..i+2];
            const insert = rules.get(pair).?;
            try new_polymer.append(insert);
            try new_polymer.append(pair[1]);
        }
        polymer.deinit();
        polymer = new_polymer;
    }

    var buckets = std.AutoArrayHashMap(u8, usize).init(alloc);
    for(polymer.items) |c| {
        var count = (try buckets.getOrPutValue(c, 0)).value_ptr;
        count.* += 1;
    }

    var max: usize = std.math.minInt(usize);
    var min: usize = std.math.maxInt(usize);
    for (buckets.keys()) |c| {
        const count = buckets.get(c).?;
        max = std.math.max(max, count);
        min = std.math.min(min, count);
    }

    var output: usize = max - min;
    std.fmt.format(std.io.getStdOut().writer(), "{}\n", .{output}) catch unreachable;
}
