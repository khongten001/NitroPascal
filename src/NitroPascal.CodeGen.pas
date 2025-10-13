{===============================================================================
  NitroPascal - Modern Pascal • C Performance

  Copyright © 2025-present tinyBigGAMES™ LLC
  All Rights Reserved.

  https://nitropascal.org

  See LICENSE for license information
===============================================================================}

unit NitroPascal.CodeGen;

{$I NitroPascal.Defines.inc}

interface

uses
  System.Classes,
  System.SysUtils,
  System.JSON,
  System.IOUtils,
  System.Generics.Collections,
  NitroPascal.Errors;

type
  { TNPCodeGenerator }
  TNPCodeGenerator = class
  strict private
    FOutputFolder: string;
    FErrorManager: TNPErrorManager;
    FTypeMap: TDictionary<string, string>;
    FCleanOutputFolder: Boolean;
    FSupportedNodes: TList<string>;
    FOutput: TStringBuilder;
    FIndentLevel: Integer;
    FCurrentUnitName: string;
    FWithStack: TList<string>;
    FDotNestLevel: Integer;
    FVariableTypes: TDictionary<string, string>;  // Track variable name -> C++ type
    
    procedure InitializeTypeMap;
    procedure InitializeSupportedNodes;
    function ParseJSON(const AJSON: string): TJSONObject;
    procedure ProcessUnits(const ARootObj: TJSONObject);
    procedure ProcessUnit(const AUnitObj: TJSONObject);
    
    procedure CleanOutputFolderFiles;


  public
    constructor Create(const AOutputFolder: string; const ACleanOutputFolder: Boolean; var AErrorManager: TNPErrorManager);
    destructor Destroy; override;

    // Code emission helpers (now public for concern units)
    procedure Emit(const AText: string; const AArgs: array of const);
    procedure EmitLine(const AText: string; const AArgs: array of const);
    procedure EmitLn;
    procedure IncIndent;
    procedure DecIndent;
    function GetIndent: string;

    // Code generation methods (thin wrappers to concern units)
    function Generate(const AJSON: string): Boolean;
    procedure GenerateCppFile(const AUnitName: string; const AAST: TJSONArray);
    procedure GenerateHeaderFile(const AUnitName: string; const AAST: TJSONArray);
    procedure GenerateIncludes;
    procedure GenerateVariables(const AVariablesNode: TJSONObject);
    procedure GenerateFunctionDeclarations(const AAST: TJSONArray);
    procedure GenerateFunctionDeclaration(const AMethodNode: TJSONObject);
    procedure GenerateFunctionImplementation(const AMethodNode: TJSONObject);
    procedure GenerateStatements(const AStatementsNode: TJSONObject);
    procedure GenerateStatement(const ANode: TJSONObject);
    procedure GenerateCall(const ACallNode: TJSONObject);
    procedure GenerateAssignment(const AAssignNode: TJSONObject);
    procedure GenerateIfStatement(const AIfNode: TJSONObject);
    procedure GenerateForLoop(const AForNode: TJSONObject);
    procedure GenerateWhileLoop(const AWhileNode: TJSONObject);
    function GenerateExpression(const AExprNode: TJSONObject): string;
    function GenerateLiteral(const ALiteralNode: TJSONObject): string;
    function GenerateIdentifier(const AIdentNode: TJSONObject): string;
    function GenerateBinaryOp(const AOpNode: TJSONObject): string;
    
    // Public helper methods for concern units
    function TranslateType(const APasType: string): string;
    function GetNodeType(const ANode: TJSONObject): string;
    function GetNodeAttribute(const ANode: TJSONObject; const AAttrName: string): string;
    function GetNodeChildren(const ANode: TJSONObject): TJSONArray;
    function FindNodeByType(const AChildren: TJSONArray; const ANodeType: string): TJSONObject;
    
    function IsNodeTypeSupported(const ANodeType: string): Boolean;
    procedure ValidateNodeSupport(const ANode: TJSONObject; const AContext: string);
    procedure CheckForUnsupportedNodes(const AChildren: TJSONArray; const AContext: string);
    function IsLibrary(const AUnitNode: TJSONObject): Boolean;
    
    // WITH context management
    procedure PushWithContext(const AContext: string);
    procedure PopWithContext;
    function GetWithQualification(const AIdentifier: string): string;
    
    // DOT expression context management
    procedure EnterDotContext;
    procedure ExitDotContext;
    function IsInDotContext: Boolean;
    
    // Public properties for concern units
    property ErrorManager: TNPErrorManager read FErrorManager;
    property OutputFolder: string read FOutputFolder;
    property Output: TStringBuilder read FOutput;
    property IndentLevel: Integer read FIndentLevel write FIndentLevel;
    property CurrentUnitName: string read FCurrentUnitName write FCurrentUnitName;
    property TypeMap: TDictionary<string, string> read FTypeMap;
    property SupportedNodes: TList<string> read FSupportedNodes;
    property WithStack: TList<string> read FWithStack;
    property VariableTypes: TDictionary<string, string> read FVariableTypes;
    
    // Helper to get variable type
    function GetVariableType(const AVariableName: string): string;
  end;

  { TNPCodeGen }
  TNPCodeGen = class
  strict private
    FOutputFolder: string;
    FCleanOutputFolder: Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    
    function GenerateFromJSON(const AJSON: string; var AErrorManager: TNPErrorManager): Boolean;
    function GenerateFromFile(const AJSONFilename: string; var AErrorManager: TNPErrorManager): Boolean;
    
    property OutputFolder: string read FOutputFolder write FOutputFolder;
    property CleanOutputFolder: Boolean read FCleanOutputFolder write FCleanOutputFolder;
  end;

