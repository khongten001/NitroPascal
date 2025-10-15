{===============================================================================
  NitroPascal - Modern Pascal • C Performance

  Copyright © 2025-present tinyBigGAMES™ LLC
  All Rights Reserved.

  https://nitropascal.org

  See LICENSE for license information
===============================================================================}

unit NitroPascal.CodeGen.Statements;

{$I NitroPascal.Defines.inc}

interface

uses
  System.JSON,
  NitroPascal.CodeGen;

{ Generate Statements }

procedure GenerateStatements(const ACodeGenerator: TNPCodeGenerator; const AStatementsNode: TJSONObject);
procedure GenerateStatement(const ACodeGenerator: TNPCodeGenerator; const ANode: TJSONObject);
procedure GenerateCall(const ACodeGenerator: TNPCodeGenerator; const ACallNode: TJSONObject);
procedure GenerateAssignment(const ACodeGenerator: TNPCodeGenerator; const AAssignNode: TJSONObject);
procedure GenerateIfStatement(const ACodeGenerator: TNPCodeGenerator; const AIfNode: TJSONObject);
procedure GenerateCaseStatement(const ACodeGenerator: TNPCodeGenerator; const ACaseNode: TJSONObject);
procedure GenerateForLoop(const ACodeGenerator: TNPCodeGenerator; const AForNode: TJSONObject);
procedure GenerateWhileLoop(const ACodeGenerator: TNPCodeGenerator; const AWhileNode: TJSONObject);
procedure GenerateRepeatLoop(const ACodeGenerator: TNPCodeGenerator; const ARepeatNode: TJSONObject);
procedure GenerateWithStatement(const ACodeGenerator: TNPCodeGenerator; const AWithNode: TJSONObject);
procedure GenerateTryStatement(const ACodeGenerator: TNPCodeGenerator; const ATryNode: TJSONObject);
function HasLoopControl(const ACodeGenerator: TNPCodeGenerator; const AStatementsNode: TJSONObject): Boolean;
function HasExit(const ACodeGenerator: TNPCodeGenerator; const AStatementsNode: TJSONObject): Boolean;

implementation

uses
  System.SysUtils,
  System.Generics.Collections,
  System.StrUtils,
  System.Classes,
  System.Math,
  NitroPascal.CodeGen.Expressions;

// Note: GetRTLFunctionName is now centralized in NitroPascal.CodeGen unit

function TransformStringToChar(const AStringExpr: string): string;
var
  LStartPos: Integer;
  LEndPos: Integer;
  LValue: string;
begin
  // Transform: np::String("A") → u'A'
  // Only convert if it's a single-character string literal
  
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
  
  // Only convert if single character (after escape sequences are considered)
  // For now, we'll be conservative and check raw length
  if Length(LValue) = 1 then
  begin
    // Convert to char literal: u'A'
    Result := Format('u''%s''', [LValue]);
  end
  else
  begin
    // Keep as string if multi-char
    Result := AStringExpr;
  end;
end;

procedure GenerateStatements(const ACodeGenerator: TNPCodeGenerator; const AStatementsNode: TJSONObject);
var
  LChildren: TJSONArray;
  LI: Integer;
  LChild: TJSONValue;
  LChildObj: TJSONObject;
begin
  LChildren := ACodeGenerator.GetNodeChildren(AStatementsNode);
  if LChildren = nil then
    Exit;
  
  for LI := 0 to LChildren.Count - 1 do
  begin
    LChild := LChildren.Items[LI];
    if not (LChild is TJSONObject) then
      Continue;
    
    LChildObj := LChild as TJSONObject;
    GenerateStatement(ACodeGenerator, LChildObj);
  end;
end;

procedure GenerateStatement(const ACodeGenerator: TNPCodeGenerator; const ANode: TJSONObject);
var
  LNodeType: string;
  LRoutineType: string;
  LChildren: TJSONArray;
  LExitValue: string;
begin
  LNodeType := ACodeGenerator.GetNodeType(ANode);
  
  // Use if..else if instead of case for string comparison
  if LNodeType = 'CALL' then
    GenerateCall(ACodeGenerator, ANode)
  else if LNodeType = 'ASSIGN' then
    GenerateAssignment(ACodeGenerator, ANode)
  else if LNodeType = 'IF' then
    GenerateIfStatement(ACodeGenerator, ANode)
  else if LNodeType = 'CASE' then
    GenerateCaseStatement(ACodeGenerator, ANode)
  else if LNodeType = 'FOR' then
    GenerateForLoop(ACodeGenerator, ANode)
  else if LNodeType = 'WHILE' then
    GenerateWhileLoop(ACodeGenerator, ANode)
  else if LNodeType = 'REPEAT' then
    GenerateRepeatLoop(ACodeGenerator, ANode)
  else if LNodeType = 'WITH' then
    GenerateWithStatement(ACodeGenerator, ANode)
  else if LNodeType = 'TRY' then
    GenerateTryStatement(ACodeGenerator, ANode)
  else if LNodeType = 'BREAK' then
  begin
    if ACodeGenerator.GetLoopDepth = 0 then
      raise Exception.Create('Break statement outside loop');
    ACodeGenerator.EmitLine('return np::LoopControl::Break;', []);
  end
  else if LNodeType = 'CONTINUE' then
  begin
    if ACodeGenerator.GetLoopDepth = 0 then
      raise Exception.Create('Continue statement outside loop');
    ACodeGenerator.EmitLine('return np::LoopControl::Continue;', []);
  end
  else if LNodeType = 'EXIT' then
  begin
    LRoutineType := ACodeGenerator.GetRoutineType();
    if LRoutineType = '' then
      raise Exception.Create('Exit statement outside function/procedure');
    
    // Check if we're inside a loop
    if ACodeGenerator.GetLoopDepth > 0 then
    begin
      // Inside loop - use flag approach
      LChildren := ACodeGenerator.GetNodeChildren(ANode);
      if (LChildren <> nil) and (LChildren.Count > 0) then
      begin
        // Exit(value)
        LExitValue := NitroPascal.CodeGen.Expressions.GenerateExpression(
          ACodeGenerator, LChildren.Items[0] as TJSONObject);
        ACodeGenerator.EmitLine('Result = %s;', [LExitValue]);
      end;
      ACodeGenerator.EmitLine('_exit_requested = true;', []);
      ACodeGenerator.EmitLine('return np::LoopControl::Break;', []);
    end
    else
    begin
      // Outside loop - normal return
      LChildren := ACodeGenerator.GetNodeChildren(ANode);
      if (LChildren <> nil) and (LChildren.Count > 0) then
      begin
        // Exit(value)
        LExitValue := NitroPascal.CodeGen.Expressions.GenerateExpression(
          ACodeGenerator, LChildren.Items[0] as TJSONObject);
        ACodeGenerator.EmitLine('Result = %s;', [LExitValue]);
        ACodeGenerator.EmitLine('return Result;', []);
      end
      else
      begin
        // Plain Exit
        if LRoutineType = 'FUNCTION' then
          ACodeGenerator.EmitLine('return Result;', [])
        else
          ACodeGenerator.EmitLine('return;', []);
      end;
    end;
  end;
