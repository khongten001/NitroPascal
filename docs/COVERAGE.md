# NitroPascal Language Coverage

This document tracks all language features planned for NitroPascal. Each feature is marked as implemented [x] or planned [ ]. This serves as the master TODO list for the project.

**INSTRUCTIONS FOR UPDATES:**
- ONLY add ticks [x] to mark features as implemented
- Find the appropriate section for the feature and tick it there
- If no appropriate section exists, create a new section with the proper feature list and tick items there
- DO NOT add any other text, commentary, or explanations
- Keep all content as tick lists only

## Basic Types
- [x] Integer → int32_t
- [x] Int64 → int64_t
- [x] Cardinal → uint32_t
- [x] Byte → uint8_t
- [x] Word → uint16_t
- [x] Boolean → bool
- [x] Double → double
- [x] Single → float
- [x] Char → char16_t (UTF-16)
- [x] String → np::String (UTF-16)
- [x] Pointer → T*
- [x] Untyped Pointer → void*
- [ ] ShortInt → int8_t
- [ ] SmallInt → int16_t
- [ ] LongInt → int32_t
- [ ] LongWord → uint32_t
- [ ] UInt64 → uint64_t
- [ ] Extended → long double
- [ ] Currency → custom type
- [ ] Real → double
- [ ] Real48 → custom type
- [ ] AnsiString → std::string
- [ ] WideString → std::wstring
- [ ] UnicodeString → std::u16string
- [ ] AnsiChar → char
- [ ] WideChar → wchar_t

## Type System
- [x] Type aliases (type T = OtherType)
- [x] Pointer type declarations (^T)
- [x] Pointer type aliases
- [ ] Subrange types (type TDigit = 0..9)
- [ ] Type casting (Integer(x))
- [ ] Type conversion operators
- [ ] Type compatibility checking
- [ ] Ordinal types
- [ ] Type identity vs assignment compatibility

## Constants
- [x] Const declarations
- [x] Typed constants
- [x] Integer constants
- [x] Float constants
- [x] String constants
- [x] Boolean constants
- [ ] Enumeration constants
- [ ] Set constants
- [ ] Array constants
- [ ] Record constants
- [ ] Pointer constants (nil)
- [ ] Constant expressions
- [ ] Resource string constants

## Variables
- [x] Variable declarations (var)
- [x] Local variables
- [x] Global variables
- [x] Multiple variables same type
- [ ] Variable initialization
- [ ] Thread-local variables (threadvar)
- [ ] Absolute variables (var X: Integer absolute Y)
- [ ] External variables (external)

## Operators - Arithmetic
- [x] Addition (+)
- [x] Subtraction (-)
- [x] Multiplication (*)
- [x] Float division (/)
- [x] Integer division (div)
- [x] Modulo (mod)
- [ ] Unary plus (+X)
- [ ] Unary minus (-X)

## Operators - Comparison
- [x] Equal (=)
- [x] Not equal (<>)
- [x] Less than (<)
- [x] Greater than (>)
- [x] Less than or equal (<=)
- [x] Greater than or equal (>=)

## Operators - Logical
- [x] Logical AND (and)
- [x] Logical OR (or)
- [x] Logical XOR (xor)
- [x] Logical NOT (not)

## Operators - Bitwise
- [x] Bitwise AND (and)
- [x] Bitwise OR (or)
- [x] Bitwise XOR (xor)
- [x] Bitwise NOT (not)
- [x] Shift left (shl)
- [x] Shift right (shr)

## Operators - Assignment
- [x] Simple assignment (:=)
- [ ] Addition assignment (+=)
- [ ] Subtraction assignment (-=)
- [ ] Multiplication assignment (*=)
- [ ] Division assignment (/=)

## Operators - Other
- [x] String concatenation (+)
- [x] Pointer dereferencing (^)
- [x] Address-of operator (@)
- [x] Set membership (in)
- [ ] Range operator (..)
- [ ] Type cast operator (as)
- [ ] Type check operator (is)

