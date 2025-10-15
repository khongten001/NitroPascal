{ ===============================================================================
  NitroPascal - Modern Pascal • C Performance

  Copyright © 2025-present tinyBigGAMES™ LLC
  All Rights Reserved.

  https://nitropascal.org

  See LICENSE for license information
===============================================================================}

program Testbed;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  UTestbed in 'UTestbed.pas',
  UTest in 'UTest.pas',
  NitroPascal.CodeGen.Declarations in '..\..\src\NitroPascal.CodeGen.Declarations.pas',
  NitroPascal.CodeGen.Expressions in '..\..\src\NitroPascal.CodeGen.Expressions.pas',
  NitroPascal.CodeGen.Files in '..\..\src\NitroPascal.CodeGen.Files.pas',
  NitroPascal.CodeGen in '..\..\src\NitroPascal.CodeGen.pas',
  NitroPascal.CodeGen.Statements in '..\..\src\NitroPascal.CodeGen.Statements.pas',
  NitroPascal.Compiler in '..\..\src\NitroPascal.Compiler.pas',
  NitroPascal.Errors in '..\..\src\NitroPascal.Errors.pas',
  NitroPascal.PasToJSON in '..\..\src\NitroPascal.PasToJSON.pas',
  NitroPascal.Preprocessor in '..\..\src\NitroPascal.Preprocessor.pas',
  NitroPascal.Utils in '..\..\src\NitroPascal.Utils.pas',
  NitroPascal.BuildSettings in '..\..\src\NitroPascal.BuildSettings.pas';

begin
  RunTestbed();
end.
