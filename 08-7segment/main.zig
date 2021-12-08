const std = @import("std");
const pr = std.debug.print;

pub fn main() !void {
    var stdin = std.io.bufferedReader(std.io.getStdIn().reader());
    var stream = stdin.reader();

    var count: usize = 0;
    var buf: [128]u8 = undefined;
    while (try stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var split = std.mem.tokenize(u8, line, "|");
        var patterns = std.mem.tokenize(u8, split.next().?, " ");
        _ = patterns;
        var outputs = std.mem.tokenize(u8, split.next().?, " ");

        while (outputs.next()) |output| {
            switch(output.len) {
                2,3,4,7 => count += 1,
                else => {},
            }
        }
    }
    pr("{}\n", .{count});
}
