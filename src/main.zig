const rl = @import("raylib");
const std = @import("std");
const ctime = @cImport({
    @cInclude("time.h");
});

const save = @import("save_data.zig");
const debug = @import("debug.zig");

const PI = 3.14159265358979323846264338327950288419716939937510;
const DEG2RAD = (PI / 180.0);
const RAD2DEG = (180.0 / PI);

pub const FlowerStemNode = struct {
    id: u32,
    is_root: bool,
    is_leaf: bool,
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

const InfoBox = struct {
    is_visible: bool,
    x: i32,
    y: i32,
    width: i32,
    height: i32,
    close_button_size: i32,
    selected_stem: ?*FlowerStemNode,
};

pub fn main() !void {
    // const allocator = std.heap.c_allocator;
    var dba: std.heap.DebugAllocator(.{}) = .init;
    const allocator = dba.allocator();

    {

        // ---- WINDOW SETUP ----
        const screenWidth = 1280;
        const screenHeight = 720;
        // const screenWidth = 1920;
        // const screenHeight = 1080;

        // DPI Scaling
        rl.setConfigFlags(.{
            .window_highdpi = true,
        });

        rl.initWindow(screenWidth, screenHeight, "Flower");
        defer rl.closeWindow();

        rl.setTargetFPS(60);
        // ---- END WINDOW SETUP ----

        // ---- TEXTURES ----
        // Watering Can
        const watering_can_texture = try rl.loadTexture("resources/watering_can_01.png");
        defer rl.unloadTexture(watering_can_texture);
        // Flowerpot
        const flowerpot_texture = try rl.loadTexture("resources/flower_pot_01.png");
        defer rl.unloadTexture(flowerpot_texture);
        // Flowerstem
        const flowerstem_texture = try rl.loadTexture("resources/flower_stem_01.png");
        defer rl.unloadTexture(flowerstem_texture);
        // ---- END TEXTURES ----

        // Flower List
        var flower_stem_nodes = std.ArrayList(FlowerStemNode).init(allocator);
        defer flower_stem_nodes.deinit();

        // ---- SAVE/LOAD DATA ----
        // try debug.load_debug_data(&flower_stem_nodes);
        // try save.create_save_file(allocator, flower_stem_nodes);

        try save.load_save_file(allocator, &flower_stem_nodes);

        // set texture for flowerstem
        for (flower_stem_nodes.items) |*node| {
            node.texture = flowerstem_texture;
        }
        // ---- END SAVE/LOAD DATA ----

        // --- UI ELEMENTS ---
        var ui_elements = std.ArrayList(UiElement).init(allocator);
        defer ui_elements.deinit();
        try ui_elements.append(
            UiElement{
                .id = 1,
                .x = screenWidth - 100.0,
                .y = 50.0,
                .width = 100.0,
                .height = 100.0,
                .texture = watering_can_texture,
            },
        );
        try ui_elements.append(
            UiElement{
                .id = 2,
                .x = screenWidth - 100.0,
                .y = 155.0,
                .width = 100.0,
                .height = 100.0,
                .texture = watering_can_texture,
            },
        );

        // Initialize the info box
        var info_box = InfoBox{
            .is_visible = false,
            .x = 10,
            .y = 30,
            .width = 400,
            .height = 660,
            .close_button_size = 20.0,
            .selected_stem = null,
        };
        // ---- END UI ELEMENTS ----

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
            mouse_pos = rl.getMousePosition().multiply(rl.getWindowScaleDPI());

            // ---- UPDATE ----
            // Timestamp
            if (timestamp_update + 1 < loop_time) {
                get_timestamp(time_buffer);
                timestamp = time_buffer[0 .. time_buffer.len - 1 :0];
                timestamp_update = loop_time;
            }

            // is mouse over flowerstem
            const stem_select = getNearestFlowerStem(mouse_pos, flower_stem_nodes);

            // Mouse input
            if (rl.isMouseButtonPressed(.left)) {
                // std.debug.print("Mouse clicked at: {d} {d}\n", .{ mouse_pos.x, mouse_pos.y });

                for (ui_elements.items) |*ui_element| {
                    if (isPointInsideRect(
                        mouse_pos.x,
                        mouse_pos.y,
                        ui_element.x,
                        ui_element.y,
                        ui_element.width,
                        ui_element.height,
                    )) {
                        std.debug.print("UI Element {d} clicked!\n", .{ui_element.id});
                    }
                }

                // Check if a flower stem is clicked
                if (stem_select) |stem| {
                    info_box.is_visible = true;
                    info_box.selected_stem = stem;
                }

                // Check if close button is clicked
                if (info_box.is_visible and isPointInsideRect(
                    mouse_pos.x,
                    mouse_pos.y,
                    @as(f32, @floatFromInt(info_box.x + info_box.width - info_box.close_button_size)),
                    @as(f32, @floatFromInt(info_box.y)),
                    @as(f32, @floatFromInt(info_box.close_button_size)),
                    @as(f32, @floatFromInt(info_box.close_button_size)),
                )) {
                    info_box.is_visible = false;
                    info_box.selected_stem = null;
                }
            } else if (rl.isMouseButtonPressed(.middle)) {} else if (rl.isMouseButtonPressed(.right)) {}
            // ---- END UPDATE ----

            // --- DRAW ---
            rl.beginDrawing();
            defer rl.endDrawing();
            rl.clearBackground(rl.Color.dark_gray);

            // Flowerstem Connections
            for (flower_stem_nodes.items) |node| {
                rl.drawCircleV(node.bottom_middle.?, 5, rl.Color.dark_green);
            }

            // Flowerstem
            for (flower_stem_nodes.items) |node| {
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
                if (node.is_leaf) {
                    rl.drawCircleV(node.top_middle.?, 5, rl.Color.yellow);
                }
            }

            // Draw Selected Flowerstem
            if (stem_select) |stem| {
                rl.drawCircleV(stem.pos.?, 5, rl.Color.red);
            }

            // Flowerpot
            rl.drawTextureV(
                flowerpot_texture,
                flowerpot_root_pos,
                rl.Color.white,
            );

            // --- UI ---
            for (ui_elements.items) |ui_element| {
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

            // Draw logic for info box
            if (info_box.is_visible) {
                // Draw the info box background
                rl.drawRectangle(
                    info_box.x,
                    info_box.y,
                    info_box.width,
                    info_box.height,
                    rl.Color.light_gray,
                );

                // Draw the close button
                rl.drawRectangle(
                    info_box.x + info_box.width - info_box.close_button_size,
                    info_box.y,
                    info_box.close_button_size,
                    info_box.close_button_size,
                    rl.Color.red,
                );

                rl.drawText(
                    "X",
                    info_box.x + info_box.width - info_box.close_button_size + 5,
                    info_box.y + 5,
                    10,
                    rl.Color.white,
                );

                // Draw placeholder info about the selected stem
                if (info_box.selected_stem) |stem| {
                    rl.drawText(
                        "Flower Stem Info:",
                        info_box.x + 10,
                        info_box.y + 30,
                        20,
                        rl.Color.black,
                    );

                    const id_string = try std.fmt.allocPrintZ(allocator, "ID: {d}", .{stem.id});
                    defer allocator.free(id_string);
                    rl.drawText(
                        id_string,
                        info_box.x + 10,
                        info_box.y + 60,
                        20,
                        rl.Color.black,
                    );

                    const angle_string = try std.fmt.allocPrintZ(allocator, "Angle: {d}", .{stem.angle});
                    defer allocator.free(angle_string);
                    rl.drawText(
                        angle_string,
                        info_box.x + 10,
                        info_box.y + 90,
                        20,
                        rl.Color.black,
                    );

                    const is_leaf_string = try std.fmt.allocPrintZ(allocator, "Leaf: {}", .{stem.is_leaf});
                    defer allocator.free(is_leaf_string);
                    rl.drawText(
                        is_leaf_string,
                        info_box.x + 10,
                        info_box.y + 120,
                        20,
                        rl.Color.black,
                    );
                }
            }

            // Timestamp at the top
            rl.drawText(timestamp, screenWidth - 200, 10, 20, rl.Color.white);
            rl.drawFPS(10, 10);

            // Wayland bug
            // Window is larger than set
            rl.drawRectangle(
                0,
                screenHeight,
                screenWidth,
                50,
                rl.Color.black,
            );
            // --- END DRAW ---

            prev_loop_time = loop_time;
        }
    }

    // Check for leaks
    if (dba.deinit() == .leak) {
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

fn isPointInsideRect(
    px: f32,
    py: f32,
    rx: f32,
    ry: f32,
    width: f32,
    height: f32,
) bool {
    return (px >= rx and px <= rx + width and py >= ry and py <= ry + height);
}

fn isPointInsideRotatedRect(
    px: f32,
    py: f32,
    rx: f32,
    ry: f32,
    width: f32,
    height: f32,
    rotation_degrees: f32,
) bool {
    const theta = rotation_degrees * DEG2RAD;

    const cos_theta = @cos(theta);
    const sin_theta = @sin(theta);

    // Translate point to rectangle-local coordinates
    const translated_x = px - rx;
    const translated_y = py - ry;

    // Rotate point by the inverse of the rectangle's rotation
    const rotated_x = translated_x * cos_theta + translated_y * sin_theta;
    const rotated_y = -translated_x * sin_theta + translated_y * cos_theta;

    const half_width = width / 2.0;
    const half_height = height / 2.0;

    return @abs(rotated_x) <= half_width and @abs(rotated_y) <= half_height;
}

fn getNearestFlowerStem(mouse_pos: rl.Vector2, flower_stem_nodes: std.ArrayList(FlowerStemNode)) ?*FlowerStemNode {
    var nearest_stem: ?*FlowerStemNode = null;

    for (flower_stem_nodes.items) |*node| {
        if (isPointInsideRotatedRect(
            mouse_pos.x,
            mouse_pos.y,
            node.pos.?.x,
            node.pos.?.y,
            100.0,
            100.0,
            node.angle,
        )) {
            if (nearest_stem == null) {
                nearest_stem = node;
            } else {
                // calculate distances to mouse
                const dist1 = rl.Vector2.init(
                    nearest_stem.?.pos.?.x - mouse_pos.x,
                    nearest_stem.?.pos.?.y - mouse_pos.y,
                ).length();

                const dist2 = rl.Vector2.init(
                    node.pos.?.x - mouse_pos.x,
                    node.pos.?.y - mouse_pos.y,
                ).length();

                if (dist2 < dist1) {
                    nearest_stem = node;
                }
            }
        }
    }

    return nearest_stem;
}
