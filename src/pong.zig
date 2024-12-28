left_off: f32,
right_off: f32,
ballx: f32,
bally: f32,
ballvx: f32,
ballvy: f32,
leftWins: u16,
rightWins: u16,
leftIsAI: bool,
rightIsAI: bool,
speedupTimer: f32,
lostTimer: f32,
scoreColor: rl.Color,

const PADDLE_WIDTH = 0.02; // 1/20th of width
const PADDLE_HEIGHT = 0.2; // paddle is 1/5th of the screen height
const PADDLE_SPEED: f32 = 1; // 1/10th of min(width, height)
const BALL_SIZE = 0.02; // 1/20th of min(width, height)
const BALL_SPEED: f32 = 0.5; // 1/10th of min(width, height)
const BALL_SPEEDUP: f32 = 1.10;

const std = @import("std");
const rl = @cImport({
    @cInclude("raylib.h");
});

const GameState = @import("game.zig");
const PongData = @This();

pub fn init(state: *GameState) PongData {
    const paddle_height = @as(f32, @floatFromInt(state.height)) * PADDLE_HEIGHT;
    const paddle_center = (@as(f32, @floatFromInt(state.height)) - paddle_height) / 2;
    const m: f32 = @as(f32, @floatFromInt(@min(state.width, state.height)));
    const ball_speed: f32 = m * BALL_SPEED;
    var vx: f32 = if (std.rand.boolean(state.random.random())) 1 else -1;
    var vy: f32 = 0.25;
    const v = vx * vx + vy * vy;
    vx /= v;
    vy /= v;
    return PongData{
        .ballx = @floatFromInt(state.width / 2),
        .bally = @floatFromInt(state.height / 2),
        .ballvx = vx * ball_speed,
        .ballvy = vy * ball_speed,
        .left_off = paddle_center,
        .right_off = paddle_center,
        .leftWins = 0,
        .rightWins = 0,
        .leftIsAI = false,
        .rightIsAI = false,
        .speedupTimer = 0,
        .lostTimer = 0,
        .scoreColor = rl.WHITE,
    };
}

pub fn draw(state: *const GameState) !void {
    const paddle_width = @as(f32, @floatFromInt(state.width)) * PADDLE_WIDTH;
    const paddle_height = @as(f32, @floatFromInt(state.height)) * PADDLE_HEIGHT;
    const ball_size = @as(f32, @floatFromInt(@min(state.width, state.height))) * BALL_SIZE;

    const self = state.details.pong;

    rl.ClearBackground(rl.BLACK);

    rl.DrawRectangle(0, @intFromFloat(self.left_off), @intFromFloat(paddle_width), @intFromFloat(paddle_height), if (self.leftIsAI) rl.GREEN else rl.WHITE);
    rl.DrawRectangle(@intCast(state.width - @as(u32, @intFromFloat(paddle_width))), @intFromFloat(self.right_off), @intFromFloat(paddle_width), @intFromFloat(paddle_height), if (self.rightIsAI) rl.GREEN else rl.WHITE);

    rl.DrawRectangle(@intFromFloat(self.ballx - ball_size), @intFromFloat(self.bally - ball_size), @intFromFloat(ball_size * 2), @intFromFloat(ball_size * 2), self.scoreColor);

    const score = try std.fmt.allocPrintZ(state.allocator, "{} - {}", .{ self.leftWins, self.rightWins });
    defer state.allocator.free(score);

    const scoreSize = 80;

    const scoreW = rl.MeasureText(score, scoreSize);

    rl.DrawText(score, (@as(c_int, @bitCast(state.width)) - scoreW) >> 1, 20, scoreSize, self.scoreColor);
}

fn bot(state: *GameState, self: *PongData, dt: f32, is_right: bool) f32 {
    const m: f32 = @as(f32, @floatFromInt(@min(state.width, state.height)));
    const ball_size: f32 = @as(f32, @floatFromInt(@min(state.width, state.height))) * BALL_SIZE;
    const paddle_width: f32 = @as(f32, @floatFromInt(state.width)) * PADDLE_WIDTH;
    const paddle_height: f32 = @as(f32, @floatFromInt(state.height)) * PADDLE_HEIGHT;
    const paddle_speed: f32 = m * PADDLE_SPEED;
    const width: f32 = @floatFromInt(state.width);
    const height: f32 = @floatFromInt(state.height);
    //if ((self.ballvx > 0) != is_right) return 0; // ball is not going towards us, dont care.
    var ballx: f32 = self.ballx;
    var bally: f32 = self.bally;
    var ballvx: f32 = self.ballvx;
    var ballvy: f32 = self.ballvy;

    while (true) {
        ballx += ballvx * dt;
        bally += ballvy * dt;

        if (bally < ball_size) {
            ballvy = @abs(ballvy);
        }
        if (bally > height - ball_size) {
            ballvy = -@abs(ballvy);
        }

        if (ballx < paddle_width + ball_size) {
            // ball on left, check if hit paddle:
            if (bally > self.left_off - ball_size and bally < self.left_off + paddle_height + ball_size and ballvx < 0) {
                if (!is_right) break; // we dont need to super recursively analyze the ball's movements
                ballvx = @abs(ballvx);
            } else if (ballx < 0) {
                if (is_right) return 0; // we win
                break; // we lost, target found
            }
            if (!is_right) break;
        }

        if (ballx > width - paddle_width - ball_size) {
            // ball on right, check if hit paddle:
            if (bally > self.right_off - ball_size and bally < self.right_off + paddle_height + ball_size and ballvx > 0) {
                if (is_right) break;
                ballvx = -@abs(ballvx);
            } else if (ballx > width - ball_size) {
                if (is_right) break; // we lost, target found
                return 0; // we win
            }
            if (is_right) break;
        }

        // if (is_right) {
        //     if (ballx > width - paddle_width - ball_size) {
        //         break;
        //     }
        // } else {
        //     if (ballx < paddle_width + ball_size) {
        //         break;
        //     }
        // }
    }

    // bally is target

    var centery = if (is_right) self.right_off else self.left_off;
    centery += paddle_height / 2;
    const d = @abs(centery - bally);
    const epsilon: f32 = paddle_speed * 4 * dt;

    if (centery < bally and d >= epsilon) {
        return 1;
    }
    if (centery > bally and d >= epsilon) {
        return -1;
    }

    return 0;
}

