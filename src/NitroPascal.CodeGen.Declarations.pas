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
procedure GenerateFunctionDeclaration(const ACodeGenerator: TNPCodeGenerator; const AMethodNode: TJSONObject; const AUnitName: string = '');
procedure GenerateFunctionImplementation(const ACodeGenerator: TNPCodeGenerator; const AMethodNode: TJSONObject);
procedure GenerateFunctionImplementationWithExport(const ACodeGenerator: TNPCodeGenerator; const AMethodNode: TJSONObject; const AIsExported: Boolean);
function  GenerateParameterList(const ACodeGenerator: TNPCodeGenerator; const AMethodNode: TJSONObject): string;
function  HasForwardDirective(const ACodeGenerator: TNPCodeGenerator; const AMethodNode: TJSONObject): Boolean;
function  IsExternalFunction(const ACodeGenerator: TNPCodeGenerator; const AMethodNode: TJSONObject): Boolean;
procedure RegisterExternalFunctionInfo(const ACodeGenerator: TNPCodeGenerator; const AMethodNode: TJSONObject);
procedure EmitRegisteredExternalFunctions(const ACodeGenerator: TNPCodeGenerator);

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
procedure GenerateArrayTypeAlias(const ACodeGenerator: TNPCodeGenerator; const ATypeName: string; const ATypeNode: TJSONObject); forward;
procedure GenerateProceduralType(const ACodeGenerator: TNPCodeGenerator; const ATypeName: string; const ATypeNode: TJSONObject); forward;
function GetCallingConvention(const ACodeGenerator: TNPCodeGenerator; const AMethodNode: TJSONObject): string; forward;
function IsBuiltInType(const ACodeGenerator: TNPCodeGenerator; const ATypeName: string): Boolean; forward;

{------------------------------------------------------------------------------}
{ Forward Declaration Support }
{------------------------------------------------------------------------------}

function HasForwardDirective(const ACodeGenerator: TNPCodeGenerator; const AMethodNode: TJSONObject): Boolean;
var
  LDirective: string;
  LChildren: TJSONArray;
  LStatementsNode: TJSONObject;
begin
  // Check for 'forward' in directive attribute first
  LDirective := ACodeGenerator.GetNodeAttribute(AMethodNode, 'directive');
  if SameText(LDirective, 'forward') then
  begin
    Result := True;
    Exit;
  end;
  
  // Alternative: forward declarations have no STATEMENTS node (no body)
  LChildren := ACodeGenerator.GetNodeChildren(AMethodNode);
  if LChildren = nil then
  begin
    Result := False;
    Exit;
  end;
  
  LStatementsNode := ACodeGenerator.FindNodeByType(LChildren, 'STATEMENTS');
  Result := LStatementsNode = nil;
end;

{------------------------------------------------------------------------------}
{ External Function Support Helpers }
{------------------------------------------------------------------------------}

function MapToCType(const APasType: string): string;
var
  LBaseType: string;
begin
  // Map Pascal types to raw C types (not np:: types)
  // These are used ONLY for external function declarations
  // This ensures compatibility with any C library (Windows API, SDL3, etc.)
  if SameText(APasType, 'Integer') then
    Result := 'int'
  else if SameText(APasType, 'Cardinal') then
    Result := 'unsigned int'
  else if SameText(APasType, 'Int64') then
    Result := 'long long'
  else if SameText(APasType, 'Byte') then
    Result := 'unsigned char'
  else if SameText(APasType, 'Word') then
    Result := 'unsigned short'
  else if SameText(APasType, 'Boolean') then
    Result := 'bool'
  else if SameText(APasType, 'Char') then
    Result := 'wchar_t'
  else if SameText(APasType, 'AnsiChar') then
    Result := 'char'
  else if SameText(APasType, 'Double') then
    Result := 'double'
  else if SameText(APasType, 'Longint') then
    Result := 'long'
  else if SameText(APasType, 'Single') then
    Result := 'float'
  else if SameText(APasType, 'Pointer') then
    Result := 'void*'
  else if SameText(APasType, 'PChar') or SameText(APasType, 'PWideChar') then
    Result := 'wchar_t*'
  else if SameText(APasType, 'PAnsiChar') then
    Result := 'char*'
  else if (Length(APasType) > 1) and (APasType[1] = 'P') and (UpCase(APasType[2]) = APasType[2]) then
  begin
    // Handle P-prefixed pointer types: PInteger, PImage, PVector2, etc.
    // Extract base type (everything after 'P')
    LBaseType := Copy(APasType, 2, Length(APasType) - 1);
    // Recursively map the base type and add pointer
    Result := MapToCType(LBaseType) + '*';
  end
  else
    Result := APasType;  // Unknown type, use as-is
end;

procedure RegisterExternalFunctionInfo(const ACodeGenerator: TNPCodeGenerator; const AMethodNode: TJSONObject);
var
  LChildren: TJSONArray;
  LI: Integer;
  LChild: TJSONValue;
  LChildObj: TJSONObject;
  LNodeType: string;
  LMethodName: string;
  LCallingConv: string;
  LReturnType: string;
  LFuncInfo: TExternalFunctionInfo;
  LParamInfo: TExternalParamInfo;
  LParamList: TList<TExternalParamInfo>;
  LParametersNode: TJSONObject;
  LParamChildren: TJSONArray;
  LParamNode: TJSONObject;
  LNameNode: TJSONObject;
  LTypeNode: TJSONObject;
  LParamName: string;
  LParamPasType: string;
  LParamCppType: string;
  LKind: string;
