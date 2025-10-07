{===============================================================================
  NitroPascal - Modern Pascal • C Performance

  Copyright © 2025-present tinyBigGAMES™ LLC
  All Rights Reserved.

  https://nitropascal.org

  See LICENSE for license information
===============================================================================}

unit UTest.Arrays;

interface

// Array declaration tests
procedure SimpleArrayDeclaration();
procedure ArrayWithInitialization();
procedure MultiDimensionalArray();
procedure ArrayOfStrings();
procedure ArrayOfFloats();

// Array indexing tests
procedure ArrayIndexing();
procedure ArrayIndexAssignment();
procedure ArrayIndexExpression();
procedure ArrayNegativeIndex();

// Array operations tests
procedure ArrayCopy();
procedure ArrayComparison();
procedure ArrayInLoop();
procedure ArrayIteration();

// Multi-dimensional array tests
procedure TwoDimensionalArray();
procedure ThreeDimensionalArray();
procedure MultiDimIndexing();
procedure MultiDimAssignment();

// Array parameter tests
procedure ArrayParameterByValue();
procedure ArrayParameterByConst();
procedure ArrayParameterByVar();
procedure ArrayReturnValue();

// Array bounds tests
procedure ArrayLowerBound();
procedure ArrayUpperBound();
procedure ArrayLength();
procedure ArrayDynamicSize();

// Array in structures tests
procedure ArrayInRecord();
procedure ArrayOfRecords();
procedure NestedArrays();

// Array initialization tests
procedure ArrayStaticInitialization();
procedure ArrayZeroInitialization();
procedure ArrayRuntimeInitialization();

// Complex array tests
procedure ArrayArithmetic();
procedure ArrayStringConcatenation();
procedure ArrayMixedTypes();
procedure ArrayInIfStatement();
procedure ArrayInFunction();

implementation

uses
  UTest.Common;

{ Array Declaration Tests }

procedure SimpleArrayDeclaration();
const
  CSource =
  '''
  program Test;
  var arr: array[0..4] of int;
  begin
    arr[0] := 1;
  end.
  ''';
begin
  RunCompilerTest('Simple Array Declaration', CSource);
end;

procedure ArrayWithInitialization();
const
  CSource =
  '''
  program Test;
  const arr: array[0..2] of int = (1, 2, 3);
  begin
    halt(0);
  end.
  ''';
begin
  RunCompilerTest('Array With Initialization', CSource);
end;

procedure MultiDimensionalArray();
const
  CSource =
  '''
  program Test;
  var matrix: array[0..1, 0..1] of int;
  begin
    matrix[0, 0] := 1;
  end.
  ''';
begin
  RunCompilerTest('Multi Dimensional Array', CSource);
end;

procedure ArrayOfStrings();
const
  CSource =
  '''
  program Test;
  var names: array[0..2] of string;
  begin
    names[0] := "Alice";
    names[1] := "Bob";
    names[2] := "Charlie";
  end.
  ''';
begin
  RunCompilerTest('Array Of Strings', CSource);
end;

procedure ArrayOfFloats();
const
  CSource =
  '''
  program Test;
  var values: array[0..3] of float;
  begin
    values[0] := 1.5;
    values[1] := 2.7;
    values[2] := 3.14;
  end.
  ''';
begin
  RunCompilerTest('Array Of Floats', CSource);
end;

{ Array Indexing Tests }

procedure ArrayIndexing();
const
  CSource =
  '''
  program Test;
  var arr: array[0..4] of int;
  var x: int;
  begin
    arr[2] := 42;
    x := arr[2];
  end.
  ''';
begin
  RunCompilerTest('Array Indexing', CSource);
end;

procedure ArrayIndexAssignment();
const
  CSource =
  '''
  program Test;
  var arr: array[0..4] of int;
  begin
    arr[0] := 10;
    arr[1] := 20;
    arr[2] := 30;
    arr[3] := 40;
    arr[4] := 50;
  end.
  ''';
begin
  RunCompilerTest('Array Index Assignment', CSource);
end;

procedure ArrayIndexExpression();
const
  CSource =
  '''
  program Test;
  var arr: array[0..9] of int;
  var i: int;
  begin
    i := 2;
    arr[i + 1] := 100;
  end.
  ''';
begin
  RunCompilerTest('Array Index Expression', CSource);
end;

procedure ArrayNegativeIndex();
const
  CSource =
  '''
  program Test;
  var arr: array[-2..2] of int;
  begin
    arr[-2] := 1;
    arr[-1] := 2;
    arr[0] := 3;
    arr[1] := 4;
    arr[2] := 5;
  end.
  ''';
begin
  RunCompilerTest('Array Negative Index', CSource);
end;

{ Array Operations Tests }

procedure ArrayCopy();
const
  CSource =
  '''
  program Test;
  var arr1, arr2: array[0..2] of int;
  var i: int;
  begin
    arr1[0] := 1;
    arr1[1] := 2;
    arr1[2] := 3;
    for i := 0 to 2 do
      arr2[i] := arr1[i];
  end.
  ''';
begin
  RunCompilerTest('Array Copy', CSource);