end;

procedure GenerateExternalCallWithStringConversions(const ACodeGenerator: TNPCodeGenerator;
  const AFuncName: string; const AFuncInfo: TExternalFunctionInfo;
  const AArgExprs: TArray<string>);
var
  LI: Integer;
  LParamType: string;
  LArgExpr: string;
  LNeedsTempBlock: Boolean;
  LTempVars: TStringList;
  LConvertedArgs: TStringBuilder;
  LTempVarName: string;
begin
  // Determine if we need temp variables (ANSI strings)
  LNeedsTempBlock := False;
  for LI := 0 to Min(High(AArgExprs), High(AFuncInfo.Parameters)) do
  begin
    LParamType := AFuncInfo.Parameters[LI].CppType;
    LArgExpr := AArgExprs[LI];
    if (LParamType = 'const char*') and LArgExpr.Contains('np::String(') then
    begin
      LNeedsTempBlock := True;
      Break;
    end;
  end;
  
  if LNeedsTempBlock then
  begin
    // Generate block with temp variables for ANSI conversion
    ACodeGenerator.EmitLine('{', []);
    ACodeGenerator.IncIndent();
    
    LTempVars := TStringList.Create();
    LConvertedArgs := TStringBuilder.Create();
    try
      // Generate temp variables for string parameters
      for LI := 0 to Min(High(AArgExprs), High(AFuncInfo.Parameters)) do
      begin
        LParamType := AFuncInfo.Parameters[LI].CppType;
        LArgExpr := AArgExprs[LI];
        
        if (LParamType = 'const char*') and LArgExpr.Contains('np::String(') then
        begin
          // ANSI string - need temp variable
          LTempVarName := Format('_temp_str_%d', [LI]);
          ACodeGenerator.EmitLine('auto %s = %s.to_ansi();', [LTempVarName, LArgExpr]);
          LTempVars.Add(Format('%s.c_str()', [LTempVarName]));
        end
        else
          LTempVars.Add(LArgExpr);
      end;
      
      // Build converted args list
      for LI := 0 to LTempVars.Count - 1 do
      begin
        if LI > 0 then
          LConvertedArgs.Append(', ');
        LConvertedArgs.Append(LTempVars[LI]);
      end;
      
      // Emit function call
      ACodeGenerator.EmitLine('%s(%s);', [AFuncName, LConvertedArgs.ToString()]);
    finally
      LConvertedArgs.Free();
      LTempVars.Free();
    end;
    
    ACodeGenerator.DecIndent();
    ACodeGenerator.EmitLine('}', []);
  end
  else
  begin
    // No temp variables needed - direct call with .c_str_wide() for Unicode
    LConvertedArgs := TStringBuilder.Create();
    try
      for LI := 0 to High(AArgExprs) do
      begin
        if LI > 0 then
          LConvertedArgs.Append(', ');
        
        if LI <= High(AFuncInfo.Parameters) then
        begin
          LParamType := AFuncInfo.Parameters[LI].CppType;
          LArgExpr := AArgExprs[LI];
          
          if (LParamType = 'const wchar_t*') and LArgExpr.Contains('np::String(') then
            // Unicode string - convert with .c_str_wide()
            LConvertedArgs.AppendFormat('%s.c_str_wide()', [LArgExpr])
          else
            LConvertedArgs.Append(LArgExpr);
        end
        else
          LConvertedArgs.Append(AArgExprs[LI]);
      end;
      
      ACodeGenerator.EmitLine('%s(%s);', [AFuncName, LConvertedArgs.ToString()]);
    finally
      LConvertedArgs.Free();
    end;
  end;
end;

procedure GenerateCall(const ACodeGenerator: TNPCodeGenerator; const ACallNode: TJSONObject);
var
  LChildren: TJSONArray;
  LFuncName: string;
  LArgs: string;
  LExpressionsNode: TJSONObject;
  LExprChildren: TJSONArray;
  LI: Integer;
  LExpr: TJSONValue;
  LExprStr: string;
  LRTLName: string;
  LIsExternal: Boolean;
  LExternalInfo: TExternalFunctionInfo;
  LArgExprs: TArray<string>;
  LRoutineType: string;
  LExitValue: string;
