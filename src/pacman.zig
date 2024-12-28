// WIP: Pacman hard

level: u8, // staying lore accurate
score: u16,
map: [256]Tile,

const GameData = @This();

const std = @import("std");

const GameState = @import("game.zig");

const rl = @cImport({
    @cInclude("raylib.h");
});

pub const Tile = enum {
    Nothing,
    Wall,
    Point,
};

pub const SpriteData = struct {
    ghosts: [4]rl.Texture,
};

pub const GhostKind = enum(u8) {
    /// The red bastard
    Blinky = 0,
    /// The pink bitch
    Pinky = 1,
    /// The blue sucker
    Inky = 2,
    /// Clyde.
    Clyde = 3,
};

fn pacmanMap() [256]Tile {
    var buffer: [256]Tile = undefined;
    for (buffer, 0..) |_, i| {
        buffer[i] = .Wall;
    }
    return buffer;
}

pub fn init() GameData {
    return GameData{
        .level = 0,
        .score = 0,
        .map = pacmanMap(),
    };
}

pub fn draw(state: *const GameState) void {
    _ = state;
}

pub fn update(state: *GameState, dt: f64) !void {
    _ = state;
    _ = dt;
}
