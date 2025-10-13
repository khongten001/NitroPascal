{ ===============================================================================
  NitroPascal - Modern Pascal • C Performance

  Copyright © 2025-present tinyBigGAMES™ LLC
  All Rights Reserved.

  https://nitropascal.org

  See LICENSE for license information
===============================================================================}

unit NitroPascal.CodeGen.Declarations;

{$I NitroPascal.Defines.inc}

interface

uses
  System.JSON,
  NitroPascal.CodeGen;

{ Generate Declarations }

procedure GenerateVariables(const ACodeGenerator: TNPCodeGenerator; const AVariablesNode: TJSONObject);
procedure GenerateExternVariables(const ACodeGenerator: TNPCodeGenerator; const AVariablesNode: TJSONObject);
procedure GenerateConstants(const ACodeGenerator: TNPCodeGenerator; const AConstantsNode: TJSONObject);
procedure GenerateTypeDeclarations(const ACodeGenerator: TNPCodeGenerator; const ATypeSectionNode: TJSONObject);
procedure GenerateEnumType(const ACodeGenerator: TNPCodeGenerator; const ATypeName: string; const ATypeNode: TJSONObject);
procedure GenerateRecordType(const ACodeGenerator: TNPCodeGenerator; const ATypeName: string; const ATypeNode: TJSONObject);
procedure GeneratePointerType(const ACodeGenerator: TNPCodeGenerator; const ATypeName: string; const ATypeNode: TJSONObject);
procedure GenerateFunctionDeclarations(const ACodeGenerator: TNPCodeGenerator; const AAST: TJSONArray);
procedure GenerateFunctionDeclaration(const ACodeGenerator: TNPCodeGenerator; const AMethodNode: TJSONObject);
procedure GenerateFunctionImplementation(const ACodeGenerator: TNPCodeGenerator; const AMethodNode: TJSONObject);
procedure GenerateFunctionImplementationWithExport(const ACodeGenerator: TNPCodeGenerator; const AMethodNode: TJSONObject; const AIsExported: Boolean);
function  GenerateParameterList(const ACodeGenerator: TNPCodeGenerator; const AMethodNode: TJSONObject): string;

implementation

uses
  System.SysUtils,
  System.Generics.Collections,
  System.StrUtils,
  NitroPascal.CodeGen.Statements,
  NitroPascal.CodeGen.Expressions;

function GenerateConstantValue(const ACodeGenerator: TNPCodeGenerator; const AValueNode: TJSONObject): string; forward;
function GenerateArrayConstant(const ACodeGenerator: TNPCodeGenerator; const AValueNode: TJSONObject): string; forward;
function IsStructType(const ACodeGenerator: TNPCodeGenerator; const ATypeName: string; const ATypeSectionNode: TJSONObject): Boolean; forward;
procedure GenerateSimpleTypeAlias(const ACodeGenerator: TNPCodeGenerator; const ATypeName: string; const ATypeNode: TJSONObject); forward;

function TransformStringToCharForConst(const AStringExpr: string): string;
var
  LStartPos: Integer;
  LEndPos: Integer;
  LValue: string;
begin
  // Transform: np::String("X") → u'X' (for constant declarations)
  // Same logic as in Statements unit, but kept separate for clarity
  
  if not AStringExpr.Contains('np::String(') then
  begin
    Result := AStringExpr;
    Exit;
  end;
  
  // Find the opening quote
  LStartPos := Pos('"', AStringExpr);
  if LStartPos = 0 then
  begin
    Result := AStringExpr;
    Exit;
  end;
  
  // Find the closing quote
  LEndPos := PosEx('"', AStringExpr, LStartPos + 1);
  if LEndPos = 0 then
  begin
    Result := AStringExpr;
    Exit;
  end;
  
  // Extract the string content between quotes
  LValue := Copy(AStringExpr, LStartPos + 1, LEndPos - LStartPos - 1);
  
  // Only convert if single character
  if Length(LValue) = 1 then
  begin
    // Convert to char literal: u'X'
    Result := Format('u''%s''', [LValue]);
  end
  else
  begin
    // Keep as string if multi-char
    Result := AStringExpr;
  end;
end;

procedure GenerateVariables(const ACodeGenerator: TNPCodeGenerator; const AVariablesNode: TJSONObject);
var
  LChildren: TJSONArray;
  LI: Integer;
  LChild: TJSONValue;
  LVarNode: TJSONObject;
  LNameNode: TJSONObject;
  LTypeNode: TJSONObject;
  LVarName: string;
  LVarType: string;
  LLiteralType: string;
  LTypeChildren: TJSONArray;
  LPointedType: string;
  LBoundsNode: TJSONObject;
  LDimensions: TJSONArray;
  LDimI: Integer;
  LDimNode: TJSONObject;
  LDimChildren: TJSONArray;
  LLowExpr: string;
  LHighExpr: string;
  LLowVal: Integer;
  LHighVal: Integer;
  LSize: Integer;
  LElementTypeNode: TJSONObject;
  LElementType: string;
