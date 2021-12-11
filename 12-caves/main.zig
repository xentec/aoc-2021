const std = @import("std");
const pr = std.debug.print;

const Cave = struct {
    const Self = @This();
    const NameType = []const u8;
    const PathListType = std.ArrayList(NameType);

    name: NameType,
    paths: PathListType,

    fn init(alloc: std.mem.Allocator, name: []const u8) !Self {
        var self = Self {
            .name = name,
            .paths = PathListType.init(alloc),
        };
        return self;
    }

    fn isBig(self: *const Self) bool {
        return std.ascii.isUpper(self.name[0]);
    }

    fn addPath(self: *Self, other: []const u8) !void {
        try self.paths.append(other);
    }
};

fn addCave(list: *std.StringArrayHashMap(Cave), name: []const u8, path: []const u8) !void {
    var entry = try list.getOrPut(name);
    if (!entry.found_existing) {
        entry.value_ptr.* = try Cave.init(list.allocator, name);
    }
    try entry.value_ptr.addPath(path);
}

pub fn main() !void {
    var stdin = std.io.bufferedReader(std.io.getStdIn().reader());
    var input = stdin.reader();

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var alloc = arena.allocator();

    var caves = std.StringArrayHashMap(Cave).init(alloc);

    const input_buf = try input.readAllAlloc(alloc, 4096);
    var lines = std.mem.tokenize(u8, input_buf, "\n");
    while (lines.next()) |line| {
        var split = std.mem.tokenize(u8, line, "-");
        const a = split.next().?;
        const b = split.next().?;

        try addCave(&caves, a, b);
        try addCave(&caves, b, a);
    }

    for (caves.keys()) |cave| {
        pr("{s}: {s}\n", .{cave, caves.getPtr(cave).?.paths.items});
    }
    pr("\n", .{});

    var cave_start: *Cave = caves.getPtr("start").?;
    var cave_end: *Cave = caves.getPtr("end").?;

    var output: usize = 0;

    var visited = std.ArrayList(struct {cave: *Cave, depth: usize,}).init(alloc);
    var smalls = std.AutoArrayHashMap(*Cave, void).init(alloc);

    try smalls.put(cave_start, {});
    try visited.append(.{.cave=cave_start, .depth=0});
    while (visited.popOrNull()) |*step| {
        var cave = step.cave;
        pr("=>{s}\t[{}]", .{cave.name, step.depth});
        if(cave == cave_end) {
            output += 1;
            pr("\n\tnext: ", .{});
            for (visited.items) |s| {
                pr("{s}[{}], ", .{s.cave.name, s.depth});
            }
            pr("\n", .{});
            if (visited.items.len == 0)
                break;
            const visit_next = &visited.items[visited.items.len-1];
            while (step.depth > visit_next.depth) : (step.depth -= 1) {
                const s = smalls.pop();
                pr("-{s} ", .{s.key.name});
            }
            pr("\n", .{});
            if (visited.items.len == 1)
                pr("============================\n", .{});
            continue;
        }
        pr("\n", .{});

        if (!cave.isBig()) {
            pr("<<{s}\n", .{cave.name});
            try smalls.put(cave, {});
        }

        for (cave.paths.items) |new_path| {
            var cave_next = caves.getPtr(new_path).?;
            if(!smalls.contains(cave_next) and (cave.isBig() or cave_next.paths.items.len > 1))
            {
                pr("+{s} ", .{cave_next.name});
                try visited.append(.{.cave=cave_next, .depth=smalls.count()});
            }
        }
        pr("\n", .{});
    }
    pr("\n", .{});

    std.fmt.format(std.io.getStdOut().writer(), "{}\n", .{output}) catch unreachable;
}
