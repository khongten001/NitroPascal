# Known Errors and Limitations

This document tracks known errors, crashes, and limitations in NitroPascal and its dependencies.

---

## DelphiAST Crashes

### String Literal with Escaped Quotes Causes Assertion Failure

**Status:** Known Issue  
**Component:** DelphiAST  
**Severity:** High - Causes compiler crash

**Description:**  
Using escaped single quotes (`''`) inside string literals causes DelphiAST to fail with an assertion error during parsing.

**Error Message:**
```
Assertion failure (C:\Dev\Delphi\Projects\NitroPascal\repo\src\Deps\DelphiAST\DelphiAST.Classes.pas, line 285)
```

**Problematic Code Example:**
```pascal
program test01;
begin
  WriteLn('Hello world, welcome to NitroPascal!');  // This crashes DelphiAST
end.
```

**Why It Happens:**  
DelphiAST's parser encounters an assertion failure when processing the escaped quote sequence `''` within a string literal. The error occurs during the AST construction phase, before JSON generation.

**Workaround:**  
Currently none. Avoid using escaped quotes in string literals until DelphiAST is fixed or replaced.

**Notes:**
- This error occurs during Pascal → JSON phase (DelphiAST parsing)
- Semantic checks cannot catch this since the crash happens before JSON is generated
- This is a DelphiAST limitation, not a NitroPascal issue

**Date Reported:** 2025-10-17

---

## Function Result Variable with SetLength and Direct Indexing

### SetLength Followed by Direct Character Assignment May Fail

**Status:** Known Issue - Workaround Available  
**Component:** Code Generation / Runtime  
**Severity:** Medium - Requires code pattern changes

**Description:**  
Using `SetLength` on a function's `Result` variable followed by direct character indexing (e.g., `Result[index] := value`) may cause runtime crashes with "String index out of range" errors.

**Error Message:**
```
libc++abi: terminating due to uncaught exception of type std::out_of_range: String index out of range
```

**Problematic Code Example:**
```pascal
function ReverseString(const AText: String): String;
var
  LIndex: Integer;
  LLength: Integer;
begin
  LLength := Length(AText);
  SetLength(Result, LLength);  // Allocate space
  for LIndex := 1 to LLength do
  begin
    Result[LIndex] := AText[LLength - LIndex + 1];  // Direct indexing - May crash
  end;
end;
```

**Why It Happens:**  
The exact cause is still under investigation. The issue appears to be related to how the transpiler initializes Pascal's implicit `Result` variable in the generated C++ code. When `SetLength` is called on `Result`, followed by direct character assignment using the `[]` operator, the runtime may not properly handle the operation.

**Workaround:**  
Use string concatenation or other string operations instead of `SetLength` + direct indexing:

```pascal
function ReverseString(const AText: String): String;
var
  LIndex: Integer;
  LLength: Integer;
  LTemp: String;
begin
  LLength := Length(AText);
  LTemp := '';
  for LIndex := LLength downto 1 do
  begin
    LTemp := LTemp + Copy(AText, LIndex, 1);  // Use concatenation instead
  end;
  Result := LTemp;
end;
```

**Best Practices:**
- Avoid using `SetLength(Result, N)` followed by `Result[index] := value` in functions
- Use string concatenation (`+` operator) or string manipulation functions (`Copy`, `Insert`, etc.)
- When performance is critical, consider using alternative approaches that don't rely on direct indexing of the Result variable

**Notes:**
- The issue specifically affects function `Result` variables, not regular string variables
- Local string variables with `SetLength` may work correctly
- Further investigation needed to determine if this is a transpiler initialization issue or runtime issue

**Date Reported:** 2025-10-19

---

## Future Sections

Additional error categories to document:
- CodeGen Limitations
- Runtime Errors
- Zig Build Issues
- Platform-Specific Problems
