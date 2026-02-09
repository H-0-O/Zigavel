//! Debug dump: prints a value (structs, hashmaps, slices, etc.) to stderr with limited depth.

const std = @import("std");

const MAX_DEPTH: usize = 8;

/// Recursively prints a value to stderr, up to MAX_DEPTH levels. Handles structs, hashmaps, slices, optionals.
pub fn dump(value: anytype) void {
    dumpImpl(@TypeOf(value), value, 0);
    std.debug.print("\n", .{});
}

fn dumpImpl(
    comptime T: type,
    value: T,
    level: usize,
) void {
    if (level >= MAX_DEPTH) {
        std.debug.print("...", .{});
        return;
    }

    switch (@typeInfo(T)) {
        .bool,
        .int,
        .float,
        .comptime_int,
        .comptime_float,
        .@"enum",
        .error_set,
        => {
            std.debug.print("{any}", .{value});
        },

        .optional => |opt| {
            if (value) |v| {
                std.debug.print("?", .{});
                dumpImpl(opt.child, v, level);
            } else {
                std.debug.print("null", .{});
            }
        },

        .error_union => |eu| {
            if (value) |v| {
                dumpImpl(eu.payload, v, level);
            } else |err| {
                std.debug.print("error.{s}", .{@errorName(err)});
            }
        },

        .pointer => |p| {
            switch (p.size) {
                .slice => {
                    if (p.child == u8) {
                        // string-like
                        std.debug.print("\"{s}\"", .{value});
                    } else {
                        std.debug.print("[\n", .{});
                        for (value, 0..) |elem, i| {
                            indentRuntime(level + 1);
                            std.debug.print("{d}: ", .{i});
                            dumpImpl(p.child, elem, level + 1);
                            std.debug.print("\n", .{});
                        }
                        indentRuntime(level);
                        std.debug.print("]", .{});
                    }
                },
                .one => {
                    dumpPointerOne(T, value, level, p);
                },
                .many, .c => {
                    dumpPointerMany(T, value, p);
                },
            }
        },

        .array => |a| {
            std.debug.print("[\n", .{});
            inline for (0..a.len) |i| {
                indentRuntime(level + 1);
                std.debug.print("{d}: ", .{i});
                dumpImpl(a.child, value[i], level + 1);
                std.debug.print("\n", .{});
            }
            indentRuntime(level);
            std.debug.print("]", .{});
        },

        .@"struct" => |s| {
            if (comptime isHashMapType(T)) {
                dumpHashMapTyped(T, value, level);
            } else {
                std.debug.print("{s} {{\n", .{@typeName(T)});
                inline for (s.fields) |f| {
                    indentRuntime(level + 1);
                    std.debug.print("{s}: ", .{f.name});
                    dumpImpl(f.type, @field(value, f.name), level + 1);
                    std.debug.print("\n", .{});
                }
                indentRuntime(level);
                std.debug.print("}}", .{});
            }
        },

        else => {
            std.debug.print("<{s}>", .{@typeName(T)});
        },
    }
}

fn dumpPointerOne(
    comptime T: type,
    value: T,
    level: usize,
    comptime p: std.builtin.Type.Pointer,
) void {
    // Check if child type is a function pointer or anyopaque at comptime
    const child_info = @typeInfo(p.child);
    switch (child_info) {
        .@"fn" => {
            // Function pointer - can't dereference safely
            std.debug.print("&<fn>", .{});
        },
        .@"opaque" => {
            // Opaque type - can't dump contents
            std.debug.print("&<opaque>", .{});
        },
        else => {
            // Regular pointer - can dereference
            // Check if pointer is null (for allowzero pointers)
            if (p.is_allowzero) {
                if (value == null) {
                    std.debug.print("&null", .{});
                    return;
                }
            }
            std.debug.print("&", .{});
            dumpImpl(p.child, value.*, level);
        },
    }
}

fn dumpPointerMany(
    comptime T: type,
    value: T,
    comptime p: std.builtin.Type.Pointer,
) void {
    // Check if child type is a function pointer at comptime
    const child_info = @typeInfo(p.child);
    switch (child_info) {
        .@"fn" => {
            std.debug.print("<ptr><fn>", .{});
        },
        else => {
            if (p.is_allowzero and value == null) {
                std.debug.print("<ptr>null", .{});
            } else {
                std.debug.print("<ptr>", .{});
                // For many/c pointers, we can't safely dereference without length
                // Just show the address
                std.debug.print("@0x{x}", .{@intFromPtr(value)});
            }
        },
    }
}

fn isHashMapType(comptime T: type) bool {
    if (@typeInfo(T) != .@"struct") return false;
    const name = @typeName(T);
    // Only std.HashMap / std.StringHashMap; "hash_map.HashMap(" excludes StringContext etc.
    return std.mem.indexOf(u8, name, "hash_map.HashMap(") != null;
}

fn dumpHashMapTyped(comptime T: type, value: T, level: usize) void {
    var m = value;
    var it = m.iterator();
    const count = m.count();
    std.debug.print("HashMap({}) {{\n", .{count});
    while (it.next()) |entry| {
        indentRuntime(level + 1);
        dumpImpl(@TypeOf(entry.key_ptr.*), entry.key_ptr.*, level + 1);
        std.debug.print(" => ", .{});
        dumpImpl(@TypeOf(entry.value_ptr.*), entry.value_ptr.*, level + 1);
        std.debug.print("\n", .{});
    }
    indentRuntime(level);
    std.debug.print("}}", .{});
}

fn indentRuntime(level: usize) void {
    for (0..level) |_| {
        std.debug.print("  ", .{});
    }
}
