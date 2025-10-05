# NitroPascal - Delphi to C++ Compiler Design

## Overview

NitroPascal is a modern compiler that converts Delphi/Object Pascal source code to C++, leveraging DelphiAST for parsing and Zig for building. It provides a streamlined CLI workflow for modernizing legacy Delphi codebases.

## Core Mission

**Convert Delphi codebases to modern C++**, enabling:
- Modernization of legacy Delphi projects (20+ years old)
- Cross-platform compilation via Zig build system
- Removal of dependency on Delphi IDE and RTL/VCL
- Preservation of business logic while targeting modern platforms

## High-Level Architecture

```
User Delphi Code (.pas files)
    ↓
[Scanner] → Discovers units and dependencies
    ↓
[Dependency Graph] → Determines build order
    ↓
DelphiAST → Parses to TSyntaxNode tree
    ↓
[Walker] → Traverses AST nodes
    ↓
[Emitter] → Generates C++ code (.h/.cpp)
    ↓
[ProjectManager] → Writes files and build.zig
    ↓
Zig Build System → Compiles to native executable
```

## Key Design Principles

1. **Use Proven Parser** - Leverage DelphiAST (tested, mature) instead of writing our own
2. **Direct C++ Generation** - Walk DelphiAST nodes directly, emit C++ immediately (no intermediate AST)
3. **Dependency-Aware** - Respect unit dependencies, build in topological order
4. **CLI-Driven** - Simple command interface (init, build, run, clean)
5. **Zig-Powered** - Use Zig as the build system and C++ compiler

## Components

All units follow the `NitroPascal.XXX.pas` naming convention:

```
src/
├─ deps/DelphiAST/                      (Third-party: Roman Yankovsky's parser)
│
├─ NitroPascal.Types.pas                (Common types, records, enums)
├─ NitroPascal.Utils.pas                (Utilities: console, file I/O, process execution)
├─ NitroPascal.ProjectManager.pas       (Project structure, build.zig generation)
├─ NitroPascal.Scanner.pas              (Find .pas files, extract uses clauses)
├─ NitroPascal.Dependency.pas           (Build dependency graph, topological sort)
├─ NitroPascal.TypeMapper.pas           (Delphi → C++ type mappings)
├─ NitroPascal.Emitter.pas              (C++ code generation infrastructure)
├─ NitroPascal.Walker.pas               (Walk DelphiAST nodes, orchestrate code gen)
├─ NitroPascal.Compiler.pas             (Main orchestrator, build pipeline)
│
└─ nitro/
   ├─ UNitro.pas                        (CLI commands implementation)
   └─ nitro.dpr                         (Main program entry point)
```

### Component Descriptions

#### 1. NitroPascal.Types.pas
**Purpose:** Shared types and data structures

```delphi
// Discovered unit metadata
TUnitInfo = class
  ModuleName: string;
  FilePath: string;
  InterfaceUses: TStringList;      // Public dependencies
  ImplementationUses: TStringList; // Private dependencies
end;

// Compiler settings
TNPCompilerSettings = record
  ZigPath: string;           // Path to Zig compiler
  BuildMode: TNPBuildMode;   // Debug/Release/ReleaseFast
  TargetTriple: string;      // e.g., 'x86_64-windows'
  OutputDir: string;
end;
```

#### 2. NitroPascal.Utils.pas
**Purpose:** Utility functions for console, file I/O, and process execution

- Console utilities (colored output, progress indicators)
- File/directory operations
- Process execution with output capture
- **Version info extraction** (from executable resources)

#### 3. NitroPascal.ProjectManager.pas
**Purpose:** Manage project structure and build configuration

**Directory Structure:**
```
<project>/
  ├── build.zig           - Generated build configuration
  ├── source/             - User's Delphi .pas files
  ├── generated/
  │   ├── include/        - Generated .h files
  │   └── src/            - Generated .cpp files
  └── zig-out/
      └── bin/            - Compiled executable
```

**Key Responsibilities:**
- Create/maintain directory structure
- Generate build.zig from compiler settings
- Clean generated files
- Track output paths

#### 4. NitroPascal.Scanner.pas
**Purpose:** Discover .pas files and extract dependencies

**Process:**
1. Recursively scan source directory for .pas files
2. Parse each file with DelphiAST (lightweight parse for uses clauses)
3. Extract unit name from AST
4. Extract interface uses clause (public dependencies)
5. Extract implementation uses clause (private dependencies)
6. Build TUnitInfo catalog