begin
  LChildren := ACodeGenerator.GetNodeChildren(AVariablesNode);
  if LChildren = nil then
    Exit;
  
  for LI := 0 to LChildren.Count - 1 do
  begin
    LChild := LChildren.Items[LI];
    if not (LChild is TJSONObject) then
      Continue;
    
    LVarNode := LChild as TJSONObject;
    if ACodeGenerator.GetNodeType(LVarNode) <> 'VARIABLE' then
      Continue;
    
    // Get NAME and TYPE children
    LNameNode := ACodeGenerator.FindNodeByType(ACodeGenerator.GetNodeChildren(LVarNode), 'NAME');
    LTypeNode := ACodeGenerator.FindNodeByType(ACodeGenerator.GetNodeChildren(LVarNode), 'TYPE');
    
    if (LNameNode <> nil) and (LTypeNode <> nil) then
    begin
      LVarName := ACodeGenerator.GetNodeAttribute(LNameNode, 'value');
      LLiteralType := ACodeGenerator.GetNodeAttribute(LTypeNode, 'literalType');
      
      // Check if it's an array type
      if LLiteralType = 'array' then
      begin
        // Get array bounds and element type
        LTypeChildren := ACodeGenerator.GetNodeChildren(LTypeNode);
        if (LTypeChildren = nil) or (LTypeChildren.Count < 2) then
          Continue;
        
        // First child is BOUNDS
        LBoundsNode := ACodeGenerator.FindNodeByType(LTypeChildren, 'BOUNDS');
        if LBoundsNode = nil then
          Continue;
        
        // Last child is element TYPE
        LElementTypeNode := LTypeChildren.Items[LTypeChildren.Count - 1] as TJSONObject;
        if ACodeGenerator.GetNodeType(LElementTypeNode) <> 'TYPE' then
          Continue;
        
        LElementType := ACodeGenerator.TranslateType(
          ACodeGenerator.GetNodeAttribute(LElementTypeNode, 'name'));
        
        // Get dimensions
        LDimensions := ACodeGenerator.GetNodeChildren(LBoundsNode);
        if (LDimensions = nil) or (LDimensions.Count = 0) then
          Continue;
        
        // Build nested std::array type from innermost to outermost
        LVarType := LElementType;
        for LDimI := LDimensions.Count - 1 downto 0 do
        begin
          LDimNode := LDimensions.Items[LDimI] as TJSONObject;
          if ACodeGenerator.GetNodeType(LDimNode) <> 'DIMENSION' then
            Continue;
          
          LDimChildren := ACodeGenerator.GetNodeChildren(LDimNode);
          if (LDimChildren = nil) or (LDimChildren.Count < 2) then
            Continue;
          
          // Get low and high bounds
          LLowExpr := NitroPascal.CodeGen.Expressions.GenerateExpression(
            ACodeGenerator, LDimChildren.Items[0] as TJSONObject);
          LHighExpr := NitroPascal.CodeGen.Expressions.GenerateExpression(
            ACodeGenerator, LDimChildren.Items[1] as TJSONObject);
          
          // Calculate size (high - low + 1)
          LLowVal := StrToIntDef(LLowExpr, 0);
          LHighVal := StrToIntDef(LHighExpr, 0);
          LSize := LHighVal - LLowVal + 1;
          
          // Wrap in std::array
          LVarType := Format('std::array<%s, %d>', [LVarType, LSize]);
        end;
        
        // Track variable type
        ACodeGenerator.VariableTypes.AddOrSetValue(LVarName, LVarType);
        ACodeGenerator.EmitLine('%s %s;', [LVarType, LVarName]);
      end
      // Check if it's a pointer type
      else if LLiteralType = 'pointer' then
      begin
        // Get the pointed-to type from children
        LTypeChildren := ACodeGenerator.GetNodeChildren(LTypeNode);
        if (LTypeChildren <> nil) and (LTypeChildren.Count > 0) then
        begin
          LPointedType := ACodeGenerator.GetNodeAttribute(LTypeChildren.Items[0] as TJSONObject, 'name');
          LVarType := ACodeGenerator.TranslateType(LPointedType) + '*';
        end
        else
          LVarType := 'void*';  // Fallback for untyped pointer
        
        // Track variable type
        ACodeGenerator.VariableTypes.AddOrSetValue(LVarName, LVarType);
        ACodeGenerator.EmitLine('%s %s;', [LVarType, LVarName]);
      end
      else
      begin
        LVarType := ACodeGenerator.TranslateType(ACodeGenerator.GetNodeAttribute(LTypeNode, 'name'));
        // Track variable type
        ACodeGenerator.VariableTypes.AddOrSetValue(LVarName, LVarType);
        ACodeGenerator.EmitLine('%s %s;', [LVarType, LVarName]);
      end;
    end;
  end;
end;

procedure GenerateExternVariables(const ACodeGenerator: TNPCodeGenerator; const AVariablesNode: TJSONObject);
var
  LChildren: TJSONArray;
  LI: Integer;
  LChild: TJSONValue;
  LVarNode: TJSONObject;
  LNameNode: TJSONObject;
  LTypeNode: TJSONObject;
  LVarName: string;
  LVarType: string;
  LLiteralType: string;
  LTypeChildren: TJSONArray;
  LPointedType: string;
  LBoundsNode: TJSONObject;
  LDimensions: TJSONArray;
  LDimI: Integer;
  LDimNode: TJSONObject;
  LDimChildren: TJSONArray;
  LLowExpr: string;
  LHighExpr: string;
  LLowVal: Integer;
  LHighVal: Integer;
  LSize: Integer;
  LElementTypeNode: TJSONObject;
  LElementType: string;
