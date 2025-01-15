const std = @import("std");
const c = @import("c.zig");
const utils = @import("./utils.zig");

const ShaderProgram = @This();

const ShaderType = enum { vertex, fragment };

const log = std.log.scoped(.shader);

vid: ?c.GLuint,
fid: ?c.GLuint,
pid: c.GLuint,

pub fn init() ShaderProgram {
    return .{
        .vid = null,
        .fid = null,
        .pid = c.glCreateProgram(),
    };
}

pub fn deinit(self: ShaderProgram) void {
    c.glUseProgram(0);
    c.glDeleteProgram(self.pid);
}

pub fn add(self: *ShaderProgram, allocator: std.mem.Allocator, filepath: []const u8, shader_type: ShaderType) !void {
    const id = switch (shader_type) {
        inline .vertex => c.glCreateShader(c.GL_VERTEX_SHADER),
        inline .fragment => c.glCreateShader(c.GL_FRAGMENT_SHADER),
    };

    switch (shader_type) {
        inline .vertex => self.vid = id,
        inline .fragment => self.fid = id,
    }

    const source = try utils.readFile(allocator, filepath);
    defer allocator.free(source);

    c.glShaderSource(id, 1, @as([*c]const [*c]const u8, @ptrCast(&source)), 0);
    c.glCompileShader(id);

    var result: c.GLint = -1;
    c.glGetShaderiv(id, c.GL_COMPILE_STATUS, &result);

    if (result == c.GL_TRUE) return;

    var buffer: [2048]u8 = undefined;
    var length: c_uint = undefined;

    c.glGetShaderInfoLog(id, 2048, @ptrCast(&length), &buffer);
    log.err("{s}", .{buffer[0..@intCast(length)]});
    return error.CompileError;
}

pub fn link(self: *ShaderProgram) !void {
    if (self.vid) |v| c.glAttachShader(self.pid, v);
    if (self.fid) |f| c.glAttachShader(self.pid, f);
    defer if (self.vid) |v| c.glDeleteShader(v);
    defer if (self.fid) |f| c.glDeleteShader(f);
    c.glLinkProgram(self.pid);

    var success: c_int = 0;
    c.glGetProgramiv(self.pid, c.GL_LINK_STATUS, &success);

    if (success == 0) {
        var buf: [1024]u8 = undefined;
        var len: c.GLsizei = 0;
        c.glGetProgramInfoLog(self.pid, buf.len, &len, &buf);
        std.log.err("Program linking failed: {s}", .{buf[0..@intCast(len)]});
        return error.ProgramLinkFailed;
    }
}

pub fn use(self: ShaderProgram) void {
    c.glUseProgram(self.pid);
}

// fn validate(self: ShaderProgram) !void {}
