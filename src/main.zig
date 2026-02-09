const std = @import("std");
const zigavel = @import("zigavel");
const _router = zigavel.Router;

pub fn main() !void {
    // Prints to stderr, ignoring potential errors.
    const allocator = zigavel.getDefaultAllocator();
    var router = _router.init(allocator);
    try router.get("/hello", handler);
    try router.get("/hello/gijidjf/idfjiodjf", handler2);

    // router.dump();

    var app = zigavel.App.init(router);

    try app.listen("127.0.0.1", 8080);
}

fn handler(request: *zigavel.Request, rs: *zigavel.Response) !void {
    std.debug.print("Hello,sfdsfasdf \n", .{});
    std.debug.print("Request: {s}\n", .{request.url});

    const user = struct { name: []const u8, fml: []const u8 };

    const instance = user{ .name = "Hello", .fml = "MEW MEW" };

    try rs.json(instance);
}

fn handler2(request: *zigavel.Request, rs: *zigavel.Response) !void {
    _ = request;
    _ = rs.statusCode(204);
}
