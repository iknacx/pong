const std = @import("std");
const c = @import("c.zig");
const utils = @import("utils.zig");
const ShaderProgram = @import("ShaderProgram.zig");

const log = std.log.scoped(.main);

const vertices: []const f32 = &.{
    //|  pos  |    uv   |
    -0.5, -0.5, 0.0, 0.0,
    0.5,  -0.5, 1.0, 0.0,
    0.5,  0.5,  0.0, 1.0,
    -0.5, 0.5,  1.0, 1.0,
};

const indices: []const u32 = &.{ 0, 1, 2, 3 };

fn onResize(_: ?*c.GLFWwindow, w: c_int, h: c_int) callconv(.C) void {
    width = w;
    height = h;
    c.glViewport(0, 0, width, height);
}

fn onGLFWError(_: c_int, description: [*c]const u8) callconv(.C) void {
    std.debug.panic("GLFW Error: {s}", .{description});
}

fn onGLError(_: c.GLenum, ty: c.GLenum, _: c.GLuint, severity: c.GLenum, _: c.GLsizei, message: [*c]const u8, _: ?*const anyopaque) callconv(.C) void {
    if (ty == c.GL_DEBUG_TYPE_ERROR) {
        log.err("GL CALLBACK(type: 0x{x}, severity: 0x{x}, message: {s})", .{
            ty,
            severity,
            message,
        });
    } else {
        log.warn("GL CALLBACK(type: 0x{x}, severity: 0x{x}, message: {s})", .{
            ty,
            severity,
            message,
        });
    }
}

var width: i32 = 800;
var height: i32 = 600;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    _ = c.glfwSetErrorCallback(onGLFWError);

    if (c.glfwInit() == c.GLFW_FALSE) return error.GlfwInit;
    defer c.glfwTerminate();

    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MAJOR, 4);
    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MINOR, 6);
    c.glfwWindowHint(c.GLFW_OPENGL_PROFILE, c.GLFW_OPENGL_CORE_PROFILE);
    // c.glfwWindowHint(c.GLFW_RESIZABLE, c.GLFW_FALSE);

    const window = c.glfwCreateWindow(width, height, "Pong", null, null) orelse return error.WindowCreation;
    defer c.glfwDestroyWindow(window);
    c.glfwMakeContextCurrent(window);

    if (c.gladLoadGLLoader(@ptrCast(&c.glfwGetProcAddress)) == c.GL_FALSE) return error.glInit;
    c.glDebugMessageCallback(&onGLError, null);
    _ = c.glfwSetFramebufferSizeCallback(window, onResize);

    var sp = ShaderProgram.init();
    defer sp.deinit();
    try sp.add(allocator, "assets/shaders/base.vs", .vertex);
    try sp.add(allocator, "assets/shaders/base.fs", .fragment);
    try sp.link();
    sp.use();

    const attrib_pos = 0;
    const attrib_uv = 1;

    var vao: u32 = undefined;
    c.glCreateVertexArrays(1, &vao);

    var vbo: u32 = undefined;
    c.glCreateBuffers(1, &vbo);
    c.glNamedBufferStorage(vbo, vertices.len * @sizeOf(f32), @ptrCast(vertices), c.GL_DYNAMIC_STORAGE_BIT);

    var ebo: u32 = undefined;
    c.glCreateBuffers(1, &ebo);
    c.glNamedBufferStorage(ebo, indices.len * @sizeOf(u32), @ptrCast(indices), c.GL_DYNAMIC_STORAGE_BIT);

    const vao_binding_point = 0;
    c.glVertexArrayVertexBuffer(vao, vao_binding_point, vbo, 0, @sizeOf(f32) * 4);
    c.glVertexArrayElementBuffer(vao, ebo);

    c.glEnableVertexArrayAttrib(vao, attrib_pos);
    c.glEnableVertexArrayAttrib(vao, attrib_uv);

    c.glVertexArrayAttribFormat(vao, attrib_pos, 2, c.GL_FLOAT, c.GL_FALSE, 0);
    c.glVertexArrayAttribFormat(vao, attrib_uv, 2, c.GL_FLOAT, c.GL_FALSE, @sizeOf(f32) * 2);

    c.glVertexArrayAttribBinding(vao, attrib_pos, vao_binding_point);
    c.glVertexArrayAttribBinding(vao, attrib_uv, vao_binding_point);

    c.glViewport(0, 0, width, height);

    c.glClearColor(0.1, 0.1, 0.1, 1.0);
    while (c.glfwWindowShouldClose(window) == c.GLFW_FALSE) {
        c.glClear(c.GL_COLOR_BUFFER_BIT);

        c.glBindVertexArray(vao);

        c.glDrawElements(c.GL_TRIANGLE_FAN, 4, c.GL_UNSIGNED_INT, null);

        c.glfwSwapBuffers(window);
        c.glfwPollEvents();
    }
}
