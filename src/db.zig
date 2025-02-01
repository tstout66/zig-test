const std = @import("std");
const sqlite = @import("sqlite");

const create_table_query =
    \\CREATE TABLE IF NOT EXISTS partitions(id INTEGER PRIMARY KEY, data BLOB);
;

const insert_query =
    \\INSERT INTO partitions(id, data) VALUES(?, ?)
    \\ON CONFLICT(id) DO UPDATE SET data=excluded.data;
;

const query =
    \\SELECT data FROM partitions WHERE id = ?
;

pub var query_stmt: sqlite.DynamicStatement.PrepareError!blk = undefined;
pub var insert_stmt: sqlite.DynamicStatement.PrepareError!blk = undefined;

pub fn init(self: @This()) !self {
    var db = try sqlite.Db.init(.{
        .mode = sqlite.Db.Mode{ .File = "./db/testsqlite.db" },
        .open_flags = .{
            .write = true,
            .create = true,
        },
        .threading_mode = .MultiThread,
    });

    self.query_stmt = try db.prepare(query);
    defer query_stmt.deinit();

    self.insert_stmt = try db.prepare(insert_query);
    defer insert_stmt.deinit();

    try db.exec(create_table_query, .{}, .{});

    return self;
}
