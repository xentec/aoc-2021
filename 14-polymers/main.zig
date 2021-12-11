const std = @import("std");
const pr = std.debug.print;

fn bytesToU16(b: []const u8) u16 { return std.mem.readIntSliceNative(u16, b); }
fn u16ToBytes(i: u16) [2]u8 {
    var b: [2]u8 = undefined;
    std.mem.writeIntNative(u16, &b, i);
    return b;
}

pub fn main() !void {
    var stdin = std.io.bufferedReader(std.io.getStdIn().reader());
    var input = stdin.reader();

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var alloc = arena.allocator();

    const input_buf = try input.readAllAlloc(alloc, 4096);
    var lines = std.mem.tokenize(u8, input_buf, "\n");

    var pair_list = std.AutoHashMap(u16, usize).init(alloc);
    var rules = std.AutoHashMap(u16, u8).init(alloc);

    const begin = lines.next().?;
    for (begin[0..begin.len-1]) |_, i| {
        const pair = bytesToU16(begin[i..i+2]);
        var count = (try pair_list.getOrPutValue(pair, 0)).value_ptr;
        count.* += 1;
    }

    while (lines.next()) |line| {
        if (line.len == 0) continue;
        var pair = std.mem.tokenize(u8, line, "->");
        const pattern = std.mem.trim(u8, pair.next().?, " ");
        const insert = std.mem.trim(u8, pair.next().?, " ");
        try rules.put(bytesToU16(pattern), insert[0]);
    }

    var step: usize = 0;
    while (step < 40) : (step += 1) {
        var pair_list_new = @TypeOf(pair_list).init(alloc);
        var iter = pair_list.iterator();
        while (iter.next()) |kv| {
            const pair = kv.key_ptr.*;
            const insert = rules.get(pair).?;
            const split = u16ToBytes(pair);
            const new_pairs = [_]u8{ split[0], insert, split[1] };
            for (new_pairs[0..new_pairs.len-1]) |_, i| {
                const np = bytesToU16(new_pairs[i..i+2]);
                var count = (try pair_list_new.getOrPutValue(np, 0)).value_ptr;
                count.* += kv.value_ptr.*;
            }
        }
        iter = pair_list_new.iterator();
        while (iter.next()) |kv|
            try pair_list.put(kv.key_ptr.*, kv.value_ptr.*);

        pair_list.deinit();
        pair_list = pair_list_new;
    }

    var max: usize = std.math.minInt(usize);
    var min: usize = std.math.maxInt(usize);

    var buckets = std.AutoArrayHashMap(u8, usize).init(alloc);
    try buckets.put(begin[0], 1);
    try buckets.put(begin[begin.len-1], 1);
    {
        var iter = pair_list.iterator();
        while (iter.next()) |kv| {
            for (u16ToBytes(kv.key_ptr.*)) |c| {
                var count = (try buckets.getOrPutValue(c, 0)).value_ptr;
                count.* += kv.value_ptr.*;
            }
        }
        for (buckets.values()) |*cnt| {
            cnt.* /= 2;
            max = std.math.max(max, cnt.*);
            min = std.math.min(min, cnt.*);
        }
    }

    var output: usize = max - min;
    std.fmt.format(std.io.getStdOut().writer(), "{}\n", .{output}) catch unreachable;
}
