{===============================================================================
  NitroPascal - Modern Pascal • C Performance

  Copyright © 2025-present tinyBigGAMES™ LLC
  All Rights Reserved.

  https://nitropascal.org

  See LICENSE for license information
===============================================================================}

unit NitroPascal.Symbols;

{$I NitroPascal.Defines.inc}

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  NitroPascal.Types;

type
  { TNPSymbolKind }
  TNPSymbolKind = (
    skType,
    skConstant,
    skVariable,
    skRoutine,
    skParameter
  );

  { TNPSymbol }
  TNPSymbol = record
    Name: string;
    Kind: TNPSymbolKind;
    IsPublic: Boolean;
    DeclNode: TNPASTNode;
    SourceModule: string;
    TypeInfo: TNPASTNode;  // Type information if applicable
    class function Create(const AName: string; AKind: TNPSymbolKind; AIsPublic: Boolean; ADeclNode: TNPASTNode; const ASourceModule: string): TNPSymbol; static;
  end;

  { TNPSymbolTable }
  TNPSymbolTable = class
  private
    FSymbols: TDictionary<string, TNPSymbol>;
    FParent: TNPSymbolTable;  // For nested scopes
  public
    constructor Create(AParent: TNPSymbolTable = nil);
    destructor Destroy; override;

    procedure AddSymbol(const ASymbol: TNPSymbol);
    function FindSymbol(const AName: string; const ASearchParent: Boolean = True): TNPSymbol;
    function HasSymbol(const AName: string; const ASearchParent: Boolean = True): Boolean;
    function GetPublicSymbols(): TArray<TNPSymbol>;
    function GetAllSymbols(): TArray<TNPSymbol>;
    
    // Type resolution
    function ResolveType(ATypeNode: TNPASTNode): TNPASTNode;
    function ResolveToSubrange(const ATypeName: string; out ASubrange: TNPSubrangeNode): Boolean;
    
    // Built-in types
    procedure RegisterBuiltInTypes();
    
    procedure Clear();
    
    property Parent: TNPSymbolTable read FParent write FParent;
  end;

  { TNPSymbolTableBuilder }
  TNPSymbolTableBuilder = class
  private
    FCurrentTable: TNPSymbolTable;
    FErrors: TList<TNPError>;
    FModuleName: string;

    procedure AddError(const APos: TNPSourcePos; const AMsg: string);
    procedure ProcessDeclarations(ADecls: TNPASTNodeList);
    procedure ProcessRoutine(ANode: TNPRoutineDeclNode);
    
  public
    constructor Create();
    destructor Destroy; override;
    
    function Build(ARoot: TNPASTNode; const AModuleName: string): TNPSymbolTable;
    
    function HasErrors(): Boolean;
    function GetErrors(): TArray<TNPError>;
  end;

implementation

{ TNPSymbol }

class function TNPSymbol.Create(const AName: string; AKind: TNPSymbolKind; AIsPublic: Boolean; ADeclNode: TNPASTNode; const ASourceModule: string): TNPSymbol;
begin
  Result.Name := AName;
  Result.Kind := AKind;
  Result.IsPublic := AIsPublic;
  Result.DeclNode := ADeclNode;
  Result.SourceModule := ASourceModule;
  Result.TypeInfo := nil;
end;

{ TNPSymbolTable }

constructor TNPSymbolTable.Create(AParent: TNPSymbolTable);
begin
  inherited Create();
  FSymbols := TDictionary<string, TNPSymbol>.Create();
  FParent := AParent;
end;

destructor TNPSymbolTable.Destroy;
begin
  FSymbols.Free();
  inherited;
end;

procedure TNPSymbolTable.AddSymbol(const ASymbol: TNPSymbol);
begin
  FSymbols.AddOrSetValue(ASymbol.Name, ASymbol);
end;

function TNPSymbolTable.FindSymbol(const AName: string; const ASearchParent: Boolean): TNPSymbol;
begin
  if FSymbols.TryGetValue(AName, Result) then
    Exit;
  
  if ASearchParent and Assigned(FParent) then
    Result := FParent.FindSymbol(AName, True)
  else
    Result := TNPSymbol.Create('', skType, False, nil, '');
end;

function TNPSymbolTable.HasSymbol(const AName: string; const ASearchParent: Boolean): Boolean;
begin
  if FSymbols.ContainsKey(AName) then
    Exit(True);
  
  if ASearchParent and Assigned(FParent) then
    Result := FParent.HasSymbol(AName, True)
  else
    Result := False;
