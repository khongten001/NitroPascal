# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- **Stop tracking .pdf files** (2025-10-19 – jarroddavis68)


### Removed
- **Release v0.4.0: Real-World Usage** (2025-10-19 – jarroddavis68)
  NitroPascal v0.4.0 delivers the features that matter for building real
  applications in production: function pointers for callbacks, structured RTL
  modules (Types, SysUtils, StrUtils, DateUtils), static library linking
  (demonstrated with raylib), comprehensive benchmarking suite, and dramatically
  expanded runtime capabilities.
  KEY MILESTONE:
  NitroPascal now demonstrates REAL-WORLD VIABILITY. Static link raylib for game
  development. Compare performance against Delphi with included benchmarks.
  Structure your code with standard Pascal RTL modules. Build production software
  with a mature, organized runtime library.
  FUNCTION POINTERS (PROCEDURAL TYPES):
  - Procedural type declarations (type TCallback = procedure(X: Integer))
  - Function variable assignments
  - Callback patterns for event handling
  - Higher-order functions and functional programming
  - Framework integration hooks
  - Plugin architectures
  - Event-driven programming patterns
  STRUCTURED RTL MODULES:
  - System.Types - Base type declarations and utilities
  - System.SysUtils - System utilities and conversions
  - System.StrUtils - String manipulation utilities
  - System.DateUtils - Date/time functions (foundation)
  - Organized, discoverable API surface
  - Standard Pascal module structure
  - Clear separation of concerns
  - Professional codebase organization
  STATIC LIBRARY LINKING:
  - Link against static libraries (.lib/.a files)
  - Demonstrated with raylib game development library
  - Zero-overhead integration with C/C++ libraries
  - Single-executable deployment (no DLL dependencies)
  - Complete control over dependencies
  - Simplified distribution
  ENHANCED STRING LIBRARY:
  - StringOfChar(Ch, Count) - Create repeated character strings
  - UniqueString(S) - Ensure unique string reference
  - SetString(S, Buffer, Len) - Direct buffer to string
  - Val(S, V, Code) - String to numeric with error code
  - Str(X, S) - Numeric to string (legacy compatibility)
  - UpCase(Ch) - Single character uppercase
  - WideCharLen(S) - Wide string length
  - WideCharToString(S) - Convert wide to string
  - StringToWideChar(S, Buf, BufSize) - String to wide buffer
  - WideCharToStrVar(S, Dest) - Wide to string variable
  - Complete wide character support for Unicode
  EXPANDED MATH LIBRARY:
  - Logarithms: Ln(X), Log10(X), Log2(X), LogN(Base, X)
  - Exponential: Exp(X), Power(Base, Exponent)
  - Integer/fractional: Int(X), Frac(X)
  - Hyperbolic trig: Sinh(X), Cosh(X), Tanh(X)
  - Inverse hyperbolic: ArcSinh(X), ArcCosh(X), ArcTanh(X)
  - Mathematical constant: Pi
  - ArcTan2(Y, X) for proper angle calculations
  - Scientific computing capabilities
  - Complete mathematical toolkit
  ENHANCED FILE I/O:
  - Read(F, Var) - Read from text file to variable
  - Eoln(F) - Test for end of line in text file
  - SeekEof(F) - Skip whitespace, test for EOF
  - SeekEoln(F) - Skip whitespace, test for EOL
  - Flush(F) - Force write buffer to disk
  - Truncate(F) - Truncate file at current position
  - Erase(F) - Delete closed file
  - Rename(F, NewName) - Rename closed file
  - IOResult - Get last I/O error code
  - Complete Delphi file I/O compatibility
  ENHANCED MEMORY FUNCTIONS:
  - AllocMem(Size) - Allocate zero-filled memory
  - FillByte(Dest, Count, Value) - Fill byte array
  - FillWord(Dest, Count, Value) - Fill word array
  - FillDWord(Dest, Count, Value) - Fill dword array
  - Efficient bulk memory operations
  - Type-specific fill operations
  ENHANCED ORDINAL FUNCTIONS:
  - Odd(X) - Test if integer is odd
  - Swap(X) - Swap byte order (endianness)
  - Byte manipulation utilities
  PLATFORM SERVICES:
  - RunError(ErrorCode) - Terminate with error code
  - Abort - Terminate with exception
  - Enhanced program control
  CODE GENERATION IMPROVEMENTS:
  - Line number directives (#line) for debugging
  - Source position tracking in generated code
  - Better debuggability
  - Improved error messages with source locations
  COMPILER DIRECTIVES:
  - {$include_header 'filename'} - Include C/C++ headers directly
  - Seamless integration with native libraries
  - Direct access to platform APIs
  BENCHMARK SUITE:
  - Comprehensive performance comparison: NitroPascal vs Delphi
  - Real-world test scenarios
  - Quantifiable performance metrics
  - Optimization validation
  - Demonstrates competitive performance
  ENHANCED C++ RUNTIME:
  - Expanded standard library wrappers
  - More complete RTL implementation
  - Better Delphi compatibility
  - Optimized performance paths
  BUILD SYSTEM ENHANCEMENTS:
  - Static library linking support
  - Improved dependency management
  - Better library path resolution
  - Cross-platform static linking
  REAL-WORLD DEMONSTRATIONS:
  - Raylib integration example (static linking)
  - Game development capabilities
  - High-performance graphics
  - Professional library integration
  - Production-ready examples
  This release proves NitroPascal's real-world viability. With function pointers
  for callbacks, structured RTL modules for organization, static linking for
  deployment simplicity, and comprehensive benchmarks showing competitive
  performance, you can confidently build production applications.
  THE REAL-WORLD MILESTONE:
  NitroPascal isn't just production-ready - it's production-proven. Static link
  libraries like raylib. Write callbacks and event handlers with function
  pointers. Structure your code with standard Pascal modules. Compare performance
  directly against Delphi. Ship real applications with confidence.
  Write once in pure Delphi. Link static libraries. Ship single executables. Run
  everywhere.
  Version: 0.4.0


## [0.3.0] - 2025-10-15

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


### Fixed
- **Repo Update** (2025-10-11 – jarroddavis68)
  - Fixed links in README and on website


### Removed
- **Release v0.3.0: Production-Ready Milestone** (2025-10-14 – jarroddavis68)
  This release brings NitroPascal from proof-of-concept to production-ready with
  comprehensive string handling, file I/O, exception handling, dynamic data
  structures, external library integration, and conditional compilation -
  everything you need to build real, working applications.
  KEY MILESTONE:
  NitroPascal now has enough features to start doing REAL, PRODUCTIVE WORK. You
  can build actual applications that manipulate strings, read/write files, handle
  errors gracefully with exceptions, use dynamic arrays and sets, call external
  libraries, and target different platforms with conditional compilation.
  EXCEPTION HANDLING:
  - try..except blocks for error recovery
  - try..finally blocks for resource cleanup
  - try..except..finally for comprehensive error handling
  - raise statement for throwing exceptions
  - on E: Exception do for typed exception catching
  - Proper exception propagation and stack unwinding
  - Resource safety with deterministic cleanup
  DYNAMIC DATA STRUCTURES:
  - Dynamic arrays (array of T) with SetLength, Length, and High
  - Sets (set of T) with Include, Exclude, and membership testing (in)
  - Enhanced RTL with np::DynArray<T> and np::Set<T> implementations
  STRING MANIPULATION:
  - Complete string library: Copy, Pos, Delete, Insert
  - Case conversion: UpperCase, LowerCase
  - Whitespace handling: Trim, TrimLeft, TrimRight
  - Type conversion: IntToStr, StrToInt, StrToIntDef, FloatToStr, StrToFloat
  - Formatted output: Format function with variadic templates
  MATH LIBRARY:
  - Basic operations: Abs, Sqr, Sqrt
  - Trigonometry: Sin, Cos, Tan, ArcSin, ArcCos, ArcTan
  - Rounding: Round, Trunc, Ceil, Floor
  - Utility: Max, Min, Random, Randomize
  FILE I/O:
  - File management: Assign, Reset, Rewrite, Append, Close
  - Text I/O: Write(F), WriteLn(F), ReadLn
  - Binary I/O: BlockRead, BlockWrite
  - File positioning: Seek, FilePos, FileSize, Eof
  - File system: FileExists, DirectoryExists, CreateDir, GetCurrentDir
  - File operations: DeleteFile, RenameFile
  CONTROL FLOW ENHANCEMENTS:
  - Loop control: break, continue
  - Early return: exit, exit with return value
  - Simplified access: with statement
  - Forward declarations for functions and procedures
  ORDINAL FUNCTIONS:
  - Type inspection: Ord, Chr, Low, High, SizeOf
  - Iteration: Succ, Pred, Inc, Dec (with optional step)
  - Pointer utilities: Assigned
  MEMORY MANAGEMENT:
  - Advanced allocation: GetMem, FreeMem, ReallocMem
  - Memory operations: FillChar, Move
  - Block operations for efficient buffer manipulation
  EXTERNAL LIBRARY INTEGRATION:
  - External function declarations (external 'library.dll')
  - Multiple calling conventions: stdcall, cdecl, fastcall
  - Automatic string type conversion (PChar, PWideChar, PAnsiChar)
  - External library tracking for automatic linking
  - Seamless C/C++ interoperability
  CONDITIONAL COMPILATION:
  - Platform detection: WIN32, WIN64, LINUX, MACOS, MSWINDOWS, POSIX
  - Architecture detection: CPUX64, CPU386, CPUARM64
  - Build mode detection: DEBUG, RELEASE
  - Application type: CONSOLE_APP, GUI_APP
  - Preprocessor directives: {$ifdef}, {$else}, {$endif}
  - Custom application type: {$apptype console|gui}
  PLATFORM SERVICES:
  - Command-line arguments: ParamCount, ParamStr
  - Program termination: Halt
  RUNTIME LIBRARY ENHANCEMENTS:
  - Enhanced np::String with comprehensive string manipulation
  - New np::DynArray<T> for dynamic array support
  - New np::Set<T> for set operations
  - File I/O wrappers maintaining Delphi semantics
  - Console input: ReadLn
  CODE GENERATION IMPROVEMENTS:
  - External function handling (no C++ declaration generation)
  - Automatic library dependency tracking
  - Calling convention mapping
  - String type conversions for external calls
  - Forward declaration support
  BUILD SYSTEM ENHANCEMENTS:
  - Automatic define injection based on target platform
  - Automatic define injection based on build mode
  - Architecture-specific defines
  - Application type defines
  - Windows subsystem control (console vs GUI)
  TESTING INFRASTRUCTURE:
  - Integrated test runner for validation
  - Comprehensive test suite covering all features
  This release represents a major leap forward in capability. With exception
  handling, string manipulation, file I/O, dynamic data structures, external
  library support, and conditional compilation, you can now build robust, real
  applications in NitroPascal.
  THE PRODUCTIVITY MILESTONE:
  NitroPascal is no longer just a compiler experiment - it's a tool you can use
  to build actual, working software. Parse files, manipulate data, handle errors
  gracefully, integrate with existing libraries, target multiple platforms, and
  ship real applications with confidence.
  Write once in pure Delphi. Compile to native C++. Run everywhere.
  Version: 0.3.0