begin
  LChildren := ACodeGenerator.GetNodeChildren(AMethodNode);
  if LChildren = nil then
    Exit;
  
  // Extract method information
  LMethodName := ACodeGenerator.GetNodeAttribute(AMethodNode, 'name');
  LCallingConv := GetCallingConvention(ACodeGenerator, AMethodNode);
  LReturnType := 'void';  // Default return type
  
  // Extract return type
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
        begin
          LParamPasType := ACodeGenerator.GetNodeAttribute(LChild as TJSONObject, 'name');
          LReturnType := MapToCType(LParamPasType);
        end;
      end;
      Break;
    end;
  end;
  
  // Build external function info for registration
  LFuncInfo.Name := LMethodName;
  LFuncInfo.CallingConvention := LCallingConv;
  LFuncInfo.ReturnType := LReturnType;
  LParamList := TList<TExternalParamInfo>.Create();
  try
    // Build parameter list with C type mapping
    LParametersNode := ACodeGenerator.FindNodeByType(LChildren, 'PARAMETERS');
    if LParametersNode <> nil then
    begin
      LParamChildren := ACodeGenerator.GetNodeChildren(LParametersNode);
      if LParamChildren <> nil then
      begin
        for LI := 0 to LParamChildren.Count - 1 do
        begin
          LParamNode := LParamChildren.Items[LI] as TJSONObject;
          if ACodeGenerator.GetNodeType(LParamNode) <> 'PARAMETER' then
            Continue;
          
          // Get NAME and TYPE children
          LNameNode := ACodeGenerator.FindNodeByType(ACodeGenerator.GetNodeChildren(LParamNode), 'NAME');
          LTypeNode := ACodeGenerator.FindNodeByType(ACodeGenerator.GetNodeChildren(LParamNode), 'TYPE');
          
          if (LNameNode = nil) or (LTypeNode = nil) then
            Continue;
          
          LParamName := ACodeGenerator.GetNodeAttribute(LNameNode, 'value');
          LParamPasType := ACodeGenerator.GetNodeAttribute(LTypeNode, 'name');
          
          // Get parameter kind (const, var, out, or empty)
          LKind := ACodeGenerator.GetNodeAttribute(LParamNode, 'kind');
          
          // Map to raw C types for external function parameters
          LParamCppType := MapToCType(LParamPasType);
          
          // Apply const modifier if needed - CRITICAL for matching C library signatures
          if LKind = 'const' then
          begin
            // Only add const if not already present (PAnsiChar/PChar already have const)
            if not LParamCppType.StartsWith('const ') then
            begin
              // const parameters: add const qualifier to the type
              if LParamCppType.Contains('*') then
                // For const pointer parameters: const Type* (pointer to const)
                LParamCppType := 'const ' + LParamCppType
              else
                // For const value parameters: const Type
                LParamCppType := 'const ' + LParamCppType;
            end;
          end;
          
          // Store parameter info for registration
          LParamInfo.Name := LParamName;
          LParamInfo.CppType := LParamCppType;
          LParamList.Add(LParamInfo);
        end;
      end;
    end;
    
    // Convert parameter list to array
    SetLength(LFuncInfo.Parameters, LParamList.Count);
    for LI := 0 to LParamList.Count - 1 do
      LFuncInfo.Parameters[LI] := LParamList[LI];
    
    // Register external function info
    ACodeGenerator.RegisterExternalFunction(LFuncInfo);
  finally
    LParamList.Free();
  end;
end;

function IsExternalFunction(const ACodeGenerator: TNPCodeGenerator; const AMethodNode: TJSONObject): Boolean;
var
  LChildren: TJSONArray;
  LI: Integer;
  LChild: TJSONValue;
  LChildObj: TJSONObject;
  LNodeType: string;
begin
  Result := False;
  LChildren := ACodeGenerator.GetNodeChildren(AMethodNode);
  if LChildren = nil then
    Exit;
  
  // Check if METHOD has an EXTERNAL child node
  for LI := 0 to LChildren.Count - 1 do
  begin
    LChild := LChildren.Items[LI];
    if not (LChild is TJSONObject) then
      Continue;
    
    LChildObj := LChild as TJSONObject;
    LNodeType := ACodeGenerator.GetNodeType(LChildObj);
    
    if LNodeType = 'EXTERNAL' then
    begin
      Result := True;
      Exit;
    end;
  end;
end;

function GetExternalLibrary(const ACodeGenerator: TNPCodeGenerator; const AMethodNode: TJSONObject): string;
var
  LChildren: TJSONArray;
  LI: Integer;
  LChild: TJSONValue;
  LChildObj: TJSONObject;
  LNodeType: string;
  LExternalChildren: TJSONArray;
  LLiteralNode: TJSONObject;
begin
  Result := '';
  LChildren := ACodeGenerator.GetNodeChildren(AMethodNode);
  if LChildren = nil then
    Exit;
  
  // Find EXTERNAL node
  for LI := 0 to LChildren.Count - 1 do
  begin
    LChild := LChildren.Items[LI];
    if not (LChild is TJSONObject) then
      Continue;
    
    LChildObj := LChild as TJSONObject;
    LNodeType := ACodeGenerator.GetNodeType(LChildObj);
    
    if LNodeType = 'EXTERNAL' then
    begin
      // Get children of EXTERNAL node
      LExternalChildren := ACodeGenerator.GetNodeChildren(LChildObj);
      if (LExternalChildren <> nil) and (LExternalChildren.Count > 0) then
      begin
        // First child should be LITERAL with library name
        LLiteralNode := LExternalChildren.Items[0] as TJSONObject;
        if ACodeGenerator.GetNodeType(LLiteralNode) = 'LITERAL' then
        begin
          Result := ACodeGenerator.GetNodeAttribute(LLiteralNode, 'value');
          Exit;
        end;
      end;
    end;
  end;
