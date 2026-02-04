const std = @import("std");
const utils = @import("utils.zig");

const Method = enum {
    GET,
    POST,
    PUT,
    DELETE,
    PATCH,
    OPTIONS,
    HEAD,
};

const Route = struct {
    url: []const u8,
    method: Method,
    handler: *const fn () void,
};

pub const Router = struct {
    routes: std.AutoHashMap(std.StringHashMap([]const u8), Route),
    allocator: std.mem.Allocator,

    pub fn init() Router {
        const allocator = @import("alloc.zig").default_alloc;
        var router = Router{
            .routes = std.AutoHashMap(std.StringHashMap([]const u8), Route).init(allocator),
            .allocator = allocator,
        };
        router.routes.ensureTotalCapacity(0) catch {
            @panic("failed to initialize router");
        };
        return router;
    }

    pub fn get(self: *Router, route: []const u8, handler: *const fn () void) !void {
        const key = std.StringHashMap([]const u8).init(self.allocator);
        try self.routes.put(key, Route{
            .url = route,
            .method = Method.GET,
            .handler = handler,
        });
    }

    pub fn dump(self: *Router) void {
        utils.dump(self.routes);
    }
};
