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
      
      // Generate function implementations with exports
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
    
    // Include the header file for this program (which includes runtime.h)
    ACodeGenerator.EmitLine('#include "%s.h"', [AUnitName]);
    
    // Generate USES clause includes
    LVariablesNode := ACodeGenerator.FindNodeByType(LChildren, 'USES');
    if LVariablesNode <> nil then
      GenerateUsesIncludes(ACodeGenerator, LVariablesNode);
    
    ACodeGenerator.EmitLn();
    
    // Generate global variables first
    LVariablesNode := ACodeGenerator.FindNodeByType(LChildren, 'VARIABLES');
    if LVariablesNode <> nil then
    begin
      NitroPascal.CodeGen.Declarations.GenerateVariables(ACodeGenerator, LVariablesNode);
      ACodeGenerator.EmitLn();
    end;
    
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
    
    // Then generate implementation in this cpp file
    // Only process IMPLEMENTATION section - INTERFACE is already in header
    for LI := 0 to LChildren.Count - 1 do
    begin
      LChild := LChildren.Items[LI];
      if not (LChild is TJSONObject) then
        Continue;
      
      LChildObj := LChild as TJSONObject;
      LNodeType := ACodeGenerator.GetNodeType(LChildObj);
      
      // Only generate implementations from IMPLEMENTATION section
      if LNodeType = 'IMPLEMENTATION' then
        NitroPascal.CodeGen.Declarations.GenerateFunctionDeclarations(ACodeGenerator, ACodeGenerator.GetNodeChildren(LChildObj));
    end;
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
  
  // Generate USES clause includes (ALWAYS - for all types of files)
  LUsesNode := ACodeGenerator.FindNodeByType(LChildren, 'USES');
  if LUsesNode <> nil then
  begin
    GenerateUsesIncludes(ACodeGenerator, LUsesNode);
    ACodeGenerator.EmitLn();
  end;
  
  // Check if this has INTERFACE section (UNIT) or just VARIABLES (PROGRAM)
  LInterfaceNode := ACodeGenerator.FindNodeByType(LChildren, 'INTERFACE');
  LHasInterface := LInterfaceNode <> nil;
  
  if LHasInterface then
  begin
    // UNIT: Generate type declarations and function declarations from INTERFACE
    LChildren := ACodeGenerator.GetNodeChildren(LInterfaceNode);
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
      
      // Track forward declarations before generating function declarations
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
      
      // Second pass: Generate function declarations
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
          NitroPascal.CodeGen.Declarations.GenerateFunctionDeclaration(ACodeGenerator, LChildObj);
          ACodeGenerator.EmitLn();
        end;
      end;
    end;
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
          NitroPascal.CodeGen.Declarations.GenerateFunctionDeclaration(ACodeGenerator, LChildObj);
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
