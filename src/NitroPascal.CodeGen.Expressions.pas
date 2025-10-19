{===============================================================================
  NitroPascal - Modern Pascal • C Performance

  Copyright © 2025-present tinyBigGAMES™ LLC
  All Rights Reserved.

  https://nitropascal.org

  See LICENSE for license information
===============================================================================}

unit NitroPascal.CodeGen.Expressions;

{$I NitroPascal.Defines.inc}

interface

uses
  System.JSON,
  NitroPascal.Errors,
  NitroPascal.CodeGen;

{ Generate Expressions }

function GenerateExpression(const ACodeGenerator: TNPCodeGenerator; const AExprNode: TJSONObject; const AExpectedType: string = ''): string;
function GenerateLiteral(const ACodeGenerator: TNPCodeGenerator; const ALiteralNode: TJSONObject; const AExpectedType: string = ''): string;
function GenerateIdentifier(const ACodeGenerator: TNPCodeGenerator; const AIdentNode: TJSONObject): string;
function GenerateBinaryOp(const ACodeGenerator: TNPCodeGenerator; const AOpNode: TJSONObject): string;
function GenerateCallExpression(const ACodeGenerator: TNPCodeGenerator; const ACallNode: TJSONObject): string;
function GenerateDotExpression(const ACodeGenerator: TNPCodeGenerator; const ADotNode: TJSONObject): string;
function GenerateDereference(const ACodeGenerator: TNPCodeGenerator; const ADerefNode: TJSONObject): string;
function GenerateIndexedExpression(const ACodeGenerator: TNPCodeGenerator; const AIndexedNode: TJSONObject): string;

implementation

uses
  System.SysUtils,
  System.Generics.Collections;

// Note: GetRTLFunctionName is now centralized in NitroPascal.CodeGen unit

function IsBuiltInTypeCast(const ATypeName: string): Boolean;
begin
  // Check if the name is a built-in type that requires np:: prefix
  Result := SameText(ATypeName, 'Integer') or
            SameText(ATypeName, 'Cardinal') or
            SameText(ATypeName, 'Int64') or
            SameText(ATypeName, 'Byte') or
            SameText(ATypeName, 'Word') or
            SameText(ATypeName, 'Single') or
            SameText(ATypeName, 'Double') or
            SameText(ATypeName, 'Char') or
            SameText(ATypeName, 'Boolean') or
            SameText(ATypeName, 'Pointer');
end;

function GenerateExpression(const ACodeGenerator: TNPCodeGenerator; const AExprNode: TJSONObject; const AExpectedType: string = ''): string;
var
  LNodeType: string;
  LChildren: TJSONArray;
  LChildExpr: string;
