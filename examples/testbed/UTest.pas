{===============================================================================
  NitroPascal - Modern Pascal • C Performance

  Copyright © 2025-present tinyBigGAMES™ LLC
  All Rights Reserved.

  https://nitropascal.org

  See LICENSE for license information
===============================================================================}

unit UTest;

interface

uses
  System.Classes,
  System.SysUtils,
  System.IOUtils,
  System.Generics.Collections,
  NitroPascal.Utils,
  NitroPascal.BuildSettings,
  NitroPascal.Compiler;

type
  { TTestEntry }
  TTestEntry = record
    Number: Integer;
    ProjectSrc: string;
    AdditionalSrc: TArray<string>;
    Build: Boolean;
    Run: Boolean;
    Clean: Boolean;
  end;

  { TTest }
  TTest = class
  private
    // ANSI color constants
    const
      COLOR_RESET   = #27'[0m';
      COLOR_BOLD    = #27'[1m';
      COLOR_RED     = #27'[31m';
      COLOR_GREEN   = #27'[32m';
      COLOR_YELLOW  = #27'[33m';
      COLOR_BLUE    = #27'[34m';
      COLOR_CYAN    = #27'[36m';
      COLOR_WHITE   = #27'[37m';

  private
    // Fields
    FTestPath: string;
    FTests: TList<TTestEntry>;
    FProjectDir: string;

    // CLI override flags
    FForceClean: Boolean;
    FForceBuild: Boolean;
    FForceRun: Boolean;
    FNoClean: Boolean;
    FNoBuild: Boolean;
    FNoRun: Boolean;

    // Statistics
    FPassedCount: Integer;
    FFailedCount: Integer;
    FTotalCount: Integer;

    // UI helpers
    function  DetectProjectType(const AFilename: string): TNPTemplate;
    function  GetFilesByExtensions(const APath: string; const AExtensions: array of string): TArray<string>;
    procedure DisplayFile(const AFilename: string);
    procedure CleanProjectFolder(const AProjectDir: string);

    procedure ShowBanner;
    procedure ShowHelp;
    procedure ShowTestList;
    procedure ShowSeparator;

    // CLI parsing
    procedure ParseCommandLine(out ACommand: string; out ATestNumbers: TArray<Integer>);
    function ParseTestSpec(const ASpec: string): TArray<Integer>;
    function ParseRange(const ARange: string): TArray<Integer>;

    // Test management
    function FindTest(const ANumber: Integer; out AEntry: TTestEntry): Boolean;

    // Execution
    procedure ExecuteTest(const ATestNum: Integer);
    procedure ExecuteTestInternal(const AEntry: TTestEntry);

    // Original Test() logic (preserved)
    procedure RunTest(const AProjectSrc: string; const AAdditionalSrc: array of string;
      const ABuild: Boolean; const ARun: Boolean; const AClean: Boolean);

  public
    constructor Create;
    destructor Destroy; override;

    // Configuration
    procedure SetTestPath(const APath: string);
    procedure SetProjectDir(const APath: string);

    // Test management
    procedure AddTest(const ANumber: Integer; const AProjectSrc: string;
      const AAdditionalSrc: array of string; const ABuild: Boolean = False;
      const ARun: Boolean = False; const AClean: Boolean = False);
    procedure ClearTests;

    // Execution methods
    procedure Test(const ANum: Integer); overload;
    procedure Test(const ANumbers: TArray<Integer>); overload;
    procedure Run; // CLI entry point
  end;

implementation

{ TTest }

function TTest.DetectProjectType(const AFilename: string): TNPTemplate;
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

function TTest.GetFilesByExtensions(const APath: string; const AExtensions: array of string): TArray<string>;
var
  LList: TArray<string>;
  LExt: string;
begin
  LList := [];
  for LExt in AExtensions do
    LList := LList + TDirectory.GetFiles(APath, LExt, TSearchOption.soAllDirectories);
  Result := LList;
end;

procedure TTest.DisplayFile(const AFilename: string);
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

