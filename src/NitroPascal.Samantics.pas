{===============================================================================
  NitroPascal - Modern Pascal • C Performance

  Copyright © 2025-present tinyBigGAMES™ LLC
  All Rights Reserved.

  https://nitropascal.org

  See LICENSE for license information
===============================================================================}

unit NitroPascal.Samantics;

{$I NitroPascal.Defines.inc}

interface

uses
  System.Classes,
  System.SysUtils,
  System.JSON,
  System.Generics.Collections,
  NitroPascal.Symbols,
  NitroPascal.Errors;

type
  { TNPSamantics }
  TNPSamantics = class
  private
    FErrorManager: TNPErrorManager;
    FSymbolTable: TNPSymbolTable;
    FCurrentFile: string;
    FWithDepth: Integer;
    FUnitSymbolMap: TDictionary<string, TDictionary<string, TNPSymbol>>;
    FUnitsData: TDictionary<string, TJSONObject>;  // Store all unit JSON data
    
    function GetUsedUnits(const AUnitObj: TJSONObject): TStringList;
    procedure CollectAllUnitSymbols(const AUnitsArray: TJSONArray);
    procedure CollectUnitInterfaceSymbols(const AUnitName: string; 
      const AUnitObj: TJSONObject);
    procedure CollectUnitGlobalSymbols(const AASTPASTArray: TJSONArray);
    procedure ValidateUnit(const AUnitName: string; const AUnitObj: TJSONObject);
    procedure ValidateIdentifier(const AIdentNode: TJSONObject);
    function IsFieldAccessName(const AParentNode: TJSONObject; 
      const ANode: TJSONObject): Boolean;
    function GetNodeType(const ANode: TJSONObject): string;
    function GetNodeAttribute(const ANode: TJSONObject; 
      const AAttrName: string): string;
    function GetNodeChildren(const ANode: TJSONObject): TJSONArray;
    function GetNodeLine(const ANode: TJSONObject): Integer;
    function GetNodeCol(const ANode: TJSONObject): Integer;
    function FindNodeByType(const AChildren: TJSONArray; 
      const ANodeType: string): TJSONObject;
    procedure TraverseNode(const ANode: TJSONObject; 
      const AParentNode: TJSONObject);
    
  public
    constructor Create(var AErrorManager: TNPErrorManager);
    destructor Destroy; override;
    
    { Validate complete JSON AST and report errors to ErrorManager }
    function Validate(const AJSON: string): Boolean;
  end;

implementation

{ TNPSamantics }

constructor TNPSamantics.Create(var AErrorManager: TNPErrorManager);
begin
  inherited Create;
  FErrorManager := AErrorManager;
  FSymbolTable := TNPSymbolTable.Create;
  FCurrentFile := '';
  FWithDepth := 0;
  FUnitSymbolMap := TDictionary<string, TDictionary<string, TNPSymbol>>.Create;
  FUnitsData := TDictionary<string, TJSONObject>.Create;
end;

destructor TNPSamantics.Destroy;
var
  LSymbolDict: TDictionary<string, TNPSymbol>;
begin
  for LSymbolDict in FUnitSymbolMap.Values do
    LSymbolDict.Free;
  FUnitSymbolMap.Free;
  FUnitsData.Free;
  FSymbolTable.Free;
  inherited;
end;

function TNPSamantics.GetUsedUnits(const AUnitObj: TJSONObject): TStringList;
var
  LASTValue: TJSONValue;
  LASTArray: TJSONArray;
  LI: Integer;
  LJ: Integer;
  LK: Integer;
  LChildValue: TJSONValue;
  LChildObj: TJSONObject;
  LNodeType: string;
  LUsesNode: TJSONObject;
  LUsesChildren: TJSONArray;
  LUnitChild: TJSONValue;
  LUnitChildObj: TJSONObject;
  LUnitName: string;
  LUnitChildren: TJSONArray;