begin
  LChildren := ACodeGenerator.GetNodeChildren(AVariablesNode);
  if LChildren = nil then
    Exit;
  
  for LI := 0 to LChildren.Count - 1 do
  begin
    LChild := LChildren.Items[LI];
    if not (LChild is TJSONObject) then
      Continue;
    
    LVarNode := LChild as TJSONObject;
    if ACodeGenerator.GetNodeType(LVarNode) <> 'VARIABLE' then
      Continue;
    
    // Get NAME and TYPE children
    LNameNode := ACodeGenerator.FindNodeByType(ACodeGenerator.GetNodeChildren(LVarNode), 'NAME');
    LTypeNode := ACodeGenerator.FindNodeByType(ACodeGenerator.GetNodeChildren(LVarNode), 'TYPE');
    
    if (LNameNode <> nil) and (LTypeNode <> nil) then
    begin
      LVarName := ACodeGenerator.GetNodeAttribute(LNameNode, 'value');
      LLiteralType := ACodeGenerator.GetNodeAttribute(LTypeNode, 'literalType');
      
      // Check if it's an array type
      if LLiteralType = 'array' then
      begin
        // Get array bounds and element type
        LTypeChildren := ACodeGenerator.GetNodeChildren(LTypeNode);
        if (LTypeChildren = nil) or (LTypeChildren.Count < 2) then
          Continue;
        
        // First child is BOUNDS
        LBoundsNode := ACodeGenerator.FindNodeByType(LTypeChildren, 'BOUNDS');
        if LBoundsNode = nil then
          Continue;
        
        // Last child is element TYPE
        LElementTypeNode := LTypeChildren.Items[LTypeChildren.Count - 1] as TJSONObject;
        if ACodeGenerator.GetNodeType(LElementTypeNode) <> 'TYPE' then
          Continue;
        
        LElementType := ACodeGenerator.TranslateType(
          ACodeGenerator.GetNodeAttribute(LElementTypeNode, 'name'));
        
        // Get dimensions
        LDimensions := ACodeGenerator.GetNodeChildren(LBoundsNode);
        if (LDimensions = nil) or (LDimensions.Count = 0) then
          Continue;
        
        // Build nested std::array type from innermost to outermost
        LVarType := LElementType;
        for LDimI := LDimensions.Count - 1 downto 0 do
        begin
          LDimNode := LDimensions.Items[LDimI] as TJSONObject;
          if ACodeGenerator.GetNodeType(LDimNode) <> 'DIMENSION' then
            Continue;
          
          LDimChildren := ACodeGenerator.GetNodeChildren(LDimNode);
          if (LDimChildren = nil) or (LDimChildren.Count < 2) then
            Continue;
          
          // Get low and high bounds
          LLowExpr := NitroPascal.CodeGen.Expressions.GenerateExpression(
            ACodeGenerator, LDimChildren.Items[0] as TJSONObject);
          LHighExpr := NitroPascal.CodeGen.Expressions.GenerateExpression(
            ACodeGenerator, LDimChildren.Items[1] as TJSONObject);
          
          // Calculate size (high - low + 1)
          LLowVal := StrToIntDef(LLowExpr, 0);
          LHighVal := StrToIntDef(LHighExpr, 0);
          LSize := LHighVal - LLowVal + 1;
          
          // Wrap in std::array
          LVarType := Format('std::array<%s, %d>', [LVarType, LSize]);
        end;
        
        ACodeGenerator.EmitLine('extern %s %s;', [LVarType, LVarName]);
      end
      // Check if it's a pointer type
      else if LLiteralType = 'pointer' then
      begin
        // Get the pointed-to type from children
        LTypeChildren := ACodeGenerator.GetNodeChildren(LTypeNode);
        if (LTypeChildren <> nil) and (LTypeChildren.Count > 0) then
        begin
          LPointedType := ACodeGenerator.GetNodeAttribute(LTypeChildren.Items[0] as TJSONObject, 'name');
          LVarType := ACodeGenerator.TranslateType(LPointedType) + '*';
        end
        else
          LVarType := 'void*';  // Fallback for untyped pointer
        
        ACodeGenerator.EmitLine('extern %s %s;', [LVarType, LVarName]);
      end
      else
      begin
        LVarType := ACodeGenerator.TranslateType(ACodeGenerator.GetNodeAttribute(LTypeNode, 'name'));
        ACodeGenerator.EmitLine('extern %s %s;', [LVarType, LVarName]);
      end;
    end;
  end;
end;

procedure GenerateConstants(const ACodeGenerator: TNPCodeGenerator; const AConstantsNode: TJSONObject);
var
  LChildren: TJSONArray;
  LI: Integer;
  LChild: TJSONValue;
  LConstNode: TJSONObject;
  LNameNode: TJSONObject;
  LTypeNode: TJSONObject;
  LValueNode: TJSONObject;
  LConstName: string;
  LConstType: string;
  LConstValue: string;
  LHasType: Boolean;
  LLiteralType: string;
begin
  LChildren := ACodeGenerator.GetNodeChildren(AConstantsNode);
  if LChildren = nil then
    Exit;
  
  for LI := 0 to LChildren.Count - 1 do
  begin
    LChild := LChildren.Items[LI];
    if not (LChild is TJSONObject) then
      Continue;
    
    LConstNode := LChild as TJSONObject;
    if ACodeGenerator.GetNodeType(LConstNode) <> 'CONSTANT' then
      Continue;
    
    // Get NAME
    LNameNode := ACodeGenerator.FindNodeByType(ACodeGenerator.GetNodeChildren(LConstNode), 'NAME');
    if LNameNode = nil then
      Continue;
    
    LConstName := ACodeGenerator.GetNodeAttribute(LNameNode, 'value');
    
    // Check if TYPE exists (typed constant)
    LTypeNode := ACodeGenerator.FindNodeByType(ACodeGenerator.GetNodeChildren(LConstNode), 'TYPE');
    LHasType := LTypeNode <> nil;
    
    // Get VALUE
    LValueNode := ACodeGenerator.FindNodeByType(ACodeGenerator.GetNodeChildren(LConstNode), 'VALUE');
    if LValueNode = nil then
      Continue;
    
    if LHasType then
    begin
      // Typed constant: const TPoint ORIGIN = {0, 0};
      LConstType := ACodeGenerator.GetNodeAttribute(LTypeNode, 'name');
      LLiteralType := ACodeGenerator.GetNodeAttribute(LTypeNode, 'literalType');
      
      if LLiteralType = 'array' then
      begin
        // Array constant - need to build type and initializer
        LConstValue := GenerateArrayConstant(ACodeGenerator, LValueNode);
        ACodeGenerator.EmitLine('const np::Integer %s[] = %s;', [LConstName, LConstValue]);
      end
      else if LConstType <> '' then
      begin
        // Record or simple typed constant
        LConstType := ACodeGenerator.TranslateType(LConstType);
        LConstValue := GenerateConstantValue(ACodeGenerator, LValueNode);
        
        // Apply Char transformation if needed (same as assignment fix)
        if (LConstType = 'np::Char') and LConstValue.Contains('np::String(') then
        begin
          // Transform: np::String("X") → u'X'
          LConstValue := TransformStringToCharForConst(LConstValue);
        end;
        
        ACodeGenerator.EmitLine('const %s %s = %s;', [LConstType, LConstName, LConstValue]);
      end;
    end
    else
    begin
      // Simple constant: constexpr auto MAX_SIZE = 100;
      LConstValue := GenerateConstantValue(ACodeGenerator, LValueNode);
      
      // String constants must use 'const' not 'constexpr' because np::String is not a literal type
      if LConstValue.Contains('np::String') then
        ACodeGenerator.EmitLine('const auto %s = %s;', [LConstName, LConstValue])
      else
        ACodeGenerator.EmitLine('constexpr auto %s = %s;', [LConstName, LConstValue]);
    end;
  end;