end;

function GetCallingConvention(const ACodeGenerator: TNPCodeGenerator; const AMethodNode: TJSONObject): string;
begin
  // Get calling convention from METHOD node attribute
  Result := ACodeGenerator.GetNodeAttribute(AMethodNode, 'callingconvention');
  // Default to cdecl if not specified
  if Result = '' then
    Result := 'cdecl';
end;

function IsBuiltInType(const ACodeGenerator: TNPCodeGenerator; const ATypeName: string): Boolean;
var
  LKey: string;
begin
  // Check if type exists in TypeMap using case-insensitive comparison
  // This ensures types like "string" (lowercase) match "String" (capitalized)
  for LKey in ACodeGenerator.TypeMap.Keys do
  begin
    if SameText(LKey, ATypeName) then
    begin
      Result := True;
      Exit;
    end;
  end;
  Result := False;
end;

function CallingConventionToCpp(const AConvention: string): string;
begin
  // Map Delphi calling convention to C++ attribute
  if SameText(AConvention, 'stdcall') then
    Result := '__stdcall'
  else if SameText(AConvention, 'cdecl') then
    Result := '__cdecl'
  else if SameText(AConvention, 'fastcall') then
    Result := '__fastcall'
  else
    Result := '__cdecl';  // Default
end;

procedure GenerateExternalFunctionDeclaration(const ACodeGenerator: TNPCodeGenerator; const AMethodNode: TJSONObject; const AUnitName: string);
var
  LChildren: TJSONArray;
  LI: Integer;
  LChild: TJSONValue;
  LChildObj: TJSONObject;
  LNodeType: string;
  LMethodName: string;
  LReturnType: string;
  LParameters: string;
  LCallingConv: string;
  LCppCallConv: string;
  LParametersNode: TJSONObject;
  LParamChildren: TJSONArray;
  LParamNode: TJSONObject;
  LNameNode: TJSONObject;
  LTypeNode: TJSONObject;
  LParamName: string;
  LParamPasType: string;
  LParamCppType: string;
  LParamStr: string;
  LKind: string;
  LFuncInfo: TExternalFunctionInfo;
  LParamInfo: TExternalParamInfo;
  LParamList: TList<TExternalParamInfo>;
begin
  LChildren := ACodeGenerator.GetNodeChildren(AMethodNode);
  if LChildren = nil then
    Exit;
  
  // Extract method information
  LMethodName := ACodeGenerator.GetNodeAttribute(AMethodNode, 'name');
  LReturnType := 'void';
  LParameters := '';
  LCallingConv := GetCallingConvention(ACodeGenerator, AMethodNode);
  LCppCallConv := CallingConventionToCpp(LCallingConv);
  
  // Build external function info for registration
  LFuncInfo.Name := LMethodName;
  LFuncInfo.CallingConvention := LCallingConv;
  LParamList := TList<TExternalParamInfo>.Create();
  try
    // Extract return type
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
          begin
            LParamPasType := ACodeGenerator.GetNodeAttribute(LChild as TJSONObject, 'name');
            LReturnType := MapToCType(LParamPasType);
          end;
        end;
      end;
    end;
    
    // Build parameter list with context-aware mapping
    LParametersNode := ACodeGenerator.FindNodeByType(LChildren, 'PARAMETERS');
    if LParametersNode <> nil then
    begin
      LParamChildren := ACodeGenerator.GetNodeChildren(LParametersNode);
      if LParamChildren <> nil then
      begin
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
          
          LParamName := ACodeGenerator.GetNodeAttribute(LNameNode, 'value');
          LParamPasType := ACodeGenerator.GetNodeAttribute(LTypeNode, 'name');
          
          // Map to raw C types for external function parameters
          LParamCppType := MapToCType(LParamPasType);
          
          // Build parameter string with appropriate modifier
          // CRITICAL: For external functions, match the C signature EXACTLY
          // Only add modifiers when explicitly specified in Pascal
          if LKind = 'var' then
            // var parameters become references
            LParamStr := Format('%s& %s', [LParamCppType, LParamName])
          else if LKind = 'out' then
            // out parameters become references
            LParamStr := Format('%s& %s', [LParamCppType, LParamName])
          else if LKind = 'const' then
          begin
            // const parameters: add const qualifier
            if LParamCppType.Contains('*') then
              // For const pointer parameters: const Type* (pointer to const)
              LParamStr := Format('const %s %s', [LParamCppType, LParamName])
            else
              // For const value parameters: const Type
              LParamStr := Format('const %s %s', [LParamCppType, LParamName]);
          end
          else
            // NO modifier in Pascal: generate parameter as-is (no const, no &)
            // This matches the C library signature exactly
            LParamStr := Format('%s %s', [LParamCppType, LParamName]);
          
          if LParameters <> '' then
            LParameters := LParameters + ', ';
          LParameters := LParameters + LParamStr;
          
          // Store parameter info for registration
          LParamInfo.Name := LParamName;
          LParamInfo.CppType := LParamCppType;
          LParamList.Add(LParamInfo);
        end;
      end;
    end;
    
    // Convert parameter list to array
    SetLength(LFuncInfo.Parameters, LParamList.Count);
    for LI := 0 to LParamList.Count - 1 do
      LFuncInfo.Parameters[LI] := LParamList[LI];
    
    // Register external function info
    ACodeGenerator.RegisterExternalFunction(LFuncInfo);
  finally
    LParamList.Free();
  end;
  
  // Generate extern "C" declaration for static library
  // Note: No __declspec(dllimport) - this is for static linking, not DLL imports
  // Note: No namespace wrapper here - unit namespace already wraps all declarations in header
  ACodeGenerator.EmitLine('extern "C" {', []);
  ACodeGenerator.IncIndent();
  ACodeGenerator.EmitLine('%s %s %s(%s);', 
    [LReturnType, LCppCallConv, LMethodName, LParameters]);
  ACodeGenerator.DecIndent();
  ACodeGenerator.EmitLine('}', []);
