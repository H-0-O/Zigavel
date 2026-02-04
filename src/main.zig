const std = @import("std");
const ziravel = @import("ziravel");

pub fn main() !void {
    // Prints to stderr, ignoring potential errors.
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});
    var app = ziravel.App.init();

    try app.router.get("/app");

    app.router.dump();

    try app.listen("127.0.0.1", 8080);
}