## Control Flow - Conditional
- [x] if..then
- [x] if..then..else
- [x] Nested if statements
- [x] case..of..end (integer)
- [x] case..of..end (enumeration)
- [ ] case..of..end (string)
- [ ] case..of..end (ranges)
- [ ] case with multiple values per branch

## Control Flow - Loops
- [x] for..to..do
- [x] for..downto..do
- [x] while..do
- [x] repeat..until
- [ ] for..in..do (arrays)
- [ ] for..in..do (collections)
- [x] break
- [x] continue
- [x] exit
- [x] exit with return value

## Control Flow - Structured
- [x] with statement
- [x] try..except
- [x] try..finally
- [x] try..except..finally
- [x] raise statement
- [x] on E: Exception do
- [ ] else in except blocks

## Functions & Procedures
- [x] Function declarations
- [x] Procedure declarations
- [x] Function return values (Result)
- [x] Parameter passing - by value
- [x] Parameter passing - const
- [x] Parameter passing - var
- [x] Parameter passing - out
- [x] Local variables
- [x] External declarations (external 'library.dll')
- [ ] Default parameter values
- [ ] Named parameters
- [ ] Parameter arrays (array of const)
- [ ] Open array parameters
- [ ] Function overloading
- [x] Forward declarations
- [ ] Inline functions
- [ ] Nested functions
- [ ] Anonymous functions
- [x] Function pointers (procedural types)
- [ ] Function return in parameter (out)

## Arrays - Static
- [x] Static array declarations
- [x] Array indexing
- [x] Multi-dimensional arrays
- [x] Array bounds checking
- [ ] Array initialization
- [ ] Array of const
- [ ] Zero-based arrays ([0..N])
- [ ] Custom-based arrays ([Low..High])
- [ ] Array assignment
- [ ] Array comparison
- [ ] Array slicing

## Arrays - Dynamic
- [x] Dynamic array declarations (array of T)
- [x] SetLength for dynamic arrays
- [x] Length for dynamic arrays
- [x] Copy for dynamic arrays
- [ ] Dynamic array assignment
- [ ] Dynamic array initialization
- [ ] Multi-dimensional dynamic arrays
- [ ] Array concatenation
- [ ] Low function for dynamic arrays
- [x] High function for dynamic arrays

## Arrays - Built-in Functions
- [x] Length(array)
- [x] Low(array)
- [x] High(array)
- [x] SetLength(array, length)
- [x] Copy(array, start, count)

## Records
- [x] Record type declarations
- [x] Record field access
- [x] Nested records
- [x] Pointer-to-record types
- [ ] Record initialization
- [ ] Record assignment
- [ ] Record comparison
- [ ] Packed records
- [ ] Aligned records
- [ ] Variant records
- [ ] Records with methods
- [ ] Record constructors
- [ ] Record operators
- [ ] Record helpers
- [ ] Record case statements
- [ ] Record class operators

## Enumerations
- [x] Enum type declarations
- [x] Enum values
- [x] Enum in case statements
- [ ] Enum with explicit values
- [ ] Enum subranges
- [ ] Scoped enumerations
- [ ] Ord function for enums
- [ ] Succ function for enums
- [ ] Pred function for enums

## Sets
- [x] Set type declarations (set of)
- [ ] Set literals
- [ ] Set operations (union +)
- [ ] Set operations (difference -)
- [ ] Set operations (intersection *)
- [ ] Set operations (symmetric difference ><)
- [x] Set membership (in)
- [ ] Set comparison (=, <>)
- [ ] Set subset (<=)
- [ ] Set superset (>=)
- [x] Include procedure
- [x] Exclude procedure

