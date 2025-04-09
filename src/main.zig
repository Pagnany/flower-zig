const rl = @import("raylib");
const std = @import("std");
const ctime = @cImport({
    @cInclude("time.h");
});
const http = @import("http.zig");

const PI = 3.14159265358979323846;
const DEG2RAD = (PI / 180.0);
const RAD2DEG = (180.0 / PI);

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

const UiElement = struct {
    id: u32,
    x: f32,
    y: f32,
    width: f32,
    height: f32,
    texture: ?rl.Texture2D,
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

        // DPI Scaling
        // rl.setConfigFlags(.{
        //     .window_highdpi = true,
        // });

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
        try flower_stem_nodes.append(FlowerStemNode{
            .id = 3,
            .is_root = false,
            .pos = null,
            .top_middle = null,
            .bottom_middle = null,
            .texture = flowerstem_texture,
            .angle = -50.0,
            .prev_id = 1,
        });
        try flower_stem_nodes.append(FlowerStemNode{
            .id = 4,
            .is_root = false,
            .pos = null,
            .top_middle = null,
            .bottom_middle = null,
            .texture = flowerstem_texture,
            .angle = 10.0,
            .prev_id = 2,
        });
        try flower_stem_nodes.append(FlowerStemNode{
            .id = 5,
            .is_root = false,
            .pos = null,
            .top_middle = null,
            .bottom_middle = null,
            .texture = flowerstem_texture,
            .angle = -170.0,
            .prev_id = 3,
        });

        // --- UI ELEMENTS ---
        var ui_elements = std.ArrayList(UiElement).init(allocator);
        defer ui_elements.deinit();
        try ui_elements.append(UiElement{
            .id = 1,
            .x = screenWidth - 100.0,
            .y = 50.0,
            .width = 100.0,
            .height = 100.0,
            .texture = watering_can_texture,
        });
        try ui_elements.append(UiElement{
            .id = 2,
            .x = screenWidth - 100.0,
            .y = 155.0,
            .width = 100.0,
            .height = 100.0,
            .texture = watering_can_texture,
        });

        // Timestamp
        var timestamp_update = rl.getTime();
        var timestamp_buffer: [24]u8 = undefined;
        const time_buffer: []u8 = timestamp_buffer[0..];
        get_timestamp(time_buffer);
        var timestamp = time_buffer[0 .. time_buffer.len - 1 :0];

        var prev_loop_time = rl.getTime();

        var mouse_pos = rl.Vector2.init(0, 0);

        const flowerpot_root_pos = rl.Vector2.init((screenWidth / 2 - 50) - 50, screenHeight - 100 - 5);
        calculate_node_pos(flowerpot_root_pos, flower_stem_nodes);

        // Main game loop
        while (!rl.windowShouldClose()) { // Detect window close button or ESC key
            const loop_time = rl.getTime();
            const delta_time = loop_time - prev_loop_time;
            _ = delta_time;
            mouse_pos = rl.getMousePosition();

            // ---- UPDATE ----
            // Timestamp
            if (timestamp_update + 1 < loop_time) {
                get_timestamp(time_buffer);
                timestamp = time_buffer[0 .. time_buffer.len - 1 :0];
                timestamp_update = loop_time;
            }

            // Mouse input
            if (rl.isMouseButtonPressed(.left)) {
                // std.debug.print(
                //     "Mouse left button pressed at x:{d}, y:{d}\n",
                //     .{ mouse_pos.x, mouse_pos.y },
                // );

                // Check if UI Element is clicked
                for (ui_elements.items) |*ui_element| {
                    if (mouse_pos.x >= ui_element.x and mouse_pos.x <= ui_element.x + ui_element.width and
                        mouse_pos.y >= ui_element.y and mouse_pos.y <= ui_element.y + ui_element.height)
                    {
                        std.debug.print("UI Element {d} clicked!\n", .{ui_element.id});
                    }
                }
            } else if (rl.isMouseButtonPressed(.middle)) {} else if (rl.isMouseButtonPressed(.right)) {}
            // ---- END UPDATE ----

            // --- DRAW ---
            rl.beginDrawing();
            defer rl.endDrawing();
            rl.clearBackground(rl.Color.dark_gray);

            // Flowerstem Connections
            for (flower_stem_nodes.items) |*node| {
                rl.drawCircleV(node.bottom_middle.?, 5, rl.Color.dark_green);
            }

            var stem_select: ?rl.Vector2 = null;
            // Flowerstem
            for (flower_stem_nodes.items) |*node| {
                // Draw Flowerstem
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

                // check for collision mouse with flowerstem
                if (isPointInsideRotatedRect(
                    mouse_pos.x,
                    mouse_pos.y,
                    node.pos.?.x,
                    node.pos.?.y,
                    100.0,
                    100.0,
                    node.angle,
                )) {
                    if (stem_select == null) {
                        stem_select = node.pos;
                    } else {
                        // calculate distances to mouse
                        const dist1 = rl.Vector2.init(
                            stem_select.?.x - mouse_pos.x,
                            stem_select.?.y - mouse_pos.y,
                        ).length();

                        const dist2 = rl.Vector2.init(
                            node.pos.?.x - mouse_pos.x,
                            node.pos.?.y - mouse_pos.y,
                        ).length();

                        if (dist2 < dist1) {
                            stem_select = node.pos;
                        }
                    }
                }
            }

            // Draw Selected Flowerstem
            if (stem_select != null) {
                rl.drawCircleV(stem_select.?, 5, rl.Color.red);
            }

            // Flowerpot
            rl.drawTextureV(
                flowerpot_texture,
                flowerpot_root_pos,
                rl.Color.white,
            );

            // --- UI ---
            for (ui_elements.items) |*ui_element| {
                rl.drawTexturePro(
                    ui_element.texture.?,
                    rl.Rectangle.init(0, 0, 100, 100),
                    rl.Rectangle.init(
                        ui_element.x,
                        ui_element.y,
                        ui_element.width,
                        ui_element.height,
                    ),
                    rl.Vector2.init(0, 0),
                    0.0,
                    rl.Color.white,
                );
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

pub fn write_read_file(alloc: std.mem.Allocator) !void {
    const file_name = "save/save01.json";

    // Create directory if it doesn't exist
    try std.fs.cwd().makePath("save");

    var file = try std.fs.cwd().createFile(file_name, .{});
    defer file.close();

    var json_data = std.ArrayList(u8).init(alloc);
    defer json_data.deinit();
    for (0..20) |_| {
        try json_data.appendSlice("test\n");
    }

    // Zig
    try file.writeAll(json_data.items);

    // Raylib
    // try json_data.append(0);
    // const temp: [:0]u8 = json_data.items[0 .. json_data.items.len - 1 :0];
    // _ = rl.saveFileText(file_name, temp);

    var file_read = try std.fs.cwd().openFile(file_name, .{});
    defer file_read.close();

    // Up to 1GB
    const file_contents = try file_read.readToEndAlloc(alloc, std.math.pow(usize, 1024, 3) * 1);
    defer alloc.free(file_contents);

    std.debug.print("File contents: {s}\n", .{file_contents});
}

fn get_timestamp(buffer: []u8) void {
    var now: ctime.time_t = undefined;
    _ = ctime.time(&now);
    const timeinfo = ctime.gmtime(&now);

    // clear slice
    @memset(buffer, 0);

    _ = ctime.strftime(buffer.ptr, buffer.len, "%Y.%m.%d %H:%M:%S", timeinfo);
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

fn calculate_node_pos(flowerpot_root: rl.Vector2, flower_nodes: std.ArrayList(FlowerStemNode)) void {
    for (flower_nodes.items) |*node| {
        if (node.pos == null) {
            // Distance between bottom middle and root pos
            const temp_vec = rl.Vector2.init(0, 0);
            _, node.bottom_middle = mark_corners_pro(temp_vec, node.angle, 100);
            const bot_mid_vec = temp_vec.subtract(node.bottom_middle.?);
            if (node.is_root) {
                node.pos = flowerpot_root.add(rl.Vector2.init(50, 0)).add(bot_mid_vec);
            } else {
                for (flower_nodes.items) |prev_node| {
                    if (prev_node.id == node.prev_id) {
                        node.pos = prev_node.top_middle.?.add(bot_mid_vec);
                        break;
                    }
                }
            }
            // Put Final Vecs in node
            node.top_middle, node.bottom_middle = mark_corners_pro(node.pos.?, node.angle, 100);
        }
    }
}

fn isPointInsideRotatedRect(
    px: f32,
    py: f32,
    cx: f32,
    cy: f32,
    width: f32,
    height: f32,
    rotation_degrees: f32,
) bool {
    const theta = rotation_degrees * DEG2RAD;

    const cos_theta = @cos(theta);
    const sin_theta = @sin(theta);

    // Translate point to rectangle-local coordinates
    const translated_x = px - cx;
    const translated_y = py - cy;

    // Rotate point by the inverse of the rectangle's rotation
    const rotated_x = translated_x * cos_theta + translated_y * sin_theta;
    const rotated_y = -translated_x * sin_theta + translated_y * cos_theta;

    const half_width = width / 2.0;
    const half_height = height / 2.0;

    return @abs(rotated_x) <= half_width and @abs(rotated_y) <= half_height;
}
