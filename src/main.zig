const std = @import("std");

// 引入JavaScriptCore的C头文件
// Import JavaScriptCore C headers
// 通过@cImport和@cInclude实现C互操作性
// Using @cImport and @cInclude to achieve C interoperability
// 这允许我们在Zig代码中调用JavaScriptCore的C API
// This allows us to call JavaScriptCore C APIs from Zig code
const c = @cImport({
    @cInclude("JavaScriptCore/JavaScript.h");
});

// 这是一个console.log的回调函数，用于将JavaScript中的console.log输出到Zig的标准输出
// Callback function for console.log to output JavaScript console.log to Zig's standard output
// 使用export而不是extern，因为这个函数是在Zig中实现并导出给C使用的
// Using export instead of extern because this function is implemented in Zig and exported for C use
export fn console_log_callback(
    ctx: c.JSContextRef, // JavaScript上下文 | JavaScript context
    _: c.JSObjectRef, // 当前对象（未使用） | Current object (unused)
    _: c.JSObjectRef, // this对象（未使用） | This object (unused)
    argumentCount: usize, // 参数数量 | Number of arguments
    arguments: [*c]const c.JSValueRef, // 参数数组 | Array of arguments
    _: [*c]c.JSValueRef, // 异常指针（未使用） | Exception pointer (unused)
) callconv(.C) c.JSValueRef { // 返回一个JSValueRef，使用C调用约定 | Returns a JSValueRef, using C calling convention
    const allocator = std.heap.page_allocator;
    var i: usize = 0;
    // 遍历所有参数，将它们转换为字符串并输出
    // Iterate through all arguments, convert them to strings and output
    while (i < argumentCount) : (i += 1) {
        var exc_temp: c.JSValueRef = null; // 异常临时变量 | Temporary exception variable
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
        // Add space separator between arguments
        if (i + 1 < argumentCount) {
            std.debug.print(" ", .{});
        }
    }
    std.debug.print("\n", .{});
    return c.JSValueMakeUndefined(ctx);
}

// 注册console对象和console.log方法到JavaScript全局上下文
// Register console object and console.log method in JavaScript global context
fn register_console(ctx: c.JSGlobalContextRef) void {
    // 获取全局对象 | Get the global object
    const global = c.JSContextGetGlobalObject(ctx);

    // 创建console对象名称字符串 | Create console object name string
    const console_name = c.JSStringCreateWithUTF8CString("console");
    // 创建console对象 | Create console object
    const console_obj = c.JSObjectMake(ctx, null, null);
    // 将console对象设置为全局属性 | Set console object as global property
    _ = c.JSObjectSetProperty(ctx, global, console_name, console_obj, 0, null);
    c.JSStringRelease(console_name);

    // 创廾log方法名称字符串 | Create log method name string
    const log_name = c.JSStringCreateWithUTF8CString("log");
    // 创建带回调的log函数 | Create log function with callback
    const func_obj = c.JSObjectMakeFunctionWithCallback(ctx, log_name, console_log_callback);
    // 将log方法设置为console对象属性 | Set log method as console object property
    _ = c.JSObjectSetProperty(ctx, console_obj, log_name, func_obj, 0, null);
    c.JSStringRelease(log_name);
}

