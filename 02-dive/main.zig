const std = @import("std");

const Command = struct {
    const Type = enum {
        forward,
        up,
        down,
    };

    type: Type,
    value: i32,
};


pub fn main() !void {
    var stdin = std.io.bufferedReader(std.io.getStdIn().reader());
    var stream = stdin.reader();
  
    var aim: i32 = 0;
    var depth: i32 = 0;
    var position: i32 = 0;

    var buf: [32]u8 = undefined;
    while(try stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var splitter = std.mem.split(u8, line, " ");

        var cmd = Command {
            .type = std.meta.stringToEnum(Command.Type, splitter.next().?).?,
            .value = try std.fmt.parseInt(i32, splitter.next().?, 10),
        };

        switch(cmd.type) {
            .down => aim += cmd.value,
            .up => aim -= cmd.value,
            .forward => {
                position += cmd.value;
                depth += cmd.value * aim;
            },
        }

    }
    std.debug.print("dive position: {}, depth: {}; ({})\n", .{position, depth, position*depth});
}