begin
  LChildren := ACodeGenerator.GetNodeChildren(ACallNode);
  if LChildren = nil then
    Exit;
  
  LArgs := '';
  
  // First child is function name
  if LChildren.Count > 0 then
    LFuncName := ACodeGenerator.GetNodeAttribute(LChildren.Items[0] as TJSONObject, 'name');
  
  // ============================================================================
  // SPECIAL HANDLING FOR CONTROL FLOW STATEMENTS (break/continue/exit)
  // ============================================================================
  
  if SameText(LFuncName, 'break') then
  begin
    if ACodeGenerator.GetLoopDepth = 0 then
      raise Exception.Create('Break statement outside loop');
    ACodeGenerator.EmitLine('return np::LoopControl::Break;', []);
    Exit;
  end
  else if SameText(LFuncName, 'continue') then
  begin
    if ACodeGenerator.GetLoopDepth = 0 then
      raise Exception.Create('Continue statement outside loop');
    ACodeGenerator.EmitLine('return np::LoopControl::Continue;', []);
    Exit;
  end
  else if SameText(LFuncName, 'exit') then
  begin
    LRoutineType := ACodeGenerator.GetRoutineType();
    if LRoutineType = '' then
      raise Exception.Create('Exit statement outside function/procedure');
    
    // Check if we're inside a loop
    if ACodeGenerator.GetLoopDepth > 0 then
    begin
      // Inside loop - use flag approach
      if LChildren.Count > 1 then
      begin
        LExpressionsNode := LChildren.Items[1] as TJSONObject;
        LExprChildren := ACodeGenerator.GetNodeChildren(LExpressionsNode);
        
        if (LExprChildren <> nil) and (LExprChildren.Count > 0) then
        begin
          // Exit(value)
          LExitValue := NitroPascal.CodeGen.Expressions.GenerateExpression(
            ACodeGenerator, LExprChildren.Items[0] as TJSONObject);
          ACodeGenerator.EmitLine('Result = %s;', [LExitValue]);
        end;
      end;
      ACodeGenerator.EmitLine('_exit_requested = true;', []);
      ACodeGenerator.EmitLine('return np::LoopControl::Break;', []);
    end
    else
    begin
      // Outside loop - normal return
      if LChildren.Count > 1 then
      begin
        LExpressionsNode := LChildren.Items[1] as TJSONObject;
        LExprChildren := ACodeGenerator.GetNodeChildren(LExpressionsNode);
        
        if (LExprChildren <> nil) and (LExprChildren.Count > 0) then
        begin
          // Exit(value)
          LExitValue := NitroPascal.CodeGen.Expressions.GenerateExpression(
            ACodeGenerator, LExprChildren.Items[0] as TJSONObject);
          ACodeGenerator.EmitLine('Result = %s;', [LExitValue]);
          ACodeGenerator.EmitLine('return Result;', []);
        end
        else
        begin
          // Plain Exit
          if LRoutineType = 'FUNCTION' then
            ACodeGenerator.EmitLine('return Result;', [])
          else
            ACodeGenerator.EmitLine('return;', []);
        end;
      end
      else
      begin
        // Plain Exit (no arguments)
        if LRoutineType = 'FUNCTION' then
          ACodeGenerator.EmitLine('return Result;', [])
        else
          ACodeGenerator.EmitLine('return;', []);
      end;
    end;
    Exit;
  end;
  
  // ============================================================================
  // NORMAL FUNCTION CALL HANDLING
  // ============================================================================
  
  // Second child is arguments
  if LChildren.Count > 1 then
  begin
    LExpressionsNode := LChildren.Items[1] as TJSONObject;
    LExprChildren := ACodeGenerator.GetNodeChildren(LExpressionsNode);
    
    if LExprChildren <> nil then
    begin
      SetLength(LArgExprs, LExprChildren.Count);
      for LI := 0 to LExprChildren.Count - 1 do
      begin
        LExpr := LExprChildren.Items[LI];
        if LExpr is TJSONObject then
        begin
          LExprStr := NitroPascal.CodeGen.Expressions.GenerateExpression(ACodeGenerator, LExpr as TJSONObject);
          LArgExprs[LI] := LExprStr;
          if LArgs <> '' then
            LArgs := LArgs + ', ';
          LArgs := LArgs + LExprStr;
        end;
      end;
    end;
  end;
  
  // Check if external function
  LIsExternal := ACodeGenerator.IsExternalFunction(LFuncName);
  
  if LIsExternal then
  begin
    // External function - handle string conversions
    LExternalInfo := ACodeGenerator.GetExternalFunctionInfo(LFuncName);
    GenerateExternalCallWithStringConversions(ACodeGenerator, LFuncName, LExternalInfo, LArgExprs);
  end
  else
  begin
    // Map Delphi RTL functions (case-insensitive) to correct C++ RTL names
    LRTLName := NitroPascal.CodeGen.GetRTLFunctionName(LFuncName);
    
    if LRTLName <> '' then
      // It's an RTL function - use normalized name with np:: prefix
      ACodeGenerator.EmitLine('np::%s(%s);', [LRTLName, LArgs])
    else
      // User function - use original name without np:: prefix
      ACodeGenerator.EmitLine('%s(%s);', [LFuncName, LArgs]);
  end;
end;

procedure GenerateAssignment(const ACodeGenerator: TNPCodeGenerator; const AAssignNode: TJSONObject);
var
  LChildren: TJSONArray;
  LLhsNode: TJSONObject;
  LRhsNode: TJSONObject;
  LLhsChildren: TJSONArray;
  LRhsChildren: TJSONArray;
  LLhs: string;
  LRhs: string;
  LLhsType: string;
  LLhsIdentifier: string;
begin
  LChildren := ACodeGenerator.GetNodeChildren(AAssignNode);
  if LChildren = nil then
    Exit;
  
  // Find LHS and RHS nodes
  LLhsNode := ACodeGenerator.FindNodeByType(LChildren, 'LHS');
  LRhsNode := ACodeGenerator.FindNodeByType(LChildren, 'RHS');
  
  if (LLhsNode = nil) or (LRhsNode = nil) then
    Exit;
  
  // Get children of LHS (should be IDENTIFIER or expression)
  LLhsChildren := ACodeGenerator.GetNodeChildren(LLhsNode);
  if (LLhsChildren <> nil) and (LLhsChildren.Count > 0) then
  begin
    LLhs := NitroPascal.CodeGen.Expressions.GenerateExpression(ACodeGenerator, LLhsChildren.Items[0] as TJSONObject);
    
    // Try to extract the identifier name for type lookup
    // Handle simple identifiers (most common case)
    if ACodeGenerator.GetNodeType(LLhsChildren.Items[0] as TJSONObject) = 'IDENTIFIER' then
      LLhsIdentifier := ACodeGenerator.GetNodeAttribute(LLhsChildren.Items[0] as TJSONObject, 'name')
    else
      LLhsIdentifier := LLhs;  // Fallback: use full expression
  end;
  
  // Get children of RHS (should be EXPRESSION node)
  LRhsChildren := ACodeGenerator.GetNodeChildren(LRhsNode);
  if (LRhsChildren <> nil) and (LRhsChildren.Count > 0) then
    LRhs := NitroPascal.CodeGen.Expressions.GenerateExpression(ACodeGenerator, LRhsChildren.Items[0] as TJSONObject);
  
  // Get the type of the LHS variable
  LLhsType := ACodeGenerator.GetVariableType(LLhsIdentifier);
  
  // Check if we need special handling for Char assignment
  if (LLhsType = 'np::Char') and LRhs.Contains('np::String(') then
  begin
    // Transform: np::String("A") → u'A'
    LRhs := TransformStringToChar(LRhs);
  end;
  
  ACodeGenerator.EmitLine('%s = %s;', [LLhs, LRhs]);
end;

procedure GenerateIfStatement(const ACodeGenerator: TNPCodeGenerator; const AIfNode: TJSONObject);
var
  LChildren: TJSONArray;
  LCondition: string;
  LThenNode: TJSONObject;
  LElseNode: TJSONObject;
  LThenStatements: TJSONObject;
  LElseStatements: TJSONObject;
  LThenChildren: TJSONArray;
  LElseChildren: TJSONArray;
  LI: Integer;
  LJ: Integer;
