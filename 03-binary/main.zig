const std = @import("std");

pub fn main() !void {
    var stdin = std.io.bufferedReader(std.io.getStdIn().reader());
    var stream = stdin.reader();
  
    var counter = std.mem.zeroes([12]i32);

    var buf: [32]u8 = undefined;
    while(try stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        for (line) |bit, idx|
            counter[idx] += if (bit == '1') @as(i32, 1) else @as(i32, -1);
    }

    var gamma: u12 = 0;
    for (counter) |bitCount, idx| {
        const bit: u12 = @boolToInt(bitCount > 0);
        gamma |= bit <<| @intCast(u12, counter.len - idx - 1);
    }
    var epsilon: u12 = ~gamma;
    var powerConsumption = @as(u32, gamma) * epsilon;

    std.debug.print("power consumption: {}\n", .{powerConsumption});
}
