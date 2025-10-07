![NitroPascal](media/nitropascal.png)

<div align="center">

[![Chat on Discord](https://img.shields.io/discord/754884471324672040?style=for-the-badge)](https://discord.gg/tinyBigGAMES) [![Follow on Bluesky](https://img.shields.io/badge/Bluesky-tinyBigGAMES-blue?style=for-the-badge&logo=bluesky)](https://bsky.app/profile/tinybiggames.com)

**Modern Pascal • C Performance**

*Write elegant NitroPascal, compile to blazing-fast native code*

[Website](https://nitropascal.org) • [Documentation](#-documentation) • [Examples](#-quick-example) • [Contributing](#-contributing)

</div>

---

## 📑 Table of Contents

- [Introduction](#-introduction)
- [What Makes It Special](#-what-makes-it-special)
- [How It Works](#-how-it-works)
- [Quick Example](#-quick-example)
- [Why NitroPascal](#-why-nitropascal)
- [Features](#-features)
- [Getting Started](#-getting-started)
- [Documentation](#-documentation)
- [Contributing](#-contributing)
- [License](#-license)
- [Acknowledgments](#-acknowledgments)

---

## 🎯 Introduction

NitroPascal is a next-generation Pascal implementation that bridges the elegance of Pascal with the raw performance of C. By combining modern language features with low-level optimization capabilities, NitroPascal aims to deliver the best of both worlds: readable, maintainable code that doesn't sacrifice speed.

## 🔥 What Makes It Special?

NitroPascal takes a revolutionary approach to achieving C-level performance: **transpilation**. Instead of interpreting or compiling directly to bytecode, NitroPascal transpiles modern NitroPascal code into highly optimized, idiomatic C++. This intermediate C++ representation is then compiled using **Zig as a drop-in C++ compiler**, with the entire build orchestrated through **build.zig**, unlocking:

- 🎯 **Multi-Target Compilation**: Generate native binaries for Windows, Linux, macOS, and beyond
- ⚡ **Aggressive Optimization**: Leverage decades of C++ compiler optimization research through Zig's LLVM backend
- 🔧 **Unified Build System**: Simple, powerful builds with Zig's build.zig
- 🌐 **Cross-Platform Excellence**: Write once in Pascal, deploy everywhere with native performance
- 🔗 **Natural Interop**: Generated C++ code interfaces seamlessly with existing C/C++ libraries

By standing on the shoulders of the C++ ecosystem while leveraging Zig's modern toolchain and preserving Pascal's elegance, NitroPascal delivers truly uncompromising performance without sacrificing developer productivity.

## 🔄 How It Works

NitroPascal's compilation pipeline transforms your Pascal code through multiple stages for optimal performance:

```
┌─────────────────┐
│  NitroPascal    │  Write clean, modern Pascal code
│     Source      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  NitroPascal    │  Parse and analyze with custom parser
│   Transpiler    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Optimized C++  │  Generate idiomatic, optimized C++
│      Code       │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Zig Compiler   │  Compile with Zig (drop-in C++ compiler)
│  (LLVM Backend) │  Leverage LLVM optimizations
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Native Binary   │  Lightning-fast executable
│  Multi-Platform │
└─────────────────┘
```

## 💻 Quick Example

See how elegant Pascal code transforms into optimized C++:

<table>
<tr>
<th>NitroPascal Source</th>
<th>Generated C++ Code</th>
</tr>
<tr>
<td>

```pascal
$optimize "debug"

program HelloWorld;

extern <stdio.h> routine printf(format: ^char; ...): int;

routine Greet(name: ^char);
begin
  printf("Hello, %s!\n", name);
end;

begin
  Greet("NitroPascal");
  ExitCode := 0;
end.
```

</td>
<td>

```cpp
// Optimized C++ output
#include <stdio.h>

void Greet(const char* name) {
  printf("Hello, %s!\n", name);
}

int main() {
  Greet("NitroPascal");
  return 0;
}
```

</td>
</tr>
</table>

## 💡 Why NitroPascal?

Pascal has always been celebrated for its clarity and strong typing, making it an excellent choice for teaching and building reliable software. However, performance-critical applications have traditionally gravitated toward C/C++. NitroPascal challenges this dichotomy by:

- **Breaking the Performance Ceiling**: Achieving C-level performance without abandoning Pascal's clarity
- **Modern Language Features**: Bringing contemporary programming paradigms to the Pascal ecosystem
- **Zero-Cost Abstractions**: High-level constructs that compile down to optimal machine code
- **Developer Experience**: Maintaining the readability and maintainability that made Pascal beloved

## ✨ Features

### Language & Syntax
- 🎨 **Clean, expressive syntax** that doesn't compromise on power
- 📝 **Modern Pascal syntax** with contemporary language features
- 🔒 **Memory safety** through strong typing without garbage collection overhead

### Performance & Optimization
- ⚡ **C-level performance** through advanced transpilation
- 🔥 **Optimized runtime** engineered for maximum speed
- 🎯 **Zero-cost abstractions** that compile to optimal machine code

### Build & Deployment
- 🛠️ **Modern tooling** powered by Zig's build system
- 🌐 **Cross-platform compilation** for Windows, Linux, macOS, and more
- ⚙️ **Low-level control** when you need it, high-level abstractions when you don't

### Interoperability
- 📦 **Seamless C/C++ interop** for leveraging existing ecosystems
- 🔗 **Natural FFI** through generated C++ code
- 🌍 **Library ecosystem access** to the vast C/C++ world

## 🚀 Getting Started

Download the latest release from the [Releases page](https://github.com/tinyBigGAMES/NitroPascal/releases). All dependencies are bundled - no separate installations required!

> **Note**: NitroPascal is currently under active development. Check the releases page for the latest version!

## 📚 Documentation

- **[Third-Party Libraries](THIRD-PARTY.md)** - Open source libraries used by NitroPascal
- **[Website](https://nitropascal.org)** - Official NitroPascal website
- **API Reference** *(coming soon)*
- **Language Guide** *(coming soon)*

## 🤝 Contributing

We welcome contributions! NitroPascal is in active development and there are many ways to help:

- 🐛 Report bugs and issues
- 💡 Suggest new features
- 📖 Improve documentation
- 🔧 Submit pull requests

Please check our [Contributing Guidelines](CONTRIBUTING.md) *(coming soon)* for more details.

## 📄 License

NitroPascal is licensed under the [BSD-3-Clause License](https://github.com/tinyBigGAMES/NitroPascal?tab=BSD-3-Clause-1-ov-file#BSD-3-Clause-1-ov-file).

### Why BSD-3-Clause?

The BSD-3-Clause license is a permissive open-source license that provides you with:

- ✅ **Commercial Use** - Use NitroPascal in commercial projects without restrictions
- ✅ **Modification** - Modify the source code to fit your needs
- ✅ **Distribution** - Redistribute the software freely
- ✅ **Private Use** - Use NitroPascal in private/proprietary projects
- ✅ **No Copyleft** - No requirement to open-source your projects built with NitroPascal

This means you can use NitroPascal to build both open-source and proprietary applications without worrying about licensing conflicts. The only requirements are to include the copyright notice and disclaimer in distributions.

## 🙏 Acknowledgments

NitroPascal builds upon excellent open-source projects:

- **[LLVM](https://github.com/llvm/llvm-project)** - Compiler infrastructure
- **[Zig](https://github.com/ziglang/zig)** - Programming language and toolchain

See [THIRD-PARTY.md](THIRD-PARTY.md) for complete attribution.

---

## 🚧 Status

> **Currently Under Construction** 🏗️
> 
> NitroPascal is in active development. Star the repo to stay updated!

---

*Built with passion for performance and elegance* ⚡

**© 2025-present tinyBigGAMES™ LLC • All Rights Reserved**
