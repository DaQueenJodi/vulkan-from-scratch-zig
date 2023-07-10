const std = @import("std");
const c = @import("c");

pub fn vkDie(result: c.VkResult) !void {
    return switch (result) {
        c.VK_SUCCESS => {},
        else => error.OopyDoopsyWeMadeAFuckyWucky,
    };
}

pub fn vkDieExt(result: c.VkResult, validResults: []c.VkResult) !void {
    for (validResults) |res| {
        if (result == res) return;
    }
    return error.OopyDoopsyWeMadeAFuckyWucky;
}
