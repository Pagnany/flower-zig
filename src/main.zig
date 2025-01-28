const rl = @import("raylib");
const std = @import("std");

pub fn main() anyerror!void {
    const screenWidth = 1280;
    const screenHeight = 720;

    rl.initWindow(screenWidth, screenHeight, "Flower");
    defer rl.closeWindow();

    var ballPosition = rl.Vector2.init(-100, -100);
    var ballColor = rl.Color.dark_blue;

    rl.setTargetFPS(60);

    // Main game loop
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        // Update
        ballPosition = rl.getMousePosition();
        ballPosition.x = @as(f32, @floatFromInt(rl.getMouseX()));
        ballPosition.y = @as(f32, @floatFromInt(rl.getMouseY()));

        if (rl.isMouseButtonPressed(.left)) {
            ballColor = rl.Color.maroon;
        } else if (rl.isMouseButtonPressed(.middle)) {
            ballColor = rl.Color.lime;
        } else if (rl.isMouseButtonPressed(.right)) {
            ballColor = rl.Color.dark_blue;
        }

        // Draw
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.ray_white);

        rl.drawCircleV(ballPosition, 40, ballColor);
    }
}
