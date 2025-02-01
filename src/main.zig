const std = @import("std");
const sqlite = @import("sqlite");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

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

    try db.exec("CREATE TABLE IF NOT EXISTS partitions(id INTEGER PRIMARY KEY, data BLOB);", .{}, .{});

    const query =
        \\SELECT data FROM partitions WHERE id = ?
    ;
    var query_stmt = try db.prepare(query);
    defer query_stmt.deinit();

    const insert_query =
        \\INSERT INTO partitions(id, data) VALUES(?, ?)
    ;

    var insert_stmt = try db.prepare(insert_query);
    defer insert_stmt.deinit();

    const some_data =
        \\"{foo:\"bar\",test:\"json\",madeup:\"data\",test:\"json\",madeup:\"data\",test:\"json\",madeup:\"data\",test:\"json\",madeup:\"data\",test:\"json\",madeup:\"data\"
        \\,test:\"json\",madeup:\"data2\",test:\"json3\",madeup:\"data3\",test:\"json\",madeup:\"dataa\",test:\"jsonv\",madeup:\"datawe\",test:\"json\",madeup:\"data\",test:\"json\",madeup:\"data\"
        \\,test:\"json\",madeup:\"data3\",test:\"json5\",madeup:\"data4\",test:\"json\",madeup:\"datas\",test:\"jsona\",madeup:\"dataw\",test:\"json\",madeup:\"data\"
        \\,test:\"json\",madeup:\"data4\",test:\"json6\",madeup:\"data5\",test:\"json\",madeup:\"datad\",test:\"jsons\",madeup:\"datar\",test:\"json\",madeup:\"data\"
        \\,test:\"json\",madeup:\"data5\",test:\"json7\",madeup:\"data6\",test:\"json\",madeup:\"dataf\",test:\"jsond\",madeup:\"datae\"
        \\,test:\"json\",madeup:\"data6\",test:\"json8\",madeup:\"data7\",test:\"json\",madeup:\"datag\",test:\"jsond\",madeup:\"dataw\"}"
    ;

    var output_array_list = std.ArrayList(u8).init(allocator);
    defer output_array_list.clearAndFree();

    var data_input_stream = std.io.fixedBufferStream(some_data[0..]);

    //try output_array_list.writer().writeAll(data_input_stream.buffer);

    try std.compress.zlib.compress(data_input_stream.reader(), output_array_list.writer(), .{});

    try insert_stmt.exec(
        .{}, 
        .{ 
            .id = 7, 
            .data = output_array_list.items 
        }
    );
    
    try stdout.print("data compressed stream: {s}", .{output_array_list.items});

    try bw.flush(); // Don't forget to flush!

}
