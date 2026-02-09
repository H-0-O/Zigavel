//! HTTP response building and serialization.
//!
//! Response holds status, headers, and body. Use fluent methods (statusCode, header, setBody, json)
//! to build the response; then toHttpString() produces the raw HTTP bytes. The framework calls
//! toHttpString and writes to the stream; handlers typically only build the response.

const std = @import("std");

/// Mutable HTTP response: status, headers, body. Create with init(), then chain statusCode/header/setBody/json.
pub const Response = struct {
    status_code: u16,
    status_text: []const u8,
    headers: std.StringHashMap([]const u8),
    body: []const u8,
    body_owned: bool,
    allocator: std.mem.Allocator,

    /// Creates a 200 OK response with empty body. Caller must call deinit() when done.
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

    /// Sets status code and default status text. Returns self for chaining.
    pub fn statusCode(self: *Response, code: u16) *Response {
        self.status_code = code;
        self.status_text = defaultStatusText(code);
        return self;
    }

    /// Sets status code and custom status text. Returns self for chaining.
    pub fn status(self: *Response, code: u16, text: []const u8) *Response {
        self.status_code = code;
        self.status_text = text;
        return self;
    }

    /// Adds a response header. Returns self for chaining.
    pub fn header(self: *Response, name: []const u8, value: []const u8) !*Response {
        try self.headers.put(name, value);
        return self;
    }

    /// Sets the response body (no ownership transfer). Frees any previous body owned by Response. Returns self for chaining.
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

    /// Serializes the response to a full HTTP/1.1 message. Caller must free the returned slice.
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

    /// Serializes `data` to JSON, sets body and Content-Type: application/json. Response owns the allocated body.
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

    /// Sets body to pre-serialized JSON and Content-Type. Caller keeps ownership of json_body.
    pub fn jsonUnmanaged(self: *Response, json_body: []const u8) !void {
        if (self.body_owned) {
            self.allocator.free(self.body);
            self.body_owned = false;
        }
        self.body = json_body;
        try self.headers.put("Content-Type", "application/json");
    }

    /// Frees response-owned memory (e.g. JSON body, headers map).
    pub fn deinit(self: *Response) void {
        if (self.body_owned) {
            self.allocator.free(self.body);
            self.body_owned = false;
        }
        self.headers.deinit();
    }
};

// --- Tests ---

const testing = std.testing;

test "Response init defaults" {
    var res = Response.init(testing.allocator);
    defer res.deinit();
    try testing.expect(res.status_code == 200);
    try testing.expectEqualStrings("OK", res.status_text);
    try testing.expect(res.body.len == 0);
    try testing.expect(!res.body_owned);
}

test "Response statusCode and chaining" {
    var res = Response.init(testing.allocator);
    defer res.deinit();
    _ = res.statusCode(201);
    try testing.expect(res.status_code == 201);
    try testing.expectEqualStrings("Created", res.status_text);
    _ = res.statusCode(204);
    try testing.expect(res.status_code == 204);
    try testing.expectEqualStrings("No Content", res.status_text);
}

test "Response status with custom text" {
    var res = Response.init(testing.allocator);
    defer res.deinit();
    _ = res.status(418, "I'm a teapot");
    try testing.expect(res.status_code == 418);
    try testing.expectEqualStrings("I'm a teapot", res.status_text);
}

test "Response header" {
    var res = Response.init(testing.allocator);
    defer res.deinit();
    _ = try res.header("X-Custom", "value");
    try testing.expect(res.headers.get("X-Custom") != null);
    try testing.expectEqualStrings("value", res.headers.get("X-Custom").?);
}

test "Response setBody" {
    var res = Response.init(testing.allocator);
    defer res.deinit();
    _ = res.setBody("hello");
    try testing.expectEqualStrings("hello", res.body);
}

test "Response toHttpString format" {
    var res = Response.init(testing.allocator);
    defer res.deinit();
    _ = res.statusCode(200).setBody("ok");
    const raw = try res.toHttpString(testing.allocator);
    defer testing.allocator.free(raw);
    try testing.expect(std.mem.startsWith(u8, raw, "HTTP/1.1 200 OK\r\n"));
    try testing.expect(std.mem.endsWith(u8, raw, "ok"));
}

test "Response json sets body and Content-Type" {
    var res = Response.init(testing.allocator);
    defer res.deinit();
    const Payload = struct { name: []const u8, n: u8 };
    try res.json(Payload{ .name = "test", .n = 42 });
    try testing.expect(res.headers.get("Content-Type") != null);
    try testing.expectEqualStrings("application/json", res.headers.get("Content-Type").?);
    try testing.expect(res.body_owned);
    try testing.expect(std.mem.indexOf(u8, res.body, "test") != null);
    try testing.expect(std.mem.indexOf(u8, res.body, "42") != null);
}
