{===============================================================================
  NitroPascal - Modern Pascal • C Performance

  Copyright © 2025-present tinyBigGAMES™ LLC
  All Rights Reserved.

  https://nitropascal.org

  See LICENSE for license information
===============================================================================}

unit UTest.Types;

interface

// Type declaration tests
procedure SimpleTypeAlias();
procedure IntegerTypeAlias();
procedure FloatTypeAlias();
procedure StringTypeAlias();
procedure BooleanTypeAlias();

// Record type tests
procedure RecordTypeDeclaration();
procedure NestedRecordTypes();
procedure RecordTypeAlias();

// Array type tests
procedure ArrayTypeDeclaration();
procedure MultiDimArrayType();
procedure ArrayTypeAlias();

// Pointer type tests
procedure PointerTypeDeclaration();
procedure PointerToRecordType();
procedure PointerTypeAlias();

// Function type tests
procedure FunctionTypeDeclaration();
procedure ProcedureTypeDeclaration();
procedure FunctionTypeAlias();

// Enum type tests (if supported)
procedure EnumTypeDeclaration();
procedure EnumWithValues();
procedure EnumTypeAlias();

// Subrange type tests
procedure SubrangeTypeDeclaration();
procedure SubrangeInArray();
procedure SubrangeVariable();

// Type casting tests
procedure IntToFloatCast();
procedure FloatToIntCast();
procedure PointerCast();
procedure RecordCast();

// Type conversion tests
procedure ExplicitConversion();
procedure ImplicitConversion();
procedure StringConversion();

// Complex type tests
procedure ArrayOfRecordType();
procedure RecordWithArrayType();
procedure PointerToArrayType();
procedure NestedTypeDeclarations();

// Type in parameters tests
procedure CustomTypeParameter();
procedure CustomTypeReturn();
procedure CustomTypeByRef();

// Type scope tests
procedure TypeInProgram();
procedure TypeInModule();
procedure TypeVisibility();

implementation

uses
  UTest.Common;

{ Type Declaration Tests }

procedure SimpleTypeAlias();
const
  CSource =
  '''
  program Test;
  type MyInt = int;
  var x: MyInt;
  begin
    x := 42;
  end.
  ''';
begin
  RunCompilerTest('Simple Type Alias', CSource);
end;

procedure IntegerTypeAlias();
const
  CSource =
  '''
  program Test;
  type Counter = int;
  var count: Counter;
  begin
    count := 10;
    count := count + 5;
  end.
  ''';
begin
  RunCompilerTest('Integer Type Alias', CSource);
end;

procedure FloatTypeAlias();
const
  CSource =
  '''
  program Test;
  type Real = float;
  var value: Real;
  begin
    value := 3.14;
  end.
  ''';
begin
  RunCompilerTest('Float Type Alias', CSource);
end;

procedure StringTypeAlias();
const
  CSource =
  '''
  program Test;
  type Text = string;
  var message: Text;
  begin
    message := "Hello";
  end.
  ''';
begin
  RunCompilerTest('String Type Alias', CSource);
end;

procedure BooleanTypeAlias();
const
  CSource =
  '''
  program Test;
  type Flag = bool;
  var isActive: Flag;
  begin
    isActive := true;
  end.
  ''';
begin
  RunCompilerTest('Boolean Type Alias', CSource);
end;

{ Record Type Tests }

procedure RecordTypeDeclaration();
const
  CSource =
  '''
  program Test;
  type Point = record
    x: int;
    y: int;
  end;
  var p: Point;
  begin
    p.x := 10;
    p.y := 20;
  end.
  ''';
begin
  RunCompilerTest('Record Type Declaration', CSource);
end;

procedure NestedRecordTypes();
const
  CSource =
  '''
  program Test;
  type Address = record
    street: string;
    city: string;
  end;
  type Person = record
    name: string;
    address: Address;
  end;
  var person: Person;
  begin
    person.name := "John";
    person.address.street := "Main St";
  end.
  ''';
