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
  System.Math,
  System.Generics.Collections,
  NitroPascal.Types,
  NitroPascal.Lexer,
  NitroPascal.Parser,
  NitroPascal.Symbols,
  NitroPascal.Resolver,
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
    
  public
    constructor Create();
    destructor Destroy; override;
    
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
    
    property Target: string read FTarget write FTarget;
    property Optimize: TNPOptimizeMode read FOptimize write FOptimize;
    property EnableExceptions: Boolean read FEnableExceptions write FEnableExceptions;
    property StripSymbols: Boolean read FStripSymbols write FStripSymbols;
  end;

  TNPCompilerOutputCallback = reference to procedure(const AText: string; const AUserData: Pointer);

  { TNPCompiler }
  TNPCompiler = class
  private
    FResolver: TNPModuleResolver;
    FSymbolTables: TObjectDictionary<string, TNPSymbolTable>;
    FErrors: TList<TNPError>;
    FGeneratedFiles: TList<TNPGeneratedFile>;
    FProjectName: string;
    FProjectDir: string;
    FBuildSettings: TNPBuildSettings;
    FOutputCallback: TNPCallback<TNPCompilerOutputCallback>;
    
    procedure CollectErrors(const AErrors: TArray<TNPError>);
    procedure AddError(const APos: TNPSourcePos; const AMsg: string);
    procedure ApplyDirectives(const ADirectives: TDictionary<string, string>);
    
    function CompileModule(const AFilename: string): TNPModule;
    function GenerateCodeForModule(const AModule: TNPModule): Boolean;
    function InferCompilationMode(const ASource: string; const AFilename: string): TNPCompilationMode;
    
    procedure UpdateBuildZig();
    
  public
    constructor Create();
    destructor Destroy; override;

    procedure SetOutputCallback(const ACallback: TNPCompilerOutputCallback; const AUserData: Pointer);

    procedure Print(const AText: string); overload;
    procedure Print(const AText: string; const AArgs: array of const); overload;
    procedure PrintLn(const AText: string); overload;
    procedure PrintLn(const AText: string; const AArgs: array of const); overload;

    // Main API
    function CompileFromFile(const AFilename: string): Boolean;
    
    // Module search paths
    procedure AddModuleSearchPath(const APath: string);
    
    // Error reporting
    function HasErrors(): Boolean;
    function GetErrors(): TArray<TNPError>;
    procedure PrintErrors();
    
    // Generated code access
    function GetGeneratedFiles(): TArray<TNPGeneratedFile>;
    
    // Save generated files
    function SaveOutput(const AOutputDir: string): Boolean;
    
    // Clear state
    procedure Clear();
    
    // Project management
    procedure Init(const AProjectName: string; const ABaseDir: string);
    procedure Build();
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
  WinApi.Windows;

const
  MAIN_PAS_TEMPLATE =
  '''
  program %s;

  extern <stdio.h> routine printf(format: ^char; ...): int;

  begin
    printf("Hello from NitroPascal!\n");
    ExitCode := 0;
  end.
  ''';


{ TNPBuildSettings }

constructor TNPBuildSettings.Create();
begin
  inherited Create();
  
  FTarget := '';
  FOptimize := omDebug;
  FEnableExceptions := False;
  FStripSymbols := False;
  
  FModulePaths := TStringList.Create();
  FIncludePaths := TStringList.Create();
  FLibraryPaths := TStringList.Create();
  FLinkLibraries := TStringList.Create();
end;

destructor TNPBuildSettings.Destroy;
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
  FErrors := TList<TNPError>.Create();
  FSymbolTables := TObjectDictionary<string, TNPSymbolTable>.Create([doOwnsValues]);
  FGeneratedFiles := TList<TNPGeneratedFile>.Create();
  FProjectName := '';
  FProjectDir := '';
  FBuildSettings := TNPBuildSettings.Create();
  
  FResolver := TNPModuleResolver.Create(
    function(AFilename: string): TNPModule
    begin
      Result := CompileModule(AFilename);
    end
  );