implementation

uses
  NitroPascal.CodeGen.Expressions,
  NitroPascal.CodeGen.Statements,
  NitroPascal.CodeGen.Declarations,
  NitroPascal.CodeGen.Files;

{ TNPCodeGenerator }

constructor TNPCodeGenerator.Create(const AOutputFolder: string; const ACleanOutputFolder: Boolean; var AErrorManager: TNPErrorManager);
begin
  inherited Create;
  FOutputFolder := AOutputFolder;
  FCleanOutputFolder := ACleanOutputFolder;
  FErrorManager := AErrorManager;
  FTypeMap := TDictionary<string, string>.Create;
  FSupportedNodes := TList<string>.Create;
  FIndentLevel := 0;
  FOutput := TStringBuilder.Create;  // Create it here and keep it
  FCurrentUnitName := '';
  FWithStack := TList<string>.Create;
  FDotNestLevel := 0;
  FVariableTypes := TDictionary<string, string>.Create;
  InitializeTypeMap;
  InitializeSupportedNodes;
end;

destructor TNPCodeGenerator.Destroy;
begin
  FVariableTypes.Free;
  FWithStack.Free;
  FOutput.Free;
  FSupportedNodes.Free;
  FTypeMap.Free;
  inherited;
end;

procedure TNPCodeGenerator.InitializeTypeMap;
begin
  FTypeMap.Clear;
  
  // Integer types → np:: runtime types
  FTypeMap.Add('Byte', 'np::Byte');
  FTypeMap.Add('ShortInt', 'int8_t');
  FTypeMap.Add('Word', 'np::Word');
  FTypeMap.Add('SmallInt', 'int16_t');
  FTypeMap.Add('Cardinal', 'np::Cardinal');
  FTypeMap.Add('Integer', 'np::Integer');
  FTypeMap.Add('LongWord', 'np::Cardinal');
  FTypeMap.Add('LongInt', 'np::Integer');
  FTypeMap.Add('Int64', 'np::Int64');
  FTypeMap.Add('UInt64', 'uint64_t');
  
  // Floating point types → np:: runtime types
  FTypeMap.Add('Single', 'np::Single');
  FTypeMap.Add('Double', 'np::Double');
  FTypeMap.Add('Extended', 'long double');
  FTypeMap.Add('Real', 'np::Double');
  
  // Character and string types → np:: runtime types
  FTypeMap.Add('Char', 'np::Char');
  FTypeMap.Add('AnsiChar', 'char');
  FTypeMap.Add('WideChar', 'np::Char');
  FTypeMap.Add('String', 'np::String');
  FTypeMap.Add('AnsiString', 'std::string');
  FTypeMap.Add('WideString', 'np::String');
  FTypeMap.Add('UnicodeString', 'np::String');
  
  // Boolean type → np:: runtime types
  FTypeMap.Add('Boolean', 'np::Boolean');
  
  // Pointer types → np:: runtime types
  FTypeMap.Add('Pointer', 'np::Pointer');
  FTypeMap.Add('PChar', 'char*');
  FTypeMap.Add('PWideChar', 'char16_t*');
  
  // Special types
  FTypeMap.Add('Variant', 'std::any');
  FTypeMap.Add('OleVariant', 'std::any');
