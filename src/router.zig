const std = @import("std");
const Route = @import("route.zig").Route;

pub const Router = struct {
    routes: []const Route,

    pub fn init(comptime routes: []const Route) Router {
        for (routes) |_, i_1| {
            for (routes) |_, i_2| {
                if (i_1 != i_2 and std.mem.eql(u8, routes[i_1].path, routes[i_2].path)) @compileError("duplicate path \"" ++ routes[i_1].path ++ "\" found in routes");
            }
        }

        return Router{ .routes = routes };
    }

    pub fn find(self: Router, path: []const u8) ?Route {
        for (self.routes) |route| {
            if (std.mem.eql(u8, path, route.path)) return route;
        } else return null;
    }
};