procedure TTest.CleanProjectFolder(const AProjectDir: string);
begin
  if TDirectory.Exists(AProjectDir) then
  begin
    TNPUtils.PrintLn('=== CLEANING PROJECT ===');
    TDirectory.Delete(AProjectDir, True);
    TNPUtils.PrintLn('✓ Removed project folder');
    TNPUtils.PrintLn('');
  end;
end;

constructor TTest.Create;
begin
  inherited Create;
  FTests := TList<TTestEntry>.Create();
  FTestPath := '..\src\tests\src';
  FProjectDir := '.\projects';

  // Initialize CLI flags
  FForceClean := False;
  FForceBuild := False;
  FForceRun := False;
  FNoClean := False;
  FNoBuild := False;
  FNoRun := False;

  // Initialize statistics
  FPassedCount := 0;
  FFailedCount := 0;
  FTotalCount := 0;
end;

destructor TTest.Destroy;
begin
  FTests.Free();
  inherited;
end;

procedure TTest.SetTestPath(const APath: string);
begin
  FTestPath := APath;
end;

procedure TTest.SetProjectDir(const APath: string);
begin
  FProjectDir := APath;
end;

procedure TTest.AddTest(const ANumber: Integer; const AProjectSrc: string;
  const AAdditionalSrc: array of string; const ABuild: Boolean;
  const ARun: Boolean; const AClean: Boolean);
var
  LEntry: TTestEntry;
  LSrc: string;
  LIndex: Integer;
begin
  LEntry.Number := ANumber;
  LEntry.ProjectSrc := AProjectSrc;
  LEntry.Build := ABuild;
  LEntry.Run := ARun;
  LEntry.Clean := AClean;

  // Copy additional sources
  SetLength(LEntry.AdditionalSrc, Length(AAdditionalSrc));
  LIndex := 0;
  for LSrc in AAdditionalSrc do
  begin
    LEntry.AdditionalSrc[LIndex] := LSrc;
    Inc(LIndex);
  end;

  FTests.Add(LEntry);
end;

procedure TTest.ClearTests;
begin
  FTests.Clear();
end;

procedure TTest.ShowBanner;
begin
  TNPUtils.PrintLn(COLOR_CYAN + COLOR_BOLD);
  TNPUtils.PrintLn(' _____         _   ____           _ ');
  TNPUtils.PrintLn('|_   _|__  ___| |_| __ )  ___  __| |');
  TNPUtils.PrintLn('  | |/ _ \/ __| __|  _ \ / _ \/ _` |');
  TNPUtils.PrintLn('  | |  __/\__ \ |_| |_) |  __/ (_| |');
  TNPUtils.PrintLn('  |_|\___||___/\__|____/ \___|\__,_|');
  TNPUtils.PrintLn(COLOR_WHITE + '      NitroPascal Test Suite' + COLOR_RESET);
  TNPUtils.PrintLn('');
end;

procedure TTest.ShowHelp;
begin
  ShowBanner();

  TNPUtils.PrintLn(COLOR_BOLD + 'USAGE:' + COLOR_RESET);
  TNPUtils.PrintLn('  testbed ' + COLOR_CYAN + '<command>' + COLOR_RESET + ' [options]');
  TNPUtils.PrintLn('');

  TNPUtils.PrintLn(COLOR_BOLD + 'COMMANDS:' + COLOR_RESET);
  TNPUtils.PrintLn('  ' + COLOR_GREEN + 'run <tests>' + COLOR_RESET + '    Run specified tests');
  TNPUtils.PrintLn('                 Examples:');
  TNPUtils.PrintLn('                   testbed run 1              # Run test 1');
  TNPUtils.PrintLn('                   testbed run 1-10           # Run tests 1 through 10');
  TNPUtils.PrintLn('                   testbed run 1,5,8          # Run tests 1, 5, and 8');
  TNPUtils.PrintLn('                   testbed run 1-5,10,15-20   # Mixed ranges');
  TNPUtils.PrintLn('                   testbed run all            # Run all tests');
  TNPUtils.PrintLn('');
  TNPUtils.PrintLn('  ' + COLOR_GREEN + 'list' + COLOR_RESET + '           List all available tests');
  TNPUtils.PrintLn('  ' + COLOR_GREEN + 'help' + COLOR_RESET + '           Show this help message');
  TNPUtils.PrintLn('  ' + COLOR_GREEN + 'version' + COLOR_RESET + '        Show version information');
  TNPUtils.PrintLn('');

  TNPUtils.PrintLn(COLOR_BOLD + 'OPTIONS:' + COLOR_RESET);
  TNPUtils.PrintLn('  --clean        Clean project folder after each test (OFF by default)');
  TNPUtils.PrintLn('  --no-build     Skip building executable');
  TNPUtils.PrintLn('  --no-run       Skip running executable');
  //TNPUtils.PrintLn('  --path <dir>   Set test source directory');
  TNPUtils.PrintLn('');

  TNPUtils.PrintLn('For more information, visit: ' + COLOR_BLUE + 'https://github.com/tinyBigGAMES/NitroPascal' + COLOR_RESET);
  TNPUtils.PrintLn('');