end;

procedure EmitRegisteredExternalFunctions(const ACodeGenerator: TNPCodeGenerator);
var
  LFuncInfo: TExternalFunctionInfo;
  LFuncName: string;
  LParameters: string;
  LI: Integer;
  LCppCallConv: string;
  LParamType: string;
begin
  // If this unit includes headers, those headers provide the declarations
  // Don't emit duplicate declarations
  if Length(ACodeGenerator.GetIncludeHeaders()) > 0 then
    Exit;

  // Emit all registered external functions OUTSIDE the namespace
  // This is called after the namespace closes in the header file
  
  // Check if we have any external functions to emit
  if (ACodeGenerator.ExternalFunctions = nil) or 
     (ACodeGenerator.ExternalFunctions.Count = 0) then
    Exit;
  
  ACodeGenerator.EmitLine('// External C function declarations (global namespace)', []);
  ACodeGenerator.EmitLine('extern "C" {', []);
  ACodeGenerator.IncIndent();
  
  // Emit external C declarations with original names
  for LFuncName in ACodeGenerator.ExternalFunctions.Keys do
  begin
    LFuncInfo := ACodeGenerator.GetExternalFunctionInfo(LFuncName);
    LCppCallConv := CallingConventionToCpp(LFuncInfo.CallingConvention);
    
    // Build parameter list with namespace-qualified types
    LParameters := '';
    for LI := 0 to High(LFuncInfo.Parameters) do
    begin
      if LParameters <> '' then
        LParameters := LParameters + ', ';
      
      // Qualify struct types with namespace
      LParamType := LFuncInfo.Parameters[LI].CppType;
      if (not LParamType.Contains('*')) and  // Not a pointer
         (not LParamType.Contains('int')) and  // Not a primitive
         (not LParamType.Contains('char')) and
         (not LParamType.Contains('bool')) and
         (not LParamType.Contains('float')) and
         (not LParamType.Contains('double')) and
         (not LParamType.Contains('void')) then
      begin
        // Check if this unit has included headers
        // If headers are included, types might be from those headers (global namespace)
        // so we should NOT namespace-qualify them
        if Length(ACodeGenerator.GetIncludeHeaders()) = 0 then
        begin
          // No included headers - this is likely a Pascal-defined struct
          // Qualify with namespace
          LParamType := ACodeGenerator.CurrentUnitName + '::' + LParamType;
        end;
        // else: Headers are included, leave type unqualified (assumes global namespace)
      end;
      
      // For external functions, emit parameters WITHOUT const qualifier
      // The registered info contains the raw C types without modifiers
      LParameters := LParameters + Format('%s %s', 
        [LParamType, LFuncInfo.Parameters[LI].Name]);
    end;
    
    // Emit external C function declaration with original name
    ACodeGenerator.EmitLine('%s %s %s(%s);', 
      [LFuncInfo.ReturnType, LCppCallConv, LFuncInfo.Name, LParameters]);
  end;
  
  ACodeGenerator.DecIndent();
  ACodeGenerator.EmitLine('}', []);
  ACodeGenerator.EmitLn();
  
  // Now bring these functions into the namespace with 'using' declarations
  ACodeGenerator.EmitLine('namespace %s {', [ACodeGenerator.CurrentUnitName]);
  ACodeGenerator.IncIndent();
  ACodeGenerator.EmitLine('// Bring external C functions into namespace', []);
  
  for LFuncName in ACodeGenerator.ExternalFunctions.Keys do
  begin
    ACodeGenerator.EmitLine('using ::%s;', [LFuncName]);
  end;
  
  ACodeGenerator.DecIndent();
  ACodeGenerator.EmitLine('} // namespace %s', [ACodeGenerator.CurrentUnitName]);
  ACodeGenerator.EmitLn();
end;

{------------------------------------------------------------------------------}
{ String Transformation Helper }
{------------------------------------------------------------------------------}

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