begin
  LChildren := ACodeGenerator.GetNodeChildren(AIfNode);
  if LChildren = nil then
    Exit;
  
  // First child is condition
  if LChildren.Count > 0 then
    LCondition := NitroPascal.CodeGen.Expressions.GenerateExpression(ACodeGenerator, LChildren.Items[0] as TJSONObject);
  
  // Find THEN and ELSE nodes
  LThenNode := ACodeGenerator.FindNodeByType(LChildren, 'THEN');
  LElseNode := ACodeGenerator.FindNodeByType(LChildren, 'ELSE');
  
  // Add parentheses only if condition doesn't already have them
  if LCondition.StartsWith('(') and LCondition.EndsWith(')') then
    ACodeGenerator.EmitLine('if %s {', [LCondition])
  else
    ACodeGenerator.EmitLine('if (%s) {', [LCondition]);
  ACodeGenerator.IncIndent();
  
  if LThenNode <> nil then
  begin
    // Try to find STATEMENTS child (for begin..end blocks)
    LThenStatements := ACodeGenerator.FindNodeByType(ACodeGenerator.GetNodeChildren(LThenNode), 'STATEMENTS');
    if LThenStatements <> nil then
      GenerateStatements(ACodeGenerator, LThenStatements)
    else
    begin
      // No STATEMENTS node - process direct children as individual statements
      LThenChildren := ACodeGenerator.GetNodeChildren(LThenNode);
      if LThenChildren <> nil then
      begin
        for LI := 0 to LThenChildren.Count - 1 do
        begin
          if LThenChildren.Items[LI] is TJSONObject then
            GenerateStatement(ACodeGenerator, LThenChildren.Items[LI] as TJSONObject);
        end;
      end;
    end;
  end;
  
  ACodeGenerator.DecIndent();
  
  if LElseNode <> nil then
  begin
    ACodeGenerator.EmitLine('} else {', []);
    ACodeGenerator.IncIndent();
    // Try to find STATEMENTS child (for begin..end blocks)
    LElseStatements := ACodeGenerator.FindNodeByType(ACodeGenerator.GetNodeChildren(LElseNode), 'STATEMENTS');
    if LElseStatements <> nil then
      GenerateStatements(ACodeGenerator, LElseStatements)
    else
    begin
      // No STATEMENTS node - process direct children as individual statements
      LElseChildren := ACodeGenerator.GetNodeChildren(LElseNode);
      if LElseChildren <> nil then
      begin
        for LJ := 0 to LElseChildren.Count - 1 do
        begin
          if LElseChildren.Items[LJ] is TJSONObject then
            GenerateStatement(ACodeGenerator, LElseChildren.Items[LJ] as TJSONObject);
        end;
      end;
    end;
    ACodeGenerator.DecIndent();
  end;
  
  ACodeGenerator.EmitLine('}', []);
end;

procedure GenerateCaseStatement(const ACodeGenerator: TNPCodeGenerator; const ACaseNode: TJSONObject);
var
  LChildren: TJSONArray;
  LCondition: string;
  LI: Integer;
  LChild: TJSONValue;
  LChildObj: TJSONObject;
  LNodeType: string;
  LSelectorNode: TJSONObject;
  LLabelsNode: TJSONObject;
  LLabelChildren: TJSONArray;
  LJ: Integer;
  LLabelChild: TJSONValue;
  LLabelObj: TJSONObject;
  LLabelExpr: string;
  LStatements: TJSONArray;
  LStmtChild: TJSONValue;
  LElseNode: TJSONObject;
  LElseStatements: TJSONObject;
  LIsRange: Boolean;
  LRangeStart: string;
  LRangeEnd: string;
  LLabelExprs: TJSONArray;
  LStartVal: Integer;
  LEndVal: Integer;
  LK: Integer;
begin
  LChildren := ACodeGenerator.GetNodeChildren(ACaseNode);
  if LChildren = nil then
    Exit;
  
  // First child is condition expression
  if LChildren.Count > 0 then
    LCondition := NitroPascal.CodeGen.Expressions.GenerateExpression(ACodeGenerator, LChildren.Items[0] as TJSONObject);
  
  ACodeGenerator.EmitLine('switch (%s) {', [LCondition]);
  ACodeGenerator.IncIndent();
  
  // Process CASESELECTOR nodes
  for LI := 0 to LChildren.Count - 1 do
  begin
    LChild := LChildren.Items[LI];
    if not (LChild is TJSONObject) then
      Continue;
    
    LChildObj := LChild as TJSONObject;
    LNodeType := ACodeGenerator.GetNodeType(LChildObj);
    
    if LNodeType = 'CASESELECTOR' then
    begin
      LSelectorNode := LChildObj;
      LLabelsNode := ACodeGenerator.FindNodeByType(ACodeGenerator.GetNodeChildren(LSelectorNode), 'CASELABELS');
      
      if LLabelsNode <> nil then
      begin
        LLabelChildren := ACodeGenerator.GetNodeChildren(LLabelsNode);
        if LLabelChildren <> nil then
        begin
          // Emit case labels
          for LJ := 0 to LLabelChildren.Count - 1 do
          begin
            LLabelChild := LLabelChildren.Items[LJ];
            if not (LLabelChild is TJSONObject) then
              Continue;
            
            LLabelObj := LLabelChild as TJSONObject;
            if ACodeGenerator.GetNodeType(LLabelObj) <> 'CASELABEL' then
              Continue;
            
            // Check if it's a range (has isRange attribute)
            LIsRange := ACodeGenerator.GetNodeAttribute(LLabelObj, 'isRange') = 'true';
            
            if LIsRange then
            begin
              // Handle range: 4..10
              LLabelExprs := ACodeGenerator.GetNodeChildren(LLabelObj);
              if (LLabelExprs <> nil) and (LLabelExprs.Count >= 2) then
              begin
                LRangeStart := NitroPascal.CodeGen.Expressions.GenerateExpression(ACodeGenerator, LLabelExprs.Items[0] as TJSONObject);
                LRangeEnd := NitroPascal.CodeGen.Expressions.GenerateExpression(ACodeGenerator, LLabelExprs.Items[1] as TJSONObject);
                
                // Emit multiple case labels for range
                ACodeGenerator.EmitLine('// Range: %s..%s', [LRangeStart, LRangeEnd]);
                
                // For integer ranges, emit all values
                if TryStrToInt(LRangeStart, LStartVal) and TryStrToInt(LRangeEnd, LEndVal) then
                begin
                  for LK := LStartVal to LEndVal do
                    ACodeGenerator.EmitLine('case %d:', [LK]);
                end
                else
                begin
                  // Fallback for non-integer ranges
                  ACodeGenerator.EmitLine('case %s:', [LRangeStart]);
                end;
              end;
            end
            else
            begin
              // Single value
              LLabelExprs := ACodeGenerator.GetNodeChildren(LLabelObj);
              if (LLabelExprs <> nil) and (LLabelExprs.Count > 0) then
              begin
                LLabelExpr := NitroPascal.CodeGen.Expressions.GenerateExpression(ACodeGenerator, LLabelExprs.Items[0] as TJSONObject);
                ACodeGenerator.EmitLine('case %s:', [LLabelExpr]);
              end;
            end;
          end;
        end;
      end;
      
      // Find and emit statements for this case
      ACodeGenerator.IncIndent();
      LStatements := ACodeGenerator.GetNodeChildren(LSelectorNode);
      if LStatements <> nil then
      begin
        for LJ := 0 to LStatements.Count - 1 do
        begin
          LStmtChild := LStatements.Items[LJ];
          if (LStmtChild is TJSONObject) and 
             (ACodeGenerator.GetNodeType(LStmtChild as TJSONObject) <> 'CASELABELS') then
          begin
            GenerateStatement(ACodeGenerator, LStmtChild as TJSONObject);
          end;
        end;
      end;
      ACodeGenerator.EmitLine('break;', []);
      ACodeGenerator.DecIndent();
    end
    else if LNodeType = 'CASEELSE' then
    begin
      // Handle else clause
      ACodeGenerator.EmitLine('default:', []);
      ACodeGenerator.IncIndent();
      
      LElseNode := LChildObj;
      LElseStatements := ACodeGenerator.FindNodeByType(ACodeGenerator.GetNodeChildren(LElseNode), 'STATEMENTS');
      if LElseStatements <> nil then
        GenerateStatements(ACodeGenerator, LElseStatements);
      
      ACodeGenerator.EmitLine('break;', []);
      ACodeGenerator.DecIndent();
    end;
  end;
  
  ACodeGenerator.DecIndent();
  ACodeGenerator.EmitLine('}', []);
