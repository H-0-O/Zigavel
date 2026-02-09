//! TCP server: listens on a host/port and invokes a capture callback for each accepted connection.
//! Used by App to run the request loop; applications typically do not use Server directly.

const std = @import("std");
const Http = @import("../Http/Response.zig");

/// Low-level TCP listener. Accepts connections and calls the provided capture function with the stream.
pub const Server = struct {
    host: []const u8,
    port: u16,

    /// Creates a Server that will listen on the given host and port.
    pub fn init(host: []const u8, port: u16) Server {
        return Server{ .host = host, .port = port };
    }

    /// Listens and blocks; for each accepted connection, calls `capture(ctx, &stream)`. Caller closes the stream when done.
    pub fn listen(self: Server, capture: *const fn (ctx: *anyopaque, stream: *std.net.Stream) void, ctx: *anyopaque) !void {
        const address = try std.net.Address.parseIp(self.host, self.port);
        var sr = try address.listen(.{ .reuse_address = true });

        defer sr.deinit();

        std.debug.print("Listen Server on {s}:{}\n", .{ self.host, self.port });

        while (true) {
            var conn = try sr.accept();
            defer conn.stream.close();

            std.debug.print("Client Connected \n", .{});

            capture(ctx, &conn.stream);
        }
    }
};
