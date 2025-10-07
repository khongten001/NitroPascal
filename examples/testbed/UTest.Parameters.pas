{===============================================================================
  NitroPascal - Modern Pascal • C Performance

  Copyright © 2025-present tinyBigGAMES™ LLC
  All Rights Reserved.

  https://nitropascal.org

  See LICENSE for license information
===============================================================================}

unit UTest.Parameters;

interface

// Basic parameter tests
procedure ParameterByValue();
procedure ParameterByConst();
procedure ParameterByVar();
procedure ParameterByOut();
procedure NoParameters();

// Multiple parameter tests
procedure MultipleValueParameters();
procedure MixedParameterModes();
procedure ManyParameters();

// Parameter type tests
procedure IntParameter();
procedure FloatParameter();
procedure StringParameter();
procedure BoolParameter();
procedure ArrayParameter();
procedure RecordParameter();
procedure PointerParameter();

// Out parameter tests
procedure SimpleOutParameter();
procedure MultipleOutParameters();
procedure OutParameterWithReturn();
procedure OutParameterInRecord();

// Array parameter tests
procedure ArrayByValue();
procedure ArrayByConst();
procedure ArrayByVar();
procedure ArrayByOut();
procedure MultiDimArrayParameter();

// Record parameter tests
procedure RecordByValue();
procedure RecordByConst();
procedure RecordByVar();
procedure RecordByOut();
procedure NestedRecordParameter();

// Pointer parameter tests
procedure PointerByValue();
procedure PointerByConst();
procedure PointerByVar();
procedure PointerByOut();
procedure PointerToPointerParameter();

// Complex parameter tests
procedure ArrayOfRecordsParameter();
procedure RecordWithArrayParameter();
procedure PointerToRecordParameter();
procedure FunctionPointerParameter();

// Parameter edge cases
procedure UnusedParameter();
procedure ParameterShadowsGlobal();
procedure ParameterModification();
procedure ConstParameterNoModify();

// Variadic parameters tests (if supported)
procedure VariadicParameters();
procedure VariadicWithFixedParams();

implementation

uses
  UTest.Common;

{ Basic Parameter Tests }

procedure ParameterByValue();
const
  CSource =
  '''
  program Test;
  
  routine Increment(x: int): int;
  begin
    x := x + 1;
    return x;
  end;
  
  var value: int;
  begin
    value := 10;
    value := Increment(value);
  end.
  ''';
begin
  RunCompilerTest('Parameter By Value', CSource);
end;

procedure ParameterByConst();
const
  CSource =
  '''
  program Test;
  
  routine GetValue(const x: int): int;
  begin
    return x * 2;
  end;
  
  var value: int;
  begin
    value := GetValue(5);
  end.
  ''';
begin
  RunCompilerTest('Parameter By Const', CSource);
end;

procedure ParameterByVar();
const
  CSource =
  '''
  program Test;
  
  routine Increment(var x: int);
  begin
    x := x + 1;
  end;
  
  var value: int;
  begin
    value := 10;
    Increment(value);
  end.
  ''';
begin
  RunCompilerTest('Parameter By Var', CSource);
end;

procedure ParameterByOut();
const
  CSource =
  '''
  program Test;
  
  routine GetValues(out x, y: int);
  begin
    x := 10;
    y := 20;
  end;
  
  var a, b: int;
  begin
    GetValues(a, b);
  end.
  ''';
begin
  RunCompilerTest('Parameter By Out', CSource);
end;

procedure NoParameters();
const
  CSource =
  '''
  program Test;
  
  routine GetConstant(): int;
  begin
    return 42;
  end;
  
  var value: int;
  begin
    value := GetConstant();
  end.
  ''';
begin
  RunCompilerTest('No Parameters', CSource);
end;

{ Multiple Parameter Tests }

procedure MultipleValueParameters();
const
  CSource =
  '''
  program Test;
  
  routine Add(a, b, c: int): int;
  begin
    return a + b + c;
  end;
  
  var result: int;
  begin
    result := Add(1, 2, 3);
  end.
  ''';
