const std = @import("std");
const utils = @import("../utils.zig");
const FnHandler = @import("Route.zig").Handler;
const Route = @import("Route.zig").Route;
const Http = @import("../Http/Request.zig");

pub const Router = struct {
    routes: std.StringHashMap(Route),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) Router {
        return Router{
            .routes = std.StringHashMap(Route).init(allocator),
            .allocator = allocator,
        };
    }

    pub fn get(self: *Router, route: []const u8, handler: FnHandler) !void {
        const key = try std.fmt.allocPrint(self.allocator, "{s}{s}", .{ Http.Method.GET.asStr(), route });
        try self.routes.put(key, Route{
            .url = route,
            .method = Http.Method.GET,
            .handler = handler,
        });
    }

    pub fn post(self: *Router, route: []const u8, handler: FnHandler) !void {
        const key = try std.fmt.allocPrint(self.allocator, "{s}{s}", .{ Http.Method.POST.asStr(), route });
        try self.routes.put(key, Route{
            .url = route,
            .method = Http.Method.POST,
            .handler = handler,
        });
    }

    pub fn put(self: *Router, route: []const u8, handler: FnHandler) !void {
        const key = try std.fmt.allocPrint(self.allocator, "{s}{s}", .{ Http.Method.PUT.asStr(), route });
        try self.routes.put(key, Route{
            .url = route,
            .method = Http.Method.PUT,
            .handler = handler,
        });
    }

    pub fn delete(self: *Router, route: []const u8, handler: FnHandler) !void {
        const key = try std.fmt.allocPrint(self.allocator, "{s}{s}", .{ Http.Method.DELETE.asStr(), route });
        try self.routes.put(key, Route{
            .url = route,
            .method = Http.Method.DELETE,
            .handler = handler,
        });
    }

    pub fn patch(self: *Router, route: []const u8, handler: FnHandler) !void {
        const key = try std.fmt.allocPrint(self.allocator, "{s}{s}", .{ Http.Method.PATCH.asStr(), route });
        try self.routes.put(key, Route{
            .url = route,
            .method = Http.Method.PATCH,
            .handler = handler,
        });
    }

    pub fn options(self: *Router, route: []const u8, handler: FnHandler) !void {
        const key = try std.fmt.allocPrint(self.allocator, "{s}{s}", .{ Http.Method.OPTIONS.asStr(), route });
        try self.routes.put(key, Route{
            .url = route,
            .method = Http.Method.OPTIONS,
            .handler = handler,
        });
    }

    pub fn head(self: *Router, route: []const u8, handler: FnHandler) !void {
        const key = try std.fmt.allocPrint(self.allocator, "{s}{s}", .{ Http.Method.HEAD.asStr(), route });
        try self.routes.put(key, Route{
            .url = route,
            .method = Http.Method.HEAD,
            .handler = handler,
        });
    }

    pub fn resolveRoute(self: *Router, method: Http.Method, url: []const u8) (RoutesError || std.mem.Allocator.Error)!Route {
        const key = try std.fmt.allocPrint(self.allocator, "{s}{s}", .{ method.asStr(), url });
        defer self.allocator.free(key);
        const route = self.routes.get(key);
        if (route == null) {
            return RoutesError.routeNotFound;
        }
        return route.?;
    }

    pub fn dump(self: *Router) void {
        utils.dump(self.routes.items);
    }

    pub fn deinit(self: *Router) void {
        var it = self.routes.keyIterator();
        while (it.next()) |key_ptr| {
            self.allocator.free(key_ptr.*);
        }
        self.routes.deinit();
    }
};

const RoutesError = error{routeNotFound};
