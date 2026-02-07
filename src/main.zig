const std = @import("std");
const zigavel = @import("zigavel");
const _router = zigavel.Router;

pub fn main() !void {
    // Prints to stderr, ignoring potential errors.
    const allocator = zigavel.getDefaultAllocator();
    var router = _router.init(allocator);
    try router.get("/hello", handler);
    router.dump();

    var app = zigavel.App.init(router);

    try app.listen("127.0.0.1", 8080);
}

fn handler(request: zigavel.Request) void {
    // _ = request;
    std.debug.print("Hello, world!\n", .{});
    std.debug.print("Request: {s}\n", .{request.url});
    zigavel.Utils.dump(request);
}