end;

destructor TNPCompiler.Destroy;
begin
  FResolver.Free();
  FSymbolTables.Free();
  FErrors.Free();
  FGeneratedFiles.Free();
  FBuildSettings.Free();
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
  if Assigned(FOutputCallback.Callback) then
    FOutputCallback.Callback(AText, FOutputCallback.UserData)
  else
    TNPUtils.Print(AText, AArgs);
end;

procedure TNPCompiler.PrintLn(const AText: string);
begin
  if Assigned(FOutputCallback.Callback) then
    FOutputCallback.Callback(AText, FOutputCallback.UserData)
  else
    TNPUtils.PrintLn(AText);
end;

procedure TNPCompiler.PrintLn(const AText: string; const AArgs: array of const);
begin
  if Assigned(FOutputCallback.Callback) then
    FOutputCallback.Callback(AText, FOutputCallback.UserData)
  else
    TNPUtils.PrintLn(AText, AArgs);
end;

procedure TNPCompiler.CollectErrors(const AErrors: TArray<TNPError>);
var
  LError: TNPError;
begin
  for LError in AErrors do
    FErrors.Add(LError);
end;

procedure TNPCompiler.AddError(const APos: TNPSourcePos; const AMsg: string);
begin
  FErrors.Add(TNPError.Create(APos, AMsg));
end;

procedure TNPCompiler.ApplyDirectives(const ADirectives: TDictionary<string, string>);
var
  LPair: TPair<string, string>;
  LPaths: TArray<string>;
  LPathItem: string;
  LPath: string;
begin
  for LPair in ADirectives do
  begin
    // Target platform
    if LPair.Key = 'target' then
      FBuildSettings.Target := LPair.Value
      
    // Optimization level
    else if LPair.Key = 'optimize' then
    begin
      if LPair.Value = 'debug' then
        FBuildSettings.Optimize := omDebug
      else if LPair.Value = 'release_safe' then
        FBuildSettings.Optimize := omReleaseSafe
      else if LPair.Value = 'release_fast' then
        FBuildSettings.Optimize := omReleaseFast
      else if LPair.Value = 'release_small' then
        FBuildSettings.Optimize := omReleaseSmall;
    end
    
    // Exceptions
    else if LPair.Key = 'exceptions' then
      FBuildSettings.EnableExceptions := (LPair.Value = 'on')
      
    // Strip symbols
    else if LPair.Key = 'strip_symbols' then
      FBuildSettings.StripSymbols := (LPair.Value = 'on')
      
    // Module paths (semicolon-separated)
    else if LPair.Key = 'module_path' then
    begin
      LPaths := LPair.Value.Split([';']);
      for LPathItem in LPaths do
      begin
        LPath := LPathItem.Trim();
        if not LPath.IsEmpty then
        begin
          FBuildSettings.AddModulePath(LPath);
          FResolver.AddSearchPath(LPath);
        end;
      end;
    end
    
    // Include paths
    else if LPair.Key = 'include_path' then
    begin
      LPaths := LPair.Value.Split([';']);
      for LPathItem in LPaths do
      begin
        LPath := LPathItem.Trim();
        if not LPath.IsEmpty then
          FBuildSettings.AddIncludePath(LPath);
      end;
    end
    
    // Library paths
    else if LPair.Key = 'library_path' then
    begin
      LPaths := LPair.Value.Split([';']);
      for LPathItem in LPaths do
      begin
        LPath := LPathItem.Trim();
        if not LPath.IsEmpty then
          FBuildSettings.AddLibraryPath(LPath);
      end;
    end
    
    // Link libraries
    else if LPair.Key = 'link_library' then
    begin
      LPaths := LPair.Value.Split([';']);
      for LPathItem in LPaths do
      begin
        LPath := LPathItem.Trim();
        if not LPath.IsEmpty then
          FBuildSettings.AddLinkLibrary(LPath);
      end;
    end;
  end;
end;