## Pointers
- [x] Pointer type declarations (^T)
- [x] New procedure
- [x] Dispose procedure
- [x] Pointer dereferencing (P^)
- [x] Address-of operator (@)
- [x] nil constant → nullptr
- [x] Typed pointers
- [ ] Pointer arithmetic
- [ ] PChar type
- [ ] Pointer comparison
- [x] GetMem function
- [x] FreeMem procedure
- [x] ReallocMem function
- [x] AllocMem function

## Classes
- [ ] Class declarations
- [ ] Class fields (private, public, protected)
- [ ] Class methods
- [ ] Class properties
- [ ] Constructors (Create)
- [ ] Destructors (Destroy)
- [ ] Class inheritance
- [ ] Virtual methods
- [ ] Abstract methods
- [ ] Override directive
- [ ] Reintroduce directive
- [ ] Class methods (class function/procedure)
- [ ] Class properties
- [ ] Class variables
- [ ] Class constructors/destructors
- [ ] Self keyword
- [ ] Inherited keyword
- [ ] Class references (TClass)
- [ ] Class.ClassName
- [ ] Class.ClassType
- [ ] Object is TClass
- [ ] Object as TClass
- [ ] Class helpers
- [ ] Class operators

## Interfaces
- [ ] Interface declarations
- [ ] Interface implementation (implements)
- [ ] Interface inheritance
- [ ] Interface methods
- [ ] Interface properties
- [ ] GUID support
- [ ] IUnknown/IInterface
- [ ] Reference counting
- [ ] Supports operator
- [ ] Interface delegation
- [ ] Interface method resolution

## Properties
- [ ] Property declarations
- [ ] Property getters
- [ ] Property setters
- [ ] Array properties
- [ ] Indexed properties
- [ ] Default properties
- [ ] Read-only properties
- [ ] Write-only properties
- [ ] Class properties
- [ ] Property directives (stored, default)

## Generics
- [ ] Generic types (type T<T>)
- [ ] Generic constraints
- [ ] Generic methods
- [ ] Generic type parameters
- [ ] Multiple generic parameters
- [ ] Generic arrays
- [ ] Generic records
- [ ] Generic classes
- [ ] Generic interfaces
- [ ] Default function for generics

## String Functions
- [x] Length(S)
- [x] String concatenation (+)
- [x] String indexing (S[i], 1-based)
- [x] Copy(S, Index, Count)
- [x] Pos(Substr, S)
- [x] Delete(S, Index, Count)
- [x] Insert(Substr, S, Index)
- [x] IntToStr(I)
- [x] StrToInt(S)
- [x] StrToIntDef(S, Default)
- [x] FloatToStr(F)
- [x] StrToFloat(S)
- [x] Format(Fmt, Args)
- [x] UpperCase(S)
- [x] LowerCase(S)
- [x] Trim(S)
- [x] TrimLeft(S)
- [x] TrimRight(S)
- [x] StringReplace(S, Old, New, Flags)
- [x] CompareStr(S1, S2)
- [ ] CompareText(S1, S2)
- [ ] SameStr(S1, S2)
- [x] SameText(S1, S2)
- [ ] AnsiUpperCase(S)
- [ ] AnsiLowerCase(S)
- [ ] AnsiCompareStr(S1, S2)
- [ ] AnsiCompareText(S1, S2)
- [x] QuotedStr(S)
- [ ] AnsiQuotedStr(S, Quote)
- [x] StringOfChar(Ch, Count)
- [x] UniqueString(S)
- [x] SetString(S, Buffer, Len)
- [x] Val(S, V, Code)
- [x] Str(X, S)
- [x] UpCase(Ch)
- [x] WideCharLen(S)
- [x] WideCharToString(S)
- [x] StringToWideChar(S, Buf, BufSize)
- [x] WideCharToStrVar(S, Dest)
- [ ] WrapText(S, MaxCol)

