const std = @import("std");
const pr = std.debug.print;

fn digit7(num: u8) u21 { return @as(u21,'🯰')+num; }

fn patternToBits(pattern: []const u8) u7 {
    var seg: u7 = 0;
    const bit: u7 = 1;
    for (pattern) |c|
        seg |= bit << @intCast(u3, c - 'a');

    return seg;
}

pub fn main() !void {
    var stdin = std.io.bufferedReader(std.io.getStdIn().reader());
    var stream = stdin.reader();

    var count: usize = 0;
    var buf: [128]u8 = undefined;
    while (try stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var split = std.mem.tokenize(u8, line, "|");
        var patterns = std.mem.tokenize(u8, split.next().?, " ");
        var outputs = std.mem.tokenize(u8, split.next().?, " ");

        var seg4: u7 = undefined;
        var seg7: u7 = undefined;
        while (patterns.next()) |pattern| {
            switch(pattern.len) {
                3 => seg7 = patternToBits(pattern),
                4 => seg4 = patternToBits(pattern),
                else => {},
            }
        }

        var num: u32 = 0;
        while (outputs.next()) |output| {
            const seg = patternToBits(output);
            const digit: u4 = switch(@popCount(u7, seg)) {
                2 => 1, // 🯱
                3 => 7, // 🯷
                4 => 4, // 🯴
                7 => 8, // 🯸
                // 🯲,🯳,🯵
                5 => if (seg & seg7 == seg7) @as(u4, 3)
                    else if(@popCount(u7, seg & seg4) == 2) @as(u4, 2)
                    else @as(u4, 5),
                // 🯶,🯹,🯰
                6 => if (seg & seg4 == seg4) @as(u4, 9)
                    else if(seg & seg7 == seg7) @as(u4, 0)
                    else @as(u4, 6),
                else => unreachable,
            };
            num = num * 10 + digit;
        }
        count += num;
    }
    pr("{}\n", .{count});
}
