{===============================================================================
  NitroPascal - Modern Pascal • C Performance

  Copyright © 2025-present tinyBigGAMES™ LLC
  All Rights Reserved.

  https://nitropascal.org

  See LICENSE for license information
===============================================================================}

unit UTest.Numbers;

interface

// Integer literal tests
procedure IntegerLiteral();
procedure NegativeInteger();
procedure ZeroInteger();
procedure LargeInteger();

// Integer arithmetic tests
procedure IntegerAddition();
procedure IntegerSubtraction();
procedure IntegerMultiplication();
procedure IntegerDivision();
procedure IntegerModulo();
procedure IntegerMixedArithmetic();

// Integer comparison tests
procedure IntegerEquals();
procedure IntegerNotEquals();
procedure IntegerLessThan();
procedure IntegerGreaterThan();
procedure IntegerLessOrEqual();
procedure IntegerGreaterOrEqual();

// Integer bitwise operations
procedure IntegerBitwiseAnd();
procedure IntegerBitwiseOr();
procedure IntegerBitwiseXor();
procedure IntegerBitwiseNot();
procedure IntegerShiftLeft();
procedure IntegerShiftRight();

// Float/Real literal tests
procedure FloatLiteral();
procedure NegativeFloat();
procedure FloatWithExponent();
procedure FloatZero();

// Float arithmetic tests
procedure FloatAddition();
procedure FloatSubtraction();
procedure FloatMultiplication();
procedure FloatDivision();
procedure FloatMixedArithmetic();

// Float comparison tests
procedure FloatEquals();
procedure FloatNotEquals();
procedure FloatLessThan();
procedure FloatGreaterThan();
procedure FloatLessOrEqual();
procedure FloatGreaterOrEqual();

// Mixed integer/float operations
procedure MixedIntFloatAdd();
procedure MixedIntFloatMultiply();
procedure IntToFloatAssignment();
procedure FloatToIntAssignment();

// Operator precedence tests
procedure PrecedenceMultiplyAdd();
procedure PrecedenceParentheses();
procedure PrecedenceDivMod();
procedure PrecedenceUnaryMinus();
procedure PrecedenceBitwiseLogical();
procedure ComplexPrecedence();

// Edge cases
procedure IntegerOverflowLarge();
procedure FloatPrecision();
procedure DivisionByVariable();
procedure ModuloNegative();

implementation

uses
  UTest.Common;

{ Integer Literal Tests }

procedure IntegerLiteral();
const
  CSource =
  '''
  program Test;
  var x: int;
  begin
    x := 42;
  end.
  ''';
begin
  RunCompilerTest('Integer Literal', CSource);
end;

procedure NegativeInteger();
const
  CSource =
  '''
  program Test;
  var x: int;
  begin
    x := -42;
  end.
  ''';
begin
  RunCompilerTest('Negative Integer', CSource);
end;

procedure ZeroInteger();
const
  CSource =
  '''
  program Test;
  var x: int;
  begin
    x := 0;
  end.
  ''';
begin
  RunCompilerTest('Zero Integer', CSource);
end;

procedure LargeInteger();
const
  CSource =
  '''
  program Test;
  var x: int;
  begin
    x := 2147483647;
  end.
  ''';
begin
  RunCompilerTest('Large Integer', CSource);
end;

{ Integer Arithmetic Tests }

procedure IntegerAddition();
const
  CSource =
  '''
  program Test;
  var a, b, c: int;
  begin
    a := 10;
    b := 20;
    c := a + b;
  end.
  ''';
begin
  RunCompilerTest('Integer Addition', CSource);
end;

procedure IntegerSubtraction();
const
  CSource =
  '''
  program Test;
  var a, b, c: int;
  begin
    a := 50;
    b := 20;
    c := a - b;
  end.
  ''';
begin
  RunCompilerTest('Integer Subtraction', CSource);
end;

procedure IntegerMultiplication();
const
  CSource =
  '''
  program Test;
  var a, b, c: int;
  begin
    a := 10;
    b := 5;
    c := a * b;
  end.
  ''';
begin
  RunCompilerTest('Integer Multiplication', CSource);
end;