## Math Functions
- [x] Abs(X)
- [x] Sqr(X)
- [x] Sqrt(X)
- [x] Sin(X)
- [x] Cos(X)
- [x] Tan(X)
- [x] ArcSin(X)
- [x] ArcCos(X)
- [x] ArcTan(X)
- [x] Ln(X)
- [x] Exp(X)
- [x] Power(Base, Exponent)
- [x] Round(X)
- [x] Trunc(X)
- [x] Int(X)
- [x] Frac(X)
- [x] Ceil(X)
- [x] Floor(X)
- [x] Pi constant
- [x] Sinh(X)
- [x] Cosh(X)
- [x] Tanh(X)
- [x] ArcSinh(X)
- [x] ArcCosh(X)
- [x] ArcTanh(X)
- [x] Log10(X)
- [x] Log2(X)
- [x] LogN(Base, X)
- [x] Max(A, B)
- [x] Min(A, B)
- [x] Random
- [x] Randomize
- [ ] RandomRange(Min, Max)

## Type Conversion Functions
- [x] IntToStr(I)
- [x] StrToInt(S)
- [x] StrToIntDef(S, Default)
- [x] FloatToStr(F)
- [x] StrToFloat(S)
- [x] BoolToStr(B)
- [ ] StrToBool(S)
- [x] Chr(I)
- [x] Ord(Ch)

## Ordinal Functions
- [x] Ord(X)
- [x] Succ(X)
- [x] Pred(X)
- [x] Inc(X)
- [x] Inc(X, N)
- [x] Dec(X)
- [x] Dec(X, N)
- [x] Low(X)
- [x] High(X)
- [x] Odd(X)
- [x] Swap(X)

## Memory Functions
- [x] New(P)
- [x] Dispose(P)
- [x] GetMem(P, Size)
- [x] FreeMem(P)
- [x] ReallocMem(P, Size)
- [ ] AllocMem(Size)
- [x] FillChar(Dest, Count, Value)
- [x] Move(Source, Dest, Count)
- [x] FillByte(Dest, Count, Value)
- [x] FillWord(Dest, Count, Value)
- [x] FillDWord(Dest, Count, Value)
- [ ] MoveChars(Source, Dest, Count)

## I/O Functions - Console
- [x] Write (basic)
- [x] WriteLn (basic)
- [ ] Write (formatted)
- [ ] WriteLn (formatted)
- [ ] Read(Var)
- [x] ReadLn(Var)
- [ ] Eof
- [ ] Eoln
- [ ] ClrScr
- [ ] GotoXY(X, Y)
- [ ] WhereX
- [ ] WhereY
- [ ] TextColor(Color)
- [ ] TextBackground(Color)

## I/O Functions - Files
- [x] Assign(F, Name)
- [x] Reset(F)
- [x] Rewrite(F)
- [x] Append(F)
- [x] Close(F)
- [x] Read(F, Var)
- [x] ReadLn(F, Var)
- [x] Write(F, Data)
- [x] WriteLn(F, Data)
- [x] BlockRead(F, Buf, Count)
- [x] BlockWrite(F, Buf, Count)
- [x] Seek(F, Position)
- [x] FilePos(F)
- [x] FileSize(F)
- [x] Eof(F)
- [x] Eoln(F)
- [x] SeekEof(F)
- [x] SeekEoln(F)
- [x] Flush(F)
- [x] Truncate(F)
- [x] Erase(F)
- [x] Rename(F, NewName)
- [x] IOResult

## File Management
- [x] FileExists(FileName)
- [x] DirectoryExists(DirName)
- [x] CreateDir(DirName)
- [ ] RemoveDir(DirName)
- [x] GetCurrentDir
- [ ] SetCurrentDir(DirName)
- [x] DeleteFile(FileName)
- [x] RenameFile(OldName, NewName)
- [ ] ChangeFileExt(FileName, Extension)
- [ ] ExtractFilePath(FileName)
- [ ] ExtractFileName(FileName)
- [ ] ExtractFileExt(FileName)
- [ ] ExtractFileDir(FileName)
- [ ] ExtractFileDrive(FileName)
- [ ] ExpandFileName(FileName)
- [ ] FileAge(FileName)
- [ ] FileGetAttr(FileName)
- [ ] FileSetAttr(FileName, Attr)

