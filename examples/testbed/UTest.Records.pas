{===============================================================================
  NitroPascal - Modern Pascal • C Performance

  Copyright © 2025-present tinyBigGAMES™ LLC
  All Rights Reserved.

  https://nitropascal.org

  See LICENSE for license information
===============================================================================}

unit UTest.Records;

interface

// Record declaration tests
procedure SimpleRecordDeclaration();
procedure RecordWithMultipleFields();
procedure RecordWithMixedTypes();
procedure RecordWithString();
procedure RecordWithArray();

// Record field access tests
procedure RecordFieldAccess();
procedure RecordFieldAssignment();
procedure RecordNestedFieldAccess();
procedure RecordFieldExpression();

// Record operations tests
procedure RecordCopy();
procedure RecordComparison();
procedure RecordInLoop();
procedure RecordInitialization();

// Nested record tests
procedure NestedRecord();
procedure DeepNestedRecord();
procedure NestedRecordAccess();
procedure NestedRecordAssignment();

// Record parameter tests
procedure RecordParameterByValue();
procedure RecordParameterByConst();
procedure RecordParameterByVar();
procedure RecordReturnValue();

// Record with arrays tests
procedure RecordContainingArray();
procedure ArrayOfRecords();
procedure RecordWithMultiDimArray();

// Record methods tests (if supported)
procedure RecordWithRoutine();
procedure RecordMethodCall();

// Complex record tests
procedure RecordInIfStatement();
procedure RecordInWhileLoop();
procedure RecordInFunction();
procedure RecordComplexNesting();

// Record initialization tests
procedure RecordStaticInitialization();
procedure RecordRuntimeInitialization();
procedure RecordPartialInitialization();

// Record pointer tests
procedure PointerToRecord();
procedure RecordPointerDereference();
procedure RecordPointerFieldAccess();

implementation

uses
  UTest.Common;

{ Record Declaration Tests }

procedure SimpleRecordDeclaration();
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
  RunCompilerTest('Simple Record Declaration', CSource);
end;

procedure RecordWithMultipleFields();
const
  CSource =
  '''
  program Test;
  type Person = record
    age: int;
    height: float;
    isAdult: bool;
  end;
  var person: Person;
  begin
    person.age := 25;
    person.height := 1.75;
    person.isAdult := true;
  end.
  ''';
begin
  RunCompilerTest('Record With Multiple Fields', CSource);
end;

procedure RecordWithMixedTypes();
const
  CSource =
  '''
  program Test;
  type Data = record
    id: int;
    value: float;
    flag: bool;
    name: string;
  end;
  var data: Data;
  begin
    data.id := 1;
    data.value := 3.14;
    data.flag := true;
    data.name := "Test";
  end.
  ''';
begin
  RunCompilerTest('Record With Mixed Types', CSource);
end;

procedure RecordWithString();
const
  CSource =
  '''
  program Test;
  type User = record
    username: string;
    email: string;
  end;
  var user: User;
  begin
    user.username := "john_doe";
    user.email := "john@example.com";
  end.
  ''';
begin
  RunCompilerTest('Record With String', CSource);
end;

procedure RecordWithArray();
const
  CSource =
  '''
  program Test;
  type Stats = record
    values: array[0..2] of int;
  end;
  var stats: Stats;
  begin
    stats.values[0] := 10;
    stats.values[1] := 20;
    stats.values[2] := 30;
  end.
  ''';
begin
  RunCompilerTest('Record With Array', CSource);
end;

{ Record Field Access Tests }

procedure RecordFieldAccess();
const
  CSource =
  '''
  program Test;
  type Point = record
    x: int;
    y: int;
  end;
  var p: Point;
  var xVal: int;
  begin
    p.x := 42;
    xVal := p.x;
  end.
  ''';
begin
  RunCompilerTest('Record Field Access', CSource);
end;

procedure RecordFieldAssignment();
const
  CSource =
  '''
  program Test;
  type Rectangle = record
    width: int;
    height: int;
  end;
  var rect: Rectangle;
  begin
    rect.width := 100;
    rect.height := 50;
  end.
  ''';
begin
  RunCompilerTest('Record Field Assignment', CSource);
end;

