# NitroPascal Compiler - TODO

**Last Updated:** 2025-10-05  
**GOAL:** Compile Hello World, Calculator, and FizzBuzz by END OF TODAY

---

## COMPLETED ✅
- [x] Type aliases
- [x] Enums (simple and with values)
- [x] Function/procedure declarations
- [x] Function/procedure implementations
- [x] Parameter lists
- [x] Local variables
- [x] Assignment statements (X := Y, Result := expr)
- [x] Exit statements
- [x] Binary operators: +, -, *, /
- [x] Identifiers
- [x] Literals (numeric, string)

---

## CRITICAL - MUST FINISH TODAY 🔥

### Operators (NEEDED FOR: FizzBuzz conditionals)
- [x] Comparison: = (equals)
- [x] Comparison: <> (not equals)
- [x] Comparison: < (less than)
- [x] Comparison: > (greater than)
- [x] Comparison: <= (less or equal)
- [x] Comparison: >= (greater or equal)
- [x] Logical: and
- [x] Logical: or
- [x] Logical: not
- [x] Arithmetic: mod (modulo - NEEDED FOR FIZZBUZZ)
- [x] Arithmetic: div (integer division)

### Control Flow (NEEDED FOR: All programs)
- [x] If statement (simple if/then)
- [x] If/Else statement
- [x] Nested if (else if)
- [x] For..to loops
- [x] For..downto loops
- [x] While loops
- [x] Repeat..until loops

### Function Calls (NEEDED FOR: WriteLn in all programs)
- [x] Function call syntax (identifier with parentheses)
- [x] Function call with arguments
- [x] Function call without arguments
- [x] WriteLn() - no args
- [x] WriteLn(single arg)
- [x] WriteLn(multiple args)
- [x] Inc(var)
- [x] Inc(var, value)
- [x] Dec(var)
- [x] Dec(var, value)

### Program Structure (NEEDED FOR: Standalone programs)
- [x] Program declaration (program ProgramName;)
- [x] Program begin..end block
- [x] Program-level variables

### Library Structure (DLL/Shared Library support) ✅ COMPLETE
- [x] Library declaration (library LibName;)
- [x] Exports section parsing
- [x] Selective exports (extern "C" EXPORT vs static)
- [x] Cross-platform export macros (Windows/Linux)
- [x] DLL entry point generation
- [ ] Library initialization/finalization (Optional - Future)

---

## PHASE 2 - After Core Works (Optional for today)

### Records
- [ ] Record type declarations
- [ ] Record field access (Rec.Field)
- [ ] Nested records

### Arrays
- [ ] Static arrays (array[0..9] of T)
- [ ] Array indexing (Arr[i])
- [ ] Dynamic arrays (array of T)
- [ ] SetLength
- [ ] Length function

### Classes
- [ ] Class declarations
- [ ] Fields (private/public)
- [ ] Methods
- [ ] Constructors
- [ ] Destructors
- [ ] Properties

### Advanced
- [ ] Case/Of statements
- [ ] String concatenation (+)
- [ ] String functions (Copy, Pos, Length)
- [ ] Try/Finally/Except
- [ ] Const section
- [ ] Pointer types

---

## MILESTONE PROGRAMS

### 1. Hello World (MINIMUM VIABLE)
```pascal
program HelloWorld;
begin
  WriteLn('Hello, World!');
end.
```
**REQUIRES:** Program structure, WriteLn

### 2. Calculator (SIMPLE LOGIC)
```pascal
program Calculator;
var
  LA, LB, LResult: Integer;
begin
  LA := 10;
  LB := 5;
  LResult := LA + LB;
  WriteLn('Result: ', LResult);
end.
```
**REQUIRES:** Program structure, variables, assignment, operators, WriteLn

### 3. FizzBuzz (FULL TEST)
```pascal
program FizzBuzz;
var
  LI: Integer;
begin
  for LI := 1 to 20 do
  begin
    if (LI mod 15) = 0 then
      WriteLn('FizzBuzz')
    else if (LI mod 3) = 0 then
      WriteLn('Fizz')
    else if (LI mod 5) = 0 then
      WriteLn('Buzz')
    else
      WriteLn(LI);
  end;
end.
```
**REQUIRES:** Program structure, variables, for loops, if/else, mod operator, comparisons, WriteLn

---

## TODAY'S EXECUTION PLAN

**PHASE 1: Operators (1-2 hours)**
1. Add comparison operators to BuildExpression
2. Add logical operators to BuildExpression
3. Add mod and div operators
4. Test with simple expressions

