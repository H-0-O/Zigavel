//! HTTP request parsing and representation.
//!
//! Request is built from a stream via `Request.parse()`. It holds method, URL,
//! and headers. Body parsing is not yet implemented (body is null).

const std = @import("std");

/// HTTP method from the request line.
pub const Method = enum(u4) {
    GET = 1,
    POST = 2,
    PUT = 3,
    DELETE = 4,
    PATCH = 5,
    OPTIONS = 6,
    HEAD = 7,

    /// Returns the method name as used in HTTP (e.g. "GET", "POST").
    pub fn asStr(self: Method) []const u8 {
        return switch (self) {
            .GET => "GET",
            .POST => "POST",
            .PUT => "PUT",
            .DELETE => "DELETE",
            .PATCH => "PATCH",
            .OPTIONS => "OPTIONS",
            .HEAD => "HEAD",
        };
    }
};

/// Parsed HTTP request: method, URL, headers. Body is currently always null.
pub const Request = struct {
    method: Method,
    url: []const u8,
    headers: std.StringHashMap([]const u8),
    body: ?[]const u8,
    allocator: std.mem.Allocator,

    /// Reads from the stream until the end of the headers (\\r\\n\\r\\n) and builds a Request. Caller must call deinit().
    pub fn parse(allocator: std.mem.Allocator, stream: *std.net.Stream) ParseErrors!Request {
        var buf: [8192]u8 = undefined;
        var used: usize = 0;

        while (true) {
            if (used == buf.len) return ParseErrors.BufferOverflow;
            const n = try stream.read(buf[used..]);

            used += n;

            if (findHeaderEnd(buf[0..used]) != null) break;
        }

        const data = buf[0..used];
        const header_end = findHeaderEnd(data).?;
        const header_block = data[0..header_end];

        var lines = std.mem.splitSequence(u8, header_block, "\r\n");

        const request_line = lines.next().?;
        var request_parts = std.mem.splitSequence(u8, request_line, " ");
        const method_str = request_parts.next() orelse return ParseErrors.InvalidRequestLine;
        const url = request_parts.next() orelse return ParseErrors.InvalidRequestLine;

        const method = parseMethod(method_str) orelse return ParseErrors.InvalidMethod;

        var headers = std.StringHashMap([]const u8).init(allocator);

        while (lines.next()) |line| {
            if (line.len == 0) break;
            if (std.mem.indexOfScalar(u8, line, ':')) |colon| {
                const name = std.mem.trim(u8, line[0..colon], " \t");
                const value = std.mem.trim(u8, line[colon + 1 ..], " \t");
                try headers.put(name, value);
            }
        }

        return Request{
            .method = method,
            .url = url,
            .headers = headers,
            .body = null,
            .allocator = allocator,
        };
    }

    /// Frees request-owned memory (e.g. headers map).
    pub fn deinit(self: *Request) void {
        self.headers.deinit();
    }
};

fn findHeaderEnd(data: []const u8) ?usize {
    return std.mem.indexOf(u8, data, "\r\n\r\n");
}

fn parseMethod(method_str: []const u8) ?Method {
    if (std.mem.eql(u8, method_str, "GET")) return Method.GET;
    if (std.mem.eql(u8, method_str, "POST")) return Method.POST;
    if (std.mem.eql(u8, method_str, "PUT")) return Method.PUT;
    if (std.mem.eql(u8, method_str, "DELETE")) return Method.DELETE;
    if (std.mem.eql(u8, method_str, "PATCH")) return Method.PATCH;
    if (std.mem.eql(u8, method_str, "OPTIONS")) return Method.OPTIONS;
    if (std.mem.eql(u8, method_str, "HEAD")) return Method.HEAD;
    return null;
}

/// Errors that may occur when parsing a request from a stream.
pub const ParseErrors = error{
    BufferOverflow,
    InvalidRequestLine,
    InvalidMethod,
} || std.net.Stream.ReadError || std.mem.Allocator.Error;