end;

procedure TNPCodeGenerator.InitializeSupportedNodes;
begin
  FSupportedNodes.Clear;
  
  // Currently supported node types (for interface/implementation sections)
  FSupportedNodes.Add('METHOD');
  FSupportedNodes.Add('PARAMETER');
  FSupportedNodes.Add('TYPE');
  FSupportedNodes.Add('RETURNTYPE');
  FSupportedNodes.Add('NAME');
  FSupportedNodes.Add('VARIABLES');
  FSupportedNodes.Add('VARIABLE');
  FSupportedNodes.Add('STATEMENTS');
  FSupportedNodes.Add('ASSIGN');
  FSupportedNodes.Add('LHS');
  FSupportedNodes.Add('RHS');
  FSupportedNodes.Add('EXPRESSION');
  FSupportedNodes.Add('IDENTIFIER');
  FSupportedNodes.Add('LITERAL');
  FSupportedNodes.Add('ADD');
  FSupportedNodes.Add('SUB');
  FSupportedNodes.Add('MUL');
  FSupportedNodes.Add('DIV');
  FSupportedNodes.Add('CALL');
  FSupportedNodes.Add('EXPRESSIONS');
  FSupportedNodes.Add('IF');
  FSupportedNodes.Add('THEN');
  FSupportedNodes.Add('ELSE');
  FSupportedNodes.Add('WHILE');
  FSupportedNodes.Add('FOR');
  FSupportedNodes.Add('FROM');
  FSupportedNodes.Add('TO');
  FSupportedNodes.Add('GREATER');
  FSupportedNodes.Add('LOWER');
  FSupportedNodes.Add('GREATEROREQUAL');
  FSupportedNodes.Add('LOWEROREQUAL');
  FSupportedNodes.Add('EQUAL');
  FSupportedNodes.Add('NOTEQUAL');
  FSupportedNodes.Add('TYPESECTION');
  FSupportedNodes.Add('TYPEDECL');
  FSupportedNodes.Add('FIELD');
  FSupportedNodes.Add('DOT');
  FSupportedNodes.Add('DEREF');
  FSupportedNodes.Add('MOD');
  FSupportedNodes.Add('SHL');
  FSupportedNodes.Add('SHR');
  FSupportedNodes.Add('AND');
  FSupportedNodes.Add('OR');
  FSupportedNodes.Add('XOR');
  FSupportedNodes.Add('NOT');
  FSupportedNodes.Add('CASE');
  FSupportedNodes.Add('CASESELECTOR');
  FSupportedNodes.Add('CASELABELS');
  FSupportedNodes.Add('CASELABEL');
  FSupportedNodes.Add('CASEELSE');
  FSupportedNodes.Add('EXPRESSIONS');
  FSupportedNodes.Add('REPEAT');
  FSupportedNodes.Add('GREATEREQUAL');
  FSupportedNodes.Add('LOWEREQUAL');
  FSupportedNodes.Add('CONSTANTS');
  FSupportedNodes.Add('CONSTANT');
  FSupportedNodes.Add('VALUE');
  FSupportedNodes.Add('BOUNDS');
  FSupportedNodes.Add('DIMENSION');
  FSupportedNodes.Add('WITH');
  FSupportedNodes.Add('EXPORTS');
  FSupportedNodes.Add('ELEMENT');
  FSupportedNodes.Add('INDEXED');
  
  // Node types that are intentionally allowed but not processed
  FSupportedNodes.Add('UNIT');
  FSupportedNodes.Add('PROGRAM');
  FSupportedNodes.Add('INTERFACE');
  FSupportedNodes.Add('IMPLEMENTATION');