begin
  Result := TStringList.Create;
  
  LASTValue := AUnitObj.GetValue('ast');
  if not (LASTValue is TJSONArray) then
    Exit;
  
  LASTArray := LASTValue as TJSONArray;
  
  { Find UNIT/PROGRAM node, then find USES node }
  for LI := 0 to LASTArray.Count - 1 do
  begin
    LChildValue := LASTArray.Items[LI];
    if not (LChildValue is TJSONObject) then
      Continue;
    
    LChildObj := LChildValue as TJSONObject;
    LNodeType := GetNodeType(LChildObj);
    
    if (LNodeType = 'UNIT') or (LNodeType = 'PROGRAM') then
    begin
      { Search children for USES node }
      LUnitChildren := GetNodeChildren(LChildObj);
      if LUnitChildren <> nil then
      begin
        for LJ := 0 to LUnitChildren.Count - 1 do
        begin
          LChildValue := LUnitChildren.Items[LJ];
          if not (LChildValue is TJSONObject) then
            Continue;
          
          LUsesNode := LChildValue as TJSONObject;
          if GetNodeType(LUsesNode) = 'USES' then
          begin
            { Found USES node - extract unit names }
            LUsesChildren := GetNodeChildren(LUsesNode);
            if LUsesChildren <> nil then
            begin
              for LK := 0 to LUsesChildren.Count - 1 do
              begin
                LUnitChild := LUsesChildren.Items[LK];
                if LUnitChild is TJSONObject then
                begin
                  LUnitChildObj := LUnitChild as TJSONObject;
                  if GetNodeType(LUnitChildObj) = 'UNIT' then
                  begin
                    LUnitName := GetNodeAttribute(LUnitChildObj, 'name');
                    if LUnitName <> '' then
                      Result.Add(LUnitName);
                  end;
                end;
              end;
            end;
            Exit;  { Found USES, done }
          end;
        end;
      end;
      Exit;  { Found UNIT/PROGRAM node, done searching }
    end;
  end;
end;

function TNPSamantics.GetNodeType(const ANode: TJSONObject): string;
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

function TNPSamantics.GetNodeAttribute(const ANode: TJSONObject;
  const AAttrName: string): string;
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

function TNPSamantics.GetNodeChildren(const ANode: TJSONObject): TJSONArray;
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

function TNPSamantics.GetNodeLine(const ANode: TJSONObject): Integer;
var
  LLineValue: TJSONValue;
begin
  Result := 0;
  if ANode = nil then
    Exit;
  
  LLineValue := ANode.GetValue('line');
  if LLineValue <> nil then
    Result := StrToIntDef(LLineValue.Value, 0);
end;

function TNPSamantics.GetNodeCol(const ANode: TJSONObject): Integer;
var
  LColValue: TJSONValue;
begin
  Result := 0;
  if ANode = nil then
    Exit;
  
  LColValue := ANode.GetValue('col');
  if LColValue <> nil then
    Result := StrToIntDef(LColValue.Value, 0);
end;

function TNPSamantics.FindNodeByType(const AChildren: TJSONArray;
  const ANodeType: string): TJSONObject;
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

function TNPSamantics.IsFieldAccessName(const AParentNode: TJSONObject;
  const ANode: TJSONObject): Boolean;
begin
  { Skip validation for ANY child of a DOT node (field access) }
  if AParentNode = nil then
    Exit(False);
  
  { Both left and right operands of DOT are field accesses }
  Result := GetNodeType(AParentNode) = 'DOT';
end;

procedure TNPSamantics.ValidateIdentifier(const AIdentNode: TJSONObject);
var
  LName: string;
  LNodeType: string;
begin
  if AIdentNode = nil then
    Exit;
  
  LNodeType := GetNodeType(AIdentNode);
  if LNodeType <> 'IDENTIFIER' then
    Exit;
  
  LName := GetNodeAttribute(AIdentNode, 'name');
  if LName = '' then
    Exit;
  
  { Skip if inside WITH block (conservative approach) }
  if FWithDepth > 0 then
    Exit;
  
  { Check if symbol exists }
  if not FSymbolTable.FindSymbol(LName) then
  begin
    FErrorManager.AddError(NP_ERROR_COMPILATION, 
      GetNodeLine(AIdentNode), 
      GetNodeCol(AIdentNode),
      FCurrentFile,
      'Undefined identifier: ' + LName);
  end;
end;

