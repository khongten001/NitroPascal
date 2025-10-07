{===============================================================================
  NitroPascal - Modern Pascal • C Performance

  Copyright © 2025-present tinyBigGAMES™ LLC
  All Rights Reserved.

  https://nitropascal.org

  See LICENSE for license information
===============================================================================}

unit UTest.Pointers;

interface

// Pointer declaration tests
procedure SimplePointerDeclaration();
procedure PointerToInt();
procedure PointerToFloat();
procedure PointerToString();
procedure PointerToRecord();

// Address-of operator tests
procedure AddressOfVariable();
procedure AddressOfArrayElement();
procedure AddressOfRecordField();

// Dereference operator tests
procedure PointerDereference();
procedure PointerDereferenceAssignment();
procedure PointerDereferenceExpression();

// Nil pointer tests
procedure NilPointer();
procedure NilPointerAssignment();
procedure NilPointerComparison();
procedure PointerNilCheck();

// Pointer arithmetic tests
procedure PointerIncrement();
procedure PointerDecrement();
procedure PointerAddition();
procedure PointerSubtraction();
procedure PointerDifference();

// Pointer to pointer tests
procedure PointerToPointer();
procedure DoublePointerDereference();
procedure PointerToPointerAssignment();

// Pointer parameter tests
procedure PointerParameterByValue();
procedure PointerParameterByConst();
procedure PointerParameterByVar();
procedure PointerReturnValue();

// Pointer to array tests
procedure PointerToArray();
procedure PointerArrayIndexing();
procedure PointerArrayIteration();

// Pointer to record tests
procedure PointerToRecordField();
procedure PointerToNestedRecord();
procedure RecordPointerAssignment();

// Function pointer tests
procedure PointerToFunction();
procedure FunctionPointerCall();
procedure FunctionPointerParameter();

// Complex pointer tests
procedure PointerInLoop();
procedure PointerInIfStatement();
procedure PointerSwap();
procedure PointerLinkedStructure();

// Type casting tests
procedure PointerTypeCast();
procedure VoidPointer();
procedure PointerConversion();

implementation

uses
  UTest.Common;

{ Pointer Declaration Tests }

procedure SimplePointerDeclaration();
const
  CSource =
  '''
  program Test;
  var x: int;
  var p: ^int;
  begin
    p := @x;
  end.
  ''';
begin
  RunCompilerTest('Simple Pointer Declaration', CSource);
end;

procedure PointerToInt();
const
  CSource =
  '''
  program Test;
  var x: int;
  var p: ^int;
  begin
    x := 42;
    p := @x;
  end.
  ''';
begin
  RunCompilerTest('Pointer To Int', CSource);
end;

procedure PointerToFloat();
const
  CSource =
  '''
  program Test;
  var f: float;
  var p: ^float;
  begin
    f := 3.14;
    p := @f;
  end.
  ''';
begin
  RunCompilerTest('Pointer To Float', CSource);
end;

procedure PointerToString();
const
  CSource =
  '''
  program Test;
  var s: string;
  var p: ^string;
  begin
    s := "Hello";
    p := @s;
  end.
  ''';
begin
  RunCompilerTest('Pointer To String', CSource);
end;

procedure PointerToRecord();
const
  CSource =
  '''
  program Test;
  type Point = record
    x: int;
    y: int;
  end;
  var pt: Point;
  var p: ^Point;
  begin
    pt.x := 10;
    pt.y := 20;
    p := @pt;
  end.
  ''';
begin
  RunCompilerTest('Pointer To Record', CSource);
end;

{ Address-Of Operator Tests }

procedure AddressOfVariable();
const
  CSource =
  '''
  program Test;
  var x: int;
  var p: ^int;
  begin
    x := 100;
    p := @x;
  end.
  ''';
begin
  RunCompilerTest('Address Of Variable', CSource);
end;

procedure AddressOfArrayElement();
const
  CSource =
  '''
  program Test;
  var arr: array[0..4] of int;
  var p: ^int;
  begin
    arr[2] := 42;
    p := @arr[2];
  end.
  ''';