end;

function TNPCodeGenerator.IsNodeTypeSupported(const ANodeType: string): Boolean;
begin
  Result := FSupportedNodes.Contains(ANodeType);
end;

procedure TNPCodeGenerator.ValidateNodeSupport(const ANode: TJSONObject; const AContext: string);
var
  LNodeType: string;
  LLine: Integer;
  LCol: Integer;
  LLineValue: TJSONValue;
  LColValue: TJSONValue;
begin
  if ANode = nil then
    Exit;
  
  LNodeType := GetNodeType(ANode);
  if LNodeType = '' then
    Exit;
  
  if not IsNodeTypeSupported(LNodeType) then
  begin
    LLine := 0;
    LCol := 0;
    
    LLineValue := ANode.GetValue('line');
    if LLineValue <> nil then
      LLine := StrToIntDef(LLineValue.Value, 0);
    
    LColValue := ANode.GetValue('col');
    if LColValue <> nil then
      LCol := StrToIntDef(LColValue.Value, 0);
    
    FErrorManager.AddError(
      NP_ERROR_INVALID,
      LLine,
      LCol,
      '',
      Format('Code generation not implemented for node type "%s" in %s. ' +
             'Currently supported: METHOD declarations with parameters and return types only.',
             [LNodeType, AContext])
    );
  end;
end;

procedure TNPCodeGenerator.CheckForUnsupportedNodes(const AChildren: TJSONArray; const AContext: string);
var
  LI: Integer;
  LChild: TJSONValue;
  LChildObj: TJSONObject;
begin
  if AChildren = nil then
    Exit;
  
  for LI := 0 to AChildren.Count - 1 do
  begin
    LChild := AChildren.Items[LI];
    if LChild is TJSONObject then
    begin
      LChildObj := LChild as TJSONObject;
      ValidateNodeSupport(LChildObj, AContext);
    end;
  end;
end;

function TNPCodeGenerator.TranslateType(const APasType: string): string;
var
  LKey: string;
begin
  // Try case-sensitive lookup first
  if FTypeMap.TryGetValue(APasType, Result) then
    Exit;
  
  // Try case-insensitive lookup
  for LKey in FTypeMap.Keys do
  begin
    if SameText(LKey, APasType) then
    begin
      Result := FTypeMap[LKey];
      Exit;
    end;
  end;
  
  // Default: use the Pascal type name as-is (for custom types)
  Result := APasType;
end;

function TNPCodeGenerator.ParseJSON(const AJSON: string): TJSONObject;
begin
  Result := nil;
  
  try
    Result := TJSONObject.ParseJSONValue(AJSON) as TJSONObject;
    if Result = nil then
      FErrorManager.AddError(NP_ERROR_INVALID, 'Invalid JSON format');
  except
    on E: Exception do
      FErrorManager.AddError(NP_ERROR_INVALID, 'JSON parse error: ' + E.Message);
  end;
end;

function TNPCodeGenerator.GetNodeType(const ANode: TJSONObject): string;
var
  LTypeValue: TJSONValue;
begin
  Result := '';
  if ANode = nil then
    Exit;
  
  LTypeValue := ANode.GetValue('type');
  if LTypeValue <> nil then
    Result := LTypeValue.Value;
end;

function TNPCodeGenerator.GetNodeAttribute(const ANode: TJSONObject; const AAttrName: string): string;
var
  LAttrValue: TJSONValue;
begin
  Result := '';
  if ANode = nil then
    Exit;
  
  LAttrValue := ANode.GetValue(AAttrName);
  if LAttrValue <> nil then
    Result := LAttrValue.Value;
end;

function TNPCodeGenerator.GetNodeChildren(const ANode: TJSONObject): TJSONArray;
var
  LChildrenValue: TJSONValue;
begin
  Result := nil;
  if ANode = nil then
    Exit;
  
  LChildrenValue := ANode.GetValue('children');
  if LChildrenValue is TJSONArray then
    Result := LChildrenValue as TJSONArray;
end;

function TNPCodeGenerator.FindNodeByType(const AChildren: TJSONArray; const ANodeType: string): TJSONObject;
var
  LI: Integer;
  LChild: TJSONValue;
  LChildObj: TJSONObject;
