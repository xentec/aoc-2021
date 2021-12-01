const std = @import("std");

pub fn main() !void {
    var stdin = std.io.bufferedReader(std.io.getStdIn().reader());
    var stream = stdin.reader();
  
    var depth_window: [3]u32 = undefined;
    var depth_window_idx: usize = 0;
    var depth_window_sum: u32 = std.math.maxInt(u32);
    var inc_count: u32 = 0;

    var buf: [32]u8 = undefined;
    while(try stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var depth_new = try std.fmt.parseInt(@TypeOf(depth_window[0]), line, 10);
        depth_window[depth_window_idx % depth_window.len] = depth_new;
        depth_window_idx += 1;
        if (depth_window_idx < depth_window.len)
            continue;

        var window_sum: u32 = 0;
        for (depth_window) |depth|
            window_sum += depth;

        if (window_sum > depth_window_sum)
            inc_count += 1;

        depth_window_sum = window_sum;
    }
    std.debug.print("depth window increments: {}\n", .{inc_count});
}