begin
  RunCompilerTest('Address Of Array Element', CSource);
end;

procedure AddressOfRecordField();
const
  CSource =
  '''
  program Test;
  type Point = record
    x: int;
    y: int;
  end;
  var pt: Point;
  var p: ^int;
  begin
    pt.x := 10;
    p := @pt.x;
  end.
  ''';
begin
  RunCompilerTest('Address Of Record Field', CSource);
end;

{ Dereference Operator Tests }

procedure PointerDereference();
const
  CSource =
  '''
  program Test;
  var x: int;
  var p: ^int;
  var value: int;
  begin
    x := 42;
    p := @x;
    value := p^;
  end.
  ''';
begin
  RunCompilerTest('Pointer Dereference', CSource);
end;

procedure PointerDereferenceAssignment();
const
  CSource =
  '''
  program Test;
  var x: int;
  var p: ^int;
  begin
    x := 10;
    p := @x;
    p^ := 20;
  end.
  ''';
begin
  RunCompilerTest('Pointer Dereference Assignment', CSource);
end;

procedure PointerDereferenceExpression();
const
  CSource =
  '''
  program Test;
  var x, y: int;
  var p: ^int;
  begin
    x := 10;
    p := @x;
    y := p^ * 2 + 5;
  end.
  ''';
begin
  RunCompilerTest('Pointer Dereference Expression', CSource);
end;

{ Nil Pointer Tests }

procedure NilPointer();
const
  CSource =
  '''
  program Test;
  var p: ^int;
  begin
    p := nil;
  end.
  ''';
begin
  RunCompilerTest('Nil Pointer', CSource);
end;

procedure NilPointerAssignment();
const
  CSource =
  '''
  program Test;
  var x: int;
  var p: ^int;
  begin
    p := @x;
    p := nil;
  end.
  ''';
begin
  RunCompilerTest('Nil Pointer Assignment', CSource);
end;

procedure NilPointerComparison();
const
  CSource =
  '''
  program Test;
  var p: ^int;
  var isNil: bool;
  begin
    p := nil;
    isNil := p = nil;
  end.
  ''';
begin
  RunCompilerTest('Nil Pointer Comparison', CSource);
end;

procedure PointerNilCheck();
const
  CSource =
  '''
  program Test;
  var p: ^int;
  begin
    p := nil;
    if p <> nil then
      halt(0);
  end.
  ''';
begin
  RunCompilerTest('Pointer Nil Check', CSource);
end;

{ Pointer Arithmetic Tests }

procedure PointerIncrement();
const
  CSource =
  '''
  program Test;
  var arr: array[0..4] of int;
  var p: ^int;
  begin
    p := @arr[0];
    p := p + 1;
  end.
  ''';
begin
  RunCompilerTest('Pointer Increment', CSource);
end;

procedure PointerDecrement();
const
  CSource =
  '''
  program Test;
  var arr: array[0..4] of int;
  var p: ^int;
  begin
    p := @arr[2];
    p := p - 1;
  end.
  ''';
begin
  RunCompilerTest('Pointer Decrement', CSource);
end;

procedure PointerAddition();
const
  CSource =
  '''
  program Test;
  var arr: array[0..9] of int;
  var p: ^int;
  begin
    p := @arr[0];
    p := p + 5;
  end.
  ''';
begin
  RunCompilerTest('Pointer Addition', CSource);
end;

procedure PointerSubtraction();
const
  CSource =
  '''
  program Test;
  var arr: array[0..9] of int;
  var p: ^int;
  begin
    p := @arr[9];
    p := p - 3;
  end.
  ''';
begin
  RunCompilerTest('Pointer Subtraction', CSource);
end;

procedure PointerDifference();
const
  CSource =
  '''
  program Test;
  var arr: array[0..9] of int;
  var p1, p2: ^int;
  var diff: int;
  begin
    p1 := @arr[2];
    p2 := @arr[7];
    diff := p2 - p1;
  end.
  ''';
begin
  RunCompilerTest('Pointer Difference', CSource);
end;

{ Pointer to Pointer Tests }

