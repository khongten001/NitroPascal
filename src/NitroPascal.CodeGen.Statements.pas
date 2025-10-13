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

implementation

uses
  System.SysUtils,
  System.Generics.Collections,
  System.StrUtils,
  NitroPascal.CodeGen.Expressions;

const
  // Map of Delphi RTL function names (uppercase) to correct C++ RTL names
  RTL_FUNCTION_MAP: array[0..14] of record Name: string; CppName: string; end = (
    (Name: 'WRITELN'; CppName: 'WriteLn'),
    (Name: 'WRITE'; CppName: 'Write'),
    (Name: 'READLN'; CppName: 'ReadLn'),
    (Name: 'NEW'; CppName: 'New'),
    (Name: 'DISPOSE'; CppName: 'Dispose'),
    (Name: 'LENGTH'; CppName: 'Length'),
    (Name: 'COPY'; CppName: 'Copy'),
    (Name: 'POS'; CppName: 'Pos'),
    (Name: 'INTTOSTR'; CppName: 'IntToStr'),
    (Name: 'STRTOINT'; CppName: 'StrToInt'),
    (Name: 'STRTOINTDEF'; CppName: 'StrToIntDef'),
    (Name: 'FLOATTOSTR'; CppName: 'FloatToStr'),
    (Name: 'STRTOFLOAT'; CppName: 'StrToFloat'),
    (Name: 'UPPERCASE'; CppName: 'UpperCase'),
    (Name: 'LOWERCASE'; CppName: 'LowerCase')
  );

function GetRTLFunctionName(const AFuncName: string): string;
var
  LI: Integer;
  LUpper: string;
begin
  LUpper := UpperCase(AFuncName);
  for LI := Low(RTL_FUNCTION_MAP) to High(RTL_FUNCTION_MAP) do
  begin
    if RTL_FUNCTION_MAP[LI].Name = LUpper then
      Exit(RTL_FUNCTION_MAP[LI].CppName);
  end;
  Result := '';  // Not an RTL function
end;

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
    GenerateWithStatement(ACodeGenerator, ANode);
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
begin
  LChildren := ACodeGenerator.GetNodeChildren(ACallNode);
  if LChildren = nil then
    Exit;
  
  LArgs := '';
  
  // First child is function name
  if LChildren.Count > 0 then
    LFuncName := ACodeGenerator.GetNodeAttribute(LChildren.Items[0] as TJSONObject, 'name');
  
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
          LExprStr := NitroPascal.CodeGen.Expressions.GenerateExpression(ACodeGenerator, LExpr as TJSONObject);
          if LArgs <> '' then
            LArgs := LArgs + ', ';
          LArgs := LArgs + LExprStr;
        end;
      end;
    end;
  end;
  
  // Map Delphi RTL functions (case-insensitive) to correct C++ RTL names
  LRTLName := GetRTLFunctionName(LFuncName);
  
  if LRTLName <> '' then
    // It's an RTL function - use normalized name with np:: prefix
    ACodeGenerator.EmitLine('np::%s(%s);', [LRTLName, LArgs])
  else
    // User function - use original name without np:: prefix
    ACodeGenerator.EmitLine('%s(%s);', [LFuncName, LArgs]);
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
  
  // Emit runtime ForLoop or ForLoopDownto with lambda
  if LIsDownto then
    ACodeGenerator.EmitLine('np::ForLoopDownto(%s, %s, [&](np::Integer %s) {', [LStartExpr, LEndExpr, LIteratorName])
  else
    ACodeGenerator.EmitLine('np::ForLoop(%s, %s, [&](np::Integer %s) {', [LStartExpr, LEndExpr, LIteratorName]);
  
  ACodeGenerator.IncIndent();
  
  // Generate loop body
  if LStatementsNode <> nil then
    GenerateStatements(ACodeGenerator, LStatementsNode)
  else
  begin
    // No STATEMENTS node - process direct children as individual statements
    // (single statement without begin..end)
    for LI := 0 to LChildren.Count - 1 do
    begin
      LChild := LChildren.Items[LI];
      if LChild is TJSONObject then
      begin
        LChildObj := LChild as TJSONObject;
        LNodeType := ACodeGenerator.GetNodeType(LChildObj);
        // Skip the FOR loop metadata nodes (IDENTIFIER, FROM, TO, DOWNTO)
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
  
  ACodeGenerator.DecIndent();
  ACodeGenerator.EmitLine('});', []);
end;

procedure GenerateWhileLoop(const ACodeGenerator: TNPCodeGenerator; const AWhileNode: TJSONObject);
var
  LChildren: TJSONArray;
  LCondition: string;
  LStatementsNode: TJSONObject;
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
  
  // Emit runtime WhileLoop with lambdas
  ACodeGenerator.EmitLine('np::WhileLoop([&]() { return %s; }, [&]() {', [LCondition]);
  ACodeGenerator.IncIndent();
  
  if LStatementsNode <> nil then
    GenerateStatements(ACodeGenerator, LStatementsNode);
  
  ACodeGenerator.DecIndent();
  ACodeGenerator.EmitLine('});', []);
end;

procedure GenerateRepeatLoop(const ACodeGenerator: TNPCodeGenerator; const ARepeatNode: TJSONObject);
var
  LChildren: TJSONArray;
  LStatementsNode: TJSONObject;
  LConditionNode: TJSONObject;
  LConditionChildren: TJSONArray;
  LCondition: string;
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
  
  // Emit runtime RepeatUntil with lambdas
  ACodeGenerator.EmitLine('np::RepeatUntil([&]() {', []);
  ACodeGenerator.IncIndent();
  
  if LStatementsNode <> nil then
    GenerateStatements(ACodeGenerator, LStatementsNode);
  
  ACodeGenerator.DecIndent();
  ACodeGenerator.EmitLine('}, [&]() { return %s; });', [LCondition]);
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
  // TODO: Multiple WITH expressions (with A, B, C do...)
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
    // Check if there's a direct statement child (single statement without begin/end)
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

end.