end;

procedure TTest.ShowTestList;
var
  LEntry: TTestEntry;
  LOptions: string;
begin
  ShowBanner();

  TNPUtils.PrintLn(COLOR_BOLD + 'AVAILABLE TESTS:' + COLOR_RESET);
  TNPUtils.PrintLn('');

  for LEntry in FTests do
  begin
    // Build options string
    LOptions := '';
    if LEntry.Build then
      LOptions := LOptions + 'Build ';
    if LEntry.Run then
      LOptions := LOptions + 'Run ';
    if LEntry.Clean then
      LOptions := LOptions + 'Clean ';
    if LOptions = '' then
      LOptions := 'Compile only';

    TNPUtils.PrintLn('  [%s] %s', [Format('%.3d', [LEntry.Number]), LEntry.ProjectSrc]);
    TNPUtils.PrintLn('       Options: %s%s%s', [COLOR_CYAN, LOptions.Trim(), COLOR_RESET]);

    if Length(LEntry.AdditionalSrc) > 0 then
      TNPUtils.PrintLn('       Additional: %s', [string.Join(', ', LEntry.AdditionalSrc)]);

    TNPUtils.PrintLn('');
  end;

  TNPUtils.PrintLn('Total: %s%d%s tests', [COLOR_BOLD, FTests.Count, COLOR_RESET]);
  TNPUtils.PrintLn('');
end;

procedure TTest.ShowSeparator;
begin
  TNPUtils.PrintLn(COLOR_CYAN + '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━' + COLOR_RESET);
end;

procedure TTest.ParseCommandLine(out ACommand: string; out ATestNumbers: TArray<Integer>);
var
  LIndex: Integer;
  LParam: string;
begin
  ACommand := '';
  SetLength(ATestNumbers, 0);

  // Reset flags
  FForceClean := False;
  FForceBuild := False;
  FForceRun := False;
  FNoClean := False;
  FNoBuild := False;
  FNoRun := False;

  if ParamCount() = 0 then
  begin
    ACommand := 'help';
    Exit;
  end;

  ACommand := LowerCase(ParamStr(1));

  // Parse remaining parameters
  LIndex := 2;
  while LIndex <= ParamCount() do
  begin
    LParam := ParamStr(LIndex);

    if LParam.StartsWith('--') then
    begin
      // Handle flags
      if LParam = '--clean' then
        FForceClean := True
      else if LParam = '--no-build' then
        FNoBuild := True
      else if LParam = '--no-run' then
        FNoRun := True
      else if (LParam = '--path') and (LIndex < ParamCount()) then
      begin
        Inc(LIndex);
        FTestPath := ParamStr(LIndex);
      end;
    end
    else
    begin
      // Test specification
      ATestNumbers := ParseTestSpec(LParam);
    end;

    Inc(LIndex);
  end;
end;

function TTest.ParseTestSpec(const ASpec: string): TArray<Integer>;
var
  LParts: TArray<string>;
  LPartIndex: string;
  LPart: string;
  LPartResults: TArray<Integer>;
  LNum: Integer;
  LIndex: Integer;