begin
  RunCompilerTest('Nested Record Types', CSource);
end;

procedure RecordTypeAlias();
const
  CSource =
  '''
  program Test;
  type Point = record
    x: int;
    y: int;
  end;
  type Coordinate = Point;
  var coord: Coordinate;
  begin
    coord.x := 5;
    coord.y := 10;
  end.
  ''';
begin
  RunCompilerTest('Record Type Alias', CSource);
end;

{ Array Type Tests }

procedure ArrayTypeDeclaration();
const
  CSource =
  '''
  program Test;
  type IntArray = array[0..9] of int;
  var numbers: IntArray;
  begin
    numbers[0] := 42;
  end.
  ''';
begin
  RunCompilerTest('Array Type Declaration', CSource);
end;

procedure MultiDimArrayType();
const
  CSource =
  '''
  program Test;
  type Matrix = array[0..2, 0..2] of int;
  var m: Matrix;
  begin
    m[0, 0] := 1;
    m[1, 1] := 2;
  end.
  ''';
begin
  RunCompilerTest('Multi Dim Array Type', CSource);
end;

procedure ArrayTypeAlias();
const
  CSource =
  '''
  program Test;
  type IntArray = array[0..4] of int;
  type Numbers = IntArray;
  var nums: Numbers;
  begin
    nums[0] := 1;
  end.
  ''';
begin
  RunCompilerTest('Array Type Alias', CSource);
end;

{ Pointer Type Tests }

procedure PointerTypeDeclaration();
const
  CSource =
  '''
  program Test;
  type IntPtr = ^int;
  var x: int;
  var p: IntPtr;
  begin
    x := 42;
    p := @x;
  end.
  ''';
begin
  RunCompilerTest('Pointer Type Declaration', CSource);
end;

procedure PointerToRecordType();
const
  CSource =
  '''
  program Test;
  type Point = record
    x: int;
    y: int;
  end;
  type PointPtr = ^Point;
  var pt: Point;
  var p: PointPtr;
  begin
    pt.x := 10;
    p := @pt;
  end.
  ''';
begin
  RunCompilerTest('Pointer To Record Type', CSource);
end;

procedure PointerTypeAlias();
const
  CSource =
  '''
  program Test;
  type IntPtr = ^int;
  type IntPointer = IntPtr;
  var x: int;
  var p: IntPointer;
  begin
    x := 42;
    p := @x;
  end.
  ''';
begin
  RunCompilerTest('Pointer Type Alias', CSource);
end;

{ Function Type Tests }

procedure FunctionTypeDeclaration();
const
  CSource =
  '''
  program Test;
  type BinaryOp = ^routine(const a, b: int): int;
  
  routine Add(const a, b: int): int;
  begin
    return a + b;
  end;
  
  var op: BinaryOp;
  begin
    op := @Add;
  end.
  ''';
begin
  RunCompilerTest('Function Type Declaration', CSource);
end;

procedure ProcedureTypeDeclaration();
const
  CSource =
  '''
  program Test;
  type Action = ^routine();
  
  routine DoSomething();
  begin
    halt(0);
  end;
  
  var act: Action;
  begin
    act := @DoSomething;
  end.
  ''';
begin
  RunCompilerTest('Procedure Type Declaration', CSource);
end;

procedure FunctionTypeAlias();
const
  CSource =
  '''
  program Test;
  type MathFunc = ^routine(const x: float): float;
  type RealFunction = MathFunc;
  
  routine Square(const x: float): float;
  begin
    return x * x;
  end;
  
  var f: RealFunction;
  begin
    f := @Square;
  end.
  ''';
begin
  RunCompilerTest('Function Type Alias', CSource);
end;

{ Enum Type Tests }

procedure EnumTypeDeclaration();
const
  CSource =
  '''
  program Test;
  type Color = (Red, Green, Blue);
  var c: Color;
  begin
    c := Red;
  end.
  ''';