procedure TNPSamantics.TraverseNode(const ANode: TJSONObject;
  const AParentNode: TJSONObject);
var
  LChildren: TJSONArray;
  LI: Integer;
  LChildValue: TJSONValue;
  LChildObj: TJSONObject;
  LNodeType: string;
  LParametersNode: TJSONObject;
  LParamChildren: TJSONArray;
  LParamNode: TJSONObject;
  LNameNode: TJSONObject;
  LReturnTypeNode: TJSONObject;
  LParamName: string;
  LSymbol: TNPSymbol;
  LTempArray: TJSONArray;
begin
  if ANode = nil then
    Exit;
  
  LNodeType := GetNodeType(ANode);
  
  { Enter scope for methods }
  if LNodeType = 'METHOD' then
  begin
    FSymbolTable.EnterScope;
    try
      { Collect parameters }
      LChildren := GetNodeChildren(ANode);
      if LChildren <> nil then
      begin
        LParametersNode := FindNodeByType(LChildren, 'PARAMETERS');
        if LParametersNode <> nil then
        begin
          LParamChildren := GetNodeChildren(LParametersNode);
          if LParamChildren <> nil then
          begin
            for LI := 0 to LParamChildren.Count - 1 do
            begin
              LChildValue := LParamChildren.Items[LI];
              if LChildValue is TJSONObject then
              begin
                LParamNode := LChildValue as TJSONObject;
                if GetNodeType(LParamNode) = 'PARAMETER' then
                begin
                  { Get parameter name from NAME child }
                  LNameNode := FindNodeByType(GetNodeChildren(LParamNode), 'NAME');
                  if LNameNode <> nil then
                  begin
                    LParamName := GetNodeAttribute(LNameNode, 'value');
                    if LParamName <> '' then
                    begin
                      LSymbol.SymbolName := LParamName;
                      LSymbol.Kind := skParameter;
                      LSymbol.Line := GetNodeLine(LParamNode);
                      LSymbol.Column := GetNodeCol(LParamNode);
                      LSymbol.SourceFile := FCurrentFile;
                      FSymbolTable.AddSymbol(LSymbol);
                    end;
                  end;
                end;
              end;
            end;
          end;
        end;
        
        { Add implicit Result variable for functions }
        LReturnTypeNode := FindNodeByType(LChildren, 'RETURNTYPE');
        if LReturnTypeNode <> nil then
        begin
          LSymbol.SymbolName := 'Result';
          LSymbol.Kind := skVariable;
          LSymbol.Line := GetNodeLine(ANode);
          LSymbol.Column := GetNodeCol(ANode);
          LSymbol.SourceFile := FCurrentFile;
          FSymbolTable.AddSymbol(LSymbol);
        end;
      end;
      
      { Collect local variables and constants }
      LChildren := GetNodeChildren(ANode);
      if LChildren <> nil then
      begin
        for LI := 0 to LChildren.Count - 1 do
        begin
          LChildValue := LChildren.Items[LI];
          if LChildValue is TJSONObject then
          begin
            LChildObj := LChildValue as TJSONObject;
            LNodeType := GetNodeType(LChildObj);
            
            if (LNodeType = 'VARIABLES') or (LNodeType = 'CONSTANTS') or (LNodeType = 'TYPESECTION') then
            begin
              LTempArray := TJSONArray.Create;
              try
                LTempArray.AddElement(LChildObj);
                CollectUnitGlobalSymbols(LTempArray);
              finally
                LTempArray.Free;
              end;
            end;
          end;
        end;
      end;
      
      { Now traverse children for validation }
      LChildren := GetNodeChildren(ANode);
      if LChildren <> nil then
      begin
        for LI := 0 to LChildren.Count - 1 do
        begin
          LChildValue := LChildren.Items[LI];
          if LChildValue is TJSONObject then
          begin
            LChildObj := LChildValue as TJSONObject;
            TraverseNode(LChildObj, ANode);
          end;
        end;
      end;
    finally
      FSymbolTable.ExitScope;
    end;
    Exit;
  end;
  
  { Handle WITH statements }
  if LNodeType = 'WITH' then
  begin
    Inc(FWithDepth);
    try
      LChildren := GetNodeChildren(ANode);
      if LChildren <> nil then
      begin
        for LI := 0 to LChildren.Count - 1 do
        begin
          LChildValue := LChildren.Items[LI];
          if LChildValue is TJSONObject then
          begin
            LChildObj := LChildValue as TJSONObject;
            TraverseNode(LChildObj, ANode);
          end;
        end;
      end;
    finally
      Dec(FWithDepth);
    end;
    Exit;
  end;
  
  { Validate identifiers }
  if LNodeType = 'IDENTIFIER' then
  begin
    if not IsFieldAccessName(AParentNode, ANode) then
      ValidateIdentifier(ANode);
  end;
  
  { Recursively traverse children }
  LChildren := GetNodeChildren(ANode);
  if LChildren <> nil then
  begin
    for LI := 0 to LChildren.Count - 1 do
    begin
      LChildValue := LChildren.Items[LI];
      if LChildValue is TJSONObject then
      begin
        LChildObj := LChildValue as TJSONObject;
        TraverseNode(LChildObj, ANode);
      end;
    end;
  end;
