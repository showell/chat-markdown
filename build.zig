const std = @import("std");

// `zig build test` runs every file's tests.
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // **`chat_markdown`, THE CHAT'S MARKDOWN DIALECT**: `render` and its
    // neighbours (src/markdown.zig). It imports nothing but std, so a host
    // on any target takes it as it is.
    _ = b.addModule("chat_markdown", .{
        .root_source_file = b.path("src/markdown.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Each file is a test root: a file's tests run only when a root reaches it.
    const test_step = b.step("test", "Run every file's tests");
    for ([_][]const u8{
        "src/markdown.zig",
        "src/markdown_fence.zig",
        "src/markdown_inline.zig",
        "src/markdown_links.zig",
        "src/markdown_media.zig",
        "src/markdown_text.zig",
    }) |path| {
        const t = b.addTest(.{ .root_module = b.createModule(.{
            .root_source_file = b.path(path),
            .target = target,
            .optimize = optimize,
        }) });
        test_step.dependOn(&b.addRunArtifact(t).step);
    }
}
