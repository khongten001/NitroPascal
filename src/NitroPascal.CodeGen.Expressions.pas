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
  NitroPascal.CodeGen;

{ Generate Expressions }

function GenerateExpression(const ACodeGenerator: TNPCodeGenerator; const AExprNode: TJSONObject): string;
function GenerateLiteral(const ACodeGenerator: TNPCodeGenerator; const ALiteralNode: TJSONObject): string;
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

function GenerateExpression(const ACodeGenerator: TNPCodeGenerator; const AExprNode: TJSONObject): string;
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
      Result := GenerateExpression(ACodeGenerator, LChildren.Items[0] as TJSONObject);
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
    Result := GenerateLiteral(ACodeGenerator, AExprNode)
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
    Result := GenerateBinaryOp(ACodeGenerator, AExprNode);
end;

function GenerateLiteral(const ACodeGenerator: TNPCodeGenerator; const ALiteralNode: TJSONObject): string;
var
  LValue: string;
  LLiteralType: string;
  LHexValue: string;
begin
  LValue := ACodeGenerator.GetNodeAttribute(ALiteralNode, 'value');
  LLiteralType := ACodeGenerator.GetNodeAttribute(ALiteralNode, 'literalType');
  
  // Use if..else if instead of case for string comparison
  if LLiteralType = 'string' then
  begin
    // ALL string literals use np::String, regardless of length
    // This ensures string concatenation works correctly (e.g., S1 + ' ' + S2)
    LValue := StringReplace(LValue, '\', '\\', [rfReplaceAll]);
    LValue := StringReplace(LValue, '"', '\"', [rfReplaceAll]);
    Result := 'np::String("' + LValue + '")';
  end
  else if (LLiteralType = 'integer') or (LLiteralType = 'float') or (LLiteralType = 'numeric') then
  begin
    // Handle hex literals: $FF → 0xFF
    if LValue.StartsWith('$') then
    begin
      LHexValue := LValue.Substring(1); // Remove $
      Result := '0x' + LHexValue;
    end
    else
      Result := LValue;
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
begin
  Result := '';
  
  LChildren := ACodeGenerator.GetNodeChildren(ACallNode);
  if LChildren = nil then
    Exit;
  
  LArgs := '';
  
  // First child is function name
  if LChildren.Count > 0 then
    LFuncName := ACodeGenerator.GetNodeAttribute(LChildren.Items[0] as TJSONObject, 'name');
  
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
          // Special handling for Format function with array literals
          // Format('fmt', ['arg1', 'arg2']) → np::Format(fmt, arg1, arg2)
          if SameText(LFuncName, 'Format') and (LI = 1) then
          begin
            // The second argument might be wrapped in EXPRESSION node
            LExprObj := LExpr as TJSONObject;
            LExprType := ACodeGenerator.GetNodeType(LExprObj);
            LActualNode := LExprObj;
            
            // Unwrap EXPRESSION wrapper if present
            if LExprType = 'EXPRESSION' then
            begin
              LExprNodeChildren := ACodeGenerator.GetNodeChildren(LExprObj);
              if (LExprNodeChildren <> nil) and (LExprNodeChildren.Count > 0) and 
                 (LExprNodeChildren.Items[0] is TJSONObject) then
              begin
                LActualNode := LExprNodeChildren.Items[0] as TJSONObject;
                LExprType := ACodeGenerator.GetNodeType(LActualNode);
              end;
            end;
            
            // Check if it's a SET (array literal)
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
          LExprStr := GenerateExpression(ACodeGenerator, LExpr as TJSONObject);
          if LArgs <> '' then
            LArgs := LArgs + ', ';
          LArgs := LArgs + LExprStr;
        end;
      end;
    end;
  end;
  
  // Check if it's an RTL function using centralized mapping
  LRTLName := NitroPascal.CodeGen.GetRTLFunctionName(LFuncName);
  
  // Return function call expression with np:: prefix for RTL functions
  if LRTLName <> '' then
    Result := Format('np::%s(%s)', [LRTLName, LArgs])
  else
    Result := Format('%s(%s)', [LFuncName, LArgs]);
end;

function GenerateDotExpression(const ACodeGenerator: TNPCodeGenerator; const ADotNode: TJSONObject): string;
var
  LChildren: TJSONArray;
  LLeft: string;
  LRight: string;
  LLeftNode: TJSONObject;
begin
  Result := '';
  LChildren := ACodeGenerator.GetNodeChildren(ADotNode);
  
  if (LChildren = nil) or (LChildren.Count < 2) then
    Exit;
  
  LLeftNode := LChildren.Items[0] as TJSONObject;
  
  // Enter DOT context to prevent WITH qualification of identifiers in DOT expressions
  ACodeGenerator.EnterDotContext();
  try
    // Check if left side is a DEREF - if so, use arrow operator
    if ACodeGenerator.GetNodeType(LLeftNode) = 'DEREF' then
    begin
      // ptr^.field → ptr->field
      LLeft := GenerateDereference(ACodeGenerator, LLeftNode);
      LRight := GenerateExpression(ACodeGenerator, LChildren.Items[1] as TJSONObject);
      Result := Format('%s->%s', [LLeft, LRight]);
    end
    else
    begin
      // normal.field → normal.field
      LLeft := GenerateExpression(ACodeGenerator, LLeftNode);
      LRight := GenerateExpression(ACodeGenerator, LChildren.Items[1] as TJSONObject);
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
    Result := '(*' + LExpr + ')';
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
