pub const App = @import("framework/Foundation/App.zig").App;
pub const Router = @import("framework/Routing/Router.zig").Router;
pub const Request = @import("framework/Http/Request.zig").Request;
pub const Utils = @import("framework/utils.zig");

pub fn getDefaultAllocator() std.mem.Allocator {
    return @import("framework/alloc.zig").default_alloc;
}

const std = @import("std");