procedure IntegerDivision();
const
  CSource =
  '''
  program Test;
  var a, b, c: int;
  begin
    a := 20;
    b := 4;
    c := a div b;
  end.
  ''';
begin
  RunCompilerTest('Integer Division', CSource);
end;

procedure IntegerModulo();
const
  CSource =
  '''
  program Test;
  var a, b, c: int;
  begin
    a := 23;
    b := 5;
    c := a mod b;
  end.
  ''';
begin
  RunCompilerTest('Integer Modulo', CSource);
end;

procedure IntegerMixedArithmetic();
const
  CSource =
  '''
  program Test;
  var result: int;
  begin
    result := 10 + 5 * 2 - 8 div 4;
  end.
  ''';
begin
  RunCompilerTest('Integer Mixed Arithmetic', CSource);
end;

{ Integer Comparison Tests }

procedure IntegerEquals();
const
  CSource =
  '''
  program Test;
  var a, b: int;
  var equal: bool;
  begin
    a := 10;
    b := 10;
    equal := a = b;
  end.
  ''';
begin
  RunCompilerTest('Integer Equals', CSource);
end;

procedure IntegerNotEquals();
const
  CSource =
  '''
  program Test;
  var a, b: int;
  var notEqual: bool;
  begin
    a := 10;
    b := 20;
    notEqual := a <> b;
  end.
  ''';
begin
  RunCompilerTest('Integer Not Equals', CSource);
end;

procedure IntegerLessThan();
const
  CSource =
  '''
  program Test;
  var a, b: int;
  var less: bool;
  begin
    a := 10;
    b := 20;
    less := a < b;
  end.
  ''';
begin
  RunCompilerTest('Integer Less Than', CSource);
end;

procedure IntegerGreaterThan();
const
  CSource =
  '''
  program Test;
  var a, b: int;
  var greater: bool;
  begin
    a := 30;
    b := 20;
    greater := a > b;
  end.
  ''';
begin
  RunCompilerTest('Integer Greater Than', CSource);
end;

procedure IntegerLessOrEqual();
const
  CSource =
  '''
  program Test;
  var a, b: int;
  var lessOrEqual: bool;
  begin
    a := 10;
    b := 20;
    lessOrEqual := a <= b;
  end.
  ''';
begin
  RunCompilerTest('Integer Less Or Equal', CSource);
end;

procedure IntegerGreaterOrEqual();
const
  CSource =
  '''
  program Test;
  var a, b: int;
  var greaterOrEqual: bool;
  begin
    a := 20;
    b := 10;
    greaterOrEqual := a >= b;
  end.
  ''';
begin
  RunCompilerTest('Integer Greater Or Equal', CSource);
end;

{ Integer Bitwise Operations }

procedure IntegerBitwiseAnd();
const
  CSource =
  '''
  program Test;
  var a, b, c: int;
  begin
    a := 15;
    b := 7;
    c := a and b;
  end.
  ''';
begin
  RunCompilerTest('Integer Bitwise And', CSource);
end;

procedure IntegerBitwiseOr();
const
  CSource =
  '''
  program Test;
  var a, b, c: int;
  begin
    a := 8;
    b := 4;
    c := a or b;
  end.
  ''';
begin
  RunCompilerTest('Integer Bitwise Or', CSource);
end;

procedure IntegerBitwiseXor();
const
  CSource =
  '''
  program Test;
  var a, b, c: int;
  begin
    a := 15;
    b := 9;
    c := a xor b;
  end.
  ''';
begin
  RunCompilerTest('Integer Bitwise Xor', CSource);
end;

procedure IntegerBitwiseNot();
const
  CSource =
  '''
  program Test;
  var a, b: int;
  begin
    a := 5;
    b := not a;
  end.
  ''';
begin
  RunCompilerTest('Integer Bitwise Not', CSource);
end;

procedure IntegerShiftLeft();
const
  CSource =
  '''
  program Test;
  var a, b: int;
  begin
    a := 1;
    b := a shl 3;
  end.
  ''';
begin
  RunCompilerTest('Integer Shift Left', CSource);
end;

