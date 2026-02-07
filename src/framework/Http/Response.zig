const std = @import("std");

pub const Response = struct {
    status_code: u16,
    status_text: []const u8,
    headers: std.StringHashMap([]const u8),
    body: []const u8,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) Response {
        return Response{
            .status_code = 200,
            .status_text = "OK",
            .headers = std.StringHashMap([]const u8).init(allocator),
            .body = "",
            .allocator = allocator,
        };
    }

    pub fn status(self: *Response, code: u16, text: []const u8) void {
        self.status_code = code;
        self.status_text = text;
    }

    pub fn header(self: *Response, name: []const u8, value: []const u8) !void {
        try self.headers.put(name, value);
    }

    pub fn setBody(self: *Response, content: []const u8) void {
        self.body = content;
    }

    pub fn toHttpString(self: *const Response, allocator: std.mem.Allocator) ![]const u8 {
        var list = std.ArrayListUnmanaged(u8){};
        defer list.deinit(allocator);

        try list.writer(allocator).print("HTTP/1.1 {} {s}\r\n", .{ self.status_code, self.status_text });

        var headers_it = self.headers.iterator();
        while (headers_it.next()) |entry| {
            try list.writer(allocator).print("{s}: {s}\r\n", .{ entry.key_ptr.*, entry.value_ptr.* });
        }

        if (self.body.len > 0) {
            try list.writer(allocator).print("Content-Length: {}\r\n", .{self.body.len});
        }

        try list.writer(allocator).print("\r\n", .{});

        if (self.body.len > 0) {
            try list.writer(allocator).print("{s}", .{self.body});
        }

        return list.toOwnedSlice(allocator);
    }

    pub fn deinit(self: *Response) void {
        self.headers.deinit();
    }
};