function TNPCompiler.InferCompilationMode(const ASource: string; const AFilename: string): TNPCompilationMode;
var
  LTempLexer: TNPLexer;
  LToken: TNPToken;
begin
  // Use lexer to skip preprocessor directives and find first real token
  LTempLexer := TNPLexer.Create(ASource, AFilename);
  try
    LToken := LTempLexer.NextToken();
    
    case LToken.Kind of
      tkProgram: Result := cmProgram;
      tkModule: Result := cmModule;
      tkLibrary: Result := cmLibrary;
    else
      Result := cmProgram; // Default
    end;
  finally
    LTempLexer.Free();
  end;
end;

function TNPCompiler.CompileModule(const AFilename: string): TNPModule;
var
  LSource: string;
  LModuleName: string;
  LMode: TNPCompilationMode;
  LLexer: TNPLexer;
  LParser: TNPParser;
  LSymbolBuilder: TNPSymbolTableBuilder;
  LAST: TNPASTNode;
  LSymbols: TNPSymbolTable;
begin
  Result := Default(TNPModule);
  
  try
    // Read source file
    if not TFile.Exists(AFilename) then
    begin
      AddError(TNPSourcePos.Create(AFilename, 0, 0), 'File not found: ' + AFilename);
      Exit;
    end;
    
    LSource := TFile.ReadAllText(AFilename);
    LModuleName := TPath.GetFileNameWithoutExtension(AFilename);
    LMode := InferCompilationMode(LSource, AFilename);
    
    // Lexical analysis (with integrated preprocessing)
    LLexer := TNPLexer.Create(LSource, AFilename);
    try
      if LLexer.HasErrors() then
      begin
        CollectErrors(LLexer.GetErrors());
        Exit;
      end;
      
      // Parsing
      LParser := TNPParser.Create(LLexer);
      try
        LAST := LParser.Parse(LMode);
        
        if LParser.HasErrors() then
        begin
          CollectErrors(LParser.GetErrors());
          if Assigned(LAST) then
            LAST.Free();
          Exit;
        end;
        
        if not Assigned(LAST) then
        begin
          AddError(TNPSourcePos.Create(AFilename, 0, 0), 'Failed to parse file');
          Exit;
        end;
        
        // Apply compiler directives from source
        ApplyDirectives(LParser.GetDirectives());
        
        // Symbol table building
        LSymbolBuilder := TNPSymbolTableBuilder.Create();
        try
          LSymbols := LSymbolBuilder.Build(LAST, LModuleName);
          
          if LSymbolBuilder.HasErrors() then
          begin
            CollectErrors(LSymbolBuilder.GetErrors());
            LAST.Free();
            Exit;
          end;
          
          // Store symbol table
          if not FSymbolTables.ContainsKey(LModuleName) then
            FSymbolTables.Add(LModuleName, LSymbols);
          
          // Build result
          Result.Filename := AFilename;
          Result.ModuleName := LModuleName;
          Result.AST := LAST;
          Result.Symbols := LSymbols;
          Result.Compiled := True;
          
        finally
          LSymbolBuilder.Free();
        end;
      finally
        LParser.Free();
      end;
    finally
      LLexer.Free();
    end;
    
  except
    on E: Exception do
    begin
      AddError(TNPSourcePos.Create(AFilename, 0, 0), 'Exception during compilation: ' + E.Message);
      if Assigned(Result.AST) then
        Result.AST.Free();
      Result := Default(TNPModule);
    end;
  end;
end;

function TNPCompiler.GenerateCodeForModule(const AModule: TNPModule): Boolean;
var
  LCodeGen: TNPCodeGenerator;
  LHeaderFile: TNPGeneratedFile;
  LImplFile: TNPGeneratedFile;
