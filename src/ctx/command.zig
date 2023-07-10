const std = @import("std");
const c = @import("c");
const HardwareCtx = @import("ctx.zig").HardwareCtx;
const vkDie = @import("../helper.zig").vkDie;

fn createSemaphore(hardware: HardwareCtx) !c.VkSemaphore {
    const typeCreateInfo: c.VkSemaphoreTypeCreateInfo = .{
        .sType = c.VK_STRUCTURE_TYPE_SEMAPHORE_TYPE_CREATE_INFO,
        .pNext = null,
        .semaphoreType = c.VK_SEMAPHORE_TYPE_BINARY,
        .initialValue = 0
    };
    const createInfo: c.VkSemaphoreCreateInfo = .{
        .sType = c.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO,
        .pNext = &typeCreateInfo,
        .flags = 0
    };
    var semaphore: c.VkSemaphore = undefined;
    try vkDie(c.vkCreateSemaphore(hardware.device, &createInfo, null, &semaphore));
    return semaphore;
}

pub const CommandCtx = struct {
    pool: c.VkCommandPool,
    buffer: c.VkCommandBuffer,
    acquireImageSemaphore: c.VkSemaphore,
    const Self = @This();
    pub fn init(hardware: HardwareCtx) !Self {

        const poolCreateInfo: c.VkCommandPoolCreateInfo = .{
            .sType = c.VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO,
            .pNext = null,
            .flags = c.VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT,
            .queueFamilyIndex = hardware.queueFamilies.graphics.?
        };


        var pool: c.VkCommandPool = undefined;
        try vkDie(c.vkCreateCommandPool(hardware.device, &poolCreateInfo, null, &pool));

        const allocateInfo: c.VkCommandBufferAllocateInfo = .{
            .sType = c.VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO,
            .pNext = null,
            .commandPool = pool,
            .level = c.VK_COMMAND_BUFFER_LEVEL_PRIMARY,
            .commandBufferCount = 1
        };

        var buffer: c.VkCommandBuffer = undefined;
        try vkDie(c.vkAllocateCommandBuffers(hardware.device, &allocateInfo, &buffer));

        return .{
            .pool = pool,
            .buffer = buffer,
            .acquireImageSemaphore = try createSemaphore(hardware)
        };
    }
    pub fn deinit(self: *Self, hardware: HardwareCtx) void {
        c.vkDestroyCommandPool(hardware.device, self.pool, null);
        c.vkDestroySemaphore(hardware.device, self.acquireImageSemaphore, null);
    }

    pub fn beginRecording(self: *Self) !void {
        const inheritanceInfo: c.VkCommandBufferInheritanceInfo = .{
            .sType = c.VK_STRUCTURE_TYPE_COMMAND_BUFFER_INHERITANCE_INFO,
            .pNext = null,
            // using dynamic rendering so this is ignored
            .renderPass = undefined,
            .subpass = undefined,
            .framebuffer = undefined,
            .occlusionQueryEnable = c.VK_FALSE,
            .queryFlags = 0,
            .pipelineStatistics = 0
        };
        const beginInfo: c.VkCommandBufferBeginInfo = .{
            .sType = c.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO,
            .pNext = null,
            .flags = c.VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT,
            .pInheritanceInfo = &inheritanceInfo
        };
        try vkDie(c.vkBeginCommandBuffer(self.buffer, &beginInfo));
    }
    pub fn endRecording(self: *Self) !void {
        try vkDie(c.vkEndCommandBuffer(self.buffer));
    }
};