begin
  Result := nil;
  if AChildren = nil then
    Exit;
  
  for LI := 0 to AChildren.Count - 1 do
  begin
    LChild := AChildren.Items[LI];
    if LChild is TJSONObject then
    begin
      LChildObj := LChild as TJSONObject;
      if GetNodeType(LChildObj) = ANodeType then
      begin
        Result := LChildObj;
        Exit;
      end;
    end;
  end;
end;

function TNPCodeGenerator.IsLibrary(const AUnitNode: TJSONObject): Boolean;
var
  LExportsNode: TJSONObject;
begin
  // A unit is a library if it has an EXPORTS section
  LExportsNode := FindNodeByType(GetNodeChildren(AUnitNode), 'EXPORTS');
  Result := LExportsNode <> nil;
end;

{ Code Emission Helpers }

procedure TNPCodeGenerator.Emit(const AText: string; const AArgs: array of const);
begin
  if Length(AArgs) > 0 then
    FOutput.Append(Format(AText, AArgs))
  else
    FOutput.Append(AText);
end;

procedure TNPCodeGenerator.EmitLine(const AText: string; const AArgs: array of const);
begin
  FOutput.Append(GetIndent);
  if Length(AArgs) > 0 then
    FOutput.AppendLine(Format(AText, AArgs))
  else
    FOutput.AppendLine(AText);
end;

procedure TNPCodeGenerator.EmitLn;
begin
  FOutput.AppendLine;
end;

procedure TNPCodeGenerator.IncIndent;
begin
  Inc(FIndentLevel);
end;

procedure TNPCodeGenerator.DecIndent;
begin
  if FIndentLevel > 0 then
    Dec(FIndentLevel);
end;

function TNPCodeGenerator.GetIndent: string;
begin
  Result := StringOfChar(' ', FIndentLevel * 4);
end;

{ Code Generation Methods - Thin Wrappers to Concern Units }

procedure TNPCodeGenerator.GenerateIncludes;
begin
  NitroPascal.CodeGen.Files.GenerateIncludes(Self);
end;

procedure TNPCodeGenerator.GenerateVariables(const AVariablesNode: TJSONObject);
begin
  NitroPascal.CodeGen.Declarations.GenerateVariables(Self, AVariablesNode);
end;

procedure TNPCodeGenerator.GenerateCppFile(const AUnitName: string; const AAST: TJSONArray);
begin
  FCurrentUnitName := AUnitName;
  FOutput.Clear();
  FIndentLevel := 0;
  NitroPascal.CodeGen.Files.GenerateCppFile(Self, AUnitName, AAST);
end;

procedure TNPCodeGenerator.GenerateHeaderFile(const AUnitName: string; const AAST: TJSONArray);
begin
  FCurrentUnitName := AUnitName;
  FOutput.Clear();
  FIndentLevel := 0;
  NitroPascal.CodeGen.Files.GenerateHeaderFile(Self, AUnitName, AAST);
end;

procedure TNPCodeGenerator.GenerateFunctionDeclarations(const AAST: TJSONArray);
begin
  NitroPascal.CodeGen.Declarations.GenerateFunctionDeclarations(Self, AAST);
end;

procedure TNPCodeGenerator.GenerateFunctionDeclaration(const AMethodNode: TJSONObject);
begin
  NitroPascal.CodeGen.Declarations.GenerateFunctionDeclaration(Self, AMethodNode);
end;

procedure TNPCodeGenerator.GenerateFunctionImplementation(const AMethodNode: TJSONObject);
begin
  NitroPascal.CodeGen.Declarations.GenerateFunctionImplementation(Self, AMethodNode);
end;

procedure TNPCodeGenerator.GenerateStatements(const AStatementsNode: TJSONObject);
begin
  NitroPascal.CodeGen.Statements.GenerateStatements(Self, AStatementsNode);
end;

procedure TNPCodeGenerator.GenerateStatement(const ANode: TJSONObject);
begin
  NitroPascal.CodeGen.Statements.GenerateStatement(Self, ANode);
end;

