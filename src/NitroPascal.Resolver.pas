{===============================================================================
  NitroPascal - Modern Pascal • C Performance

  Copyright © 2025-present tinyBigGAMES™ LLC
  All Rights Reserved.

  https://nitropascal.org

  See LICENSE for license information
===============================================================================}

unit NitroPascal.Resolver;

{$I NitroPascal.Defines.inc}

interface

uses
  System.SysUtils,
  System.IOUtils,
  System.Generics.Collections,
  NitroPascal.Types,
  NitroPascal.Symbols;

type
  { TNPModule }
  TNPModule = record
    Filename: string;
    ModuleName: string;
    AST: TNPASTNode;
    Symbols: TNPSymbolTable;
    Imports: TArray<string>;
    Compiled: Boolean;
  end;

  { TNPModuleResolver }
  TNPModuleResolver = class
  private
    FSearchPaths: TList<string>;
    FModules: TDictionary<string, TNPModule>;
    FErrors: TList<TNPError>;
    FCompilerCallback: TFunc<string, TNPModule>;
    
    function FindModuleFile(const AModuleName: string): string;
    function LoadModule(const AModuleName: string): Boolean;
    function DetectCircularDependency(const AModuleName: string; AChain: TList<string>): Boolean;
    function BuildDependencyOrder(): TArray<string>;
    procedure TopologicalSort(const AModuleName: string; AVisited, AStack: TDictionary<string, Boolean>; AResult: TList<string>);
    procedure CollectImports(AAST: TNPASTNode; out AImports: TArray<string>);
    
  public
    constructor Create(const ACompilerCallback: TFunc<string, TNPModule>);
    destructor Destroy; override;
    
    procedure AddSearchPath(const APath: string);
    function ResolveImports(AMainModule: TNPModule): Boolean;
    function GetCompilationOrder(): TArray<string>;
    
    function GetModule(const AName: string): TNPModule;
    function HasModule(const AName: string): Boolean;
    
    function HasErrors(): Boolean;
    function GetErrors(): TArray<TNPError>;
    
    procedure Clear();
  end;

implementation

{ TNPModuleResolver }

constructor TNPModuleResolver.Create(const ACompilerCallback: TFunc<string, TNPModule>);
begin
  inherited Create();
  FSearchPaths := TList<string>.Create();
  FModules := TDictionary<string, TNPModule>.Create();
  FErrors := TList<TNPError>.Create();
  FCompilerCallback := ACompilerCallback;
end;

destructor TNPModuleResolver.Destroy;
begin
  FSearchPaths.Free();
  FModules.Free();
  FErrors.Free();
  inherited;
end;

procedure TNPModuleResolver.AddSearchPath(const APath: string);
begin
  if not FSearchPaths.Contains(APath) then
    FSearchPaths.Add(APath);
end;

function TNPModuleResolver.FindModuleFile(const AModuleName: string): string;
var
  LPath: string;
  LCandidate: string;
begin
  // Try each search path
  for LPath in FSearchPaths do
  begin
    LCandidate := TPath.Combine(LPath, AModuleName + '.np');
    if TFile.Exists(LCandidate) then
      Exit(LCandidate);
  end;
  
  Result := '';
end;

procedure TNPModuleResolver.CollectImports(AAST: TNPASTNode; out AImports: TArray<string>);
var
  LList: TList<string>;
  LNode: TNPASTNode;
  LImportNode: TNPImportNode;
  LProgramNode: TNPProgramNode;
  LModuleNode: TNPModuleNode;
  LLibraryNode: TNPLibraryNode;
begin
  LList := TList<string>.Create();
  try
    if AAST is TNPProgramNode then
    begin
      LProgramNode := TNPProgramNode(AAST);
      for LNode in LProgramNode.Declarations do
      begin
        if LNode is TNPImportNode then
        begin
          LImportNode := TNPImportNode(LNode);
          if not LList.Contains(LImportNode.ModuleName) then
            LList.Add(LImportNode.ModuleName);
        end;
      end;
    end
    else if AAST is TNPModuleNode then
    begin
      LModuleNode := TNPModuleNode(AAST);
      for LNode in LModuleNode.Declarations do
      begin
        if LNode is TNPImportNode then
        begin
          LImportNode := TNPImportNode(LNode);
          if not LList.Contains(LImportNode.ModuleName) then
            LList.Add(LImportNode.ModuleName);
        end;
      end;
    end
    else if AAST is TNPLibraryNode then
    begin
      LLibraryNode := TNPLibraryNode(AAST);
      for LNode in LLibraryNode.Declarations do
      begin
        if LNode is TNPImportNode then
        begin
          LImportNode := TNPImportNode(LNode);
          if not LList.Contains(LImportNode.ModuleName) then
            LList.Add(LImportNode.ModuleName);
        end;
      end;
    end;
    
    AImports := LList.ToArray();
  finally
    LList.Free();
  end;
end;

function TNPModuleResolver.LoadModule(const AModuleName: string): Boolean;
var
  LFilename: string;
  LModule: TNPModule;
  LImportName: string;
  LChain: TList<string>;