begin
  RunCompilerTest('Multiple Value Parameters', CSource);
end;

procedure MixedParameterModes();
const
  CSource =
  '''
  program Test;
  
  routine Process(const input: int; var output: int; out result: int);
  begin
    output := input * 2;
    result := input + output;
  end;
  
  var x, y, z: int;
  begin
    x := 5;
    Process(x, y, z);
  end.
  ''';
begin
  RunCompilerTest('Mixed Parameter Modes', CSource);
end;

procedure ManyParameters();
const
  CSource =
  '''
  program Test;
  
  routine Sum(const a, b, c, d, e: int): int;
  begin
    return a + b + c + d + e;
  end;
  
  var total: int;
  begin
    total := Sum(1, 2, 3, 4, 5);
  end.
  ''';
begin
  RunCompilerTest('Many Parameters', CSource);
end;

{ Parameter Type Tests }

procedure IntParameter();
const
  CSource =
  '''
  program Test;
  
  routine Square(const x: int): int;
  begin
    return x * x;
  end;
  
  var result: int;
  begin
    result := Square(5);
  end.
  ''';
begin
  RunCompilerTest('Int Parameter', CSource);
end;

procedure FloatParameter();
const
  CSource =
  '''
  program Test;
  
  routine Half(const x: float): float;
  begin
    return x / 2.0;
  end;
  
  var result: float;
  begin
    result := Half(10.0);
  end.
  ''';
begin
  RunCompilerTest('Float Parameter', CSource);
end;

procedure StringParameter();
const
  CSource =
  '''
  program Test;
  
  routine GetLength(const s: string): int;
  begin
    return s.length();
  end;
  
  var len: int;
  begin
    len := GetLength("Hello");
  end.
  ''';
begin
  RunCompilerTest('String Parameter', CSource);
end;

procedure BoolParameter();
const
  CSource =
  '''
  program Test;
  
  routine Toggle(const flag: bool): bool;
  begin
    return not flag;
  end;
  
  var result: bool;
  begin
    result := Toggle(true);
  end.
  ''';
begin
  RunCompilerTest('Bool Parameter', CSource);
end;

procedure ArrayParameter();
const
  CSource =
  '''
  program Test;
  
  routine GetFirst(const arr: array[0..4] of int): int;
  begin
    return arr[0];
  end;
  
  var numbers: array[0..4] of int;
  var first: int;
  begin
    numbers[0] := 42;
    first := GetFirst(numbers);
  end.
  ''';
begin
  RunCompilerTest('Array Parameter', CSource);
end;

procedure RecordParameter();
const
  CSource =
  '''
  program Test;
  type Point = record
    x: int;
    y: int;
  end;
  
  routine GetX(const p: Point): int;
  begin
    return p.x;
  end;
  
  var pt: Point;
  var x: int;
  begin
    pt.x := 10;
    pt.y := 20;
    x := GetX(pt);
  end.
  ''';
begin
  RunCompilerTest('Record Parameter', CSource);
end;

procedure PointerParameter();
const
  CSource =
  '''
  program Test;
  
  routine GetValue(const p: ^int): int;
  begin
    return p^;
  end;
  
  var value: int;
  var result: int;
  begin
    value := 42;
    result := GetValue(@value);
  end.
  ''';
begin
  RunCompilerTest('Pointer Parameter', CSource);
end;

{ Out Parameter Tests }

procedure SimpleOutParameter();
const
  CSource =
  '''
  program Test;
  
  routine Initialize(out x: int);
  begin
    x := 100;
  end;
  
  var value: int;
  begin
    Initialize(value);
  end.
  ''';
begin
  RunCompilerTest('Simple Out Parameter', CSource);
end;

procedure MultipleOutParameters();
const
  CSource =
  '''
  program Test;
  
  routine GetCoordinates(out x, y, z: int);
  begin
    x := 1;
    y := 2;
    z := 3;
  end;
  
  var a, b, c: int;
  begin
    GetCoordinates(a, b, c);
  end.
  ''';
