const std = @import("std");

pub fn dump(value: anytype) void {
    dumpImpl(value, 0);
    std.debug.print("\n", .{});
}

fn indent(level: usize) void {
    var i: usize = 0;
    while (i < level) : (i += 1) {
        std.debug.print("  ", .{});
    }
}

fn dumpImpl(value: anytype, level: usize) void {
    const T = @TypeOf(value);
    const ti = @typeInfo(T);

    switch (ti) {
        .bool, .int, .float, .comptime_int, .comptime_float, .@"enum", .error_set => {
            std.debug.print("{any}", .{value});
        },

        .optional => |opt| {
            if (value) |v| {
                std.debug.print("?", .{});
                dumpImpl(v, level);
            } else {
                std.debug.print("null", .{});
            }
            _ = opt;
        },

        .error_union => {
            if (value) |v| {
                dumpImpl(v, level);
            } else |err| {
                std.debug.print("error.{s}", .{@errorName(err)});
            }
        },

        .pointer => |p| {
            // Special-case slices and strings
            if (p.size == .slice) {
                const Child = p.child;

                // Treat []u8 / []const u8 as string-like
                if (Child == u8) {
                    std.debug.print("\"{s}\"", .{value});
                } else {
                    std.debug.print("[\n", .{});
                    for (value, 0..) |elem, i| {
                        indent(level + 1);
                        std.debug.print("{d}: ", .{i});
                        dumpImpl(elem, level + 1);
                        std.debug.print("\n", .{});
                    }
                    indent(level);
                    std.debug.print("]", .{});
                }
                return;
            }

            // One-item pointer: print pointee
            if (p.size == .one) {
                std.debug.print("&", .{});
                dumpImpl(value.*, level);
                return;
            }

            // Fallback
            std.debug.print("{any}", .{value});
        },

        .array => {
            std.debug.print("[\n", .{});
            for (value, 0..) |elem, i| {
                indent(level + 1);
                std.debug.print("{d}: ", .{i});
                dumpImpl(elem, level + 1);
                std.debug.print("\n", .{});
            }
            indent(level);
            std.debug.print("]", .{});
        },

        .@"struct" => |s| {
            std.debug.print("{s} {{\n", .{@typeName(T)});
            inline for (s.fields) |f| {
                indent(level + 1);
                std.debug.print("{s}: ", .{f.name});
                dumpImpl(@field(value, f.name), level + 1);
                std.debug.print("\n", .{});
            }
            indent(level);
            std.debug.print("}}", .{});
        },

        // Many other cases exist (union, vector, etc.)
        else => {
            // Fallback: let Zig print something reasonable
            std.debug.print("{any}", .{value});
        },
    }
}