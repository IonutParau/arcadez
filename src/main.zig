const std = @import("std");
const builtin = @import("builtin");
const rl = @cImport({
    @cInclude("raylib.h");
});
const GameState = @import("game.zig");

pub fn main() !void {
    rl.SetTraceLogLevel(rl.LOG_NONE);
    rl.SetConfigFlags(rl.FLAG_WINDOW_RESIZABLE);
    rl.InitWindow(800, 600, "ArcadeZ");

    defer rl.CloseWindow();

    if (builtin.mode != .Debug) {
        rl.SetExitKey(rl.KEY_NULL);
    }

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var state = GameState.init(gpa.allocator());

    while (!rl.WindowShouldClose()) {
        try state.draw();
        const dt = rl.GetFrameTime();
        try state.update(dt);
    }
}
