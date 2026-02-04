const std = @import("std");
const ziravel = @import("ziravel");
const _router = @import("ziravel").Router;
pub fn main() !void {
    // Prints to stderr, ignoring potential errors.
    var router = _router.init();
    try router.get("/hello");

    router.dump();

    var app = ziravel.App.init(router);

    try app.listen("127.0.0.1", 8080);
}