begin
  Result := False;
  
  LCodeGen := TNPCodeGenerator.Create(AModule.Symbols);
  try
    if not LCodeGen.Generate(AModule.AST, AModule.ModuleName) then
    begin
      CollectErrors(LCodeGen.GetErrors());
      Exit;
    end;
    
    // Create header file
    LHeaderFile.Filename := AModule.ModuleName + '.h';
    LHeaderFile.Content := LCodeGen.GetHeaderCode();
    LHeaderFile.IsHeader := True;
    FGeneratedFiles.Add(LHeaderFile);
    
    // Create implementation file
    LImplFile.Filename := AModule.ModuleName + '.cpp';
    LImplFile.Content := LCodeGen.GetImplementationCode();
    LImplFile.IsHeader := False;
    FGeneratedFiles.Add(LImplFile);
    
    Result := True;
  finally
    LCodeGen.Free();
  end;
end;

function TNPCompiler.CompileFromFile(const AFilename: string): Boolean;
var
  LMainModule: TNPModule;
  LCompilationOrder: TArray<string>;
  LModuleName: string;
  LModule: TNPModule;
  LDir: string;
begin
  Result := False;
  FErrors.Clear();
  FGeneratedFiles.Clear();
  
  try
    // Add file's directory to search paths
    LDir := TPath.GetDirectoryName(AFilename);
    if not LDir.IsEmpty then
      FResolver.AddSearchPath(LDir);
    
    // Compile main file
    LMainModule := CompileModule(AFilename);
    if not Assigned(LMainModule.AST) then
      Exit;
    
    // Resolve all imports recursively
    if not FResolver.ResolveImports(LMainModule) then
    begin
      CollectErrors(FResolver.GetErrors());
      Exit;
    end;
    
    // Get compilation order (topologically sorted)
    LCompilationOrder := FResolver.GetCompilationOrder();
    
    // Generate code for each module in order
    for LModuleName in LCompilationOrder do
    begin
      LModule := FResolver.GetModule(LModuleName);
      if not GenerateCodeForModule(LModule) then
        Exit;
    end;
    
    // Generate code for main module (if not already in list)
    if not FResolver.HasModule(LMainModule.ModuleName) then
    begin
      if not GenerateCodeForModule(LMainModule) then
        Exit;
    end;
    
    Result := not HasErrors();
    
  except
    on E: Exception do
    begin
      AddError(TNPSourcePos.Create(AFilename, 0, 0), 'Unhandled exception: ' + E.Message);
      Result := False;
    end;
  end;
end;

procedure TNPCompiler.AddModuleSearchPath(const APath: string);
begin
  FResolver.AddSearchPath(APath);
end;

function TNPCompiler.HasErrors(): Boolean;
begin
  Result := FErrors.Count > 0;
end;

function TNPCompiler.GetErrors(): TArray<TNPError>;
begin
  Result := FErrors.ToArray();
end;

procedure TNPCompiler.PrintErrors();
var
  LError: TNPError;
begin

  //if not TNPUtils.HasConsole() then
  //  Exit;

  for LError in FErrors do
  begin
    PrintLn(LError.ToString());
  end;
end;

function TNPCompiler.GetGeneratedFiles(): TArray<TNPGeneratedFile>;
begin
  Result := FGeneratedFiles.ToArray();
end;

function TNPCompiler.SaveOutput(const AOutputDir: string): Boolean;
var
  LFile: TNPGeneratedFile;
  LFullPath: string;
begin
  Result := True;
  
  try
    // Create output directory if needed
    if not TDirectory.Exists(AOutputDir) then
      TDirectory.CreateDirectory(AOutputDir);
    
    // Save each generated file
    for LFile in FGeneratedFiles do
    begin
      LFullPath := TPath.Combine(AOutputDir, LFile.Filename);
      
      try
        TFile.WriteAllText(LFullPath, LFile.Content);
      except
        on E: Exception do
        begin
          AddError(TNPSourcePos.Create(LFile.Filename, 0, 0), 
                   'Failed to write file: ' + E.Message);
          Result := False;
        end;
      end;
    end;
    
  except
    on E: Exception do
    begin
      AddError(TNPSourcePos.Create('', 0, 0), 
               'Failed to save output: ' + E.Message);
      Result := False;
    end;
  end;
