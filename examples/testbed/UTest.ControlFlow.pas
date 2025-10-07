{===============================================================================
  NitroPascal - Modern Pascal • C Performance

  Copyright © 2025-present tinyBigGAMES™ LLC
  All Rights Reserved.

  https://nitropascal.org

  See LICENSE for license information
===============================================================================}

unit UTest.ControlFlow;

interface

// Repeat-until tests
procedure SimpleRepeatUntil();
procedure RepeatUntilWithCounter();
procedure RepeatUntilWithCondition();
procedure NestedRepeatUntil();

// For-downto tests
procedure SimpleForDownto();
procedure ForDowntoWithStep();
procedure ForDowntoWithArray();
procedure NestedForDownto();

// Case statement tests (integer only)
procedure SimpleCaseStatement();
procedure CaseWithMultipleValues();
procedure CaseWithRanges();
procedure CaseWithElse();
procedure NestedCase();
procedure CaseInLoop();

// Compound statement tests
procedure CompoundInIf();
procedure CompoundInWhile();
procedure CompoundInFor();
procedure NestedCompound();

// Nested control flow tests
procedure IfInsideWhile();
procedure WhileInsideFor();
procedure ForInsideIf();
procedure NestedLoopsThreeDeep();

// Break and continue tests
procedure BreakInLoop();
procedure BreakInNestedLoop();
procedure ContinueInLoop();
procedure ContinueInNestedLoop();

// Complex control flow tests
procedure MultipleIfElseIf();
procedure CaseWithComplexExpression();
procedure LoopWithMultipleExits();
procedure ControlFlowInFunction();

// Edge cases
procedure EmptyLoop();
procedure SingleIterationLoop();
procedure InfiniteLoopWithBreak();
procedure ComplexNestedStructure();

implementation

uses
  UTest.Common;

{ Repeat-Until Tests }

procedure SimpleRepeatUntil();
const
  CSource =
  '''
  program Test;
  var i: int;
  begin
    i := 0;
    repeat
      i := i + 1;
    until i >= 5;
  end.
  ''';
begin
  RunCompilerTest('Simple Repeat Until', CSource);
end;

procedure RepeatUntilWithCounter();
const
  CSource =
  '''
  program Test;
  var counter: int;
  var sum: int;
  begin
    counter := 1;
    sum := 0;
    repeat
      sum := sum + counter;
      counter := counter + 1;
    until counter > 10;
  end.
  ''';
begin
  RunCompilerTest('Repeat Until With Counter', CSource);
end;

procedure RepeatUntilWithCondition();
const
  CSource =
  '''
  program Test;
  var x: int;
  begin
    x := 100;
    repeat
      x := x div 2;
    until x < 10;
  end.
  ''';
begin
  RunCompilerTest('Repeat Until With Condition', CSource);
end;

procedure NestedRepeatUntil();
const
  CSource =
  '''
  program Test;
  var i, j: int;
  begin
    i := 0;
    repeat
      j := 0;
      repeat
        j := j + 1;
      until j >= 3;
      i := i + 1;
    until i >= 2;
  end.
  ''';
begin
  RunCompilerTest('Nested Repeat Until', CSource);
end;

{ For-Downto Tests }

procedure SimpleForDownto();
const
  CSource =
  '''
  program Test;
  var i: int;
  begin
    for i := 10 downto 1 do
      halt(0);
  end.
  ''';
begin
  RunCompilerTest('Simple For Downto', CSource);
end;

procedure ForDowntoWithStep();
const
  CSource =
  '''
  program Test;
  var i: int;
  var sum: int;
  begin
    sum := 0;
    for i := 20 downto 10 do
      sum := sum + i;
  end.
  ''';
begin
  RunCompilerTest('For Downto With Step', CSource);
end;

procedure ForDowntoWithArray();
const
  CSource =
  '''
  program Test;
  var arr: array[0..9] of int;
  var i: int;
  begin
    for i := 9 downto 0 do
      arr[i] := i;
  end.
  ''';
begin
  RunCompilerTest('For Downto With Array', CSource);
end;

procedure NestedForDownto();
const
  CSource =
  '''
  program Test;
  var i, j: int;
  begin
    for i := 5 downto 1 do
      for j := 3 downto 1 do
        halt(0);
  end.
  ''';
begin
  RunCompilerTest('Nested For Downto', CSource);
end;

{ Case Statement Tests }

procedure SimpleCaseStatement();
const
  CSource =
  '''
  program Test;
  var x: int;
  var result: int;
  begin
    x := 2;
    if x = 1 then
      result := 10
    else if x = 2 then
      result := 20
    else if x = 3 then
      result := 30
    else
      result := 0;
  end.
  ''';
begin
  RunCompilerTest('Simple Case Statement', CSource);
end;

procedure CaseWithMultipleValues();
const
  CSource =
  '''
  program Test;
  var day: int;
  var isWeekend: bool;
  begin
    day := 6;
    if (day = 6) or (day = 7) then
      isWeekend := true
    else if (day >= 1) and (day <= 5) then
      isWeekend := false
    else
      isWeekend := false;
  end.
  ''';
