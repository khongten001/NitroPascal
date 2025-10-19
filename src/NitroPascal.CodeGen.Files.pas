{===============================================================================
  NitroPascal - Modern Pascal • C Performance

  Copyright © 2025-present tinyBigGAMES™ LLC
  All Rights Reserved.

  https://nitropascal.org

  See LICENSE for license information
===============================================================================}

unit NitroPascal.CodeGen.Files;

{$I NitroPascal.Defines.inc}

interface

uses
  System.Generics.Collections,
  System.JSON,
  NitroPascal.CodeGen;

{ Generate Files }

procedure GenerateCppFile(const ACodeGenerator: TNPCodeGenerator; const AUnitName: string; const AAST: TJSONArray);
procedure GenerateHeaderFile(const ACodeGenerator: TNPCodeGenerator; const AUnitName: string; const AAST: TJSONArray);
procedure GenerateIncludes(const ACodeGenerator: TNPCodeGenerator);
function  GetExportedFunctions(const ACodeGenerator: TNPCodeGenerator; const AChildren: TJSONArray): TList<string>;
procedure GenerateExportMacros(const ACodeGenerator: TNPCodeGenerator);
procedure GenerateDllMain(const ACodeGenerator: TNPCodeGenerator);

implementation

uses
  System.SysUtils,
  System.IOUtils,
  NitroPascal.CodeGen.Declarations,
  NitroPascal.CodeGen.Statements;

procedure GenerateIncludes(const ACodeGenerator: TNPCodeGenerator);
begin
  ACodeGenerator.EmitLine('#include "runtime.h"', []);
end;

function GetExportedFunctions(const ACodeGenerator: TNPCodeGenerator; const AChildren: TJSONArray): TList<string>;
var
  LI: Integer;
  LJ: Integer;
  LChild: TJSONValue;
  LChildObj: TJSONObject;
  LNodeType: string;
  LExportsNode: TJSONObject;
  LExportChildren: TJSONArray;
  LExportElement: TJSONObject;
  LFuncName: string;
begin
  Result := TList<string>.Create();
  
  if AChildren = nil then
    Exit;
  
  // Find EXPORTS node
  for LI := 0 to AChildren.Count - 1 do
  begin
    LChild := AChildren.Items[LI];
    if not (LChild is TJSONObject) then
      Continue;
    
    LChildObj := LChild as TJSONObject;
    LNodeType := ACodeGenerator.GetNodeType(LChildObj);
    
    if LNodeType = 'EXPORTS' then
    begin
      LExportsNode := LChildObj;
      LExportChildren := ACodeGenerator.GetNodeChildren(LExportsNode);
      
      if LExportChildren <> nil then
      begin
        for LJ := 0 to LExportChildren.Count - 1 do
        begin
          LExportElement := LExportChildren.Items[LJ] as TJSONObject;
          if ACodeGenerator.GetNodeType(LExportElement) = 'ELEMENT' then
          begin
            LFuncName := ACodeGenerator.GetNodeAttribute(LExportElement, 'name');
            if LFuncName <> '' then
              Result.Add(LFuncName);
          end;
        end;
      end;
      Break;
    end;
  end;
end;

procedure GenerateExportMacros(const ACodeGenerator: TNPCodeGenerator);
begin
  ACodeGenerator.EmitLine('// Platform-specific export macros', []);
  ACodeGenerator.EmitLine('#ifdef _WIN32', []);
  ACodeGenerator.EmitLine('  #define EXPORT_API __declspec(dllexport)', []);
  ACodeGenerator.EmitLine('  #define STDCALL __stdcall', []);
  ACodeGenerator.EmitLine('  #ifndef CDECL', []);
  ACodeGenerator.EmitLine('    #define CDECL __cdecl', []);
  ACodeGenerator.EmitLine('  #endif', []);
  ACodeGenerator.EmitLine('#else', []);
  ACodeGenerator.EmitLine('  #define EXPORT_API __attribute__((visibility("default")))', []);
  ACodeGenerator.EmitLine('  #define STDCALL', []);
  ACodeGenerator.EmitLine('  #define CDECL', []);
  ACodeGenerator.EmitLine('#endif', []);
  ACodeGenerator.EmitLn();
end;

