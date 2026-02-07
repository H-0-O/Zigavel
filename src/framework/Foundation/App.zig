const server = @import("./Server.zig");
const router = @import("../Routing/Router.zig");
const Http = @import("../Http/Request.zig");
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
        var request = Http.Request.parse(allocator, stream) catch |err| {
            std.debug.print("Error parsing request: {}\n", .{err});
            return;
        };
        defer request.deinit();

        // TODO: Route matching and handler invocation
        // _ = self.router.routes[0];
        self.router.routes.items[0].handler(request);

    }
};

