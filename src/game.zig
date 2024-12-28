allocator: Allocator,
random: std.rand.DefaultPrng,
currentMenu: Menu,
details: Details, // extra needed info
width: u32,
height: u32,

const std = @import("std");
const Allocator = std.mem.Allocator;
const rl = @cImport({
    @cInclude("raylib.h");
});

const GameState = @This();

pub const Menu = enum {
    TitleMenu,
    Pong,
    Tetris,
    Pacman,
};

const Pong = @import("pong.zig");
const Tetris = @import("tetris.zig");

pub const Details = union {
    mainMenuAnim: f64,
    pong: Pong,
    tetris: Tetris,
};

pub fn init(allocator: std.mem.Allocator) GameState {
    return GameState{
        .width = @intCast(rl.GetScreenWidth()),
        .height = @intCast(rl.GetScreenHeight()),
        .details = Details{ .mainMenuAnim = 0 },
        .allocator = allocator,
        .random = std.rand.DefaultPrng.init(@bitCast(std.time.timestamp())),
        .currentMenu = .TitleMenu,
    };
}

pub fn draw(self: *const GameState) !void {
    rl.BeginDrawing();
    defer rl.EndDrawing();

    switch (self.currentMenu) {
        .TitleMenu => {
            rl.ClearBackground(rl.BLACK);
        },
        .Pong => {
            try Pong.draw(self);
        },
        .Tetris => {
            try Tetris.draw(self);
        },
        else => {
            std.debug.panic("Bad menu: {}", .{self.currentMenu});
        },
    }
}

pub fn update(self: *GameState, dt: f32) !void {
    self.width = @intCast(rl.GetScreenWidth());
    self.height = @intCast(rl.GetScreenHeight());
    switch (self.currentMenu) {
        .TitleMenu => {
            if (rl.IsKeyDown(rl.KEY_P)) {
                self.currentMenu = .Pong;
                self.details = Details{ .pong = Pong.init(self) };
            }
            if (rl.IsKeyDown(rl.KEY_T)) {
                self.currentMenu = .Tetris;
                self.details = Details{ .tetris = Tetris.init(self) };
            }
        },
        .Pong => {
            try Pong.update(self, dt);
        },
        .Tetris => {
            try Tetris.update(self, dt);
        },
        else => {
            std.debug.panic("Bad menu: {}", .{self.currentMenu});
        },
    }
}
