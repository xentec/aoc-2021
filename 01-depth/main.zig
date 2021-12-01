const std = @import("std");

pub fn main() !void {
    var stdin = std.io.bufferedReader(std.io.getStdIn().reader());
    var stream = stdin.reader();
  
    var depth: u32 = std.math.maxInt(u32);
    var inc_count: u32 = 0;

    var buf: [32]u8 = undefined;
    while(try stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var depth_new = try std.fmt.parseInt(@TypeOf(depth), line, 10);
        if (depth_new > depth)
            inc_count += 1;

        depth = depth_new;
    }
    std.debug.print("depth increments: {}\n", .{inc_count});
}
