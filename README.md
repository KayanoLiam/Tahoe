# Tahoe

Tahoe is a lightweight JavaScript runtime environment built with Zig, integrating Apple's JavaScriptCore engine.

## Features

- 🚀 **High Performance**: Built on Zig's memory safety and performance advantages
- 🔧 **JavaScriptCore Integration**: Uses Apple's mature JavaScript engine
- 🖥️ **Cross-Platform**: Supports macOS (extensible to other platforms)
- 📝 **Console Support**: Full console.log output functionality
- 🔒 **Memory Safe**: Zig's memory management ensures runtime safety

## System Requirements

- Zig 0.14.1 or higher
- macOS (for JavaScriptCore framework)
- Xcode Command Line Tools

## Installation and Usage

### Clone the Project

```bash
git clone https://github.com/KayanoLiam/Tahoe.git
cd Tahoe
```

### Build the Project

```bash
zig build
```

### Run JavaScript Files

```bash
zig build run -- your_script.js
```

Or use the compiled executable:

```bash
./zig-out/bin/tahoe your_script.js
```

## Example

Create a simple JavaScript file:

```javascript
// hello.js
console.log("Hello, World!");

function greet(name) {
    return "Hello, " + name + "!";
}

console.log(greet("Tahoe"));

var result = 2 + 3;
console.log("Result:", result);
```

Run it:

```bash
zig build run -- hello.js
```

Output:

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
console.log("Result:", result);
Hello, World!
Hello, Tahoe!
Result: 5
JavaScript execution completed!
```

## Supported JavaScript Features

- ✅ Basic data types (numbers, strings, booleans)
- ✅ Variable declaration and assignment
- ✅ Function definition and invocation
- ✅ Objects and methods
- ✅ Control flow (if/else, loops, etc.)
- ✅ console.log output
- ✅ Expression evaluation and return values

## Project Structure

```
Tahoe/
├── build.zig          # Zig build configuration
├── build.zig.zon      # Package management configuration
├── src/
│   ├── main.zig       # Main program entry point
│   └── root.zig       # Library root file
├── test.js            # Test file
├── simple_test.js     # Simple test
├── comprehensive_test.js # Comprehensive test
└── README.md          # Project documentation
```

## Technical Architecture

Tahoe uses the following technology stack:

- **Zig**: Systems programming language providing memory safety and high performance
- **JavaScriptCore**: Apple's JavaScript engine
- **C Interop**: JavaScriptCore integration through Zig's C interoperability
- **Native Build System**: Uses Zig's native build tools

## Development Roadmap

- [ ] Add more JavaScript built-in object support
- [ ] File system API
- [ ] Network request support
- [ ] Module system
- [ ] Extend to Linux and Windows platforms

## Contributing

Issues and Pull Requests are welcome!

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Author

kayano

---

*Tahoe - A modern, safe, and high-performance JavaScript runtime environment*