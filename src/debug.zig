const rl = @import("raylib");
const std = @import("std");
const main = @import("main.zig");

/// Debug data for testing
pub fn load_debug_data(flower_stem_nodes: *std.ArrayList(main.FlowerStemNode)) !void {
    try flower_stem_nodes.append(
        main.FlowerStemNode{
            .id = 1,
            .is_root = true,
            .is_leaf = false,
            .pos = null,
            .top_middle = null,
            .bottom_middle = null,
            .texture = null,
            .angle = 0.0,
            .prev_id = 0,
        },
    );
    try flower_stem_nodes.append(
        main.FlowerStemNode{
            .id = 2,
            .is_root = false,
            .is_leaf = false,
            .pos = null,
            .top_middle = null,
            .bottom_middle = null,
            .texture = null,
            .angle = 30.0,
            .prev_id = 1,
        },
    );
    try flower_stem_nodes.append(
        main.FlowerStemNode{
            .id = 3,
            .is_root = false,
            .is_leaf = false,
            .pos = null,
            .top_middle = null,
            .bottom_middle = null,
            .texture = null,
            .angle = -50.0,
            .prev_id = 1,
        },
    );
    try flower_stem_nodes.append(
        main.FlowerStemNode{
            .id = 4,
            .is_root = false,
            .is_leaf = true,
            .pos = null,
            .top_middle = null,
            .bottom_middle = null,
            .texture = null,
            .angle = 10.0,
            .prev_id = 2,
        },
    );
    try flower_stem_nodes.append(
        main.FlowerStemNode{
            .id = 5,
            .is_root = false,
            .is_leaf = true,
            .pos = null,
            .top_middle = null,
            .bottom_middle = null,
            .texture = null,
            .angle = -170.0,
            .prev_id = 3,
        },
    );
    try flower_stem_nodes.append(
        main.FlowerStemNode{
            .id = 6,
            .is_root = false,
            .is_leaf = true,
            .pos = null,
            .top_middle = null,
            .bottom_middle = null,
            .texture = null,
            .angle = 90.0,
            .prev_id = 2,
        },
    );
}
