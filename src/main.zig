const std = @import("std");
const c = @import("c.zig");
const utils = @import("utils.zig");
const ShaderProgram = @import("ShaderProgram.zig");

const log = std.log.scoped(.main);

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

    const window = c.glfwCreateWindow(800, 600, "Pong", null, null) orelse return error.WindowCreation;
    defer c.glfwDestroyWindow(window);
    c.glfwMakeContextCurrent(window);

    if (c.gladLoadGLLoader(@ptrCast(&c.glfwGetProcAddress)) == c.GL_FALSE) return error.glInit;
    c.glDebugMessageCallback(&onGLError, null);

    var sp = ShaderProgram.init();
    defer sp.deinit();
    try sp.add(allocator, "assets/shaders/base.vs", .vertex);
    try sp.add(allocator, "assets/shaders/base.fs", .fragment);
    try sp.link();
    sp.use();

    const vertices: []const f32 = &.{
        -1.0, -1.0, 0.0, 1.0, 0.0, 0.0,
        1.0,  -1.0, 0.0, 0.0, 1.0, 0.0,
        0.0,  1.0,  0.0, 0.0, 0.0, 1.0,
    };

    const attrib_pos = 0;
    const attrib_col = 1;

    var vbo: u32 = undefined;
    c.glCreateBuffers(1, &vbo);

    c.glNamedBufferStorage(vbo, vertices.len * 8, @ptrCast(vertices), c.GL_DYNAMIC_STORAGE_BIT);

    var vao: u32 = undefined;
    c.glCreateVertexArrays(1, &vao);

    const vao_binding_point = 0;
    c.glVertexArrayVertexBuffer(vao, vao_binding_point, vbo, 0, @sizeOf(f32) * 6);

    c.glEnableVertexArrayAttrib(vao, attrib_pos);
    c.glEnableVertexArrayAttrib(vao, attrib_col);

    c.glVertexArrayAttribFormat(vao, attrib_pos, 3, c.GL_FLOAT, c.GL_FALSE, 0);
    c.glVertexArrayAttribFormat(vao, attrib_col, 3, c.GL_FLOAT, c.GL_FALSE, @sizeOf(f32) * 3);

    c.glVertexArrayAttribBinding(vao, attrib_pos, vao_binding_point);
    c.glVertexArrayAttribBinding(vao, attrib_col, vao_binding_point);

    c.glClearColor(0.1, 0.1, 0.1, 1.0);
    while (c.glfwWindowShouldClose(window) == c.GLFW_FALSE) {
        c.glClear(c.GL_COLOR_BUFFER_BIT);

        c.glBindVertexArray(vao);
        c.glDrawArrays(c.GL_TRIANGLES, 0, 3);
        c.glfwSwapBuffers(window);
        c.glfwPollEvents();
    }
}
