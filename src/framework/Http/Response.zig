const std = @import("std");

pub const Response = struct {
    status_code: u16,
    status_text: []const u8,
    headers: std.StringHashMap([]const u8),
    body: []const u8,
    body_owned: bool,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) Response {
        return Response{
            .status_code = 200,
            .status_text = "OK",
            .headers = std.StringHashMap([]const u8).init(allocator),
            .body = "",
            .body_owned = false,
            .allocator = allocator,
        };
    }

    fn defaultStatusText(code: u16) []const u8 {
        return switch (code) {
            200 => "OK",
            201 => "Created",
            204 => "No Content",
            400 => "Bad Request",
            404 => "Not Found",
            500 => "Internal Server Error",
            else => "Unknown",
        };
    }

    pub fn statusCode(self: *Response, code: u16) *Response {
        self.status_code = code;
        self.status_text = defaultStatusText(code);
        return self;
    }

    pub fn status(self: *Response, code: u16, text: []const u8) *Response {
        self.status_code = code;
        self.status_text = text;
        return self;
    }

    pub fn header(self: *Response, name: []const u8, value: []const u8) !*Response {
        try self.headers.put(name, value);
        return self;
    }

    pub fn setBody(self: *Response, content: []const u8) *Response {
        if (self.body_owned) {
            self.allocator.free(self.body);
            self.body_owned = false;
        }
        self.body = content;
        return self;
    }

    fn hasHeaderIgnoreCase(self: *const Response, name: []const u8) bool {
        var it = self.headers.iterator();
        while (it.next()) |entry| {
            if (std.ascii.eqlIgnoreCase(entry.key_ptr.*, name)) return true;
        }
        return false;
    }

    pub fn toHttpString(self: *const Response, allocator: std.mem.Allocator) ![]const u8 {
        var list = std.ArrayListUnmanaged(u8){};
        defer list.deinit(allocator);

        try list.writer(allocator).print("HTTP/1.1 {} {s}\r\n", .{ self.status_code, self.status_text });

        var headers_it = self.headers.iterator();
        while (headers_it.next()) |entry| {
            try list.writer(allocator).print("{s}: {s}\r\n", .{ entry.key_ptr.*, entry.value_ptr.* });
        }

        if (self.body.len > 0 and !self.hasHeaderIgnoreCase("Content-Length")) {
            try list.writer(allocator).print("Content-Length: {}\r\n", .{self.body.len});
        }

        try list.writer(allocator).print("\r\n", .{});

        if (self.body.len > 0) {
            try list.writer(allocator).print("{s}", .{self.body});
        }

        return list.toOwnedSlice(allocator);
    }

    pub fn json(self: *Response, data: anytype) !void {
        if (self.body_owned) {
            self.allocator.free(self.body);
            self.body_owned = false;
        }

        var out: std.io.Writer.Allocating = .init(self.allocator);
        defer out.deinit();

        try std.json.Stringify.value(data, .{}, &out.writer);
        const str = try out.toOwnedSlice();

        self.body = str;
        self.body_owned = true;
        try self.headers.put("Content-Type", "application/json");
    }

    pub fn jsonUnmanaged(self: *Response, json_body: []const u8) !void {
        if (self.body_owned) {
            self.allocator.free(self.body);
            self.body_owned = false;
        }
        self.body = json_body;
        try self.headers.put("Content-Type", "application/json");
    }

    pub fn deinit(self: *Response) void {
        if (self.body_owned) {
            self.allocator.free(self.body);
            self.body_owned = false;
        }
        self.headers.deinit();
    }
};
