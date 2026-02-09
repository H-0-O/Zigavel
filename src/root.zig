//! Zigavel public API.
//!
//! This module re-exports the framework surface consumed by applications:
//! App, Router, Request, Response, and the default allocator. Use `@import("zigavel")`
//! to access these types and functions.

pub const App = @import("foundation").App;
pub const Router = @import("routing").Router;
pub const Request = @import("http").Request;
pub const Response = @import("http").Response;
pub const Utils = @import("utils");

/// Returns the framework's default allocator (e.g. for creating the Router or allocating in handlers).
pub fn getDefaultAllocator() std.mem.Allocator {
    return @import("alloc").default_alloc;
}

/// Call once at startup (e.g. in main) so the framework uses GeneralPurposeAllocator for process-lifetime data (Router, config).
/// Before this, default_alloc is page_allocator. Request-scoped allocations always use an arena regardless.
pub const initDefaultAllocator = @import("alloc").initDefaultAllocator;

const std = @import("std");
