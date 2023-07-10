const std = @import("std");
const Allocator = std.mem.Allocator;
const c = @import("c");

pub const HardwareCtx = @import("hardware.zig").HardwareCtx;
pub const GlfwCtx = @import("glfw.zig").GlfwCtx;
//pub const DebugCtx = @import("debug.zig").DebugCtx;
pub const RenderingCtx = @import("rendering.zig").RenderingCtx;
pub const CommandCtx = @import("command.zig").CommandCtx;

const layers = [_][*:0]const u8 {
    "VK_LAYER_KHRONOS_validation"
};

const extensions = [_][*:0]const u8 {
    c.VK_KHR_SWAPCHAIN_EXTENSION_NAME,
    c.VK_KHR_DYNAMIC_RENDERING_EXTENSION_NAME
};

const features: c.VkValidationFeaturesEXT = .{
    .sType = c.VK_STRUCTURE_TYPE_VALIDATION_FEATURES_EXT,
    .pNext = null,
    .enabledValidationFeatureCount = 2,
    .pEnabledValidationFeatures = &[2]c.VkValidationFeatureEnableEXT {
        c.VK_VALIDATION_FEATURE_ENABLE_GPU_ASSISTED_EXT,
        c.VK_VALIDATION_FEATURE_ENABLE_SYNCHRONIZATION_VALIDATION_EXT
    },
    .disabledValidationFeatureCount = 0,
    .pDisabledValidationFeatures = null
};

pub const Ctx = struct {
    hardware: HardwareCtx,
    glfw: GlfwCtx,
    //debug: DebugCtx,
    rendering: RenderingCtx,
    command: CommandCtx,
    const Self = @This();
    pub fn init(allocator: Allocator) !Self {
        const glfw = try GlfwCtx.init();
        const hardware = try HardwareCtx.init(
            allocator,
            @constCast(layers[0..]),
            @constCast(extensions[0..]),
            features
        );
        //const debug = try DebugCtx.init(hardware);
        const rendering = try RenderingCtx.init(allocator, hardware, glfw);

        const command = try CommandCtx.init(hardware);
        return .{ 
            .hardware = hardware,
            .glfw = glfw,
            //.debug = debug,
            .rendering = rendering,
            .command = command
        };
    }
    pub fn deinit(self: *Self) void {
        self.glfw.deinit();
        self.rendering.deinit(self.hardware);
        self.command.deinit(self.hardware);
        //self.debug.deinit(self.hardware);
        self.hardware.deinit();
    }
    pub fn run(self: *Self) !void {
        while (c.glfwWindowShouldClose(self.glfw.window) == c.GLFW_FALSE) {
            try self.rendering.draw(self.hardware, &self.command);
        }
    }
};
