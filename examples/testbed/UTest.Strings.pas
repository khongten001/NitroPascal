{===============================================================================
  NitroPascal - Modern Pascal • C Performance

  Copyright © 2025-present tinyBigGAMES™ LLC
  All Rights Reserved.

  https://nitropascal.org

  See LICENSE for license information
===============================================================================}

unit UTest.Strings;

interface

// Basic string tests
procedure StringLiteral();
procedure StringVariable();
procedure StringAssignment();
procedure EmptyString();

// String concatenation tests
procedure StringConcatenation();
procedure StringConcatenationMultiple();
procedure StringConcatenationWithEmpty();

// String comparison tests
procedure StringEquality();
procedure StringInequality();
procedure StringLessThan();
procedure StringGreaterThan();

// String indexing tests
procedure StringIndexing();
procedure StringIndexAssignment();

// String method tests
procedure StringLength();
procedure StringSubstr();
procedure StringFind();
procedure StringEmpty();
procedure StringClear();

// String parameter passing tests
procedure StringParameterByValue();
procedure StringParameterByConst();
procedure StringParameterByVar();

// String return values
procedure StringReturnValue();
procedure StringReturnEmpty();

// String escape sequences
procedure StringEscapeNewline();
procedure StringEscapeTab();
procedure StringEscapeQuote();
procedure StringEscapeBackslash();

// String edge cases
procedure StringWithSpaces();
procedure StringWithNumbers();
procedure StringWithSpecialChars();

// String in modules
procedure ModuleWithStringPublic();
procedure ModuleWithStringPrivate();

// String in libraries
procedure LibraryWithString();

// Complex string operations
procedure StringComplexExpression();
procedure StringInControlFlow();
procedure StringInLoop();

implementation

uses
  UTest.Common;

{ Basic String Tests }

procedure StringLiteral();
const
  CSource =
  '''
  program Test;
  extern <stdio.h> routine printf(format: ^char; ...): int;
  var s: string;
  begin
    s := "Hello, World!";
    printf("String: %s\n", s);
  end.
  ''';
begin
  RunCompilerTest('String Literal', CSource);
end;

procedure StringVariable();
const
  CSource =
  '''
  program Test;
  var s1, s2: string;
  begin
    s1 := "First";
    s2 := "Second";
  end.
  ''';
begin
  RunCompilerTest('String Variable', CSource);
end;

procedure StringAssignment();
const
  CSource =
  '''
  program Test;
  var s1, s2: string;
  begin
    s1 := "Hello";
    s2 := s1;
  end.
  ''';
begin
  RunCompilerTest('String Assignment', CSource);
end;

procedure EmptyString();
const
  CSource =
  '''
  program Test;
  var s: string;
  begin
    s := "";
  end.
  ''';
begin
  RunCompilerTest('Empty String', CSource);
end;

{ String Concatenation Tests }

procedure StringConcatenation();
const
  CSource =
  '''
  program Test;
  var s1, s2, s3: string;
  begin
    s1 := "Hello";
    s2 := "World";
    s3 := s1 + s2;
  end.
  ''';
begin
  RunCompilerTest('String Concatenation', CSource);
end;

procedure StringConcatenationMultiple();
const
  CSource =
  '''
  program Test;
  var result: string;
  begin
    result := "Hello" + ", " + "World" + "!";
  end.
  ''';
begin
  RunCompilerTest('String Concatenation Multiple', CSource);
end;

procedure StringConcatenationWithEmpty();
const
  CSource =
  '''
  program Test;
  var s1, s2: string;
  begin
    s1 := "Hello";
    s2 := s1 + "";
  end.
  ''';
begin
  RunCompilerTest('String Concatenation With Empty', CSource);
end;

{ String Comparison Tests }

procedure StringEquality();
const
  CSource =
  '''
  program Test;
  var s1, s2: string;
  var equal: bool;
  begin
    s1 := "Hello";
    s2 := "Hello";
    equal := s1 = s2;
  end.
  ''';
begin
  RunCompilerTest('String Equality', CSource);
end;

