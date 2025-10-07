{===============================================================================
  NitroPascal - Modern Pascal • C Performance

  Copyright © 2025-present tinyBigGAMES™ LLC
  All Rights Reserved.

  https://nitropascal.org

  See LICENSE for license information
===============================================================================}

unit UTest.CodeGen;

interface

// Basic code generation tests
procedure SimpleProgramCodeGen();
procedure ProgramWithVariables();
procedure ProgramWithRoutine();

// Module code generation
procedure SimpleModuleCodeGen();
procedure ModuleWithPublicRoutines();
procedure ModuleWithTypes();
procedure ModuleVisibilityTest();

// Library code generation
procedure SimpleLibraryCodeGen();
procedure LibraryWithExports();

// Expression code generation
procedure ArithmeticExpression();
procedure BooleanExpression();

// Statement code generation
procedure IfStatementCodeGen();
procedure WhileLoopCodeGen();
procedure ForLoopCodeGen();

implementation

uses
  UTest.Common;

procedure SimpleProgramCodeGen();
const
  CSource =
  '''
  program Hello;
  begin
    halt(0);
  end.
  ''';
begin
  RunCompilerTest('Simple Program CodeGen', CSource);
end;

procedure ProgramWithVariables();
const
  CSource =
  '''
  program Test;
  var x, y: int;
  begin
    x := 5;
    y := 10;
  end.
  ''';
begin
  RunCompilerTest('Program With Variables', CSource);
end;

procedure ProgramWithRoutine();
const
  CSource =
  '''
  program Test;
  routine Add(const a, b: int): int;
  begin
    return a + b;
  end;
  begin
  end.
  ''';
begin
  RunCompilerTest('Program With Routine', CSource);
end;

procedure ArithmeticExpression();
const
  CSource =
  '''
  program Test;
  var result: int;
  begin
    result := (5 + 3) * 2 - 1;
  end.
  ''';
begin
  RunCompilerTest('Arithmetic Expression', CSource);
end;

procedure BooleanExpression();
const
  CSource =
  '''
  program Test;
  var flag: bool;
  begin
    flag := (5 > 3) and (10 < 20);
  end.
  ''';
begin
  RunCompilerTest('Boolean Expression', CSource);
end;

procedure IfStatementCodeGen();
const
  CSource =
  '''
  program Test;
  var x: int;
  begin
    if x > 0 then
      x := 1
    else
      x := 0;
  end.
  ''';
begin
  RunCompilerTest('If Statement CodeGen', CSource);
end;

procedure WhileLoopCodeGen();
const
  CSource =
  '''
  program Test;
  var i: int;
  begin
    i := 0;
    while i < 10 do
      i := i + 1;
  end.
  ''';
begin
  RunCompilerTest('While Loop CodeGen', CSource);
end;

procedure ForLoopCodeGen();
const
  CSource =
  '''
  program Test;
  var i: int;
  begin
    for i := 1 to 10 do
      halt(0);
  end.
  ''';
begin
  RunCompilerTest('For Loop CodeGen', CSource);
end;

procedure SimpleModuleCodeGen();
const
  CSource =
  '''
  module Math;
  
  public routine Square(const x: int): int;
  begin
    return x * x;
  end;
  
  end.
  ''';
begin
  RunCompilerTest('Simple Module CodeGen', CSource);
end;

procedure ModuleWithPublicRoutines();
const
  CSource =
  '''
  module Calculator;
  
  public routine Add(const a, b: int): int;
  begin
    return a + b;
  end;
  
  public routine Multiply(const a, b: int): int;
  begin
    return a * b;
  end;
  
  routine PrivateHelper(const x: int): int;
  begin
    return x + 1;
  end;
  
  end.
  ''';
begin
  RunCompilerTest('Module With Public Routines', CSource);
end;

procedure ModuleWithTypes();
const
  CSource =
  '''
  module Types;
  
  const MAX_SIZE: int = 100;
  
  var counter: int;
  
  public routine GetCounter(): int;
  begin
    return counter;
  end;
  
  public routine IncrementCounter();
  begin
    counter := counter + 1;
  end;
  
  end.
  ''';
begin
  RunCompilerTest('Module With Types', CSource);
end;

procedure ModuleVisibilityTest();
const
  CSource =
  '''
  module Visibility;
  
  // This should appear in the header
  public routine PublicFunction(const x: int): int;
  begin
    return PrivateHelper(x) + 10;
  end;
  
  // This should NOT appear in the header (only in cpp)
  routine PrivateHelper(const x: int): int;
  begin
    return x * 2;
  end;
  
  // Another public function
  public routine AnotherPublic(): int;
  begin
    return 42;
  end;
  
  // Another private function
  routine AnotherPrivate(): int;
  begin
    return 99;
  end;
  
  end.
  ''';
begin
  RunCompilerTest('Module Visibility Test (Public vs Private)', CSource);
end;

procedure SimpleLibraryCodeGen();
const
  CSource =
  '''
  library MyLib;
  
  public routine LibVersion(): int;
  begin
    return 1;
  end;
  
  end.
  ''';
begin
  RunCompilerTest('Simple Library CodeGen', CSource);
end;

procedure LibraryWithExports();
const
  CSource =
  '''
  library MathLib;
  
  public routine Add(const a, b: int): int;
  begin
    return a + b;
  end;
  
  public routine Subtract(const a, b: int): int;
  begin
    return a - b;
  end;
  
  public routine Multiply(const a, b: int): int;
  begin
    return a * b;
  end;
  
  end.
  ''';
begin
  RunCompilerTest('Library With Exports', CSource);
end;

end.
