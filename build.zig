const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    const mode = b.standardReleaseOptions();

    // builds the library as a static library
    {
        const lib = b.addStaticLibrary("zest", "src/zest.zig");
        lib.setBuildMode(mode);
        lib.install();
    }

    // builds and runs the tests
    {
        const main_tests = b.addTest("src/zest.zig");
        main_tests.setBuildMode(mode);
        main_tests.use_stage1 = true;
        const test_step = b.step("test", "Run library tests");
        test_step.dependOn(&main_tests.step);
    }

    // examples
    {
        const target = b.standardTargetOptions(.{});
        var opt = b.option([]const u8, "example", "The example to build & run") orelse "scouter";
        const example_file = blk: {
            if (std.mem.eql(u8, opt, "scouter"))
                break :blk "examples/scouter.zig";

            break :blk "examples/scouter.zig";
        };

        // allows for running the example
        var example = b.addExecutable(opt, example_file);
        example.setTarget(target);
        example.addPackage(.{
            .name = "zest",
            .source = .{ .path = "src/zest.zig" },
        });
        example.setBuildMode(mode);
        example.use_stage1 = true;
        example.install();

        const run_example = example.run();
        run_example.step.dependOn(b.getInstallStep());

        const example_step = b.step("example", "Run example");
        example_step.dependOn(&run_example.step);
    }
}
