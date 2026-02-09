//! Route registration and resolution.
//!
//! Router maps (method, path) to Route. Register routes with get(), post(), etc.;
//! the App calls resolveRoute() to find the handler for each request. Matching is exact (no path params yet).

const std = @import("std");
const utils = @import("utils");
const FnHandler = @import("Route.zig").Handler;
const Route = @import("Route.zig").Route;
const http = @import("http");

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
        const key = try std.fmt.allocPrint(self.allocator, "{s}-{s}", .{ http.Method.GET.asStr(), route });
        try self.routes.put(key, Route{
            .url = route,
            .method = http.Method.GET,
            .handler = handler,
        });
    }

    /// Registers a POST route.
    pub fn post(self: *Router, route: []const u8, handler: FnHandler) !void {
        const key = try std.fmt.allocPrint(self.allocator, "{s}-{s}", .{ http.Method.POST.asStr(), route });
        try self.routes.put(key, Route{
            .url = route,
            .method = http.Method.POST,
            .handler = handler,
        });
    }

    /// Registers a PUT route.
    pub fn put(self: *Router, route: []const u8, handler: FnHandler) !void {
        const key = try std.fmt.allocPrint(self.allocator, "{s}-{s}", .{ http.Method.PUT.asStr(), route });
        try self.routes.put(key, Route{
            .url = route,
            .method = http.Method.PUT,
            .handler = handler,
        });
    }

    /// Registers a DELETE route.
    pub fn delete(self: *Router, route: []const u8, handler: FnHandler) !void {
        const key = try std.fmt.allocPrint(self.allocator, "{s}-{s}", .{ http.Method.DELETE.asStr(), route });
        try self.routes.put(key, Route{
            .url = route,
            .method = http.Method.DELETE,
            .handler = handler,
        });
    }

    /// Registers a PATCH route.
    pub fn patch(self: *Router, route: []const u8, handler: FnHandler) !void {
        const key = try std.fmt.allocPrint(self.allocator, "{s}-{s}", .{ http.Method.PATCH.asStr(), route });
        try self.routes.put(key, Route{
            .url = route,
            .method = http.Method.PATCH,
            .handler = handler,
        });
    }

    /// Registers an OPTIONS route.
    pub fn options(self: *Router, route: []const u8, handler: FnHandler) !void {
        const key = try std.fmt.allocPrint(self.allocator, "{s}-{s}", .{ http.Method.OPTIONS.asStr(), route });
        try self.routes.put(key, Route{
            .url = route,
            .method = http.Method.OPTIONS,
            .handler = handler,
        });
    }

    /// Registers a HEAD route.
    pub fn head(self: *Router, route: []const u8, handler: FnHandler) !void {
        const key = try std.fmt.allocPrint(self.allocator, "{s}-{s}", .{ http.Method.HEAD.asStr(), route });
        try self.routes.put(key, Route{
            .url = route,
            .method = http.Method.HEAD,
            .handler = handler,
        });
    }

    /// Looks up a route by method and URL. Returns error.routeNotFound if no route matches.
    pub fn resolveRoute(self: *Router, method: http.Method, url: []const u8) (RoutesError || std.mem.Allocator.Error)!Route {
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

// --- Tests ---

const testing = std.testing;

fn noopHandler(_: *http.Request, _: *http.Response) !void {}

test "routerii" {
    var router = Router.init(testing.allocator);
    defer router.deinit();
    try testing.expect(router.routes.count() == 0);
}

test "Router get and resolveRoute finds route " {
    var router = Router.init(testing.allocator);
    defer router.deinit();
    try router.get("/hello", noopHandler);
    try router.get("/api/users", noopHandler);

    const r = try router.resolveRoute(http.Method.GET, "/hello");
    try testing.expect(std.mem.eql(u8, r.url, "/hello"));
    try testing.expect(r.method == http.Method.GET);

    const r2 = try router.resolveRoute(http.Method.GET, "/api/users");
    try testing.expect(std.mem.eql(u8, r2.url, "/api/users"));
}

test "Router resolveRoute returns routeNotFound for unknown path" {
    var router = Router.init(testing.allocator);
    defer router.deinit();
    try router.get("/hello", noopHandler);

    const result = router.resolveRoute(http.Method.GET, "/missing");
    try testing.expectError(error.routeNotFound, result);
}

test "Router resolveRoute returns routeNotFound for wrong method" {
    var router = Router.init(testing.allocator);
    defer router.deinit();
    try router.get("/hello", noopHandler);

    const result = router.resolveRoute(http.Method.POST, "/hello");
    try testing.expectError(error.routeNotFound, result);
}

test "Router post put delete patch options head" {
    var router = Router.init(testing.allocator);
    defer router.deinit();
    try router.post("/post", noopHandler);
    try router.put("/put", noopHandler);
    try router.delete("/delete", noopHandler);
    try router.patch("/patch", noopHandler);
    try router.options("/options", noopHandler);
    try router.head("/head", noopHandler);

    try testing.expect((try router.resolveRoute(http.Method.POST, "/post")).url.len > 0);
    try testing.expect((try router.resolveRoute(http.Method.PUT, "/put")).url.len > 0);
    try testing.expect((try router.resolveRoute(http.Method.DELETE, "/delete")).url.len > 0);
    try testing.expect((try router.resolveRoute(http.Method.PATCH, "/patch")).url.len > 0);
    try testing.expect((try router.resolveRoute(http.Method.OPTIONS, "/options")).url.len > 0);
    try testing.expect((try router.resolveRoute(http.Method.HEAD, "/head")).url.len > 0);
}