procedure StringInequality();
const
  CSource =
  '''
  program Test;
  var s1, s2: string;
  var notEqual: bool;
  begin
    s1 := "Hello";
    s2 := "World";
    notEqual := s1 <> s2;
  end.
  ''';
begin
  RunCompilerTest('String Inequality', CSource);
end;

procedure StringLessThan();
const
  CSource =
  '''
  program Test;
  var s1, s2: string;
  var less: bool;
  begin
    s1 := "Apple";
    s2 := "Banana";
    less := s1 < s2;
  end.
  ''';
begin
  RunCompilerTest('String Less Than', CSource);
end;

procedure StringGreaterThan();
const
  CSource =
  '''
  program Test;
  var s1, s2: string;
  var greater: bool;
  begin
    s1 := "Zebra";
    s2 := "Apple";
    greater := s1 > s2;
  end.
  ''';
begin
  RunCompilerTest('String Greater Than', CSource);
end;

{ String Indexing Tests }

procedure StringIndexing();
const
  CSource =
  '''
  program Test;
  var s: string;
  var c: char;
  begin
    s := "Hello";
    c := s[0];
  end.
  ''';
begin
  RunCompilerTest('String Indexing', CSource);
end;

procedure StringIndexAssignment();
const
  CSource =
  '''
  program Test;
  var s: string;
  begin
    s := "Hello";
    s[0] := 'h';
  end.
  ''';
begin
  RunCompilerTest('String Index Assignment', CSource);
end;

{ String Method Tests }

procedure StringLength();
const
  CSource =
  '''
  program Test;
  var s: string;
  var len: int;
  begin
    s := "Hello, World!";
    len := s.length();
  end.
  ''';
begin
  RunCompilerTest('String Length Method', CSource);
end;

procedure StringSubstr();
const
  CSource =
  '''
  program Test;
  var s: string;
  var sub: string;
  begin
    s := "Hello, World!";
    sub := s.substr(0, 5);
  end.
  ''';
begin
  RunCompilerTest('String Substr Method', CSource);
end;

procedure StringFind();
const
  CSource =
  '''
  program Test;
  var s: string;
  var pos: int;
  begin
    s := "Hello, World!";
    pos := s.find("World");
  end.
  ''';
begin
  RunCompilerTest('String Find Method', CSource);
end;

procedure StringEmpty();
const
  CSource =
  '''
  program Test;
  var s: string;
  var isEmpty: bool;
  begin
    s := "";
    isEmpty := s.empty();
  end.
  ''';
begin
  RunCompilerTest('String Empty Method', CSource);
end;

procedure StringClear();
const
  CSource =
  '''
  program Test;
  var s: string;
  begin
    s := "Hello";
    s.clear();
  end.
  ''';
begin
  RunCompilerTest('String Clear Method', CSource);
end;

{ String Parameter Passing Tests }

procedure StringParameterByValue();
const
  CSource =
  '''
  program Test;
  
  routine ProcessString(s: string);
  begin
    s := s + " processed";
  end;
  
  var text: string;
  begin
    text := "Test";
    ProcessString(text);
  end.
  ''';
begin
  RunCompilerTest('String Parameter By Value', CSource);
end;

procedure StringParameterByConst();
const
  CSource =
  '''
  program Test;
  
  routine PrintString(const s: string);
  begin
    halt(0);
  end;
  
  var text: string;
  begin
    text := "Test";
    PrintString(text);
  end.
  ''';
begin
  RunCompilerTest('String Parameter By Const', CSource);
end;

procedure StringParameterByVar();
const
  CSource =
  '''
  program Test;
  
  routine ModifyString(var s: string);
  begin
    s := s + " modified";
  end;
  
  var text: string;
  begin
    text := "Test";
    ModifyString(text);
  end.
  ''';
begin
  RunCompilerTest('String Parameter By Var', CSource);
end;

{ String Return Values }

procedure StringReturnValue();
const
  CSource =
  '''
  program Test;
  
  routine GetGreeting(): string;
  begin
    return "Hello, World!";
  end;
  
  var greeting: string;
  begin
    greeting := GetGreeting();
  end.
  ''';
begin
  RunCompilerTest('String Return Value', CSource);
end;