end;

procedure GenerateForLoop(const ACodeGenerator: TNPCodeGenerator; const AForNode: TJSONObject);
var
  LChildren: TJSONArray;
  LIteratorName: string;
  LStartExpr: string;
  LEndExpr: string;
  LStatementsNode: TJSONObject;
  LI: Integer;
  LChild: TJSONValue;
  LChildObj: TJSONObject;
  LNodeType: string;
  LIsDownto: Boolean;
  LHasControl: Boolean;
  LHasExit: Boolean;
  LRoutineType: string;
begin
  LChildren := ACodeGenerator.GetNodeChildren(AForNode);
  if LChildren = nil then
    Exit;
  
  LIteratorName := '';
  LStartExpr := '';
  LEndExpr := '';
  LStatementsNode := nil;
  LIsDownto := False;
  
  // Extract for loop components
  for LI := 0 to LChildren.Count - 1 do
  begin
    LChild := LChildren.Items[LI];
    if not (LChild is TJSONObject) then
      Continue;
    
    LChildObj := LChild as TJSONObject;
    LNodeType := ACodeGenerator.GetNodeType(LChildObj);
    
    if LNodeType = 'IDENTIFIER' then
      LIteratorName := ACodeGenerator.GetNodeAttribute(LChildObj, 'name')
    else if LNodeType = 'FROM' then
    begin
      if ACodeGenerator.GetNodeChildren(LChildObj).Count > 0 then
      begin
        LChild := ACodeGenerator.GetNodeChildren(LChildObj).Items[0];
        if LChild is TJSONObject then
          LStartExpr := NitroPascal.CodeGen.Expressions.GenerateExpression(ACodeGenerator, LChild as TJSONObject);
      end;
    end
    else if LNodeType = 'TO' then
    begin
      LIsDownto := False;
      if ACodeGenerator.GetNodeChildren(LChildObj).Count > 0 then
      begin
        LChild := ACodeGenerator.GetNodeChildren(LChildObj).Items[0];
        if LChild is TJSONObject then
          LEndExpr := NitroPascal.CodeGen.Expressions.GenerateExpression(ACodeGenerator, LChild as TJSONObject);
      end;
    end
    else if LNodeType = 'DOWNTO' then
    begin
      LIsDownto := True;
      if ACodeGenerator.GetNodeChildren(LChildObj).Count > 0 then
      begin
        LChild := ACodeGenerator.GetNodeChildren(LChildObj).Items[0];
        if LChild is TJSONObject then
          LEndExpr := NitroPascal.CodeGen.Expressions.GenerateExpression(ACodeGenerator, LChild as TJSONObject);
      end;
    end
    else if LNodeType = 'STATEMENTS' then
      LStatementsNode := LChildObj;
  end;
  
  // Check if loop body has Break/Continue
  LHasControl := HasLoopControl(ACodeGenerator, LStatementsNode);
  
  // Check if loop body has Exit
  LHasExit := HasExit(ACodeGenerator, LStatementsNode);
  
  // If has Exit, declare flag before loop
  if LHasExit then
    ACodeGenerator.EmitLine('bool _exit_requested = false;', []);
  
  // Track loop depth
  ACodeGenerator.EnterLoop();
  try
    // Emit runtime ForLoop or ForLoopDownto with lambda
    // Note: ALWAYS return LoopControl::Normal to ensure SFINAE picks correct overload
    // This prevents ambiguity between void and LoopControl overloads in runtime.h
    if LIsDownto then
      ACodeGenerator.EmitLine('np::ForLoopDownto(%s, %s, [&](np::Integer _loop_iter) {', [LStartExpr, LEndExpr])
    else
      ACodeGenerator.EmitLine('np::ForLoop(%s, %s, [&](np::Integer _loop_iter) {', [LStartExpr, LEndExpr]);
    
    ACodeGenerator.IncIndent();
    
    // Assign lambda parameter to outer loop variable
    ACodeGenerator.EmitLine('%s = _loop_iter;', [LIteratorName]);
    
    // Generate loop body
    if LStatementsNode <> nil then
      GenerateStatements(ACodeGenerator, LStatementsNode)
    else
    begin
      // No STATEMENTS node - process direct children as individual statements
      for LI := 0 to LChildren.Count - 1 do
      begin
        LChild := LChildren.Items[LI];
        if LChild is TJSONObject then
        begin
          LChildObj := LChild as TJSONObject;
          LNodeType := ACodeGenerator.GetNodeType(LChildObj);
          // Skip the FOR loop metadata nodes
          if (LNodeType <> 'IDENTIFIER') and 
             (LNodeType <> 'FROM') and 
             (LNodeType <> 'TO') and 
             (LNodeType <> 'DOWNTO') then
          begin
            GenerateStatement(ACodeGenerator, LChildObj);
          end;
        end;
      end;
    end;
    
    // Conditionally emit return based on loop control/exit
    // If loop has break/continue/exit, emit return to use LoopControl overload
    // Otherwise, omit return to use more efficient void overload
    if LHasControl or LHasExit then
      ACodeGenerator.EmitLine('return np::LoopControl::Normal;', []);
    
    ACodeGenerator.DecIndent();
    ACodeGenerator.EmitLine('});', []);
  finally
    ACodeGenerator.ExitLoop();
  end;
  
  // If has Exit, check flag after loop
  if LHasExit then
  begin
    LRoutineType := ACodeGenerator.GetRoutineType();
    ACodeGenerator.EmitLine('if (_exit_requested) {', []);
    ACodeGenerator.IncIndent();
    if LRoutineType = 'FUNCTION' then
      ACodeGenerator.EmitLine('return Result;', [])
    else
      ACodeGenerator.EmitLine('return;', []);
    ACodeGenerator.DecIndent();
    ACodeGenerator.EmitLine('}', []);
  end;