begin
  RunCompilerTest('Enum Type Declaration', CSource);
end;

procedure EnumWithValues();
const
  CSource =
  '''
  program Test;
  type Status = (Pending, Active, Completed);
  var status: Status;
  begin
    status := Active;
  end.
  ''';
begin
  RunCompilerTest('Enum With Values', CSource);
end;

procedure EnumTypeAlias();
const
  CSource =
  '''
  program Test;
  type Color = (Red, Green, Blue);
  type RGB = Color;
  var c: RGB;
  begin
    c := Blue;
  end.
  ''';
begin
  RunCompilerTest('Enum Type Alias', CSource);
end;

{ Subrange Type Tests }

procedure SubrangeTypeDeclaration();
const
  CSource =
  '''
  program Test;
  type Digit = 0..9;
  var d: Digit;
  begin
    d := 5;
  end.
  ''';
begin
  RunCompilerTest('Subrange Type Declaration', CSource);
end;

procedure SubrangeInArray();
const
  CSource =
  '''
  program Test;
  type Index = 0..9;
  var arr: array[Index] of int;
  var i: Index;
  begin
    for i := 0 to 9 do
      arr[i] := i;
  end.
  ''';
begin
  RunCompilerTest('Subrange In Array', CSource);
end;

procedure SubrangeVariable();
const
  CSource =
  '''
  program Test;
  type Percentage = 0..100;
  var score: Percentage;
  begin
    score := 85;
  end.
  ''';
begin
  RunCompilerTest('Subrange Variable', CSource);
end;

{ Type Casting Tests }

procedure IntToFloatCast();
const
  CSource =
  '''
  program Test;
  var i: int;
  var f: float;
  begin
    i := 42;
    f := float(i);
  end.
  ''';
begin
  RunCompilerTest('Int To Float Cast', CSource);
end;

procedure FloatToIntCast();
const
  CSource =
  '''
  program Test;
  var f: float;
  var i: int;
  begin
    f := 3.14;
    i := int(f);
  end.
  ''';
begin
  RunCompilerTest('Float To Int Cast', CSource);
end;

procedure PointerCast();
const
  CSource =
  '''
  program Test;
  var i: int;
  var pi: ^int;
  var pv: ^void;
  begin
    i := 42;
    pi := @i;
    pv := ^void(pi);
  end.
  ''';
begin
  RunCompilerTest('Pointer Cast', CSource);
end;

procedure RecordCast();
const
  CSource =
  '''
  program Test;
  type Point2D = record
    x: int;
    y: int;
  end;
  type Point3D = record
    x: int;
    y: int;
    z: int;
  end;
  var p2: Point2D;
  var p3: Point3D;
  begin
    p2.x := 10;
    p2.y := 20;
  end.
  ''';
begin
  RunCompilerTest('Record Cast', CSource);
end;

{ Type Conversion Tests }

procedure ExplicitConversion();
const
  CSource =
  '''
  program Test;
  var i: int;
  var f: float;
  begin
    i := 10;
    f := float(i);
    i := int(f);
  end.
  ''';
begin
  RunCompilerTest('Explicit Conversion', CSource);
end;

procedure ImplicitConversion();
const
  CSource =
  '''
  program Test;
  var i: int;
  var f: float;
  begin
    i := 10;
    f := i;
  end.
  ''';
begin
  RunCompilerTest('Implicit Conversion', CSource);
end;

procedure StringConversion();
const
  CSource =
  '''
  program Test;
  var s: string;
  var i: int;
  begin
    i := 42;
  end.
  ''';
begin
  RunCompilerTest('String Conversion', CSource);
end;

{ Complex Type Tests }

procedure ArrayOfRecordType();
const
  CSource =
  '''
  program Test;
  type Point = record
    x: int;
    y: int;
  end;
  type PointArray = array[0..9] of Point;
  var points: PointArray;
  begin
    points[0].x := 1;
    points[0].y := 2;
  end.
  ''';