begin
  RunCompilerTest('Multiple Out Parameters', CSource);
end;

procedure OutParameterWithReturn();
const
  CSource =
  '''
  program Test;
  
  routine Divide(const a, b: int; out remainder: int): int;
  begin
    remainder := a mod b;
    return a div b;
  end;
  
  var quotient, rem: int;
  begin
    quotient := Divide(17, 5, rem);
  end.
  ''';
begin
  RunCompilerTest('Out Parameter With Return', CSource);
end;

procedure OutParameterInRecord();
const
  CSource =
  '''
  program Test;
  type Point = record
    x: int;
    y: int;
  end;
  
  routine CreatePoint(const ax, ay: int; out p: Point);
  begin
    p.x := ax;
    p.y := ay;
  end;
  
  var pt: Point;
  begin
    CreatePoint(10, 20, pt);
  end.
  ''';
begin
  RunCompilerTest('Out Parameter In Record', CSource);
end;

{ Array Parameter Tests }

procedure ArrayByValue();
const
  CSource =
  '''
  program Test;
  
  routine ModifyArray(arr: array[0..2] of int);
  begin
    arr[0] := 99;
  end;
  
  var numbers: array[0..2] of int;
  begin
    numbers[0] := 1;
    ModifyArray(numbers);
  end.
  ''';
begin
  RunCompilerTest('Array By Value', CSource);
end;

procedure ArrayByConst();
const
  CSource =
  '''
  program Test;
  
  routine SumArray(const arr: array[0..4] of int): int;
  var i: int;
  var total: int;
  begin
    total := 0;
    for i := 0 to 4 do
      total := total + arr[i];
    return total;
  end;
  
  var numbers: array[0..4] of int;
  var sum: int;
  var i: int;
  begin
    for i := 0 to 4 do
      numbers[i] := i + 1;
    sum := SumArray(numbers);
  end.
  ''';
begin
  RunCompilerTest('Array By Const', CSource);
end;

procedure ArrayByVar();
const
  CSource =
  '''
  program Test;
  
  routine FillArray(var arr: array[0..2] of int; const value: int);
  var i: int;
  begin
    for i := 0 to 2 do
      arr[i] := value;
  end;
  
  var numbers: array[0..2] of int;
  begin
    FillArray(numbers, 42);
  end.
  ''';
begin
  RunCompilerTest('Array By Var', CSource);
end;

procedure ArrayByOut();
const
  CSource =
  '''
  program Test;
  
  routine InitArray(out arr: array[0..2] of int);
  var i: int;
  begin
    for i := 0 to 2 do
      arr[i] := i * 10;
  end;
  
  var numbers: array[0..2] of int;
  begin
    InitArray(numbers);
  end.
  ''';
begin
  RunCompilerTest('Array By Out', CSource);
end;

procedure MultiDimArrayParameter();
const
  CSource =
  '''
  program Test;
  
  routine InitMatrix(var m: array[0..1, 0..1] of int);
  begin
    m[0, 0] := 1;
    m[0, 1] := 2;
    m[1, 0] := 3;
    m[1, 1] := 4;
  end;
  
  var matrix: array[0..1, 0..1] of int;
  begin
    InitMatrix(matrix);
  end.
  ''';
begin
  RunCompilerTest('Multi Dim Array Parameter', CSource);
end;

{ Record Parameter Tests }

procedure RecordByValue();
const
  CSource =
  '''
  program Test;
  type Point = record
    x: int;
    y: int;
  end;
  
  routine ModifyPoint(p: Point);
  begin
    p.x := 99;
    p.y := 99;
  end;
  
  var pt: Point;
  begin
    pt.x := 10;
    pt.y := 20;
    ModifyPoint(pt);
  end.
  ''';
begin
  RunCompilerTest('Record By Value', CSource);
end;

procedure RecordByConst();
const
  CSource =
  '''
  program Test;
  type Point = record
    x: int;
    y: int;
  end;
  
  routine GetSum(const p: Point): int;
  begin
    return p.x + p.y;
  end;
  
  var pt: Point;
  var sum: int;
  begin
    pt.x := 10;
    pt.y := 20;
    sum := GetSum(pt);
  end.
  ''';