end;

procedure GenerateWhileLoop(const ACodeGenerator: TNPCodeGenerator; const AWhileNode: TJSONObject);
var
  LChildren: TJSONArray;
  LCondition: string;
  LStatementsNode: TJSONObject;
  LHasControl: Boolean;
  LHasExit: Boolean;
  LRoutineType: string;
begin
  LChildren := ACodeGenerator.GetNodeChildren(AWhileNode);
  if LChildren = nil then
    Exit;
  
  // First child is condition, second is statements
  if LChildren.Count > 0 then
    LCondition := NitroPascal.CodeGen.Expressions.GenerateExpression(ACodeGenerator, LChildren.Items[0] as TJSONObject);
  
  if LChildren.Count > 1 then
    LStatementsNode := LChildren.Items[1] as TJSONObject
  else
    LStatementsNode := nil;
  
  // Check if loop body has Break/Continue
  LHasControl := HasLoopControl(ACodeGenerator, LStatementsNode);
  
  // Check if loop body has Exit
  LHasExit := HasExit(ACodeGenerator, LStatementsNode);
  
  // If has Exit, declare flag before loop
  if LHasExit then
    ACodeGenerator.EmitLine('bool _exit_requested = false;', []);
  
  // Track loop depth
  ACodeGenerator.EnterLoop();
  try
    // Emit runtime WhileLoop with lambdas
    // Note: ALWAYS return LoopControl::Normal to ensure correct overload selection
    ACodeGenerator.EmitLine('np::WhileLoop([&]() { return %s; }, [&]() {', [LCondition]);
    
    ACodeGenerator.IncIndent();
    
    if LStatementsNode <> nil then
      GenerateStatements(ACodeGenerator, LStatementsNode);
    
    // Conditionally emit return based on loop control/exit
    // If loop has break/continue/exit, emit return to use LoopControl overload
    // Otherwise, omit return to use more efficient void overload
    if LHasControl or LHasExit then
      ACodeGenerator.EmitLine('return np::LoopControl::Normal;', []);
    
    ACodeGenerator.DecIndent();
    ACodeGenerator.EmitLine('});', []);
  finally
    ACodeGenerator.ExitLoop();
  end;
  
  // If has Exit, check flag after loop
  if LHasExit then
  begin
    LRoutineType := ACodeGenerator.GetRoutineType();
    ACodeGenerator.EmitLine('if (_exit_requested) {', []);
    ACodeGenerator.IncIndent();
    if LRoutineType = 'FUNCTION' then
      ACodeGenerator.EmitLine('return Result;', [])
    else
      ACodeGenerator.EmitLine('return;', []);
    ACodeGenerator.DecIndent();
    ACodeGenerator.EmitLine('}', []);
  end;
end;

procedure GenerateRepeatLoop(const ACodeGenerator: TNPCodeGenerator; const ARepeatNode: TJSONObject);
var
  LChildren: TJSONArray;
  LStatementsNode: TJSONObject;
  LConditionNode: TJSONObject;
  LConditionChildren: TJSONArray;
  LCondition: string;
  LHasControl: Boolean;
  LHasExit: Boolean;
  LRoutineType: string;
begin
  LChildren := ACodeGenerator.GetNodeChildren(ARepeatNode);
  if LChildren = nil then
    Exit;
  
  // First child is STATEMENTS, second is condition EXPRESSION
  if LChildren.Count >= 2 then
  begin
    LStatementsNode := LChildren.Items[0] as TJSONObject;
    LConditionNode := LChildren.Items[1] as TJSONObject;
    
    // The condition is wrapped in an EXPRESSION node - get its child
    LConditionChildren := ACodeGenerator.GetNodeChildren(LConditionNode);
    if (LConditionChildren <> nil) and (LConditionChildren.Count > 0) then
    begin
      LCondition := NitroPascal.CodeGen.Expressions.GenerateExpression(
        ACodeGenerator,
        LConditionChildren.Items[0] as TJSONObject);
    end
    else
      Exit;
  end
  else
    Exit;
  
  // Check if loop body has Break/Continue
  LHasControl := HasLoopControl(ACodeGenerator, LStatementsNode);
  
  // Check if loop body has Exit
  LHasExit := HasExit(ACodeGenerator, LStatementsNode);
  
  // If has Exit, declare flag before loop
  if LHasExit then
    ACodeGenerator.EmitLine('bool _exit_requested = false;', []);
  
  // Track loop depth
  ACodeGenerator.EnterLoop();
  try
    // Emit runtime RepeatUntil with lambdas
    // Note: ALWAYS return LoopControl::Normal to ensure correct overload selection
    ACodeGenerator.EmitLine('np::RepeatUntil([&]() {', []);
    
    ACodeGenerator.IncIndent();
    
    if LStatementsNode <> nil then
      GenerateStatements(ACodeGenerator, LStatementsNode);
    
    // Conditionally emit return based on loop control/exit
    // If loop has break/continue/exit, emit return to use LoopControl overload
    // Otherwise, omit return to use more efficient void overload
    if LHasControl or LHasExit then
      ACodeGenerator.EmitLine('return np::LoopControl::Normal;', []);
    
    ACodeGenerator.DecIndent();
    ACodeGenerator.EmitLine('}, [&]() { return %s; });', [LCondition]);
  finally
    ACodeGenerator.ExitLoop();
  end;
  
  // If has Exit, check flag after loop
  if LHasExit then
  begin
    LRoutineType := ACodeGenerator.GetRoutineType();
    ACodeGenerator.EmitLine('if (_exit_requested) {', []);
    ACodeGenerator.IncIndent();
    if LRoutineType = 'FUNCTION' then
      ACodeGenerator.EmitLine('return Result;', [])
    else
      ACodeGenerator.EmitLine('return;', []);
    ACodeGenerator.DecIndent();
    ACodeGenerator.EmitLine('}', []);
  end;