**API:**
```delphi
procedure ScanDirectory(const ADirectory: string);
function GetUnit(const AModuleName: string): TUnitInfo;
function GetAllUnits(): TArray<TUnitInfo>;
```

#### 5. NitroPascal.Dependency.pas
**Purpose:** Build dependency graph and determine compilation order

**Responsibilities:**
- Create directed graph from unit dependencies
- Detect circular dependencies (and report errors)
- Perform topological sort for build order
- Ensure units are compiled before their dependents

**Algorithm:** Depth-first search for topological ordering

**API:**
```delphi
procedure BuildGraph(const AUnits: TArray<TUnitInfo>);
function GetTopologicalSort(): TArray<string>;
function GetNodeCount(): Integer;
```

#### 6. NitroPascal.TypeMapper.pas
**Purpose:** Map Delphi types to C++ equivalents

**Type Mappings:**
```
Delphi          → C++
Integer         → int32_t
Cardinal        → uint32_t
Int64           → int64_t
UInt64          → uint64_t
Single          → float
Double          → double
Boolean         → bool
Char            → char
String          → std::string
Pointer         → void*
PChar           → char*
array[0..N]     → std::array<T, N+1>
array of T      → std::vector<T>
record          → struct
class           → class
```

**API:**
```delphi
function MapType(const ADelphiType: string): string;
function IsBuiltInType(const ATypeName: string): Boolean;
```

#### 7. NitroPascal.Emitter.pas
**Purpose:** C++ code generation infrastructure