end;

function GenerateConstantValue(const ACodeGenerator: TNPCodeGenerator; const AValueNode: TJSONObject): string;
var
  LChildren: TJSONArray;
  LExprNode: TJSONObject;
  LI: Integer;
  LField: TJSONObject;
  LFieldName: string;
  LFieldValue: string;
  LResult: TStringBuilder;
begin
  LChildren := ACodeGenerator.GetNodeChildren(AValueNode);
  if (LChildren = nil) or (LChildren.Count = 0) then
  begin
    Result := '';
    Exit;
  end;
  
  // Check if it's a record initializer (has FIELD children)
  if ACodeGenerator.GetNodeType(LChildren.Items[0] as TJSONObject) = 'FIELD' then
  begin
    // Record initialization: {.X = 0, .Y = 0}
    LResult := TStringBuilder.Create();
    try
      LResult.Append('{');
      
      for LI := 0 to LChildren.Count - 1 do
      begin
        LField := LChildren.Items[LI] as TJSONObject;
        if ACodeGenerator.GetNodeType(LField) <> 'FIELD' then
          Continue;
        
        LFieldName := ACodeGenerator.GetNodeAttribute(LField, 'value');
        LFieldValue := NitroPascal.CodeGen.Expressions.GenerateExpression(
          ACodeGenerator,
          ACodeGenerator.GetNodeChildren(LField).Items[0] as TJSONObject);
        
        if LI > 0 then
          LResult.Append(', ');
        LResult.AppendFormat('.%s = %s', [LFieldName, LFieldValue]);
      end;
      
      LResult.Append('}');
      Result := LResult.ToString();
    finally
      LResult.Free();
    end;
  end
  else
  begin
    // Expression value
    LExprNode := LChildren.Items[0] as TJSONObject;
    Result := NitroPascal.CodeGen.Expressions.GenerateExpression(ACodeGenerator, LExprNode);
  end;
end;

function GenerateArrayConstant(const ACodeGenerator: TNPCodeGenerator; const AValueNode: TJSONObject): string;
var
  LChildren: TJSONArray;
  LExprsNode: TJSONObject;
  LExprArray: TJSONArray;
  LI: Integer;
  LExpr: string;
  LResult: TStringBuilder;
begin
  LChildren := ACodeGenerator.GetNodeChildren(AValueNode);
  if (LChildren = nil) or (LChildren.Count = 0) then
  begin
    Result := '{}';
    Exit;
  end;
  
  LExprsNode := LChildren.Items[0] as TJSONObject;
  if ACodeGenerator.GetNodeType(LExprsNode) <> 'EXPRESSIONS' then
  begin
    Result := '{}';
    Exit;
  end;
  
  LExprArray := ACodeGenerator.GetNodeChildren(LExprsNode);
  if LExprArray = nil then
  begin
    Result := '{}';
    Exit;
  end;
  
  LResult := TStringBuilder.Create();
  try
    LResult.Append('{');
    
    for LI := 0 to LExprArray.Count - 1 do
    begin
      LExpr := NitroPascal.CodeGen.Expressions.GenerateExpression(
        ACodeGenerator,
        LExprArray.Items[LI] as TJSONObject);
      
      if LI > 0 then
        LResult.Append(', ');
      LResult.Append(LExpr);
    end;
    
    LResult.Append('}');
    Result := LResult.ToString();
  finally
    LResult.Free();
  end;
end;

function IsStructType(const ACodeGenerator: TNPCodeGenerator; const ATypeName: string; const ATypeSectionNode: TJSONObject): Boolean;
var
  LChildren: TJSONArray;
  LI: Integer;
  LTypeDeclNode: TJSONObject;
  LTypeNode: TJSONObject;
  LDeclName: string;
  LLiteralType: string;
begin
  Result := False;
  LChildren := ACodeGenerator.GetNodeChildren(ATypeSectionNode);
  if LChildren = nil then
    Exit;
    
  for LI := 0 to LChildren.Count - 1 do
  begin
    if not (LChildren.Items[LI] is TJSONObject) then
      Continue;
      
    LTypeDeclNode := LChildren.Items[LI] as TJSONObject;
    if ACodeGenerator.GetNodeType(LTypeDeclNode) <> 'TYPEDECL' then
      Continue;
      
    LDeclName := ACodeGenerator.GetNodeAttribute(LTypeDeclNode, 'name');
    if LDeclName = ATypeName then
    begin
      LTypeNode := ACodeGenerator.FindNodeByType(
        ACodeGenerator.GetNodeChildren(LTypeDeclNode), 'TYPE');
      if LTypeNode <> nil then
      begin
        LLiteralType := ACodeGenerator.GetNodeAttribute(LTypeNode, 'literalType');
        Result := (LLiteralType = 'record');
      end;
      Exit;
    end;
  end;
end;

