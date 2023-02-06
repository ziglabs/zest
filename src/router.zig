const std = @import("std");
const Route = @import("route.zig").Route;

pub const Router = struct {
    routes: []const Route,

    pub fn init(routes: []const Route) Router {
        return Router{ .routes = routes};
    }

    pub fn find(self: Router, path: []const u8) ?Route {
        for (self.routes) |route| {
            if (std.mem.eql(u8, path, route.path)) return route;
        } else return null;
    }
};