{===============================================================================
  NitroPascal - Modern Pascal • C Performance

  Copyright © 2025-present tinyBigGAMES™ LLC
  All Rights Reserved.

  https://nitropascal.org

  See LICENSE for license information
===============================================================================}

unit UTest;

interface

{ Test Runner }
procedure Test(const AProjectSrc: string; const AAdditionalSrc: array of string;
  const ABuild: Boolean=False; const ARun: Boolean=False;
  const ACleanProject: Boolean=False);

implementation

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  NitroPascal.Utils,
  NitroPascal.Compiler;

function DetectProjectType(const AFilename: string): TNPTemplate;
var
  LLines: TStringList;
  LLine: string;
  LTrimmed: string;
begin
  Result := tpProgram; // Default

  if not TFile.Exists(AFilename) then
    Exit;

  LLines := TStringList.Create();
  try
    LLines.LoadFromFile(AFilename);

    // Find first keyword
    for LLine in LLines do
    begin
      LTrimmed := Trim(LLine).ToLower();

      // Skip empty lines and comments
      if (LTrimmed = '') or LTrimmed.StartsWith('//') or LTrimmed.StartsWith('{') then
        Continue;

      if LTrimmed.StartsWith('program ') then
        Exit(tpProgram)
      else if LTrimmed.StartsWith('library ') then
        Exit(tpLibrary)
      else if LTrimmed.StartsWith('unit ') then
        Exit(tpUnit);
    end;
  finally
    LLines.Free();
  end;
end;

function GetFilesByExtensions(const APath: string; const AExtensions: array of string): TArray<string>;
var
  LList: TArray<string>;
  LExt: string;
begin
  LList := [];
  for LExt in AExtensions do
    LList := LList + TDirectory.GetFiles(APath, LExt, TSearchOption.soAllDirectories);
  Result := LList;
end;

procedure DisplayFile(const AFilename: string);
var
  LContent: string;
begin
  if not TFile.Exists(AFilename) then
  begin
    TNPUtils.PrintLn('File not found: %s', [AFilename]);
    Exit;
  end;

  TNPUtils.PrintLn('--- %s ---', [TPath.GetFileName(AFilename)]);
  LContent := TFile.ReadAllText(AFilename);
  TNPUtils.PrintLn(LContent);
  TNPUtils.PrintLn('');
end;

procedure CleanProject(const AProjectDir: string);
begin
  if TDirectory.Exists(AProjectDir) then
  begin
    TNPUtils.PrintLn('=== CLEANING PROJECT ===');
    TDirectory.Delete(AProjectDir, True);
    TNPUtils.PrintLn('✓ Removed project folder');
    TNPUtils.PrintLn('');
  end;
end;

procedure Test(const AProjectSrc: string; const AAdditionalSrc: array of string; const ABuild: Boolean; const ARun: Boolean; const ACleanProject: Boolean);
var
  LCompiler: TNPCompiler;
  LProjectType: TNPTemplate;
  LProjectName: string;
  LProjectDir: string;
  LProjectSrcDir: string;
  LDestFile: string;
  LSrcFile: string;
  LFiles: TArray<string>;
  LFile: string;
  LFilename: string;
begin
  LFilename := TPath.Combine('..\src\tests\src', AProjectSrc);

  // 1. Detect project type
  TNPUtils.PrintLn('=== DETECTING PROJECT TYPE ===');
  LProjectType := DetectProjectType(LFilename);
  case LProjectType of
    tpProgram: TNPUtils.PrintLn('Detected: Program');
    tpLibrary: TNPUtils.PrintLn('Detected: Library');
    tpUnit:    TNPUtils.PrintLn('Detected: Unit');
  end;
  TNPUtils.PrintLn('');

  // 2. Create compiler and init project
  LProjectName := TPath.GetFileNameWithoutExtension(LFilename);
  TNPUtils.PrintLn('=== INITIALIZING PROJECT: %s ===', [LProjectName]);

  LCompiler := TNPCompiler.Create();
  try
    LCompiler.Init(LProjectName, '.\projects', LProjectType);
    TNPUtils.PrintLn('');

    // 3. Copy source files to project
    TNPUtils.PrintLn('=== COPYING SOURCE FILES ===');
    LProjectDir := TPath.Combine('.\projects', LProjectName);
    LProjectSrcDir := TPath.Combine(LProjectDir, 'src');

    // Copy main project source
    LDestFile := TPath.Combine(LProjectSrcDir, TPath.GetFileName(LFilename));
    TNPUtils.CopyFilePreservingEncoding(LFilename, LDestFile);
    TNPUtils.PrintLn('Copied: %s', [TPath.GetFileName(LFilename)]);

    // Copy additional sources
    for LSrcFile in AAdditionalSrc do
    begin
      LFilename := TPath.Combine('..\src\tests\src', LSrcFile);
      LDestFile := TPath.Combine(LProjectSrcDir, TPath.GetFileName(LFilename));
      TNPUtils.CopyFilePreservingEncoding(LFilename, LDestFile);
      TNPUtils.PrintLn('Copied: %s', [TPath.GetFileName(LFilename)]);
    end;
    TNPUtils.PrintLn('');

    // 4. Display info - SOURCE FILES
    TNPUtils.PrintLn('=== SOURCE FILES ===');
    LFiles := GetFilesByExtensions(LProjectSrcDir, ['*.pas', '*.dpr']);
    for LFile in LFiles do
      DisplayFile(LFile);

    // 5. Compile project
    TNPUtils.PrintLn('=== COMPILING PROJECT ===');
    try
      LCompiler.Build(True);
      TNPUtils.PrintLn('✓ Compilation successful');
    except
      on E: Exception do
      begin
        // Build() already called PrintErrors() before raising exception
        TNPUtils.PrintLn('✗ Compilation failed');
        // Continue to show what was generated (partial results)
      end;
    end;
    TNPUtils.PrintLn('');

    // 6. Display info - JSON FILES
    TNPUtils.PrintLn('=== GENERATED JSON ===');
    LFiles := GetFilesByExtensions(TPath.Combine(LProjectDir, 'generated'), ['*.json']);
    for LFile in LFiles do
      DisplayFile(LFile);

    // 7. Display info - GENERATED C++ FILES
    TNPUtils.PrintLn('=== GENERATED C++ FILES ===');
    LFiles := GetFilesByExtensions(TPath.Combine(LProjectDir, 'generated'), ['*.h', '*.cpp']);
    for LFile in LFiles do
      DisplayFile(LFile);

    // 8. Build project
    if ABuild then
    begin
      TNPUtils.PrintLn('=== BUILDING PROJECT ===');
      LCompiler.Build();
      TNPUtils.PrintLn('');
    end;

    // 9. Optionally run
    if ARun then
    begin
      TNPUtils.PrintLn();
      TNPUtils.PrintLn('=== RUNNING PROJECT ===');
      LCompiler.Run();
    end;

    // 10. Clean project folder
    if ACleanProject then
      CleanProject(LProjectDir);

    // 11. Display any errors
    if LCompiler.HasErrors then
    begin
      TNPUtils.PrintLn();
      LCompiler.PrintErrors();
    end;

  finally
    LCompiler.Free();
  end;
end;

end.