## Date/Time Functions
- [ ] Now
- [ ] Date
- [ ] Time
- [ ] DateToStr(Date)
- [ ] TimeToStr(Time)
- [ ] DateTimeToStr(DateTime)
- [ ] StrToDate(S)
- [ ] StrToTime(S)
- [ ] StrToDateTime(S)
- [ ] FormatDateTime(Format, DateTime)
- [ ] EncodeDate(Year, Month, Day)
- [ ] EncodeTime(Hour, Min, Sec, MSec)
- [ ] DecodeDate(Date, Year, Month, Day)
- [ ] DecodeTime(Time, Hour, Min, Sec, MSec)
- [ ] DayOfWeek(Date)
- [ ] IsLeapYear(Year)
- [ ] IncMonth(Date, Months)

## Compiler Directives - Build Settings
- [x] {$optimization mode}
- [x] {$target triple}
- [x] {$exceptions on|off}
- [x] {$strip on|off}
- [x] {$include_path path}
- [x] {$library_path path}
- [x] {$link library}
- [x] {$module_path path}
- [x] {$apptype console|gui}
- [x] {$include_header 'filename'}
- [ ] {$define symbol}
- [ ] {$undef symbol}
- [x] {$ifdef symbol}
- [ ] {$ifndef symbol}
- [ ] {$if expression}
- [x] {$else}
- [ ] {$elseif expression}
- [x] {$endif}
- [ ] {$ifopt switch}

## Compiler Directives - Code Control
- [ ] {$inline on|off}
- [ ] {$rangechecks on|off}
- [ ] {$overflowchecks on|off}
- [ ] {$iochecks on|off}
- [ ] {$typedaddress on|off}
- [ ] {$writeableconst on|off}
- [ ] {$booleval on|off}
- [ ] {$assertions on|off}
- [ ] {$optimization on|off}
- [ ] {$stackframes on|off}
- [ ] {$hints on|off}
- [ ] {$warnings on|off}

## Compiler Directives - Include
- [ ] {$I filename} or {$include filename}
- [ ] {$include_once filename}
- [ ] {$resource filename}

## Units & Modules
- [x] Unit declarations
- [x] Unit interface section
- [x] Unit implementation section
- [x] Uses clause
- [x] Unit namespaces
- [ ] Unit initialization section
- [ ] Unit finalization section
- [ ] Circular unit references
- [ ] Unit aliases
- [ ] Unit versioning

## Program Structure
- [x] Program declarations
- [x] Library declarations
- [x] Package declarations
- [ ] Uses clause in program
- [x] Program parameters (ParamCount, ParamStr)

## Exception Handling
- [ ] Exception class hierarchy
- [x] try..except blocks
- [x] try..finally blocks
- [x] try..except..finally blocks
- [x] raise statement
- [ ] raise with at
- [x] on E: Exception do
- [ ] else in except
- [ ] Exception.Message
- [ ] Exception.ClassName
- [ ] ExceptObject function
- [ ] ExceptionClass function
- [ ] AcquireExceptionObject
- [ ] ReleaseExceptionObject

## Attributes
- [ ] Custom attributes
- [ ] Attribute declarations
- [ ] Attribute parameters
- [ ] RTTI for attributes
- [ ] TCustomAttribute base class

## Anonymous Methods
- [ ] Anonymous method declarations
- [ ] Anonymous method types
- [ ] Anonymous method capture
- [ ] Anonymous method parameters
- [ ] Anonymous method as properties

## RTTI (Run-Time Type Information)
- [ ] TypeInfo function
- [ ] TObject.ClassInfo
- [ ] TObject.ClassName
- [ ] TObject.ClassType
- [ ] TObject.InheritsFrom
- [ ] GetTypeData function
- [ ] GetEnumName function
- [ ] GetEnumValue function
- [ ] TRttiContext
- [ ] TRttiType
- [ ] TRttiMethod
- [ ] TRttiProperty
- [ ] TRttiField

