const server = @import("server.zig");
const router = @import("router.zig");
const std = @import("std");

pub const App = struct {
    server: ?server.Server,
    router: router.Router,

    pub fn init(_router: router.Router) App {
        return App{
            .server = null,
            .router = _router,
        };
    }

    pub fn listen(self: *App, host: []const u8, port: u16) !void {
        self.server = server.Server.init(host, port);

        // Wrapper function that matches the expected signature
        const capture_wrapper = struct {
            fn call(ctx: *anyopaque, stream: *std.net.Stream) void {
                const app: *App = @ptrCast(@alignCast(ctx));
                app.capture(stream);
            }
        };

        try self.server.?.listen(capture_wrapper.call, self);
    }

    pub fn capture(self: *App, stream: *std.net.Stream) void {
        _ = self;
        headerExtraction(stream) catch |err| {
            std.debug.print("Error extracting headers: {}\n", .{err});
        };
    }
};

fn findHeaderEnd(data: []const u8) ?usize {
    return std.mem.indexOf(u8, data, "\r\n\r\n");
}

fn headerExtraction(stream: *std.net.Stream) HeaderErrors!void {
    var buf: [8192]u8 = undefined;
    var used: usize = 0;

    while (true) {
        if (used == buf.len) return HeaderErrors.BufferOverflow;
        const n = try stream.read(buf[used..]);

        used += n;

        if (findHeaderEnd(buf[0..used]) != null) break;
    }

    const data = buf[0..used];

    const header_end = findHeaderEnd(data).?;
    const header_block = data[0..header_end];

    var lines = std.mem.splitSequence(u8, header_block, "\r\n");

    const request_line = lines.next().?;

    std.debug.print("Request line: {s}\n", .{request_line});

    while (lines.next()) |line| {
        if (line.len == 0) break; // shouldn't happen because we cut before \r\n\r\n
        std.debug.print("Header: {s}\n", .{line});

        // If you want key/value:
        if (std.mem.indexOfScalar(u8, line, ':')) |colon| {
            const name = std.mem.trim(u8, line[0..colon], " \t");
            const value = std.mem.trim(u8, line[colon + 1 ..], " \t");
            std.debug.print("  name={s} value={s}\n", .{ name, value });
        }
    }
}

const HeaderErrors = error{
    BufferOverflow,
} || std.net.Stream.ReadError;
