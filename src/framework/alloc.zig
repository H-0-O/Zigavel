//! Allocator strategy for the framework.
//!
//! - **Process lifetime** (Router, config, container, route keys): use `default_alloc`.
//!   Backed by GeneralPurposeAllocator so long-lived data can be freed in any order.
//!
//! - **Per-request** (parsing, Response, route lookup temp): use a request-scoped arena.
//!   App creates an ArenaAllocator at the start of each request and resets it at the end;
//!   all request-scoped allocations are then freed in one shot (fast, no fragmentation).
//!
//! Applications may use `default_alloc` from the root module for app-wide allocations.

const std = @import("std");

/// Backing allocator for the GPA (uses OS pages; the GPA then pools and reuses).
var gpa_backing: std.heap.GeneralPurposeAllocator(.{}) = undefined;
var gpa_init = false;

/// Process-lifetime allocator. Use for Router, config, container, and any long-lived data.
/// Before initDefaultAllocator() this is page_allocator; after init it is the GPA.
/// For per-request data use a request-scoped arena (see requestArena).
pub var default_alloc: std.mem.Allocator = std.heap.page_allocator;

/// Call once at startup (e.g. in main) to set up the default allocator.
/// After this, default_alloc is the GPA (better for long-lived and repeated allocations).
pub fn initDefaultAllocator() void {
    if (gpa_init) return;
    gpa_backing = std.heap.GeneralPurposeAllocator(.{}){};
    default_alloc = gpa_backing.allocator();
    gpa_init = true;
}

/// Request-scoped arena: use for one HTTP request then reset.
/// Backed by default_alloc. Call reset() at end of request (or let arena go out of scope).
pub fn requestArena() std.heap.ArenaAllocator {
    return std.heap.ArenaAllocator.init(default_alloc);
}

/// Optional: call at process exit to detect leaks (e.g. in tests).
/// Only use after all long-lived objects (Router, App, etc.) have been deinitialized.
pub fn deinitDefaultAllocator() void {
    if (!gpa_init) return;
    _ = gpa_backing.deinit();
    gpa_init = false;
}