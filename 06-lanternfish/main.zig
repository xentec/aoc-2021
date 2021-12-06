const std = @import("std");


pub fn main() !void {
    var stdin = std.io.bufferedReader(std.io.getStdIn().reader());
    var stream = stdin.reader();

    var bucket = std.mem.zeroes([9]u64);

    // Read lines
    var buf: [16]u8 = undefined;
    while (try stream.readUntilDelimiterOrEof(&buf, ',')) |str| {
        const timer = try std.fmt.parseUnsigned(u4, std.mem.trim(u8, str, "\n "), 8);
        bucket[timer] += 1;
    }

    var day: usize = 0;
    while (day < 256) : (day += 1) {
        bucket[7] += bucket[0];
        std.mem.rotate(u64, &bucket, 1);
    }
    var sum: u64 = 0;
    for (bucket) |count| {
        sum += count;
    }
    std.debug.print("{}\n", .{sum});
}