end;

procedure GenerateWithStatement(const ACodeGenerator: TNPCodeGenerator; const AWithNode: TJSONObject);
var
  LChildren: TJSONArray;
  LExpressionsNode: TJSONObject;
  LExprChildren: TJSONArray;
  LWithExpr: string;
  LStatementsNode: TJSONObject;
  LStmtChild: TJSONValue;
begin
  LChildren := ACodeGenerator.GetNodeChildren(AWithNode);
  if LChildren = nil then
    Exit;
  
  // First child is EXPRESSIONS node containing the WITH expression(s)
  LExpressionsNode := ACodeGenerator.FindNodeByType(LChildren, 'EXPRESSIONS');
  if LExpressionsNode = nil then
    Exit;
  
  LExprChildren := ACodeGenerator.GetNodeChildren(LExpressionsNode);
  if (LExprChildren = nil) or (LExprChildren.Count = 0) then
    Exit;
  
  // For now, handle single WITH expression
  LWithExpr := NitroPascal.CodeGen.Expressions.GenerateExpression(
    ACodeGenerator,
    LExprChildren.Items[0] as TJSONObject);
  
  // Push WITH context
  ACodeGenerator.PushWithContext(LWithExpr);
  
  // Generate C++ scope
  ACodeGenerator.EmitLine('{', []);
  ACodeGenerator.IncIndent();
  ACodeGenerator.EmitLine('// with %s do', [LWithExpr]);
  
  // Find and generate statements
  LStatementsNode := ACodeGenerator.FindNodeByType(LChildren, 'STATEMENTS');
  if LStatementsNode <> nil then
  begin
    GenerateStatements(ACodeGenerator, LStatementsNode);
  end
  else
  begin
    // Check if there's a direct statement child
    if LChildren.Count > 1 then
    begin
      LStmtChild := LChildren.Items[1];
      if (LStmtChild is TJSONObject) and
         (ACodeGenerator.GetNodeType(LStmtChild as TJSONObject) <> 'EXPRESSIONS') then
      begin
        GenerateStatement(ACodeGenerator, LStmtChild as TJSONObject);
      end;
    end;
  end;
  
  // Pop WITH context
  ACodeGenerator.PopWithContext();
  
  ACodeGenerator.DecIndent();
  ACodeGenerator.EmitLine('}', []);
end;

procedure GenerateTryStatement(const ACodeGenerator: TNPCodeGenerator; const ATryNode: TJSONObject);
var
  LChildren: TJSONArray;
  LTryStatements: TJSONObject;
  LExceptNode: TJSONObject;
  LFinallyNode: TJSONObject;
  LExceptStatements: TJSONObject;
  LFinallyStatements: TJSONObject;
begin
  LChildren := ACodeGenerator.GetNodeChildren(ATryNode);
  if LChildren = nil then
    Exit;
  
  // First child is the try block STATEMENTS
  if LChildren.Count = 0 then
    Exit;
  
  LTryStatements := LChildren.Items[0] as TJSONObject;
  
  // Second child is either EXCEPT or FINALLY
  if LChildren.Count < 2 then
    Exit;
  
  LExceptNode := ACodeGenerator.FindNodeByType(LChildren, 'EXCEPT');
  LFinallyNode := ACodeGenerator.FindNodeByType(LChildren, 'FINALLY');
  
  if LExceptNode <> nil then
  begin
    // Generate try...except
    ACodeGenerator.EmitLine('try {', []);
    ACodeGenerator.IncIndent();
    
    // Generate try block statements
    if ACodeGenerator.GetNodeType(LTryStatements) = 'STATEMENTS' then
      GenerateStatements(ACodeGenerator, LTryStatements);
    
    ACodeGenerator.DecIndent();
    ACodeGenerator.EmitLine('} catch (const np::Exception& e) {', []);
    ACodeGenerator.IncIndent();
    
    // Set the current exception message so GetExceptionMessage() works
    ACodeGenerator.EmitLine('np::_current_exception_message = e.Message;', []);
    
    // Generate except block statements
    LExceptStatements := ACodeGenerator.FindNodeByType(
      ACodeGenerator.GetNodeChildren(LExceptNode), 'STATEMENTS');
    
    if LExceptStatements <> nil then
      GenerateStatements(ACodeGenerator, LExceptStatements)
    else
    begin
      // No STATEMENTS child - check direct children of EXCEPT node
      LChildren := ACodeGenerator.GetNodeChildren(LExceptNode);
      if LChildren <> nil then
        GenerateStatements(ACodeGenerator, LExceptNode);
    end;
    
    ACodeGenerator.DecIndent();
    ACodeGenerator.EmitLine('}', []);
  end
  else if LFinallyNode <> nil then
  begin
    // Generate try...finally
    // In C++, finally is implemented as:
    // 1. try { } catch (...) { finally_code; throw; }
    // 2. finally_code (also executed on normal path)
    
    ACodeGenerator.EmitLine('try {', []);
    ACodeGenerator.IncIndent();
    
    // Generate try block statements
    if ACodeGenerator.GetNodeType(LTryStatements) = 'STATEMENTS' then
      GenerateStatements(ACodeGenerator, LTryStatements);
    
    ACodeGenerator.DecIndent();
    ACodeGenerator.EmitLine('} catch (...) {', []);
    ACodeGenerator.IncIndent();
    
    // Generate finally block statements (exception path)
    LFinallyStatements := ACodeGenerator.FindNodeByType(
      ACodeGenerator.GetNodeChildren(LFinallyNode), 'STATEMENTS');
    
    if LFinallyStatements <> nil then
      GenerateStatements(ACodeGenerator, LFinallyStatements)
    else
    begin
      // No STATEMENTS child - check direct children of FINALLY node
      LChildren := ACodeGenerator.GetNodeChildren(LFinallyNode);
      if LChildren <> nil then
        GenerateStatements(ACodeGenerator, LFinallyNode);
    end;
    
    // Re-throw the exception
    ACodeGenerator.EmitLine('throw;', []);
    
    ACodeGenerator.DecIndent();
    ACodeGenerator.EmitLine('}', []);
    
    // Generate finally block statements (normal path)
    if LFinallyStatements <> nil then
      GenerateStatements(ACodeGenerator, LFinallyStatements)
    else
    begin
      // No STATEMENTS child - check direct children of FINALLY node
      LChildren := ACodeGenerator.GetNodeChildren(LFinallyNode);
      if LChildren <> nil then
        GenerateStatements(ACodeGenerator, LFinallyNode);
    end;
  end;
