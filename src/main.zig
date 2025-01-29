const rl = @import("raylib");
const std = @import("std");

pub fn main() !void {
    const screenWidth = 1280;
    const screenHeight = 720;

    rl.initWindow(screenWidth, screenHeight, "Flower");
    defer rl.closeWindow();

    rl.setTargetFPS(60);

    var ballPosition = rl.Vector2.init(-100, -100);
    var ballColor = rl.Color.dark_blue;

    const image = try rl.loadImage("resources/r.png"); // Loaded in CPU memory (RAM)
    const texture = try rl.loadTextureFromImage(image); // Image converted to texture, GPU memory (VRAM)
    // Once image has been converted to texture and uploaded to VRAM,
    // it can be unloaded from RAM
    rl.unloadImage(image);

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
        rl.clearBackground(rl.Color.black);

        rl.drawTexture(
            texture,
            0,
            0,
            rl.Color.white,
        );
        rl.drawTexture(
            texture,
            screenWidth / 2 - @divFloor(texture.width, 2),
            screenHeight / 2 - @divFloor(texture.height, 2),
            rl.Color.white,
        );

        rl.drawCircleV(ballPosition, 5, ballColor);
    }
}
