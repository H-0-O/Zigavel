const std = @import("std");
const utils = @import("utils.zig");

pub const Router = struct {
    routes: std.ArrayList([]const u8),
    allocator: std.mem.Allocator,

    pub fn init() Router {
        const allocator = @import("alloc.zig").default_alloc;
        var router = Router{
            .routes = std.ArrayList([]const u8){},
            .allocator = allocator,
        };
        router.routes.ensureTotalCapacity(allocator, 0) catch {
            @panic("failed to initialize router");
        };
        return router;
    }

    pub fn get(self: *Router, route: []const u8) !void {
        try self.routes.append(self.allocator, route);
    }

    pub fn dump(self: *Router) void {
        utils.dump(self.routes);
    }
};
