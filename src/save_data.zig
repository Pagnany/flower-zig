const rl = @import("raylib");
const std = @import("std");
const main = @import("main.zig");

/// Create a save file with the flower stem nodes
/// texture is not saved
pub fn create_save_file(
    allocator: std.mem.Allocator,
    flower_stem_nodes_org: std.ArrayList(main.FlowerStemNode),
) !void {
    const file_name = "save/save01.json";

    // Create a copy because we need to remove the texture
    const flower_stem_nodes = try flower_stem_nodes_org.clone();

    // Don't save texture
    defer flower_stem_nodes.deinit();
    for (flower_stem_nodes.items) |*node| {
        node.texture = null;
    }

    var json_string = std.ArrayList(u8).init(allocator);
    defer json_string.deinit();
    try std.json.stringify(flower_stem_nodes.items, .{}, json_string.writer());

    // Create Dir and File
    try std.fs.cwd().makePath("save");
    var file = try std.fs.cwd().createFile(file_name, .{});
    defer file.close();

    // Write to File
    try file.writeAll(json_string.items);
}

pub fn load_save_file(
    allocator: std.mem.Allocator,
    flower_stem_nodes: *std.ArrayList(main.FlowerStemNode),
) !void {
    const file_name = "save/save01.json";

    // Read from File
    var file_read = try std.fs.cwd().openFile(file_name, .{});
    defer file_read.close();

    // Max 1GB
    const file_contents = try file_read.readToEndAlloc(allocator, std.math.pow(usize, 1024, 3) * 1);

    // Parse Object from Json String
    const parsed = try std.json.parseFromSlice([]main.FlowerStemNode, allocator, file_contents, .{});
    allocator.free(file_contents);

    // Convert to ArrayList
    flower_stem_nodes.clearAndFree();
    try flower_stem_nodes.appendSlice(parsed.value);
    parsed.deinit();
}
