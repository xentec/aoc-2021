const std = @import("std");
const pr = std.debug.print;

pub fn main() !void {
    var stdin = std.io.bufferedReader(std.io.getStdIn().reader());
    var stream = stdin.reader();
    var buf: [128]u8 = undefined;

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var alloc = arena.allocator();

    var stack = try std.ArrayList(u8).initCapacity(alloc, 100);
    defer stack.deinit();

    var output: usize = 0;
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
                        output += @as(usize, switch(char) {
                            ')' => 3,
                            ']' => 57,
                            '}' => 1197,
                            '>' => 25137,
                            else => unreachable,
                        });
                        break;
                    }
                },
                else => unreachable,
            }
        }
    }

    pr("{}\n", .{output});
}
