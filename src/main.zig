const std = @import("std");
const ziravel = @import("ziravel");
const _router = ziravel.Router;

pub fn main() !void {
    // Prints to stderr, ignoring potential errors.
    const allocator = ziravel.getDefaultAllocator();
    var router = _router.init(allocator);
    try router.get("/hello", handler);
    router.dump();

    var app = ziravel.App.init(router);

    try app.listen("127.0.0.1", 8080);
}

fn handler(request: ziravel.Request) void {
    // _ = request;
    std.debug.print("Hello, world!\n", .{});
    std.debug.print("Request: {s}\n", .{request.url});
    ziravel.Utils.dump(request);
}