{------------------------------------------------------------------------------}
{ Variable Generation }
{------------------------------------------------------------------------------}

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
  LVarLine: Integer;
  LSourceFile: string;
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
    
    // Emit #line directive for variable declaration
    LVarLine := StrToIntDef(ACodeGenerator.GetNodeAttribute(LVarNode, 'line'), 0);
    LSourceFile := ACodeGenerator.CurrentUnitName + '.pas';
    if LVarLine > 0 then
      ACodeGenerator.EmitLineDirective(LSourceFile, LVarLine);
    
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
        
        // Get dimensions - if BOUNDS has no children, it's a DYNAMIC ARRAY
        LDimensions := ACodeGenerator.GetNodeChildren(LBoundsNode);
        if (LDimensions = nil) or (LDimensions.Count = 0) then
        begin
          // DYNAMIC ARRAY: array of T
          // Last child is element TYPE
          LElementTypeNode := LTypeChildren.Items[LTypeChildren.Count - 1] as TJSONObject;
          if ACodeGenerator.GetNodeType(LElementTypeNode) <> 'TYPE' then
            Continue;
          
          LElementType := ACodeGenerator.TranslateType(
            ACodeGenerator.GetNodeAttribute(LElementTypeNode, 'name'));
          
          // Emit: np::DynArray<T> varname;
          LVarType := Format('np::DynArray<%s>', [LElementType]);
          ACodeGenerator.VariableTypes.AddOrSetValue(LVarName, LVarType);
          ACodeGenerator.EmitLine('%s %s;', [LVarType, LVarName]);
          Continue;
        end;
        
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
      // Check if it's a set type
      else if LLiteralType = 'set' then
      begin
        // SET TYPE: set of T
        // Children are range expressions (e.g., 0..9 has two EXPRESSION nodes)
        // For now, we use Integer as the element type
        // TODO: Extract actual element type from range if needed
        
        LVarType := 'np::Set<np::Integer>';
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
      // Check if it's a file type
      else if SameText(LLiteralType, 'file') then
      begin
        // FILE TYPE: untyped file maps to np::BinaryFile
        LVarType := 'np::BinaryFile';
        ACodeGenerator.VariableTypes.AddOrSetValue(LVarName, LVarType);
        ACodeGenerator.EmitLine('%s %s;', [LVarType, LVarName]);
      end
      else
      begin
        // Named type (e.g., TPoint, PPoint, Integer) - use as-is, it's already declared
        LVarType := ACodeGenerator.GetNodeAttribute(LTypeNode, 'name');
        
        // Only call TranslateType if it's a built-in type that needs namespace qualification
        // For user-defined types (TPoint, PPoint), use them directly
        if IsBuiltInType(ACodeGenerator, LVarType) then
          LVarType := ACodeGenerator.TranslateType(LVarType);
        // else: use LVarType as-is (it's a user-defined type already declared)
        
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
        
        // Get dimensions - if BOUNDS has no children, it's a DYNAMIC ARRAY
        LDimensions := ACodeGenerator.GetNodeChildren(LBoundsNode);
        if (LDimensions = nil) or (LDimensions.Count = 0) then
        begin
          // DYNAMIC ARRAY: array of T
          LElementTypeNode := LTypeChildren.Items[LTypeChildren.Count - 1] as TJSONObject;
          if ACodeGenerator.GetNodeType(LElementTypeNode) <> 'TYPE' then
            Continue;
          
          LElementType := ACodeGenerator.TranslateType(
            ACodeGenerator.GetNodeAttribute(LElementTypeNode, 'name'));
          
          LVarType := Format('np::DynArray<%s>', [LElementType]);
          ACodeGenerator.EmitLine('extern %s %s;', [LVarType, LVarName]);
          Continue;
        end;
        
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
      // Check if it's a set type
      else if LLiteralType = 'set' then
      begin
        LVarType := 'np::Set<np::Integer>';
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
      // Check if it's a file type
      else if SameText(LLiteralType, 'file') then
      begin
        // FILE TYPE: untyped file maps to np::BinaryFile
        LVarType := 'np::BinaryFile';
        ACodeGenerator.EmitLine('extern %s %s;', [LVarType, LVarName]);
      end
      else
      begin
        // Named type (e.g., TPoint, PPoint, Integer) - use as-is, it's already declared
        LVarType := ACodeGenerator.GetNodeAttribute(LTypeNode, 'name');
        
        // Only call TranslateType if it's a built-in type that needs namespace qualification
        // For user-defined types (TPoint, PPoint), use them directly
        if IsBuiltInType(ACodeGenerator, LVarType) then
          LVarType := ACodeGenerator.TranslateType(LVarType);
        // else: use LVarType as-is (it's a user-defined type already declared)
        
        ACodeGenerator.EmitLine('extern %s %s;', [LVarType, LVarName]);
      end;
    end;
  end;
end;

{------------------------------------------------------------------------------}
{ Constant Generation }
{------------------------------------------------------------------------------}

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
  LConstLine: Integer;
  LSourceFile: string;
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
    
    // Emit #line directive for constant declaration
    LConstLine := StrToIntDef(ACodeGenerator.GetNodeAttribute(LConstNode, 'line'), 0);
    LSourceFile := ACodeGenerator.CurrentUnitName + '.pas';
    if LConstLine > 0 then
      ACodeGenerator.EmitLineDirective(LSourceFile, LConstLine);
    
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

{------------------------------------------------------------------------------}
{ Type Declaration Helpers }
{------------------------------------------------------------------------------}

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
  LTypeLine: Integer;
  LSourceFile: string;
begin
  // Emit #line directive for type alias declaration
  LTypeLine := StrToIntDef(ACodeGenerator.GetNodeAttribute(ATypeNode, 'line'), 0);
  LSourceFile := ACodeGenerator.CurrentUnitName + '.pas';
  if LTypeLine > 0 then
    ACodeGenerator.EmitLineDirective(LSourceFile, LTypeLine);
  
  LBaseType := ACodeGenerator.GetNodeAttribute(ATypeNode, 'name');
  LCppType := ACodeGenerator.TranslateType(LBaseType);
  ACodeGenerator.EmitLine('using %s = %s;', [ATypeName, LCppType]);
