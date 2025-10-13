{===============================================================================
  NitroPascal - Modern Pascal • C Performance

  Copyright © 2025-present tinyBigGAMES™ LLC
  All Rights Reserved.

  https://nitropascal.org

  See LICENSE for license information
===============================================================================}

unit NitroPascal.PasToJSON;

{$I NitroPascal.Defines.inc}

interface

uses
  System.Classes,
  System.SysUtils,
  System.JSON,
  System.Generics.Collections,
  DelphiAST.Classes,
  DelphiAST.Consts,
  DelphiAST.ProjectIndexer,
  NitroPascal.Errors,
  NitroPascal.Utils;

type
  { TNPJSONWriter }
  TNPJSONWriter = class
  strict private
    FIndexer: TProjectIndexer;
    FSymbolMap: TDictionary<string, TSyntaxNode>;
    
    procedure BuildSymbolMap;
    function GetUsedUnits(ANode: TSyntaxNode): TStringList;
    function ResolveIdentifier(const AName: string; 
      AUsedUnits: TStrings): TJSONObject;
    
    procedure NodeToJSON(ANode: TSyntaxNode; AOutput: TJSONArray; 
      AUsedUnits: TStrings);
    procedure SerializeUnit(AUnitInfo: TProjectIndexer.TUnitInfo; 
      AOutput: TJSONArray);
    
  public
    constructor Create(const AIndexer: TProjectIndexer);
    destructor Destroy; override;
    
    class function ToJSON(const AIndexer: TProjectIndexer; 
      const AFormatted: Boolean = False): string; static;
  end;

  { TNPPasToJSON }
  TNPPasToJSON = class
  strict private
    FJSON: string;
    FFormatted: Boolean;
    FSearchPath: string;
    FDefines: string;
    FUseCompilerDefines: Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    
    function Parse(const AFilename: string; 
      var AErrorManager: TNPErrorManager): Boolean;
    
    function GetJSON: string;
    
    property Formatted: Boolean read FFormatted write FFormatted;
    property SearchPath: string read FSearchPath write FSearchPath;
    property Defines: string read FDefines write FDefines;
    property UseCompilerDefines: Boolean read FUseCompilerDefines write FUseCompilerDefines;
  end;

implementation

uses
  System.IOUtils;

{ TNPJSONWriter }

constructor TNPJSONWriter.Create(const AIndexer: TProjectIndexer);
begin
  inherited Create;
  FIndexer := AIndexer;
  FSymbolMap := TDictionary<string, TSyntaxNode>.Create;
  BuildSymbolMap;
end;

destructor TNPJSONWriter.Destroy;
begin
  FSymbolMap.Free;
  inherited;
end;

procedure TNPJSONWriter.BuildSymbolMap;
var
  LUnitInfo: TProjectIndexer.TUnitInfo;
begin
  FSymbolMap.Clear;
  
  for LUnitInfo in FIndexer.ParsedUnits do
  begin
    if LUnitInfo.SyntaxTree <> nil then
      FSymbolMap.Add(LUnitInfo.Name, LUnitInfo.SyntaxTree);
  end;
end;

function TNPJSONWriter.GetUsedUnits(ANode: TSyntaxNode): TStringList;
var
  LUsesNode: TSyntaxNode;
  LChild: TSyntaxNode;
begin
  Result := TStringList.Create;
  
  LUsesNode := ANode.FindNode(ntUses);
  if LUsesNode <> nil then
  begin
    for LChild in LUsesNode.ChildNodes do
    begin
      if LChild.Typ = ntUnit then
        Result.Add(LChild.GetAttribute(anName));
    end;
  end;
end;

function TNPJSONWriter.ResolveIdentifier(const AName: string; 
  AUsedUnits: TStrings): TJSONObject;
var
  LUnitName: string;
  LUnitTree: TSyntaxNode;
  LInterfaceNode: TSyntaxNode;
  LMethod: TSyntaxNode;
  LReturnType: TSyntaxNode;
  LTypeNode: TSyntaxNode;
begin
  Result := nil;
  
  for LUnitName in AUsedUnits do
  begin
    if not FSymbolMap.TryGetValue(LUnitName, LUnitTree) then
      Continue;
    
    LInterfaceNode := LUnitTree.FindNode(ntInterface);
    if LInterfaceNode = nil then
      Continue;
    
    for LMethod in LInterfaceNode.ChildNodes do
    begin
      if (LMethod.Typ = ntMethod) and 
         (LMethod.GetAttribute(anName) = AName) then
      begin
        Result := TJSONObject.Create;
        Result.AddPair('declaringUnit', LUnitName);
        Result.AddPair('symbolType', LMethod.GetAttribute(anKind));
        
        LReturnType := LMethod.FindNode(ntReturnType);
        if LReturnType <> nil then
        begin
          LTypeNode := LReturnType.FindNode(ntType);
          if LTypeNode <> nil then
            Result.AddPair('returnType', LTypeNode.GetAttribute(anName));
        end;
        
        Exit;
      end;
    end;
  end;
end;

procedure TNPJSONWriter.NodeToJSON(ANode: TSyntaxNode; AOutput: TJSONArray; 
  AUsedUnits: TStrings);
var
  LNodeObj: TJSONObject;
  LChild: TSyntaxNode;
  LResolved: TJSONObject;
  LChildArray: TJSONArray;
  LAttr: TAttributeEntry;