procedure TNPCodeGenerator.GenerateCall(const ACallNode: TJSONObject);
begin
  NitroPascal.CodeGen.Statements.GenerateCall(Self, ACallNode);
end;

procedure TNPCodeGenerator.GenerateAssignment(const AAssignNode: TJSONObject);
begin
  NitroPascal.CodeGen.Statements.GenerateAssignment(Self, AAssignNode);
end;

procedure TNPCodeGenerator.GenerateIfStatement(const AIfNode: TJSONObject);
begin
  NitroPascal.CodeGen.Statements.GenerateIfStatement(Self, AIfNode);
end;

procedure TNPCodeGenerator.GenerateForLoop(const AForNode: TJSONObject);
begin
  NitroPascal.CodeGen.Statements.GenerateForLoop(Self, AForNode);
end;

procedure TNPCodeGenerator.GenerateWhileLoop(const AWhileNode: TJSONObject);
begin
  NitroPascal.CodeGen.Statements.GenerateWhileLoop(Self, AWhileNode);
end;

function TNPCodeGenerator.GenerateExpression(const AExprNode: TJSONObject): string;
begin
  Result := NitroPascal.CodeGen.Expressions.GenerateExpression(Self, AExprNode);
end;

function TNPCodeGenerator.GenerateLiteral(const ALiteralNode: TJSONObject): string;
begin
  Result := NitroPascal.CodeGen.Expressions.GenerateLiteral(Self, ALiteralNode);
end;

function TNPCodeGenerator.GenerateIdentifier(const AIdentNode: TJSONObject): string;
begin
  Result := NitroPascal.CodeGen.Expressions.GenerateIdentifier(Self, AIdentNode);
end;

function TNPCodeGenerator.GenerateBinaryOp(const AOpNode: TJSONObject): string;
begin
  Result := NitroPascal.CodeGen.Expressions.GenerateBinaryOp(Self, AOpNode);
end;

{ ProcessUnit }

procedure TNPCodeGenerator.ProcessUnit(const AUnitObj: TJSONObject);
var
  LUnitName: string;
  LASTValue: TJSONValue;
  LASTArray: TJSONArray;
begin
  LUnitName := GetNodeAttribute(AUnitObj, 'name');
  if LUnitName = '' then
  begin
    FErrorManager.AddError(NP_ERROR_INVALID, 'Unit has no name');
    Exit;
  end;
  
  LASTValue := AUnitObj.GetValue('ast');
  if not (LASTValue is TJSONArray) then
  begin
    FErrorManager.AddError(NP_ERROR_INVALID, 'Unit "' + LUnitName + '" has no AST array');
    Exit;
  end;
  
  LASTArray := LASTValue as TJSONArray;
  
  // No longer blocking TYPESECTION - enum types are now supported
  
  // Generate both .h and .cpp files ALWAYS
  GenerateHeaderFile(LUnitName, LASTArray);
  GenerateCppFile(LUnitName, LASTArray);
end;

procedure TNPCodeGenerator.ProcessUnits(const ARootObj: TJSONObject);
var
  LUnitsValue: TJSONValue;
  LUnitsArray: TJSONArray;
  LI: Integer;
  LUnitValue: TJSONValue;
  LUnitObj: TJSONObject;
begin
  LUnitsValue := ARootObj.GetValue('units');
  if not (LUnitsValue is TJSONArray) then
  begin
    FErrorManager.AddError(NP_ERROR_INVALID, 'JSON root has no "units" array');
    Exit;
  end;
  
  LUnitsArray := LUnitsValue as TJSONArray;
  
  for LI := 0 to LUnitsArray.Count - 1 do
  begin
    LUnitValue := LUnitsArray.Items[LI];
    if LUnitValue is TJSONObject then
    begin
      LUnitObj := LUnitValue as TJSONObject;
      ProcessUnit(LUnitObj);
    end;
  end;
end;

procedure TNPCodeGenerator.CleanOutputFolderFiles;
var
  LFiles: TArray<string>;
  LFile: string;
