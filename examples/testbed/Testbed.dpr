{===============================================================================
  NitroPascal - Modern Pascal • C Performance

  Copyright © 2025-present tinyBigGAMES™ LLC
  All Rights Reserved.

  https://nitropascal.org

  See LICENSE for license information
===============================================================================}

program Testbed;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  UTest.Arrays in 'UTest.Arrays.pas',
  UTest.CodeGen in 'UTest.CodeGen.pas',
  UTest.Common in 'UTest.Common.pas',
  UTest.ConditionalCompilation in 'UTest.ConditionalCompilation.pas',
  UTest.ControlFlow in 'UTest.ControlFlow.pas',
  UTest.Lexer in 'UTest.Lexer.pas',
  UTest.Numbers in 'UTest.Numbers.pas',
  UTest.Parameters in 'UTest.Parameters.pas',
  UTest.Parser in 'UTest.Parser.pas',
  UTest.Pointers in 'UTest.Pointers.pas',
  UTest.Records in 'UTest.Records.pas',
  UTest.Strings in 'UTest.Strings.pas',
  UTest.Types in 'UTest.Types.pas',
  UTestbed in 'UTestbed.pas',
  NitroPascal.CodeGen in '..\..\src\NitroPascal.CodeGen.pas',
  NitroPascal.Compiler in '..\..\src\NitroPascal.Compiler.pas',
  NitroPascal.Lexer in '..\..\src\NitroPascal.Lexer.pas',
  NitroPascal.Parser in '..\..\src\NitroPascal.Parser.pas',
  NitroPascal.Resolver in '..\..\src\NitroPascal.Resolver.pas',
  NitroPascal.Symbols in '..\..\src\NitroPascal.Symbols.pas',
  NitroPascal.Types in '..\..\src\NitroPascal.Types.pas',
  NitroPascal.Utils in '..\..\src\NitroPascal.Utils.pas';

begin
  UTestbed.RunTests();
end.