end;

function HasLoopControl(const ACodeGenerator: TNPCodeGenerator; const AStatementsNode: TJSONObject): Boolean;
var
  LChildren: TJSONArray;
  LI: Integer;
  LChild: TJSONValue;
  LChildObj: TJSONObject;
  LNodeType: string;
  LCallChildren: TJSONArray;
  LFuncName: string;
  LThenNode: TJSONObject;
  LElseNode: TJSONObject;
  LThenStatements: TJSONObject;
  LElseStatements: TJSONObject;
begin
  Result := False;
  
  if AStatementsNode = nil then
    Exit;
  
  LChildren := ACodeGenerator.GetNodeChildren(AStatementsNode);
  if LChildren = nil then
    Exit;
  
  for LI := 0 to LChildren.Count - 1 do
  begin
    LChild := LChildren.Items[LI];
    if not (LChild is TJSONObject) then
      Continue;
    
    LChildObj := LChild as TJSONObject;
    LNodeType := ACodeGenerator.GetNodeType(LChildObj);
    
    // Found Break or Continue
    if (LNodeType = 'BREAK') or (LNodeType = 'CONTINUE') then
      Exit(True);
    
    // Check for break/continue as CALL nodes
    if LNodeType = 'CALL' then
    begin
      LCallChildren := ACodeGenerator.GetNodeChildren(LChildObj);
      if (LCallChildren <> nil) and (LCallChildren.Count > 0) then
      begin
        LFuncName := ACodeGenerator.GetNodeAttribute(LCallChildren.Items[0] as TJSONObject, 'name');
        if SameText(LFuncName, 'break') or SameText(LFuncName, 'continue') then
          Exit(True);
      end;
    end;
    
    // Recursively check compound statements
    if (LNodeType = 'IF') then
    begin
      // Check THEN branch
      LThenNode := ACodeGenerator.FindNodeByType(ACodeGenerator.GetNodeChildren(LChildObj), 'THEN');
      if LThenNode <> nil then
      begin
        LThenStatements := ACodeGenerator.FindNodeByType(ACodeGenerator.GetNodeChildren(LThenNode), 'STATEMENTS');
        if LThenStatements <> nil then
        begin
          if HasLoopControl(ACodeGenerator, LThenStatements) then
            Exit(True);
        end
        else
        begin
          // No STATEMENTS child, check THEN node directly
          if HasLoopControl(ACodeGenerator, LThenNode) then
            Exit(True);
        end;
      end;
      
      // Check ELSE branch
      LElseNode := ACodeGenerator.FindNodeByType(ACodeGenerator.GetNodeChildren(LChildObj), 'ELSE');
      if LElseNode <> nil then
      begin
        LElseStatements := ACodeGenerator.FindNodeByType(ACodeGenerator.GetNodeChildren(LElseNode), 'STATEMENTS');
        if LElseStatements <> nil then
        begin
          if HasLoopControl(ACodeGenerator, LElseStatements) then
            Exit(True);
        end
        else
        begin
          // No STATEMENTS child, check ELSE node directly
          if HasLoopControl(ACodeGenerator, LElseNode) then
            Exit(True);
        end;
      end;
    end
    else if (LNodeType = 'CASE') then
    begin
      // Check case selectors
      if HasLoopControl(ACodeGenerator, LChildObj) then
        Exit(True);
    end;
    // Note: Don't recurse into nested loops
  end;
end;

function HasExit(const ACodeGenerator: TNPCodeGenerator; const AStatementsNode: TJSONObject): Boolean;
var
  LChildren: TJSONArray;
  LI: Integer;
  LChild: TJSONValue;
  LChildObj: TJSONObject;
  LNodeType: string;
  LCallChildren: TJSONArray;
  LFuncName: string;
  LThenNode: TJSONObject;
  LElseNode: TJSONObject;
  LThenStatements: TJSONObject;
  LElseStatements: TJSONObject;
begin
  Result := False;
  
  if AStatementsNode = nil then
    Exit;
  
  LChildren := ACodeGenerator.GetNodeChildren(AStatementsNode);
  if LChildren = nil then
    Exit;
  
  for LI := 0 to LChildren.Count - 1 do
  begin
    LChild := LChildren.Items[LI];
    if not (LChild is TJSONObject) then
      Continue;
    
    LChildObj := LChild as TJSONObject;
    LNodeType := ACodeGenerator.GetNodeType(LChildObj);
    
    // Found EXIT node
    if LNodeType = 'EXIT' then
      Exit(True);
    
    // Check for exit as CALL node
    if LNodeType = 'CALL' then
    begin
      LCallChildren := ACodeGenerator.GetNodeChildren(LChildObj);
      if (LCallChildren <> nil) and (LCallChildren.Count > 0) then
      begin
        LFuncName := ACodeGenerator.GetNodeAttribute(LCallChildren.Items[0] as TJSONObject, 'name');
        if SameText(LFuncName, 'exit') then
          Exit(True);
      end;
    end;
    
    // Recursively check compound statements
    if LNodeType = 'IF' then
    begin
      // Check THEN branch
      LThenNode := ACodeGenerator.FindNodeByType(ACodeGenerator.GetNodeChildren(LChildObj), 'THEN');
      if LThenNode <> nil then
      begin
        LThenStatements := ACodeGenerator.FindNodeByType(ACodeGenerator.GetNodeChildren(LThenNode), 'STATEMENTS');
        if LThenStatements <> nil then
        begin
          if HasExit(ACodeGenerator, LThenStatements) then
            Exit(True);
        end
        else
        begin
          // No STATEMENTS child, check THEN node directly
          if HasExit(ACodeGenerator, LThenNode) then
            Exit(True);
        end;
      end;
      
      // Check ELSE branch
      LElseNode := ACodeGenerator.FindNodeByType(ACodeGenerator.GetNodeChildren(LChildObj), 'ELSE');
      if LElseNode <> nil then
      begin
        LElseStatements := ACodeGenerator.FindNodeByType(ACodeGenerator.GetNodeChildren(LElseNode), 'STATEMENTS');
        if LElseStatements <> nil then
        begin
          if HasExit(ACodeGenerator, LElseStatements) then
            Exit(True);
        end
        else
        begin
          // No STATEMENTS child, check ELSE node directly
          if HasExit(ACodeGenerator, LElseNode) then
            Exit(True);
        end;
      end;
    end
    else if LNodeType = 'CASE' then
    begin
      // Check case selectors
      if HasExit(ACodeGenerator, LChildObj) then
        Exit(True);
    end;
    // Note: Don't recurse into nested loops - they handle their own Exit
  end;
end;

end.
