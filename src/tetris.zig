random: std.Random,
upcoming: [PIECES_AHEAD]Tetrimino,
held: ?Tetrimino,
board: [AREA]rl.Color,
level: u16, // if you get to 65536, good luck
linesForLeveling: u8,
score: u32, // if you get 4294967296 you used a bot, fuck you
current: CurrentPiece,
fallingDownTimer: f32,
fellDownTimer: f32,

const WIDTH = 10;
const HEIGHT = 20;
const AREA = WIDTH * HEIGHT;
const PIECES_AHEAD = 3;
const FALLING_INTERVAL = 0.5;

const std = @import("std");
const rl = @cImport({
    @cInclude("raylib.h");
});

const GameState = @import("game.zig");
const TetrisData = @This();

// official name according to https://tetris.fandom.com/wiki/Tetromino so suck it
const Tetrimino = enum {
    I,
    L,
    J,
    O,
    S,
    Z,
    T,
};

const Piece = struct {
    width: u3,
    height: u3,
    data: [6]u1,
    color: rl.Color,
};

const CurrentPiece = struct {
    tet: Tetrimino,
    rot: u2,
    x: u7,
    y: u7,
};

fn getTheOnePiece(tetrimino: Tetrimino, rotation: u2) Piece {
    switch (tetrimino) {
        .I => {
            const color = rl.GetColor(0x348AE0FF);
            if (rotation % 2 == 0) {
                return Piece{
                    .width = 4,
                    .height = 1,
                    .data = [_]u1{
                        1, 1, 1, 1,
                        // junk
                        0, 0,
                    },
                    .color = color,
                };
            }
            return Piece{
                .width = 1,
                .height = 4,
                .data = [_]u1{
                    1,
                    1,
                    1,
                    1,
                    // junk
                    0,
                    0,
                },
                .color = color,
            };
        },
        .O => {
            const color = rl.GetColor(0xF0F05BFF);
            return Piece{
                .width = 2,
                .height = 2,
                .data = [_]u1{
                    1, 1,
                    1, 1,
                    // junk
                    0, 0,
                },
                .color = color,
            };
        },
        .J => {
            const color = rl.GetColor(0x1E3CD4FF);
            return switch (rotation) {
                0 => Piece{
                    .width = 3,
                    .height = 2,
                    .data = [_]u1{
                        1, 1, 1,
                        0, 0, 1,
                    },
                    .color = color,
                },
                1 => Piece{
                    .width = 2,
                    .height = 3,
                    .data = [_]u1{
                        0, 1,
                        0, 1,
                        1, 1,
                    },
                    .color = color,
                },
                2 => Piece{
                    .width = 3,
                    .height = 2,
                    .data = [_]u1{
                        1, 0, 0,
                        1, 1, 1,
                    },
                    .color = color,
                },
                3 => Piece{
                    .width = 2,
                    .height = 3,
                    .data = [_]u1{
                        1, 1,
                        1, 0,
                        1, 0,
                    },
                    .color = color,
                },
            };
        },
        .L => {
            const color = rl.GetColor(0xDE9F33FF);
            return switch (rotation) {
                0 => Piece{
                    .width = 3,
                    .height = 2,
                    .data = [_]u1{
                        1, 1, 1,
                        1, 0, 0,
                    },
                    .color = color,
                },
                1 => Piece{
                    .width = 2,
                    .height = 3,
                    .data = [_]u1{
                        1, 1,
                        0, 1,
                        0, 1,
                    },
                    .color = color,
                },
                2 => Piece{
                    .width = 3,
                    .height = 2,
                    .data = [_]u1{
                        0, 0, 1,
                        1, 1, 1,
                    },
                    .color = color,
                },
                3 => Piece{
                    .width = 2,
                    .height = 3,
                    .data = [_]u1{
                        1, 0,
                        1, 0,
                        1, 1,
                    },
                    .color = color,
                },
            };
        },
        .T => {
            const color = rl.GetColor(0x5B2DCFFF);
            return switch (rotation) {
                0 => Piece{
                    .width = 3,
                    .height = 2,
                    .data = [_]u1{
                        1, 1, 1,
                        0, 1, 0,
                    },
                    .color = color,
                },
                1 => Piece{
                    .width = 2,
                    .height = 3,
                    .data = [_]u1{
                        0, 1,
                        1, 1,
                        0, 1,
                    },
                    .color = color,
                },
                2 => Piece{
                    .width = 3,
                    .height = 2,
                    .data = [_]u1{
                        0, 1, 0,
                        1, 1, 1,
                    },
                    .color = color,
                },
                3 => Piece{
                    .width = 2,
                    .height = 3,
                    .data = [_]u1{
                        1, 0,
                        1, 1,
                        1, 0,
                    },
                    .color = color,
                },
            };
        },
        .S => {
            const color = rl.GetColor(0xE6654EFF);
            const all = [_]Piece{
                Piece{
                    .width = 3,
                    .height = 2,
                    .data = [_]u1{
                        0, 1, 1,
                        1, 1, 0,
                    },
                    .color = color,
                },
                Piece{
                    .width = 2,
                    .height = 3,
                    .data = [_]u1{
                        1, 0,
                        1, 1,
                        0, 1,
                    },
                    .color = color,
                },
            };

            return all[rotation % 2];
        },
        .Z => {
            const color = rl.GetColor(0x2EC742FF);
            const all = [_]Piece{
                Piece{
                    .width = 3,
                    .height = 2,
                    .data = [_]u1{
                        1, 1, 0,
                        0, 1, 1,
                    },
                    .color = color,
                },
                Piece{
                    .width = 2,
                    .height = 3,
                    .data = [_]u1{
                        0, 1,
                        1, 1,
                        1, 0,
                    },
                    .color = color,
                },
            };

            return all[rotation % 2];
        },
    }
}

