const std = @import("std");
const Ctx = @import("ctx/ctx.zig").Ctx;
const Allocator = std.mem.Allocator;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() == .leak) {} ;
    const allocator = gpa.allocator();
    var ctx = try Ctx.init(allocator);
    defer ctx.deinit();
    try ctx.run();
}