procedure GenerateDllMain(const ACodeGenerator: TNPCodeGenerator);
begin
  ACodeGenerator.EmitLine('// Platform-specific DLL initialization', []);
  ACodeGenerator.EmitLine('#ifdef _WIN32', []);
  ACodeGenerator.EmitLine('#include <windows.h>', []);
  ACodeGenerator.EmitLn();
  ACodeGenerator.EmitLine('BOOL WINAPI DllMain(HINSTANCE hinstDLL, DWORD fdwReason, LPVOID lpvReserved) {', []);
  ACodeGenerator.IncIndent();
  ACodeGenerator.EmitLine('switch (fdwReason) {', []);
  ACodeGenerator.IncIndent();
  ACodeGenerator.EmitLine('case DLL_PROCESS_ATTACH:', []);
  ACodeGenerator.IncIndent();
  ACodeGenerator.EmitLine('// Library initialization', []);
  ACodeGenerator.EmitLine('break;', []);
  ACodeGenerator.DecIndent();
  ACodeGenerator.EmitLine('case DLL_PROCESS_DETACH:', []);
  ACodeGenerator.IncIndent();
  ACodeGenerator.EmitLine('// Library cleanup', []);
  ACodeGenerator.EmitLine('break;', []);
  ACodeGenerator.DecIndent();
  ACodeGenerator.EmitLine('case DLL_THREAD_ATTACH:', []);
  ACodeGenerator.EmitLine('case DLL_THREAD_DETACH:', []);
  ACodeGenerator.IncIndent();
  ACodeGenerator.EmitLine('break;', []);
  ACodeGenerator.DecIndent();
  ACodeGenerator.DecIndent();
  ACodeGenerator.EmitLine('}', []);
  ACodeGenerator.EmitLine('return TRUE;', []);
  ACodeGenerator.DecIndent();
  ACodeGenerator.EmitLine('}', []);
  ACodeGenerator.EmitLine('#else', []);
  ACodeGenerator.EmitLine('// Non-Windows shared library initialization', []);
  ACodeGenerator.EmitLine('__attribute__((constructor))', []);
  ACodeGenerator.EmitLine('void DllMain_Init() {', []);
  ACodeGenerator.IncIndent();
  ACodeGenerator.EmitLine('// Initialization code here', []);
  ACodeGenerator.DecIndent();
  ACodeGenerator.EmitLine('}', []);
  ACodeGenerator.EmitLn();
  ACodeGenerator.EmitLine('__attribute__((destructor))', []);
  ACodeGenerator.EmitLine('void DllMain_Cleanup() {', []);
  ACodeGenerator.IncIndent();
  ACodeGenerator.EmitLine('// Cleanup code here', []);
  ACodeGenerator.DecIndent();
  ACodeGenerator.EmitLine('}', []);
  ACodeGenerator.EmitLine('#endif', []);
  ACodeGenerator.EmitLn();
end;

procedure RegisterAllExternalFunctions(const ACodeGenerator: TNPCodeGenerator; const AChildren: TJSONArray);
var
  LI: Integer;
  LChild: TJSONValue;
  LChildObj: TJSONObject;
  LNodeType: string;
  LInterfaceChildren: TJSONArray;
  LJ: Integer;
begin
  if AChildren = nil then
    Exit;
  
  // Register external functions from top-level METHOD nodes
  for LI := 0 to AChildren.Count - 1 do
  begin
    LChild := AChildren.Items[LI];
    if not (LChild is TJSONObject) then
      Continue;
    
    LChildObj := LChild as TJSONObject;
    LNodeType := ACodeGenerator.GetNodeType(LChildObj);
    
    if LNodeType = 'METHOD' then
    begin
      if NitroPascal.CodeGen.Declarations.IsExternalFunction(ACodeGenerator, LChildObj) then
        NitroPascal.CodeGen.Declarations.RegisterExternalFunctionInfo(ACodeGenerator, LChildObj);
    end
    else if LNodeType = 'INTERFACE' then
    begin
      // Also check inside INTERFACE section for units
      LInterfaceChildren := ACodeGenerator.GetNodeChildren(LChildObj);
      if LInterfaceChildren <> nil then
      begin
        for LJ := 0 to LInterfaceChildren.Count - 1 do
        begin
          if not (LInterfaceChildren.Items[LJ] is TJSONObject) then
            Continue;
          
          LChildObj := LInterfaceChildren.Items[LJ] as TJSONObject;
          if ACodeGenerator.GetNodeType(LChildObj) = 'METHOD' then
          begin
            if NitroPascal.CodeGen.Declarations.IsExternalFunction(ACodeGenerator, LChildObj) then
              NitroPascal.CodeGen.Declarations.RegisterExternalFunctionInfo(ACodeGenerator, LChildObj);
          end;
        end;
      end;
    end;
  end;
end;

procedure GenerateUsesNamespaces(const ACodeGenerator: TNPCodeGenerator; const AUsesNode: TJSONObject);
var
  LChildren: TJSONArray;
  LI: Integer;
  LChild: TJSONValue;
  LUnitNode: TJSONObject;
  LUnitName: string;
begin
  LChildren := ACodeGenerator.GetNodeChildren(AUsesNode);
  if LChildren = nil then
    Exit;
  
  // Generate using namespace statements in the order of the uses clause
  // This matches Delphi's behavior where the last unit takes precedence
  for LI := 0 to LChildren.Count - 1 do
  begin
    LChild := LChildren.Items[LI];
    if not (LChild is TJSONObject) then
      Continue;
    
    LUnitNode := LChild as TJSONObject;
    if ACodeGenerator.GetNodeType(LUnitNode) = 'UNIT' then
    begin
      LUnitName := ACodeGenerator.GetNodeAttribute(LUnitNode, 'name');
      ACodeGenerator.EmitLine('using namespace %s;', [LUnitName]);
    end;
  end;
end;