procedure PointerToPointer();
const
  CSource =
  '''
  program Test;
  var x: int;
  var p: ^int;
  var pp: ^^int;
  begin
    x := 42;
    p := @x;
    pp := @p;
  end.
  ''';
begin
  RunCompilerTest('Pointer To Pointer', CSource);
end;

procedure DoublePointerDereference();
const
  CSource =
  '''
  program Test;
  var x: int;
  var p: ^int;
  var pp: ^^int;
  var value: int;
  begin
    x := 42;
    p := @x;
    pp := @p;
    value := pp^^;
  end.
  ''';
begin
  RunCompilerTest('Double Pointer Dereference', CSource);
end;

procedure PointerToPointerAssignment();
const
  CSource =
  '''
  program Test;
  var x: int;
  var p: ^int;
  var pp: ^^int;
  begin
    x := 100;
    p := @x;
    pp := @p;
    pp^^ := 200;
  end.
  ''';
begin
  RunCompilerTest('Pointer To Pointer Assignment', CSource);
end;

{ Pointer Parameter Tests }

procedure PointerParameterByValue();
const
  CSource =
  '''
  program Test;
  
  routine ModifyValue(p: ^int);
  begin
    p^ := 100;
  end;
  
  var x: int;
  begin
    x := 10;
    ModifyValue(@x);
  end.
  ''';
begin
  RunCompilerTest('Pointer Parameter By Value', CSource);
end;

procedure PointerParameterByConst();
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
  RunCompilerTest('Pointer Parameter By Const', CSource);
end;

procedure PointerParameterByVar();
const
  CSource =
  '''
  program Test;
  
  routine ChangePointer(var p: ^int; var newTarget: int);
  begin
    p := @newTarget;
  end;
  
  var x, y: int;
  var p: ^int;
  begin
    x := 10;
    y := 20;
    p := @x;
    ChangePointer(p, y);
  end.
  ''';
begin
  RunCompilerTest('Pointer Parameter By Var', CSource);
end;

procedure PointerReturnValue();
const
  CSource =
  '''
  program Test;
  
  routine GetPointer(var x: int): ^int;
  begin
    return @x;
  end;
  
  var value: int;
  var p: ^int;
  begin
    value := 42;
    p := GetPointer(value);
  end.
  ''';
begin
  RunCompilerTest('Pointer Return Value', CSource);
end;

{ Pointer to Array Tests }

procedure PointerToArray();
const
  CSource =
  '''
  program Test;
  var arr: array[0..4] of int;
  var p: ^int;
  begin
    arr[0] := 10;
    p := @arr[0];
  end.
  ''';
begin
  RunCompilerTest('Pointer To Array', CSource);
end;

procedure PointerArrayIndexing();
const
  CSource =
  '''
  program Test;
  var arr: array[0..4] of int;
  var p: ^int;
  var value: int;
  begin
    arr[2] := 42;
    p := @arr[0];
    value := (p + 2)^;
  end.
  ''';
begin
  RunCompilerTest('Pointer Array Indexing', CSource);
end;

procedure PointerArrayIteration();
const
  CSource =
  '''
  program Test;
  var arr: array[0..4] of int;
  var p: ^int;
  var i: int;
  begin
    for i := 0 to 4 do
      arr[i] := i * 10;
    p := @arr[0];
    for i := 0 to 4 do
    begin
      (p + i)^ := (p + i)^ * 2;
    end;
  end.
  ''';
begin
  RunCompilerTest('Pointer Array Iteration', CSource);
end;

{ Pointer to Record Tests }

procedure PointerToRecordField();
const
  CSource =
  '''
  program Test;
  type Point = record
    x: int;
    y: int;
  end;
  var pt: Point;
  var p: ^Point;
  var xValue: int;
  begin
    pt.x := 10;
    pt.y := 20;
    p := @pt;
    xValue := p^.x;
  end.
  ''';
begin
  RunCompilerTest('Pointer To Record Field', CSource);
end;