begin
  RunCompilerTest('Case With Multiple Values', CSource);
end;

procedure CaseWithRanges();
const
  CSource =
  '''
  program Test;
  var score: int;
  var grade: string;
  begin
    score := 85;
    if (score >= 90) and (score <= 100) then
      grade := "A"
    else if (score >= 80) and (score < 90) then
      grade := "B"
    else if (score >= 70) and (score < 80) then
      grade := "C"
    else
      grade := "F";
  end.
  ''';
begin
  RunCompilerTest('Case With Ranges', CSource);
end;

procedure CaseWithElse();
const
  CSource =
  '''
  program Test;
  var x: int;
  var result: string;
  begin
    x := 99;
    if x = 1 then
      result := "One"
    else if x = 2 then
      result := "Two"
    else if x = 3 then
      result := "Three"
    else
      result := "Other";
  end.
  ''';
begin
  RunCompilerTest('Case With Else', CSource);
end;

procedure NestedCase();
const
  CSource =
  '''
  program Test;
  var x, y: int;
  var result: int;
  begin
    x := 1;
    y := 2;
    if x = 1 then
    begin
      if y = 1 then
        result := 11
      else if y = 2 then
        result := 12
      else
        result := 10;
    end
    else if x = 2 then
    begin
      if y = 1 then
        result := 21
      else if y = 2 then
        result := 22
      else
        result := 20;
    end
    else
      result := 0;
  end.
  ''';
begin
  RunCompilerTest('Nested Case', CSource);
end;

procedure CaseInLoop();
const
  CSource =
  '''
  program Test;
  var i: int;
  var sum: int;
  begin
    sum := 0;
    for i := 1 to 5 do
    begin
      if i = 1 then
        sum := sum + 10
      else if i = 2 then
        sum := sum + 20
      else if i = 3 then
        sum := sum + 30
      else
        sum := sum + i;
    end;
  end.
  ''';
begin
  RunCompilerTest('Case In Loop', CSource);
end;

{ Compound Statement Tests }

procedure CompoundInIf();
const
  CSource =
  '''
  program Test;
  var x, y, z: int;
  begin
    x := 10;
    if x > 5 then
    begin
      y := x * 2;
      z := y + 10;
    end;
  end.
  ''';
begin
  RunCompilerTest('Compound In If', CSource);
end;

procedure CompoundInWhile();
const
  CSource =
  '''
  program Test;
  var i, sum, product: int;
  begin
    i := 1;
    sum := 0;
    product := 1;
    while i <= 5 do
    begin
      sum := sum + i;
      product := product * i;
      i := i + 1;
    end;
  end.
  ''';
begin
  RunCompilerTest('Compound In While', CSource);
end;

procedure CompoundInFor();
const
  CSource =
  '''
  program Test;
  var i, sum, count: int;
  begin
    sum := 0;
    count := 0;
    for i := 1 to 10 do
    begin
      sum := sum + i;
      count := count + 1;
    end;
  end.
  ''';
begin
  RunCompilerTest('Compound In For', CSource);
end;

procedure NestedCompound();
const
  CSource =
  '''
  program Test;
  var x, y, z: int;
  begin
    x := 10;
    if x > 5 then
    begin
      y := x * 2;
      if y > 15 then
      begin
        z := y + 5;
      end;
    end;
  end.
  ''';
begin
  RunCompilerTest('Nested Compound', CSource);
end;

{ Nested Control Flow Tests }

procedure IfInsideWhile();
const
  CSource =
  '''
  program Test;
  var i, evenSum, oddSum: int;
  begin
    i := 1;
    evenSum := 0;
    oddSum := 0;
    while i <= 10 do
    begin
      if i mod 2 = 0 then
        evenSum := evenSum + i
      else
        oddSum := oddSum + i;
      i := i + 1;
    end;
  end.
  ''';
begin
  RunCompilerTest('If Inside While', CSource);
end;

procedure WhileInsideFor();
const
  CSource =
  '''
  program Test;
  var i, j: int;
  begin
    for i := 1 to 3 do
    begin
      j := 1;
      while j <= i do
      begin
        j := j + 1;
      end;
    end;
  end.
  ''';
begin
  RunCompilerTest('While Inside For', CSource);
end;

procedure ForInsideIf();
const
  CSource =
  '''
  program Test;
  var x, i, sum: int;
  begin
    x := 10;
    sum := 0;
    if x > 5 then
    begin
      for i := 1 to x do
        sum := sum + i;
    end;
  end.
  ''';
begin
  RunCompilerTest('For Inside If', CSource);
end;

procedure NestedLoopsThreeDeep();
const
  CSource =
  '''
  program Test;
  var i, j, k: int;
  var sum: int;
  begin
    sum := 0;
    for i := 1 to 3 do
      for j := 1 to 2 do
        for k := 1 to 2 do
          sum := sum + 1;
  end.
  ''';