pub fn main() !void {
    // 使用页面分配器来管理内存
    // Use page allocator for memory management
    // 这是Zig的标准内存分配器之一，适合简单的内存管理需求
    // This is one of Zig's standard memory allocators, suitable for simple memory management needs
    const allocator = std.heap.page_allocator;
    // 获取命令行参数
    // Get command line arguments
    // argsAlloc会分配内存来存储所有命令行参数
    // argsAlloc allocates memory to store all command line arguments
    // 使用const因为args在后续代码中不会被重新赋值（符合Zig最佳实践）
    // Use const because args won't be reassigned in subsequent code (follows Zig best practices)
    const args = try std.process.argsAlloc(allocator);
    // 确保在函数结束时释放内存，避免内存泄漏
    // Ensure memory is freed when function ends, avoiding memory leaks
    defer std.process.argsFree(allocator, args);
    // 检查命令行参数数量
    // Check number of command line arguments
    // args[0]是程序名，args[1]是脚本文件名
    // args[0] is program name, args[1] is script file name
    if (args.len < 2) {
        // 在Zig 0.14.1中，字符串参数必须使用{s}格式说明符
        // In Zig 0.14.1, string parameters must use {s} format specifier
        std.debug.print("Usage: {s} <script.js>\n", .{args[0]});
        return;
    }
    // 获取JavaScript文件路径（第一个命令行参数）
    // Get JavaScript file path (first command line argument)
    const js_file_path = args[1];
    // 打印确认信息，显示即将执行的脚本文件
    // Print confirmation message showing script to be executed
    // 使用{s}格式说明符来正确格式化字符串
    // Use {s} format specifier to correctly format strings
    std.debug.print("Running script: {s}\n", .{js_file_path});
    // 打开JavaScript文件进行读取
    // Open JavaScript file for reading
    // 使用当前工作目录的openFile方法，以只读模式打开文件
    // Use current working directory's openFile method to open file in read-only mode
    const file = try std.fs.cwd().openFile(js_file_path, .{});
    // 确保文件在函数结束时关闭，防止文件句柄泄漏
    // Ensure file is closed when function ends, preventing file handle leaks
    defer file.close();

    // 读取文件内容到内存中
    // Read file content into memory
    // 在Zig 0.14.1中，readToEndAlloc只需要allocator和max_bytes两个参数
    // In Zig 0.14.1, readToEndAlloc only needs allocator and max_bytes parameters
    // 设置最大读取字节数为1MB，防止读取过大的文件导致内存问题
    // Set maximum read bytes to 1MB to prevent reading large files causing memory issues
    const contents = try file.readToEndAlloc(allocator, 1024 * 1024);
    // 确保在函数结束时释放文件内容占用的内存
    // Ensure file content memory is freed when function ends
    defer allocator.free(contents);

    // 打印JavaScript文件的内容
    // Print JavaScript file content
    // 使用{s}格式说明符来正确显示字符串内容
    // Use {s} format specifier to correctly display string content
    std.debug.print("JavaScript file contents:\n{s}\n", .{contents});
    // 创建一个JavaScript执行环境
    // Create a JavaScript execution environment
    // JSGlobalContextCreate创建一个全局JavaScript上下文
    // JSGlobalContextCreate creates a global JavaScript context
    const ctx = c.JSGlobalContextCreate(null);
    // 确保在函数结束时释放JavaScript上下文，防止内存泄漏
    // Ensure JavaScript context is released when function ends, preventing memory leaks
    defer c.JSGlobalContextRelease(ctx);

    // 注册console对象和方法
    // Register console object and methods
    register_console(ctx);

    // 将文件内容转换为JavaScript字符串
    // Convert file content to JavaScript string
    // 需要将Zig的[]u8切片转换为C字符串指针[*c]const u8
    // Need to convert Zig's []u8 slice to C string pointer [*c]const u8
    // 使用.ptr获取指针，但首先需要确保字符串以null结尾
    // Use .ptr to get pointer, but first ensure string is null-terminated
    const null_terminated_contents = try allocator.dupeZ(u8, contents);
    defer allocator.free(null_terminated_contents);

    // 创建JavaScript字符串对象
    // Create JavaScript string object
    const js_string = c.JSStringCreateWithUTF8CString(null_terminated_contents.ptr);
    // 确保在函数结束时释放JavaScript字符串对象
    // Ensure JavaScript string object is released when function ends
    defer c.JSStringRelease(js_string);

    // 执行JavaScript代码
    // Execute JavaScript code
    // JSEvaluateScript用于执行JavaScript代码并返回结果
    // JSEvaluateScript is used to execute JavaScript code and return result
    var exception: c.JSValueRef = null;
    const js_result = c.JSEvaluateScript(ctx, js_string, null, null, 0, &exception);

    // 检查是否有执行异常
    // Check if there are execution exceptions
    if (exception != null) {
        // 将异常转换为字符串并打印
        // Convert exception to string and print
        const exception_string = c.JSValueToStringCopy(ctx, exception, null);
        defer c.JSStringRelease(exception_string);

        // 获取异常字符串的UTF8表示
        // Get UTF8 representation of exception string
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
        // If there's a return value, try to print the result
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
                    // Only display when result is not "undefined"
                    const result_str = result_buffer[0 .. actual_length - 1];
                    if (!std.mem.eql(u8, result_str, "undefined")) {
                        std.debug.print("JavaScript执行结果: {s}\n", .{result_str});
                    }
                }
            }
        }
    }
}