end;

procedure ArrayComparison();
const
  CSource =
  '''
  program Test;
  var arr: array[0..2] of int;
  var equal: bool;
  begin
    arr[0] := 5;
    equal := arr[0] = 5;
  end.
  ''';
begin
  RunCompilerTest('Array Comparison', CSource);
end;

procedure ArrayInLoop();
const
  CSource =
  '''
  program Test;
  var arr: array[0..9] of int;
  var i: int;
  begin
    for i := 0 to 9 do
      arr[i] := i * 2;
  end.
  ''';
begin
  RunCompilerTest('Array In Loop', CSource);
end;

procedure ArrayIteration();
const
  CSource =
  '''
  program Test;
  var arr: array[0..4] of int;
  var i: int;
  var sum: int;
  begin
    arr[0] := 1;
    arr[1] := 2;
    arr[2] := 3;
    arr[3] := 4;
    arr[4] := 5;
    sum := 0;
    for i := 0 to 4 do
      sum := sum + arr[i];
  end.
  ''';
begin
  RunCompilerTest('Array Iteration', CSource);
end;

{ Multi-Dimensional Array Tests }

procedure TwoDimensionalArray();
const
  CSource =
  '''
  program Test;
  var matrix: array[0..2, 0..2] of int;
  begin
    matrix[0, 0] := 1;
    matrix[0, 1] := 2;
    matrix[1, 0] := 3;
    matrix[1, 1] := 4;
  end.
  ''';
begin
  RunCompilerTest('Two Dimensional Array', CSource);
end;

procedure ThreeDimensionalArray();
const
  CSource =
  '''
  program Test;
  var cube: array[0..1, 0..1, 0..1] of int;
  begin
    cube[0, 0, 0] := 1;
    cube[0, 0, 1] := 2;
    cube[1, 1, 1] := 8;
  end.
  ''';
begin
  RunCompilerTest('Three Dimensional Array', CSource);
end;

procedure MultiDimIndexing();
const
  CSource =
  '''
  program Test;
  var matrix: array[0..2, 0..2] of int;
  var i, j: int;
  begin
    i := 1;
    j := 2;
    matrix[i, j] := 42;
  end.
  ''';
begin
  RunCompilerTest('Multi Dim Indexing', CSource);
end;

procedure MultiDimAssignment();
const
  CSource =
  '''
  program Test;
  var matrix: array[0..2, 0..2] of int;
  var i, j: int;
  begin
    for i := 0 to 2 do
      for j := 0 to 2 do
        matrix[i, j] := i * 10 + j;
  end.
  ''';
begin
  RunCompilerTest('Multi Dim Assignment', CSource);
end;

{ Array Parameter Tests }

procedure ArrayParameterByValue();
const
  CSource =
  '''
  program Test;
  
  routine ProcessArray(arr: array[0..2] of int);
  var i: int;
  begin
    for i := 0 to 2 do
      arr[i] := arr[i] * 2;
  end;
  
  var myArray: array[0..2] of int;
  begin
    myArray[0] := 1;
    myArray[1] := 2;
    myArray[2] := 3;
    ProcessArray(myArray);
  end.
  ''';
begin
  RunCompilerTest('Array Parameter By Value', CSource);
end;