begin
  Result := '';
  
  LNodeType := ACodeGenerator.GetNodeType(AExprNode);
  
  // Handle EXPRESSION wrapper node - unwrap it
  if LNodeType = 'EXPRESSION' then
  begin
    LChildren := ACodeGenerator.GetNodeChildren(AExprNode);
    if (LChildren <> nil) and (LChildren.Count > 0) then
      Result := GenerateExpression(ACodeGenerator, LChildren.Items[0] as TJSONObject, AExpectedType);
    Exit;
  end;
  
  // Handle EXPRESSIONS wrapper (parenthesized expressions)
  // Only add parentheses if the child expression doesn't already have them
  if LNodeType = 'EXPRESSIONS' then
  begin
    LChildren := ACodeGenerator.GetNodeChildren(AExprNode);
    if (LChildren <> nil) and (LChildren.Count > 0) then
    begin
      LChildExpr := GenerateExpression(ACodeGenerator, LChildren.Items[0] as TJSONObject);
      // Only add parens if not already present
      if LChildExpr.StartsWith('(') and LChildExpr.EndsWith(')') then
        Result := LChildExpr
      else
        Result := '(' + LChildExpr + ')';
    end;
    Exit;
  end;
  
  // Use if..else if instead of case for string comparison
  if LNodeType = 'LITERAL' then
    Result := GenerateLiteral(ACodeGenerator, AExprNode, AExpectedType)
  else if LNodeType = 'IDENTIFIER' then
    Result := GenerateIdentifier(ACodeGenerator, AExprNode)
  else if LNodeType = 'CALL' then
    Result := GenerateCallExpression(ACodeGenerator, AExprNode)
  else if LNodeType = 'DOT' then
    Result := GenerateDotExpression(ACodeGenerator, AExprNode)
  else if LNodeType = 'DEREF' then
    Result := GenerateDereference(ACodeGenerator, AExprNode)
  else if LNodeType = 'INDEXED' then
    Result := GenerateIndexedExpression(ACodeGenerator, AExprNode)
  else if LNodeType = 'NOT' then
  begin
    // Handle unary NOT operator
    LChildren := ACodeGenerator.GetNodeChildren(AExprNode);
    if (LChildren <> nil) and (LChildren.Count > 0) then
      Result := '(!' + GenerateExpression(ACodeGenerator, LChildren.Items[0] as TJSONObject) + ')';
  end
  else if LNodeType = 'UNARYMINUS' then
  begin
    // Handle unary minus operator (-value)
    LChildren := ACodeGenerator.GetNodeChildren(AExprNode);
    if (LChildren <> nil) and (LChildren.Count > 0) then
      Result := '(-' + GenerateExpression(ACodeGenerator, LChildren.Items[0] as TJSONObject) + ')';
  end
  else if LNodeType = 'ADDR' then
  begin
    // Handle address-of operator (@variable)
    LChildren := ACodeGenerator.GetNodeChildren(AExprNode);
    if (LChildren <> nil) and (LChildren.Count > 0) then
      Result := '(&' + GenerateExpression(ACodeGenerator, LChildren.Items[0] as TJSONObject) + ')';
  end
  else if LNodeType = 'IN' then
  begin
    // Handle IN operator (set membership test)
    LChildren := ACodeGenerator.GetNodeChildren(AExprNode);
    if (LChildren <> nil) and (LChildren.Count >= 2) then
      Result := 'np::In(' + GenerateExpression(ACodeGenerator, LChildren.Items[0] as TJSONObject) + ', ' +
                GenerateExpression(ACodeGenerator, LChildren.Items[1] as TJSONObject) + ')';
  end
  else if (LNodeType = 'ADD') or (LNodeType = 'SUB') or (LNodeType = 'MUL') or 
          (LNodeType = 'DIV') or (LNodeType = 'FDIV') or (LNodeType = 'MOD') or (LNodeType = 'SHL') or 
          (LNodeType = 'SHR') or (LNodeType = 'GREATER') or (LNodeType = 'LOWER') or 
          (LNodeType = 'GREATEROREQUAL') or (LNodeType = 'GREATEREQUAL') or
          (LNodeType = 'LOWEROREQUAL') or (LNodeType = 'LOWEREQUAL') or
          (LNodeType = 'EQUAL') or (LNodeType = 'NOTEQUAL') or 
          (LNodeType = 'AND') or (LNodeType = 'OR') or (LNodeType = 'XOR') then
    Result := GenerateBinaryOp(ACodeGenerator, AExprNode)
  else
  begin
    // Unknown expression type - report error with full context
    ACodeGenerator.ErrorManager.AddError(
      NP_ERROR_INVALID,
      StrToIntDef(ACodeGenerator.GetNodeAttribute(AExprNode, 'line'), 0),
      StrToIntDef(ACodeGenerator.GetNodeAttribute(AExprNode, 'col'), 0),
      ACodeGenerator.CurrentUnitName,
      'Code generation not implemented for expression type: ' + LNodeType
    );
    Result := ''; // Return empty string on error
  end;
end;

function GenerateLiteral(const ACodeGenerator: TNPCodeGenerator; const ALiteralNode: TJSONObject; const AExpectedType: string = ''): string;
var
  LValue: string;
  LLiteralType: string;
  LHexValue: string;
  LCharValue: string;
