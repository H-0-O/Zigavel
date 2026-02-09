//! Application bootstrap and request capture.
//!
//! App ties the Router to the Server: it parses incoming streams into Request,
//! resolves routes, dispatches to handlers, and writes the Response back. The
//! request lifecycle is: Parse → Resolve → Handler(Request, Response) → Write.

const server = @import("./Server.zig");
const routing = @import("routing");
const http = @import("http");
const alloc = @import("alloc");
const std = @import("std");

/// Central application: holds the Router and Server, and runs the request lifecycle per connection.
pub const App = struct {
    server: ?server.Server,
    router: routing.Router,

    /// Creates an App that will use the given router for route resolution.
    pub fn init(_router: routing.Router) App {
        return App{
            .server = null,
            .router = _router,
        };
    }

    /// Binds the server to host:port and runs the accept loop. Blocks; for each connection, capture() is invoked.
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

    /// Handles one connection: parse Request, resolve Route, call handler, serialize and write Response.
    /// Uses a request-scoped arena so all per-request allocations are freed in one shot when capture returns.
    fn capture(self: *App, stream: *std.net.Stream) void {
        var arena = alloc.requestArena();
        defer arena.deinit();
        const allocator = arena.allocator();

        var request = http.Request.parse(allocator, stream) catch |err| {
            std.debug.print("Error parsing request: {}\n", .{err});
            return;
        };
        defer request.deinit();

        var response = http.Response.init(allocator);
        defer response.deinit();

        const route: ?routing.Route = self.router.resolveRoute(request.method, request.url) catch |err| de: {
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
        // response_str is arena-owned; freed when arena.deinit() runs
        stream.writeAll(response_str) catch |err| {
            @panic(std.fmt.allocPrint(allocator, "writing stream failed: {any}", .{err}) catch "writing stream failed");
        };
    }
};