pub fn init(state: *GameState) TetrisData {
    var upcoming = std.mem.zeroes([PIECES_AHEAD]Tetrimino);
    const rng = state.random.random();
    for (upcoming, 0..) |_, i| {
        upcoming[i] = rng.enumValue(Tetrimino);
    }
    var current = std.mem.zeroes(CurrentPiece);
    current.tet = rng.enumValue(Tetrimino);
    current.rot = 0;
    const data = getTheOnePiece(current.tet, current.rot);
    current.x = @intCast((@as(u32, WIDTH) - data.width) / 2);
    current.y = 0;

    return TetrisData{
        .held = null,
        .random = rng,
        .upcoming = upcoming,
        .level = 0,
        .linesForLeveling = 0,
        .score = 0,
        .board = std.mem.zeroes([AREA]rl.Color),
        .current = current,
        .fallingDownTimer = 0,
        .fellDownTimer = 0,
    };
}

pub fn draw(state: *const GameState) !void {
    rl.ClearBackground(rl.BLACK);

    const m: c_int = @intCast(@min(state.width, state.height));
    const tileSize = @min(@divFloor(m, WIDTH), @divFloor(m, HEIGHT));

    const x = (@as(c_int, @intCast(state.width)) - tileSize * WIDTH) >> 1;

    const bgColors = [2]rl.Color{
        rl.GetColor(0x38393BFF),
        rl.GetColor(0x2C2D2EFF),
    };

    const self = state.details.tetris;

    {
        var i: c_int = 0;
        var j: c_int = 0;

        while (i < WIDTH) : (i += 1) {
            while (j < HEIGHT) : (j += 1) {
                const tile = self.board[@intCast(j * WIDTH + i)];
                if (rl.ColorToInt(tile) == 0) {
                    rl.DrawRectangle(x + (i * tileSize), j * tileSize, tileSize, tileSize, bgColors[@intCast(@rem((@rem(i, 2) + @rem(j, 2)), 2))]);
                } else {
                    rl.DrawRectangle(x + (i * tileSize), j * tileSize, tileSize, tileSize, tile);
                }
            }
            j = 0;
        }
    }

    const score = try std.fmt.allocPrintZ(state.allocator, "Score: {}\nLevel: {}", .{ self.score, self.level });
    defer state.allocator.free(score);

    rl.DrawText(score, 5, 5, 20, rl.WHITE);

    // Draw current
    {
        const data = getTheOnePiece(self.current.tet, self.current.rot);
        var i: c_int = 0;
        while (i < data.width) : (i += 1) {
            var j: c_int = 0;
            while (j < data.height) : (j += 1) {
                if (data.data[@intCast(i + j * data.width)] != 0) {
                    const cx = @as(c_int, @intCast(self.current.x)) + i;
                    const cy = @as(c_int, @intCast(self.current.y)) + j;
                    rl.DrawRectangle(x + cx * tileSize, cy * tileSize, tileSize, tileSize, data.color);
                }
            }
        }
    }

    // Draw held
    if (self.held) |held| {
        const data = getTheOnePiece(held, 0);
        var i: c_int = 0;
        while (i < data.width) : (i += 1) {
            var j: c_int = 0;
            while (j < data.height) : (j += 1) {
                if (data.data[@intCast(i + j * data.width)] != 0) {
                    const cx = i - data.width - 1;
                    const cy = j + 1;
                    rl.DrawRectangle(x + cx * tileSize, cy * tileSize, tileSize, tileSize, data.color);
                }
            }
        }
    }

    {
        var off: c_int = 0;
        for (self.upcoming) |upcoming| {
            const data = getTheOnePiece(upcoming, 0);
            var i: c_int = 0;
            while (i < data.width) : (i += 1) {
                var j: c_int = 0;
                while (j < data.height) : (j += 1) {
                    if (data.data[@intCast(i + j * data.width)] != 0) {
                        const cx = i + WIDTH + 1;
                        const cy = j + off + 1;
                        rl.DrawRectangle(x + cx * tileSize, cy * tileSize, tileSize, tileSize, data.color);
                    }
                }
            }
            off += data.height + 1;
        }
    }
}