pub fn update(state: *GameState, _dt: f32) !void {
    var dt = _dt;
    const self = &state.details.pong;

    if (rl.IsKeyDown(rl.KEY_SPACE)) {
        dt *= 10;
    }
    if (rl.IsKeyDown(rl.KEY_LEFT_SHIFT)) {
        dt /= 10;
    }

    if (rl.IsKeyPressed(rl.KEY_P)) {
        self.* = PongData.init(state);
    }

    if (rl.IsKeyPressed(rl.KEY_ONE)) {
        self.leftIsAI = !self.leftIsAI;
    }
    if (rl.IsKeyPressed(rl.KEY_TWO)) {
        self.rightIsAI = !self.rightIsAI;
    }

    if (self.lostTimer > 0) {
        self.lostTimer += dt;
        if (self.lostTimer > 3) {
            var next = PongData.init(state);
            next.leftWins = self.leftWins;
            next.rightWins = self.rightWins;
            next.leftIsAI = self.leftIsAI;
            next.rightIsAI = self.rightIsAI;
            self.* = next;
            return;
        }
        const colors = [_]rl.Color{
            rl.WHITE,
            rl.RED,
            rl.GREEN,
            rl.BLUE,
            rl.YELLOW,
        };
        const idx: u8 = @intFromFloat(self.lostTimer * 2);
        self.scoreColor = colors[idx % colors.len];
        return;
    }

    const m: f32 = @as(f32, @floatFromInt(@min(state.width, state.height)));
    const paddle_width: f32 = @as(f32, @floatFromInt(state.width)) * PADDLE_WIDTH;
    const paddle_height: f32 = @as(f32, @floatFromInt(state.height)) * PADDLE_HEIGHT;
    const ball_size: f32 = @as(f32, @floatFromInt(@min(state.width, state.height))) * BALL_SIZE;
    const paddle_speed: f32 = m * PADDLE_SPEED;
    const width: f32 = @floatFromInt(state.width);
    const height: f32 = @floatFromInt(state.height);

    self.ballx += self.ballvx * dt;
    self.bally += self.ballvy * dt;

    if (self.bally < ball_size) {
        self.ballvy = @abs(self.ballvy);
    }
    if (self.bally > height - ball_size) {
        self.ballvy = -@abs(self.ballvy);
    }

    if (self.leftIsAI) {
        self.left_off += bot(state, self, dt, false) * paddle_speed * dt;
    } else {
        if (rl.IsKeyDown(rl.KEY_W)) {
            self.left_off -= paddle_speed * dt;
        }
        if (rl.IsKeyDown(rl.KEY_S)) {
            self.left_off += paddle_speed * dt;
        }
    }

    if (self.left_off < 0) {
        self.left_off = 0;
    }
    if (self.left_off > height - paddle_height) {
        self.left_off = height - paddle_height;
    }

    if (self.rightIsAI) {
        self.right_off += bot(state, self, dt, true) * paddle_speed * dt;
    } else {
        if (rl.IsKeyDown(rl.KEY_UP)) {
            self.right_off -= paddle_speed * dt;
        }
        if (rl.IsKeyDown(rl.KEY_DOWN)) {
            self.right_off += paddle_speed * dt;
        }
    }

    if (self.right_off < 0) {
        self.right_off = 0;
    }
    if (self.right_off > height - paddle_height) {
        self.right_off = height - paddle_height;
    }

    if (self.ballx < paddle_width + ball_size) {
        // ball on left, check if hit paddle:
        if (self.bally > self.left_off - ball_size and self.bally < self.left_off + paddle_height + ball_size and self.ballvx < 0) {
            self.ballvx = @abs(self.ballvx);
        } else if (self.ballx < 0) {
            self.lostTimer = dt;
            self.rightWins += 1;
        }
    }

    if (self.ballx > width - paddle_width - ball_size) {
        // ball on left, check if hit paddle:
        if (self.bally > self.right_off - ball_size and self.bally < self.right_off + paddle_height + ball_size and self.ballvx > 0) {
            self.ballvx = -@abs(self.ballvx);
        } else if (self.ballx > width - ball_size) {
            self.lostTimer = dt;
            self.leftWins += 1;
        }
    }

    self.speedupTimer += dt;
    const interval = 10;
    while (self.speedupTimer > interval) {
        self.speedupTimer -= interval;
        self.ballvx *= BALL_SPEEDUP;
        self.ballvy *= BALL_SPEEDUP;
    }
}
