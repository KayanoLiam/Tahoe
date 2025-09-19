const std = @import("std");

// 引入JavaScriptCore的C头文件
// 通过@cImport和@cInclude实现C互操作性
// 这允许我们在Zig代码中调用JavaScriptCore的C API
const c = @cImport({
    @cInclude("JavaScriptCore/JavaScript.h");
});

// 这是一个console.log的回调函数，用于将JavaScript中的console.log输出到Zig的标准输出
// 使用export而不是extern，因为这个函数是在Zig中实现并导出给C使用的
export fn console_log_callback(
    ctx: c.JSContextRef, // JavaScript上下文
    _: c.JSObjectRef, // 当前对象（未使用）
    _: c.JSObjectRef, // this对象（未使用）
    argumentCount: usize, // 参数数量
    arguments: [*c]const c.JSValueRef, // 参数数组
    _: [*c]c.JSValueRef, // 异常指针（未使用）
) callconv(.C) c.JSValueRef { // 返回一个JSValueRef，使用C调用约定
    const allocator = std.heap.page_allocator;
    var i: usize = 0;
    // 遍历所有参数，将它们转换为字符串并输出
    while (i < argumentCount) : (i += 1) {
        var exc_temp: c.JSValueRef = null; // 异常临时变量
        const js_str = c.JSValueToStringCopy(ctx, arguments[i], &exc_temp);
        if (js_str != null) {
            const max_size = c.JSStringGetMaximumUTF8CStringSize(js_str);
            var buf = allocator.alloc(u8, max_size) catch return c.JSValueMakeUndefined(ctx);
            defer allocator.free(buf);
            const written = c.JSStringGetUTF8CString(js_str, buf.ptr, max_size);
            if (written > 1) {
                const slice = buf[0 .. written - 1];
                std.debug.print("{s}", .{slice});
            }
            c.JSStringRelease(js_str);
        }
        // 在参数之间添加空格分隔符
        if (i + 1 < argumentCount) {
            std.debug.print(" ", .{});
        }
    }
    std.debug.print("\n", .{});
    return c.JSValueMakeUndefined(ctx);
}

fn register_console(ctx: c.JSGlobalContextRef) void {
    const global = c.JSContextGetGlobalObject(ctx);

    const console_name = c.JSStringCreateWithUTF8CString("console");
    const console_obj = c.JSObjectMake(ctx, null, null);
    _ = c.JSObjectSetProperty(ctx, global, console_name, console_obj, 0, null);
    c.JSStringRelease(console_name);

    const log_name = c.JSStringCreateWithUTF8CString("log");
    const func_obj = c.JSObjectMakeFunctionWithCallback(ctx, log_name, console_log_callback);
    _ = c.JSObjectSetProperty(ctx, console_obj, log_name, func_obj, 0, null);
    c.JSStringRelease(log_name);
}

pub fn main() !void {
    // 使用页面分配器来管理内存
    // 这是Zig的标准内存分配器之一，适合简单的内存管理需求
    const allocator = std.heap.page_allocator;
    // 获取命令行参数
    // argsAlloc会分配内存来存储所有命令行参数
    // 使用const因为args在后续代码中不会被重新赋值（符合Zig最佳实践）
    const args = try std.process.argsAlloc(allocator);
    // 确保在函数结束时释放内存，避免内存泄漏
    defer std.process.argsFree(allocator, args);
    // 检查命令行参数数量
    // args[0]是程序名，args[1]是脚本文件名
    if (args.len < 2) {
        // 在Zig 0.14.1中，字符串参数必须使用{s}格式说明符
        std.debug.print("Usage: {s} <script.js>\n", .{args[0]});
        return;
    }
    // 获取JavaScript文件路径（第一个命令行参数）
    const js_file_path = args[1];
    // 打印确认信息，显示即将执行的脚本文件
    // 使用{s}格式说明符来正确格式化字符串
    std.debug.print("Running script: {s}\n", .{js_file_path});
    // 打开JavaScript文件进行读取
    // 使用当前工作目录的openFile方法，以只读模式打开文件
    const file = try std.fs.cwd().openFile(js_file_path, .{});
    // 确保文件在函数结束时关闭，防止文件句柄泄漏
    defer file.close();

    // 读取文件内容到内存中
    // 在Zig 0.14.1中，readToEndAlloc只需要allocator和max_bytes两个参数
    // 设置最大读取字节数为1MB，防止读取过大的文件导致内存问题
    const contents = try file.readToEndAlloc(allocator, 1024 * 1024);
    // 确保在函数结束时释放文件内容占用的内存
    defer allocator.free(contents);

    // 打印JavaScript文件的内容
    // 使用{s}格式说明符来正确显示字符串内容
    std.debug.print("JavaScript file contents:\n{s}\n", .{contents});
    // 创建一个JavaScript执行环境
    // JSGlobalContextCreate创建一个全局JavaScript上下文
    const ctx = c.JSGlobalContextCreate(null);
    // 确保在函数结束时释放JavaScript上下文，防止内存泄漏
    defer c.JSGlobalContextRelease(ctx);

    register_console(ctx);

    // 将文件内容转换为JavaScript字符串
    // 需要将Zig的[]u8切片转换为C字符串指针[*c]const u8
    // 使用.ptr获取指针，但首先需要确保字符串以null结尾
    const null_terminated_contents = try allocator.dupeZ(u8, contents);
    defer allocator.free(null_terminated_contents);

    const js_string = c.JSStringCreateWithUTF8CString(null_terminated_contents.ptr);
    // 确保在函数结束时释放JavaScript字符串对象
    defer c.JSStringRelease(js_string);

    // 执行JavaScript代码
    // JSEvaluateScript用于执行JavaScript代码并返回结果
    var exception: c.JSValueRef = null;
    const js_result = c.JSEvaluateScript(ctx, js_string, null, null, 0, &exception);

    // 检查是否有执行异常
    if (exception != null) {
        // 将异常转换为字符串并打印
        const exception_string = c.JSValueToStringCopy(ctx, exception, null);
        defer c.JSStringRelease(exception_string);

        // 获取异常字符串的UTF8表示
        const exception_length = c.JSStringGetMaximumUTF8CStringSize(exception_string);
        const exception_buffer = try allocator.allocSentinel(u8, exception_length - 1, 0);
        defer allocator.free(exception_buffer);
        const actual_exception_length = c.JSStringGetUTF8CString(exception_string, exception_buffer.ptr, exception_length);

        if (actual_exception_length > 1) {
            const exception_str = exception_buffer[0 .. actual_exception_length - 1];
            std.debug.print("JavaScript执行错误: {s}\n", .{exception_str});
        }
    } else {
        std.debug.print("JavaScript代码执行完毕!\n", .{});

        // 如果有返回值，尝试打印结果
        if (js_result != null) {
            const result_string = c.JSValueToStringCopy(ctx, js_result, null);
            if (result_string != null) {
                defer c.JSStringRelease(result_string);

                const result_length = c.JSStringGetMaximumUTF8CStringSize(result_string);
                const result_buffer = try allocator.allocSentinel(u8, result_length - 1, 0);
                defer allocator.free(result_buffer);
                const actual_length = c.JSStringGetUTF8CString(result_string, result_buffer.ptr, result_length);

                if (actual_length > 1) {
                    // 只有当结果不是"undefined"时才显示
                    const result_str = result_buffer[0 .. actual_length - 1];
                    if (!std.mem.eql(u8, result_str, "undefined")) {
                        std.debug.print("JavaScript执行结果: {s}\n", .{result_str});
                    }
                }
            }
        }
    }
}