## Operators Overloading
- [ ] operator overload declarations
- [ ] Implicit operator
- [ ] Explicit operator
- [ ] Add operator (+)
- [ ] Subtract operator (-)
- [ ] Multiply operator (*)
- [ ] Divide operator (/)
- [ ] IntDivide operator (div)
- [ ] Modulus operator (mod)
- [ ] Equal operator (=)
- [ ] NotEqual operator (<>)
- [ ] GreaterThan operator (>)
- [ ] LessThan operator (<)
- [ ] GreaterThanOrEqual operator (>=)
- [ ] LessThanOrEqual operator (<=)
- [ ] LogicalAnd operator (and)
- [ ] LogicalOr operator (or)
- [ ] LogicalXor operator (xor)
- [ ] LogicalNot operator (not)
- [ ] Negative operator (unary -)
- [ ] Positive operator (unary +)
- [ ] Inc operator
- [ ] Dec operator
- [ ] In operator

## Helpers
- [ ] Class helpers
- [ ] Record helpers
- [ ] Type helpers
- [ ] Helper for built-in types
- [ ] Helper inheritance

## Advanced Language Features
- [ ] Inline assembly
- [ ] Absolute addressing (var X: Integer absolute $0040:$0017)
- [ ] External variables
- [ ] External functions
- [ ] Platform attribute
- [ ] Deprecated attribute
- [ ] Experimental attribute
- [ ] Library attribute

## Collections - System.Generics.Collections
- [ ] TList<T>
- [ ] TQueue<T>
- [ ] TStack<T>
- [ ] TDictionary<K,V>
- [ ] TObjectList<T>
- [ ] TObjectQueue<T>
- [ ] TObjectStack<T>
- [ ] TObjectDictionary<K,V>
- [ ] TThreadList<T>
- [ ] TThreadedQueue<T>

## Collections - System.Classes
- [ ] TStringList
- [ ] TList
- [ ] TCollection
- [ ] TCollectionItem
- [ ] TComponent
- [ ] TPersistent
- [ ] TStream
- [ ] TFileStream
- [ ] TMemoryStream
- [ ] TStringStream
- [ ] TBytesStream

## Threading
- [ ] TThread class
- [ ] BeginThread function
- [ ] EndThread procedure
- [ ] TMonitor
- [ ] TCriticalSection
- [ ] TMultiReadExclusiveWriteSynchronizer
- [ ] TEvent
- [ ] TMutex
- [ ] TSemaphore
- [ ] TThreadPool
- [ ] Parallel.For
- [ ] TParallel.For
- [ ] TTask
- [ ] ITask
- [ ] TTask.Run
- [ ] TTask.Wait
- [ ] TTask.WaitForAll
- [ ] TTask.WaitForAny

## Variants
- [ ] Variant type
- [ ] Variant creation
- [ ] Variant type conversion
- [ ] Variant operators
- [ ] VarType function
- [ ] VarIsNull function
- [ ] VarIsEmpty function
- [ ] VarIsClear function
- [ ] VarIsNumeric function
- [ ] VarIsStr function
- [ ] VarIsArray function
- [ ] VarArrayCreate function
- [ ] VarArrayOf function
- [ ] VarArrayDimCount function
- [ ] VarArrayLowBound function
- [ ] VarArrayHighBound function

## COM/OLE
- [ ] Interface reference counting
- [ ] IUnknown interface
- [ ] IDispatch interface
- [ ] CoCreateInstance
- [ ] CoInitialize
- [ ] CoUninitialize
- [ ] Variant for OLE Automation
- [ ] CreateOleObject function
- [ ] GetActiveOleObject function

