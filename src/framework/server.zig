const std = @import("std");
const App = @import("app.zig").App;

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
            // var buf: [1024]u8 = undefined;

            // const n = try conn.stream.read(&buf);

            const response =
                "HTTP/1.1 200 OK\r\n" ++
                "Content-Length: 12\r\n" ++
                "Content-Type: text/plain\r\n" ++
                "\r\n" ++
                "Hello world\n";

            // _ = n;

            try conn.stream.writeAll(response);
        }
    }
};
