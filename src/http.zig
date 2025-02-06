const std = @import("std");

pub const LoginResponse = struct {
    id: []u8,
    token: []u8,
};

/// Connection to Game Server
/// Get the Player ID and Login Token
pub fn login_server(allocator: std.mem.Allocator, username: []u8, password: []u8) !LoginResponse {

    // Stringifying 'data' into JSON
    const data = .{
        .username = username,
        .password = password,
    };
    var json_string = std.ArrayList(u8).init(allocator);
    defer json_string.deinit();
    try std.json.stringify(data, .{}, json_string.writer());

    // Sending the JSON to the server
    var client = std.http.Client{ .allocator = allocator };
    defer client.deinit();
    var buf: [2048]u8 = undefined;
    const uri = try std.Uri.parse("https://pagnany.de/flower-api.php");
    var request = try client.open(.POST, uri, .{
        .server_header_buffer = &buf,
    });
    defer request.deinit();
    request.transfer_encoding = .chunked;
    try request.send();
    try request.writeAll(json_string.items);
    try request.finish();
    try request.wait();

    // Reading the response
    const body = try request.reader().readAllAlloc(allocator, 256);
    // std.debug.print("{s}\n", .{body});
    const parsed = try std.json.parseFromSlice(LoginResponse, allocator, body, .{});

    return parsed.value;
}
