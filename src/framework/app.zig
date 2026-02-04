const server = @import("server.zig");
const router = @import("router.zig");

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
        try self.server.?.listen();
    }
};