procedure RegisterExternalFunctionsFromImportedUnits(const ACodeGenerator: TNPCodeGenerator; const AUsesNode: TJSONObject; const AAST: TJSONArray);
var
  LChildren: TJSONArray;
  LI: Integer;
  LJ: Integer;
  LK: Integer;
  LChild: TJSONValue;
  LUnitNode: TJSONObject;
  LUnitName: string;
  LJSONPath: string;
  LJSON: string;
  LFullJSON: TJSONValue;
  LFullJSONObj: TJSONObject;
  LUnitsArray: TJSONArray;
  LUnitWrapper: TJSONObject;
  LUnitAST: TJSONArray;
  LUnitASTNode: TJSONObject;
  LImportedChildren: TJSONArray;
  LInterfaceNode: TJSONObject;
  LInterfaceChildren: TJSONArray;
  LMethodNode: TJSONObject;
  LFoundUnitName: string;
  LFiles: TArray<string>;
begin
  LChildren := ACodeGenerator.GetNodeChildren(AUsesNode);
  if LChildren = nil then
    Exit;
  
  // Load the FULL JSON file which contains all units
  LJSONPath := TPath.Combine(ACodeGenerator.OutputFolder, 
    TPath.GetFileNameWithoutExtension(ACodeGenerator.OutputFolder) + '.json');
  
  // The JSON filename is based on the project name
  // Try to find it by looking for *.json in the output folder
  LFiles := TDirectory.GetFiles(ACodeGenerator.OutputFolder, '*.json');
  if Length(LFiles) = 0 then
    Exit;
  
  LJSONPath := LFiles[0];  // Use the first JSON file found
  
  try
    LJSON := TFile.ReadAllText(LJSONPath, TEncoding.UTF8);
    LFullJSON := TJSONObject.ParseJSONValue(LJSON);
    try
      if not (LFullJSON is TJSONObject) then
        Exit;
      
      LFullJSONObj := LFullJSON as TJSONObject;
      
      // Get the "units" array
      if not LFullJSONObj.TryGetValue<TJSONArray>('units', LUnitsArray) then
        Exit;
      
      // Scan each imported unit
      for LI := 0 to LChildren.Count - 1 do
      begin
        LChild := LChildren.Items[LI];
        if not (LChild is TJSONObject) then
          Continue;
        
        LUnitNode := LChild as TJSONObject;
        if ACodeGenerator.GetNodeType(LUnitNode) = 'UNIT' then
        begin
          LUnitName := ACodeGenerator.GetNodeAttribute(LUnitNode, 'name');
          
          // Search for this unit in the units array
          for LJ := 0 to LUnitsArray.Count - 1 do
          begin
            if not (LUnitsArray.Items[LJ] is TJSONObject) then
              Continue;
            
            LUnitWrapper := LUnitsArray.Items[LJ] as TJSONObject;
            
            // Check if the unit name matches
            if not LUnitWrapper.TryGetValue<string>('name', LFoundUnitName) then
              Continue;
            
            if not SameText(LFoundUnitName, LUnitName) then
              Continue;
            
            // Get the AST array from inside the wrapper
            if not LUnitWrapper.TryGetValue<TJSONArray>('ast', LUnitAST) then
              Continue;
            
            if (LUnitAST = nil) or (LUnitAST.Count = 0) then
              Continue;
            
            // Get the actual UNIT node from the AST
            LUnitASTNode := LUnitAST.Items[0] as TJSONObject;
            
            // Found the unit - scan its interface for external functions
            LImportedChildren := ACodeGenerator.GetNodeChildren(LUnitASTNode);
            if LImportedChildren = nil then
              Continue;
            
            // Find the INTERFACE section
            LInterfaceNode := ACodeGenerator.FindNodeByType(LImportedChildren, 'INTERFACE');
            if LInterfaceNode = nil then
              Continue;
            
            LInterfaceChildren := ACodeGenerator.GetNodeChildren(LInterfaceNode);
            if LInterfaceChildren = nil then
              Continue;
            
            // Scan for external function declarations
            for LK := 0 to LInterfaceChildren.Count - 1 do
            begin
              if not (LInterfaceChildren.Items[LK] is TJSONObject) then
                Continue;
              
              LMethodNode := LInterfaceChildren.Items[LK] as TJSONObject;
              if ACodeGenerator.GetNodeType(LMethodNode) <> 'METHOD' then
                Continue;
              
              // Check if it's an external function and register it
              if NitroPascal.CodeGen.Declarations.IsExternalFunction(ACodeGenerator, LMethodNode) then
                NitroPascal.CodeGen.Declarations.RegisterExternalFunctionInfo(ACodeGenerator, LMethodNode);
            end;
            
            Break; // Found the unit, no need to continue searching
          end;
        end;
      end;
      
    finally
      LFullJSON.Free();
    end;
  except
    // Silently fail if JSON cannot be loaded
  end;
end;

procedure GenerateUsesIncludes(const ACodeGenerator: TNPCodeGenerator; const AUsesNode: TJSONObject);
var
  LChildren: TJSONArray;
  LI: Integer;
  LChild: TJSONValue;
  LUnitNode: TJSONObject;
  LUnitName: string;
begin
  LChildren := ACodeGenerator.GetNodeChildren(AUsesNode);
  if LChildren = nil then
    Exit;
  
  for LI := 0 to LChildren.Count - 1 do
  begin
    LChild := LChildren.Items[LI];
    if not (LChild is TJSONObject) then
      Continue;
    
    LUnitNode := LChild as TJSONObject;
    if ACodeGenerator.GetNodeType(LUnitNode) = 'UNIT' then
    begin
      LUnitName := ACodeGenerator.GetNodeAttribute(LUnitNode, 'name');
      ACodeGenerator.EmitLine('#include "%s.h"', [LUnitName]);
    end;
  end;