begin
  RunCompilerTest('Record By Const', CSource);
end;

procedure RecordByVar();
const
  CSource =
  '''
  program Test;
  type Point = record
    x: int;
    y: int;
  end;
  
  routine ScalePoint(var p: Point; const factor: int);
  begin
    p.x := p.x * factor;
    p.y := p.y * factor;
  end;
  
  var pt: Point;
  begin
    pt.x := 10;
    pt.y := 20;
    ScalePoint(pt, 2);
  end.
  ''';
begin
  RunCompilerTest('Record By Var', CSource);
end;

procedure RecordByOut();
const
  CSource =
  '''
  program Test;
  type Point = record
    x: int;
    y: int;
  end;
  
  routine CreateOrigin(out p: Point);
  begin
    p.x := 0;
    p.y := 0;
  end;
  
  var pt: Point;
  begin
    CreateOrigin(pt);
  end.
  ''';
begin
  RunCompilerTest('Record By Out', CSource);
end;

procedure NestedRecordParameter();
const
  CSource =
  '''
  program Test;
  type Inner = record
    value: int;
  end;
  type Outer = record
    inner: Inner;
  end;
  
  routine GetValue(const o: Outer): int;
  begin
    return o.inner.value;
  end;
  
  var obj: Outer;
  var val: int;
  begin
    obj.inner.value := 42;
    val := GetValue(obj);
  end.
  ''';
begin
  RunCompilerTest('Nested Record Parameter', CSource);
end;

{ Pointer Parameter Tests }

procedure PointerByValue();
const
  CSource =
  '''
  program Test;
  
  routine SetValue(p: ^int; const value: int);
  begin
    p^ := value;
  end;
  
  var x: int;
  begin
    x := 0;
    SetValue(@x, 42);
  end.
  ''';
begin
  RunCompilerTest('Pointer By Value', CSource);
end;

procedure PointerByConst();
const
  CSource =
  '''
  program Test;
  
  routine GetValue(const p: ^int): int;
  begin
    return p^;
  end;
  
  var x: int;
  var value: int;
  begin
    x := 42;
    value := GetValue(@x);
  end.
  ''';
begin
  RunCompilerTest('Pointer By Const', CSource);
end;

procedure PointerByVar();
const
  CSource =
  '''
  program Test;
  
  routine ChangeTarget(var p: ^int; var newTarget: int);
  begin
    p := @newTarget;
  end;
  
  var x, y: int;
  var p: ^int;
  begin
    x := 10;
    y := 20;
    p := @x;
    ChangeTarget(p, y);
  end.
  ''';
begin
  RunCompilerTest('Pointer By Var', CSource);
end;

procedure PointerByOut();
const
  CSource =
  '''
  program Test;
  
  routine AllocatePointer(out p: ^int; var target: int);
  begin
    p := @target;
  end;
  
  var value: int;
  var ptr: ^int;
  begin
    value := 42;
    AllocatePointer(ptr, value);
  end.
  ''';
begin
  RunCompilerTest('Pointer By Out', CSource);
end;

procedure PointerToPointerParameter();
const
  CSource =
  '''
  program Test;
  
  routine GetValue(const pp: ^^int): int;
  begin
    return pp^^;
  end;
  
  var x: int;
  var p: ^int;
  var value: int;
  begin
    x := 42;
    p := @x;
    value := GetValue(@p);
  end.
  ''';
begin
  RunCompilerTest('Pointer To Pointer Parameter', CSource);
end;

{ Complex Parameter Tests }

procedure ArrayOfRecordsParameter();
const
  CSource =
  '''
  program Test;
  type Point = record
    x: int;
    y: int;
  end;
  
  routine SumX(const points: array[0..2] of Point): int;
  var i: int;
  var total: int;
  begin
    total := 0;
    for i := 0 to 2 do
      total := total + points[i].x;
    return total;
  end;
  
  var pts: array[0..2] of Point;
  var sum: int;
  begin
    pts[0].x := 1;
    pts[1].x := 2;
    pts[2].x := 3;
    sum := SumX(pts);
  end.
  ''';