procedure GenerateSimpleTypeAlias(const ACodeGenerator: TNPCodeGenerator; const ATypeName: string; const ATypeNode: TJSONObject);
var
  LBaseType: string;
  LCppType: string;
begin
  LBaseType := ACodeGenerator.GetNodeAttribute(ATypeNode, 'name');
  LCppType := ACodeGenerator.TranslateType(LBaseType);
  ACodeGenerator.EmitLine('using %s = %s;', [ATypeName, LCppType]);
end;

procedure GenerateTypeDeclarations(const ACodeGenerator: TNPCodeGenerator; const ATypeSectionNode: TJSONObject);
var
  LChildren: TJSONArray;
  LI: Integer;
  LChild: TJSONValue;
  LTypeDeclNode: TJSONObject;
  LTypeNode: TJSONObject;
  LTypeName: string;
  LLiteralType: string;
  LTypeDef: string;
begin
  LChildren := ACodeGenerator.GetNodeChildren(ATypeSectionNode);
  if LChildren = nil then
    Exit;
  
  // First pass: Forward declare structs and their pointer types to avoid forward reference issues
  for LI := 0 to LChildren.Count - 1 do
  begin
    LChild := LChildren.Items[LI];
    if not (LChild is TJSONObject) then
      Continue;
    
    LTypeDeclNode := LChild as TJSONObject;
    if ACodeGenerator.GetNodeType(LTypeDeclNode) <> 'TYPEDECL' then
      Continue;
    
    LTypeName := ACodeGenerator.GetNodeAttribute(LTypeDeclNode, 'name');
    LTypeNode := ACodeGenerator.FindNodeByType(ACodeGenerator.GetNodeChildren(LTypeDeclNode), 'TYPE');
    if LTypeNode = nil then
      Continue;
    
    LLiteralType := ACodeGenerator.GetNodeAttribute(LTypeNode, 'literalType');
    
    // Forward declare pointer types
    if LLiteralType = 'pointer' then
    begin
      // Forward declare the target type if it's not a primitive
      var LTargetChildren := ACodeGenerator.GetNodeChildren(LTypeNode);
      if (LTargetChildren <> nil) and (LTargetChildren.Count > 0) then
      begin
        var LTargetTypeNode := LTargetChildren.Items[0] as TJSONObject;
        var LTargetType := ACodeGenerator.GetNodeAttribute(LTargetTypeNode, 'name');
        // Check if target is not a primitive type
        if not ((LTargetType = 'Integer') or (LTargetType = 'Boolean') or 
                (LTargetType = 'Double') or (LTargetType = 'String') or
                (LTargetType = 'Byte') or (LTargetType = 'Word') or
                (LTargetType = 'Cardinal') or (LTargetType = 'Int64')) then
        begin
          // Only forward declare if target is an actual struct/record, not a type alias
          var LIsActualStruct := IsStructType(ACodeGenerator, LTargetType, ATypeSectionNode);
          if LIsActualStruct then
          begin
            ACodeGenerator.EmitLine('struct %s;', [LTargetType]);
            // Immediately declare the pointer type so it's available for struct definitions
            ACodeGenerator.EmitLine('using %s = %s*;', [LTypeName, LTargetType]);
          end;
        end;
      end;
    end;
  end;
  
  // Second pass: Generate full type declarations
  for LI := 0 to LChildren.Count - 1 do
  begin
    LChild := LChildren.Items[LI];
    if not (LChild is TJSONObject) then
      Continue;
    
    LTypeDeclNode := LChild as TJSONObject;
    if ACodeGenerator.GetNodeType(LTypeDeclNode) <> 'TYPEDECL' then
      Continue;
    
    // Get type name
    LTypeName := ACodeGenerator.GetNodeAttribute(LTypeDeclNode, 'name');
    
    // Get TYPE node
    LTypeNode := ACodeGenerator.FindNodeByType(ACodeGenerator.GetNodeChildren(LTypeDeclNode), 'TYPE');
    if LTypeNode = nil then
      Continue;
    
    // Check if it's an enum by looking at the 'name' attribute
    LTypeDef := ACodeGenerator.GetNodeAttribute(LTypeNode, 'name');
    if LTypeDef = 'enum' then
    begin
      GenerateEnumType(ACodeGenerator, LTypeName, LTypeNode);
    end
    else
    begin
      // Get literal type to determine what kind of type this is
      LLiteralType := ACodeGenerator.GetNodeAttribute(LTypeNode, 'literalType');
      
      if LLiteralType = 'record' then
        GenerateRecordType(ACodeGenerator, LTypeName, LTypeNode)
      else if LLiteralType = 'pointer' then
      begin
        // Skip pointer types - they were already declared in first pass
        // (only for pointers to structs; other pointers still need generation)
        var LTargetChildren := ACodeGenerator.GetNodeChildren(LTypeNode);
        if (LTargetChildren <> nil) and (LTargetChildren.Count > 0) then
        begin
          var LTargetTypeNode := LTargetChildren.Items[0] as TJSONObject;
          var LTargetType := ACodeGenerator.GetNodeAttribute(LTargetTypeNode, 'name');
          var LIsPrimitive := ((LTargetType = 'Integer') or (LTargetType = 'Boolean') or 
                              (LTargetType = 'Double') or (LTargetType = 'String') or
                              (LTargetType = 'Byte') or (LTargetType = 'Word') or
                              (LTargetType = 'Cardinal') or (LTargetType = 'Int64'));
          var LIsActualStruct := not LIsPrimitive and IsStructType(ACodeGenerator, LTargetType, ATypeSectionNode);
          // Only generate if NOT already declared in first pass
          if not LIsActualStruct then
            GeneratePointerType(ACodeGenerator, LTypeName, LTypeNode);
        end
        else
          GeneratePointerType(ACodeGenerator, LTypeName, LTypeNode);
      end
      else if (LTypeDef <> '') and (LLiteralType = '') then
      begin
        // Simple type alias: TMyInt = Integer
        GenerateSimpleTypeAlias(ACodeGenerator, LTypeName, LTypeNode);
      end;
      // Add more type kinds here as needed (class, array, etc.)
    end;
  end;
