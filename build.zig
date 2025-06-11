const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Main executable module
    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Main executable
    const exe = b.addExecutable(.{
        .name = "seqtkz",
        .root_module = exe_mod,
    });

    exe.addIncludePath(b.path("include"));
    exe.linkLibC();
    exe.linkSystemLibrary("z");

    b.installArtifact(exe);

    // Run command
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // Unit tests for main executable
    const exe_unit_tests = b.addTest(.{
        .root_module = exe_mod,
    });

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    // Test harness for comparing with seqtk
    const test_harness = b.addTest(.{
        .root_source_file = b.path("src/test_harness.zig"),
        .target = target,
        .optimize = optimize,
    });

    test_harness.addIncludePath(b.path("include"));
    test_harness.linkLibC();
    test_harness.linkSystemLibrary("z");

    const run_test_harness = b.addRunArtifact(test_harness);

    // Check if seqtk is available
    const check_seqtk = b.addSystemCommand(&.{ "which", "seqtk" });
    run_test_harness.step.dependOn(&check_seqtk.step);

    // Standard test step
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);

    // Comparison test step
    const compare_step = b.step("test-compare", "Run comparison tests against seqtk");
    compare_step.dependOn(&run_test_harness.step);

    // Benchmark step
    const bench_harness = b.addTest(.{
        .root_source_file = b.path("src/test_harness.zig"),
        .target = target,
        .optimize = .ReleaseFast, // Use release mode for benchmarks
    });

    bench_harness.addIncludePath(b.path("include"));
    bench_harness.linkLibC();
    bench_harness.linkSystemLibrary("z");

    const run_bench = b.addRunArtifact(bench_harness);
    //run_bench.setFilter("benchmark"); // Only run benchmark tests

    const bench_step = b.step("bench", "Run benchmarks comparing with seqtk");
    bench_step.dependOn(&run_bench.step);

    // All tests (unit + comparison)
    const test_all_step = b.step("test-all", "Run all tests");
    test_all_step.dependOn(&run_exe_unit_tests.step);
    test_all_step.dependOn(&run_test_harness.step);
}
