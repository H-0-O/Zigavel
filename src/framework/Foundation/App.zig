const server = @import("./Server.zig");
const router = @import("../Routing/Router.zig");
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

        // TODO: Route matching and handler invocation
        // _ = self.router.routes[0];
        const route = self.router.resolveRoute(request.method, request.url) catch |err| {
            std.debug.print("Error resolving route: {}\n", .{err});
            return;
        };
        var response = HttpResponse.Response.init(allocator);
        defer response.deinit();

        route.handler(&request, &response);

        // response.setBody("Hello world\n");
        // try response.header("Content-Type", "text/plain");

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