end;

procedure GenerateEnumType(const ACodeGenerator: TNPCodeGenerator; const ATypeName: string; const ATypeNode: TJSONObject);
var
  LChildren: TJSONArray;
  LI: Integer;
  LChild: TJSONValue;
  LEnumValue: TJSONObject;
  LEnumName: string;
  LExpressionNode: TJSONObject;
  LLiteralNode: TJSONObject;
  LExplicitValue: string;
  LIsFirst: Boolean;
  LExprChildren: TJSONArray;
begin
  // Emit enum opening
  ACodeGenerator.EmitLine('enum %s {', [ATypeName]);
  ACodeGenerator.IncIndent();
  
  // Get enum values
  LChildren := ACodeGenerator.GetNodeChildren(ATypeNode);
  if LChildren <> nil then
  begin
    LIsFirst := True;
    LI := 0;
    while LI < LChildren.Count do
    begin
      LChild := LChildren.Items[LI];
      if not (LChild is TJSONObject) then
      begin
        Inc(LI);
        Continue;
      end;
      
      LEnumValue := LChild as TJSONObject;
      if ACodeGenerator.GetNodeType(LEnumValue) <> 'IDENTIFIER' then
      begin
        Inc(LI);
        Continue;
      end;
      
      // Get enum value name
      LEnumName := ACodeGenerator.GetNodeAttribute(LEnumValue, 'name');
      
      if not LIsFirst then
        ACodeGenerator.Emit(',', [])
      else
        LIsFirst := False;
      
      // Check if next element is an EXPRESSION (explicit value)
      LExplicitValue := '';
      if (LI + 1 < LChildren.Count) then
      begin
        LChild := LChildren.Items[LI + 1];
        if (LChild is TJSONObject) and 
           (ACodeGenerator.GetNodeType(LChild as TJSONObject) = 'EXPRESSION') then
        begin
          LExpressionNode := LChild as TJSONObject;
          // Get the literal value from the expression
          LExprChildren := ACodeGenerator.GetNodeChildren(LExpressionNode);
          if (LExprChildren <> nil) and (LExprChildren.Count > 0) then
          begin
            LLiteralNode := LExprChildren.Items[0] as TJSONObject;
            if ACodeGenerator.GetNodeType(LLiteralNode) = 'LITERAL' then
            begin
              LExplicitValue := ACodeGenerator.GetNodeAttribute(LLiteralNode, 'value');
              Inc(LI); // Skip the EXPRESSION node
            end;
          end;
        end;
      end;
      
      // Emit enum value
      if LExplicitValue <> '' then
      begin
        ACodeGenerator.EmitLn();
        ACodeGenerator.Emit('%s%s = %s', [ACodeGenerator.GetIndent(), LEnumName, LExplicitValue]);
      end
      else
      begin
        ACodeGenerator.EmitLn();
        ACodeGenerator.Emit('%s%s', [ACodeGenerator.GetIndent(), LEnumName]);
      end;
      
      Inc(LI);
    end;
  end;
  
  ACodeGenerator.EmitLn();
  ACodeGenerator.DecIndent();
  ACodeGenerator.EmitLine('};', []);
end;

procedure GenerateRecordType(const ACodeGenerator: TNPCodeGenerator; const ATypeName: string; const ATypeNode: TJSONObject);
var
  LChildren: TJSONArray;
  LI: Integer;
  LChild: TJSONValue;
  LFieldNode: TJSONObject;
  LFieldNameNode: TJSONObject;
  LFieldTypeNode: TJSONObject;
  LFieldName: string;
  LFieldType: string;
begin
  // Emit struct opening
  ACodeGenerator.EmitLine('struct %s {', [ATypeName]);
  ACodeGenerator.IncIndent();
  
  // Get fields
  LChildren := ACodeGenerator.GetNodeChildren(ATypeNode);
  if LChildren <> nil then
  begin
    for LI := 0 to LChildren.Count - 1 do
    begin
      LChild := LChildren.Items[LI];
      if not (LChild is TJSONObject) then
        Continue;
      
      LFieldNode := LChild as TJSONObject;
      if ACodeGenerator.GetNodeType(LFieldNode) <> 'FIELD' then
        Continue;
      
      // Get field NAME and TYPE children
      LFieldNameNode := ACodeGenerator.FindNodeByType(ACodeGenerator.GetNodeChildren(LFieldNode), 'NAME');
      LFieldTypeNode := ACodeGenerator.FindNodeByType(ACodeGenerator.GetNodeChildren(LFieldNode), 'TYPE');
      
      if (LFieldNameNode <> nil) and (LFieldTypeNode <> nil) then
      begin
        LFieldName := ACodeGenerator.GetNodeAttribute(LFieldNameNode, 'value');
        LFieldType := ACodeGenerator.TranslateType(ACodeGenerator.GetNodeAttribute(LFieldTypeNode, 'name'));
        ACodeGenerator.EmitLine('%s %s;', [LFieldType, LFieldName]);
      end;
    end;
  end;
  
  ACodeGenerator.DecIndent();
  ACodeGenerator.EmitLine('};', []);
end;

procedure GeneratePointerType(const ACodeGenerator: TNPCodeGenerator; const ATypeName: string; const ATypeNode: TJSONObject);
var
  LChildren: TJSONArray;
  LTargetTypeNode: TJSONObject;
  LTargetType: string;
begin
  // Get the target type (what the pointer points to)
  LChildren := ACodeGenerator.GetNodeChildren(ATypeNode);
  if (LChildren = nil) or (LChildren.Count = 0) then
    Exit;
  
  LTargetTypeNode := LChildren.Items[0] as TJSONObject;
  LTargetType := ACodeGenerator.GetNodeAttribute(LTargetTypeNode, 'name');
  
  // Translate type and emit using (modern C++ style)
  LTargetType := ACodeGenerator.TranslateType(LTargetType);
  ACodeGenerator.EmitLine('using %s = %s*;', [ATypeName, LTargetType]);