end;

procedure GenerateArrayTypeAlias(const ACodeGenerator: TNPCodeGenerator; const ATypeName: string; const ATypeNode: TJSONObject);
var
  LTypeChildren: TJSONArray;
  LBoundsNode: TJSONObject;
  LDimensions: TJSONArray;
  LDimNode: TJSONObject;
  LDimChildren: TJSONArray;
  LElementTypeNode: TJSONObject;
  LElementType: string;
  LLowExpr: string;
  LHighExpr: string;
  LLowVal: Integer;
  LHighVal: Integer;
  LSize: Integer;
  LCppType: string;
  LDimI: Integer;
  LTypeLine: Integer;
  LSourceFile: string;
begin
  // Emit #line directive for array type alias declaration
  LTypeLine := StrToIntDef(ACodeGenerator.GetNodeAttribute(ATypeNode, 'line'), 0);
  LSourceFile := ACodeGenerator.CurrentUnitName + '.pas';
  if LTypeLine > 0 then
    ACodeGenerator.EmitLineDirective(LSourceFile, LTypeLine);
  
  // Array type alias: TByteArray = array[0..99] of Byte
  // Translates to: using TByteArray = std::array<np::Byte, 100>;
  
  LTypeChildren := ACodeGenerator.GetNodeChildren(ATypeNode);
  if (LTypeChildren = nil) or (LTypeChildren.Count < 2) then
    Exit;
  
  // First child is BOUNDS
  LBoundsNode := ACodeGenerator.FindNodeByType(LTypeChildren, 'BOUNDS');
  if LBoundsNode = nil then
    Exit;
  
  // Last child is element TYPE
  LElementTypeNode := LTypeChildren.Items[LTypeChildren.Count - 1] as TJSONObject;
  if ACodeGenerator.GetNodeType(LElementTypeNode) <> 'TYPE' then
    Exit;
  
  LElementType := ACodeGenerator.TranslateType(
    ACodeGenerator.GetNodeAttribute(LElementTypeNode, 'name'));
  
  // Get dimensions
  LDimensions := ACodeGenerator.GetNodeChildren(LBoundsNode);
  if (LDimensions = nil) or (LDimensions.Count = 0) then
    Exit;
  
  // Build nested std::array type from innermost to outermost
  LCppType := LElementType;
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
    LCppType := Format('std::array<%s, %d>', [LCppType, LSize]);
  end;
  
  // Emit type alias
  ACodeGenerator.EmitLine('using %s = %s;', [ATypeName, LCppType]);
end;

{------------------------------------------------------------------------------}
{ Type Declaration Generation }
{------------------------------------------------------------------------------}

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
    // Check if it's a procedural type (function or procedure)
    else if (LTypeDef = 'function') or (LTypeDef = 'procedure') then
    begin
      GenerateProceduralType(ACodeGenerator, LTypeName, LTypeNode);
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
      else if LLiteralType = 'array' then
      begin
        // Array type alias: TByteArray = array[0..99] of Byte
        GenerateArrayTypeAlias(ACodeGenerator, LTypeName, LTypeNode);
      end
      else if (LTypeDef <> '') and (LLiteralType = '') then
      begin
        // Simple type alias: TMyInt = Integer
        GenerateSimpleTypeAlias(ACodeGenerator, LTypeName, LTypeNode);
      end;
      // Add more type kinds here as needed (class, etc.)
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
  LTypeLine: Integer;
  LSourceFile: string;
begin
  // Emit #line directive for enum type declaration
  LTypeLine := StrToIntDef(ACodeGenerator.GetNodeAttribute(ATypeNode, 'line'), 0);
  LSourceFile := ACodeGenerator.CurrentUnitName + '.pas';
  if LTypeLine > 0 then
    ACodeGenerator.EmitLineDirective(LSourceFile, LTypeLine);
  
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
  LTypeLine: Integer;
  LSourceFile: string;
begin
  // Emit #line directive for record type declaration
  LTypeLine := StrToIntDef(ACodeGenerator.GetNodeAttribute(ATypeNode, 'line'), 0);
  LSourceFile := ACodeGenerator.CurrentUnitName + '.pas';
  if LTypeLine > 0 then
    ACodeGenerator.EmitLineDirective(LSourceFile, LTypeLine);
  
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
        LFieldType := ACodeGenerator.GetNodeAttribute(LFieldTypeNode, 'name');
        
        // Only call TranslateType if it's a built-in type that needs namespace qualification
        // For user-defined types (TPoint, PPoint), use them directly
        if IsBuiltInType(ACodeGenerator, LFieldType) then
          LFieldType := ACodeGenerator.TranslateType(LFieldType);
        // else: use LFieldType as-is (it's a user-defined type already declared)
        
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
  LTypeLine: Integer;
  LSourceFile: string;
begin
  // Emit #line directive for pointer type declaration
  LTypeLine := StrToIntDef(ACodeGenerator.GetNodeAttribute(ATypeNode, 'line'), 0);
  LSourceFile := ACodeGenerator.CurrentUnitName + '.pas';
  if LTypeLine > 0 then
    ACodeGenerator.EmitLineDirective(LSourceFile, LTypeLine);
  
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

