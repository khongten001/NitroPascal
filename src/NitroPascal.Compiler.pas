{===============================================================================
  NitroPascal - Modern Pascal • C Performance

  Copyright © 2025-present tinyBigGAMES™ LLC
  All Rights Reserved.

  https://nitropascal.org

  See LICENSE for license information
===============================================================================}

unit NitroPascal.Compiler;

{$I NitroPascal.Defines.inc}

interface

uses
  System.SysUtils,
  System.IOUtils,
  System.Classes,
  System.Generics.Collections,
  WinApi.Windows,
  NitroPascal.Errors,
  NitroPascal.PasToJSON,
  NitroPascal.CodeGen,
  NitroPascal.Utils;

type
  { TNPOptimizeMode }
  TNPOptimizeMode = (
    omDebug,           // Debug mode with safety checks
    omReleaseSafe,     // Optimized with safety checks
    omReleaseFast,     // Fully optimized, minimal safety
    omReleaseSmall     // Optimized for size
  );

  { TNPTemplate }
  TNPTemplate = (
    tpProgram,     // Program template
    tpLibrary,     // Library template
    tpUnit         // Unit template
  );

  { TNPBuildSettings }
  TNPBuildSettings = class
  private
    FTarget: string;
    FOptimize: TNPOptimizeMode;
    FEnableExceptions: Boolean;
    FStripSymbols: Boolean;
    FModulePaths: TStringList;
    FIncludePaths: TStringList;
    FLibraryPaths: TStringList;
    FLinkLibraries: TStringList;
    
    function NormalizePath(const APath: string): string;
    function IsValidIdentifier(const AValue: string): Boolean;
    
  public
    constructor Create();
    destructor Destroy(); override;
    
    procedure AddModulePath(const APath: string);
    procedure AddIncludePath(const APath: string);
    procedure AddLibraryPath(const APath: string);
    procedure AddLinkLibrary(const ALibrary: string);
    
    procedure ClearModulePaths();
    procedure ClearIncludePaths();
    procedure ClearLibraryPaths();
    procedure ClearLinkLibraries();
    
    function GetModulePaths(): TArray<string>;
    function GetIncludePaths(): TArray<string>;
    function GetLibraryPaths(): TArray<string>;
    function GetLinkLibraries(): TArray<string>;
    
    procedure Reset();
    function ValidateAndNormalizeTarget(const ATarget: string): string;
    
    property Target: string read FTarget write FTarget;
    property Optimize: TNPOptimizeMode read FOptimize write FOptimize;
    property EnableExceptions: Boolean read FEnableExceptions write FEnableExceptions;
    property StripSymbols: Boolean read FStripSymbols write FStripSymbols;
  end;

  TNPCompilerOutputCallback = reference to procedure(const AText: string; const AUserData: Pointer);

  { TNPCompiler }
  TNPCompiler = class
  private
    FErrorManager: TNPErrorManager;
    FProjectName: string;
    FProjectDir: string;
    FBuildSettings: TNPBuildSettings;
    FOutputCallback: TNPCallback<TNPCompilerOutputCallback>;
    FTemplateType: TNPTemplate;
    
    function DetectTemplateTypeFromSource(const AFilename: string): TNPTemplate;
    procedure UpdateBuildZig();
    
  public
    constructor Create();
    destructor Destroy(); override;

    procedure SetOutputCallback(const ACallback: TNPCompilerOutputCallback; const AUserData: Pointer);

    procedure Print(const AText: string); overload;
    procedure Print(const AText: string; const AArgs: array of const); overload;
    procedure PrintLn(const AText: string); overload;
    procedure PrintLn(const AText: string; const AArgs: array of const); overload;

    // Main API
    function CompileFromFile(const AFilename: string): Boolean;

    // Error reporting
    function HasErrors(): Boolean;
    function GetErrors(): TArray<TNPError>;
    procedure PrintErrors();
    
    // Clear state
    procedure Clear();
    
    // Project management
    procedure Init(const AProjectName: string; const ABaseDir: string; const ATemplate: TNPTemplate);
    procedure Build(const ACompileOnly: Boolean=False);
    procedure Run();
    procedure Clean();
    procedure ConvertCHeader(const AInputFile: string; const AOutputFile: string; 
      const ALibraryName: string; const AConvention: string);
    
    // Build configuration methods
    procedure SetTarget(const ATarget: string);
    procedure SetOptimize(const AMode: TNPOptimizeMode);
    procedure SetEnableExceptions(const AEnable: Boolean);
    procedure SetStripSymbols(const AStrip: Boolean);
    
    procedure AddModulePath(const APath: string);
    procedure AddIncludePath(const APath: string);
    procedure AddLibraryPath(const APath: string);
    procedure AddLinkLibrary(const ALibrary: string);
    
    procedure ClearModulePaths();
    procedure ClearIncludePaths();
    procedure ClearLibraryPaths();
    procedure ClearLinkLibraries();
    
    procedure ResetBuildSettings();
  end;

implementation

