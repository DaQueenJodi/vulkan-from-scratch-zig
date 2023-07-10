const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const c = @import("c");
const vkDie = @import("../helper.zig").vkDie;


pub fn getInstanceExtensions(allocator: Allocator) !ArrayList([*c]const u8) {
    var glfwExtensionCount: u32 = undefined;
    const glfwExtensions = c.glfwGetRequiredInstanceExtensions(&glfwExtensionCount);
    var neededExtensions = ArrayList([*c]const u8).init(allocator);
    try neededExtensions.appendSlice(glfwExtensions[0..glfwExtensionCount]);
    try neededExtensions.append(c.VK_EXT_DEBUG_UTILS_EXTENSION_NAME);
    return neededExtensions;
}
pub fn createInstance(
    allocator: Allocator,
    layers: [][*:0]const u8,
    validationFeatures: ?c.VkValidationFeaturesEXT
) !c.VkInstance {
    const appInfo: c.VkApplicationInfo = .{
        .sType = c.VK_STRUCTURE_TYPE_APPLICATION_INFO,
        .pNext = null,
        .pApplicationName = "uwu",
        .applicationVersion = c.VK_MAKE_VERSION(0.0, 0.0, 1.0),
        .pEngineName = "owo",
        .engineVersion = c.VK_MAKE_VERSION(0.0, 0.0, 1.0),
        .apiVersion = c.VK_API_VERSION_1_3,
    };
    const instanceExtensions = try getInstanceExtensions(allocator);
    defer instanceExtensions.deinit();
    var instance: c.VkInstance = undefined;
    const instanceCreateInfo: c.VkInstanceCreateInfo = .{
        .sType = c.VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO,
        .pNext = if (validationFeatures) |f| &f else null,
        .flags = 0,
        .pApplicationInfo = &appInfo,
        .enabledLayerCount = @intCast(layers.len),
        .ppEnabledLayerNames = layers.ptr,
        .enabledExtensionCount = @intCast(instanceExtensions.items.len),
        .ppEnabledExtensionNames = instanceExtensions.items.ptr,
    };
    try vkDie(c.vkCreateInstance(&instanceCreateInfo, null, &instance));
    return instance;
}

pub fn choosePhysicalDevice(
    allocator: Allocator,
    physicalDevices: []c.VkPhysicalDevice,
    extensions: [][*:0]const u8
) !c.VkPhysicalDevice {
    for (physicalDevices) |dev| {
        var extCount: u32 = undefined;
        try vkDie(c.vkEnumerateDeviceExtensionProperties(dev, null, &extCount, null));
        var availableExtensions = try allocator.alloc(c.VkExtensionProperties, extCount);
        defer allocator.free(availableExtensions);
        try vkDie(c.vkEnumerateDeviceExtensionProperties(dev, null, &extCount, availableExtensions.ptr));
        var allExtensionsAvailable = true;
        for (extensions) |target| {
            var found = false;
            for (availableExtensions) |actual| {
                const name: [:0]const u8 = @ptrCast(&actual.extensionName);
                if (std.mem.orderZ(u8, name, target) == .eq) found = true; 
            }
            if (!found) {
                allExtensionsAvailable = false; break; 
            }
        }
        if (!allExtensionsAvailable) continue;
        const families = try getQueueFamilies(allocator, dev);
        if (families.graphics == null) continue;
        return dev;
    }
    return error.FailedToFindSuitablePhysicalDevice;
}

const QueueFamilies = struct {
    graphics: ?u32,
};

pub fn getQueueFamilies(allocator: Allocator, physicalDevice: c.VkPhysicalDevice) !QueueFamilies {
    var queueFamilyCount: u32 = undefined;
    c.vkGetPhysicalDeviceQueueFamilyProperties(physicalDevice, &queueFamilyCount, null);
    var queueFamilies = try allocator.alloc(c.VkQueueFamilyProperties, queueFamilyCount);
    c.vkGetPhysicalDeviceQueueFamilyProperties(physicalDevice, &queueFamilyCount, queueFamilies.ptr);
    defer allocator.free(queueFamilies);
    var graphics: ?u32 = null;
    for (queueFamilies, 0..) |fam, i| {
        if ((fam.queueFlags & c.VK_QUEUE_GRAPHICS_BIT) > 0) {
            graphics = @intCast(i);
        }
    }
    return .{ .graphics = graphics };
}
pub fn createDevice(
    physicalDevice: c.VkPhysicalDevice,
    queueFamilies: QueueFamilies,
    layers: [][*:0]const u8,
    extensions: [][*:0]const u8
) !c.VkDevice {
    const queueCreateInfo: c.VkDeviceQueueCreateInfo = .{
        .sType = c.VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO,
        .pNext = null,
        .flags = 0,
        .queueFamilyIndex = queueFamilies.graphics.?,
        .queueCount = 1,
        .pQueuePriorities = &@as(f32, 1.0)
    };

    var features = std.mem.zeroes(c.VkPhysicalDeviceVulkan13Features);
    features.sType = c.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_3_FEATURES;
    features.pNext = null;

    const deviceCreateInfo: c.VkDeviceCreateInfo = .{
        .sType = c.VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO,
        .pNext = &features,
        .flags = 0,
        .queueCreateInfoCount = 1,
        .pQueueCreateInfos = &queueCreateInfo,
        .enabledLayerCount = @intCast(layers.len),
        .ppEnabledLayerNames = layers.ptr,
        .enabledExtensionCount = @intCast(extensions.len),
        .ppEnabledExtensionNames = extensions.ptr,
        .pEnabledFeatures = null
    };
    var device: c.VkDevice = undefined;
    try vkDie(c.vkCreateDevice(physicalDevice, &deviceCreateInfo, null, &device));
    return device;
}

pub const HardwareCtx = struct {
    physicalDevice: c.VkPhysicalDevice,
    device: c.VkDevice,
    instance: c.VkInstance,
    queueFamilies: QueueFamilies,
    graphicsQueue: c.VkQueue,
    const Self = @This();
    pub fn init(
        allocator: Allocator,
        layers: [][*:0]const u8,
        extensions: [][*:0]const u8,
        features: ?c.VkValidationFeaturesEXT
    ) !Self {
        const instance = try createInstance(allocator, layers, features);
        var physicalDeviceCount: u32 = undefined;
        try vkDie(c.vkEnumeratePhysicalDevices(instance, &physicalDeviceCount, null));
        var physicalDevices = try allocator.alloc(c.VkPhysicalDevice, physicalDeviceCount);
        defer allocator.free(physicalDevices);
        try vkDie(c.vkEnumeratePhysicalDevices(instance, &physicalDeviceCount, physicalDevices.ptr));
        const physicalDevice = try choosePhysicalDevice(allocator, physicalDevices, extensions);
        const queueFamilies = try getQueueFamilies(allocator, physicalDevice);
        const device = try createDevice(physicalDevice, queueFamilies, layers, extensions);
        var graphicsQueue: c.VkQueue = undefined;
        c.vkGetDeviceQueue(device, queueFamilies.graphics.?, 0, &graphicsQueue);
        return .{
            .physicalDevice = physicalDevice,
            .device = device,
            .instance = instance,
            .queueFamilies = queueFamilies,
            .graphicsQueue = graphicsQueue
        };
    }
    pub fn deinit(self: *Self) void {
        c.vkDestroyDevice(self.device, null);
    }
};