begin
  RunCompilerTest('Array Of Records Parameter', CSource);
end;

procedure RecordWithArrayParameter();
const
  CSource =
  '''
  program Test;
  type Data = record
    values: array[0..2] of int;
  end;
  
  routine GetSum(const d: Data): int;
  var i: int;
  var total: int;
  begin
    total := 0;
    for i := 0 to 2 do
      total := total + d.values[i];
    return total;
  end;
  
  var data: Data;
  var sum: int;
  begin
    data.values[0] := 10;
    data.values[1] := 20;
    data.values[2] := 30;
    sum := GetSum(data);
  end.
  ''';
begin
  RunCompilerTest('Record With Array Parameter', CSource);
end;

procedure PointerToRecordParameter();
const
  CSource =
  '''
  program Test;
  type Point = record
    x: int;
    y: int;
  end;
  
  routine ModifyPoint(const p: ^Point);
  begin
    p^.x := 100;
    p^.y := 200;
  end;
  
  var pt: Point;
  begin
    pt.x := 10;
    pt.y := 20;
    ModifyPoint(@pt);
  end.
  ''';
begin
  RunCompilerTest('Pointer To Record Parameter', CSource);
end;

procedure FunctionPointerParameter();
const
  CSource =
  '''
  program Test;
  
  routine Add(const a, b: int): int;
  begin
    return a + b;
  end;
  
  routine ApplyOp(const a, b: int; const op: ^routine(const x, y: int): int): int;
  begin
    return op^(a, b);
  end;
  
  var result: int;
  begin
    result := ApplyOp(5, 3, @Add);
  end.
  ''';
begin
  RunCompilerTest('Function Pointer Parameter', CSource);
end;

{ Parameter Edge Cases }

procedure UnusedParameter();
const
  CSource =
  '''
  program Test;
  
  routine DoSomething(const unused: int): int;
  begin
    return 42;
  end;
  
  var result: int;
  begin
    result := DoSomething(100);
  end.
  ''';
begin
  RunCompilerTest('Unused Parameter', CSource);
end;

procedure ParameterShadowsGlobal();
const
  CSource =
  '''
  program Test;
  var x: int;
  
  routine UseLocal(const x: int): int;
  begin
    return x * 2;
  end;
  
  begin
    x := 10;
    x := UseLocal(5);
  end.
  ''';
begin
  RunCompilerTest('Parameter Shadows Global', CSource);
end;

procedure ParameterModification();
const
  CSource =
  '''
  program Test;
  
  routine Modify(x: int): int;
  begin
    x := x + 10;
    return x;
  end;
  
  var value: int;
  begin
    value := 5;
    value := Modify(value);
  end.
  ''';
begin
  RunCompilerTest('Parameter Modification', CSource);
end;

procedure ConstParameterNoModify();
const
  CSource =
  '''
  program Test;
  
  routine GetValue(const x: int): int;
  begin
    return x;
  end;
  
  var value: int;
  begin
    value := GetValue(42);
  end.
  ''';
begin
  RunCompilerTest('Const Parameter No Modify', CSource);
end;

{ Variadic Parameters Tests }

procedure VariadicParameters();
const
  CSource =
  '''
  program Test;
  extern <stdio.h> routine printf(format: ^char; ...): int;
  begin
    printf("Hello %s, you are %d years old\n", "John", 25);
  end.
  ''';
begin
  RunCompilerTest('Variadic Parameters', CSource);
end;

procedure VariadicWithFixedParams();
const
  CSource =
  '''
  program Test;
  extern <stdio.h> routine printf(format: ^char; ...): int;
  var name: string;
  var age: int;
  begin
    name := "Alice";
    age := 30;
    printf("Name: %s, Age: %d\n", name, age);
  end.
  ''';
begin
  RunCompilerTest('Variadic With Fixed Params', CSource);
end;

end.
