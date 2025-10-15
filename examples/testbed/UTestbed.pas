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
  NitroPascal.Utils,
  UTest;

procedure RunTestbed();
var
  LTestSuite: TTest;
begin
  LTestSuite := TTest.Create();
  try
    // Register all tests with their specific options
    // Format: AddTest(Number, SourceFile, [AdditionalFiles], Build, Run, Clean)

    // 0.2.0 Tests
    LTestSuite.AddTest(001, 'ProgramSimple.pas', [], True, True);
    LTestSuite.AddTest(002, 'ProgramVariables.pas', [], True, True);
    LTestSuite.AddTest(003, 'ProgramFunctions.pas', [], True, True);
    LTestSuite.AddTest(004, 'ProgramControlFlow.pas', [], True, True);
    LTestSuite.AddTest(005, 'ProgramTypes.pas', [], True, True);
    LTestSuite.AddTest(006, 'ProgramComplete.pas', [], True, True);
    LTestSuite.AddTest(007, 'UnitSimple.pas', [], True, True);
    LTestSuite.AddTest(008, 'ProgramUsesUnit.pas', ['UnitSimple.pas'], True, True);
    LTestSuite.AddTest(009, 'LibrarySimple.pas', [], True, True);
    LTestSuite.AddTest(010, 'ProgramCaseAndOperators.pas', [], True, True);
    LTestSuite.AddTest(011, 'ProgramConstantsAndRepeat.pas', [], True, True);
    LTestSuite.AddTest(012, 'ProgramStringsAndWith.pas', [], True, True);
    LTestSuite.AddTest(013, 'ProgramFunctions.pas', [], True, True);
    LTestSuite.AddTest(014, 'ProgramWriteWriteLn.pas', [], True, True);
    LTestSuite.AddTest(015, 'ProgramBasicTypes.pas', [], True, True);
    LTestSuite.AddTest(016, 'ProgramTypeAliases.pas', [], True, True);
    LTestSuite.AddTest(017, 'ProgramTypedConstants.pas', [], True, True);
    LTestSuite.AddTest(018, 'ProgramAllOperators.pas', [], True, True);
    LTestSuite.AddTest(019, 'ProgramParameterPassing.pas', [], True, True);
    LTestSuite.AddTest(020, 'ProgramMultiDimArrays.pas', [], True, True);
    LTestSuite.AddTest(021, 'ProgramNestedRecords.pas', [], True, True);
    LTestSuite.AddTest(022, 'ProgramEnumerations.pas', [], True, True);
    LTestSuite.AddTest(023, 'ProgramPointerOperations.pas', [], True, True);
    LTestSuite.AddTest(024, 'ProgramStringOperations.pas', [], True, True);
    LTestSuite.AddTest(025, 'ProgramCompilerDirectives.pas', [], True, True);
    LTestSuite.AddTest(026, 'ProgramUsesUnitTypes.pas', ['UnitWithTypes.pas'], True, True);
    LTestSuite.AddTest(027, 'LibraryWithExports.pas', [], True, True);

    // 0.3.0 Tests
    LTestSuite.AddTest(028, 'ProgramMessageBox.pas', [], True, True);
    LTestSuite.AddTest(029, 'DirectiveTest.pas', [], True, True);
    LTestSuite.AddTest(030, 'ProgramArraySet.pas', [], True, True);
    LTestSuite.AddTest(031, 'ProgramBreakContinueExit.pas', [], True, True);
    LTestSuite.AddTest(032, 'ProgramRuntimeIntrinsics.pas', [], True, True);
    LTestSuite.AddTest(033, 'ProgramMathFunctions.pas', [], True, True);
    LTestSuite.AddTest(034, 'ProgramSizeOf.pas', [], True, True);
    LTestSuite.AddTest(035, 'ProgramFormat.pas', [], True, True);
    LTestSuite.AddTest(036, 'ProgramFileIO.pas', [], True, True);
    LTestSuite.AddTest(037, 'ProgramBinaryFileIO.pas', [], True, True);
    LTestSuite.AddTest(038, 'ProgramExceptions.pas', [], True, True);
    LTestSuite.AddTest(039, 'ProgramCommandLine.pas', [], True, True);
    LTestSuite.AddTest(040, 'ProgramForwardDeclarations.pas', [], True, True);
    LTestSuite.AddTest(041, 'ProgramStringFunctions.pas', [], True, True);
    LTestSuite.AddTest(042, 'ProgramArrayCopy.pas', [], True, True);
    LTestSuite.AddTest(043, 'LibraryForward.pas', [], True, True);

    // Run the test suite based on command line
    LTestSuite.Run();

  finally
    LTestSuite.Free();
  end;

end;

end.
