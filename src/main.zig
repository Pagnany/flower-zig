const rl = @import("raylib");
const std = @import("std");
const ctime = @cImport({
    @cInclude("time.h");
});
const http = @import("http.zig");

const allocator = std.heap.c_allocator;

pub fn main() !void {
    // // Log in to the server
    // var login: http.LoginResponse = undefined;
    // {
    //     var a_username = std.ArrayList(u8).init(allocator);
    //     defer a_username.deinit();
    //     try a_username.appendSlice("pagnany");
    //
    //     var a_password = std.ArrayList(u8).init(allocator);
    //     defer a_password.deinit();
    //     try a_password.appendSlice("test");
    //
    //     login = try http.login_server(allocator, a_username.items, a_password.items);
    // }
    // std.debug.print("Login ID: {s}\n", .{login.id});
    // std.debug.print("Login Token: {s}\n", .{login.token});

    // Raylib init window
    const screenWidth = 1920;
    const screenHeight = 1080;

    rl.initWindow(screenWidth, screenHeight, "Flower");
    defer rl.closeWindow();

    rl.setTargetFPS(60);

    var ballPosition = rl.Vector2.init(-100, -100);

    // Raylib load image and convert to texture
    const image = try rl.loadImage("resources/r.png"); // Loaded in CPU memory (RAM)
    const texture = try rl.loadTextureFromImage(image); // Image converted to texture, GPU memory (VRAM)
    defer rl.unloadTexture(texture);
    // Once image has been converted to texture and uploaded to VRAM,
    // it can be unloaded from RAM
    rl.unloadImage(image);

    // Timestamp
    var timestamp_update = rl.getTime();
    var buffer: [24]u8 = undefined;
    const time_buffer: []u8 = buffer[0..buffer.len];
    get_timestamp(time_buffer);
    var timestamp = try std.mem.Allocator.dupeZ(allocator, u8, time_buffer);

    var prev_loop_time = rl.getTime();

    // Main game loop
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        const loop_time = rl.getTime();
        const delta_time = loop_time - prev_loop_time;
        _ = delta_time;

        // UPDATE
        // Timestamp
        if (timestamp_update + 1 < loop_time) {
            allocator.free(timestamp);
            get_timestamp(time_buffer);
            timestamp = try std.mem.Allocator.dupeZ(allocator, u8, time_buffer);
            timestamp_update = loop_time;
        }
        // Energy saver
        if (rl.isKeyPressed(.p) and rl.getFPS() == 60) {
            rl.setTargetFPS(5);
        } else if (rl.isKeyPressed(.p) and rl.getFPS() == 5) {
            rl.setTargetFPS(60);
        }

        // Ballposition
        ballPosition = rl.getMousePosition();

        // Mouse input
        if (rl.isMouseButtonPressed(.left)) {} else if (rl.isMouseButtonPressed(.middle)) {} else if (rl.isMouseButtonPressed(.right)) {}

        // DRAW
        rl.beginDrawing();
        defer rl.endDrawing();
        rl.clearBackground(rl.Color.black);

        rl.drawTexture(
            texture,
            200,
            200,
            rl.Color.white,
        );
        rl.drawTexture(
            texture,
            screenWidth / 2 - @divFloor(texture.width, 2),
            screenHeight / 2 - @divFloor(texture.height, 2),
            rl.Color.white,
        );
        rl.drawTextureV(texture, ballPosition, rl.Color.white);

        // Timestamp at the top
        rl.drawText(timestamp, 1000, 10, 20, rl.Color.white);
        rl.drawFPS(10, 10);

        prev_loop_time = loop_time;
    }
}

fn get_timestamp(buffer: []u8) void {
    var now: ctime.time_t = undefined;
    _ = ctime.time(&now);
    const timeinfo = ctime.gmtime(&now);

    // clear slice
    @memset(buffer, 0);

    _ = ctime.strftime(buffer.ptr, buffer.len, "%Y.%m.%d %H:%M:%S", timeinfo);
}
