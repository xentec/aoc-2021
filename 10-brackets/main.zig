const std = @import("std");
const pr = std.debug.print;

pub fn main() !void {
    var stdin = std.io.bufferedReader(std.io.getStdIn().reader());
    var stream = stdin.reader();
    var buf: [128]u8 = undefined;

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var alloc = arena.allocator();

    var stack = try std.ArrayList(u8).initCapacity(alloc, 32);
    defer stack.deinit();
    var score_list = try std.ArrayList(usize).initCapacity(alloc, 32);

lines:
    while (try stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        stack.clearRetainingCapacity();
        for (line) |char| {
            switch(char) {
                '(','[','{','<' => {
                    try stack.append(char);
                    continue;
                },
                ')',']','}','>' => {
                    const matching = char - @as(u8, if (char==')') 1 else 2);
                    const match = if(stack.popOrNull()) |c| c == matching else false;
                    if(!match) {
                        continue :lines;
                    }
                },
                else => unreachable,
            }
        }

        var score: usize = 0;
        for (stack.items) |_, i| {
            const c = stack.items[stack.items.len-i-1];
            score *= 5;
            score += @as(usize, switch(c) {
                '(' => 1,
                '[' => 2,
                '{' => 3,
                '<' => 4,
                else => unreachable,
            });
        }
        if (score > 0)
            try score_list.append(score);
    }

    std.sort.sort(usize, score_list.items, {}, comptime std.sort.asc(usize));
    var output = score_list.items[score_list.items.len/2];
    pr("{}\n", .{output});
}
