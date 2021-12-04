const std = @import("std");

fn findRating(numbers: []u12, most: bool) u12 {
    const NumType = @TypeOf(numbers[0]);

    std.sort.sort(NumType, numbers, {}, comptime std.sort.desc(NumType));
    var shift: u4 = @bitSizeOf(NumType) - 1;
    var nums = numbers;
    while (nums.len > 1) {
        var idx = nums.len / 2;
        const shiftedBit = @as(NumType, 1) << shift;
        shift -= 1;
        const middleBit = nums[idx] & shiftedBit;
        const incr = if (middleBit > 0) @as(isize, 1) else @as(isize, -1);
        if (nums.len > 2) {
            while (nums[idx] & shiftedBit == middleBit) // find 1->0 change offset
                idx = @intCast(usize, @intCast(isize, idx) + incr);

            if (incr == -1)
                idx += 1;
        }
        const ones = nums[0..idx];
        const zeroes = nums[idx..];
        const takeOnes = if (ones.len == zeroes.len) most else most and ones.len > zeroes.len or !most and ones.len < zeroes.len;
        nums = if (takeOnes) ones else zeroes;
    }
    return nums[0];
}

pub fn main() !void {
    var stdin = std.io.bufferedReader(std.io.getStdIn().reader());
    var stream = stdin.reader();

    const NumType = u12;
    var numbers = try std.ArrayList(NumType).initCapacity(std.heap.page_allocator, 1024);
    defer numbers.deinit();

    var buf: [16]u8 = undefined;
    while (try stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        const num = try std.fmt.parseUnsigned(NumType, line, 2);
        try numbers.append(num);
    }

    const o2Rating = findRating(numbers.items, true);
    const co2Rating = findRating(numbers.items, false);

    std.debug.print("O2 rating: {}, CO2 rating: {} ({})\n", .{ o2Rating, co2Rating, @as(u32, o2Rating) * co2Rating });
}
