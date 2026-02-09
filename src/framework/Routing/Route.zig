const HttpRequest = @import("../Http/Request.zig");
const HttpResponse = @import("../Http/Response.zig");

pub const Handler = *const fn (*HttpRequest.Request, *HttpResponse.Response) anyerror!void;

pub const Route = struct {
    url: []const u8,
    method: HttpRequest.Method,
    handler: Handler,
};