end;

procedure TNPCompiler.Clear();
begin
  FErrors.Clear();
  FGeneratedFiles.Clear();
  FSymbolTables.Clear();
  FResolver.Clear();
end;

procedure TNPCompiler.UpdateBuildZig();
var
  LBuildZigPath: string;
  LBuilder: TStringBuilder;
  LFile: TNPGeneratedFile;
  LPath: string;
  LLibrary: string;
  LOptimizeMode: string;
  LTargetParts: TArray<string>;
  LArch: string;
  LOS: string;
  LABI: string;
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
      // Parse and use specified target triple: arch-os[-abi]
      LTargetParts := FBuildSettings.Target.ToLower().Split(['-']);
      LArch := '';
      LOS := '';
      LABI := '';
      
      if Length(LTargetParts) >= 1 then
        LArch := LTargetParts[0];
      if Length(LTargetParts) >= 2 then
        LOS := LTargetParts[1];
      if Length(LTargetParts) >= 3 then
        LABI := LTargetParts[2];
      
      // Generate resolveTargetQuery call
      LBuilder.AppendLine('    const target = b.resolveTargetQuery(.{');
      if not LArch.IsEmpty then
        LBuilder.AppendLine('        .cpu_arch = .' + LArch + ',');
      if not LOS.IsEmpty then
        LBuilder.AppendLine('        .os_tag = .' + LOS + ',');
      if not LABI.IsEmpty then
        LBuilder.AppendLine('        .abi = .' + LABI + ',');
      LBuilder.AppendLine('    });');
    end;
    
    //LBuilder.AppendLine('    const optimize = b.standardOptimizeOption(.{});');
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
    LBuilder.AppendLine('    // Add all generated C++ files');
    for LFile in FGeneratedFiles do
    begin
      if not LFile.IsHeader then
      begin
        LBuilder.AppendLine('    module.addCSourceFile(.{');
        LBuilder.AppendLine('        .file = b.path("generated/' + LFile.Filename + '"),');
        LBuilder.AppendLine('        .flags = &cpp_flags,');
        LBuilder.AppendLine('    });');
      end;
    end;
    LBuilder.AppendLine('');
    
    // Add include paths
    for LPath in FBuildSettings.GetIncludePaths() do
    begin
      LBuilder.AppendLine('    module.addIncludePath(.{ .path = "' + 
        FBuildSettings.NormalizePath(LPath) + '" });');
    end;
    if Length(FBuildSettings.GetIncludePaths()) > 0 then
      LBuilder.AppendLine('');
    
    // Create executable
    LBuilder.AppendLine('    // Create executable');
    LBuilder.AppendLine('    const exe = b.addExecutable(.{');
    LBuilder.AppendLine('        .name = "' + FProjectName + '",');
    LBuilder.AppendLine('        .root_module = module,');
    if FBuildSettings.StripSymbols then
      LBuilder.AppendLine('        .strip = true,');
    LBuilder.AppendLine('    });');
    LBuilder.AppendLine('');
    
    // Link C++ standard library
    LBuilder.AppendLine('    // Link C++ standard library');
    LBuilder.AppendLine('    exe.linkLibCpp();');
    LBuilder.AppendLine('');
    
    // Add library paths
    for LPath in FBuildSettings.GetLibraryPaths() do
    begin
      LBuilder.AppendLine('    exe.addLibraryPath(.{ .path = "' + 
        FBuildSettings.NormalizePath(LPath) + '" });');
    end;
    if Length(FBuildSettings.GetLibraryPaths()) > 0 then
      LBuilder.AppendLine('');
    
    // Link libraries
    for LLibrary in FBuildSettings.GetLinkLibraries() do
    begin
      LBuilder.AppendLine('    exe.linkSystemLibrary("' + LLibrary + '");');
    end;
    if Length(FBuildSettings.GetLinkLibraries()) > 0 then
      LBuilder.AppendLine('');
    
    // Install artifact
    LBuilder.AppendLine('    b.installArtifact(exe);');
    LBuilder.AppendLine('}');
    
    // Write to file
    LBuildZigPath := TPath.Combine(FProjectDir, 'build.zig');
    TFile.WriteAllText(LBuildZigPath, LBuilder.ToString());
    
  finally
    LBuilder.Free();
  end;