uses
  NitroPascal.Preprocessor;

const
  TEMPLATE_PROGRAM =
  '''
  program %s;
  begin
    WriteLn(''Hello world, welcome to NitroPascal!'');
  end.
  ''';

  TEMPLATE_LIBRARY =
  '''
  library %s;

  function LibAdd(A: Integer; B: Integer): Integer; cdecl;
  begin
    Result := A + B;
  end;

  function LibMultiply(A: Integer; B: Integer): Integer; stdcall;
  begin
    Result := A * B;
  end;

  exports
    LibAdd,
    LibMultiply;

  begin
  end.

  ''';

  TEMPLATE_UNIT =
  '''
  unit %s;

  interface

  function LibAdd(A: Integer; B: Integer): Integer; cdecl;
  function LibMultiply(A: Integer; B: Integer): Integer; stdcall;

  implementation

  function LibAdd(A: Integer; B: Integer): Integer; cdecl;
  begin
    Result := A + B;
  end;

  function LibMultiply(A: Integer; B: Integer): Integer; stdcall;
  begin
    Result := A * B;
  end;

  end.
  ''';

{ TNPBuildSettings }

constructor TNPBuildSettings.Create();
begin
  inherited Create();
  
  FTarget := '';
  FOptimize := omDebug;
  FEnableExceptions := True;
  FStripSymbols := False;
  
  FModulePaths := TStringList.Create();
  FIncludePaths := TStringList.Create();
  FLibraryPaths := TStringList.Create();
  FLinkLibraries := TStringList.Create();
end;

destructor TNPBuildSettings.Destroy();
begin
  FModulePaths.Free();
  FIncludePaths.Free();
  FLibraryPaths.Free();
  FLinkLibraries.Free();
  inherited;
end;

