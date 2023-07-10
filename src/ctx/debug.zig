const std = @import("std");
const c = @import("c");
const vkDie = @import("../helper.zig").vkDie;

const HardwareCtx = @import("hardware.zig").HardwareCtx;


fn messageCallback(
    messageSeverity: c.VkDebugUtilsMessageSeverityFlagBitsEXT,
    messageTypes: c.VkDebugUtilsMessageTypeFlagsEXT,
    pCallbackData: [*c]const c.VkDebugUtilsMessengerCallbackDataEXT,
    pUserData: ?*anyopaque
) callconv(.C) c.VkBool32 {
    _ = messageTypes;
    _ = pUserData;
    const blue = "\x1b[34m";
    const yellow = "\x1b[33m";
    const red = "\x1b[31m";
    const color = switch (messageSeverity) {
        c.VK_DEBUG_UTILS_MESSAGE_SEVERITY_INFO_BIT_EXT, c.VK_DEBUG_UTILS_MESSAGE_SEVERITY_VERBOSE_BIT_EXT => blue,
        c.VK_DEBUG_UTILS_MESSAGE_SEVERITY_WARNING_BIT_EXT => yellow,
        c.VK_DEBUG_UTILS_MESSAGE_SEVERITY_ERROR_BIT_EXT => red,
        else => unreachable
    };
    std.debug.print("{s}{s}\x1b[m\n", .{color, pCallbackData.?.*.pMessage});
    return c.VK_FALSE;
}
fn vkDestroyDebugUtilsMessengerEXT(
    instance: c.VkInstance,
    messenger: c.VkDebugUtilsMessengerEXT,
    pAllocator: ?*const c.VkAllocationCallbacks,
) void {
    const func = @as(
        c.PFN_vkDestroyDebugUtilsMessengerEXT,
        @ptrCast(c.vkGetInstanceProcAddr(instance, "vkDestroyDebugUtilsMessengerEXT"))
    );
    if (func) |f| {
       return f(instance, messenger, pAllocator);
    } else {
        @panic("failed to load DestroyDebugUtilsMessenger");
    }
}

fn vkCreateDebugUtilsMessengerEXT(
    instance: c.VkInstance,
    pCreateInfo: ?*const c.VkDebugUtilsMessengerCreateInfoEXT,
    pAllocator: ?*c.VkAllocationCallbacks,
    pMessenger: ?*c.VkDebugUtilsMessengerEXT
) c.VkResult {
    const func = @as(
        c.PFN_vkCreateDebugUtilsMessengerEXT,
        @ptrCast(c.vkGetInstanceProcAddr(instance, "vkCreateDebugUtilsMessengerEXT"))
    );
    if (func) |f| {
        return f(instance, pCreateInfo, pAllocator, pMessenger);
    } else {
        return c.VK_ERROR_EXTENSION_NOT_PRESENT;
    }
}

pub const DebugCtx = struct {
    messenger: c.VkDebugUtilsMessengerEXT,
    const Self = @This();
    pub fn init(hardware: HardwareCtx) !Self {
        const messengerCreateinfo: c.VkDebugUtilsMessengerCreateInfoEXT = .{
            .sType = c.VK_STRUCTURE_TYPE_DEBUG_UTILS_MESSENGER_CREATE_INFO_EXT,
            .pNext = null,
            .flags = 0,
            .messageSeverity = 1,
            .messageType = 1,
            .pfnUserCallback = messageCallback,
            .pUserData = null
        };
        var messenger: c.VkDebugUtilsMessengerEXT = undefined;
        try vkDie(c.vkCreateDebugUtilsMessengerEXT(hardware.instance, &messengerCreateinfo, null, &messenger));
        return .{
            .messenger = messenger
        };
    }
    pub fn deinit(self: *Self, hardware: HardwareCtx) void {
        vkDestroyDebugUtilsMessengerEXT(hardware.instance, self.messenger, null);
    }
};