## Platform Services
- [x] ParamCount function
- [x] ParamStr function
- [ ] GetEnvironmentVariable function
- [ ] SetEnvironmentVariable procedure
- [ ] ExitCode variable
- [x] Halt procedure
- [x] RunError procedure
- [x] Abort procedure
- [ ] GetTickCount function
- [ ] Sleep procedure

## Code Generation
- [x] Header file (.h) generation
- [x] Implementation file (.cpp) generation
- [x] Namespace per unit
- [x] Proper includes
- [x] Forward declarations
- [ ] Comment preservation
- [ ] Pragma once guards
- [ ] Include guard defines
- [x] Line number directives (#line)
- [x] Source position tracking
- [ ] Debug information generation

## Build System
- [x] Program → Executable
- [x] Library → Shared library (.dll/.so/.dylib)
- [x] Unit → Static library (.lib/.a)
- [x] Zig build system integration
- [x] Cross-platform compilation
- [x] Build optimization modes (Debug, ReleaseSafe, ReleaseFast, ReleaseSmall)
- [x] Conditional compilation support (DEBUG/RELEASE defines)
- [x] Platform defines (WIN32/WIN64/LINUX/MACOS/MSWINDOWS/POSIX)
- [x] Architecture defines (CPUX64/CPU386/CPUARM64)
- [x] Application type defines (CONSOLE_APP/GUI_APP)
- [x] Windows subsystem control (console vs GUI)
- [ ] Incremental compilation
- [ ] Precompiled headers
- [ ] Package management
- [ ] Dependency resolution
- [ ] Build scripts
- [ ] Custom build steps

## Debugging Support
- [ ] Debug symbols generation
- [ ] Source line mapping
- [ ] Variable inspection
- [ ] Breakpoint support
- [ ] Stack trace generation
- [ ] Memory leak detection
- [ ] Assert statements
- [ ] DebugBreak support

## Standard Library - System
- [x] WriteLn
- [x] Write
- [x] ReadLn
- [ ] Read
- [x] Length
- [x] SetLength
- [x] Copy
- [x] Delete
- [x] Insert
- [x] Pos
- [x] New
- [x] Dispose
- [x] GetMem
- [x] FreeMem
- [x] Inc
- [x] Dec
- [x] Succ
- [x] Pred
- [x] Ord
- [x] Chr
- [x] Low
- [x] High
- [x] SizeOf
- [ ] TypeOf
- [x] Assigned
- [ ] Default
- [ ] Initialize
- [ ] Finalize

## Standard Library - System.SysUtils
- [x] IntToStr
- [x] StrToInt
- [x] StrToIntDef
- [x] FloatToStr
- [x] StrToFloat
- [x] Format
- [ ] FormatFloat
- [ ] FormatDateTime
- [x] UpperCase
- [x] LowerCase
- [x] Trim
- [x] TrimLeft
- [x] TrimRight
- [x] StringReplace
- [x] QuotedStr
- [ ] ExtractFilePath
- [ ] ExtractFileName
- [ ] ExtractFileExt
- [ ] ChangeFileExt
- [x] FileExists
- [x] DirectoryExists
- [x] DeleteFile
- [x] RenameFile
- [x] CreateDir
- [ ] RemoveDir
- [ ] Now
- [ ] Date
- [ ] Time
- [ ] EncodeDate
- [ ] EncodeTime
- [ ] DecodeDate
- [ ] DecodeTime

## Standard Library - System.Math
- [x] Abs
- [x] Sqr
- [x] Sqrt
- [x] Sin
- [x] Cos
- [x] Tan
- [x] ArcSin
- [x] ArcCos
- [x] ArcTan
- [x] ArcTan2
- [x] Ln
- [x] Exp
- [x] Power
- [ ] IntPower
- [x] Round
- [ ] RoundTo
- [x] Trunc
- [x] Int
- [x] Frac
- [x] Ceil
- [x] Floor
- [x] Sinh(X)
- [x] Cosh(X)
- [x] Tanh(X)
- [x] ArcSinh(X)
- [x] ArcCosh(X)
- [x] ArcTanh(X)
- [x] Log10(X)
- [x] Log2(X)
- [x] LogN(Base, X)
- [x] Max
- [x] Min
- [ ] MaxValue
- [ ] MinValue
- [ ] MaxIntValue
- [ ] MinIntValue
- [ ] InRange
- [ ] EnsureRange
- [ ] Sign
- [ ] CompareValue
- [ ] SameValue
- [ ] IsNan
- [ ] IsInfinite
- [ ] IsZero

## C/C++ Interoperability
- [x] External function declarations (external 'library.dll')
- [x] External library tracking for linking
- [x] Calling conventions (stdcall, cdecl, fastcall)
- [x] Automatic string type conversion for external functions
- [x] PChar/PWideChar → const wchar_t* mapping
- [x] PAnsiChar → const char* mapping
- [x] Call-site string conversion (.c_str_wide(), .to_ansi())
- [x] Pascal type → C type mapping for external declarations
- [x] No declaration generation for external functions (linker resolves)
- [ ] External variable declarations
- [ ] C header file import
- [ ] C++ class wrapping
- [ ] C++ template wrapping
- [ ] C array handling
- [ ] Structure alignment
- [ ] Packed structures
- [ ] Name mangling control

## Tools & Utilities
- [x] Command-line compiler (nitro)
- [x] Build command
- [x] Run command
- [x] Clean command
- [x] Init command (project creation)
- [x] Version command
- [x] Help command
- [ ] Convert-header command (C header conversion)
- [ ] Package manager
- [ ] Documentation generator
- [ ] Profiler
- [ ] Code formatter
- [ ] Static analyzer
- [ ] Refactoring tools
- [ ] IDE integration
- [ ] Language server protocol (LSP)
- [ ] Syntax highlighting definitions

## Runtime Library (RTL)
- [x] I/O functions (Write, WriteLn)
- [x] Control flow helpers (ForLoop, WhileLoop, RepeatUntil)
- [x] Basic operators (Div, Mod, Shl, Shr)
- [x] String class (np::String)
- [x] Dynamic arrays (np::DynArray<T>)
- [x] Sets (np::Set<T>)
- [x] Exception handling
- [x] Memory management
- [ ] Thread support
- [ ] RTTI support
- [ ] Collection classes
- [x] File I/O
- [ ] Date/Time support
- [x] Math functions
- [x] String functions
- [x] Type conversion functions

## Cross-Platform Support
- [x] Windows (x64)
- [x] Linux (x64)
- [x] macOS (x64)
- [ ] Windows (ARM64)
- [ ] Linux (ARM64)
- [ ] macOS (ARM64/Apple Silicon)
- [ ] FreeBSD
- [ ] WebAssembly (WASI)
- [ ] Android
- [ ] iOS
- [ ] Embedded systems
- [ ] Raspberry Pi

## Optimization
- [x] Optimization levels (Debug, ReleaseSafe, ReleaseFast, ReleaseSmall)
- [ ] Inline functions
- [ ] Dead code elimination
- [ ] Constant folding
- [ ] Constant propagation
- [ ] Loop unrolling
- [ ] Tail call optimization
- [ ] Register allocation hints
- [ ] Profile-guided optimization
- [ ] Link-time optimization (LTO)

## Testing & Quality
- [ ] Unit testing framework
- [x] Test runner
- [ ] Code coverage analysis
- [ ] Memory leak detection
- [ ] Static analysis
- [ ] Lint warnings
- [ ] Code metrics
- [ ] Continuous integration support

## Documentation
- [x] User manual
- [x] Design documentation
- [x] Language coverage list
- [ ] API reference
- [ ] Tutorial series
- [ ] Cookbook/recipes
- [ ] Migration guide (Delphi → NitroPascal)
- [ ] Performance guide
- [ ] Best practices guide
- [ ] Troubleshooting guide
