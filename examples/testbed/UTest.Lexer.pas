{===============================================================================
  NitroPascal - Modern Pascal • C Performance

  Copyright © 2025-present tinyBigGAMES™ LLC
  All Rights Reserved.

  https://nitropascal.org

  See LICENSE for license information
===============================================================================}

unit UTest.Lexer;

interface

// Basic token tests
procedure SimpleIdentifiers();
procedure Keywords();
procedure IntegerLiterals();
procedure FloatLiterals();
procedure StringLiterals();

// Operator tests
procedure ArithmeticOperators();
procedure ComparisonOperators();
procedure AssignmentOperator();

// Comment tests
procedure LineComments();
procedure BlockComments();

implementation

uses
  UTest.Common;

procedure SimpleIdentifiers();
const
  CSource =
  '''
  foo bar baz MyVar count x
  ''';
begin
  RunLexerTest('Simple Identifiers', CSource);
end;

procedure Keywords();
const
  CSource =
  '''
  program module library routine var const type begin end if then else
  ''';
begin
  RunLexerTest('Keywords', CSource);
end;

procedure IntegerLiterals();
const
  CSource =
  '''
  0 42 123 0xFF 0b1010
  ''';
begin
  RunLexerTest('Integer Literals', CSource);
end;

procedure FloatLiterals();
const
  CSource =
  '''
  3.14 0.5 2.5e10 1.23e-5
  ''';
begin
  RunLexerTest('Float Literals', CSource);
end;

procedure StringLiterals();
const
  CSource =
  '''
  "hello" "world" "test\n" "escaped\"quote"
  ''';
begin
  RunLexerTest('String Literals', CSource);
end;

procedure ArithmeticOperators();
const
  CSource =
  '''
  + - * / div mod
  ''';
begin
  RunLexerTest('Arithmetic Operators', CSource);
end;

procedure ComparisonOperators();
const
  CSource =
  '''
  = <> < <= > >= and or not
  ''';
begin
  RunLexerTest('Comparison Operators', CSource);
end;

procedure AssignmentOperator();
const
  CSource =
  '''
  x := 5
  ''';
begin
  RunLexerTest('Assignment Operator', CSource);
end;

procedure LineComments();
const
  CSource =
  '''
  x := 5; // this is a comment
  y := 10; // another one
  ''';
begin
  RunLexerTest('Line Comments', CSource);
end;

procedure BlockComments();
const
  CSource =
  '''
  x := 5; (* block comment *) y := 10;
  { another block }
  ''';
begin
  RunLexerTest('Block Comments', CSource);
end;

end.