procedure IntegerShiftRight();
const
  CSource =
  '''
  program Test;
  var a, b: int;
  begin
    a := 16;
    b := a shr 2;
  end.
  ''';
begin
  RunCompilerTest('Integer Shift Right', CSource);
end;

{ Float/Real Literal Tests }

procedure FloatLiteral();
const
  CSource =
  '''
  program Test;
  var x: float;
  begin
    x := 3.14;
  end.
  ''';
begin
  RunCompilerTest('Float Literal', CSource);
end;

procedure NegativeFloat();
const
  CSource =
  '''
  program Test;
  var x: float;
  begin
    x := -3.14;
  end.
  ''';
begin
  RunCompilerTest('Negative Float', CSource);
end;

procedure FloatWithExponent();
const
  CSource =
  '''
  program Test;
  var x: float;
  begin
    x := 1.5e10;
  end.
  ''';
begin
  RunCompilerTest('Float With Exponent', CSource);
end;

procedure FloatZero();
const
  CSource =
  '''
  program Test;
  var x: float;
  begin
    x := 0.0;
  end.
  ''';
begin
  RunCompilerTest('Float Zero', CSource);
end;

{ Float Arithmetic Tests }

procedure FloatAddition();
const
  CSource =
  '''
  program Test;
  var a, b, c: float;
  begin
    a := 1.5;
    b := 2.5;
    c := a + b;
  end.
  ''';
begin
  RunCompilerTest('Float Addition', CSource);
end;

procedure FloatSubtraction();
const
  CSource =
  '''
  program Test;
  var a, b, c: float;
  begin
    a := 5.5;
    b := 2.3;
    c := a - b;
  end.
  ''';
begin
  RunCompilerTest('Float Subtraction', CSource);
end;

procedure FloatMultiplication();
const
  CSource =
  '''
  program Test;
  var a, b, c: float;
  begin
    a := 2.5;
    b := 4.0;
    c := a * b;
  end.
  ''';
begin
  RunCompilerTest('Float Multiplication', CSource);
end;

procedure FloatDivision();
const
  CSource =
  '''
  program Test;
  var a, b, c: float;
  begin
    a := 10.0;
    b := 4.0;
    c := a / b;
  end.
  ''';
begin
  RunCompilerTest('Float Division', CSource);
end;

procedure FloatMixedArithmetic();
const
  CSource =
  '''
  program Test;
  var result: float;
  begin
    result := 1.5 + 2.0 * 3.5 - 1.0 / 2.0;
  end.
  ''';
begin
  RunCompilerTest('Float Mixed Arithmetic', CSource);
end;

{ Float Comparison Tests }

procedure FloatEquals();
const
  CSource =
  '''
  program Test;
  var a, b: float;
  var equal: bool;
  begin
    a := 3.14;
    b := 3.14;
    equal := a = b;
  end.
  ''';
begin
  RunCompilerTest('Float Equals', CSource);
end;

procedure FloatNotEquals();
const
  CSource =
  '''
  program Test;
  var a, b: float;
  var notEqual: bool;
  begin
    a := 3.14;
    b := 2.71;
    notEqual := a <> b;
  end.
  ''';
begin
  RunCompilerTest('Float Not Equals', CSource);
end;

procedure FloatLessThan();
const
  CSource =
  '''
  program Test;
  var a, b: float;
  var less: bool;
  begin
    a := 2.5;
    b := 3.5;
    less := a < b;
  end.
  ''';
begin
  RunCompilerTest('Float Less Than', CSource);
end;

procedure FloatGreaterThan();
const
  CSource =
  '''
  program Test;
  var a, b: float;
  var greater: bool;
  begin
    a := 5.5;
    b := 3.5;
    greater := a > b;
  end.
  ''';
begin
  RunCompilerTest('Float Greater Than', CSource);
end;

procedure FloatLessOrEqual();
const
  CSource =
  '''
  program Test;
  var a, b: float;
  var lessOrEqual: bool;
  begin
    a := 3.14;
    b := 3.14;
    lessOrEqual := a <= b;
  end.
  ''';
begin
  RunCompilerTest('Float Less Or Equal', CSource);
end;