end;

procedure GenerateCppFile(const ACodeGenerator: TNPCodeGenerator; const AUnitName: string; const AAST: TJSONArray);
var
  LOutputPath: string;
  LUnitNode: TJSONObject;
  LChildren: TJSONArray;
  LI: Integer;
  LChild: TJSONValue;
  LChildObj: TJSONObject;
  LNodeType: string;
  LHasStatements: Boolean;
  LHasInterface: Boolean;
  LIsLibrary: Boolean;
  LVariablesNode: TJSONObject;
  LStatementsNode: TJSONObject;
  LExportedFunctions: TList<string>;
  LIsExported: Boolean;
  LMethodName: string;
begin
  // Get unit node
  if AAST.Count = 0 then
    Exit;
  
  LUnitNode := AAST.Items[0] as TJSONObject;
  LChildren := ACodeGenerator.GetNodeChildren(LUnitNode);
  
  if LChildren = nil then
    Exit;
  
  // CRITICAL: Register ALL external functions FIRST (before any code generation)
  // This ensures string conversion works for ALL file types (program, unit, library)
  RegisterAllExternalFunctions(ACodeGenerator, LChildren);
  
  // Check what type of unit this is
  LHasStatements := ACodeGenerator.FindNodeByType(LChildren, 'STATEMENTS') <> nil;
  LHasInterface := ACodeGenerator.FindNodeByType(LChildren, 'INTERFACE') <> nil;
  LIsLibrary := ACodeGenerator.IsLibrary(LUnitNode);
  
  if LIsLibrary then
  begin
    // LIBRARY GENERATION
    LExportedFunctions := GetExportedFunctions(ACodeGenerator, LChildren);
    try
      // File header
      ACodeGenerator.EmitLine('/**', []);
      ACodeGenerator.EmitLine(' * Generated by NitroPascal Compiler', []);
      ACodeGenerator.EmitLine(' * Source: %s.dpr (Library)', [AUnitName]);
      ACodeGenerator.EmitLine(' * Date: %s', [FormatDateTime('yyyy-mm-dd hh:nn:ss', Now)]);
      ACodeGenerator.EmitLine(' * ', []);
      ACodeGenerator.EmitLine(' * IMPORTANT: This file is UTF-8 encoded', []);
    ACodeGenerator.EmitLine(' */', []);
    ACodeGenerator.EmitLn();
    
    // Tell MSVC the source file is UTF-8
    ACodeGenerator.EmitLine('#ifdef _MSC_VER', []);
    ACodeGenerator.EmitLine('#pragma execution_character_set("utf-8")', []);
    ACodeGenerator.EmitLine('#endif', []);
    ACodeGenerator.EmitLn();
      
      // Includes
      GenerateIncludes(ACodeGenerator);
      ACodeGenerator.EmitLn();
      
      // Export macros
      GenerateExportMacros(ACodeGenerator);
      
      // DllMain
      GenerateDllMain(ACodeGenerator);
      
      // First: Process IMPLEMENTATION section for constants, types, and variables
      for LI := 0 to LChildren.Count - 1 do
      begin
        LChild := LChildren.Items[LI];
        if not (LChild is TJSONObject) then
          Continue;
        
        LChildObj := LChild as TJSONObject;
        LNodeType := ACodeGenerator.GetNodeType(LChildObj);
        
        if LNodeType = 'IMPLEMENTATION' then
        begin
          var LImplChildren := ACodeGenerator.GetNodeChildren(LChildObj);
          if LImplChildren <> nil then
          begin
            for var LJ := 0 to LImplChildren.Count - 1 do
            begin
              if not (LImplChildren.Items[LJ] is TJSONObject) then
                Continue;
              
              var LImplChild := LImplChildren.Items[LJ] as TJSONObject;
              var LImplNodeType := ACodeGenerator.GetNodeType(LImplChild);
              
              // Generate constants
              if LImplNodeType = 'CONSTANTS' then
              begin
                NitroPascal.CodeGen.Declarations.GenerateConstants(ACodeGenerator, LImplChild);
                ACodeGenerator.EmitLn();
              end
              // Generate types
              else if LImplNodeType = 'TYPESECTION' then
              begin
                ACodeGenerator.EmitLine('// Type declarations', []);
                NitroPascal.CodeGen.Declarations.GenerateTypeDeclarations(ACodeGenerator, LImplChild);
                ACodeGenerator.EmitLn();
              end
              // Generate variables
              else if LImplNodeType = 'VARIABLES' then
              begin
                NitroPascal.CodeGen.Declarations.GenerateVariables(ACodeGenerator, LImplChild);
                ACodeGenerator.EmitLn();
              end;
            end;
          end;
        end;
      end;
      
      // Then: Generate function implementations with exports
      ACodeGenerator.EmitLine('// Exported functions', []);
      ACodeGenerator.EmitLine('extern "C" {', []);
      ACodeGenerator.EmitLn();
      
      for LI := 0 to LChildren.Count - 1 do
      begin
        LChild := LChildren.Items[LI];
        if not (LChild is TJSONObject) then
          Continue;
        
        LChildObj := LChild as TJSONObject;
        LNodeType := ACodeGenerator.GetNodeType(LChildObj);
        
        if LNodeType = 'METHOD' then
        begin
          LMethodName := ACodeGenerator.GetNodeAttribute(LChildObj, 'name');
          LIsExported := LExportedFunctions.Contains(LMethodName);
          
          // Generate with EXPORT_API prefix if exported
          NitroPascal.CodeGen.Declarations.GenerateFunctionImplementationWithExport(
            ACodeGenerator, LChildObj, LIsExported);
          ACodeGenerator.EmitLn();
        end;
      end;
      
      ACodeGenerator.EmitLine('} // extern "C"', []);
    finally
      LExportedFunctions.Free();
    end;
  end
  else if LHasStatements then
  begin
    // This is a PROGRAM - has direct STATEMENTS children
    // Generate file header comment
    ACodeGenerator.EmitLine('/**', []);
    ACodeGenerator.EmitLine(' * Generated by NitroPascal Compiler', []);
    ACodeGenerator.EmitLine(' * Source: %s.pas', [AUnitName]);
    ACodeGenerator.EmitLine(' * Date: %s', [FormatDateTime('yyyy-mm-dd hh:nn:ss', Now)]);
    ACodeGenerator.EmitLine(' * ', []);
    ACodeGenerator.EmitLine(' * IMPORTANT: This file is UTF-8 encoded', []);
    ACodeGenerator.EmitLine(' */', []);
    ACodeGenerator.EmitLn();
    
    // Tell MSVC the source file is UTF-8
    ACodeGenerator.EmitLine('#ifdef _MSC_VER', []);
    ACodeGenerator.EmitLine('#pragma execution_character_set("utf-8")', []);
    ACodeGenerator.EmitLine('#endif', []);
    ACodeGenerator.EmitLn();
    
    // Include the header file for this program
    ACodeGenerator.EmitLine('#include "%s.h"', [AUnitName]);
    
    // Generate USES clause includes
    LVariablesNode := ACodeGenerator.FindNodeByType(LChildren, 'USES');
    if LVariablesNode <> nil then
    begin
      // First, register external functions from imported units
      RegisterExternalFunctionsFromImportedUnits(ACodeGenerator, LVariablesNode, AAST);
      
      // Then generate includes
      GenerateUsesIncludes(ACodeGenerator, LVariablesNode);
      ACodeGenerator.EmitLn();
      
      // Generate using namespace directives to import symbols from used units
      // This matches Pascal semantics where 'uses UnitName' makes all public symbols
      // from that unit available without qualification
      GenerateUsesNamespaces(ACodeGenerator, LVariablesNode);
    end;
    
    ACodeGenerator.EmitLn();
    
    // Generate global variables first
    LVariablesNode := ACodeGenerator.FindNodeByType(LChildren, 'VARIABLES');
    if LVariablesNode <> nil then
    begin
      NitroPascal.CodeGen.Declarations.GenerateVariables(ACodeGenerator, LVariablesNode);
      ACodeGenerator.EmitLn();
    end;
    
    // NOTE: Type declarations are NOT generated here for PROGRAM files
    // They are already in the .h file (which is included above)
    // Generating them here would cause redefinition errors
    
    // Generate constants
    for LI := 0 to LChildren.Count - 1 do
    begin
      LChild := LChildren.Items[LI];
      if not (LChild is TJSONObject) then
        Continue;
      
      LChildObj := LChild as TJSONObject;
      LNodeType := ACodeGenerator.GetNodeType(LChildObj);
      
      if LNodeType = 'CONSTANTS' then
      begin
        NitroPascal.CodeGen.Declarations.GenerateConstants(ACodeGenerator, LChildObj);
        ACodeGenerator.EmitLn();
      end;
    end;
    
    // Generate function declarations and implementations BEFORE main()
    for LI := 0 to LChildren.Count - 1 do
    begin
      LChild := LChildren.Items[LI];
      if not (LChild is TJSONObject) then
        Continue;
      
      LChildObj := LChild as TJSONObject;
      LNodeType := ACodeGenerator.GetNodeType(LChildObj);
      
      if (LNodeType = 'METHOD') then
      begin
        NitroPascal.CodeGen.Declarations.GenerateFunctionImplementation(ACodeGenerator, LChildObj);
        ACodeGenerator.EmitLn();
      end;
    end;
    
    // Generate main() function
    ACodeGenerator.EmitLine('int main(int argc, char* argv[]) {', []);
    ACodeGenerator.IncIndent();
    
    // Initialize console for UTF-8 support (Windows)
    ACodeGenerator.EmitLine('np::InitializeConsole();', []);
    ACodeGenerator.EmitLn();
    
    // Initialize command line parameters
    ACodeGenerator.EmitLine('np::InitCommandLine(argc, argv);', []);
    ACodeGenerator.EmitLn();
    
    // Generate statements
    LStatementsNode := ACodeGenerator.FindNodeByType(LChildren, 'STATEMENTS');
    if LStatementsNode <> nil then
      NitroPascal.CodeGen.Statements.GenerateStatements(ACodeGenerator, LStatementsNode);
    
    // Return from main
    ACodeGenerator.EmitLine('return 0;', []);
    
    ACodeGenerator.DecIndent();
    ACodeGenerator.EmitLine('}', []);
  end
  else if LHasInterface then
  begin
    // This is a UNIT - has INTERFACE/IMPLEMENTATION sections
    // Generate cpp file header
    ACodeGenerator.EmitLine('/**', []);
    ACodeGenerator.EmitLine(' * Generated by NitroPascal Compiler', []);
    ACodeGenerator.EmitLine(' * Source: %s.pas', [AUnitName]);
    ACodeGenerator.EmitLine(' * Date: %s', [FormatDateTime('yyyy-mm-dd hh:nn:ss', Now)]);
    ACodeGenerator.EmitLine(' * ', []);
    ACodeGenerator.EmitLine(' * IMPORTANT: This file is UTF-8 encoded', []);
    ACodeGenerator.EmitLine(' */', []);
    ACodeGenerator.EmitLn();
    
    // Tell MSVC the source file is UTF-8
    ACodeGenerator.EmitLine('#ifdef _MSC_VER', []);
    ACodeGenerator.EmitLine('#pragma execution_character_set("utf-8")', []);
    ACodeGenerator.EmitLine('#endif', []);
    ACodeGenerator.EmitLn();
    
    // Include the header file
    ACodeGenerator.EmitLine('#include "%s.h"', [AUnitName]);
    ACodeGenerator.EmitLn();
    
    // Open namespace for implementation
    ACodeGenerator.EmitLine('namespace %s {', [AUnitName]);
    ACodeGenerator.EmitLn();
    
    // Process IMPLEMENTATION section - generate constants, types, variables, then functions
    for LI := 0 to LChildren.Count - 1 do
    begin
      LChild := LChildren.Items[LI];
      if not (LChild is TJSONObject) then
        Continue;
      
      LChildObj := LChild as TJSONObject;
      LNodeType := ACodeGenerator.GetNodeType(LChildObj);
      
      if LNodeType = 'IMPLEMENTATION' then
      begin
        var LImplChildren := ACodeGenerator.GetNodeChildren(LChildObj);
        if LImplChildren <> nil then
        begin
          // First pass: Generate types
          for var LJ := 0 to LImplChildren.Count - 1 do
          begin
            if not (LImplChildren.Items[LJ] is TJSONObject) then
              Continue;
            
            var LImplChild := LImplChildren.Items[LJ] as TJSONObject;
            var LImplNodeType := ACodeGenerator.GetNodeType(LImplChild);
            
            if LImplNodeType = 'TYPESECTION' then
            begin
              ACodeGenerator.EmitLine('// Type declarations', []);
              NitroPascal.CodeGen.Declarations.GenerateTypeDeclarations(ACodeGenerator, LImplChild);
              ACodeGenerator.EmitLn();
            end;
          end;
          
          // Second pass: Generate constants
          for var LJ := 0 to LImplChildren.Count - 1 do
          begin
            if not (LImplChildren.Items[LJ] is TJSONObject) then
              Continue;
            
            var LImplChild := LImplChildren.Items[LJ] as TJSONObject;
            var LImplNodeType := ACodeGenerator.GetNodeType(LImplChild);
            
            if LImplNodeType = 'CONSTANTS' then
            begin
              NitroPascal.CodeGen.Declarations.GenerateConstants(ACodeGenerator, LImplChild);
              ACodeGenerator.EmitLn();
            end;
          end;
          
          // Third pass: Generate variables
          for var LJ := 0 to LImplChildren.Count - 1 do
          begin
            if not (LImplChildren.Items[LJ] is TJSONObject) then
              Continue;
            
            var LImplChild := LImplChildren.Items[LJ] as TJSONObject;
            var LImplNodeType := ACodeGenerator.GetNodeType(LImplChild);
            
            if LImplNodeType = 'VARIABLES' then
            begin
              NitroPascal.CodeGen.Declarations.GenerateVariables(ACodeGenerator, LImplChild);
              ACodeGenerator.EmitLn();
            end;
          end;
          
          // Fourth pass: Generate function implementations
          NitroPascal.CodeGen.Declarations.GenerateFunctionDeclarations(ACodeGenerator, LImplChildren);
        end;
      end;
    end;
    
    // Close namespace
    ACodeGenerator.EmitLine('} // namespace %s', [AUnitName]);
  end;
    
  // Write output file with UTF-8 encoding (CRITICAL for UTF-8 string literals)
  LOutputPath := TPath.Combine(ACodeGenerator.OutputFolder, AUnitName + '.cpp');
  TFile.WriteAllText(LOutputPath, ACodeGenerator.Output.ToString(), TEncoding.UTF8);