procedure StringReturnEmpty();
const
  CSource =
  '''
  program Test;
  
  routine GetEmpty(): string;
  begin
    return "";
  end;
  
  var empty: string;
  begin
    empty := GetEmpty();
  end.
  ''';
begin
  RunCompilerTest('String Return Empty', CSource);
end;

{ String Escape Sequences }

procedure StringEscapeNewline();
const
  CSource =
  '''
  program Test;
  var s: string;
  begin
    s := "Line 1\nLine 2";
  end.
  ''';
begin
  RunCompilerTest('String Escape Newline', CSource);
end;

procedure StringEscapeTab();
const
  CSource =
  '''
  program Test;
  var s: string;
  begin
    s := "Column1\tColumn2";
  end.
  ''';
begin
  RunCompilerTest('String Escape Tab', CSource);
end;

procedure StringEscapeQuote();
const
  CSource =
  '''
  program Test;
  var s: string;
  begin
    s := "He said \"Hello\"";
  end.
  ''';
begin
  RunCompilerTest('String Escape Quote', CSource);
end;

procedure StringEscapeBackslash();
const
  CSource =
  '''
  program Test;
  var s: string;
  begin
    s := "Path: C:\\Users\\Name";
  end.
  ''';
begin
  RunCompilerTest('String Escape Backslash', CSource);
end;

{ String Edge Cases }

procedure StringWithSpaces();
const
  CSource =
  '''
  program Test;
  var s: string;
  begin
    s := "  spaces  around  ";
  end.
  ''';
begin
  RunCompilerTest('String With Spaces', CSource);
end;

procedure StringWithNumbers();
const
  CSource =
  '''
  program Test;
  var s: string;
  begin
    s := "Value: 12345";
  end.
  ''';
begin
  RunCompilerTest('String With Numbers', CSource);
end;

procedure StringWithSpecialChars();
const
  CSource =
  '''
  program Test;
  var s: string;
  begin
    s := "Special: !@#$%^&*()";
  end.
  ''';
begin
  RunCompilerTest('String With Special Chars', CSource);
end;

{ String in Modules }

procedure ModuleWithStringPublic();
const
  CSource =
  '''
  module StringUtils;
  
  public routine GetVersion(): string;
  begin
    return "1.0";
  end;
  
  public routine Concat(const a, b: string): string;
  begin
    return a + b;
  end;
  
  end.
  ''';
begin
  RunCompilerTest('Module With String Public', CSource);
end;

procedure ModuleWithStringPrivate();
const
  CSource =
  '''
  module StringUtils;
  
  routine InternalFormat(const s: string): string;
  begin
    return "[" + s + "]";
  end;
  
  public routine Format(const s: string): string;
  begin
    return InternalFormat(s);
  end;
  
  end.
  ''';
begin
  RunCompilerTest('Module With String Private', CSource);
end;

{ String in Libraries }

procedure LibraryWithString();
const
  CSource =
  '''
  library StringLib;
  
  public routine GetLibName(): string;
  begin
    return "StringLib";
  end;
  
  public routine Echo(const msg: string): string;
  begin
    return msg;
  end;
  
  end.
  ''';
begin
  RunCompilerTest('Library With String', CSource);
end;

{ Complex String Operations }

procedure StringComplexExpression();
const
  CSource =
  '''
  program Test;
  var s1, s2, s3, result: string;
  begin
    s1 := "Hello";
    s2 := "World";
    s3 := "!";
    result := s1 + ", " + s2 + s3;
  end.
  ''';
begin
  RunCompilerTest('String Complex Expression', CSource);
end;

procedure StringInControlFlow();
const
  CSource =
  '''
  program Test;
  var s: string;
  var result: string;
  begin
    s := "Hello";
    if s = "Hello" then
      result := "Match"
    else
      result := "No match";
  end.
  ''';
begin
  RunCompilerTest('String In Control Flow', CSource);
end;

procedure StringInLoop();
const
  CSource =
  '''
  program Test;
  var s: string;
  var i: int;
  begin
    s := "";
    for i := 1 to 5 do
      s := s + "x";
  end.
  ''';
begin
  RunCompilerTest('String In Loop', CSource);
end;

end.