procedure RecordNestedFieldAccess();
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
  begin
    obj.inner.value := 42;
  end.
  ''';
begin
  RunCompilerTest('Record Nested Field Access', CSource);
end;

procedure RecordFieldExpression();
const
  CSource =
  '''
  program Test;
  type Point = record
    x: int;
    y: int;
  end;
  var p1, p2: Point;
  var distance: int;
  begin
    p1.x := 10;
    p1.y := 20;
    p2.x := 30;
    p2.y := 40;
    distance := (p2.x - p1.x) + (p2.y - p1.y);
  end.
  ''';
begin
  RunCompilerTest('Record Field Expression', CSource);
end;

{ Record Operations Tests }

procedure RecordCopy();
const
  CSource =
  '''
  program Test;
  type Point = record
    x: int;
    y: int;
  end;
  var p1, p2: Point;
  begin
    p1.x := 10;
    p1.y := 20;
    p2 := p1;
  end.
  ''';
begin
  RunCompilerTest('Record Copy', CSource);
end;

procedure RecordComparison();
const
  CSource =
  '''
  program Test;
  type Point = record
    x: int;
    y: int;
  end;
  var p1, p2: Point;
  var equal: bool;
  begin
    p1.x := 10;
    p1.y := 20;
    p2.x := 10;
    p2.y := 20;
    equal := (p1.x = p2.x) and (p1.y = p2.y);
  end.
  ''';
begin
  RunCompilerTest('Record Comparison', CSource);
end;

procedure RecordInLoop();
const
  CSource =
  '''
  program Test;
  type Counter = record
    value: int;
  end;
  var counter: Counter;
  var i: int;
  begin
    counter.value := 0;
    for i := 1 to 10 do
      counter.value := counter.value + 1;
  end.
  ''';
begin
  RunCompilerTest('Record In Loop', CSource);
end;

procedure RecordInitialization();
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
    p.x := 0;
    p.y := 0;
  end.
  ''';
begin
  RunCompilerTest('Record Initialization', CSource);
end;

{ Nested Record Tests }

procedure NestedRecord();
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
    person.address.city := "New York";
  end.
  ''';
begin
  RunCompilerTest('Nested Record', CSource);
end;

procedure DeepNestedRecord();
const
  CSource =
  '''
  program Test;
  type Level3 = record
    value: int;
  end;
  type Level2 = record
    level3: Level3;
  end;
  type Level1 = record
    level2: Level2;
  end;
  var obj: Level1;
  begin
    obj.level2.level3.value := 42;
  end.
  ''';
begin
  RunCompilerTest('Deep Nested Record', CSource);
end;

procedure NestedRecordAccess();
const
  CSource =
  '''
  program Test;
  type Inner = record
    x: int;
    y: int;
  end;
  type Outer = record
    inner: Inner;
    z: int;
  end;
  var obj: Outer;
  var sum: int;
  begin
    obj.inner.x := 10;
    obj.inner.y := 20;
    obj.z := 30;
    sum := obj.inner.x + obj.inner.y + obj.z;
  end.
  ''';
begin
  RunCompilerTest('Nested Record Access', CSource);
end;

procedure NestedRecordAssignment();
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
  var obj1, obj2: Outer;
  begin
    obj1.inner.value := 42;
    obj2 := obj1;
  end.
  ''';
begin
  RunCompilerTest('Nested Record Assignment', CSource);
end;

{ Record Parameter Tests }

procedure RecordParameterByValue();
const
  CSource =
  '''
  program Test;
  type Point = record
    x: int;
    y: int;
  end;
  
  routine ProcessPoint(p: Point);
  begin
    p.x := p.x * 2;
    p.y := p.y * 2;
  end;
  
  var point: Point;
  begin
    point.x := 10;
    point.y := 20;
    ProcessPoint(point);
  end.
  ''';
begin
  RunCompilerTest('Record Parameter By Value', CSource);
end;

procedure RecordParameterByConst();
const
  CSource =
  '''
  program Test;
  type Point = record
    x: int;
    y: int;
  end;
  
  routine GetDistance(const p: Point): int;
  begin
    return p.x + p.y;
  end;
  
  var point: Point;
  var dist: int;
  begin
    point.x := 10;
    point.y := 20;
    dist := GetDistance(point);
  end.
  ''';
begin
  RunCompilerTest('Record Parameter By Const', CSource);
end;

procedure RecordParameterByVar();
const
  CSource =
  '''
  program Test;
  type Point = record
    x: int;
    y: int;
  end;
  
  routine ModifyPoint(var p: Point);
  begin
    p.x := p.x * 2;
    p.y := p.y * 2;
  end;
  
  var point: Point;
  begin
    point.x := 10;
    point.y := 20;
    ModifyPoint(point);
  end.
  ''';
begin
  RunCompilerTest('Record Parameter By Var', CSource);
end;

