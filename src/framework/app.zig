const router = @import("router.zig");
const server = @import("server.zig");


pub const App = struct {
    router: router.Router,
    server: ?server.Server,

    pub fn init() App{
        return App {
            .router = router.Router.init(),
            .server = null,
        };
    }

    pub fn listen(self: *App , host: []const u8 , port: u16) !void {
        self.server = server.Server.init(host , port);
        try self.server.?.listen();
    }
};