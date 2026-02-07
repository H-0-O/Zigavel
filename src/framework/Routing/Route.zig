const Http = @import("../Http/Request.zig");

pub const Route = struct {
    url: []const u8,
    method: Http.Method,
    handler: *const fn (Http.Request) void,
};