begin
  LValue := ACodeGenerator.GetNodeAttribute(ALiteralNode, 'value');
  LLiteralType := ACodeGenerator.GetNodeAttribute(ALiteralNode, 'literalType');
  
  // Use if..else if instead of case for string comparison
  if LLiteralType = 'string' then
  begin
    // Check if this is a single-character string literal
    // Single-char literals should be generated as char literals (u'x') not np::String
    // Multi-char literals remain as np::String
    if LValue = '#0' then
    begin
      // Special case: #0 null character from parser
      Result := 'u''\0''';
    end
    else if LValue.Length = 1 then
    begin
      // Single character - generate as char literal: u'x'
      // Handle special escape sequences
      if LValue = '\' then
        LCharValue := '\\'
      else if LValue = '''' then
        LCharValue := '\'
      else if LValue = #0 then
        LCharValue := '\0'
      else
        LCharValue := LValue;
      Result := 'u''' + LCharValue + '''';
    end
    else
    begin
      // Multi-character string - use np::String
      // Escape backslashes and double quotes for C++ string literals
      LValue := StringReplace(LValue, '\', '\\', [rfReplaceAll]);
      LValue := StringReplace(LValue, '"', '\"', [rfReplaceAll]);
      Result := 'np::String("' + LValue + '")';
    end;
  end
  else if (LLiteralType = 'integer') or (LLiteralType = 'float') or (LLiteralType = 'numeric') then
  begin
    // Handle hex literals: $FF → 0xFF
    if LValue.StartsWith('$') then
    begin
      LHexValue := LValue.Substring(1); // Remove $
      Result := '0x' + LHexValue;
      // Add suffix for 64-bit types
      if AExpectedType = 'np::Int64' then
        Result := Result + 'LL'
      else if AExpectedType = 'uint64_t' then
        Result := Result + 'ULL';
    end
    else
    begin
      Result := LValue;
      // Add suffix for 64-bit integer literals
      if (LLiteralType = 'integer') then
      begin
        if AExpectedType = 'np::Int64' then
          Result := Result + 'LL'
        else if AExpectedType = 'uint64_t' then
          Result := Result + 'ULL';
      end;
    end;
  end
  else if LLiteralType = 'boolean' then
    Result := LowerCase(LValue)
  else if LLiteralType = 'nil' then
    Result := 'nullptr'
  else
    Result := LValue;
end;

function GenerateIdentifier(const ACodeGenerator: TNPCodeGenerator; const AIdentNode: TJSONObject): string;
var
  LName: string;
begin
  LName := ACodeGenerator.GetNodeAttribute(AIdentNode, 'name');
  
  // Convert Pascal boolean literals to C++ lowercase
  if SameText(LName, 'True') then
    Result := 'true'
  else if SameText(LName, 'False') then
    Result := 'false'
  else
  begin
    // Check if we're in a WITH context and should qualify the identifier
    // BUT: Don't qualify if we're inside a DOT expression (explicit path)
    if (ACodeGenerator.WithStack.Count > 0) and (not ACodeGenerator.IsInDotContext()) then
    begin
      // Qualify the identifier with the WITH context
      Result := ACodeGenerator.GetWithQualification(LName);
    end
    else
    begin
      // NOTE: Unit qualification removed - identifiers are only qualified via explicit
      // DOT expressions (e.g., raylib.RAYWHITE) or qualified calls (e.g., raylib.InitWindow()).
      // The 'unit' attribute from the parser was incorrectly marking local identifiers,
      // so we no longer use it for automatic namespace qualification.
      Result := LName;
    end;
  end;
end;

function GenerateBinaryOp(const ACodeGenerator: TNPCodeGenerator; const AOpNode: TJSONObject): string;
var
  LNodeType: string;
  LChildren: TJSONArray;
  LLeft: string;
  LRight: string;
begin
  LNodeType := ACodeGenerator.GetNodeType(AOpNode);
  LChildren := ACodeGenerator.GetNodeChildren(AOpNode);
  
  if (LChildren = nil) or (LChildren.Count < 2) then
  begin
    Result := '';
    Exit;
  end;
  
  // Generate left and right operands
  LLeft := GenerateExpression(ACodeGenerator, LChildren.Items[0] as TJSONObject);
  LRight := GenerateExpression(ACodeGenerator, LChildren.Items[1] as TJSONObject);
  
  // Use runtime wrappers for Delphi-specific operators (if..else if instead of case)
  if LNodeType = 'ADD' then
    Result := Format('(%s + %s)', [LLeft, LRight])
  else if LNodeType = 'SUB' then
    Result := Format('(%s - %s)', [LLeft, LRight])
  else if LNodeType = 'MUL' then
    Result := Format('(%s * %s)', [LLeft, LRight])
  else if LNodeType = 'DIV' then
    Result := Format('np::Div(%s, %s)', [LLeft, LRight])  // Integer division
  else if LNodeType = 'FDIV' then
    Result := Format('(%s / %s)', [LLeft, LRight])  // Float division
  else if LNodeType = 'MOD' then
    Result := Format('np::Mod(%s, %s)', [LLeft, LRight])
  else if LNodeType = 'SHL' then
    Result := Format('np::Shl(%s, %s)', [LLeft, LRight])
  else if LNodeType = 'SHR' then
    Result := Format('np::Shr(%s, %s)', [LLeft, LRight])
  else if LNodeType = 'GREATER' then
    Result := Format('(%s > %s)', [LLeft, LRight])
  else if LNodeType = 'LOWER' then
    Result := Format('(%s < %s)', [LLeft, LRight])
  else if (LNodeType = 'GREATEROREQUAL') or (LNodeType = 'GREATEREQUAL') then
    Result := Format('(%s >= %s)', [LLeft, LRight])
  else if (LNodeType = 'LOWEROREQUAL') or (LNodeType = 'LOWEREQUAL') then
    Result := Format('(%s <= %s)', [LLeft, LRight])
  else if LNodeType = 'EQUAL' then
    Result := Format('(%s == %s)', [LLeft, LRight])
  else if LNodeType = 'NOTEQUAL' then
    Result := Format('(%s != %s)', [LLeft, LRight])
  else if LNodeType = 'AND' then
  begin
    // Use && for boolean AND (when operands are comparisons), & for bitwise
    if (LLeft.Contains('==')) or (LLeft.Contains('>')) or (LLeft.Contains('<')) or
       (LLeft.Contains('!=')) or (LLeft.Contains('>=')) or (LLeft.Contains('<=')) then
      Result := Format('(%s && %s)', [LLeft, LRight])
    else
      Result := Format('(%s & %s)', [LLeft, LRight]);
  end
  else if LNodeType = 'OR' then
  begin
    // Use || for boolean OR (when operands are comparisons), | for bitwise
    if (LLeft.Contains('==')) or (LLeft.Contains('>')) or (LLeft.Contains('<')) or
       (LLeft.Contains('!=')) or (LLeft.Contains('>=')) or (LLeft.Contains('<=')) then
      Result := Format('(%s || %s)', [LLeft, LRight])
    else
      Result := Format('(%s | %s)', [LLeft, LRight]);
  end
  else if LNodeType = 'XOR' then
    Result := Format('(%s ^ %s)', [LLeft, LRight])
  else
    Result := Format('(%s ? %s)', [LLeft, LRight]);
end;

function GenerateCallExpression(const ACodeGenerator: TNPCodeGenerator; const ACallNode: TJSONObject): string;
var
  LChildren: TJSONArray;
  LFuncName: string;
  LRTLName: string;
  LArgs: string;
  LExpressionsNode: TJSONObject;
  LExprChildren: TJSONArray;
  LI: Integer;
  LJ: Integer;
  LExpr: TJSONValue;
  LElem: TJSONValue;
  LExprStr: string;
  LFirstArg: string;
  LArrayElements: TJSONArray;
  LElementChildren: TJSONArray;
  LExprObj: TJSONObject;
  LExprType: string;
  LActualNode: TJSONObject;
  LExprNodeChildren: TJSONArray;
  LDerefChildren: TJSONArray;
  LIsMemoryFunc: Boolean;
  LFuncNode: TJSONObject;
  LFuncNodeType: string;
  LDotChildren: TJSONArray;
  LUnitName: string;
  LIsQualifiedCall: Boolean;
  LFuncInfo: TExternalFunctionInfo;
  LParamType: string;
begin
  Result := '';
  
  LChildren := ACodeGenerator.GetNodeChildren(ACallNode);
  if LChildren = nil then
    Exit;
  
  LArgs := '';
  LIsQualifiedCall := False;
  
  // First child is function name or DOT expression (for qualified calls)
  if LChildren.Count > 0 then
  begin
    LFuncNode := LChildren.Items[0] as TJSONObject;
    LFuncNodeType := ACodeGenerator.GetNodeType(LFuncNode);
    
    // Check if this is a unit-qualified call (e.g., UnitName.FunctionName)
    if LFuncNodeType = 'DOT' then
    begin
      LDotChildren := ACodeGenerator.GetNodeChildren(LFuncNode);
      if (LDotChildren <> nil) and (LDotChildren.Count >= 2) then
      begin
        // Left side is the unit name, right side is the function name
        LUnitName := ACodeGenerator.GetNodeAttribute(LDotChildren.Items[0] as TJSONObject, 'name');
        LFuncName := ACodeGenerator.GetNodeAttribute(LDotChildren.Items[1] as TJSONObject, 'name');
        LIsQualifiedCall := True;
      end;
    end
    else
    begin
      // Regular unqualified call
      LFuncName := ACodeGenerator.GetNodeAttribute(LFuncNode, 'name');
    end;
  end;
  
  // Check if this is a memory management function that takes void* parameters
  LIsMemoryFunc := SameText(LFuncName, 'FillChar') or SameText(LFuncName, 'FillByte') or
                   SameText(LFuncName, 'FillWord') or SameText(LFuncName, 'FillDWord') or
                   SameText(LFuncName, 'Move') or SameText(LFuncName, 'AllocMem') or
                   SameText(LFuncName, 'GetMem') or SameText(LFuncName, 'ReallocMem') or
                   SameText(LFuncName, 'FreeMem');
  
  // Handle SizeOf specially - it's a C++ operator, not a function
  if SameText(LFuncName, 'SizeOf') then
  begin
    // Get first argument
    if LChildren.Count > 1 then
    begin
      LExpressionsNode := LChildren.Items[1] as TJSONObject;
      LExprChildren := ACodeGenerator.GetNodeChildren(LExpressionsNode);
      
      if (LExprChildren <> nil) and (LExprChildren.Count > 0) then
      begin
        LExpr := LExprChildren.Items[0];
        if LExpr is TJSONObject then
        begin
          LExprObj := LExpr as TJSONObject;
          LExprType := ACodeGenerator.GetNodeType(LExprObj);
          
          // Unwrap EXPRESSION wrapper if present
          if LExprType = 'EXPRESSION' then
          begin
            LExprNodeChildren := ACodeGenerator.GetNodeChildren(LExprObj);
            if (LExprNodeChildren <> nil) and (LExprNodeChildren.Count > 0) and 
               (LExprNodeChildren.Items[0] is TJSONObject) then
            begin
              LExprObj := LExprNodeChildren.Items[0] as TJSONObject;
              LExprType := ACodeGenerator.GetNodeType(LExprObj);
            end;
          end;
          
          // Check if it's an IDENTIFIER (could be a type name)
          if LExprType = 'IDENTIFIER' then
          begin
            LFirstArg := ACodeGenerator.GetNodeAttribute(LExprObj, 'name');
            // Try to translate as a type
            LFirstArg := ACodeGenerator.TranslateType(LFirstArg);
          end
          else
          begin
            // It's an expression
            LFirstArg := GenerateExpression(ACodeGenerator, LExprObj);
          end;
          Result := Format('sizeof(%s)', [LFirstArg]);
          Exit;
        end;
      end;
    end;
  end;
  
  // Second child is arguments
  if LChildren.Count > 1 then
  begin
    LExpressionsNode := LChildren.Items[1] as TJSONObject;
    LExprChildren := ACodeGenerator.GetNodeChildren(LExpressionsNode);
    
    if LExprChildren <> nil then
    begin
      for LI := 0 to LExprChildren.Count - 1 do
      begin
        LExpr := LExprChildren.Items[LI];
        if LExpr is TJSONObject then
        begin
          LExprObj := LExpr as TJSONObject;
          LExprType := ACodeGenerator.GetNodeType(LExprObj);
          LActualNode := LExprObj;
          
          // For memory functions: check if arg is DEREF (before unwrapping)
          // FillChar(ptr^, ...) should become FillChar(ptr, ...) not FillChar(*ptr, ...)
          if LIsMemoryFunc and ((LI = 0) or (SameText(LFuncName, 'Move') and (LI <= 1))) then
          begin
            if LExprType = 'DEREF' then
            begin
              // Pass pointer directly without dereferencing
              LDerefChildren := ACodeGenerator.GetNodeChildren(LExprObj);
              if (LDerefChildren <> nil) and (LDerefChildren.Count > 0) then
              begin
                LExprStr := GenerateExpression(ACodeGenerator, LDerefChildren.Items[0] as TJSONObject);
                if LArgs <> '' then
                  LArgs := LArgs + ', ';
                LArgs := LArgs + LExprStr;
                Continue;
              end;
            end;
          end;
          
          // Unwrap EXPRESSION wrapper if present
          if LExprType = 'EXPRESSION' then
          begin
            LExprNodeChildren := ACodeGenerator.GetNodeChildren(LExprObj);
            if (LExprNodeChildren <> nil) and (LExprNodeChildren.Count > 0) and 
               (LExprNodeChildren.Items[0] is TJSONObject) then
            begin
              LActualNode := LExprNodeChildren.Items[0] as TJSONObject;
              LExprType := ACodeGenerator.GetNodeType(LActualNode);
              
              // Check again after unwrapping for DEREF in memory functions
              if LIsMemoryFunc and ((LI = 0) or (SameText(LFuncName, 'Move') and (LI <= 1))) then
              begin
                if LExprType = 'DEREF' then
                begin
                  LDerefChildren := ACodeGenerator.GetNodeChildren(LActualNode);
                  if (LDerefChildren <> nil) and (LDerefChildren.Count > 0) then
                  begin
                    LExprStr := GenerateExpression(ACodeGenerator, LDerefChildren.Items[0] as TJSONObject);
                    if LArgs <> '' then
                      LArgs := LArgs + ', ';
                    LArgs := LArgs + LExprStr;
                    Continue;
                  end;
                end;
              end;
            end;
          end;
          
          // Special handling for StringOfChar function - first arg must be Char
          // StringOfChar('*', 5) → np::StringOfChar(u'*', 5)
          if SameText(LFuncName, 'StringOfChar') and (LI = 0) then
          begin
            // Check if it's a LITERAL after unwrapping
            if LExprType = 'LITERAL' then
            begin
              LFirstArg := ACodeGenerator.GetNodeAttribute(LActualNode, 'value');
              // If it's a single-character string literal, convert to char literal
              if LFirstArg.Length = 1 then
              begin
                // Escape special chars for C++ char literal
                if LFirstArg = '\' then
                  LExprStr := 'u''\\'''
                else if LFirstArg = '''' then
                  LExprStr := 'u''\'''''
                else
                  LExprStr := 'u''' + LFirstArg + '''';
                
                if LArgs <> '' then
                  LArgs := LArgs + ', ';
                LArgs := LArgs + LExprStr;
                Continue; // Skip normal processing for this argument
              end;
            end;
          end;
          
          // Special handling for Format function with array literals
          // Format('fmt', ['arg1', 'arg2']) → np::Format(fmt, arg1, arg2)
          if SameText(LFuncName, 'Format') and (LI = 1) then
          begin
            // Check if it's a SET (array literal) after unwrapping
            if LExprType = 'SET' then
            begin
              // This is the array parameter for Format - unwrap its elements
              LArrayElements := ACodeGenerator.GetNodeChildren(LActualNode);
              if LArrayElements <> nil then
              begin
                for LJ := 0 to LArrayElements.Count - 1 do
                begin
                  LElem := LArrayElements.Items[LJ];
                  if LElem is TJSONObject then
                  begin
                    // Each element is wrapped in an ELEMENT node
                    if ACodeGenerator.GetNodeType(LElem as TJSONObject) = 'ELEMENT' then
                    begin
                      LElementChildren := ACodeGenerator.GetNodeChildren(LElem as TJSONObject);
                      if (LElementChildren <> nil) and (LElementChildren.Count > 0) then
                      begin
                        // Get the expression inside the ELEMENT
                        LExprStr := GenerateExpression(ACodeGenerator, LElementChildren.Items[0] as TJSONObject);
                        if LArgs <> '' then
                          LArgs := LArgs + ', ';
                        LArgs := LArgs + LExprStr;
                      end;
                    end;
                  end;
                end;
              end;
              Continue; // Skip normal processing for this argument
            end;
          end;
          
          // Normal argument processing
          LExprStr := GenerateExpression(ACodeGenerator, LActualNode);
          
          // Check if this is an external function call needing string conversion
          // Use the actual function name (without unit prefix if qualified)
          if ACodeGenerator.IsExternalFunction(LFuncName) then
          begin
            LFuncInfo := ACodeGenerator.GetExternalFunctionInfo(LFuncName);

            // Check if this parameter expects const char* or const wchar_t* and argument is np::String
            if (LI < Length(LFuncInfo.Parameters)) then
            begin
              LParamType := LFuncInfo.Parameters[LI].CppType;

              // If parameter expects char* (with or without const) and argument is np::String, convert
              if ((LParamType = 'const char*') or (LParamType = 'char*')) and LExprStr.Contains('np::String(') then
              begin
                LExprStr := LExprStr + '.to_ansi()';
              end
              // If parameter expects wchar_t* (with or without const) and argument is np::String, convert
              else if ((LParamType = 'const wchar_t*') or (LParamType = 'wchar_t*')) and LExprStr.Contains('np::String(') then
              begin
                LExprStr := LExprStr + '.c_str_wide()';
              end;
            end;

          end;
          
          if LArgs <> '' then
            LArgs := LArgs + ', ';
          LArgs := LArgs + LExprStr;
        end;
      end;
    end;
  end;
  
  // Check if it's a built-in type cast (e.g., Integer(expr), Byte(expr))
  if IsBuiltInTypeCast(LFuncName) then
  begin
    // Special case: Pointer type cast with Integer arithmetic
    // Pointer(Integer(ptr) + offset) → static_cast<char*>(ptr) + offset
    if SameText(LFuncName, 'Pointer') and (LChildren.Count > 1) then
    begin
      LExpressionsNode := LChildren.Items[1] as TJSONObject;
      LExprChildren := ACodeGenerator.GetNodeChildren(LExpressionsNode);
      
      if (LExprChildren <> nil) and (LExprChildren.Count > 0) then
      begin
        LExprObj := LExprChildren.Items[0] as TJSONObject;
        LExprType := ACodeGenerator.GetNodeType(LExprObj);
        
        // Unwrap EXPRESSION wrapper if present
        if LExprType = 'EXPRESSION' then
        begin
          LExprNodeChildren := ACodeGenerator.GetNodeChildren(LExprObj);
          if (LExprNodeChildren <> nil) and (LExprNodeChildren.Count > 0) then
          begin
            LExprObj := LExprNodeChildren.Items[0] as TJSONObject;
            LExprType := ACodeGenerator.GetNodeType(LExprObj);
          end;
        end;
        
        // Check if argument is ADD (pointer arithmetic)
        if LExprType = 'ADD' then
        begin
          LArrayElements := ACodeGenerator.GetNodeChildren(LExprObj);
          if (LArrayElements <> nil) and (LArrayElements.Count >= 2) then
          begin
            // Check if left side is Integer(ptr) cast
            LActualNode := LArrayElements.Items[0] as TJSONObject;
            
            // Unwrap EXPRESSION if present
            if ACodeGenerator.GetNodeType(LActualNode) = 'EXPRESSION' then
            begin
              LElementChildren := ACodeGenerator.GetNodeChildren(LActualNode);
              if (LElementChildren <> nil) and (LElementChildren.Count > 0) then
                LActualNode := LElementChildren.Items[0] as TJSONObject;
            end;
            
            if (ACodeGenerator.GetNodeType(LActualNode) = 'CALL') then
            begin
              LElementChildren := ACodeGenerator.GetNodeChildren(LActualNode);
              if (LElementChildren <> nil) and (LElementChildren.Count > 0) then
              begin
                LFirstArg := ACodeGenerator.GetNodeAttribute(LElementChildren.Items[0] as TJSONObject, 'name');
                if SameText(LFirstArg, 'Integer') or SameText(LFirstArg, 'Cardinal') then
                begin
                  // This is the pattern: Pointer(Integer(ptr) + offset)
                  // Get the pointer and offset
                  if LElementChildren.Count > 1 then
                  begin
                    LExprNodeChildren := ACodeGenerator.GetNodeChildren(LElementChildren.Items[1] as TJSONObject);
                    if (LExprNodeChildren <> nil) and (LExprNodeChildren.Count > 0) then
                    begin
                      LExprStr := GenerateExpression(ACodeGenerator, LExprNodeChildren.Items[0] as TJSONObject);
                      
                      // Unwrap EXPRESSION from LExprStr if it's wrapped
                      LActualNode := LArrayElements.Items[1] as TJSONObject;
                      if ACodeGenerator.GetNodeType(LActualNode) = 'EXPRESSION' then
                      begin
                        LElementChildren := ACodeGenerator.GetNodeChildren(LActualNode);
                        if (LElementChildren <> nil) and (LElementChildren.Count > 0) then
                          LActualNode := LElementChildren.Items[0] as TJSONObject;
                      end;
                      
                      LFirstArg := GenerateExpression(ACodeGenerator, LActualNode);
                      
                      // Generate: static_cast<char*>(ptr) + offset
                      Result := Format('static_cast<char*>(%s) + %s', [LExprStr, LFirstArg]);
                      Exit;
                    end;
                  end;
                end;
              end;
            end;
          end;
        end;
      end;
    end;
    
    // Normal type cast: Integer(expr) → np::Integer(expr)
    Result := Format('np::%s(%s)', [LFuncName, LArgs]);
    Exit;
  end;
  
  // Check if it's an RTL function using centralized mapping
  LRTLName := NitroPascal.CodeGen.GetRTLFunctionName(LFuncName);
  
  // Return function call expression with np:: prefix for RTL functions
  if LRTLName <> '' then
    Result := Format('np::%s(%s)', [LRTLName, LArgs])
  else if LIsQualifiedCall then
    // For qualified calls, emit: UnitName::FunctionName(args)
    // This prevents name collisions when multiple units have same function names
    Result := Format('%s::%s(%s)', [LUnitName, LFuncName, LArgs])
  else
    Result := Format('%s(%s)', [LFuncName, LArgs]);
end;

function GenerateDotExpression(const ACodeGenerator: TNPCodeGenerator; const ADotNode: TJSONObject): string;
var
  LChildren: TJSONArray;
  LLeft: string;
  LRight: string;
  LLeftNode: TJSONObject;
  LLeftNodeType: string;
  LLeftName: string;
  LIsUnitAccess: Boolean;
begin
  Result := '';
  LChildren := ACodeGenerator.GetNodeChildren(ADotNode);
  
  if (LChildren = nil) or (LChildren.Count < 2) then
    Exit;
  
  LLeftNode := LChildren.Items[0] as TJSONObject;
  LLeftNodeType := ACodeGenerator.GetNodeType(LLeftNode);
  
  // Enter DOT context to prevent WITH qualification of identifiers in DOT expressions
  ACodeGenerator.EnterDotContext();
  try
    // Check if left side is a DEREF - if so, use arrow operator
    if LLeftNodeType = 'DEREF' then
    begin
      // ptr^.field → ptr->field
      LLeft := GenerateDereference(ACodeGenerator, LLeftNode);
      LRight := GenerateExpression(ACodeGenerator, LChildren.Items[1] as TJSONObject);
      Result := Format('%s->%s', [LLeft, LRight]);
    end
    else
    begin
      // Check if this is a unit/namespace access (raylib.CONSTANT) vs struct field access (myStruct.field)
      // If left side is a simple IDENTIFIER, check if it looks like a unit name
      LIsUnitAccess := False;
      if LLeftNodeType = 'IDENTIFIER' then
      begin
        LLeftName := ACodeGenerator.GetNodeAttribute(LLeftNode, 'name');
        // Heuristic: Unit names typically start with lowercase or are known units
        // For now, we'll use a simple rule: if it's used in a DOT context and starts with lowercase,
        // it's likely a unit/namespace. This covers cases like: raylib.CONSTANT, System.WriteLn
        // A more robust solution would be to track imported unit names.
        if (Length(LLeftName) > 0) and 
           ((LLeftName[1] >= 'a') and (LLeftName[1] <= 'z')) then
          LIsUnitAccess := True;
      end;
      
      LLeft := GenerateExpression(ACodeGenerator, LLeftNode);
      LRight := GenerateExpression(ACodeGenerator, LChildren.Items[1] as TJSONObject);
      
      // Use :: for unit/namespace access, . for field access
      if LIsUnitAccess then
        Result := Format('%s::%s', [LLeft, LRight])
      else
        Result := Format('%s.%s', [LLeft, LRight]);
    end;
  finally
    ACodeGenerator.ExitDotContext();
  end;
end;

function GenerateDereference(const ACodeGenerator: TNPCodeGenerator; const ADerefNode: TJSONObject): string;
var
  LChildren: TJSONArray;
  LExpr: string;
begin
  Result := '';
  LChildren := ACodeGenerator.GetNodeChildren(ADerefNode);
  
  if (LChildren = nil) or (LChildren.Count < 1) then
    Exit;
  
  LExpr := GenerateExpression(ACodeGenerator, LChildren.Items[0] as TJSONObject);
  
  // For DOT context: return just the pointer (DOT handler will use ->)
  // For other contexts (assignment, expressions): return *ptr
  if ACodeGenerator.IsInDotContext() then
    Result := LExpr
  else
  begin
    // Wrap complex expressions in parentheses before dereferencing
    // to ensure correct precedence: (*(expr)) instead of (*expr)
    if LExpr.Contains('+') or LExpr.Contains('-') or LExpr.Contains('static_cast') or LExpr.Contains('reinterpret_cast') then
      Result := '(*(' + LExpr + '))'
    else
      Result := '(*' + LExpr + ')';
  end;
end;

function GenerateIndexedExpression(const ACodeGenerator: TNPCodeGenerator; const AIndexedNode: TJSONObject): string;
var
  LChildren: TJSONArray;
  LI: Integer;
  LArrayName: string;
  LIndex: string;
  LIndexNode: TJSONObject;
begin
  Result := '';
  LChildren := ACodeGenerator.GetNodeChildren(AIndexedNode);
  
  if (LChildren = nil) or (LChildren.Count < 2) then
    Exit;
  
  // Last child is the array identifier
  LArrayName := GenerateExpression(ACodeGenerator, 
    LChildren.Items[LChildren.Count - 1] as TJSONObject);
  
  // Build multi-dimensional array access: arr[i][j][k]
  Result := LArrayName;
  
  // Process all index expressions (all children except the last one)
  for LI := 0 to LChildren.Count - 2 do
  begin
    LIndexNode := LChildren.Items[LI] as TJSONObject;
    LIndex := GenerateExpression(ACodeGenerator, LIndexNode);
    Result := Result + '[' + LIndex + ']';
  end;
end;

end.
