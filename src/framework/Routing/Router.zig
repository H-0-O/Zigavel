//! Route registration and resolution.
//!
//! Router maps (method, path) to Route. Register routes with get(), post(), etc.;
//! the App calls resolveRoute() to find the handler for each request. Matching is exact (no path params yet).

const std = @import("std");
const utils = @import("../utils.zig");
const FnHandler = @import("Route.zig").Handler;
const Route = @import("Route.zig").Route;
const Http = @import("../Http/Request.zig");

/// Holds registered routes and resolves them by method and URL.
pub const Router = struct {
    routes: std.StringHashMap(Route),
    allocator: std.mem.Allocator,

    /// Initializes the router with the given allocator (used for route keys and internal data).
    pub fn init(allocator: std.mem.Allocator) Router {
        return Router{
            .routes = std.StringHashMap(Route).init(allocator),
            .allocator = allocator,
        };
    }

    /// Registers a GET route.
    pub fn get(self: *Router, route: []const u8, handler: FnHandler) !void {
        const key = try std.fmt.allocPrint(self.allocator, "{s}-{s}", .{ Http.Method.GET.asStr(), route });
        try self.routes.put(key, Route{
            .url = route,
            .method = Http.Method.GET,
            .handler = handler,
        });
    }

    /// Registers a POST route.
    pub fn post(self: *Router, route: []const u8, handler: FnHandler) !void {
        const key = try std.fmt.allocPrint(self.allocator, "{s}-{s}", .{ Http.Method.POST.asStr(), route });
        try self.routes.put(key, Route{
            .url = route,
            .method = Http.Method.POST,
            .handler = handler,
        });
    }

    /// Registers a PUT route.
    pub fn put(self: *Router, route: []const u8, handler: FnHandler) !void {
        const key = try std.fmt.allocPrint(self.allocator, "{s}-{s}", .{ Http.Method.PUT.asStr(), route });
        try self.routes.put(key, Route{
            .url = route,
            .method = Http.Method.PUT,
            .handler = handler,
        });
    }

    /// Registers a DELETE route.
    pub fn delete(self: *Router, route: []const u8, handler: FnHandler) !void {
        const key = try std.fmt.allocPrint(self.allocator, "{s}-{s}", .{ Http.Method.DELETE.asStr(), route });
        try self.routes.put(key, Route{
            .url = route,
            .method = Http.Method.DELETE,
            .handler = handler,
        });
    }

    /// Registers a PATCH route.
    pub fn patch(self: *Router, route: []const u8, handler: FnHandler) !void {
        const key = try std.fmt.allocPrint(self.allocator, "{s}{s}", .{ Http.Method.PATCH.asStr(), route });
        try self.routes.put(key, Route{
            .url = route,
            .method = Http.Method.PATCH,
            .handler = handler,
        });
    }

    /// Registers an OPTIONS route.
    pub fn options(self: *Router, route: []const u8, handler: FnHandler) !void {
        const key = try std.fmt.allocPrint(self.allocator, "{s}-{s}", .{ Http.Method.OPTIONS.asStr(), route });
        try self.routes.put(key, Route{
            .url = route,
            .method = Http.Method.OPTIONS,
            .handler = handler,
        });
    }

    /// Registers a HEAD route.
    pub fn head(self: *Router, route: []const u8, handler: FnHandler) !void {
        const key = try std.fmt.allocPrint(self.allocator, "{s}-{s}", .{ Http.Method.HEAD.asStr(), route });
        try self.routes.put(key, Route{
            .url = route,
            .method = Http.Method.HEAD,
            .handler = handler,
        });
    }

    /// Looks up a route by method and URL. Returns error.routeNotFound if no route matches.
    pub fn resolveRoute(self: *Router, method: Http.Method, url: []const u8) (RoutesError || std.mem.Allocator.Error)!Route {
        const key = try std.fmt.allocPrint(self.allocator, "{s}-{s}", .{ method.asStr(), url });
        defer self.allocator.free(key);
        const route = self.routes.get(key);
        if (route == null) {
            return RoutesError.routeNotFound;
        }
        return route.?;
    }

    /// Debug: prints all registered routes to stderr.
    pub fn dump(self: *Router) void {
        utils.dump(self.routes);
    }

    /// Frees all route keys and the routes map.
    pub fn deinit(self: *Router) void {
        var it = self.routes.keyIterator();
        while (it.next()) |key_ptr| {
            self.allocator.free(key_ptr.*);
        }
        self.routes.deinit();
    }
};

/// Errors returned by the router (e.g. resolveRoute when no route matches).
pub const RoutesError = error{routeNotFound};
