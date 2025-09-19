# Tahoe

Tahoe 是一个基于 Zig 语言开发的轻量级 JavaScript 运行时环境，集成了 Apple 的 JavaScriptCore 引擎。

## 特性

- 🚀 **高性能**: 基于 Zig 语言的内存安全和性能优势
- 🔧 **JavaScriptCore 集成**: 使用 Apple 成熟的 JavaScript 引擎
- 🖥️ **跨平台**: 支持 macOS 平台（可扩展到其他平台）
- 📝 **Console 支持**: 完整的 console.log 输出功能
- 🔒 **内存安全**: Zig 语言的内存管理保证运行时安全

## 系统要求

- Zig 0.14.1 或更高版本
- macOS（用于 JavaScriptCore 框架）
- Xcode Command Line Tools

## 安装和使用

### 克隆项目

```bash
git clone https://github.com/KayanoLiam/Tahoe.git
cd Tahoe
```

### 编译项目

```bash
zig build
```

### 运行 JavaScript 文件

```bash
zig build run -- your_script.js
```

或者使用编译后的可执行文件：

```bash
./zig-out/bin/tahoe your_script.js
```

## 示例

创建一个简单的 JavaScript 文件：

```javascript
// hello.js
console.log("Hello, World!");

function greet(name) {
    return "Hello, " + name + "!";
}

console.log(greet("Tahoe"));

var result = 2 + 3;
console.log("计算结果:", result);
```

运行：

```bash
zig build run -- hello.js
```

输出：

```
Running script: hello.js
JavaScript file contents:
// hello.js
console.log("Hello, World!");

function greet(name) {
    return "Hello, " + name + "!";
}

console.log(greet("Tahoe"));

var result = 2 + 3;
console.log("计算结果:", result);
Hello, World!
Hello, Tahoe!
计算结果: 5
JavaScript代码执行完毕!
```

## 支持的 JavaScript 功能

- ✅ 基本数据类型（数字、字符串、布尔值）
- ✅ 变量声明和赋值
- ✅ 函数定义和调用
- ✅ 对象和方法
- ✅ 控制流程（if/else、循环等）
- ✅ console.log 输出
- ✅ 表达式求值和返回值

## 项目结构

```
Tahoe/
├── build.zig          # Zig 构建配置
├── build.zig.zon      # 包管理配置
├── src/
│   ├── main.zig       # 主程序入口
│   └── root.zig       # 库根文件
├── test.js            # 测试文件
├── simple_test.js     # 简单测试
├── comprehensive_test.js # 综合测试
└── README.md          # 项目说明
```

## 技术架构

Tahoe 采用以下技术栈：

- **Zig**: 系统编程语言，提供内存安全和高性能
- **JavaScriptCore**: Apple 的 JavaScript 引擎
- **C 互操作**: 通过 Zig 的 C 互操作功能集成 JavaScriptCore
- **原生构建系统**: 使用 Zig 的原生构建工具

## 开发计划

- [ ] 添加更多 JavaScript 内置对象支持
- [ ] 文件系统 API
- [ ] 网络请求支持
- [ ] 模块系统
- [ ] 扩展到 Linux 和 Windows 平台

## 贡献

欢迎提交 Issue 和 Pull Request！

## 许可证

本项目采用 MIT 许可证。详见 [LICENSE](LICENSE) 文件。

## 作者

尹明华

---

*Tahoe - 一个现代、安全、高性能的 JavaScript 运行时环境*