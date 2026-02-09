# Zigavel

A Laravel-inspired web framework for Zig. Zigavel reproduces Laravel’s design principles, developer experience, and architectural patterns in native Zig—not by copying PHP syntax, but by adopting the same mental models: routing, thin controllers, middleware pipelines, and a service-oriented architecture.

## What Zigavel Is

- **Convention over configuration** — Sensible defaults so you write less boilerplate.
- **Expressive APIs** — Readable, fluent interfaces for routing and HTTP.
- **Laravel-like architecture** — Router → Middleware → Controller → Response; business logic in services, not in routes.
- **Extensible** — Designed for a Service Container, Service Providers, and pluggable subsystems (see [ROADMAP.md](ROADMAP.md)).

## Quick Start

**Requirements:** Zig 0.15.2 or later.

```bash
git clone <repo-url>
cd zigavel
zig build run
```

The default app listens on `127.0.0.1:8080`. Try:

- `GET http://127.0.0.1:8080/hello`
- `GET http://127.0.0.1:8080/hello2`

## Minimal Application

```zig
const std = @import("std");
const zigavel = @import("zigavel");

pub fn main() !void {
    const allocator = zigavel.getDefaultAllocator();
    var router = zigavel.Router.init(allocator);

    try router.get("/hello", helloHandler);
    try router.get("/users", usersHandler);

    var app = zigavel.App.init(router);
    try app.listen("127.0.0.1", 8080);
}

fn helloHandler(request: *zigavel.Request, response: *zigavel.Response) !void {
    _ = request;
    try response.json(.{ .message = "Hello, Zigavel!" });
}

fn usersHandler(request: *zigavel.Request, response: *zigavel.Response) !void {
    _ = request;
    try response.json(.{ .users = &.{} });
}
```

## Project Layout

| Path | Purpose |
|------|--------|
| `src/main.zig` | Application entry point; define routes and start the server here. |
| `src/root.zig` | Public API surface; re-exports `App`, `Router`, `Request`, `Response`, etc. |
| `src/framework/` | Framework core (Foundation, Http, Routing). |
| [ROADMAP.md](ROADMAP.md) | Version goals (v0.1–v0.5) and planned features. |
| [docs/FRAMEWORK.md](docs/FRAMEWORK.md) | Full framework documentation. |

## Build Commands

| Command | Description |
|---------|-------------|
| `zig build` | Build the executable (output in `zig-out/bin/`). |
| `zig build run` | Build and run the app. |
| `zig build test` | Run tests. |

## Philosophy and Conventions

The project follows Laravel-style architecture and naming. For detailed rules and patterns (Service Container, Providers, middleware, controllers, validation, etc.), see:

- **[.cursorrules](.cursorrules)** — Design philosophy and code-style expectations for the codebase.
- **[docs/FRAMEWORK.md](docs/FRAMEWORK.md)** — Framework architecture, modules, and API reference.

## Current Version

Baseline is **v0.0.0**. Planned milestones (routing improvements, path params, middleware, controllers, container, validation) are described in [ROADMAP.md](ROADMAP.md).

## License

See repository for license information.