**PHASE 2: Control Flow (2-3 hours)**
5. Implement If/Then/Else (WalkIfStatement)
6. Implement For loops (WalkForStatement)
7. Implement While loops (WalkWhileStatement)
8. Implement Repeat/Until (WalkRepeatStatement)
9. Test control flow

**PHASE 3: Function Calls (2-3 hours)**
10. Implement function call syntax
11. Implement WriteLn (map to printf or cout)
12. Implement Inc/Dec
13. Test function calls

**PHASE 4: Program Structure (1 hour)**
14. Handle program declarations
15. Handle program-level vars
16. Handle program begin..end

**PHASE 5: Integration Testing (1-2 hours)**
17. Test Hello World - compile and run
18. Test Calculator - compile and run
19. Test FizzBuzz - compile and run
20. Fix any bugs

**TOTAL ESTIMATED TIME: 7-11 hours**

---

## CURRENT STATUS
**Items Complete:** 47/54 core items (87%)  
**Critical Path Items Remaining:** 0 ✅ ALL CRITICAL FEATURES COMPLETE!  
**Time Remaining Today:** ~4-5 hours  
**Status:** 🎆 READY FOR PRODUCTION TESTING  

**LATEST COMPLETION (2025-10-05):**
✅ **Library (DLL) Support** - Fully implemented and tested
  - Library keyword detection
  - Exports section parsing (selective export)
  - Cross-platform export macros (Windows __declspec, Linux __attribute__)
  - Internal vs exported function differentiation
  - All 4 unit tests passing (UTest.Libraries.pas)
  - Generated code quality: Production-ready

**NEXT IMMEDIATE TASKS:**
1. Integration testing with Hello World (30 min)
2. Integration testing with Calculator (30 min)
3. Integration testing with FizzBuzz (1 hour)
4. Fix any bugs discovered (variable)
5. Real-world library testing (optional)

---

## PHASE 3 - FUTURE ENHANCEMENTS

### C Header to Delphi Unit Conversion (libclang)
**Architecture:** Implement as `TNPCHeaderConverter` class, expose via NitroPascal CLI command

**Class Design (TNPCHeaderConverter):**
- [ ] libclang integration layer
- [ ] C header parsing engine
- [ ] Type mapping system (C types → Delphi types)
  - [ ] Basic types (int→Integer, float→Single, char*→PAnsiChar, etc.)
  - [ ] Pointer types (T* → ^T or Pointer)
  - [ ] Array types
  - [ ] Function pointer types → Delphi procedural types
- [ ] Struct converter → Delphi records (with packing/alignment)
- [ ] Enum converter → Delphi enumerations
- [ ] Function declaration converter (calling conventions, external declarations)
- [ ] Macro processor (#define constants → const section)
- [ ] Typedef resolver
- [ ] Delphi unit file generator

**CLI Integration:**
- [ ] Add new command: `nitro convert-header <input.h> [options]`
- [ ] Options:
  - [ ] `--output <file>` - Output Delphi unit filename
  - [ ] `--library <name>` - Target library name for external declarations
  - [ ] `--convention <cdecl|stdcall>` - Default calling convention
  - [ ] `--unit-name <name>` - Override generated unit name

**Deployment & Implementation:**

**libclang Distribution Requirements:**
- **DLL:** Include `libclang.dll` in `bin\res\libclang\`
- **Builtin Headers (REQUIRED):** libclang needs Clang's compiler builtin headers to parse even basic C code
  - Location: `bin\res\libclang\lib\clang\<version>\include\`
  - Required files: `stddef.h`, `stdarg.h`, `stdint.h`, `stdatomic.h`, `float.h`, `limits.h`, etc.
  - These are compiler-provided headers separate from system libc headers
  - libclang looks for them relative to the DLL at: `<dll_dir>/../lib/clang/<version>/include/`

**Header Source Options:**
1. Bundle the builtin headers from the LLVM/Clang distribution that libclang.dll comes from (recommended)
2. Extract compatible headers from Zig's distribution (if version-compatible)
3. Configure libclang to use custom resource directory via `-resource-dir` flag

**Implementation Notes:**
- When initializing libclang, it will automatically find headers if they're in the standard relative path
- Alternative: Use `clang_parseTranslationUnit` with `-resource-dir` argument to specify custom location
- The Zig bundled Clang (used for `zig c++`) has its own headers, but they may not be in the structure libclang expects
- Safest approach: Bundle libclang.dll with its matching builtin headers from the same LLVM release

**Benefits:** Clean separation of libclang distribution, guaranteed version compatibility

**Use Case:** Automatically generate Delphi bindings for C libraries (SDL2, OpenGL, SQLite, etc.) from their header files.

**Note:** C headers only - C++ headers are out of scope.