function TNPBuildSettings.NormalizePath(const APath: string): string;
begin
  // Normalize path separators for Zig (forward slashes)
  Result := StringReplace(APath, '\', '/', [rfReplaceAll]);
end;

function TNPBuildSettings.IsValidIdentifier(const AValue: string): Boolean;
var
  LI: Integer;
  LC: Char;
begin
  Result := False;
  
  if AValue.IsEmpty then
    Exit;
  
  for LI := 1 to AValue.Length do
  begin
    LC := AValue[LI];
    if not CharInSet(LC, ['a'..'z', '0'..'9', '_']) then
      Exit;
  end;
  
  Result := True;
end;

function TNPBuildSettings.ValidateAndNormalizeTarget(const ATarget: string): string;
var
  LTrimmed: string;
  LParts: TArray<string>;
  LI: Integer;
  LPart: string;
begin
  LTrimmed := ATarget.Trim().ToLower();
  
  // Empty or 'native' is valid
  if (LTrimmed = '') or (LTrimmed = 'native') then
    Exit('native');
  
  // Split by dash
  LParts := LTrimmed.Split(['-']);
  
  // Must have 2 or 3 parts: arch-os or arch-os-abi
  if (Length(LParts) < 2) or (Length(LParts) > 3) then
    raise Exception.CreateFmt(
      'Invalid target format: "%s"' + sLineBreak +
      'Expected format: arch-os or arch-os-abi' + sLineBreak +
      'Examples: x86_64-linux, aarch64-macos, wasm32-wasi',
      [ATarget]
    );
  
  // Validate and clean each part
  for LI := 0 to High(LParts) do
  begin
    LPart := LParts[LI].Trim();
    
    // Remove any extra spaces or invalid characters
    if Pos(' ', LPart) > 0 then
    begin
      // If contains space, take last word (handles "triple x86_64" → "x86_64")
      LPart := LPart.Split([' '])[High(LPart.Split([' ']))];
    end;
    
    // Ensure it's a valid identifier (alphanumeric + underscore)
    if not IsValidIdentifier(LPart) then
      raise Exception.CreateFmt(
        'Invalid component "%s" in target "%s"' + sLineBreak +
        'Components must be alphanumeric (a-z, 0-9, _)',
        [LPart, ATarget]
      );
    
    LParts[LI] := LPart;
  end;
  
  // Reconstruct normalized target
  Result := string.Join('-', LParts);
end;

procedure TNPBuildSettings.AddModulePath(const APath: string);
begin
  if not FModulePaths.Contains(APath) then
    FModulePaths.Add(APath);
end;

procedure TNPBuildSettings.AddIncludePath(const APath: string);
begin
  if not FIncludePaths.Contains(APath) then
    FIncludePaths.Add(APath);
end;

procedure TNPBuildSettings.AddLibraryPath(const APath: string);
begin
  if not FLibraryPaths.Contains(APath) then
    FLibraryPaths.Add(APath);
end;

procedure TNPBuildSettings.AddLinkLibrary(const ALibrary: string);
begin
  if not FLinkLibraries.Contains(ALibrary) then
    FLinkLibraries.Add(ALibrary);
end;

procedure TNPBuildSettings.ClearModulePaths();
begin
  FModulePaths.Clear();
end;

procedure TNPBuildSettings.ClearIncludePaths();
begin
  FIncludePaths.Clear();
end;

procedure TNPBuildSettings.ClearLibraryPaths();
begin
  FLibraryPaths.Clear();
end;

procedure TNPBuildSettings.ClearLinkLibraries();
begin
  FLinkLibraries.Clear();
end;

function TNPBuildSettings.GetModulePaths(): TArray<string>;
begin
  Result := FModulePaths.ToStringArray();
end;

function TNPBuildSettings.GetIncludePaths(): TArray<string>;
begin
  Result := FIncludePaths.ToStringArray();
end;

function TNPBuildSettings.GetLibraryPaths(): TArray<string>;
begin
  Result := FLibraryPaths.ToStringArray();
end;

function TNPBuildSettings.GetLinkLibraries(): TArray<string>;
begin
  Result := FLinkLibraries.ToStringArray();
end;

procedure TNPBuildSettings.Reset();
begin
  FTarget := '';
  FOptimize := omDebug;
  FEnableExceptions := False;
  FStripSymbols := False;
  
  FModulePaths.Clear();
  FIncludePaths.Clear();
  FLibraryPaths.Clear();
  FLinkLibraries.Clear();
end;

{ TNPCompiler }

constructor TNPCompiler.Create();
begin
  inherited Create();
  FErrorManager := TNPErrorManager.Create();
  FProjectName := '';
  FProjectDir := '';
  FBuildSettings := TNPBuildSettings.Create();
  FTemplateType := tpProgram;
end;

destructor TNPCompiler.Destroy();
begin
  FBuildSettings.Free();
  FErrorManager.Free();
  inherited;
end;

procedure TNPCompiler.SetOutputCallback(const ACallback: TNPCompilerOutputCallback; const AUserData: Pointer);
begin
  FOutputCallback.Callback := ACallback;
  FOutputCallback.UserData := AUserData;
end;

procedure TNPCompiler.Print(const AText: string);
begin
  if Assigned(FOutputCallback.Callback) then
    FOutputCallback.Callback(AText, FOutputCallback.UserData)
  else
    TNPUtils.Print(AText);
end;

procedure TNPCompiler.Print(const AText: string; const AArgs: array of const);
begin
  Print(Format(AText, AArgs));
end;

procedure TNPCompiler.PrintLn(const AText: string);
begin
  if Assigned(FOutputCallback.Callback) then
    FOutputCallback.Callback(AText + sLineBreak, FOutputCallback.UserData)
  else
    TNPUtils.PrintLn(AText);
end;

procedure TNPCompiler.PrintLn(const AText: string; const AArgs: array of const);
begin
  PrintLn(Format(AText, AArgs));
end;

function TNPCompiler.CompileFromFile(const AFilename: string): Boolean;
var
  LPreprocessor: TNPPreprocessor;
  LParser: TNPPasToJSON;
  LCodeGen: TNPCodeGen;
  LJSONData: string;
  LJSONPath: string;
  LGeneratedDir: string;
begin
  Result := False;
  FErrorManager.ClearErrors();
  
  try
    if not TFile.Exists(AFilename) then
    begin
      FErrorManager.AddError(NP_ERROR_FILENOTFOUND, 0, 0, AFilename, 'File not found: ' + AFilename);
      Exit;
    end;
    
    // Phase 0: Preprocess compiler directives
    LPreprocessor := TNPPreprocessor.Create(Self);
    try
      if not LPreprocessor.ProcessFile(AFilename) then
        Exit;
    finally
      LPreprocessor.Free();
    end;
    
    // Determine generated folder
    if FProjectDir <> '' then
      LGeneratedDir := TPath.Combine(FProjectDir, 'generated')
    else
      LGeneratedDir := TPath.Combine(TPath.GetDirectoryName(AFilename), 'generated');
    
    // Ensure generated directory exists
    if not TDirectory.Exists(LGeneratedDir) then
      TDirectory.CreateDirectory(LGeneratedDir);
    
    // Phase 1: Parse Pascal to JSON
    LParser := TNPPasToJSON.Create();
    try
      LParser.SearchPath := TPath.GetDirectoryName(AFilename);
      LParser.Formatted := True;
      
      if not LParser.Parse(AFilename, FErrorManager) then
        Exit;
      
      LJSONData := LParser.GetJSON();
      
      // Save JSON to generated folder
      LJSONPath := TPath.Combine(LGeneratedDir, TPath.GetFileNameWithoutExtension(AFilename) + '.json');
      TFile.WriteAllText(LJSONPath, LJSONData);
      
    finally
      LParser.Free();
    end;
    
    // Phase 2: Generate C++ from JSON file
    LCodeGen := TNPCodeGen.Create();
    try
      LCodeGen.OutputFolder := LGeneratedDir;
      LCodeGen.CleanOutputFolder := False;
      
      if not LCodeGen.GenerateFromFile(LJSONPath, FErrorManager) then
        Exit;
      
      Result := True;
      
    finally
      LCodeGen.Free();
    end;
    
  except
    on E: Exception do
    begin
      FErrorManager.AddError(NP_ERROR_INTERNAL, 0, 0, AFilename, 'Unhandled exception: ' + E.Message);
      Result := False;
    end;
  end;
end;

function TNPCompiler.HasErrors(): Boolean;
begin
  Result := FErrorManager.HasErrors();
end;

function TNPCompiler.GetErrors(): TArray<TNPError>;
begin
  Result := FErrorManager.GetErrors();
end;

procedure TNPCompiler.PrintErrors();
var
  LError: TNPError;
  LMsg: string;
begin
  for LError in FErrorManager.GetErrors() do
  begin
    if LError.FileName <> '' then
      LMsg := Format('%s(%d,%d): [%s] %s', 
        [LError.FileName, LError.Line, LError.Column, LError.ErrorType, LError.Message])
    else
      LMsg := Format('[%s] %s', [LError.ErrorType, LError.Message]);
    
    PrintLn(LMsg);
  end;
end;

procedure TNPCompiler.Clear();
begin
  FErrorManager.ClearErrors();
end;

function TNPCompiler.DetectTemplateTypeFromSource(const AFilename: string): TNPTemplate;
var
  LContent: string;
  LLine: string;
  LTrimmed: string;
begin
  Result := tpProgram; // Default
  
  if not TFile.Exists(AFilename) then
    Exit;
  
  LContent := TFile.ReadAllText(AFilename);
  
  // Find first keyword
  for LLine in LContent.Split([#13#10, #10]) do
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
end;

procedure TNPCompiler.UpdateBuildZig();
var
  LBuildZigPath: string;
  LBuilder: TStringBuilder;
  LPath: string;
  LLibrary: string;
  LOptimizeMode: string;
  LTargetParts: TArray<string>;
  LArch: string;
  LOS: string;
  LABI: string;
  LFiles: TArray<string>;
  LFile: string;
  LGeneratedDir: string;
begin
  LBuilder := TStringBuilder.Create();
  try
    // Convert optimize mode to Zig enum
    case FBuildSettings.Optimize of
      omDebug:        LOptimizeMode := 'Debug';
      omReleaseSafe:  LOptimizeMode := 'ReleaseSafe';
      omReleaseFast:  LOptimizeMode := 'ReleaseFast';
      omReleaseSmall: LOptimizeMode := 'ReleaseSmall';
    end;

    // Header
    LBuilder.AppendLine('const std = @import("std");');
    LBuilder.AppendLine('');
    LBuilder.AppendLine('pub fn build(b: *std.Build) void {');
    
    // Handle target specification
    if FBuildSettings.Target.IsEmpty() or (FBuildSettings.Target.ToLower() = 'native') then
    begin
      // Use standard target options (allows command-line override)
      LBuilder.AppendLine('    const target = b.standardTargetOptions(.{});');
    end
    else
    begin
      // Parse the validated and normalized target triple: arch-os[-abi]
      // Target is already validated by ValidateAndNormalizeTarget()
      LTargetParts := FBuildSettings.Target.Split(['-']);
      
      // These are guaranteed to be clean (no spaces, valid identifiers)
      LArch := LTargetParts[0];
      LOS := '';
      LABI := '';
      
      if Length(LTargetParts) >= 2 then
        LOS := LTargetParts[1];
      if Length(LTargetParts) >= 3 then
        LABI := LTargetParts[2];
      
      // Generate resolveTargetQuery call
      LBuilder.AppendLine('    const target = b.resolveTargetQuery(.{');
      LBuilder.AppendLine('        .cpu_arch = .' + LArch + ',');
      if not LOS.IsEmpty then
        LBuilder.AppendLine('        .os_tag = .' + LOS + ',');
      if not LABI.IsEmpty then
        LBuilder.AppendLine('        .abi = .' + LABI + ',');
      LBuilder.AppendLine('    });');
    end;
    
    LBuilder.AppendLine('    const optimize = .' + LOptimizeMode + ';');
    LBuilder.AppendLine('');
    
    // Create module
    LBuilder.AppendLine('    // Create module for C++ sources');
    LBuilder.AppendLine('    const module = b.addModule("' + FProjectName + '", .{');
    LBuilder.AppendLine('        .target = target,');
    LBuilder.AppendLine('        .optimize = optimize,');
    LBuilder.AppendLine('        .link_libc = true,');
    LBuilder.AppendLine('    });');
    LBuilder.AppendLine('');
    
    // C++ compiler flags
    LBuilder.AppendLine('    // C++ compiler flags');
    LBuilder.AppendLine('    const cpp_flags = [_][]const u8{');
    LBuilder.AppendLine('        "-std=c++20",');
    if not FBuildSettings.EnableExceptions then
      LBuilder.AppendLine('        "-fno-exceptions",');
    LBuilder.AppendLine('    };');
    LBuilder.AppendLine('');
    
    // Add C++ source files
    LGeneratedDir := TPath.Combine(FProjectDir, 'generated');
    if TDirectory.Exists(LGeneratedDir) then
    begin
      LBuilder.AppendLine('    // Add all generated C++ files');
      LFiles := TDirectory.GetFiles(LGeneratedDir, '*.cpp');
      for LFile in LFiles do
      begin
        LBuilder.AppendLine('    module.addCSourceFile(.{');
        LBuilder.AppendLine('        .file = b.path("generated/' + TPath.GetFileName(LFile) + '"),');
        LBuilder.AppendLine('        .flags = &cpp_flags,');
        LBuilder.AppendLine('    });');
      end;
      LBuilder.AppendLine('');
    end;
    
    // Add runtime source file
    LBuilder.AppendLine('    // Add runtime source');
    LBuilder.AppendLine('    module.addCSourceFile(.{');
    LBuilder.AppendLine('        .file = b.path("runtime/runtime.cpp"),');
    LBuilder.AppendLine('        .flags = &cpp_flags,');
    LBuilder.AppendLine('    });');
    LBuilder.AppendLine('');
    
    // Add include paths
    for LPath in FBuildSettings.GetIncludePaths() do
    begin
      LBuilder.AppendLine('    module.addIncludePath(b.path("' + 
        FBuildSettings.NormalizePath(LPath) + '"));');
    end;
    if Length(FBuildSettings.GetIncludePaths()) > 0 then
      LBuilder.AppendLine('');
    
    // Add runtime include path
    LBuilder.AppendLine('    module.addIncludePath(b.path("runtime"));');
    LBuilder.AppendLine('');
    
    // Create executable/library/static library
    // Note: Symbol stripping is controlled by optimize mode in Zig
    case FTemplateType of
      tpProgram:
        begin
          LBuilder.AppendLine('    // Create executable');
          LBuilder.AppendLine('    const exe = b.addExecutable(.{');
          LBuilder.AppendLine('        .name = "' + FProjectName + '",');
          LBuilder.AppendLine('        .root_module = module,');
          LBuilder.AppendLine('    });');
        end;
      
      tpLibrary:
        begin
          LBuilder.AppendLine('    // Create shared library');
          LBuilder.AppendLine('    const lib = b.addLibrary(.{');
          LBuilder.AppendLine('        .linkage = .dynamic,');
          LBuilder.AppendLine('        .name = "' + FProjectName + '",');
          LBuilder.AppendLine('        .root_module = module,');
          LBuilder.AppendLine('    });');
        end;
      
      tpUnit:
        begin
          LBuilder.AppendLine('    // Create static library');
          LBuilder.AppendLine('    const lib = b.addLibrary(.{');
          LBuilder.AppendLine('        .linkage = .static,');
          LBuilder.AppendLine('        .name = "' + FProjectName + '",');
          LBuilder.AppendLine('        .root_module = module,');
          LBuilder.AppendLine('    });');
        end;
    end;
    LBuilder.AppendLine('');
    
    // Link C++ standard library
    case FTemplateType of
      tpProgram:
        begin
          LBuilder.AppendLine('    // Link C++ standard library');
          LBuilder.AppendLine('    exe.linkLibCpp();');
        end;
      tpLibrary, tpUnit:
        begin
          LBuilder.AppendLine('    // Link C++ standard library');
          LBuilder.AppendLine('    lib.linkLibCpp();');
        end;
    end;
    LBuilder.AppendLine('');
    
    // Add library paths
    case FTemplateType of
      tpProgram:
        begin
          for LPath in FBuildSettings.GetLibraryPaths() do
          begin
            LBuilder.AppendLine('    exe.addLibraryPath(b.path("' + 
              FBuildSettings.NormalizePath(LPath) + '"));');
          end;
        end;
      tpLibrary, tpUnit:
        begin
          for LPath in FBuildSettings.GetLibraryPaths() do
          begin
            LBuilder.AppendLine('    lib.addLibraryPath(b.path("' + 
              FBuildSettings.NormalizePath(LPath) + '"));');
          end;
        end;
    end;
    if Length(FBuildSettings.GetLibraryPaths()) > 0 then
      LBuilder.AppendLine('');
    
    // Link libraries
    case FTemplateType of
      tpProgram:
        begin
          for LLibrary in FBuildSettings.GetLinkLibraries() do
          begin
            LBuilder.AppendLine('    exe.linkSystemLibrary("' + LLibrary + '");');
          end;
        end;
      tpLibrary, tpUnit:
        begin
          for LLibrary in FBuildSettings.GetLinkLibraries() do
          begin
            LBuilder.AppendLine('    lib.linkSystemLibrary("' + LLibrary + '");');
          end;
        end;
    end;
    if Length(FBuildSettings.GetLinkLibraries()) > 0 then
      LBuilder.AppendLine('');
    
    // Install artifact
    case FTemplateType of
      tpProgram:
        LBuilder.AppendLine('    b.installArtifact(exe);');
      tpLibrary, tpUnit:
        LBuilder.AppendLine('    b.installArtifact(lib);');
    end;
    LBuilder.AppendLine('}');
    
    // Write to file
    LBuildZigPath := TPath.Combine(FProjectDir, 'build.zig');
    TFile.WriteAllText(LBuildZigPath, LBuilder.ToString());
    
  finally
    LBuilder.Free();
  end;
end;

procedure TNPCompiler.Init(const AProjectName: string; const ABaseDir: string; const ATemplate: TNPTemplate);
var
  LSrcDir: string;
  LGeneratedDir: string;
  LMainPasPath: string;
  LBuildZigPath: string;
  LBuilder: TStringBuilder;
  LTemplateContent: string;
  LExeDir: string;
  LRuntimeSrcDir: string;
  LRuntimeDestDir: string;
  LRuntimeFiles: TArray<string>;
  LRuntimeFile: string;
  LDestFile: string;
begin
  FProjectName := AProjectName;
  FProjectDir := TPath.Combine(ABaseDir, AProjectName);
  FTemplateType := ATemplate;
  
  PrintLn('Creating project: ' + AProjectName);
  PrintLn('Location: ' + FProjectDir);
  PrintLn('');
  
  // Create directory structure
  if not TDirectory.Exists(FProjectDir) then
    TDirectory.CreateDirectory(FProjectDir);
  
  LSrcDir := TPath.Combine(FProjectDir, 'src');
  if not TDirectory.Exists(LSrcDir) then
    TDirectory.CreateDirectory(LSrcDir);
  
  LGeneratedDir := TPath.Combine(FProjectDir, 'generated');
  if not TDirectory.Exists(LGeneratedDir) then
    TDirectory.CreateDirectory(LGeneratedDir);
  
  PrintLn('✓ Created directory structure');
  
  // Copy runtime files from exe directory
  LRuntimeDestDir := TPath.Combine(FProjectDir, 'runtime');
  if not TDirectory.Exists(LRuntimeDestDir) then
    TDirectory.CreateDirectory(LRuntimeDestDir);
  
  LExeDir := TPath.GetDirectoryName(ParamStr(0));
  LRuntimeSrcDir := TPath.Combine(LExeDir, 'res' + PathDelim + 'runtime');
  
  if TDirectory.Exists(LRuntimeSrcDir) then
  begin
    LRuntimeFiles := TDirectory.GetFiles(LRuntimeSrcDir);
    for LRuntimeFile in LRuntimeFiles do
    begin
      LDestFile := TPath.Combine(LRuntimeDestDir, TPath.GetFileName(LRuntimeFile));
      TFile.Copy(LRuntimeFile, LDestFile, True);
    end;
    PrintLn('✓ Copied runtime files');
  end
  else
  begin
    PrintLn('Warning: Runtime files not found at: ' + LRuntimeSrcDir);
  end;
  
  // Select template based on type
  case ATemplate of
    tpProgram: LTemplateContent := TEMPLATE_PROGRAM;
    tpLibrary: LTemplateContent := TEMPLATE_LIBRARY;
    tpUnit:    LTemplateContent := TEMPLATE_UNIT;
  end;
  
  // Create starter {ProjectName}.pas file
  LMainPasPath := TPath.Combine(LSrcDir, AProjectName + '.pas');
  if not TFile.Exists(LMainPasPath) then
  begin
    TFile.WriteAllText(LMainPasPath, Format(LTemplateContent, [AProjectName]));
    PrintLn('✓ Created src/' + AProjectName + '.pas');
  end;
  
  // Create initial build.zig dynamically
  LBuilder := TStringBuilder.Create();
  try
    LBuilder.AppendLine('const std = @import("std");');
    LBuilder.AppendLine('');
    LBuilder.AppendLine('pub fn build(b: *std.Build) void {');
    LBuilder.AppendLine('    const target = b.standardTargetOptions(.{});');
    LBuilder.AppendLine('    const optimize = b.standardOptimizeOption(.{});');
    LBuilder.AppendLine('');
    LBuilder.AppendLine('    // Create module for C++ sources');
    LBuilder.AppendLine('    const module = b.addModule("' + AProjectName + '", .{');
    LBuilder.AppendLine('        .target = target,');
    LBuilder.AppendLine('        .optimize = optimize,');
    LBuilder.AppendLine('        .link_libc = true,');
    LBuilder.AppendLine('    });');
    LBuilder.AppendLine('');
    LBuilder.AppendLine('    // C++ compiler flags');
    LBuilder.AppendLine('    const cpp_flags = [_][]const u8{');
    LBuilder.AppendLine('        "-std=c++20",');
    LBuilder.AppendLine('    };');
    LBuilder.AppendLine('');
    LBuilder.AppendLine('    // No C++ files yet - run "nitro build" to generate');
    LBuilder.AppendLine('');
    LBuilder.AppendLine('    // Create executable');
    LBuilder.AppendLine('    const exe = b.addExecutable(.{');
    LBuilder.AppendLine('        .name = "' + AProjectName + '",');
    LBuilder.AppendLine('        .root_module = module,');
    LBuilder.AppendLine('    });');
    LBuilder.AppendLine('');
    LBuilder.AppendLine('    // Link C++ standard library');
    LBuilder.AppendLine('    exe.linkLibCpp();');
    LBuilder.AppendLine('');
    LBuilder.AppendLine('    b.installArtifact(exe);');
    LBuilder.AppendLine('}');
    
    LBuildZigPath := TPath.Combine(FProjectDir, 'build.zig');
    TFile.WriteAllText(LBuildZigPath, LBuilder.ToString());
  finally
    LBuilder.Free();
  end;
  
  PrintLn('✓ Created build.zig');

  PrintLn('');
  PrintLn('Project initialized successfully!');
  PrintLn('');
  PrintLn('Next steps:');
  PrintLn('  cd ' + AProjectName);
  PrintLn('  nitro build');
  PrintLn('  nitro run');
end;

procedure TNPCompiler.Build(const ACompileOnly: Boolean);
var
  LMainPasPath: string;
  LExitCode: DWORD;
  LEntryPointName: string;
  LLastDescription: string;
  LZigExe: string;
begin
  // Ensure we're in a project
  if FProjectDir.IsEmpty then
    FProjectDir := GetCurrentDir();
  
  if FProjectName.IsEmpty then
    FProjectName := TPath.GetFileName(FProjectDir);
  
  // Smart entry point detection: Try {ProjectName}.pas first, fallback to main.pas
  LMainPasPath := TPath.Combine(FProjectDir, 'src' + PathDelim + FProjectName + '.pas');
  if TFile.Exists(LMainPasPath) then
  begin
    LEntryPointName := FProjectName + '.pas';
  end
  else
  begin
    // Fallback to main.pas
    LMainPasPath := TPath.Combine(FProjectDir, 'src' + PathDelim + 'main.pas');
    if TFile.Exists(LMainPasPath) then
    begin
      LEntryPointName := 'main.pas';
    end
    else
    begin
      raise Exception.Create('Error: No entry point found. Expected src/' + FProjectName + '.pas or src/main.pas');
    end;
  end;
  
  PrintLn('Entry point: ' + LEntryPointName);
  PrintLn('Compiling NitroPascal to C++...');
  PrintLn('');
  
  // Phase 1: Transpile Pascal → C++
  if not CompileFromFile(LMainPasPath) then
  begin
    PrintErrors();
    raise Exception.Create('Transpilation failed');
  end;

  PrintLn('✓ Transpilation complete');
  PrintLn('');

  // Exit if compile only
  if ACompileOnly then
    Exit;

  // Phase 2: Detect template type from source
  FTemplateType := DetectTemplateTypeFromSource(LMainPasPath);
  
  // Phase 3: Update build.zig with generated files
  UpdateBuildZig();
  PrintLn('✓ Updated build.zig');
  PrintLn('');

  // Phase 4: Call Zig build
  PrintLn('Building with Zig...');
  PrintLn('');

  LExitCode := 0;

  LZigExe := TNPUtils.GetZigExePath();
  if not TFile.Exists(LZigExe) then
  begin
    PrintLn('');
    PrintLn('Error: Zig EXE was not found...');
    Exit;
  end;

  LLastDescription := '';
  TNPUtils.CaptureZigConsoleOutput(
    'Building ' + FProjectName,
    PChar(LZigExe),
    'build',
    FProjectDir,
    LExitCode,
    nil,
    procedure(const ALine: string; const AUserData: Pointer)
    var
      LTrimmed: string;
      LBracketPos: Integer;
      LDescription: string;
    begin
      LTrimmed := ALine.Trim();

      // Skip empty lines
      if LTrimmed = '' then
        Exit;

      // Check if it's a progress line: [N/M] Description
      if (LTrimmed.Length > 0) and (LTrimmed[1] = '[') then
      begin
        LBracketPos := Pos(']', LTrimmed);
        if LBracketPos > 0 then
        begin
          // Extract description after "]"
          LDescription := Copy(LTrimmed, LBracketPos + 1, Length(LTrimmed)).Trim();

          if LDescription = LLastDescription then
          begin
            // Same description - overwrite current line
            Print(#13'  %s', [LTrimmed]);
            Print(#27'[0K', []);
          end
          else
          begin
            // New description - start new line
            if LLastDescription <> '' then
              PrintLn(''); // Finalize previous
            Print(#13'  %s', [LTrimmed]);
            Print(#27'[0K', []);
            LLastDescription := LDescription;
          end;
          Exit;
        end;
      end;

      // Regular non-progress output
      if LLastDescription <> '' then
      begin
        PrintLn(''); // Finalize progress
        LLastDescription := '';
      end;
      PrintLn('  %s', [LTrimmed]);
    end
  );

  if LExitCode <> 0 then
    raise Exception.CreateFmt('Zig build failed with exit code %d', [LExitCode]);
end;

procedure TNPCompiler.Run();
var
  LExePath: string;
  LExitCode: Cardinal;
begin
  // Ensure we're in a project
  if FProjectDir.IsEmpty then
    FProjectDir := GetCurrentDir();
  
  if FProjectName.IsEmpty then
    FProjectName := TPath.GetFileName(FProjectDir);
  
  // Only programs are executable
  if FTemplateType <> tpProgram then
  begin
    FErrorManager.AddError('Warning', 'Cannot run library or unit projects. Only programs are executable.');
    Exit;
  end;

  // Only run on Windows targets
  if not FBuildSettings.Target.IsEmpty() and
     (FBuildSettings.Target.ToLower() <> 'native') then
  begin
    // Check if target is x86_64-windows
    if not FBuildSettings.Target.ToLower().StartsWith('x86_64-windows') then
    begin
      FErrorManager.AddError('Warning', Format('Skipping run: Target "%s" is not Win64. Only Win64 targets can be executed directly.', [FBuildSettings.Target]));
      Exit;
    end;
  end;

  // Determine executable path
  LExePath := TPath.Combine(FProjectDir, 'zig-out' + PathDelim + 'bin' + PathDelim + FProjectName);

  {$IFDEF MSWINDOWS}
  LExePath := LExePath + '.exe';
  {$ENDIF}

  if not TFile.Exists(LExePath) then
    raise Exception.Create('Error: Executable not found. Did you run "nitro build" first?');

  PrintLn('');
  PrintLn('');
  PrintLn('Running ' + FProjectName + '...');
  PrintLn('');

  // Run the executable using TNPUtils.RunExe
  LExitCode := TNPUtils.RunExe(
    LExePath,
    '',
    FProjectDir,
    True,
    SW_SHOW
  );

  if LExitCode <> 0 then
    PrintLn('Program exited with code: %d', [LExitCode]);
end;

procedure TNPCompiler.Clean();
var
  LGeneratedDir: string;
  LZigCacheDir: string;
  LZigOutDir: string;
begin
  // Ensure we're in a project
  if FProjectDir.IsEmpty then
    FProjectDir := GetCurrentDir();

  PrintLn('Cleaning project...');
  PrintLn('');
  
  LGeneratedDir := TPath.Combine(FProjectDir, 'generated');
  LZigCacheDir := TPath.Combine(FProjectDir, '.zig-cache');
  LZigOutDir := TPath.Combine(FProjectDir, 'zig-out');
  
  // Delete generated/ directory
  if TDirectory.Exists(LGeneratedDir) then
  begin
    TDirectory.Delete(LGeneratedDir, True);
    PrintLn('✓ Removed generated/');
  end;
  
  // Delete zig-cache/ directory
  if TDirectory.Exists(LZigCacheDir) then
  begin
    TDirectory.Delete(LZigCacheDir, True);
    PrintLn('✓ Removed zig-cache/');
  end;

  // Delete zig-out/ directory
  if TDirectory.Exists(LZigOutDir) then
  begin
    TDirectory.Delete(LZigOutDir, True);
    PrintLn('✓ Removed zig-out/');
  end;
  
  // Recreate empty generated/ directory
  TDirectory.CreateDirectory(LGeneratedDir);
end;

procedure TNPCompiler.ConvertCHeader(const AInputFile: string; const AOutputFile: string;
  const ALibraryName: string; const AConvention: string);
begin
end;

{ Build configuration methods }

procedure TNPCompiler.SetTarget(const ATarget: string);
begin
  FBuildSettings.Target := FBuildSettings.ValidateAndNormalizeTarget(ATarget);
end;

procedure TNPCompiler.SetOptimize(const AMode: TNPOptimizeMode);
begin
  FBuildSettings.Optimize := AMode;
end;

procedure TNPCompiler.SetEnableExceptions(const AEnable: Boolean);
begin
  FBuildSettings.EnableExceptions := AEnable;
end;

procedure TNPCompiler.SetStripSymbols(const AStrip: Boolean);
begin
  FBuildSettings.StripSymbols := AStrip;
end;

procedure TNPCompiler.AddModulePath(const APath: string);
begin
  FBuildSettings.AddModulePath(APath);
end;

procedure TNPCompiler.AddIncludePath(const APath: string);
begin
  FBuildSettings.AddIncludePath(APath);
end;

procedure TNPCompiler.AddLibraryPath(const APath: string);
begin
  FBuildSettings.AddLibraryPath(APath);
end;

procedure TNPCompiler.AddLinkLibrary(const ALibrary: string);
begin
  FBuildSettings.AddLinkLibrary(ALibrary);
end;

procedure TNPCompiler.ClearModulePaths();
begin
  FBuildSettings.ClearModulePaths();
end;

procedure TNPCompiler.ClearIncludePaths();
begin
  FBuildSettings.ClearIncludePaths();
end;

procedure TNPCompiler.ClearLibraryPaths();
begin
  FBuildSettings.ClearLibraryPaths();
end;

procedure TNPCompiler.ClearLinkLibraries();
begin
  FBuildSettings.ClearLinkLibraries();
end;

procedure TNPCompiler.ResetBuildSettings();
begin
  FBuildSettings.Reset();
end;

end.