procedure GenerateProceduralType(const ACodeGenerator: TNPCodeGenerator; const ATypeName: string; const ATypeNode: TJSONObject);
var
  LChildren: TJSONArray;
  LParametersNode: TJSONObject;
  LReturnTypeNode: TJSONObject;
  LParamChildren: TJSONArray;
  LParamNode: TJSONObject;
  LTypeNode: TJSONObject;
  LI: Integer;
  LParamType: string;
  LParamTypes: TStringBuilder;
  LReturnType: string;
  LFunctionSignature: string;
  LKind: string;
  LTypeLine: Integer;
  LSourceFile: string;
begin
  // Emit #line directive for procedural type declaration
  LTypeLine := StrToIntDef(ACodeGenerator.GetNodeAttribute(ATypeNode, 'line'), 0);
  LSourceFile := ACodeGenerator.CurrentUnitName + '.pas';
  if LTypeLine > 0 then
    ACodeGenerator.EmitLineDirective(LSourceFile, LTypeLine);
  
  // Generate C++ function type using std::function<>
  // Pascal: TCallback = function(x: Integer): String;
  // C++:    using TCallback = std::function<np::String(np::Integer)>;
  
  LChildren := ACodeGenerator.GetNodeChildren(ATypeNode);
  if LChildren = nil then
    Exit;
  
  // Find PARAMETERS and RETURNTYPE nodes
  LParametersNode := ACodeGenerator.FindNodeByType(LChildren, 'PARAMETERS');
  LReturnTypeNode := ACodeGenerator.FindNodeByType(LChildren, 'RETURNTYPE');
  
  // Determine return type
  if LReturnTypeNode <> nil then
  begin
    // Function type - has return type
    if ACodeGenerator.GetNodeChildren(LReturnTypeNode).Count > 0 then
    begin
      LReturnType := ACodeGenerator.TranslateType(
        ACodeGenerator.GetNodeAttribute(
          ACodeGenerator.GetNodeChildren(LReturnTypeNode).Items[0] as TJSONObject, 'name'));
    end
    else
      LReturnType := 'void';
  end
  else
  begin
    // Procedure type - no return type
    LReturnType := 'void';
  end;
  
  // Build parameter type list
  LParamTypes := TStringBuilder.Create();
  try
    if LParametersNode <> nil then
    begin
      LParamChildren := ACodeGenerator.GetNodeChildren(LParametersNode);
      if LParamChildren <> nil then
      begin
        for LI := 0 to LParamChildren.Count - 1 do
        begin
          LParamNode := LParamChildren.Items[LI] as TJSONObject;
          if ACodeGenerator.GetNodeType(LParamNode) <> 'PARAMETER' then
            Continue;
          
          // Get parameter kind (const, var, out)
          LKind := ACodeGenerator.GetNodeAttribute(LParamNode, 'kind');
          
          // Get TYPE child
          LTypeNode := ACodeGenerator.FindNodeByType(
            ACodeGenerator.GetNodeChildren(LParamNode), 'TYPE');
          
          if LTypeNode = nil then
            Continue;
          
          LParamType := ACodeGenerator.TranslateType(
            ACodeGenerator.GetNodeAttribute(LTypeNode, 'name'));
          
          // Add reference modifier for var/out parameters
          if (LKind = 'var') or (LKind = 'out') then
            LParamType := LParamType + '&';
          
          if LParamTypes.Length > 0 then
            LParamTypes.Append(', ');
          LParamTypes.Append(LParamType);
        end;
      end;
    end;
    
    // Build final std::function signature
    if LParamTypes.Length > 0 then
      LFunctionSignature := Format('std::function<%s(%s)>', [LReturnType, LParamTypes.ToString()])
    else
      LFunctionSignature := Format('std::function<%s()>', [LReturnType]);
    
    // Emit type alias
    ACodeGenerator.EmitLine('using %s = %s;', [ATypeName, LFunctionSignature]);
  finally
    LParamTypes.Free();
  end;
end;

{------------------------------------------------------------------------------}
{ Function Declaration Generation }
{------------------------------------------------------------------------------}

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

procedure GenerateFunctionDeclaration(const ACodeGenerator: TNPCodeGenerator; const AMethodNode: TJSONObject; const AUnitName: string);
var
  LChildren: TJSONArray;
  LI: Integer;
  LChild: TJSONValue;
  LChildObj: TJSONObject;
  LNodeType: string;
  LMethodName: string;
  LReturnType: string;
  LParameters: string;
  LLibrary: string;
  LLibName: string;
  LStatementsNode: TJSONObject;
begin
  // Skip if this is an implementation of a forward-declared function
  LMethodName := ACodeGenerator.GetNodeAttribute(AMethodNode, 'name');
  LChildren := ACodeGenerator.GetNodeChildren(AMethodNode);
  
  if LChildren = nil then
    Exit;
  
  LStatementsNode := ACodeGenerator.FindNodeByType(LChildren, 'STATEMENTS');
  // If this has a body (implementation) AND was forward declared, skip
  if (LStatementsNode <> nil) and ACodeGenerator.IsForwardDeclared(LMethodName) then
    Exit;
  
  // Check if this is an external function
  if IsExternalFunction(ACodeGenerator, AMethodNode) then
  begin
    // Get library name to determine linking type
    LLibrary := GetExternalLibrary(ACodeGenerator, AMethodNode);
    
    if LLibrary <> '' then
    begin
      // DLL LINKING: external 'library.dll'
      // Don't generate declaration - linker will resolve at runtime
      // Just track the library for linking
      LLibName := ChangeFileExt(LLibrary, '');
      ACodeGenerator.AddExternalLibrary(LLibName);
      
      // Register external function info (needed for string conversions at call sites)
      RegisterExternalFunctionInfo(ACodeGenerator, AMethodNode);
      
      Exit;  // Skip declaration generation - DLL will provide
    end
    else
    begin
      // STATIC LINKING: external; (no library name)
      // Register external function info - declaration will be emitted outside namespace
      RegisterExternalFunctionInfo(ACodeGenerator, AMethodNode);
      Exit;  // Skip normal function processing - external declaration handled separately
    end;
  end;
  
  // Normal function declaration (existing code)
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
        begin
          LReturnType := ACodeGenerator.GetNodeAttribute(LChild as TJSONObject, 'name');
          
          // Only call TranslateType if it's a built-in type that needs namespace qualification
          // For user-defined types (TPoint, PPoint), use them directly
          if IsBuiltInType(ACodeGenerator, LReturnType) then
            LReturnType := ACodeGenerator.TranslateType(LReturnType);
          // else: use LReturnType as-is (it's a user-defined type already declared)
        end;
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
  LIsForward: Boolean;
