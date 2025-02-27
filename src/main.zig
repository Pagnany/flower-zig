const rl = @import("raylib");
const std = @import("std");
const ctime = @cImport({
    @cInclude("time.h");
});
const http = @import("http.zig");

const PI = 3.14159;

const Flower = struct {
    name: []u8,
    description: []u8,
    price: f32,
    image: []u8,
};

pub fn main() !void {
    const allocator = std.heap.c_allocator;

    // ---- WINDOW SETUP ----
    const screenWidth = 1280;
    const screenHeight = 720;
    // const screenWidth = 1920;
    // const screenHeight = 1080;

    rl.initWindow(screenWidth, screenHeight, "Flower");
    defer rl.closeWindow();

    rl.setTargetFPS(60);
    // ---- END WINDOW SETUP ----

    // ---- TEXTURES ----
    // Watering Can
    const watering_can_img = try rl.loadImage("resources/watering_can_01.png");
    const watering_can_texture = try rl.loadTextureFromImage(watering_can_img);
    defer rl.unloadTexture(watering_can_texture);
    rl.unloadImage(watering_can_img);
    // Flowerpot
    const flowerpot_img = try rl.loadImage("resources/flower_pot_01.png");
    const flowerpot_texture = try rl.loadTextureFromImage(flowerpot_img);
    defer rl.unloadTexture(flowerpot_texture);
    rl.unloadImage(flowerpot_img);
    // Flowerstem
    const flowerstem_img = try rl.loadImage("resources/flower_stem_01.png");
    const flowerstem_texture = try rl.loadTextureFromImage(flowerstem_img);
    defer rl.unloadTexture(flowerstem_texture);
    rl.unloadImage(flowerstem_img);
    // ---- END TEXTURES ----

    // Timestamp
    var timestamp_update = rl.getTime();
    var buffer: [24]u8 = undefined;
    const time_buffer: []u8 = buffer[0..buffer.len];
    get_timestamp(time_buffer);
    var timestamp = try std.mem.Allocator.dupeZ(allocator, u8, time_buffer);
    defer allocator.free(timestamp);

    var prev_loop_time = rl.getTime();

    var mouse_pos = rl.Vector2.init(0, 0);

    const flowerpot_root_pos = rl.Vector2.init((screenWidth / 2 - 50) - 50, screenHeight - 100 - 5);

    // Rotate Test
    var angle: f32 = 0.0;

    // Main game loop
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        const loop_time = rl.getTime();
        const delta_time = loop_time - prev_loop_time;
        _ = delta_time;
        mouse_pos = rl.getMousePosition();

        // ---- UPDATE ----
        // Timestamp
        if (timestamp_update + 1 < loop_time) {
            allocator.free(timestamp);
            get_timestamp(time_buffer);
            timestamp = try std.mem.Allocator.dupeZ(allocator, u8, time_buffer);
            timestamp_update = loop_time;
        }

        // Mouse input
        if (rl.isMouseButtonPressed(.left)) {
            std.debug.print("Mouse left button pressed at x:{d}, y:{d}\n", .{ mouse_pos.x, mouse_pos.y });
        } else if (rl.isMouseButtonPressed(.middle)) {} else if (rl.isMouseButtonPressed(.right)) {}
        // ---- END UPDATE ----

        // --- DRAW ---
        rl.beginDrawing();
        defer rl.endDrawing();
        rl.clearBackground(rl.Color.dark_gray);

        // Overview Menu (Right)
        rl.drawTexture(watering_can_texture, screenWidth - 100, 50, rl.Color.white);
        rl.drawRectangle(screenWidth - 100, 155, 100, 100, rl.Color.red);
        rl.drawRectangle(screenWidth - 100, 260, 100, 100, rl.Color.red);
        rl.drawRectangle(screenWidth - 100, 365, 100, 100, rl.Color.red);

        // Flowerpot
        rl.drawTextureV(flowerpot_texture, flowerpot_root_pos, rl.Color.white);

        // Flowerstem
        rl.drawTextureV(flowerstem_texture, flowerpot_root_pos.add(rl.Vector2.init(0, -100)), rl.Color.white);

        // Rotate Test
        angle += 1.0;
        if (angle >= 360.0) {
            angle = 0.0;
        }
        const new_pos_x: f32 = flowerpot_root_pos.x + 50;
        const new_pos_y: f32 = flowerpot_root_pos.y - 150;
        rl.drawTexturePro(flowerstem_texture, rl.Rectangle.init(0, 0, 100, 100), rl.Rectangle.init(new_pos_x, new_pos_y, 100, 100), rl.Vector2.init(50, 50), angle, rl.Color.white);
        // End Rotate Test

        // Timestamp at the top
        rl.drawText(timestamp, screenWidth - 200, 10, 20, rl.Color.white);
        rl.drawFPS(10, 10);
        // --- END DRAW ---

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

fn create_flowers(alloc: std.mem.Allocator) !std.ArrayList(Flower) {
    var flowers = std.ArrayList(Flower).init(alloc);

    try flowers.append(Flower{ .name = try alloc.dupe(u8, "Rose"), .description = try alloc.dupe(u8, "Red"), .price = 1.0, .image = try alloc.dupe(u8, "resources/r.png") });
    try flowers.append(Flower{ .name = try alloc.dupe(u8, "Tulip"), .description = try alloc.dupe(u8, "Yellow"), .price = 1.5, .image = try alloc.dupe(u8, "resources/t.png") });
    try flowers.append(Flower{ .name = try alloc.dupe(u8, "Sunflower"), .description = try alloc.dupe(u8, "Yellow"), .price = 2.0, .image = try alloc.dupe(u8, "resources/s.png") });

    return flowers;
}

fn destroy_flowers(alloc: std.mem.Allocator, flowers: std.ArrayList(Flower)) void {
    for (flowers.items) |f| {
        alloc.free(f.name);
        alloc.free(f.description);
        alloc.free(f.image);
    }
    flowers.deinit();
}

/// Marks the corners of a square picture rotated inside a rectangle
fn mark_corners(pos: rl.Vector2, angle: i32, pic_lenght: i32) void {
    const pic_lenght_f32: f32 = @as(f32, @floatFromInt(pic_lenght));

    const angle1_f32: f32 = (@as(f32, @floatFromInt(angle)) * PI) / 180.0;
    const length1: f32 = @sin(angle1_f32) * pic_lenght_f32;

    const temp_angle = 180.0 - 90.0 - @as(f32, @floatFromInt(angle));
    const angle2_f32: f32 = (temp_angle * PI) / 180.0;
    const length2: f32 = @sin(angle2_f32) * pic_lenght_f32;

    const top_left = pos.add(rl.Vector2.init(length1, 0));
    rl.drawCircleV(top_left, 5, rl.Color.red);
    const bot_left = pos.add(rl.Vector2.init(0, length2));
    rl.drawCircleV(bot_left, 5, rl.Color.red);
    const top_right = top_left.add(rl.Vector2.init(length2, length1));
    rl.drawCircleV(top_right, 5, rl.Color.red);
    const bot_right = bot_left.add(rl.Vector2.init(length2, length1));
    rl.drawCircleV(bot_right, 5, rl.Color.red);

    const middle_top = top_left.add(top_right).divide(rl.Vector2.init(2, 2));
    rl.drawCircleV(middle_top, 5, rl.Color.red);
    const middle_bot = bot_left.add(bot_right).divide(rl.Vector2.init(2, 2));
    rl.drawCircleV(middle_bot, 5, rl.Color.red);
    const middle_left = top_left.add(bot_left).divide(rl.Vector2.init(2, 2));
    rl.drawCircleV(middle_left, 5, rl.Color.red);
    const middle_right = top_right.add(bot_right).divide(rl.Vector2.init(2, 2));
    rl.drawCircleV(middle_right, 5, rl.Color.red);
}