end;

procedure GenerateFunctionDeclarations(const ACodeGenerator: TNPCodeGenerator; const AAST: TJSONArray);
var
  LI: Integer;
  LChild: TJSONValue;
  LChildObj: TJSONObject;
  LNodeType: string;
begin
  if AAST = nil then
    Exit;
  
  for LI := 0 to AAST.Count - 1 do
  begin
    LChild := AAST.Items[LI];
    if not (LChild is TJSONObject) then
      Continue;
    
    LChildObj := LChild as TJSONObject;
    LNodeType := ACodeGenerator.GetNodeType(LChildObj);
    
    if (LNodeType = 'METHOD') or (LNodeType = 'PROCEDURE') or (LNodeType = 'FUNCTION') then
    begin
      GenerateFunctionImplementation(ACodeGenerator, LChildObj);
      ACodeGenerator.EmitLn();
    end;
  end;
end;

procedure GenerateFunctionDeclaration(const ACodeGenerator: TNPCodeGenerator; const AMethodNode: TJSONObject);
var
  LChildren: TJSONArray;
  LI: Integer;
  LChild: TJSONValue;
  LChildObj: TJSONObject;
  LNodeType: string;
  LMethodName: string;
  LReturnType: string;
  LParameters: string;
begin
  LChildren := ACodeGenerator.GetNodeChildren(AMethodNode);
  if LChildren = nil then
    Exit;
  
  // Extract method information
  // Get method name directly from METHOD node attribute
  LMethodName := ACodeGenerator.GetNodeAttribute(AMethodNode, 'name');
  LReturnType := 'void';
  LParameters := '';
  
  for LI := 0 to LChildren.Count - 1 do
  begin
    LChild := LChildren.Items[LI];
    if not (LChild is TJSONObject) then
      Continue;
    
    LChildObj := LChild as TJSONObject;
    LNodeType := ACodeGenerator.GetNodeType(LChildObj);
    
    if LNodeType = 'RETURNTYPE' then
    begin
      if ACodeGenerator.GetNodeChildren(LChildObj).Count > 0 then
      begin
        LChild := ACodeGenerator.GetNodeChildren(LChildObj).Items[0];
        if LChild is TJSONObject then
          LReturnType := ACodeGenerator.TranslateType(ACodeGenerator.GetNodeAttribute(LChild as TJSONObject, 'name'));
      end;
    end;
  end;
  
  // Get parameter list
  LParameters := GenerateParameterList(ACodeGenerator, AMethodNode);
  
  // Generate function declaration (no body)
  ACodeGenerator.EmitLine('%s %s(%s);', [LReturnType, LMethodName, LParameters]);
end;

procedure GenerateFunctionImplementation(const ACodeGenerator: TNPCodeGenerator; const AMethodNode: TJSONObject);
var
  LChildren: TJSONArray;
  LI: Integer;
  LChild: TJSONValue;
  LChildObj: TJSONObject;
  LNodeType: string;
  LMethodName: string;
  LReturnType: string;
  LParameters: string;
  LStatementsNode: TJSONObject;
  LVariablesNode: TJSONObject;
begin
  LChildren := ACodeGenerator.GetNodeChildren(AMethodNode);
  if LChildren = nil then
    Exit;
  
  // Extract method information
  // Get method name directly from METHOD node attribute
  LMethodName := ACodeGenerator.GetNodeAttribute(AMethodNode, 'name');
  LReturnType := 'void';
  LParameters := '';
  LStatementsNode := nil;
  
  for LI := 0 to LChildren.Count - 1 do
  begin
    LChild := LChildren.Items[LI];
    if not (LChild is TJSONObject) then
      Continue;
    
    LChildObj := LChild as TJSONObject;
    LNodeType := ACodeGenerator.GetNodeType(LChildObj);
    
    if LNodeType = 'RETURNTYPE' then
    begin
      if ACodeGenerator.GetNodeChildren(LChildObj).Count > 0 then
      begin
        LChild := ACodeGenerator.GetNodeChildren(LChildObj).Items[0];
        if LChild is TJSONObject then
          LReturnType := ACodeGenerator.TranslateType(ACodeGenerator.GetNodeAttribute(LChild as TJSONObject, 'name'));
      end;
    end
    else if LNodeType = 'STATEMENTS' then
      LStatementsNode := LChildObj;
  end;
  
  // Get parameter list
  LParameters := GenerateParameterList(ACodeGenerator, AMethodNode);
  
  // Generate function signature
  ACodeGenerator.EmitLine('%s %s(%s) {', [LReturnType, LMethodName, LParameters]);
  ACodeGenerator.IncIndent();
  
  // Declare Result variable for functions (not procedures)
  if LReturnType <> 'void' then
  begin
    ACodeGenerator.EmitLine('%s Result;', [LReturnType]);
  end;
  
  // Handle local variables from VARIABLES node
  LVariablesNode := ACodeGenerator.FindNodeByType(LChildren, 'VARIABLES');
  if LVariablesNode <> nil then
  begin
    GenerateVariables(ACodeGenerator, LVariablesNode);
  end;
  
  // Generate function body
  if LStatementsNode <> nil then
    NitroPascal.CodeGen.Statements.GenerateStatements(ACodeGenerator, LStatementsNode);
  
  // Return Result for functions
  if LReturnType <> 'void' then
  begin
    ACodeGenerator.EmitLine('return Result;', []);
  end;
  
  ACodeGenerator.DecIndent();
  ACodeGenerator.EmitLine('}', []);
end;

