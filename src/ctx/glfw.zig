const c = @import("c");

pub const GlfwCtx = struct {
    window: *c.GLFWwindow,
    const Self = @This();
    pub fn init() !Self {
        if (c.glfwInit() != c.GLFW_TRUE) return error.FailedToInitGlfw;
        c.glfwWindowHint(c.GLFW_CLIENT_API, c.GLFW_NO_API);
        const window = c.glfwCreateWindow(640, 480, "uwu", null, null).?;
        return .{ .window = window };
    }
    pub fn deinit(self: *Self) void {
        c.glfwDestroyWindow(self.window);
        c.glfwTerminate();
    }
};
