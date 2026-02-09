//! Zigavel public API.
//!
//! This module re-exports the framework surface consumed by applications:
//! App, Router, Request, Response, and the default allocator. Use `@import("zigavel")`
//! to access these types and functions.

pub const App = @import("framework/Foundation/App.zig").App;
pub const Router = @import("framework/Routing/Router.zig").Router;
pub const Request = @import("framework/Http/Request.zig").Request;
pub const Response = @import("framework/Http/Response.zig").Response;
pub const Utils = @import("framework/utils.zig");

/// Returns the framework's default allocator (e.g. for creating the Router or allocating in handlers).
pub fn getDefaultAllocator() std.mem.Allocator {
    return @import("framework/alloc.zig").default_alloc;
}

/// Call once at startup (e.g. in main) so the framework uses GeneralPurposeAllocator for process-lifetime data (Router, config).
/// Before this, default_alloc is page_allocator. Request-scoped allocations always use an arena regardless.
pub const initDefaultAllocator = @import("framework/alloc.zig").initDefaultAllocator;

const std = @import("std");