end;

function TNPSymbolTable.GetPublicSymbols(): TArray<TNPSymbol>;
var
  LList: TList<TNPSymbol>;
  LPair: TPair<string, TNPSymbol>;
begin
  LList := TList<TNPSymbol>.Create();
  try
    for LPair in FSymbols do
    begin
      if LPair.Value.IsPublic then
        LList.Add(LPair.Value);
    end;
    Result := LList.ToArray();
  finally
    LList.Free();
  end;
end;

function TNPSymbolTable.GetAllSymbols(): TArray<TNPSymbol>;
var
  LList: TList<TNPSymbol>;
  LPair: TPair<string, TNPSymbol>;
begin
  LList := TList<TNPSymbol>.Create();
  try
    for LPair in FSymbols do
      LList.Add(LPair.Value);
    Result := LList.ToArray();
  finally
    LList.Free();
  end;
end;

procedure TNPSymbolTable.Clear();
begin
  FSymbols.Clear();
end;

function TNPSymbolTable.ResolveType(ATypeNode: TNPASTNode): TNPASTNode;
var
  LIdentNode: TNPIdentifierNode;
  LSymbol: TNPSymbol;
  LMaxDepth: Integer;
begin
  Result := ATypeNode;
  
  if not Assigned(ATypeNode) then
    Exit;
  
  // Follow identifier chains to resolve type aliases
  LMaxDepth := 100; // Prevent infinite recursion
  while (Result is TNPIdentifierNode) and (LMaxDepth > 0) do
  begin
    LIdentNode := TNPIdentifierNode(Result);
    
    LSymbol := FindSymbol(LIdentNode.Name, True);
    if (LSymbol.Name = '') or (not Assigned(LSymbol.TypeInfo)) then
      Break; // Cannot resolve further
    
    Result := LSymbol.TypeInfo;
    Dec(LMaxDepth);
  end;
end;

function TNPSymbolTable.ResolveToSubrange(const ATypeName: string; out ASubrange: TNPSubrangeNode): Boolean;
var
  LSymbol: TNPSymbol;
  LResolvedType: TNPASTNode;
begin
  Result := False;
  ASubrange := nil;
  
  // Find the type symbol
  LSymbol := FindSymbol(ATypeName, True);
  if LSymbol.Name = '' then
    Exit;
  
  // Resolve type aliases
  LResolvedType := ResolveType(LSymbol.TypeInfo);
  
  // Check if it's a subrange
  if LResolvedType is TNPSubrangeNode then
  begin
    ASubrange := TNPSubrangeNode(LResolvedType);
    Result := True;
  end;
end;

procedure TNPSymbolTable.RegisterBuiltInTypes();

  // Helper function to create type symbol
  procedure AddBuiltInType(const AName: string);
  var
    LTypeIdent: TNPIdentifierNode;
    LTypeSymbol: TNPSymbol;
  begin
    LTypeIdent := TNPIdentifierNode.Create(TNPSourcePos.Create('', 0, 0));
    LTypeIdent.Name := AName;

    LTypeSymbol := TNPSymbol.Create(AName, skType, True, LTypeIdent, '<built-in>');
    LTypeSymbol.TypeInfo := LTypeIdent;
    AddSymbol(LTypeSymbol);
  end;
begin

  // Register built-in types
  AddBuiltInType('int');
  AddBuiltInType('uint');
  AddBuiltInType('int64');
  AddBuiltInType('uint64');
  AddBuiltInType('int16');
  AddBuiltInType('uint16');
  AddBuiltInType('byte');
  AddBuiltInType('double');
  AddBuiltInType('float');
  AddBuiltInType('bool');
  AddBuiltInType('char');
  AddBuiltInType('string');
  AddBuiltInType('pointer');
end;

{ TNPSymbolTableBuilder }

constructor TNPSymbolTableBuilder.Create();
begin
  inherited Create();
  FErrors := TList<TNPError>.Create();
end;

destructor TNPSymbolTableBuilder.Destroy;
begin
  FErrors.Free();
  inherited;
end;

procedure TNPSymbolTableBuilder.AddError(const APos: TNPSourcePos; const AMsg: string);
begin
  FErrors.Add(TNPError.Create(APos, AMsg));
end;

function TNPSymbolTableBuilder.Build(ARoot: TNPASTNode; const AModuleName: string): TNPSymbolTable;
var
  LProgramNode: TNPProgramNode;
  LModuleNode: TNPModuleNode;
  LLibraryNode: TNPLibraryNode;
