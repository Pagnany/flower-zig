const std = @import("std");

pub fn learn() void {
    const MyStruct = struct {
        string: []u8,
    };
    const my_string = "Hello, World!";
    var buffer: [200]u8 = undefined;
    const mutableSlice: []u8 = buffer[0..my_string.len];
    std.mem.copyForwards(u8, mutableSlice, my_string);
    mutableSlice[1] = 'x';
    var my_data: MyStruct = undefined;
    my_data.string = mutableSlice;
    std.debug.print("My Data: {s}\n", .{my_data.string});
}
