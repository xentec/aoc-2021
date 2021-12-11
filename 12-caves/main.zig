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

    fn isSmall(self: *const Self) bool {
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

    var cave_start: *Cave = caves.getPtr("start").?;
    var cave_end: *Cave = caves.getPtr("end").?;

    var output: usize = 0;
    const Step = struct {
        const Self = @This();
        cave: *Cave,
        next: std.ArrayList(*Cave),

        fn init(a: std.mem.Allocator, cave: *Cave) !@This() {
            return Self {.cave=cave,.next=std.ArrayList(*Cave).init(a)};
        }
        fn deinit(self: *Self) void {
            self.next.deinit();
        }
    };

    var path = std.ArrayList(Step).init(alloc);
    var visited = std.AutoHashMap(*Cave, void).init(alloc);
    var extra: ?*Cave = null;

    try path.append(try Step.init(alloc, cave_start));
    while (path.items.len > 0) {
        var step = &path.items[path.items.len-1];
        var cave = step.cave;

        if(cave == cave_end) {
            output += 1;
            path.pop().deinit();
            continue;
        }

        if (step.next.capacity == 0) { // never visited
            if (cave.isSmall()) {
                var entry = try visited.getOrPut(cave);
                if(entry.found_existing)
                    extra = cave;
            }
            for (cave.paths.items) |new_path| {
                var cave_next = caves.getPtr(new_path).?;
                if (cave_next.isSmall()) {
                    if(cave_next == cave_start)
                        continue;

                    if(visited.contains(cave_next)) {
                        if (extra) |_|
                            continue;
                    }
                }
                try step.next.append(cave_next);
            }
        }

        if (step.next.popOrNull()) |next| {
            try path.append(try Step.init(alloc, next));
        } else {
            var s = path.pop();
            if (s.cave.isSmall()) {
                const in_extra = if (extra) |e| e == s.cave else false;
                if (in_extra) {
                    extra = null;
                } else
                    _ = visited.remove(s.cave);
            }
            s.deinit();
            continue;
        }
    }
    std.fmt.format(std.io.getStdOut().writer(), "{}\n", .{output}) catch unreachable;
}