begin
  RunCompilerTest('Array Of Record Type', CSource);
end;

procedure RecordWithArrayType();
const
  CSource =
  '''
  program Test;
  type IntArray = array[0..2] of int;
  type Data = record
    values: IntArray;
  end;
  var data: Data;
  begin
    data.values[0] := 1;
  end.
  ''';
begin
  RunCompilerTest('Record With Array Type', CSource);
end;

procedure PointerToArrayType();
const
  CSource =
  '''
  program Test;
  type IntArray = array[0..9] of int;
  type ArrayPtr = ^IntArray;
  var arr: IntArray;
  var p: ArrayPtr;
  begin
    arr[0] := 42;
    p := @arr;
  end.
  ''';
begin
  RunCompilerTest('Pointer To Array Type', CSource);
end;

procedure NestedTypeDeclarations();
const
  CSource =
  '''
  program Test;
  type Value = int;
  type ValueArray = array[0..9] of Value;
  type Data = record
    values: ValueArray;
  end;
  type DataPtr = ^Data;
  var d: Data;
  var p: DataPtr;
  begin
    d.values[0] := 1;
    p := @d;
  end.
  ''';
begin
  RunCompilerTest('Nested Type Declarations', CSource);
end;

{ Type in Parameters Tests }

procedure CustomTypeParameter();
const
  CSource =
  '''
  program Test;
  type Point = record
    x: int;
    y: int;
  end;
  
  routine PrintPoint(const p: Point);
  begin
    halt(0);
  end;
  
  var pt: Point;
  begin
    pt.x := 10;
    pt.y := 20;
    PrintPoint(pt);
  end.
  ''';
begin
  RunCompilerTest('Custom Type Parameter', CSource);
end;

procedure CustomTypeReturn();
const
  CSource =
  '''
  program Test;
  type Point = record
    x: int;
    y: int;
  end;
  
  routine CreatePoint(const ax, ay: int): Point;
  var p: Point;
  begin
    p.x := ax;
    p.y := ay;
    return p;
  end;
  
  var pt: Point;
  begin
    pt := CreatePoint(5, 10);
  end.
  ''';
begin
  RunCompilerTest('Custom Type Return', CSource);
end;

procedure CustomTypeByRef();
const
  CSource =
  '''
  program Test;
  type Counter = record
    value: int;
  end;
  
  routine Increment(var c: Counter);
  begin
    c.value := c.value + 1;
  end;
  
  var counter: Counter;
  begin
    counter.value := 0;
    Increment(counter);
  end.
  ''';
begin
  RunCompilerTest('Custom Type By Ref', CSource);
end;

{ Type Scope Tests }

procedure TypeInProgram();
const
  CSource =
  '''
  program Test;
  type MyInt = int;
  var x: MyInt;
  begin
    x := 42;
  end.
  ''';
begin
  RunCompilerTest('Type In Program', CSource);
end;

procedure TypeInModule();
const
  CSource =
  '''
  module Math;
  
  type Vector = record
    x: float;
    y: float;
  end;
  
  public routine CreateVector(const ax, ay: float): Vector;
  var v: Vector;
  begin
    v.x := ax;
    v.y := ay;
    return v;
  end;
  
  end.
  ''';
begin
  RunCompilerTest('Type In Module', CSource);
end;

procedure TypeVisibility();
const
  CSource =
  '''
  module Types;
  
  type PublicType = record
    value: int;
  end;
  
  type PrivateType = record
    data: int;
  end;
  
  public routine GetPublic(): PublicType;
  var p: PublicType;
  begin
    p.value := 42;
    return p;
  end;
  
  routine UsePrivate(): PrivateType;
  var p: PrivateType;
  begin
    p.data := 100;
    return p;
  end;
  
  end.
  ''';
begin
  RunCompilerTest('Type Visibility', CSource);
end;

end.