end;

procedure GenerateHeaderFile(const ACodeGenerator: TNPCodeGenerator; const AUnitName: string; const AAST: TJSONArray);
var
  LOutputPath: string;
  LUnitNode: TJSONObject;
  LChildren: TJSONArray;
  LI: Integer;
  LChild: TJSONValue;
  LChildObj: TJSONObject;
  LNodeType: string;
  LInterfaceNode: TJSONObject;
  LUsesNode: TJSONObject;
  LHasInterface: Boolean;
  LFirstMethod: Boolean;
  LMethodName: string;
  LHeaders: TArray<string>;
  LHeader: string;
begin
  // Generate file header comment
  ACodeGenerator.EmitLine('/**', []);
  ACodeGenerator.EmitLine(' * Generated by NitroPascal Compiler', []);
  ACodeGenerator.EmitLine(' * Source: %s.pas', [AUnitName]);
  ACodeGenerator.EmitLine(' * Date: %s', [FormatDateTime('yyyy-mm-dd hh:nn:ss', Now)]);
  ACodeGenerator.EmitLine(' * ', []);
  ACodeGenerator.EmitLine(' * IMPORTANT: This file is UTF-8 encoded', []);
  ACodeGenerator.EmitLine(' */', []);
  ACodeGenerator.EmitLn();

  // Header guard
  ACodeGenerator.EmitLine('#pragma once', []);
  ACodeGenerator.EmitLn();

  // Tell MSVC the source file is UTF-8
  ACodeGenerator.EmitLine('#ifdef _MSC_VER', []);
  ACodeGenerator.EmitLine('#pragma execution_character_set("utf-8")', []);
  ACodeGenerator.EmitLine('#endif', []);
  ACodeGenerator.EmitLn();

  // User-specified headers from {$INCLUDE_HEADER} directives
  LHeaders := ACodeGenerator.GetIncludeHeaders();
  if Length(LHeaders) > 0 then
  begin
    ACodeGenerator.EmitLine('// User-specified headers', []);
    for LHeader in LHeaders do
    begin
      // Determine if it's a system header (<>) or local header ("")
      if (LHeader.StartsWith('<') and LHeader.EndsWith('>')) or
         (LHeader.StartsWith('"') and LHeader.EndsWith('"')) then
        ACodeGenerator.EmitLine('#include %s', [LHeader])
      else
        // Default to system header
        ACodeGenerator.EmitLine('#include <%s>', [LHeader]);
    end;
    ACodeGenerator.EmitLn();
  end;

  // Generate includes
  GenerateIncludes(ACodeGenerator);
  ACodeGenerator.EmitLn();
  
  // Get unit node
  if AAST.Count = 0 then
    Exit;
  
  LUnitNode := AAST.Items[0] as TJSONObject;
  LChildren := ACodeGenerator.GetNodeChildren(LUnitNode);
  
  if LChildren = nil then
    Exit;
  
  // CRITICAL: Register ALL external functions FIRST (before any code generation)
  // This ensures string conversion works for ALL file types (program, unit, library)
  RegisterAllExternalFunctions(ACodeGenerator, LChildren);
  
  // Check if this has INTERFACE section (UNIT) or just VARIABLES (PROGRAM)
  LInterfaceNode := ACodeGenerator.FindNodeByType(LChildren, 'INTERFACE');
  LHasInterface := LInterfaceNode <> nil;
  
  // Generate USES clause includes (ALWAYS - for all types of files)
  LUsesNode := ACodeGenerator.FindNodeByType(LChildren, 'USES');
  if LUsesNode <> nil then
  begin
    GenerateUsesIncludes(ACodeGenerator, LUsesNode);
    ACodeGenerator.EmitLn();
    
    // For PROGRAM files (not UNIT files), also generate using namespace directives
    // This matches the behavior in the .cpp file and makes types from used units available
    if not LHasInterface then
    begin
      GenerateUsesNamespaces(ACodeGenerator, LUsesNode);
      ACodeGenerator.EmitLn();
    end;
  end;
  
  if LHasInterface then
  begin
    // UNIT: Generate type declarations and function declarations from INTERFACE
    LChildren := ACodeGenerator.GetNodeChildren(LInterfaceNode);
    
    // ALWAYS open namespace for UNIT files, even if INTERFACE is empty
    // This ensures the namespace exists for 'using namespace' directives
    ACodeGenerator.EmitLine('namespace %s {', [AUnitName]);
    ACodeGenerator.EmitLn();
    
    if LChildren <> nil then
    begin
      
      // First pass: Generate type declarations
      for LI := 0 to LChildren.Count - 1 do
      begin
        LChild := LChildren.Items[LI];
        if not (LChild is TJSONObject) then
          Continue;
        
        LChildObj := LChild as TJSONObject;
        LNodeType := ACodeGenerator.GetNodeType(LChildObj);
        
        if LNodeType = 'TYPESECTION' then
        begin
          ACodeGenerator.EmitLine('// Type declarations', []);
          NitroPascal.CodeGen.Declarations.GenerateTypeDeclarations(ACodeGenerator, LChildObj);
          ACodeGenerator.EmitLn();
        end;
      end;
      
      // Second pass: Generate constants
      for LI := 0 to LChildren.Count - 1 do
      begin
        LChild := LChildren.Items[LI];
        if not (LChild is TJSONObject) then
          Continue;
        
        LChildObj := LChild as TJSONObject;
        LNodeType := ACodeGenerator.GetNodeType(LChildObj);
        
        if LNodeType = 'CONSTANTS' then
        begin
          NitroPascal.CodeGen.Declarations.GenerateConstants(ACodeGenerator, LChildObj);
          ACodeGenerator.EmitLn();
        end;
      end;
      
      // Third pass: Track forward declarations before generating function declarations
      for LI := 0 to LChildren.Count - 1 do
      begin
        LChild := LChildren.Items[LI];
        if not (LChild is TJSONObject) then
          Continue;
        
        LChildObj := LChild as TJSONObject;
        LNodeType := ACodeGenerator.GetNodeType(LChildObj);
        
        if (LNodeType = 'METHOD') or (LNodeType = 'PROCEDURE') or (LNodeType = 'FUNCTION') then
        begin
          if NitroPascal.CodeGen.Declarations.HasForwardDirective(ACodeGenerator, LChildObj) then
          begin
            LMethodName := ACodeGenerator.GetNodeAttribute(LChildObj, 'name');
            ACodeGenerator.AddForwardDeclaration(LMethodName);
          end;
        end;
      end;
      
      // Fourth pass: Generate function declarations
      LFirstMethod := True;
      for LI := 0 to LChildren.Count - 1 do
      begin
        LChild := LChildren.Items[LI];
        if not (LChild is TJSONObject) then
          Continue;
        
        LChildObj := LChild as TJSONObject;
        LNodeType := ACodeGenerator.GetNodeType(LChildObj);
        
        if (LNodeType = 'METHOD') or (LNodeType = 'PROCEDURE') or (LNodeType = 'FUNCTION') then
        begin
          if LFirstMethod then
          begin
            ACodeGenerator.EmitLine('// Function declarations', []);
            LFirstMethod := False;
          end;
          NitroPascal.CodeGen.Declarations.GenerateFunctionDeclaration(ACodeGenerator, LChildObj, AUnitName);
          ACodeGenerator.EmitLn();
        end;
      end;
    end;
    
    // Close namespace (ALWAYS - even if interface is empty)
    ACodeGenerator.EmitLine('} // namespace %s', [AUnitName]);
    ACodeGenerator.EmitLn();
    
    // Emit external function declarations OUTSIDE the namespace
    NitroPascal.CodeGen.Declarations.EmitRegisteredExternalFunctions(ACodeGenerator);
  end
  else
  begin
    // PROGRAM: Generate type declarations and extern variables
    // Get the original unit node's children (not the interface node)
    LUnitNode := AAST.Items[0] as TJSONObject;
    LChildren := ACodeGenerator.GetNodeChildren(LUnitNode);
    
    if LChildren <> nil then
    begin
      // Generate type declarations first
      for LI := 0 to LChildren.Count - 1 do
      begin
        LChild := LChildren.Items[LI];
        if not (LChild is TJSONObject) then
          Continue;
        
        LChildObj := LChild as TJSONObject;
        LNodeType := ACodeGenerator.GetNodeType(LChildObj);
        
        if LNodeType = 'TYPESECTION' then
        begin
          ACodeGenerator.EmitLine('// Type declarations', []);
          NitroPascal.CodeGen.Declarations.GenerateTypeDeclarations(ACodeGenerator, LChildObj);
          ACodeGenerator.EmitLn();
        end;
      end;
      
      // Track forward declarations before generating function declarations
      for LI := 0 to LChildren.Count - 1 do
      begin
        LChild := LChildren.Items[LI];
        if not (LChild is TJSONObject) then
          Continue;
        
        LChildObj := LChild as TJSONObject;
        LNodeType := ACodeGenerator.GetNodeType(LChildObj);
        
        if LNodeType = 'METHOD' then
        begin
          if NitroPascal.CodeGen.Declarations.HasForwardDirective(ACodeGenerator, LChildObj) then
          begin
            LMethodName := ACodeGenerator.GetNodeAttribute(LChildObj, 'name');
            ACodeGenerator.AddForwardDeclaration(LMethodName);
          end;
        end;
      end;
      
      // Generate function declarations
      LFirstMethod := True;
      for LI := 0 to LChildren.Count - 1 do
      begin
        LChild := LChildren.Items[LI];
        if not (LChild is TJSONObject) then
          Continue;
        
        LChildObj := LChild as TJSONObject;
        LNodeType := ACodeGenerator.GetNodeType(LChildObj);
        
        if LNodeType = 'METHOD' then
        begin
          if LFirstMethod then
          begin
            ACodeGenerator.EmitLine('// Function declarations', []);
            LFirstMethod := False;
          end;
          NitroPascal.CodeGen.Declarations.GenerateFunctionDeclaration(ACodeGenerator, LChildObj, AUnitName);
          ACodeGenerator.EmitLn();
        end;
      end;
      
      // Generate extern declarations for global variables
      for LI := 0 to LChildren.Count - 1 do
      begin
        LChild := LChildren.Items[LI];
        if not (LChild is TJSONObject) then
          Continue;
        
        LChildObj := LChild as TJSONObject;
        LNodeType := ACodeGenerator.GetNodeType(LChildObj);
        
        if LNodeType = 'VARIABLES' then
        begin
          ACodeGenerator.EmitLine('// Global variables', []);
          NitroPascal.CodeGen.Declarations.GenerateExternVariables(ACodeGenerator, LChildObj);
          ACodeGenerator.EmitLn();
        end;
      end;
    end;
  end;
    
  // Write output file with UTF-8 encoding (CRITICAL for UTF-8 string literals)
  LOutputPath := TPath.Combine(ACodeGenerator.OutputFolder, AUnitName + '.h');
  TFile.WriteAllText(LOutputPath, ACodeGenerator.Output.ToString(), TEncoding.UTF8);
end;

end.
