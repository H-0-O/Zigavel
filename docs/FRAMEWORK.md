# Zigavel Framework Documentation

This document describes the Zigavel framework architecture, modules, and public API. Zigavel is built in the spirit of Laravel: convention over configuration, thin controllers, and a clear request lifecycle.

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Request Lifecycle](#request-lifecycle)
3. [Module Structure](#module-structure)
4. [Public API Reference](#public-api-reference)
5. [Conventions and Patterns](#conventions-and-patterns)
6. [Planned Evolution](#planned-evolution)

---

## Architecture Overview

Zigavel is organized around these layers:

| Layer | Responsibility |
|-------|----------------|
| **Foundation** | Application bootstrap, server binding, request capture. |
| **Routing** | Route registration and resolution; mapping HTTP method + path to handlers. |
| **Http** | Request parsing and Response building (status, headers, body, JSON). |

The flow is: **Server → App → Router → Handler(Request, Response)**. Business logic belongs in handlers (or future controllers/services), not in route definitions.

### High-Level Flow

```
Client request
    → Server accepts connection
    → App.capture(stream)
    → Request.parse(stream)
    → Router.resolveRoute(method, url)
    → Route.handler(request, response)
    → Response serialized to HTTP and written to stream
```

---

## Request Lifecycle

1. **Accept** — `Server` listens on host/port and accepts TCP connections.
2. **Capture** — For each connection, `App.capture` is invoked with the stream.
3. **Parse** — The raw stream is parsed into a `Request` (method, URL, headers). Body parsing is not yet implemented.
4. **Resolve** — The router looks up a route by `METHOD-PATH`. If none is found, the app returns **404 Route Not Found** (or 500 on resolver errors).
5. **Dispatch** — The matched route’s handler is called with `(request, response)`.
6. **Respond** — The handler may set status, headers, and body (e.g. `response.json(...)`). The app then serializes the `Response` to an HTTP string and writes it to the stream.
7. **Cleanup** — Request and response are deinitialized; the connection is closed.

Errors in the handler currently result in a 500 response; unhandled resolver errors are also mapped to 500.

---

## Module Structure

```
src/
├── main.zig              # Application entry; routes + app.listen()
├── root.zig              # Public API: re-exports App, Router, Request, Response, getDefaultAllocator
└── framework/
    ├── alloc.zig         # default_alloc (page_allocator)
    ├── utils.zig         # Re-exports utils (e.g. dump)
    ├── Foundation/
    │   ├── App.zig       # App init, listen, capture
    │   └── Server.zig    # Server init, listen (TCP)
    ├── Http/
    │   ├── Request.zig   # Method, Request, parse, ParseErrors
    │   └── Response.zig  # Response init, statusCode, setBody, json, toHttpString
    └── Routing/
        ├── Route.zig     # Handler type, Route struct
        └── Router.zig    # Router init, get/post/put/delete/patch/options/head, resolveRoute, dump, deinit
```

- **Consumers** of the framework use `@import("zigavel")` and only touch the API exposed in `root.zig`.
- **Internal** modules live under `framework/` and are composed by `App`, `Router`, and `root.zig`.

---

## Public API Reference

### Application and Server

**`zigavel.App`**

| Method | Signature | Description |
|--------|-----------|-------------|
| `init` | `init(router: Router) App` | Creates an app that uses the given router. |
| `listen` | `listen(self: *App, host: []const u8, port: u16) !void` | Binds the server to host/port and starts the request loop. Blocks. |

**`zigavel.getDefaultAllocator()`**  
Returns the default allocator used by the framework (currently `std.heap.page_allocator`). Use it when creating the `Router` and when allocating in handlers if you want to match framework behavior.

---

### Router

**`zigavel.Router`**

| Method | Signature | Description |
|--------|-----------|-------------|
| `init` | `init(allocator: std.mem.Allocator) Router` | Initializes the router with an allocator (e.g. from `getDefaultAllocator()`). |
| `get` | `get(self: *Router, path: []const u8, handler: Handler) !void` | Registers a GET route. |
| `post` | `post(self: *Router, path: []const u8, handler: Handler) !void` | Registers a POST route. |
| `put` | `put(...)` | Registers a PUT route. |
| `delete` | `delete(...)` | Registers a DELETE route. |
| `patch` | `patch(...)` | Registers a PATCH route. |
| `options` | `options(...)` | Registers an OPTIONS route. |
| `head` | `head(...)` | Registers a HEAD route. |
| `resolveRoute` | `resolveRoute(self: *Router, method: Http.Method, url: []const u8) !Route` | Resolves a route by method and URL. Returns `error.routeNotFound` if no match. |
| `dump` | `dump(self: *Router) void` | Debug: prints registered routes. |
| `deinit` | `deinit(self: *Router) void` | Frees router-owned memory. |

**Route matching:** Exact match on `METHOD-PATH` only. Path parameters (e.g. `/users/:id`) are planned for a later version.

**`zigavel.Router.RoutesError`**  
Error set for routing: `routeNotFound`.

---

### Request

**`zigavel.Request`**

| Field | Type | Description |
|-------|------|-------------|
| `method` | `Http.Method` | GET, POST, PUT, DELETE, PATCH, OPTIONS, HEAD. |
| `url` | `[]const u8` | Request path (as in the request line). |
| `headers` | `std.StringHashMap([]const u8)` | Parsed headers. |
| `body` | `?[]const u8` | Request body; currently always `null`. |
| `allocator` | `std.mem.Allocator` | Allocator used for this request. |

**Static / free function**

| Function | Signature | Description |
|----------|-----------|-------------|
| `parse` | `Request.parse(allocator, stream: *std.net.Stream) ParseErrors!Request` | Parses the stream into a `Request`. Caller must call `request.deinit()`. |

**`Request.deinit(self: *Request) void`**  
Frees request-owned memory (e.g. headers).

**`Request.ParseErrors`**  
`BufferOverflow`, `InvalidRequestLine`, `InvalidMethod`, plus stream/allocator errors.

---

### Response

**`zigavel.Response`**

| Method | Signature | Description |
|--------|-----------|-------------|
| `init` | `init(allocator: std.mem.Allocator) Response` | Creates a 200 OK response with empty body. |
| `statusCode` | `statusCode(self: *Response, code: u16) *Response` | Sets status code and default status text. Fluent. |
| `status` | `status(self: *Response, code: u16, text: []const u8) *Response` | Sets status code and custom text. Fluent. |
| `header` | `header(self: *Response, name: []const u8, value: []const u8) !*Response` | Adds a response header. Fluent. |
| `setBody` | `setBody(self: *Response, content: []const u8) *Response` | Sets body (no ownership transfer). Fluent. |
| `json` | `json(self: *Response, data: anytype) !void` | Serializes `data` to JSON, sets body and `Content-Type: application/json`. Response owns the allocated body. |
| `jsonUnmanaged` | `jsonUnmanaged(self: *Response, json_body: []const u8) !void` | Sets body to pre-serialized JSON and Content-Type. Caller keeps ownership of `json_body`. |
| `toHttpString` | `toHttpString(self: *const Response, allocator: std.mem.Allocator) ![]const u8` | Builds the full HTTP response string. Caller must free the returned slice. |
| `deinit` | `deinit(self: *Response) void` | Frees response-owned memory (e.g. JSON body, headers). |

If the body is set and no `Content-Length` header is present, `toHttpString` adds it automatically.

---

### Route Handler

**`zigavel.Route.Handler`** (conceptually; the type is re-exported via Router/Route)

```zig
*const fn (*Request, *Response) anyerror!void
```

Handlers receive the parsed request and the response builder. They may read `request.method`, `request.url`, `request.headers`, and set status, headers, and body (including `response.json(...)`). The framework writes the response after the handler returns.

---

## Conventions and Patterns

### Allocator Usage

- The **Router** is created with an allocator (e.g. `getDefaultAllocator()`) and uses it for route keys and internal data structures.
- **Request** and **Response** are created by the framework with the same default allocator in `App.capture`. Handlers receive them and must not replace their allocators.
- Handlers that allocate (e.g. for JSON or temporary data) should use `request.allocator` or `response.allocator` so lifecycle stays consistent.

### Routing

- **Do not** put business logic in route registration. Register routes in `main` (or a dedicated routes module) and delegate to handler functions (or future controllers).
- Keep handlers **thin**: parse input, call a service or action, then set response. Heavy logic belongs in separate modules (future services/actions).

### Response Building

- Prefer **fluent** calls: `response.statusCode(201).header("X-Custom", "value").json(payload)`.
- For JSON APIs, use `response.json(data)`; the framework sets Content-Type and owns the serialized body.
- Call `response.deinit()` only if you created the Response yourself; in the normal request path, `App.capture` creates and deinits it.

### Error Handling

- Handlers may return an error; the app currently turns that into **500 Internal Server Error**.
- Route-not-found is handled before the handler (404). Other resolver errors result in 500.
- Future versions will centralize error handling and support validation (e.g. 422) and proper 405 Method Not Allowed.

---

## Planned Evolution

The framework is at a **v0.0.0** baseline. Planned work is documented in [ROADMAP.md](../ROADMAP.md). Summary:

| Version | Focus |
|---------|--------|
| **v0.1** | 404/405 behavior, query string on Request, README/version. |
| **v0.2** | Path parameters (e.g. `/users/:id`), params on Request. |
| **v0.3** | Middleware pipeline, Controller abstraction. |
| **v0.4** | Service Container, Service Providers, Config. |
| **v0.5** | Validation, request lifecycle docs, JSON body parsing, centralized errors. |

Future docs will extend this document with:

- Middleware registration and order
- Controller dispatch and dependency injection
- Container bindings and resolution
- Validation rules and 422 responses
- Config and environment loading

For design philosophy and code-style rules (Laravel-like architecture, naming, what to avoid), see the project root [.cursorrules](../.cursorrules).