end;

procedure TNPCompiler.Init(const AProjectName: string; const ABaseDir: string);
var
  LSrcDir: string;
  LGeneratedDir: string;
  LMainPasPath: string;
  LBuildZigPath: string;
  LBuilder: TStringBuilder;
begin
  FProjectName := AProjectName;
  FProjectDir := TPath.Combine(ABaseDir, AProjectName);
  
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
  
  // Create starter {ProjectName}.pas file
  LMainPasPath := TPath.Combine(LSrcDir, AProjectName + '.pas');
  if not TFile.Exists(LMainPasPath) then
  begin
    TFile.WriteAllText(LMainPasPath, Format(MAIN_PAS_TEMPLATE, [AProjectName]));
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
    LBuilder.AppendLine('        "-fno-exceptions",');
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

procedure TNPCompiler.Build();
var
  LMainPasPath: string;
  LGeneratedDir: string;
  LExitCode: DWORD;
  LEntryPointName: string;
  LLastDescription: string;
  LZigExe: string;

  function GetZigExePath(): string;
  var
    LBase: string;
  begin
    LBase := TPath.GetDirectoryName(ParamStr(0));
    Result := TPath.Combine(
      LBase,
      TPath.Combine('res', TPath.Combine('zig', 'zig.exe'))
    );
  end;

begin
  // Ensure we're in a project
  if FProjectDir.IsEmpty then
    FProjectDir := GetCurrentDir();
  
  if FProjectName.IsEmpty then
    FProjectName := TPath.GetFileName(FProjectDir);
  
  LGeneratedDir := TPath.Combine(FProjectDir, 'generated');
  
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

  // Save generated C++ files
  if not SaveOutput(LGeneratedDir) then
    raise Exception.Create('Failed to save generated files');

  PrintLn('✓ Transpilation complete');
  PrintLn('');

  // Phase 2: Update build.zig with generated files
  UpdateBuildZig();
  PrintLn('✓ Updated build.zig');
  PrintLn('');

  // Phase 3: Call Zig build
  PrintLn('Building with Zig...');
  PrintLn('');

  LExitCode := 0;

  LZigExe := GetZigExePath();
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
      LTrimmed := ALine.Trim;

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
          LDescription := Copy(LTrimmed, LBracketPos + 1, Length(LTrimmed)).Trim;

          if LDescription = LLastDescription then
          begin
            // Same description - overwrite current line
            Print(#13'  %s', [LTrimmed]);
            //TNPUtils.ClearToEOL();
            Print(#27'[0K', []);
          end
          else
          begin
            // New description - start new line
            if LLastDescription <> '' then
              PrintLn(''); // Finalize previous
            Print(#13'  %s', [LTrimmed]);
            //TNPUtils.ClearToEOL();
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
  
  // Determine executable path
  LExePath := TPath.Combine(FProjectDir, 'zig-out' + PathDelim + 'bin' + PathDelim + FProjectName);
  
  {$IFDEF MSWINDOWS}
  LExePath := LExePath + '.exe';
  {$ENDIF}
  
  if not TFile.Exists(LExePath) then
    raise Exception.Create('Error: Executable not found. Did you run "nitro build" first?');

  PrintLn('', []);
  PrintLn('', []);
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
    PrintLn('Program exited with code: %s', [IntToStr(LExitCode)]);
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
    //ForceDeleteDir(LZigCacheDir);
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
  raise Exception.Create('ConvertCHeader: Not yet implemented');
end;

{ Build configuration methods }

procedure TNPCompiler.SetTarget(const ATarget: string);
begin
  FBuildSettings.Target := ATarget;
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
  // Also add to resolver for import resolution
  FResolver.AddSearchPath(APath);
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
