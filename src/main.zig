const rl = @import("raylib");
const std = @import("std");
const ctime = @cImport({
    @cInclude("time.h");
});
const http = @import("http.zig");

const PI = 3.14159265358979323846;
const DEG2RAD = (PI / 180.0);
const RAD2DEG = (180.0 / PI);

const Flower = struct {
    name: []u8,
    description: []u8,
    price: f32,
    image: []u8,
};

const FlowerStemNode = struct {
    id: u32,
    is_root: bool,
    pos: ?rl.Vector2,
    top_middle: ?rl.Vector2,
    bottom_middle: ?rl.Vector2,
    texture: ?rl.Texture2D,
    angle: f32,
    prev_id: u32,
};

pub fn main() !void {
    // const allocator = std.heap.c_allocator;
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    {

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

        // Flower List
        var flower_stem_nodes = std.ArrayList(FlowerStemNode).init(allocator);
        defer flower_stem_nodes.deinit();
        try flower_stem_nodes.append(FlowerStemNode{
            .id = 1,
            .is_root = true,
            .pos = null,
            .top_middle = null,
            .bottom_middle = null,
            .texture = flowerstem_texture,
            .angle = 0.0,
            .prev_id = 0,
        });
        try flower_stem_nodes.append(FlowerStemNode{
            .id = 2,
            .is_root = false,
            .pos = null,
            .top_middle = null,
            .bottom_middle = null,
            .texture = flowerstem_texture,
            .angle = 30.0,
            .prev_id = 1,
        });

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
            rl.drawTextureV(
                flowerpot_texture,
                flowerpot_root_pos,
                rl.Color.white,
            );

            // Flowerstem
            for (flower_stem_nodes.items) |*node| {
                if (node.pos == null) {
                    node.pos = rl.Vector2.init(100, 100);
                    node.top_middle, node.bottom_middle = mark_corners_pro(node.pos.?, node.angle, 100);
                } else {
                    rl.drawTexturePro(
                        node.texture.?,
                        rl.Rectangle.init(0, 0, 100, 100),
                        rl.Rectangle.init(
                            node.pos.?.x,
                            node.pos.?.y,
                            100,
                            100,
                        ),
                        rl.Vector2.init(50, 50),
                        node.angle,
                        rl.Color.white,
                    );
                }
            }

            // Timestamp at the top
            rl.drawText(timestamp, screenWidth - 200, 10, 20, rl.Color.white);
            rl.drawFPS(10, 10);
            // --- END DRAW ---

            prev_loop_time = loop_time;
        }
    }

    // Check for leaks
    if (gpa.deinit() == .leak) {
        std.debug.print("Memory leak detected!\n", .{});
    } else {
        std.debug.print("No memory leaks!\n", .{});
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

    try flowers.append(Flower{
        .name = try alloc.dupe(u8, "Rose"),
        .description = try alloc.dupe(u8, "Red"),
        .price = 1.0,
        .image = try alloc.dupe(u8, "resources/r.png"),
    });
    try flowers.append(Flower{
        .name = try alloc.dupe(u8, "Tulip"),
        .description = try alloc.dupe(u8, "Yellow"),
        .price = 1.5,
        .image = try alloc.dupe(u8, "resources/t.png"),
    });
    try flowers.append(Flower{
        .name = try alloc.dupe(u8, "Sunflower"),
        .description = try alloc.dupe(u8, "Yellow"),
        .price = 2.0,
        .image = try alloc.dupe(u8, "resources/s.png"),
    });

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

fn mark_corners_pro(pos: rl.Vector2, angle: f32, pic_lenght: i32) struct { rl.Vector2, rl.Vector2 } {
    const pic_lenght_f32: f32 = @as(f32, @floatFromInt(pic_lenght));
    const pic_lenght_half_f32: f32 = @as(f32, @floatFromInt(pic_lenght)) / 2.0;

    const sinRotation = @sin(angle * DEG2RAD);
    const cosRotation = @cos(angle * DEG2RAD);
    const x = pos.x;
    const y = pos.y;
    const dx = -pic_lenght_half_f32;
    const dy = -pic_lenght_half_f32;

    const topLeftx = x + dx * cosRotation - dy * sinRotation;
    const topLefty = y + dx * sinRotation + dy * cosRotation;

    const topRightx = x + (dx + pic_lenght_f32) * cosRotation - dy * sinRotation;
    const topRighty = y + (dx + pic_lenght_f32) * sinRotation + dy * cosRotation;

    const bottomLeftx = x + dx * cosRotation - (dy + pic_lenght_f32) * sinRotation;
    const bottomLefty = y + dx * sinRotation + (dy + pic_lenght_f32) * cosRotation;

    const bottomRightx = x + (dx + pic_lenght_f32) * cosRotation - (dy + pic_lenght_f32) * sinRotation;
    const bottomRighty = y + (dx + pic_lenght_f32) * sinRotation + (dy + pic_lenght_f32) * cosRotation;

    const topLeft = rl.Vector2.init(topLeftx, topLefty);
    const topRight = rl.Vector2.init(topRightx, topRighty);
    const bottomLeft = rl.Vector2.init(bottomLeftx, bottomLefty);
    const bottomRight = rl.Vector2.init(bottomRightx, bottomRighty);

    const topMiddle = topLeft.add(topRight.subtract(topLeft).multiply(rl.Vector2.init(0.5, 0.5)));
    const bottomMiddle = bottomLeft.add(bottomRight.subtract(bottomLeft).multiply(rl.Vector2.init(0.5, 0.5)));

    return .{ topMiddle, bottomMiddle };
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