**Features:**
- Separate TStringBuilder for .h and .cpp files
- Automatic indentation management (4 spaces)
- Include management (#pragma once, header includes)
- Format string support for code generation

**API:**
```delphi
procedure Initialize(const AModuleName: string);
procedure EmitH(const AText: string);      // Write to header
procedure EmitCpp(const AText: string);    // Write to source
procedure IncIndent() / DecIndent();
procedure AddInclude(const AHeaderFile: string);
procedure SaveFiles(const AHeaderPath, ASourcePath: string);
```

**Generated Format:**
```cpp
// MyUnit.h
#pragma once
#include <cstdint>
#include "OtherUnit.h"

// ... declarations ...

// MyUnit.cpp
#include "MyUnit.h"

// ... implementations ...
```

#### 8. NitroPascal.Walker.pas
**Purpose:** Walk DelphiAST nodes and orchestrate C++ generation

**Responsibilities:**
- Traverse TSyntaxNode tree from DelphiAST
- Dispatch to appropriate handler for each node type
- Coordinate with Emitter for code output
- Handle scope and context tracking

**Key Methods:**
```delphi
procedure WalkUnit(const ANode: TSyntaxNode; const AUnitInfo: TNPUnitInfo);
procedure WalkInterface(const ANode: TSyntaxNode);
procedure WalkImplementation(const ANode: TSyntaxNode);
procedure WalkUses(const ANode: TSyntaxNode; const AIsInterface: Boolean);
procedure WalkTypeDeclarations(const ANode: TSyntaxNode);
procedure WalkTypeDecl(const ANode: TSyntaxNode);
procedure WalkEnumType(const ANode: TSyntaxNode; const ATypeName: string);
procedure WalkFunctionDeclaration(const ANode: TSyntaxNode);
procedure WalkFunctionImplementation(const ANode: TSyntaxNode);
procedure WalkStatement(const ANode: TSyntaxNode);
procedure WalkExpression(const ANode: TSyntaxNode);
```

#### 9. NitroPascal.Compiler.pas
**Purpose:** Main orchestrator, build pipeline

**Build Pipeline:**
```delphi
procedure Build():
  1. Validate project exists
  2. Scan source directory (Scanner)
  3. Build dependency graph (DependencyGraph)
  4. Get topological sort (build order)
  5. For each unit in order:
     a. Parse with DelphiAST → TSyntaxNode
     b. Walk AST with Walker
     c. Generate C++ with Emitter
     d. Save .h and .cpp files
  6. Generate build.zig
  7. Execute Zig build
  8. Report success/failure
```

**Other Commands:**
- `Initialize()` - Create project structure
- `Run()` - Execute compiled program
- `Clean()` - Remove generated files

#### 10. CLI Tool (nitro/)
**Purpose:** Command-line interface

**Commands:**
```bash
nitro init <projectname>   → Create project structure
nitro build                → Run build pipeline
nitro run                  → Execute compiled program
nitro clean                → Clean generated files
nitro version              → Show version (from exe resources)
nitro help                 → Show help
```

## Compilation Process

### Phase 1: Initialization (nitro init)

```
User runs: nitro init MyProject

1. Create directory structure:
   MyProject/
     ├── source/          (Place .pas files here)
     ├── generated/
     │   ├── include/
     │   └── src/
     └── zig-out/bin/

2. Create initial (empty) build.zig

3. Display instructions
```

### Phase 2: Scanning & Analysis (nitro build - Part 1)

```
1. Scanner.ScanDirectory("MyProject/source/")
   - Find all .pas files
   - Parse each with DelphiAST (lightweight)
   - Extract uses clauses
   - Build TUnitInfo catalog

2. DependencyGraph.BuildGraph(units)
   - Create edges from uses clauses
   - Detect cycles (error if found)
   - Topological sort → build order
```

### Phase 3: Code Generation (nitro build - Part 2)

```
For each unit in build order:
  1. Parse: DelphiAST.Run(unit.pas) → TSyntaxNode tree
  
  2. Walk: Walker.WalkUnit(tree, unitInfo)
     - WalkInterface() → emit class/function declarations
     - WalkImplementation() → emit method bodies
     - Emitter generates C++ code
  
  3. Save: Emitter.SaveFiles()
     - generated/include/MyUnit.h
     - generated/src/MyUnit.cpp
```

### Phase 4: Build & Link (nitro build - Part 3)

```
1. ProjectManager.GenerateBuildZig()
   - Lists all .cpp files
   - Sets compilation flags
   - Links C++ standard library

2. Execute: zig build
   - Compiles all .cpp files
   - Links into executable

3. Output: zig-out/bin/MyProject.exe
```

### Phase 5: Execution (nitro run)

```
Execute: zig-out/bin/MyProject.exe
```

## Delphi → C++ Translation

### Units → Modules

**Delphi:**
```delphi
unit MyUnit;

interface
uses OtherUnit;
type
  TMyClass = class
    function DoIt(const AValue: Integer): Integer;
  end;

implementation
function TMyClass.DoIt(const AValue: Integer): Integer;
begin
  Result := AValue * 2;
end;
end.
```

**C++:**
```cpp
// MyUnit.h
#pragma once
#include <cstdint>
#include "OtherUnit.h"

class TMyClass {
public:
    int32_t DoIt(int32_t AValue);
};

// MyUnit.cpp
#include "MyUnit.h"

int32_t TMyClass::DoIt(int32_t AValue) {
    return AValue * 2;
}
```

### Uses Clauses → Includes

**Interface uses** → Header includes (public):
```delphi
interface
uses UnitA, UnitB;
```
```cpp
#include "UnitA.h"
#include "UnitB.h"
```

**Implementation uses** → Source includes (private):
```delphi
implementation
uses UnitC, UnitD;
```
```cpp
// In .cpp file only
#include "UnitC.h"
#include "UnitD.h"
```

### Types → Structs/Classes

**Records:**
```delphi
type
  TPoint = record
    X, Y: Integer;
  end;
```
```cpp
struct TPoint {
    int32_t X;
    int32_t Y;
};
```

**Enums:**
```delphi
type
  TColor = (Red, Green, Blue);
```
```cpp
enum class TColor {
    Red,
    Green,
    Blue
};
```

**Classes:**
```delphi
type
  TMyClass = class
  private
    FValue: Integer;
  public
    constructor Create();
    destructor Destroy(); override;
    property Value: Integer read FValue write FValue;
  end;
```
```cpp
class TMyClass {
private:
    int32_t FValue;
public:
    TMyClass();
    virtual ~TMyClass();
    
    int32_t GetValue() const { return FValue; }
    void SetValue(int32_t AValue) { FValue = AValue; }
};
```

### Statements → C++ Equivalents

| Delphi | C++ |
|--------|-----|
| `begin..end` | `{ }` |
| `if..then..else` | `if () { } else { }` |
| `while..do` | `while () { }` |
| `for I := A to B do` | `for (int32_t I = A; I <= B; ++I) { }` |
| `for I := A downto B do` | `for (int32_t I = A; I >= B; --I) { }` |
| `case..of..else..end` | `switch () { case: ... default: }` |
| `repeat..until` | `do { } while (!(condition));` |
| `X := Y` | `X = Y` |
| `Result := X` | `return X` |

### Expressions

| Delphi | C++ |
|--------|-----|
| `A + B` | `A + B` |
| `A = B` | `A == B` |
| `A <> B` | `A != B` |
| `not Flag` | `!Flag` |
| `A and B` | `A && B` |
| `A or B` | `A \|\| B` |

---

**Last Updated:** 2025-10-04  
**Document Purpose:** Architecture and design goals