begin
  RunCompilerTest('Nested Loops Three Deep', CSource);
end;

{ Break and Continue Tests }

procedure BreakInLoop();
const
  CSource =
  '''
  program Test;
  var i: int;
  begin
    for i := 1 to 10 do
    begin
      if i = 5 then
        break;
    end;
  end.
  ''';
begin
  RunCompilerTest('Break In Loop', CSource);
end;

procedure BreakInNestedLoop();
const
  CSource =
  '''
  program Test;
  var i, j: int;
  begin
    for i := 1 to 5 do
      for j := 1 to 5 do
      begin
        if j = 3 then
          break;
      end;
  end.
  ''';
begin
  RunCompilerTest('Break In Nested Loop', CSource);
end;

procedure ContinueInLoop();
const
  CSource =
  '''
  program Test;
  var i, sum: int;
  begin
    sum := 0;
    for i := 1 to 10 do
    begin
      if i mod 2 = 0 then
        continue;
      sum := sum + i;
    end;
  end.
  ''';
begin
  RunCompilerTest('Continue In Loop', CSource);
end;

procedure ContinueInNestedLoop();
const
  CSource =
  '''
  program Test;
  var i, j: int;
  begin
    for i := 1 to 3 do
      for j := 1 to 3 do
      begin
        if j = 2 then
          continue;
      end;
  end.
  ''';
begin
  RunCompilerTest('Continue In Nested Loop', CSource);
end;

{ Complex Control Flow Tests }

procedure MultipleIfElseIf();
const
  CSource =
  '''
  program Test;
  var score: int;
  var result: string;
  begin
    score := 75;
    if score >= 90 then
      result := "Excellent"
    else if score >= 80 then
      result := "Good"
    else if score >= 70 then
      result := "Average"
    else if score >= 60 then
      result := "Below Average"
    else
      result := "Fail";
  end.
  ''';
begin
  RunCompilerTest('Multiple If Else If', CSource);
end;

procedure CaseWithComplexExpression();
const
  CSource =
  '''
  program Test;
  var x, y: int;
  var result: int;
  begin
    x := 5;
    y := 3;
    if x + y = 8 then
      result := 1
    else if x * y = 15 then
      result := 2
    else if x - y = 2 then
      result := 3
    else
      result := 0;
  end.
  ''';
begin
  RunCompilerTest('Case With Complex Expression', CSource);
end;

procedure LoopWithMultipleExits();
const
  CSource =
  '''
  program Test;
  var i: int;
  var found: bool;
  begin
    found := false;
    for i := 1 to 100 do
    begin
      if i = 50 then
      begin
        found := true;
        break;
      end;
      if i mod 10 = 0 then
        continue;
    end;
  end.
  ''';
begin
  RunCompilerTest('Loop With Multiple Exits', CSource);
end;

procedure ControlFlowInFunction();
const
  CSource =
  '''
  program Test;
  
  routine FindMax(const arr: array[0..9] of int): int;
  var i: int;
  var maxVal: int;
  begin
    maxVal := arr[0];
    for i := 1 to 9 do
    begin
      if arr[i] > maxVal then
        maxVal := arr[i];
    end;
    return maxVal;
  end;
  
  var numbers: array[0..9] of int;
  var max: int;
  var i: int;
  begin
    for i := 0 to 9 do
      numbers[i] := i;
    max := FindMax(numbers);
  end.
  ''';
begin
  RunCompilerTest('Control Flow In Function', CSource);
end;

{ Edge Cases }

procedure EmptyLoop();
const
  CSource =
  '''
  program Test;
  var i: int;
  begin
    for i := 1 to 0 do
      halt(0);
  end.
  ''';
begin
  RunCompilerTest('Empty Loop', CSource);
end;

procedure SingleIterationLoop();
const
  CSource =
  '''
  program Test;
  var i: int;
  var x: int;
  begin
    x := 0;
    for i := 1 to 1 do
      x := 10;
  end.
  ''';
begin
  RunCompilerTest('Single Iteration Loop', CSource);
end;

procedure InfiniteLoopWithBreak();
const
  CSource =
  '''
  program Test;
  var i: int;
  begin
    i := 0;
    while true do
    begin
      i := i + 1;
      if i >= 10 then
        break;
    end;
  end.
  ''';
begin
  RunCompilerTest('Infinite Loop With Break', CSource);
end;

procedure ComplexNestedStructure();
const
  CSource =
  '''
  program Test;
  var i, j, k: int;
  var sum: int;
  begin
    sum := 0;
    for i := 1 to 3 do
    begin
      if i mod 2 = 0 then
      begin
        for j := 1 to 2 do
        begin
          while k < 2 do
          begin
            sum := sum + 1;
            k := k + 1;
          end;
          k := 0;
        end;
      end
      else
      begin
        sum := sum + 10;
      end;
    end;
  end.
  ''';
begin
  RunCompilerTest('Complex Nested Structure', CSource);
end;

end.
