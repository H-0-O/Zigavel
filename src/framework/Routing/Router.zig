const std = @import("std");
const utils = @import("../utils.zig");
const Route = @import("Route.zig").Route;
const Http = @import("../Http/Request.zig");

pub const Router = struct {
    routes: std.ArrayListUnmanaged(Route),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) Router {
        return Router{
            .routes = .{},
            .allocator = allocator,
        };
    }

    pub fn get(self: *Router, route: []const u8, handler: *const fn (Http.Request) void) !void {
        try self.routes.append(self.allocator, Route{
            .url = route,
            .method = Http.Method.GET,
            .handler = handler,
        });
    }

    pub fn dump(self: *Router) void {
        utils.dump(self.routes.items);
    }

    pub fn deinit(self: *Router) void {
        self.routes.deinit(self.allocator);
    }
};

