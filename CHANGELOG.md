# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Repo Update** (2025-10-12 – jarroddavis68)
  Release v0.2.0: Core language features and RTL foundation
  This release establishes the foundational architecture and implements core
  Object Pascal language features with the RTL wrapping strategy.
  LANGUAGE FEATURES:
  - Complete basic type system (Integer, Double, String, Boolean, Pointer, etc.)
  - Type aliases and pointer type declarations
  - Constants (typed and untyped) and variables (local/global)
  - All arithmetic, comparison, logical, and bitwise operators
  - Control flow: if/else, case, for, while, repeat-until
  - Functions and procedures with multiple parameter passing modes
  - Static arrays, records, enumerations, and pointers
  - Memory management (New/Dispose)
  RUNTIME LIBRARY (RTL):
  - I/O functions (Write/WriteLn with variadic templates)
  - Control flow wrappers (ForLoop, WhileLoop, RepeatUntil)
  - Operator functions (Div, Mod, Shl, Shr)
  - String class (np::String with UTF-16 and 1-based indexing)
  - All Delphi semantics wrapped in np:: namespace
  CODE GENERATION:
  - Header (.h) and implementation (.cpp) file generation
  - Namespace per unit
  - RTL wrapping strategy: complexity in RTL, not codegen
  - Forward declarations and proper includes
  BUILD SYSTEM:
  - Zig build integration for cross-platform compilation
  - Multiple optimization modes (Debug, ReleaseSafe, ReleaseFast, ReleaseSmall)
  - Program → executable, Library → .dll/.so/.dylib, Unit → .lib/.a
  - Compiler directives support ({$optimization}, {$target}, etc.)
  TOOLS:
  - nitro CLI with build, run, clean, init, version, help commands
  PLATFORMS:
  - Windows x64, Linux x64, macOS x64
  DOCUMENTATION:
  - Updated README.md with documentation links (COVERAGE.md, DESIGN.md, MANUAL.md)
  - Updated code examples to demonstrate RTL wrapping approach
  - Added DelphiAST attribution
  - Complete language coverage tracking (COVERAGE.md)
  - Comprehensive design document (DESIGN.md)
  ARCHITECTURE:
  The core architectural principle is RTL wrapping: all Delphi constructs are
  wrapped in C++ runtime library functions. This makes the code generator a
  simple syntax translator while ensuring correct Delphi semantics. The
  transpilation pipeline is: Pascal → C++ (via RTL) → Native Code (via Zig/LLVM).
  Version: 0.2.0


### Fixed
- **Repo Update** (2025-10-11 – jarroddavis68)
  - Fixed links in README and on website


## [0.1.0] - 2025-10-07

### Added
- **Create FUNDING.yml** (2025-07-27 – Jarrod Davis)


### Changed
- **Repo Update** (2025-10-07 – jarroddavis68)
  - Initial commit

- **Repo Update** (2025-10-07 – jarroddavis68)
  - update documentation

- **Repo Update** (2025-10-05 – jarroddavis68)
  - website update

- **Update LICENSE** (2025-10-05 – jarroddavis68)

- **Repo Update** (2025-10-05 – jarroddavis68)
  - Setting up repo

- **Update README.md** (2025-10-05 – Jarrod Davis)

- **Initial commit** (2025-07-27 – Jarrod Davis)

