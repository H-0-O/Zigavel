const server = @import("./Server.zig");
const router = @import("../Routing/Router.zig");
const Route = @import("../Routing/Route.zig").Route;
const HttpRequest = @import("../Http/Request.zig");
const HttpResponse = @import("../Http/Response.zig");
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
        const allocator = @import("../alloc.zig").default_alloc;
        var request = HttpRequest.Request.parse(allocator, stream) catch |err| {
            std.debug.print("Error parsing request: {}\n", .{err});
            return;
        };
        defer request.deinit();

        var response = HttpResponse.Response.init(allocator);
        defer response.deinit();

        const route: ?Route = self.router.resolveRoute(request.method, request.url) catch |err| de: {
            switch (err) {
                error.routeNotFound => {
                    _ = response.statusCode(404).setBody("Route Not Found");
                    break :de null;
                },
                else => {
                    _ = response.statusCode(500).setBody("Something went wrong");
                    break :de null;
                },
            }
        };

        if (route) |r| {
            r.handler(&request, &response) catch |err| {
                std.debug.print("Handler error: {}\n", .{err});
                _ = response.statusCode(500).setBody("Internal Server Error");
            };
        }

        const response_str = response.toHttpString(allocator) catch |err| blk: {
            std.debug.print("Error building response: {}\n", .{err});
            const body = "Internal Server Error";
            break :blk std.fmt.allocPrint(allocator, "HTTP/1.1 500 Internal Server Error\r\nContent-Length: {d}\r\n\r\n{s}", .{ body.len, body }) catch @panic("cannot build 500 response");
        };
        defer allocator.free(response_str);
        stream.writeAll(response_str) catch |err| {
            @panic(std.fmt.allocPrint(allocator, "writing stream failed: {any}", .{err}) catch "writing stream failed");
        };
    }
};