begin
  // Already loaded?
  if FModules.ContainsKey(AModuleName) then
    Exit(True);
  
  // Find module file
  LFilename := FindModuleFile(AModuleName);
  if LFilename.IsEmpty then
  begin
    FErrors.Add(TNPError.Create(
      TNPSourcePos.Create('', 0, 0),
      Format('Module not found: %s', [AModuleName])
    ));
    Exit(False);
  end;
  
  // Check for circular dependencies before compiling
  LChain := TList<string>.Create();
  try
    if DetectCircularDependency(AModuleName, LChain) then
    begin
      FErrors.Add(TNPError.Create(
        TNPSourcePos.Create(LFilename, 0, 0),
        Format('Circular dependency detected: %s', [AModuleName])
      ));
      Exit(False);
    end;
  finally
    LChain.Free();
  end;
  
  // Compile the module via callback
  if not Assigned(FCompilerCallback) then
  begin
    FErrors.Add(TNPError.Create(
      TNPSourcePos.Create(LFilename, 0, 0),
      'No compiler callback set'
    ));
    Exit(False);
  end;
  
  LModule := FCompilerCallback(LFilename);
  if not Assigned(LModule.AST) then
  begin
    FErrors.Add(TNPError.Create(
      TNPSourcePos.Create(LFilename, 0, 0),
      Format('Failed to compile module: %s', [AModuleName])
    ));
    Exit(False);
  end;
  
  // Collect imports from the module
  CollectImports(LModule.AST, LModule.Imports);
  
  // Store the module
  FModules.Add(AModuleName, LModule);
  
  // Recursively load imports
  for LImportName in LModule.Imports do
  begin
    if not LoadModule(LImportName) then
      Exit(False);
  end;
  
  Result := True;
end;

function TNPModuleResolver.DetectCircularDependency(const AModuleName: string; AChain: TList<string>): Boolean;
var
  LModule: TNPModule;
  LImportName: string;
begin
  // Check if module is already in the chain
  if AChain.Contains(AModuleName) then
    Exit(True);
  
  // If not yet loaded, no cycle (will be detected during load)
  if not FModules.TryGetValue(AModuleName, LModule) then
    Exit(False);
  
  // Add to chain
  AChain.Add(AModuleName);
  
  // Check imports recursively
  for LImportName in LModule.Imports do
  begin
    if DetectCircularDependency(LImportName, AChain) then
      Exit(True);
  end;
  
  // Remove from chain (backtrack)
  AChain.Delete(AChain.Count - 1);
  
  Result := False;
end;

procedure TNPModuleResolver.TopologicalSort(const AModuleName: string; AVisited, AStack: TDictionary<string, Boolean>; AResult: TList<string>);
var
  LModule: TNPModule;
  LImportName: string;
begin
  // Mark as visited
  AVisited.AddOrSetValue(AModuleName, True);
  
  // Get module
  if not FModules.TryGetValue(AModuleName, LModule) then
    Exit;
  
  // Visit all imports first
  for LImportName in LModule.Imports do
  begin
    if not AVisited.ContainsKey(LImportName) then
      TopologicalSort(LImportName, AVisited, AStack, AResult);
  end;
  
  // Add this module to result
  if not AStack.ContainsKey(AModuleName) then
  begin
    AStack.AddOrSetValue(AModuleName, True);
    AResult.Add(AModuleName);
  end;
end;

function TNPModuleResolver.BuildDependencyOrder(): TArray<string>;
var
  LVisited: TDictionary<string, Boolean>;
  LStack: TDictionary<string, Boolean>;
  LResult: TList<string>;
  LModuleName: string;
begin
  LVisited := TDictionary<string, Boolean>.Create();
  LStack := TDictionary<string, Boolean>.Create();
  LResult := TList<string>.Create();
  try
    // Topologically sort all modules
    for LModuleName in FModules.Keys do
    begin
      if not LVisited.ContainsKey(LModuleName) then
        TopologicalSort(LModuleName, LVisited, LStack, LResult);
    end;
    
    Result := LResult.ToArray();
  finally
    LVisited.Free();
    LStack.Free();
    LResult.Free();
  end;
end;

function TNPModuleResolver.ResolveImports(AMainModule: TNPModule): Boolean;
var
  LImportName: string;
begin
  FErrors.Clear();
  
  // Store main module
  if not FModules.ContainsKey(AMainModule.ModuleName) then
    FModules.Add(AMainModule.ModuleName, AMainModule);
  
  // Collect imports from main module
  CollectImports(AMainModule.AST, AMainModule.Imports);
  
  // Recursively load all imports
  for LImportName in AMainModule.Imports do
  begin
    if not LoadModule(LImportName) then
      Exit(False);
  end;
  
  Result := not HasErrors();
end;

function TNPModuleResolver.GetCompilationOrder(): TArray<string>;
begin
  Result := BuildDependencyOrder();
end;

function TNPModuleResolver.GetModule(const AName: string): TNPModule;
begin
  if not FModules.TryGetValue(AName, Result) then
    Result := Default(TNPModule);
end;

function TNPModuleResolver.HasModule(const AName: string): Boolean;
begin
  Result := FModules.ContainsKey(AName);
end;

function TNPModuleResolver.HasErrors(): Boolean;
begin
  Result := FErrors.Count > 0;
end;

function TNPModuleResolver.GetErrors(): TArray<TNPError>;
begin
  Result := FErrors.ToArray();
end;

procedure TNPModuleResolver.Clear();
begin
  FModules.Clear();
  FErrors.Clear();
end;

end.