begin
  // Flatten double-nested CALL nodes (standalone procedure call statements)
  if (ANode.Typ = ntCall) and
     (ANode.HasChildren) and
     (Length(ANode.ChildNodes) = 1) and
     (ANode.ChildNodes[0].Typ = ntCall) then
  begin
    // Skip the outer statement wrapper, process the inner call directly
    NodeToJSON(ANode.ChildNodes[0], AOutput, AUsedUnits);
    Exit;
  end;
  
  LNodeObj := TJSONObject.Create;
  
  LNodeObj.AddPair('type', UpperCase(SyntaxNodeNames[ANode.Typ]));
  LNodeObj.AddPair('line', TJSONNumber.Create(ANode.Line));
  LNodeObj.AddPair('col', TJSONNumber.Create(ANode.Col));
  
  if ANode is TValuedSyntaxNode then
    LNodeObj.AddPair('value', TValuedSyntaxNode(ANode).Value);
  
  for LAttr in ANode.Attributes do
  begin
    // Rename 'type' attribute to avoid collision with node type
    if AttributeNameStrings[LAttr.Key] = 'type' then
      LNodeObj.AddPair('literalType', LAttr.Value)
    else
      LNodeObj.AddPair(AttributeNameStrings[LAttr.Key], LAttr.Value);
  end;
  
  // Add range marker for case labels with two expressions (4..10 syntax)
  if (ANode.Typ = ntCaseLabel) and 
     (ANode.HasChildren) and 
     (Length(ANode.ChildNodes) = 2) then
  begin
    LNodeObj.AddPair('isRange', TJSONBool.Create(True));
  end;
  
  if ANode.Typ = ntIdentifier then
  begin
    LResolved := ResolveIdentifier(ANode.GetAttribute(anName), AUsedUnits);
    if LResolved <> nil then
      LNodeObj.AddPair('resolved', LResolved);
  end;
  
  if ANode.HasChildren then
  begin
    LChildArray := TJSONArray.Create;
    for LChild in ANode.ChildNodes do
      NodeToJSON(LChild, LChildArray, AUsedUnits);
    LNodeObj.AddPair('children', LChildArray);
  end;
  
  AOutput.AddElement(LNodeObj);
end;

procedure TNPJSONWriter.SerializeUnit(AUnitInfo: TProjectIndexer.TUnitInfo; 
  AOutput: TJSONArray);
var
  LUnitObj: TJSONObject;
  LUsedUnits: TStringList;
  LNodeArray: TJSONArray;
begin
  if AUnitInfo.SyntaxTree = nil then
    Exit;
  
  LUnitObj := TJSONObject.Create;
  LUnitObj.AddPair('name', AUnitInfo.Name);
  LUnitObj.AddPair('path', AUnitInfo.Path);
  
  LUsedUnits := GetUsedUnits(AUnitInfo.SyntaxTree);
  try
    LNodeArray := TJSONArray.Create;
    NodeToJSON(AUnitInfo.SyntaxTree, LNodeArray, LUsedUnits);
    LUnitObj.AddPair('ast', LNodeArray);
    
    AOutput.AddElement(LUnitObj);
  finally
    LUsedUnits.Free;
  end;
end;

class function TNPJSONWriter.ToJSON(const AIndexer: TProjectIndexer; 
  const AFormatted: Boolean = False): string;
var
  LWriter: TNPJSONWriter;
  LRootObj: TJSONObject;
  LUnitsArray: TJSONArray;
  LUnitInfo: TProjectIndexer.TUnitInfo;
begin
  LWriter := TNPJSONWriter.Create(AIndexer);
  try
    LRootObj := TJSONObject.Create;
    try
      LUnitsArray := TJSONArray.Create;
      
      for LUnitInfo in AIndexer.ParsedUnits do
        LWriter.SerializeUnit(LUnitInfo, LUnitsArray);
      
      LRootObj.AddPair('units', LUnitsArray);
      
      if AFormatted then
        Result := LRootObj.Format(2)
      else
        Result := LRootObj.ToJSON;

    finally
      LRootObj.Free;
    end;
  finally
    LWriter.Free;
  end;
end;

{ TNPPasToJSON }

constructor TNPPasToJSON.Create;
begin
  inherited;
  FFormatted := True;
  FSearchPath := '';
  FDefines := '';
  FUseCompilerDefines := True;
end;

destructor TNPPasToJSON.Destroy;
begin
  inherited;
end;

function TNPPasToJSON.Parse(const AFilename: string; 
  var AErrorManager: TNPErrorManager): Boolean;
var
  LIndexer: TProjectIndexer;
begin
  Result := False;
  FJSON := '';
  
  if not FileExists(AFilename) then
  begin
    AErrorManager.AddError(NP_ERROR_FILENOTFOUND, 0, 0, AFilename, 
      'File not found');
    Exit;
  end;
  
  try
    LIndexer := TProjectIndexer.Create;
    try
      // Apply SearchPath
      if FSearchPath <> '' then
        LIndexer.SearchPath := FSearchPath
      else
        LIndexer.SearchPath := ExtractFilePath(AFilename);
      
      // Apply Defines
      LIndexer.Defines := FDefines;
      
      // Convert boolean to TOptions
      if FUseCompilerDefines then
        LIndexer.Options := [TProjectIndexer.TOption.piUseDefinesDefinedByCompiler]
      else
        LIndexer.Options := [];
      
      // Parse the file directly from original location
      LIndexer.Index(AFilename);
      
      FJSON := TNPJSONWriter.ToJSON(LIndexer, FFormatted);

      Result := True;
    finally
      LIndexer.Free;
    end;
    
  except
    on E: Exception do
      AErrorManager.AddError(NP_ERROR_INTERNAL, 0, 0, AFilename, E.Message);
  end;
end;

function TNPPasToJSON.GetJSON: string;
begin
  Result := FJSON;
end;

end.
