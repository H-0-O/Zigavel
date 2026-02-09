//! Route definition: URL, HTTP method, and handler. Used by Router for registration and resolution.

const HttpRequest = @import("../Http/Request.zig");
const HttpResponse = @import("../Http/Response.zig");

/// Type of a route handler: receives request and response; may set status, headers, body (e.g. response.json(...)).
pub const Handler = *const fn (*HttpRequest.Request, *HttpResponse.Response) anyerror!void;

/// A single route: path, method, and the function to call when the route matches.
pub const Route = struct {
    url: []const u8,
    method: HttpRequest.Method,
    handler: Handler,
};