procedure PointerToNestedRecord();
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
  var obj: Outer;
  var p: ^Outer;
  begin
    obj.inner.value := 42;
    p := @obj;
    p^.inner.value := 100;
  end.
  ''';
begin
  RunCompilerTest('Pointer To Nested Record', CSource);
end;

procedure RecordPointerAssignment();
const
  CSource =
  '''
  program Test;
  type Point = record
    x: int;
    y: int;
  end;
  var pt: Point;
  var p: ^Point;
  begin
    pt.x := 10;
    pt.y := 20;
    p := @pt;
    p^.x := 30;
    p^.y := 40;
  end.
  ''';
begin
  RunCompilerTest('Record Pointer Assignment', CSource);
end;

{ Function Pointer Tests }

procedure PointerToFunction();
const
  CSource =
  '''
  program Test;
  
  routine Add(const a, b: int): int;
  begin
    return a + b;
  end;
  
  var fp: ^routine(const a, b: int): int;
  begin
    fp := @Add;
  end.
  ''';
begin
  RunCompilerTest('Pointer To Function', CSource);
end;

procedure FunctionPointerCall();
const
  CSource =
  '''
  program Test;
  
  routine Multiply(const a, b: int): int;
  begin
    return a * b;
  end;
  
  var fp: ^routine(const a, b: int): int;
  var result: int;
  begin
    fp := @Multiply;
    result := fp^(5, 3);
  end.
  ''';
begin
  RunCompilerTest('Function Pointer Call', CSource);
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
  
  routine ApplyOperation(const a, b: int; op: ^routine(const x, y: int): int): int;
  begin
    return op^(a, b);
  end;
  
  var result: int;
  begin
    result := ApplyOperation(10, 5, @Add);
  end.
  ''';
begin
  RunCompilerTest('Function Pointer Parameter', CSource);
end;

{ Complex Pointer Tests }

procedure PointerInLoop();
const
  CSource =
  '''
  program Test;
  var arr: array[0..9] of int;
  var p: ^int;
  var i: int;
  begin
    p := @arr[0];
    for i := 0 to 9 do
    begin
      (p + i)^ := i;
    end;
  end.
  ''';
begin
  RunCompilerTest('Pointer In Loop', CSource);
end;

procedure PointerInIfStatement();
const
  CSource =
  '''
  program Test;
  var x: int;
  var p: ^int;
  begin
    x := 10;
    p := @x;
    if p <> nil then
      p^ := 20;
  end.
  ''';
begin
  RunCompilerTest('Pointer In If Statement', CSource);
end;

procedure PointerSwap();
const
  CSource =
  '''
  program Test;
  
  routine Swap(var a, b: int);
  var temp: int;
  begin
    temp := a;
    a := b;
    b := temp;
  end;
  
  var x, y: int;
  begin
    x := 10;
    y := 20;
    Swap(x, y);
  end.
  ''';
begin
  RunCompilerTest('Pointer Swap', CSource);
end;

procedure PointerLinkedStructure();
const
  CSource =
  '''
  program Test;
  type Node = record
    value: int;
    next: ^Node;
  end;
  var node1, node2: Node;
  begin
    node1.value := 10;
    node2.value := 20;
    node1.next := @node2;
    node2.next := nil;
  end.
  ''';
begin
  RunCompilerTest('Pointer Linked Structure', CSource);
end;

{ Type Casting Tests }

procedure PointerTypeCast();
const
  CSource =
  '''
  program Test;
  var x: int;
  var pi: ^int;
  var pf: ^float;
  begin
    x := 42;
    pi := @x;
    pf := ^float(pi);
  end.
  ''';
begin
  RunCompilerTest('Pointer Type Cast', CSource);
end;

procedure VoidPointer();
const
  CSource =
  '''
  program Test;
  var x: int;
  var p: ^void;
  begin
    x := 42;
    p := @x;
  end.
  ''';
begin
  RunCompilerTest('Void Pointer', CSource);
end;

procedure PointerConversion();
const
  CSource =
  '''
  program Test;
  var x: int;
  var p: ^int;
  var pv: ^void;
  begin
    x := 42;
    p := @x;
    pv := ^void(p);
    p := ^int(pv);
  end.
  ''';
begin
  RunCompilerTest('Pointer Conversion', CSource);
end;

end.