procedure ArrayParameterByConst();
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
  
  var myArray: array[0..4] of int;
  var sum: int;
  begin
    myArray[0] := 1;
    myArray[1] := 2;
    myArray[2] := 3;
    myArray[3] := 4;
    myArray[4] := 5;
    sum := SumArray(myArray);
  end.
  ''';
begin
  RunCompilerTest('Array Parameter By Const', CSource);
end;

procedure ArrayParameterByVar();
const
  CSource =
  '''
  program Test;
  
  routine FillArray(var arr: array[0..2] of int);
  var i: int;
  begin
    for i := 0 to 2 do
      arr[i] := i * 10;
  end;
  
  var myArray: array[0..2] of int;
  begin
    FillArray(myArray);
  end.
  ''';
begin
  RunCompilerTest('Array Parameter By Var', CSource);
end;

procedure ArrayReturnValue();
const
  CSource =
  '''
  program Test;
  
  routine CreateArray(): array[0..2] of int;
  var arr: array[0..2] of int;
  begin
    arr[0] := 1;
    arr[1] := 2;
    arr[2] := 3;
    return arr;
  end;
  
  var myArray: array[0..2] of int;
  begin
    myArray := CreateArray();
  end.
  ''';
begin
  RunCompilerTest('Array Return Value', CSource);
end;

{ Array Bounds Tests }

procedure ArrayLowerBound();
const
  CSource =
  '''
  program Test;
  var arr: array[5..9] of int;
  begin
    arr[5] := 100;
  end.
  ''';
begin
  RunCompilerTest('Array Lower Bound', CSource);
end;

procedure ArrayUpperBound();
const
  CSource =
  '''
  program Test;
  var arr: array[0..9] of int;
  begin
    arr[9] := 100;
  end.
  ''';
begin
  RunCompilerTest('Array Upper Bound', CSource);
end;

procedure ArrayLength();
const
  CSource =
  '''
  program Test;
  var arr: array[0..9] of int;
  var len: int;
  begin
    len := 10;
  end.
  ''';
begin
  RunCompilerTest('Array Length', CSource);
end;

procedure ArrayDynamicSize();
const
  CSource =
  '''
  program Test;
  const SIZE: int = 5;
  var arr: array[0..SIZE] of int;
  begin
    arr[SIZE] := 42;
  end.
  ''';
begin
  RunCompilerTest('Array Dynamic Size', CSource);
end;

{ Array in Structures Tests }

procedure ArrayInRecord();
const
  CSource =
  '''
  program Test;
  type Point = record
    coords: array[0..2] of float;
  end;
  var p: Point;
  begin
    p.coords[0] := 1.0;
    p.coords[1] := 2.0;
    p.coords[2] := 3.0;
  end.
  ''';
begin
  RunCompilerTest('Array In Record', CSource);
end;

procedure ArrayOfRecords();
const
  CSource =
  '''
  program Test;
  type Person = record
    age: int;
  end;
  var people: array[0..2] of Person;
  begin
    people[0].age := 25;
    people[1].age := 30;
    people[2].age := 35;
  end.
  ''';
begin
  RunCompilerTest('Array Of Records', CSource);
end;

procedure NestedArrays();
const
  CSource =
  '''
  program Test;
  type Matrix = array[0..1] of array[0..1] of int;
  var m: Matrix;
  begin
    m[0][0] := 1;
    m[0][1] := 2;
    m[1][0] := 3;
    m[1][1] := 4;
  end.
  ''';
begin
  RunCompilerTest('Nested Arrays', CSource);
end;

{ Array Initialization Tests }

procedure ArrayStaticInitialization();
const
  CSource =
  '''
  program Test;
  const arr: array[0..4] of int = (10, 20, 30, 40, 50);
  begin
    halt(0);
  end.
  ''';
begin
  RunCompilerTest('Array Static Initialization', CSource);
end;

procedure ArrayZeroInitialization();
const
  CSource =
  '''
  program Test;
  var arr: array[0..9] of int;
  var i: int;
  begin
    for i := 0 to 9 do
      arr[i] := 0;
  end.
  ''';
begin
  RunCompilerTest('Array Zero Initialization', CSource);
end;

procedure ArrayRuntimeInitialization();
const
  CSource =
  '''
  program Test;
  var arr: array[0..4] of int;
  var i: int;
  begin
    for i := 0 to 4 do
      arr[i] := i + 1;
  end.
  ''';
begin
  RunCompilerTest('Array Runtime Initialization', CSource);
end;

{ Complex Array Tests }

procedure ArrayArithmetic();
const
  CSource =
  '''
  program Test;
  var arr1, arr2, result: array[0..2] of int;
  var i: int;
  begin
    arr1[0] := 1;
    arr1[1] := 2;
    arr1[2] := 3;
    arr2[0] := 4;
    arr2[1] := 5;
    arr2[2] := 6;
    for i := 0 to 2 do
      result[i] := arr1[i] + arr2[i];
  end.
  ''';
begin
  RunCompilerTest('Array Arithmetic', CSource);
end;

procedure ArrayStringConcatenation();
const
  CSource =
  '''
  program Test;
  var words: array[0..2] of string;
  var sentence: string;
  var i: int;
  begin
    words[0] := "Hello";
    words[1] := " ";
    words[2] := "World";
    sentence := "";
    for i := 0 to 2 do
      sentence := sentence + words[i];
  end.
  ''';
begin
  RunCompilerTest('Array String Concatenation', CSource);
end;

procedure ArrayMixedTypes();
const
  CSource =
  '''
  program Test;
  var intArray: array[0..2] of int;
  var floatArray: array[0..2] of float;
  var i: int;
  begin
    intArray[0] := 1;
    intArray[1] := 2;
    intArray[2] := 3;
    for i := 0 to 2 do
      floatArray[i] := intArray[i];
  end.
  ''';
begin
  RunCompilerTest('Array Mixed Types', CSource);
end;

procedure ArrayInIfStatement();
const
  CSource =
  '''
  program Test;
  var arr: array[0..4] of int;
  var i: int;
  begin
    arr[0] := 10;
    if arr[0] > 5 then
      arr[0] := arr[0] * 2;
  end.
  ''';
begin
  RunCompilerTest('Array In If Statement', CSource);
end;

procedure ArrayInFunction();
const
  CSource =
  '''
  program Test;
  
  routine GetMax(const arr: array[0..4] of int): int;
  var i: int;
  var maxVal: int;
  begin
    maxVal := arr[0];
    for i := 1 to 4 do
    begin
      if arr[i] > maxVal then
        maxVal := arr[i];
    end;
    return maxVal;
  end;
  
  var numbers: array[0..4] of int;
  var maximum: int;
  begin
    numbers[0] := 5;
    numbers[1] := 12;
    numbers[2] := 3;
    numbers[3] := 18;
    numbers[4] := 7;
    maximum := GetMax(numbers);
  end.
  ''';
begin
  RunCompilerTest('Array In Function', CSource);
end;

end.