begin
  SetLength(Result, 0);

  // Handle "all" keyword
  if LowerCase(ASpec) = 'all' then
  begin
    SetLength(Result, FTests.Count);
    LIndex := 0;
    for LNum := 0 to FTests.Count - 1 do
    begin
      Result[LIndex] := FTests[LNum].Number;
      Inc(LIndex);
    end;
    Exit;
  end;

  // Split by comma
  LParts := ASpec.Split([',']);

  for LPartIndex in LParts do
  begin
    LPart := LPartIndex.Trim();

    if LPart.Contains('-') then
    begin
      // Range: 1-10
      LPartResults := ParseRange(LPart);
      Result := Result + LPartResults;
    end
    else
    begin
      // Single number: 5
      if TryStrToInt(LPart, LNum) then
      begin
        SetLength(Result, Length(Result) + 1);
        Result[High(Result)] := LNum;
      end;
    end;
  end;
end;

function TTest.ParseRange(const ARange: string): TArray<Integer>;
var
  LParts: TArray<string>;
  LStart: Integer;
  LEnd: Integer;
  LIndex: Integer;
  LCurrent: Integer;
begin
  SetLength(Result, 0);

  LParts := ARange.Split(['-']);
  if Length(LParts) <> 2 then
    Exit;

  if not TryStrToInt(LParts[0].Trim(), LStart) then
    Exit;

  if not TryStrToInt(LParts[1].Trim(), LEnd) then
    Exit;

  if LStart > LEnd then
    Exit;

  SetLength(Result, LEnd - LStart + 1);
  LIndex := 0;
  for LCurrent := LStart to LEnd do
  begin
    Result[LIndex] := LCurrent;
    Inc(LIndex);
  end;
end;

function TTest.FindTest(const ANumber: Integer; out AEntry: TTestEntry): Boolean;
var
  LTest: TTestEntry;
begin
  Result := False;
  for LTest in FTests do
  begin
    if LTest.Number = ANumber then
    begin
      AEntry := LTest;
      Exit(True);
    end;
  end;
end;

procedure TTest.ExecuteTest(const ATestNum: Integer);
var
  LEntry: TTestEntry;
begin
  if not FindTest(ATestNum, LEntry) then
  begin
    TNPUtils.PrintLn(COLOR_RED + 'Error: ' + COLOR_RESET + 'Test %d not found', [ATestNum]);
    Inc(FFailedCount);
    Exit;
  end;

  ExecuteTestInternal(LEntry);
end;

procedure TTest.ExecuteTestInternal(const AEntry: TTestEntry);
var
  LBuild: Boolean;
  LRun: Boolean;
  LClean: Boolean;
  LStartTime: TDateTime;
  LElapsed: Double;
begin
  // Apply test defaults
  LBuild := AEntry.Build;
  LRun := AEntry.Run;
  LClean := AEntry.Clean;

  // Apply CLI overrides
  if FNoBuild then
    LBuild := False;
  if FNoRun then
    LRun := False;
  if FNoClean then
    LClean := False;
  if FForceBuild then
    LBuild := True;
  if FForceRun then
    LRun := True;
  if FForceClean then
    LClean := True;

  // Show test header
  TNPUtils.PrintLn('');
  TNPUtils.PrintLn(COLOR_BOLD + '[%s] %s' + COLOR_RESET, [Format('%.3d', [AEntry.Number]), AEntry.ProjectSrc]);

  LStartTime := Now;

  try
    // Execute the test
    RunTest(AEntry.ProjectSrc, AEntry.AdditionalSrc, LBuild, LRun, LClean);

    // Calculate elapsed time
    LElapsed := (Now - LStartTime) * 86400; // Convert to seconds

    // Show success
    TNPUtils.PrintLn('      %s✓ PASSED%s (%.1fs)', [COLOR_GREEN, COLOR_RESET, LElapsed]);
    Inc(FPassedCount);
  except
    on E: Exception do
    begin
      // Calculate elapsed time
      LElapsed := (Now - LStartTime) * 86400;

      // Show failure
      TNPUtils.PrintLn('      %s✗ FAILED%s (%.1fs)', [COLOR_RED, COLOR_RESET, LElapsed]);
      TNPUtils.PrintLn('      Error: %s', [E.Message]);
      Inc(FFailedCount);
    end;
  end;

  Inc(FTotalCount);
end;