procedure RecordReturnValue();
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
  
  var point: Point;
  begin
    point := CreatePoint(10, 20);
  end.
  ''';
begin
  RunCompilerTest('Record Return Value', CSource);
end;

{ Record with Arrays Tests }

procedure RecordContainingArray();
const
  CSource =
  '''
  program Test;
  type Vector = record
    components: array[0..2] of float;
  end;
  var v: Vector;
  begin
    v.components[0] := 1.0;
    v.components[1] := 2.0;
    v.components[2] := 3.0;
  end.
  ''';
begin
  RunCompilerTest('Record Containing Array', CSource);
end;

procedure ArrayOfRecords();
const
  CSource =
  '''
  program Test;
  type Point = record
    x: int;
    y: int;
  end;
  var points: array[0..2] of Point;
  begin
    points[0].x := 1;
    points[0].y := 2;
    points[1].x := 3;
    points[1].y := 4;
    points[2].x := 5;
    points[2].y := 6;
  end.
  ''';
begin
  RunCompilerTest('Array Of Records', CSource);
end;

procedure RecordWithMultiDimArray();
const
  CSource =
  '''
  program Test;
  type Matrix = record
    data: array[0..1, 0..1] of int;
  end;
  var m: Matrix;
  begin
    m.data[0, 0] := 1;
    m.data[0, 1] := 2;
    m.data[1, 0] := 3;
    m.data[1, 1] := 4;
  end.
  ''';
begin
  RunCompilerTest('Record With Multi Dim Array', CSource);
end;

{ Record Methods Tests }

procedure RecordWithRoutine();
const
  CSource =
  '''
  program Test;
  type Point = record
    x: int;
    y: int;
  end;
  
  routine PointDistance(const p: Point): int;
  begin
    return p.x + p.y;
  end;
  
  var p: Point;
  var dist: int;
  begin
    p.x := 3;
    p.y := 4;
    dist := PointDistance(p);
  end.
  ''';
begin
  RunCompilerTest('Record With Routine', CSource);
end;

procedure RecordMethodCall();
const
  CSource =
  '''
  program Test;
  type Counter = record
    value: int;
  end;
  
  routine IncrementCounter(var c: Counter);
  begin
    c.value := c.value + 1;
  end;
  
  var counter: Counter;
  begin
    counter.value := 0;
    IncrementCounter(counter);
  end.
  ''';
begin
  RunCompilerTest('Record Method Call', CSource);
end;

{ Complex Record Tests }

procedure RecordInIfStatement();
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
    if p.x > 5 then
      p.y := p.y * 2;
  end.
  ''';
begin
  RunCompilerTest('Record In If Statement', CSource);
end;

procedure RecordInWhileLoop();
const
  CSource =
  '''
  program Test;
  type Counter = record
    value: int;
  end;
  var counter: Counter;
  begin
    counter.value := 0;
    while counter.value < 10 do
      counter.value := counter.value + 1;
  end.
  ''';
begin
  RunCompilerTest('Record In While Loop', CSource);
end;

procedure RecordInFunction();
const
  CSource =
  '''
  program Test;
  type Rectangle = record
    width: int;
    height: int;
  end;
  
  routine CalculateArea(const r: Rectangle): int;
  begin
    return r.width * r.height;
  end;
  
  var rect: Rectangle;
  var area: int;
  begin
    rect.width := 10;
    rect.height := 5;
    area := CalculateArea(rect);
  end.
  ''';
begin
  RunCompilerTest('Record In Function', CSource);
end;

procedure RecordComplexNesting();
const
  CSource =
  '''
  program Test;
  type Point = record
    x: int;
    y: int;
  end;
  type Line = record
    start: Point;
    finish: Point;
  end;
  type Shape = record
    edges: array[0..1] of Line;
  end;
  var shape: Shape;
  begin
    shape.edges[0].start.x := 0;
    shape.edges[0].start.y := 0;
    shape.edges[0].finish.x := 10;
    shape.edges[0].finish.y := 10;
  end.
  ''';
begin
  RunCompilerTest('Record Complex Nesting', CSource);
end;

{ Record Initialization Tests }

procedure RecordStaticInitialization();
const
  CSource =
  '''
  program Test;
  type Point = record
    x: int;
    y: int;
  end;
  const origin: Point = (x: 0; y: 0);
  begin
    halt(0);
  end.
  ''';
begin
  RunCompilerTest('Record Static Initialization', CSource);
end;

procedure RecordRuntimeInitialization();
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
  RunCompilerTest('Record Runtime Initialization', CSource);
end;

procedure RecordPartialInitialization();
const
  CSource =
  '''
  program Test;
  type Data = record
    a: int;
    b: int;
    c: int;
  end;
  var data: Data;
  begin
    data.a := 1;
    data.c := 3;
  end.
  ''';
begin
  RunCompilerTest('Record Partial Initialization', CSource);
end;

{ Record Pointer Tests }

procedure PointerToRecord();
const
  CSource =
  '''
  program Test;
  type Point = record
    x: int;
    y: int;
  end;
  var p: Point;
  var ptr: ^Point;
  begin
    p.x := 10;
    p.y := 20;
    ptr := @p;
  end.
  ''';
begin
  RunCompilerTest('Pointer To Record', CSource);
end;

procedure RecordPointerDereference();
const
  CSource =
  '''
  program Test;
  type Point = record
    x: int;
    y: int;
  end;
  var p: Point;
  var ptr: ^Point;
  var value: int;
  begin
    p.x := 42;
    ptr := @p;
    value := ptr^.x;
  end.
  ''';
begin
  RunCompilerTest('Record Pointer Dereference', CSource);
end;

procedure RecordPointerFieldAccess();
const
  CSource =
  '''
  program Test;
  type Point = record
    x: int;
    y: int;
  end;
  var p: Point;
  var ptr: ^Point;
  begin
    p.x := 10;
    p.y := 20;
    ptr := @p;
    ptr^.x := 30;
    ptr^.y := 40;
  end.
  ''';
begin
  RunCompilerTest('Record Pointer Field Access', CSource);
end;

end.