pub fn update(state: *GameState, dt: f32) !void {
    var self = &state.details.tetris;

    var mx: isize = 0;
    var my: isize = 0;

    if (rl.IsKeyPressed(rl.KEY_Q)) {
        if (self.held) |held| {
            self.held = self.current.tet;
            self.current = std.mem.zeroes(CurrentPiece);
            self.current.tet = held;
            self.current.rot = 0;
            const data = getTheOnePiece(self.current.tet, self.current.rot);
            self.current.x = @intCast((@as(u32, WIDTH) - data.width) / 2);
            self.current.y = 0;
        } else {
            self.held = self.current.tet;
            self.current = std.mem.zeroes(CurrentPiece);
            self.current.tet = self.upcoming[0];
            self.current.rot = 0;
            const data = getTheOnePiece(self.current.tet, self.current.rot);
            self.current.x = @intCast((@as(u32, WIDTH) - data.width) / 2);
            self.current.y = 0;
            for (self.upcoming, 0..) |_, k| {
                if (k > 0) self.upcoming[k - 1] = self.upcoming[k];
            }
            self.upcoming[PIECES_AHEAD - 1] = self.random.enumValue(Tetrimino);
        }
    }

    if (rl.IsKeyPressed(rl.KEY_A)) {
        mx -= 1;
    } else if (rl.IsKeyPressed(rl.KEY_D)) {
        mx += 1;
    } else {
        // Technically lets the user stall the game indefinitely
        self.fallingDownTimer += dt;
        if (rl.IsKeyDown(rl.KEY_S)) {
            self.fallingDownTimer += 9 * dt;
        }
    }

    if (self.fallingDownTimer > FALLING_INTERVAL) {
        my += 1;
        self.fallingDownTimer -= FALLING_INTERVAL;
    }

    // try rotation
    if (rl.IsKeyPressed(rl.KEY_W)) {
        const newData = getTheOnePiece(self.current.tet, self.current.rot +% 1);
        var valid = true;
        var i: usize = 0;
        collision_check: while (i < newData.width) : (i += 1) {
            var j: usize = 0;
            while (j < newData.height) : (j += 1) {
                const tx = self.current.x + i;
                const ty = self.current.y + j;
                if (newData.data[@intCast(i + j * newData.width)] != 0) {
                    if (rl.ColorToInt(self.board[@intCast(tx + ty * WIDTH)]) != 0) {
                        // cant, collision
                        valid = false;
                        break :collision_check;
                    }
                }
            }
        }
        if (valid) {
            self.current.rot +%= 1;
        }
    }

    // try x movement
    const currentData = getTheOnePiece(self.current.tet, self.current.rot);

    if (mx != 0) {
        var cantMove = false;
        if (mx < 0 and self.current.x == 0) {
            cantMove = true;
        } else if (mx > 0 and self.current.x == @as(usize, WIDTH) - currentData.width) {
            cantMove = true;
        } else {
            var i: usize = 0;
            collision_check: while (i < currentData.width) : (i += 1) {
                var j: usize = 0;
                while (j < currentData.height) : (j += 1) {
                    const tx: isize = @as(isize, @intCast(self.current.x + i)) + mx;
                    const ty: isize = @intCast(self.current.y + j);
                    if (currentData.data[@intCast(i + j * currentData.width)] != 0) {
                        if (rl.ColorToInt(self.board[@intCast(tx + ty * WIDTH)]) != 0) {
                            // cant, collision
                            cantMove = true;
                            break :collision_check;
                        }
                    }
                }
            }
        }

        if (!cantMove) {
            if (mx < 0) {
                self.current.x -= 1;
            } else if (mx > 0) {
                self.current.x += 1;
            }
        }
    }

    var cantFall = false;

    if (my > 0 and self.current.y == (@as(usize, HEIGHT) - currentData.height)) {
        cantFall = true;
    } else if (my > 0) {
        var i: usize = 0;
        collision_check: while (i < currentData.width) : (i += 1) {
            var j: usize = 0;
            while (j < currentData.height) : (j += 1) {
                const tx = self.current.x + i;
                const ty = self.current.y + j + 1;
                if (currentData.data[@intCast(i + j * currentData.width)] != 0) {
                    if (rl.ColorToInt(self.board[tx + ty * WIDTH]) != 0) {
                        // cant, collision
                        cantFall = true;
                        break :collision_check;
                    }
                }
            }
        }
    }

    if (cantFall) {
        var i: usize = 0;
        while (i < currentData.width) : (i += 1) {
            var j: usize = 0;
            while (j < currentData.height) : (j += 1) {
                const tx = self.current.x + i;
                const ty = self.current.y + j;
                if (tx >= WIDTH or ty >= HEIGHT) continue;
                if (currentData.data[@intCast(i + j * currentData.width)] != 0) {
                    self.board[tx + ty * WIDTH] = currentData.color;
                }
            }
        }
        self.current = std.mem.zeroes(CurrentPiece);
        self.current.tet = self.upcoming[0];
        self.current.rot = 0;
        const data = getTheOnePiece(self.current.tet, self.current.rot);
        self.current.x = @intCast((@as(u32, WIDTH) - data.width) / 2);
        self.current.y = 0;
        for (self.upcoming, 0..) |_, k| {
            if (k > 0) self.upcoming[k - 1] = self.upcoming[k];
        }
        self.upcoming[PIECES_AHEAD - 1] = self.random.enumValue(Tetrimino);
    } else {
        self.current.y += @intCast(my);
    }

    // Line clearing
    {
        var linesCleared: usize = 0;
        var i: usize = HEIGHT - 1;
        while (i > 0) : (i -= 1) {
            var lineHasEmpty = false;
            for (0..WIDTH) |x| {
                if (rl.ColorToInt(self.board[x + i * WIDTH]) == 0) {
                    lineHasEmpty = true;
                }
            }
            if (!lineHasEmpty) {
                linesCleared += 1;
                for (0..WIDTH) |x| {
                    self.board[x + i * WIDTH] = std.mem.zeroes(rl.Color);
                }
                if (i > 0) {
                    // we got shit to move
                    var j: usize = i;
                    while (j > 0) : (j -= 1) {
                        for (0..WIDTH) |x| {
                            const k = j - 1;
                            self.board[x + j * WIDTH] = self.board[x + k * WIDTH];
                            self.board[x + k * WIDTH] = std.mem.zeroes(rl.Color);
                        }
                    }
                }
            }
        }

        const pointsFor = [5]usize{ 0, 40, 100, 300, 1200 };
        self.score += @intCast(pointsFor[linesCleared] * (self.level + 1));

        self.linesForLeveling += @intCast(linesCleared);
        while (self.linesForLeveling >= 10) {
            self.linesForLeveling -= 10;
            self.level += 1;
        }
    }
}