procedure TTest.RunTest(const AProjectSrc: string; const AAdditionalSrc: array of string;
  const ABuild: Boolean; const ARun: Boolean; const AClean: Boolean);
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
  LFilename := TPath.Combine(FTestPath, AProjectSrc);

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
    LCompiler.Init(LProjectName, FProjectDir, LProjectType);
    TNPUtils.PrintLn('');

    // 3. Copy source files to project
    TNPUtils.PrintLn('=== COPYING SOURCE FILES ===');
    LProjectDir := TPath.Combine(FProjectDir, LProjectName);
    LProjectSrcDir := TPath.Combine(LProjectDir, 'src');

    // Copy main project source
    LDestFile := TPath.Combine(LProjectSrcDir, TPath.GetFileName(LFilename));
    TNPUtils.CopyFilePreservingEncoding(LFilename, LDestFile);
    TNPUtils.PrintLn('Copied: %s', [TPath.GetFileName(LFilename)]);

    // Copy additional sources
    for LSrcFile in AAdditionalSrc do
    begin
      LFilename := TPath.Combine(FTestPath, LSrcFile);
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
    if AClean then
      CleanProjectFolder(LProjectDir);

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

procedure TTest.Test(const ANum: Integer);
begin
  FPassedCount := 0;
  FFailedCount := 0;
  FTotalCount := 0;

  ExecuteTest(ANum);
end;

procedure TTest.Test(const ANumbers: TArray<Integer>);
var
  LNum: Integer;
begin
  FPassedCount := 0;
  FFailedCount := 0;
  FTotalCount := 0;

  if Length(ANumbers) = 0 then
    Exit;

  ShowBanner();
  TNPUtils.PrintLn('Running %d tests', [Length(ANumbers)]);
  ShowSeparator();

  for LNum in ANumbers do
    ExecuteTest(LNum);

  ShowSeparator();
  TNPUtils.PrintLn('');
  TNPUtils.PrintLn(COLOR_BOLD + 'Results: ' + COLOR_RESET +
    COLOR_GREEN + '%d passed' + COLOR_RESET + ', ' +
    COLOR_RED + '%d failed' + COLOR_RESET + ', ' +
    '%d total',
    [FPassedCount, FFailedCount, FTotalCount]);
  TNPUtils.PrintLn('');
end;

procedure TTest.Run;
var
  LCommand: string;
  LTestNumbers: TArray<Integer>;
  LVersion: TNPVersionInfo;
begin
  ParseCommandLine(LCommand, LTestNumbers);

  // Handle commands
  if (LCommand = 'help') or (LCommand = '-h') or (LCommand = '--help') then
  begin
    ShowHelp();
    Exit;
  end;

  if (LCommand = 'version') or (LCommand = '--version') then
  begin
    ShowBanner();
    if TNPUtils.GetVersionInfo(LVersion) then
      TNPUtils.PrintLn('Version: %s', [LVersion.VersionString])
    else
      TNPUtils.PrintLn('Version: Unknown');
    TNPUtils.PrintLn('');
    TNPUtils.PrintLn('Copyright © 2025-present tinyBigGAMES™ LLC');
    TNPUtils.PrintLn('All Rights Reserved.');
    TNPUtils.PrintLn('');
    Exit;
  end;

  if LCommand = 'list' then
  begin
    ShowTestList();
    Exit;
  end;

  if LCommand = 'run' then
  begin
    if Length(LTestNumbers) = 0 then
    begin
      TNPUtils.PrintLn('');
      TNPUtils.PrintLn(COLOR_RED + 'Error: ' + COLOR_RESET + 'No tests specified');
      TNPUtils.PrintLn('');
      TNPUtils.PrintLn('Usage: testbed run <tests>');
      TNPUtils.PrintLn('Example: testbed run 1-10');
      TNPUtils.PrintLn('');
      Exit;
    end;

    Test(LTestNumbers);
    Exit;
  end;

  // Unknown command or no command - show help
  if LCommand <> '' then
  begin
    TNPUtils.PrintLn('');
    TNPUtils.PrintLn(COLOR_RED + 'Error: ' + COLOR_RESET + 'Unknown command: ' + COLOR_YELLOW + LCommand + COLOR_RESET);
    TNPUtils.PrintLn('');
  end;

  ShowHelp();
end;

end.