end;

procedure TNPSamantics.CollectUnitInterfaceSymbols(const AUnitName: string;
  const AUnitObj: TJSONObject);
var
  LASTValue: TJSONValue;
  LASTArray: TJSONArray;
  LChildValue: TJSONValue;
  LChildObj: TJSONObject;
  LNodeType: string;
  LSymbolName: string;
  LSymbol: TNPSymbol;
  LChildren: TJSONArray;
  LJ: Integer;
  LUnitNode: TJSONObject;
  LInterfaceNode: TJSONObject;
  LTypeChild: TJSONObject;
  LTypeChildren: TJSONArray;
  LK: Integer;
  LEnumChild: TJSONValue;
  LEnumChildObj: TJSONObject;
  LEnumName: string;
  LNextChild: TJSONValue;
begin
  LASTValue := AUnitObj.GetValue('ast');
  if not (LASTValue is TJSONArray) then
    Exit;
  
  LASTArray := LASTValue as TJSONArray;
  if LASTArray.Count = 0 then
    Exit;
  
  { Get the UNIT node (first element in AST array - DelphiAST always creates UNIT root) }
  LUnitNode := LASTArray.Items[0] as TJSONObject;
  if GetNodeType(LUnitNode) <> 'UNIT' then
    Exit;
  
  { Get UNIT node's children }
  LChildren := GetNodeChildren(LUnitNode);
  if LChildren = nil then
    Exit;
  
  { Find INTERFACE node in UNIT's children }
  LInterfaceNode := FindNodeByType(LChildren, 'INTERFACE');
  if LInterfaceNode = nil then
    Exit;
  
  { Get INTERFACE children }
  LChildren := GetNodeChildren(LInterfaceNode);
  if LChildren = nil then
    Exit;
  
  { Process interface symbols }
  for LJ := 0 to LChildren.Count - 1 do
  begin
    LChildValue := LChildren.Items[LJ];
    if not (LChildValue is TJSONObject) then
      Continue;
    
    LChildObj := LChildValue as TJSONObject;
    LNodeType := GetNodeType(LChildObj);
    
    if LNodeType = 'METHOD' then
      begin
        LSymbolName := GetNodeAttribute(LChildObj, 'name');
        if LSymbolName <> '' then
        begin
          LSymbol.SymbolName := LSymbolName;
          LSymbol.Kind := skFunction;
          LSymbol.Line := GetNodeLine(LChildObj);
          LSymbol.Column := GetNodeCol(LChildObj);
          LSymbol.SourceFile := AUnitName;
          FSymbolTable.AddSymbol(LSymbol);
        end;
      end
    else if LNodeType = 'TYPEDECL' then
      begin
        LSymbolName := GetNodeAttribute(LChildObj, 'name');
        if LSymbolName <> '' then
        begin
          LSymbol.SymbolName := LSymbolName;
          LSymbol.Kind := skType;
          LSymbol.Line := GetNodeLine(LChildObj);
          LSymbol.Column := GetNodeCol(LChildObj);
          LSymbol.SourceFile := AUnitName;
          FSymbolTable.AddSymbol(LSymbol);
          
          { Also collect enum members if this is an enum type }
          LTypeChild := FindNodeByType(GetNodeChildren(LChildObj), 'TYPE');
          if LTypeChild <> nil then
          begin
            if GetNodeAttribute(LTypeChild, 'name') = 'enum' then
            begin
              LTypeChildren := GetNodeChildren(LTypeChild);
              if LTypeChildren <> nil then
              begin
                LK := 0;
                while LK < LTypeChildren.Count do
                begin
                  LEnumChild := LTypeChildren.Items[LK];
                  if LEnumChild is TJSONObject then
                  begin
                    LEnumChildObj := LEnumChild as TJSONObject;
                    if GetNodeType(LEnumChildObj) = 'IDENTIFIER' then
                    begin
                      LEnumName := GetNodeAttribute(LEnumChildObj, 'name');
                      if LEnumName <> '' then
                      begin
                        LSymbol.SymbolName := LEnumName;
                        LSymbol.Kind := skConstant;
                        LSymbol.Line := GetNodeLine(LEnumChildObj);
                        LSymbol.Column := GetNodeCol(LEnumChildObj);
                        LSymbol.SourceFile := AUnitName;
                        FSymbolTable.AddSymbol(LSymbol);
                      end;

                      { Skip next node if it's an EXPRESSION (explicit enum value) }
                      if (LK + 1 < LTypeChildren.Count) then
                      begin
                        LNextChild := LTypeChildren.Items[LK + 1];
                        if (LNextChild is TJSONObject) and
                           (GetNodeType(LNextChild as TJSONObject) = 'EXPRESSION') then
                          Inc(LK);
                      end;
                    end;
                  end;
                  Inc(LK);

                end;
              end;
            end;
          end;
        end;
      end;
  end;  // End for LJ loop
end;

procedure TNPSamantics.CollectAllUnitSymbols(const AUnitsArray: TJSONArray);
var
  LI: Integer;
  LUnitValue: TJSONValue;
  LUnitObj: TJSONObject;
  LUnitName: string;
  LSymbolDict: TDictionary<string, TNPSymbol>;
  LASTValue: TJSONValue;
  LASTArray: TJSONArray;
  LRootNode: TJSONObject;
  LChildren: TJSONArray;
  LInterfaceNode: TJSONObject;
begin
  if AUnitsArray = nil then
    Exit;
  
  for LI := 0 to AUnitsArray.Count - 1 do
  begin
    LUnitValue := AUnitsArray.Items[LI];
    if not (LUnitValue is TJSONObject) then
      Continue;
    
    LUnitObj := LUnitValue as TJSONObject;
    LUnitName := GetNodeAttribute(LUnitObj, 'name');
    if LUnitName = '' then
      Continue;
    
    { Check if this has an INTERFACE section - skip PROGRAM files }
    LASTValue := LUnitObj.GetValue('ast');
    if (LASTValue is TJSONArray) then
    begin
      LASTArray := LASTValue as TJSONArray;
      if LASTArray.Count > 0 then
      begin
        LRootNode := LASTArray.Items[0] as TJSONObject;
        LChildren := GetNodeChildren(LRootNode);
        if LChildren <> nil then
        begin
          LInterfaceNode := FindNodeByType(LChildren, 'INTERFACE');
          if LInterfaceNode = nil then
            Continue;  { No INTERFACE - this is a PROGRAM, skip it }
        end;
      end;
    end;
    
    LSymbolDict := TDictionary<string, TNPSymbol>.Create;
    FUnitSymbolMap.Add(LUnitName, LSymbolDict);
    
    CollectUnitInterfaceSymbols(LUnitName, LUnitObj);
  end;
end;

procedure TNPSamantics.CollectUnitGlobalSymbols(const AASTPASTArray: TJSONArray);
var
  LI: Integer;
  LChildValue: TJSONValue;
  LChildObj: TJSONObject;
  LNodeType: string;
  LSymbolName: string;
  LSymbol: TNPSymbol;
  LChildren: TJSONArray;
  LJ: Integer;
  LVarChild: TJSONValue;
  LVarChildObj: TJSONObject;
  LNameChild: TJSONObject;
  LTypeChild: TJSONObject;
  LTypeChildren: TJSONArray;
  LK: Integer;
  LEnumChild: TJSONValue;
  LEnumChildObj: TJSONObject;
begin
  if AASTPASTArray = nil then
    Exit;
  
  { Scan top-level AST nodes for TYPESECTION, VARIABLES, CONSTANTS }
  for LI := 0 to AASTPASTArray.Count - 1 do
  begin
    LChildValue := AASTPASTArray.Items[LI];
    if not (LChildValue is TJSONObject) then
      Continue;
    
    LChildObj := LChildValue as TJSONObject;
    LNodeType := GetNodeType(LChildObj);
    
    { METHOD: function/procedure declarations at top level (PROGRAM files) }
    if LNodeType = 'METHOD' then
    begin
      LSymbolName := GetNodeAttribute(LChildObj, 'name');
      if LSymbolName <> '' then
      begin
        LSymbol.SymbolName := LSymbolName;
        LSymbol.Kind := skFunction;
        LSymbol.Line := GetNodeLine(LChildObj);
        LSymbol.Column := GetNodeCol(LChildObj);
        LSymbol.SourceFile := FCurrentFile;
        FSymbolTable.AddSymbol(LSymbol);
      end;
    end
    
    { TYPESECTION: contains TYPEDECL nodes }
    else if LNodeType = 'TYPESECTION' then
    begin
      LChildren := GetNodeChildren(LChildObj);
      if LChildren <> nil then
      begin
        for LJ := 0 to LChildren.Count - 1 do
        begin
          LVarChild := LChildren.Items[LJ];
          if LVarChild is TJSONObject then
          begin
            LVarChildObj := LVarChild as TJSONObject;
            if GetNodeType(LVarChildObj) = 'TYPEDECL' then
            begin
              { Add the type itself }
              LSymbolName := GetNodeAttribute(LVarChildObj, 'name');
              if LSymbolName <> '' then
              begin
                LSymbol.SymbolName := LSymbolName;
                LSymbol.Kind := skType;
                LSymbol.Line := GetNodeLine(LVarChildObj);
                LSymbol.Column := GetNodeCol(LVarChildObj);
                LSymbol.SourceFile := FCurrentFile;
                FSymbolTable.AddSymbol(LSymbol);
              end;
              
              { Extract enum members if this is an enum type }
              LTypeChild := FindNodeByType(GetNodeChildren(LVarChildObj), 'TYPE');
              if LTypeChild <> nil then
              begin
                { Check if this TYPE node represents an enum }
                { Enum types have name='enum' attribute }
                if GetNodeAttribute(LTypeChild, 'name') = 'enum' then
                begin
                  LTypeChildren := GetNodeChildren(LTypeChild);
                  if LTypeChildren <> nil then
                  begin
                    { Enum members are IDENTIFIER nodes, optionally followed by EXPRESSION nodes }
                    var
                      LNextChild: TJSONValue;
                    begin
                      LK := 0;
                      while LK < LTypeChildren.Count do
                      begin
                        LEnumChild := LTypeChildren.Items[LK];
                        if LEnumChild is TJSONObject then
                        begin
                          LEnumChildObj := LEnumChild as TJSONObject;
                          if GetNodeType(LEnumChildObj) = 'IDENTIFIER' then
                          begin
                            LSymbolName := GetNodeAttribute(LEnumChildObj, 'name');
                            if LSymbolName <> '' then
                            begin
                              LSymbol.SymbolName := LSymbolName;
                              LSymbol.Kind := skConstant;
                              LSymbol.Line := GetNodeLine(LEnumChildObj);
                              LSymbol.Column := GetNodeCol(LEnumChildObj);
                              LSymbol.SourceFile := FCurrentFile;
                              FSymbolTable.AddSymbol(LSymbol);
                            end;
                            
                            { Skip next node if it's an EXPRESSION (explicit enum value) }
                            if (LK + 1 < LTypeChildren.Count) then
                            begin
                              LNextChild := LTypeChildren.Items[LK + 1];
                              if (LNextChild is TJSONObject) and 
                                 (GetNodeType(LNextChild as TJSONObject) = 'EXPRESSION') then
                                Inc(LK);
                            end;
                          end;
                        end;
                        Inc(LK);
                      end;
                    end;
                  end;
                end;
              end;
            end;
          end;
        end;
      end;
    end
    
    { VARIABLES: contains VARIABLE nodes with NAME and TYPE children }
    else if LNodeType = 'VARIABLES' then
    begin
      LChildren := GetNodeChildren(LChildObj);
      if LChildren <> nil then
      begin
        for LJ := 0 to LChildren.Count - 1 do
        begin
          LVarChild := LChildren.Items[LJ];
          if LVarChild is TJSONObject then
          begin
            LVarChildObj := LVarChild as TJSONObject;
            if GetNodeType(LVarChildObj) = 'VARIABLE' then
            begin
              { Extract name from first NAME child }
              LNameChild := FindNodeByType(GetNodeChildren(LVarChildObj), 'NAME');
              if LNameChild <> nil then
              begin
                LSymbolName := GetNodeAttribute(LNameChild, 'value');
                if LSymbolName <> '' then
                begin
                  LSymbol.SymbolName := LSymbolName;
                  LSymbol.Kind := skVariable;
                  LSymbol.Line := GetNodeLine(LVarChildObj);
                  LSymbol.Column := GetNodeCol(LVarChildObj);
                  LSymbol.SourceFile := FCurrentFile;
                  FSymbolTable.AddSymbol(LSymbol);
                end;
              end;
            end;
          end;
        end;
      end;
    end
    
    { CONSTANTS: contains DECLCONST or CONSTANT nodes }
    else if LNodeType = 'CONSTANTS' then
    begin
      LChildren := GetNodeChildren(LChildObj);
      if LChildren <> nil then
      begin
        for LJ := 0 to LChildren.Count - 1 do
        begin
          LVarChild := LChildren.Items[LJ];
          if LVarChild is TJSONObject then
          begin
            LVarChildObj := LVarChild as TJSONObject;
            LNodeType := GetNodeType(LVarChildObj);
            
            if (LNodeType = 'DECLCONST') or (LNodeType = 'CONSTANT') then
            begin
              LSymbolName := GetNodeAttribute(LVarChildObj, 'name');
              if LSymbolName <> '' then
              begin
                LSymbol.SymbolName := LSymbolName;
                LSymbol.Kind := skConstant;
                LSymbol.Line := GetNodeLine(LVarChildObj);
                LSymbol.Column := GetNodeCol(LVarChildObj);
                LSymbol.SourceFile := FCurrentFile;
                FSymbolTable.AddSymbol(LSymbol);
              end;
            end;
          end;
        end;
      end;
    end;
  end;
end;

procedure TNPSamantics.ValidateUnit(const AUnitName: string;
  const AUnitObj: TJSONObject);
var
  LASTValue: TJSONValue;
  LASTArray: TJSONArray;
  LI: Integer;
  LChildValue: TJSONValue;
  LChildObj: TJSONObject;
  LParent: TJSONObject;
  LUsedUnits: TStringList;
  LUsedUnitName: string;
  LUsedUnitObj: TJSONObject;
begin
  FCurrentFile := GetNodeAttribute(AUnitObj, 'path');
  
  { Collect interface symbols from all used units }
  LUsedUnits := GetUsedUnits(AUnitObj);
  try
    for LUsedUnitName in LUsedUnits do
    begin
      if FUnitsData.TryGetValue(LUsedUnitName, LUsedUnitObj) then
      begin
        CollectUnitInterfaceSymbols(LUsedUnitName, LUsedUnitObj);
      end;
    end;
  finally
    LUsedUnits.Free;
  end;
  
  LASTValue := AUnitObj.GetValue('ast');
  if not (LASTValue is TJSONArray) then
    Exit;
  
  LASTArray := LASTValue as TJSONArray;
  
  { Traverse and validate all nodes in unit }
  for LI := 0 to LASTArray.Count - 1 do
  begin
    LChildValue := LASTArray.Items[LI];
    if LChildValue is TJSONObject then
    begin
      LChildObj := LChildValue as TJSONObject;
      LParent := nil;
      TraverseNode(LChildObj, LParent);
    end;
  end;
end;

function TNPSamantics.Validate(const AJSON: string): Boolean;
var
  LRootObj: TJSONObject;
  LUnitsValue: TJSONValue;
  LUnitsArray: TJSONArray;
  LI: Integer;
  LUnitValue: TJSONValue;
  LUnitObj: TJSONObject;
  LUnitName: string;
  LASTArray: TJSONArray;
  LFirstNode: TJSONValue;
  LUnitNode: TJSONObject;
  LUnitChildren: TJSONArray;
begin
  Result := False;
  
  { Clear symbol table once at start }
  FSymbolTable.Clear;
  FWithDepth := 0;
  FUnitsData.Clear;
  
  try
    { Parse JSON }
    try
      LRootObj := TJSONObject.ParseJSONValue(AJSON) as TJSONObject;
      if LRootObj = nil then
      begin
        FErrorManager.AddError(NP_ERROR_INVALID, 0, 0, '', 
          'Invalid JSON format');
        Exit;
      end;
    except
      on E: Exception do
      begin
        FErrorManager.AddError(NP_ERROR_INVALID, 0, 0, '', 
          'JSON parse error: ' + E.Message);
        Exit;
      end;
    end;
    
    try
      { Get units array }
      LUnitsValue := LRootObj.GetValue('units');
      if not (LUnitsValue is TJSONArray) then
      begin
        FErrorManager.AddError(NP_ERROR_INVALID, 0, 0, '', 
          'JSON root has no "units" array');
        Exit;
      end;
      
      LUnitsArray := LUnitsValue as TJSONArray;
      
      { Phase 0: Store all units data for cross-references }
      for LI := 0 to LUnitsArray.Count - 1 do
      begin
        LUnitValue := LUnitsArray.Items[LI];
        if not (LUnitValue is TJSONObject) then
          Continue;
        
        LUnitObj := LUnitValue as TJSONObject;
        LUnitName := GetNodeAttribute(LUnitObj, 'name');
        if LUnitName <> '' then
          FUnitsData.Add(LUnitName, LUnitObj);
      end;
      
      { Phase 1: Collect all unit interface symbols }
      CollectAllUnitSymbols(LUnitsArray);
      
      { Phase 1b: Collect all unit global symbols (VAR, CONST, TYPE at top level) }
      for LI := 0 to LUnitsArray.Count - 1 do
      begin
        LUnitValue := LUnitsArray.Items[LI];
        if not (LUnitValue is TJSONObject) then
          Continue;
        
        LUnitObj := LUnitValue as TJSONObject;

        begin
          FCurrentFile := GetNodeAttribute(LUnitObj, 'path');
          
          { Get the UNIT node's AST array }
          LUnitValue := LUnitObj.GetValue('ast');
          if not (LUnitValue is TJSONArray) then
            Continue;
          
          { Get first element (the UNIT/PROGRAM node) }
          LASTArray := LUnitValue as TJSONArray;
          if LASTArray.Count = 0 then
            Continue;
          
          LFirstNode := LASTArray.Items[0];
          if not (LFirstNode is TJSONObject) then
            Continue;
          
          { Get the UNIT node's children and collect globals }
          LUnitNode := LFirstNode as TJSONObject;
          LUnitChildren := GetNodeChildren(LUnitNode);
          if LUnitChildren <> nil then
            CollectUnitGlobalSymbols(LUnitChildren);
        end;
      end;
      
      { Phase 2: Validate each unit }
      for LI := 0 to LUnitsArray.Count - 1 do
      begin
        LUnitValue := LUnitsArray.Items[LI];
        if not (LUnitValue is TJSONObject) then
          Continue;
        
        LUnitObj := LUnitValue as TJSONObject;
        LUnitName := GetNodeAttribute(LUnitObj, 'name');
        if LUnitName = '' then
          Continue;
        
        ValidateUnit(LUnitName, LUnitObj);
      end;
      
      Result := not FErrorManager.HasErrors;
    finally
      LRootObj.Free;
    end;
  except
    on E: Exception do
    begin
      FErrorManager.AddError(NP_ERROR_INTERNAL, 0, 0, '', 
        'Validation error: ' + E.Message);
    end;
  end;
end;

end.
