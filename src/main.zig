const std = @import("std");
const sqlite = @import("sqlite");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

    const stdout_writer = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_writer);
    const stdout = bw.writer();

    const stdin_reader = std.io.getStdIn().reader();
    var br = std.io.bufferedReader(stdin_reader);
    const stdin = br.reader();

    try stdout.print("Run `zig build test` to run the tests.\n", .{});
    try bw.flush(); // Don't forget to flush!
    var db = try sqlite.Db.init(.{
        .mode = sqlite.Db.Mode{ .File = "./db/testsqlite.db" },
        .open_flags = .{
            .write = true,
            .create = true,
        },
        .threading_mode = .MultiThread,
    });

    const create_table_query =
        \\CREATE TABLE IF NOT EXISTS partitions(id INTEGER PRIMARY KEY, data BLOB);
    ;

    try db.exec(create_table_query, .{}, .{});

    const query =
        \\SELECT data FROM partitions WHERE id = ?
    ;
    var query_stmt = try db.prepare(query);
    defer query_stmt.deinit();

    const insert_query =
        \\INSERT INTO partitions(id, data) VALUES(?, ?)
        \\ON CONFLICT(id) DO UPDATE SET data=excluded.data;
    ;

    var insert_stmt = try db.prepare(insert_query);
    defer insert_stmt.deinit();

    var msg_buf: [4096]u8 = undefined;
    _ = try stdin.readUntilDelimiterOrEof(&msg_buf, '\n');

    var output_array_list = std.ArrayList(u8).init(allocator);
    defer output_array_list.clearAndFree();

    var data_input_stream = std.io.fixedBufferStream(msg_buf[0..]);

    const row = try query_stmt.oneAlloc(
        []const u8,
        allocator,
        .{},
        .{ .id = 8 },
    );
    if (row) |data| {
        //const data_ptr: [*:0]const u8 = &r.data;
        try stdout.print("data: {s} \n", .{data});
    }

    try std.compress.zlib.compress(data_input_stream.reader(), output_array_list.writer(), .{});

    try insert_stmt.exec(.{}, .{
        .id = 8,
        .data = output_array_list.items,
    });

    try stdout.print("data compressed stream: {s}", .{output_array_list.items});

    try bw.flush(); // Don't forget to flush!

}