begin
  if not TDirectory.Exists(FOutputFolder) then
    Exit;
  
  try
    LFiles := TDirectory.GetFiles(FOutputFolder);
    for LFile in LFiles do
    begin
      if (LFile.EndsWith('.h', True)) or (LFile.EndsWith('.cpp', True)) then
      begin
        TFile.Delete(LFile);
      end;
    end;
  except
    on E: Exception do
      FErrorManager.AddError(NP_ERROR_IO, 'Cannot clean output folder: ' + E.Message);
  end;
end;

function TNPCodeGenerator.Generate(const AJSON: string): Boolean;
var
  LRootObj: TJSONObject;
begin
  Result := False;
  
  if not TDirectory.Exists(FOutputFolder) then
  begin
    try
      TDirectory.CreateDirectory(FOutputFolder);
    except
      on E: Exception do
      begin
        FErrorManager.AddError(NP_ERROR_IO, 'Cannot create output directory: ' + E.Message);
        Exit;
      end;
    end;
  end;
  
  if FCleanOutputFolder then
    CleanOutputFolderFiles();
  
  LRootObj := ParseJSON(AJSON);
  if LRootObj = nil then
    Exit;
  
  try
    ProcessUnits(LRootObj);
    Result := not FErrorManager.HasErrors;
  finally
    LRootObj.Free;
  end;
end;

{ TNPCodeGen }

constructor TNPCodeGen.Create;
begin
  inherited;
  FOutputFolder := '';
  FCleanOutputFolder := False;
end;

destructor TNPCodeGen.Destroy;
begin
  inherited;
end;

function TNPCodeGen.GenerateFromJSON(const AJSON: string; var AErrorManager: TNPErrorManager): Boolean;
var
  LGenerator: TNPCodeGenerator;
begin
  Result := False;
  
  if FOutputFolder = '' then
  begin
    AErrorManager.AddError(NP_ERROR_INVALID, 'Output folder not set');
    Exit;
  end;
  
  LGenerator := TNPCodeGenerator.Create(FOutputFolder, FCleanOutputFolder, AErrorManager);
  try
    Result := LGenerator.Generate(AJSON);
  finally
    LGenerator.Free;
  end;
end;

function TNPCodeGen.GenerateFromFile(const AJSONFilename: string; var AErrorManager: TNPErrorManager): Boolean;
var
  LJSON: string;
begin
  Result := False;
  
  if not FileExists(AJSONFilename) then
  begin
    AErrorManager.AddError(NP_ERROR_FILENOTFOUND, 0, 0, AJSONFilename, 'JSON file not found');
    Exit;
  end;
  
  try
    LJSON := TFile.ReadAllText(AJSONFilename);
    Result := GenerateFromJSON(LJSON, AErrorManager);
  except
    on E: Exception do
      AErrorManager.AddError(NP_ERROR_IO, 0, 0, AJSONFilename, 'Cannot read file: ' + E.Message);
  end;
end;

{ WITH Context Management }

procedure TNPCodeGenerator.PushWithContext(const AContext: string);
begin
  FWithStack.Add(AContext);
end;

procedure TNPCodeGenerator.PopWithContext;
begin
  if FWithStack.Count > 0 then
    FWithStack.Delete(FWithStack.Count - 1);
end;

function TNPCodeGenerator.GetWithQualification(const AIdentifier: string): string;
var
  LI: Integer;
begin
  // Check WITH contexts from innermost to outermost
  // Return the identifier qualified with the WITH context
  for LI := FWithStack.Count - 1 downto 0 do
  begin
    Result := FWithStack[LI] + '.' + AIdentifier;
    Exit;
  end;
  
  // No WITH context, return unqualified
  Result := AIdentifier;
end;

{ DOT Context Management }

procedure TNPCodeGenerator.EnterDotContext;
begin
  Inc(FDotNestLevel);
end;

procedure TNPCodeGenerator.ExitDotContext;
begin
  if FDotNestLevel > 0 then
    Dec(FDotNestLevel);
end;

function TNPCodeGenerator.IsInDotContext: Boolean;
begin
  Result := FDotNestLevel > 0;
end;

{ GetVariableType }

function TNPCodeGenerator.GetVariableType(const AVariableName: string): string;
begin
  if not FVariableTypes.TryGetValue(AVariableName, Result) then
    Result := '';  // Unknown type
end;

end.