procedure GenerateFunctionImplementationWithExport(const ACodeGenerator: TNPCodeGenerator; const AMethodNode: TJSONObject; const AIsExported: Boolean);
var
  LChildren: TJSONArray;
  LI: Integer;
  LChild: TJSONValue;
  LChildObj: TJSONObject;
  LNodeType: string;
  LMethodName: string;
  LReturnType: string;
  LParameters: string;
  LStatementsNode: TJSONObject;
  LVariablesNode: TJSONObject;
  LCallingConvention: string;
  LCallConv: string;
  LExportPrefix: string;
begin
  LChildren := ACodeGenerator.GetNodeChildren(AMethodNode);
  if LChildren = nil then
    Exit;
  
  // Extract method information
  LMethodName := ACodeGenerator.GetNodeAttribute(AMethodNode, 'name');
  LReturnType := 'void';
  LParameters := '';
  LStatementsNode := nil;
  LCallingConvention := ACodeGenerator.GetNodeAttribute(AMethodNode, 'callingconvention');
  
  // Map calling convention
  LCallConv := '';
  if LCallingConvention = 'stdcall' then
    LCallConv := ' STDCALL'
  else if LCallingConvention = 'cdecl' then
    LCallConv := ' CDECL';
  
  // Determine export prefix
  if AIsExported then
    LExportPrefix := 'EXPORT_API '
  else
    LExportPrefix := '';
  
  for LI := 0 to LChildren.Count - 1 do
  begin
    LChild := LChildren.Items[LI];
    if not (LChild is TJSONObject) then
      Continue;
    
    LChildObj := LChild as TJSONObject;
    LNodeType := ACodeGenerator.GetNodeType(LChildObj);
    
    if LNodeType = 'RETURNTYPE' then
    begin
      if ACodeGenerator.GetNodeChildren(LChildObj).Count > 0 then
      begin
        LChild := ACodeGenerator.GetNodeChildren(LChildObj).Items[0];
        if LChild is TJSONObject then
          LReturnType := ACodeGenerator.TranslateType(
            ACodeGenerator.GetNodeAttribute(LChild as TJSONObject, 'name'));
      end;
    end
    else if LNodeType = 'STATEMENTS' then
      LStatementsNode := LChildObj;
  end;
  
  // Get parameter list
  LParameters := GenerateParameterList(ACodeGenerator, AMethodNode);
  
  // Generate function signature with export and calling convention
  ACodeGenerator.EmitLine('%s%s%s %s(%s) {', 
    [LExportPrefix, LReturnType, LCallConv, LMethodName, LParameters]);
  ACodeGenerator.IncIndent();
  
  // Declare Result variable for functions (not procedures)
  if LReturnType <> 'void' then
  begin
    ACodeGenerator.EmitLine('%s Result;', [LReturnType]);
  end;
  
  // Handle local variables
  LVariablesNode := ACodeGenerator.FindNodeByType(LChildren, 'VARIABLES');
  if LVariablesNode <> nil then
  begin
    GenerateVariables(ACodeGenerator, LVariablesNode);
  end;
  
  // Generate function body
  if LStatementsNode <> nil then
    NitroPascal.CodeGen.Statements.GenerateStatements(ACodeGenerator, LStatementsNode);
  
  // Return Result for functions
  if LReturnType <> 'void' then
  begin
    ACodeGenerator.EmitLine('return Result;', []);
  end;
  
  ACodeGenerator.DecIndent();
  ACodeGenerator.EmitLine('}', []);
end;

function GenerateParameterList(const ACodeGenerator: TNPCodeGenerator; const AMethodNode: TJSONObject): string;
var
  LChildren: TJSONArray;
  LParametersNode: TJSONObject;
  LParamChildren: TJSONArray;
  LI: Integer;
  LParamNode: TJSONObject;
  LNameNode: TJSONObject;
  LTypeNode: TJSONObject;
  LKind: string;
  LName: string;
  LType: string;
  LParam: string;
begin
  Result := '';
  
  LChildren := ACodeGenerator.GetNodeChildren(AMethodNode);
  if LChildren = nil then
    Exit;
  
  // Find PARAMETERS node
  LParametersNode := ACodeGenerator.FindNodeByType(LChildren, 'PARAMETERS');
  if LParametersNode = nil then
    Exit;
  
  LParamChildren := ACodeGenerator.GetNodeChildren(LParametersNode);
  if LParamChildren = nil then
    Exit;
  
  // Build parameter list
  for LI := 0 to LParamChildren.Count - 1 do
  begin
    LParamNode := LParamChildren.Items[LI] as TJSONObject;
    if ACodeGenerator.GetNodeType(LParamNode) <> 'PARAMETER' then
      Continue;
    
    // Get parameter kind (const, var, out, or empty)
    LKind := ACodeGenerator.GetNodeAttribute(LParamNode, 'kind');
    
    // Get NAME and TYPE children
    LNameNode := ACodeGenerator.FindNodeByType(ACodeGenerator.GetNodeChildren(LParamNode), 'NAME');
    LTypeNode := ACodeGenerator.FindNodeByType(ACodeGenerator.GetNodeChildren(LParamNode), 'TYPE');
    
    if (LNameNode = nil) or (LTypeNode = nil) then
      Continue;
    
    LName := ACodeGenerator.GetNodeAttribute(LNameNode, 'value');
    LType := ACodeGenerator.TranslateType(ACodeGenerator.GetNodeAttribute(LTypeNode, 'name'));
    
    // Build parameter with appropriate modifier
    if LKind = 'var' then
      LParam := Format('%s& %s', [LType, LName])
    else if LKind = 'out' then
      LParam := Format('%s& %s', [LType, LName])
    else if LKind = 'const' then
      LParam := Format('const %s %s', [LType, LName])
    else
      LParam := Format('%s %s', [LType, LName]);
    
    if Result <> '' then
      Result := Result + ', ';
    Result := Result + LParam;
  end;
end;

end.
