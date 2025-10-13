{===============================================================================
  NitroPascal - Modern Pascal • C Performance

  Copyright © 2025-present tinyBigGAMES™ LLC
  All Rights Reserved.

  https://nitropascal.org

  See LICENSE for license information
===============================================================================}

unit UTestbed;

interface

procedure RunTestbed();

implementation

uses
  System.SysUtils,
  System.IOUtils,
  NitroPascal.Utils,
  UTest;

procedure RunTestbed();
var
  LNum: Integer;
begin
  try
    LNum := 001;
    case LNum of
      001: Test('ProgramSimple.pas', [], True, True);
      002: Test('ProgramVariables.pas', [], True, True);
      003: Test('ProgramFunctions.pas', [], True, True);
      004: Test('ProgramControlFlow.pas', [], True, True);
      005: Test('ProgramTypes.pas', [], True, True);
      006: Test('ProgramComplete.pas', [], True, True);
      007: Test('UnitSimple.pas', [], True, True);
      008: Test('ProgramUsesUnit.pas', ['UnitSimple.pas'], True, True);
      009: Test('LibrarySimple.pas', [], True, True);
      010: Test('ProgramCaseAndOperators.pas', [], True, True);
      011: Test('ProgramConstantsAndRepeat.pas', [], True, True);
      012: Test('ProgramStringsAndWith.pas', [], True, True);
      013: Test('ProgramFunctions.pas', [], True, True);
      014: Test('ProgramWriteWriteLn.pas', [], True, True);
      015: Test('ProgramBasicTypes.pas', [], True, True);
      016: Test('ProgramTypeAliases.pas', [], True, True);
      017: Test('ProgramTypedConstants.pas', [], True, True);
      018: Test('ProgramAllOperators.pas', [], True, True);
      019: Test('ProgramParameterPassing.pas', [], True, True);
      020: Test('ProgramMultiDimArrays.pas', [], True, True);
      021: Test('ProgramNestedRecords.pas', [], True, True);
      022: Test('ProgramEnumerations.pas', [], True, True);
      023: Test('ProgramPointerOperations.pas', [], True, True);
      024: Test('ProgramStringOperations.pas', [], True, True);
      025: Test('ProgramCompilerDirectives.pas', [], True, True);
      026: Test('ProgramUsesUnitTypes.pas', ['UnitWithTypes.pas'], True, True);
      027: Test('LibraryWithExports.pas', [], True, True);
    end;

  except
    on E: Exception do
    begin
      TNPUtils.PrintLn('Fatal Error: %s', [E.Message]);
    end;

  end;

  TNPUtils.Pause();
end;

end.
