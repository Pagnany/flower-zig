const rl = @import("raylib");
const std = @import("std");
const ctime = @cImport({
    @cInclude("time.h");
});
const http = @import("http.zig");
const learn = @import("learn_zig.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    // learn.learn();

    // Log in to the server
    var login: http.LoginResponse = undefined;
    {
        var a_username = std.ArrayList(u8).init(allocator);
        defer a_username.deinit();
        try a_username.appendSlice("pagnany");

        var a_password = std.ArrayList(u8).init(allocator);
        defer a_password.deinit();
        try a_password.appendSlice("test");

        login = try http.http_test(allocator, a_username.items, a_password.items);
    }
    std.debug.print("Login ID: {s}\n", .{login.id});
    std.debug.print("Login Token: {s}\n", .{login.token});

    const screenWidth = 1280;
    const screenHeight = 720;

    rl.initWindow(screenWidth, screenHeight, "Flower");
    defer rl.closeWindow();

    rl.setTargetFPS(60);

    var ballPosition = rl.Vector2.init(-100, -100);

    // Time
    var now: ctime.time_t = undefined;
    _ = ctime.time(&now);
    const timeinfo = ctime.gmtime(&now);
    const hour = timeinfo.*.tm_hour;
    std.debug.print("Hour: {}\n", .{hour});

    // Full Timestamp
    const s = ctime.asctime(timeinfo);

    const image = try rl.loadImage("resources/r.png"); // Loaded in CPU memory (RAM)
    const texture = try rl.loadTextureFromImage(image); // Image converted to texture, GPU memory (VRAM)
    // Once image has been converted to texture and uploaded to VRAM,
    // it can be unloaded from RAM
    rl.unloadImage(image);

    // Main game loop
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        // Update
        ballPosition = rl.getMousePosition();

        if (rl.isMouseButtonPressed(.left)) {} else if (rl.isMouseButtonPressed(.middle)) {} else if (rl.isMouseButtonPressed(.right)) {}

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

        rl.drawText(s, 1000, 10, 20, rl.Color.white);
    }
}