begin
  FErrors.Clear();
  FModuleName := AModuleName;
  FCurrentTable := TNPSymbolTable.Create();
  
  // Register built-in types
  FCurrentTable.RegisterBuiltInTypes();
  
  if ARoot is TNPProgramNode then
  begin
    LProgramNode := TNPProgramNode(ARoot);
    ProcessDeclarations(LProgramNode.Declarations);
  end
  else if ARoot is TNPModuleNode then
  begin
    LModuleNode := TNPModuleNode(ARoot);
    ProcessDeclarations(LModuleNode.Declarations);
  end
  else if ARoot is TNPLibraryNode then
  begin
    LLibraryNode := TNPLibraryNode(ARoot);
    ProcessDeclarations(LLibraryNode.Declarations);
  end;
  
  Result := FCurrentTable;
end;

procedure TNPSymbolTableBuilder.ProcessDeclarations(ADecls: TNPASTNodeList);
var
  LNode: TNPASTNode;
  LTypeDecl: TNPTypeDeclNode;
  LConstDecl: TNPConstDeclNode;
  LVarDecl: TNPVarDeclNode;
  LRoutineDecl: TNPRoutineDeclNode;
  LSymbol: TNPSymbol;
  LVarName: string;
begin
  for LNode in ADecls do
  begin
    if LNode is TNPTypeDeclNode then
    begin
      LTypeDecl := TNPTypeDeclNode(LNode);
      
      if FCurrentTable.HasSymbol(LTypeDecl.TypeName, False) then
      begin
        AddError(LTypeDecl.Position, Format('Type "%s" already declared', [LTypeDecl.TypeName]));
        Continue;
      end;
      
      LSymbol := TNPSymbol.Create(
        LTypeDecl.TypeName,
        skType,
        True,  // Types are public by default in modules
        LTypeDecl,
        FModuleName
      );
      LSymbol.TypeInfo := LTypeDecl.TypeDef;
      FCurrentTable.AddSymbol(LSymbol);
    end
    else if LNode is TNPConstDeclNode then
    begin
      LConstDecl := TNPConstDeclNode(LNode);
      
      if FCurrentTable.HasSymbol(LConstDecl.ConstName, False) then
      begin
        AddError(LConstDecl.Position, Format('Constant "%s" already declared', [LConstDecl.ConstName]));
        Continue;
      end;
      
      LSymbol := TNPSymbol.Create(
        LConstDecl.ConstName,
        skConstant,
        False,  // Constants are internal by default
        LConstDecl,
        FModuleName
      );
      LSymbol.TypeInfo := LConstDecl.TypeNode;
      FCurrentTable.AddSymbol(LSymbol);
    end
    else if LNode is TNPVarDeclNode then
    begin
      LVarDecl := TNPVarDeclNode(LNode);
      
      for LVarName in LVarDecl.VarNames do
      begin
        if FCurrentTable.HasSymbol(LVarName, False) then
        begin
          AddError(LVarDecl.Position, Format('Variable "%s" already declared', [LVarName]));
          Continue;
        end;
        
        LSymbol := TNPSymbol.Create(
          LVarName,
          skVariable,
          False,  // Variables are internal by default
          LVarDecl,
          FModuleName
        );
        LSymbol.TypeInfo := LVarDecl.TypeNode;
        FCurrentTable.AddSymbol(LSymbol);
      end;
    end
    else if LNode is TNPRoutineDeclNode then
    begin
      LRoutineDecl := TNPRoutineDeclNode(LNode);
      ProcessRoutine(LRoutineDecl);
    end;
  end;
end;

procedure TNPSymbolTableBuilder.ProcessRoutine(ANode: TNPRoutineDeclNode);
var
  LSymbol: TNPSymbol;
begin
  if FCurrentTable.HasSymbol(ANode.RoutineName, False) then
  begin
    AddError(ANode.Position, Format('Routine "%s" already declared', [ANode.RoutineName]));
    Exit;
  end;
  
  LSymbol := TNPSymbol.Create(
    ANode.RoutineName,
    skRoutine,
    ANode.IsPublic,
    ANode,
    FModuleName
  );
  LSymbol.TypeInfo := ANode.ReturnType;
  FCurrentTable.AddSymbol(LSymbol);
end;

function TNPSymbolTableBuilder.HasErrors(): Boolean;
begin
  Result := FErrors.Count > 0;
end;

function TNPSymbolTableBuilder.GetErrors(): TArray<TNPError>;
begin
  Result := FErrors.ToArray();
end;

end.
