const std = @import("std");
const Http = @import("../Http/Response.zig");

pub const Server = struct {
    host: []const u8,
    port: u16,

    pub fn init(host: []const u8, port: u16) Server {
        return Server{ .host = host, .port = port };
    }

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