begin
  // Skip implementation for external functions
  if IsExternalFunction(ACodeGenerator, AMethodNode) then
    Exit;
  
  // Get method name
  LMethodName := ACodeGenerator.GetNodeAttribute(AMethodNode, 'name');
  
  // Check if this is a forward declaration
  LIsForward := HasForwardDirective(ACodeGenerator, AMethodNode);
  
  if LIsForward then
  begin
    // For forward declarations: skip emission in .cpp (already in .h)
    // Track this function as forward declared
    ACodeGenerator.AddForwardDeclaration(LMethodName);
    Exit;
  end;
  
  // Normal function implementation
  LChildren := ACodeGenerator.GetNodeChildren(AMethodNode);
  if LChildren = nil then
    Exit;
  
  // Extract method information (LMethodName already obtained above)
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
        begin
          LReturnType := ACodeGenerator.GetNodeAttribute(LChild as TJSONObject, 'name');
          
          // Only call TranslateType if it's a built-in type that needs namespace qualification
          // For user-defined types (TPoint, PPoint), use them directly
          if IsBuiltInType(ACodeGenerator, LReturnType) then
            LReturnType := ACodeGenerator.TranslateType(LReturnType);
          // else: use LReturnType as-is (it's a user-defined type already declared)
        end;
      end;
    end
    else if LNodeType = 'STATEMENTS' then
      LStatementsNode := LChildObj;
  end;
  
  // Get parameter list
  LParameters := GenerateParameterList(ACodeGenerator, AMethodNode);
  
  // Set routine context for Exit support
  if LReturnType <> 'void' then
    ACodeGenerator.SetRoutineContext('FUNCTION', LReturnType)
  else
    ACodeGenerator.SetRoutineContext('PROCEDURE', '');
  try
    // Emit #line directive for function start
    var LMethodLine := StrToIntDef(ACodeGenerator.GetNodeAttribute(AMethodNode, 'line'), 0);
    var LSourceFile := ACodeGenerator.CurrentUnitName + '.pas';
    if LMethodLine > 0 then
      ACodeGenerator.EmitLineDirective(LSourceFile, LMethodLine);
    
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
  finally
    ACodeGenerator.ClearRoutineContext();
  end;
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
  LIsForward: Boolean;
begin
  // Skip forward declarations
  LMethodName := ACodeGenerator.GetNodeAttribute(AMethodNode, 'name');
  LIsForward := HasForwardDirective(ACodeGenerator, AMethodNode);
  
  if LIsForward then
  begin
    // For forward declarations: skip emission (already tracked)
    ACodeGenerator.AddForwardDeclaration(LMethodName);
    Exit;
  end;
  
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
        begin
          LReturnType := ACodeGenerator.GetNodeAttribute(LChild as TJSONObject, 'name');
          
          // Only call TranslateType if it's a built-in type that needs namespace qualification
          // For user-defined types (TPoint, PPoint), use them directly
          if IsBuiltInType(ACodeGenerator, LReturnType) then
            LReturnType := ACodeGenerator.TranslateType(LReturnType);
          // else: use LReturnType as-is (it's a user-defined type already declared)
        end;
      end;
    end
    else if LNodeType = 'STATEMENTS' then
      LStatementsNode := LChildObj;
  end;
  
  // Get parameter list
  LParameters := GenerateParameterList(ACodeGenerator, AMethodNode);
  
  // Set routine context for Exit support
  if LReturnType <> 'void' then
    ACodeGenerator.SetRoutineContext('FUNCTION', LReturnType)
  else
    ACodeGenerator.SetRoutineContext('PROCEDURE', '');
  try
    // Emit #line directive for function start
    var LMethodLine := StrToIntDef(ACodeGenerator.GetNodeAttribute(AMethodNode, 'line'), 0);
    var LSourceFile := ACodeGenerator.CurrentUnitName + '.pas';
    if LMethodLine > 0 then
      ACodeGenerator.EmitLineDirective(LSourceFile, LMethodLine);
    
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
  finally
    ACodeGenerator.ClearRoutineContext();
  end;
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
    LType := ACodeGenerator.GetNodeAttribute(LTypeNode, 'name');
    
    // Only call TranslateType if it's a built-in type that needs namespace qualification
    // For user-defined types (TPoint, PPoint), use them directly
    if IsBuiltInType(ACodeGenerator, LType) then
      LType := ACodeGenerator.TranslateType(LType);
    // else: use LType as-is (it's a user-defined type already declared)
    
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