procedure FloatGreaterOrEqual();
const
  CSource =
  '''
  program Test;
  var a, b: float;
  var greaterOrEqual: bool;
  begin
    a := 3.14;
    b := 2.71;
    greaterOrEqual := a >= b;
  end.
  ''';
begin
  RunCompilerTest('Float Greater Or Equal', CSource);
end;

{ Mixed Integer/Float Operations }

procedure MixedIntFloatAdd();
const
  CSource =
  '''
  program Test;
  var i: int;
  var f: float;
  var result: float;
  begin
    i := 5;
    f := 2.5;
    result := i + f;
  end.
  ''';
begin
  RunCompilerTest('Mixed Int Float Addition', CSource);
end;

procedure MixedIntFloatMultiply();
const
  CSource =
  '''
  program Test;
  var i: int;
  var f: float;
  var result: float;
  begin
    i := 3;
    f := 2.5;
    result := i * f;
  end.
  ''';
begin
  RunCompilerTest('Mixed Int Float Multiply', CSource);
end;

procedure IntToFloatAssignment();
const
  CSource =
  '''
  program Test;
  var i: int;
  var f: float;
  begin
    i := 42;
    f := i;
  end.
  ''';
begin
  RunCompilerTest('Int To Float Assignment', CSource);
end;

procedure FloatToIntAssignment();
const
  CSource =
  '''
  program Test;
  var i: int;
  var f: float;
  begin
    f := 42.7;
    i := f;
  end.
  ''';
begin
  RunCompilerTest('Float To Int Assignment', CSource);
end;

{ Operator Precedence Tests }

procedure PrecedenceMultiplyAdd();
const
  CSource =
  '''
  program Test;
  var result: int;
  begin
    result := 2 + 3 * 4;
  end.
  ''';
begin
  RunCompilerTest('Precedence Multiply Before Add', CSource);
end;

procedure PrecedenceParentheses();
const
  CSource =
  '''
  program Test;
  var result: int;
  begin
    result := (2 + 3) * 4;
  end.
  ''';
begin
  RunCompilerTest('Precedence Parentheses', CSource);
end;

procedure PrecedenceDivMod();
const
  CSource =
  '''
  program Test;
  var result: int;
  begin
    result := 20 div 4 + 10 mod 3;
  end.
  ''';
begin
  RunCompilerTest('Precedence Div Mod', CSource);
end;

procedure PrecedenceUnaryMinus();
const
  CSource =
  '''
  program Test;
  var result: int;
  begin
    result := -2 * 3;
  end.
  ''';
begin
  RunCompilerTest('Precedence Unary Minus', CSource);
end;

procedure PrecedenceBitwiseLogical();
const
  CSource =
  '''
  program Test;
  var result: int;
  begin
    result := 5 or 3 and 1;
  end.
  ''';
begin
  RunCompilerTest('Precedence Bitwise Logical', CSource);
end;

procedure ComplexPrecedence();
const
  CSource =
  '''
  program Test;
  var result: int;
  begin
    result := (10 + 5) * 2 - 8 div (2 + 2) mod 3;
  end.
  ''';
begin
  RunCompilerTest('Complex Precedence', CSource);
end;

{ Edge Cases }

procedure IntegerOverflowLarge();
const
  CSource =
  '''
  program Test;
  var x, y: int;
  begin
    x := 2147483647;
    y := x + 1;
  end.
  ''';
begin
  RunCompilerTest('Integer Overflow Large', CSource);
end;

procedure FloatPrecision();
const
  CSource =
  '''
  program Test;
  var x: float;
  begin
    x := 0.1 + 0.2;
  end.
  ''';
begin
  RunCompilerTest('Float Precision', CSource);
end;

procedure DivisionByVariable();
const
  CSource =
  '''
  program Test;
  var a, b, c: int;
  begin
    a := 10;
    b := 2;
    c := a div b;
  end.
  ''';
begin
  RunCompilerTest('Division By Variable', CSource);
end;

procedure ModuloNegative();
const
  CSource =
  '''
  program Test;
  var a, b, c: int;
  begin
    a := -10;
    b := 3;
    c := a mod b;
  end.
  ''';
begin
  RunCompilerTest('Modulo Negative', CSource);
end;

end.
