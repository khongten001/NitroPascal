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
  NitroPascal.Utils,
  NitroPascal.BuildSettings;

type
  { TNPJSONWriter }
  TNPJSONWriter = class
  strict private
    FIndexer: TProjectIndexer;
    FSymbolMap: TDictionary<string, TSyntaxNode>;
    FUnitHeaders: TDictionary<string, TArray<string>>;  // Track unit name -> headers
    FUnitLinks: TDictionary<string, TArray<string>>;    // Track unit name -> link libraries
    FUnitModulePaths: TDictionary<string, TArray<string>>;   // Track unit name -> module paths
    FUnitIncludePaths: TDictionary<string, TArray<string>>;  // Track unit name -> include paths
    FUnitLibraryPaths: TDictionary<string, TArray<string>>;  // Track unit name -> library paths
    
    procedure BuildSymbolMap;
    function GetUsedUnits(ANode: TSyntaxNode): TStringList;
    function ResolveIdentifier(const AName: string; 
      AUsedUnits: TStrings): TJSONObject;
    
    procedure NodeToJSON(ANode: TSyntaxNode; AOutput: TJSONArray; 
      AUsedUnits: TStrings);
    procedure SerializeUnit(AUnitInfo: TProjectIndexer.TUnitInfo; 
      AOutput: TJSONArray);
    procedure PreprocessUnitsForHeaders;
    
  public
    constructor Create(const AIndexer: TProjectIndexer);
    destructor Destroy; override;
    
    procedure SetUnitHeaders(const AUnitName: string; const AHeaders: TArray<string>);
    procedure SetUnitLinks(const AUnitName: string; const ALinks: TArray<string>);
    procedure SetUnitModulePaths(const AUnitName: string; const APaths: TArray<string>);
    procedure SetUnitIncludePaths(const AUnitName: string; const APaths: TArray<string>);
    procedure SetUnitLibraryPaths(const AUnitName: string; const APaths: TArray<string>);
    
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
    
    procedure SetupDefines(const ABuildSettings: TNPBuildSettings);
    
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
  System.IOUtils,
  NitroPascal.Preprocessor;

{ TNPJSONWriter }

constructor TNPJSONWriter.Create(const AIndexer: TProjectIndexer);
begin
  inherited Create;
  FIndexer := AIndexer;
  FSymbolMap := TDictionary<string, TSyntaxNode>.Create;
  FUnitHeaders := TDictionary<string, TArray<string>>.Create;
  FUnitLinks := TDictionary<string, TArray<string>>.Create;
  FUnitModulePaths := TDictionary<string, TArray<string>>.Create;
  FUnitIncludePaths := TDictionary<string, TArray<string>>.Create;
  FUnitLibraryPaths := TDictionary<string, TArray<string>>.Create;
  BuildSymbolMap;
end;

destructor TNPJSONWriter.Destroy;
begin
  FUnitLibraryPaths.Free;
  FUnitIncludePaths.Free;
  FUnitModulePaths.Free;
  FUnitLinks.Free;
  FUnitHeaders.Free;
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

procedure TNPJSONWriter.SetUnitHeaders(const AUnitName: string; const AHeaders: TArray<string>);
begin
  FUnitHeaders.AddOrSetValue(AUnitName, AHeaders);
end;

procedure TNPJSONWriter.SetUnitLinks(const AUnitName: string; const ALinks: TArray<string>);
begin
  FUnitLinks.AddOrSetValue(AUnitName, ALinks);
end;

procedure TNPJSONWriter.SetUnitModulePaths(const AUnitName: string; const APaths: TArray<string>);
begin
  FUnitModulePaths.AddOrSetValue(AUnitName, APaths);
end;

procedure TNPJSONWriter.SetUnitIncludePaths(const AUnitName: string; const APaths: TArray<string>);
begin
  FUnitIncludePaths.AddOrSetValue(AUnitName, APaths);
end;

procedure TNPJSONWriter.SetUnitLibraryPaths(const AUnitName: string; const APaths: TArray<string>);
begin
  FUnitLibraryPaths.AddOrSetValue(AUnitName, APaths);
end;

procedure TNPJSONWriter.PreprocessUnitsForHeaders;
var
  LUnitInfo: TProjectIndexer.TUnitInfo;
  LUnitSettings: TNPBuildSettings;
  LPreprocessor: TNPPreprocessor;
begin
  // Preprocess each unit to collect {$INCLUDE_HEADER} and {$LINK} directives
  for LUnitInfo in FIndexer.ParsedUnits do
  begin
    if TFile.Exists(LUnitInfo.Path) then
    begin
      // Create temporary BuildSettings for this unit
      LUnitSettings := TNPBuildSettings.Create();
      try
        // Preprocess the unit file to collect directives
        LPreprocessor := TNPPreprocessor.Create(nil);
        try
          LPreprocessor.ProcessFile(LUnitInfo.Path, LUnitSettings);
          
          // Store collected headers and link libraries for this unit
          SetUnitHeaders(LUnitInfo.Name, LUnitSettings.GetIncludeHeaders());
          SetUnitLinks(LUnitInfo.Name, LUnitSettings.GetLinkLibraries());
          
          // Store collected paths for this unit
          SetUnitModulePaths(LUnitInfo.Name, LUnitSettings.GetModulePaths());
          SetUnitIncludePaths(LUnitInfo.Name, LUnitSettings.GetIncludePaths());
          SetUnitLibraryPaths(LUnitInfo.Name, LUnitSettings.GetLibraryPaths());
        finally
          LPreprocessor.Free();
        end;
      finally
        LUnitSettings.Free();
      end;
    end;
  end;
end;

procedure TNPJSONWriter.SerializeUnit(AUnitInfo: TProjectIndexer.TUnitInfo; 
  AOutput: TJSONArray);
var
  LUnitObj: TJSONObject;
  LUsedUnits: TStringList;
  LNodeArray: TJSONArray;
  LHeaders: TArray<string>;
  LHeadersArray: TJSONArray;
  LHeader: string;
  LLinks: TArray<string>;
  LLinksArray: TJSONArray;
  LLink: string;
  LModulePaths: TArray<string>;
  LModulePathsArray: TJSONArray;
  LIncludePaths: TArray<string>;
  LIncludePathsArray: TJSONArray;
  LLibraryPaths: TArray<string>;
  LLibraryPathsArray: TJSONArray;
  LPath: string;
begin
  if AUnitInfo.SyntaxTree = nil then
    Exit;
  
  LUnitObj := TJSONObject.Create;
  LUnitObj.AddPair('name', AUnitInfo.Name);
  LUnitObj.AddPair('path', AUnitInfo.Path);
  
  // Add include headers if any exist for this unit
  if FUnitHeaders.TryGetValue(AUnitInfo.Name, LHeaders) and (Length(LHeaders) > 0) then
  begin
    LHeadersArray := TJSONArray.Create;
    for LHeader in LHeaders do
      LHeadersArray.Add(LHeader);
    LUnitObj.AddPair('includeHeaders', LHeadersArray);
  end;
  
  // Add link libraries if any exist for this unit
  if FUnitLinks.TryGetValue(AUnitInfo.Name, LLinks) and (Length(LLinks) > 0) then
  begin
    LLinksArray := TJSONArray.Create;
    for LLink in LLinks do
      LLinksArray.Add(LLink);
    LUnitObj.AddPair('linkLibraries', LLinksArray);
  end;
  
  // Add module paths if any exist for this unit
  if FUnitModulePaths.TryGetValue(AUnitInfo.Name, LModulePaths) and (Length(LModulePaths) > 0) then
  begin
    LModulePathsArray := TJSONArray.Create;
    for LPath in LModulePaths do
      LModulePathsArray.Add(LPath);
    LUnitObj.AddPair('modulePaths', LModulePathsArray);
  end;
  
  // Add include paths if any exist for this unit
  if FUnitIncludePaths.TryGetValue(AUnitInfo.Name, LIncludePaths) and (Length(LIncludePaths) > 0) then
  begin
    LIncludePathsArray := TJSONArray.Create;
    for LPath in LIncludePaths do
      LIncludePathsArray.Add(LPath);
    LUnitObj.AddPair('includePaths', LIncludePathsArray);
  end;
  
  // Add library paths if any exist for this unit
  if FUnitLibraryPaths.TryGetValue(AUnitInfo.Name, LLibraryPaths) and (Length(LLibraryPaths) > 0) then
  begin
    LLibraryPathsArray := TJSONArray.Create;
    for LPath in LLibraryPaths do
      LLibraryPathsArray.Add(LPath);
    LUnitObj.AddPair('libraryPaths', LLibraryPathsArray);
  end;
  
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
    // Preprocess all units to collect their {$INCLUDE_HEADER} and {$LINK} directives
    LWriter.PreprocessUnitsForHeaders();
    
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

procedure TNPPasToJSON.SetupDefines(const ABuildSettings: TNPBuildSettings);
var
  LDefinesList: TStringList;
  LParts: TArray<string>;
  LArch: string;
  LOS: string;
begin
  LDefinesList := TStringList.Create();
  try
    // 1. Always add NITROPASCAL define
    LDefinesList.Add('NITROPASCAL');
    
    // 2. Add DEBUG or RELEASE based on optimization mode
    if ABuildSettings.Optimize = omDebug then
      LDefinesList.Add('DEBUG')
    else
      LDefinesList.Add('RELEASE');
    
    // 3. Add CONSOLE_APP or GUI_APP based on app type
    if ABuildSettings.AppType = atConsole then
      LDefinesList.Add('CONSOLE_APP')
    else
      LDefinesList.Add('GUI_APP');
    
    // 4. Parse target triplet for platform defines
    if (not ABuildSettings.Target.IsEmpty) and 
       (ABuildSettings.Target.ToLower <> 'native') then
    begin
      // Parse already-validated triplet: arch-os[-abi]
      LParts := ABuildSettings.Target.ToLower.Split(['-']);
      
      if Length(LParts) >= 2 then
      begin
        LArch := LParts[0];
        LOS := LParts[1];
        
        // Architecture defines
        if (LArch = 'x86_64') or (LArch = 'amd64') then
        begin
          LDefinesList.Add('CPUX64');
          if LOS.Contains('windows') then
            LDefinesList.Add('WIN64');
        end
        else if (LArch = 'i386') or (LArch = 'i686') then
        begin
          LDefinesList.Add('CPU386');
          if LOS.Contains('windows') then
            LDefinesList.Add('WIN32');
        end
        else if (LArch = 'aarch64') or LArch.Contains('arm64') then
        begin
          LDefinesList.Add('CPUARM64');
          LDefinesList.Add('ARM64');
        end;
        
        // OS defines
        if LOS.Contains('windows') then
        begin
          LDefinesList.Add('MSWINDOWS');
          LDefinesList.Add('WINDOWS');
        end
        else if LOS.Contains('linux') then
        begin
          LDefinesList.Add('LINUX');
          LDefinesList.Add('POSIX');
          LDefinesList.Add('UNIX');
        end
        else if LOS.Contains('darwin') or LOS.Contains('macos') then
        begin
          LDefinesList.Add('MACOS');
          LDefinesList.Add('DARWIN');
          LDefinesList.Add('POSIX');
          LDefinesList.Add('UNIX');
        end;
      end;
    end;
    
    // Convert list to semicolon-separated string for DelphiAST
    FDefines := string.Join(';', LDefinesList.ToStringArray());
    
  finally
    LDefinesList.Free();
  end;
end;

function TNPPasToJSON.Parse(const AFilename: string; 
  var AErrorManager: TNPErrorManager): Boolean;
var
  LIndexer: TProjectIndexer;
  LProblem: TProjectIndexer.TProblemInfo;
  LDescription: string;
  LParts: TArray<string>;
  LLine: Integer;
  LCol: Integer;
  LErrorMessage: string;
  LLoopIndex: Integer;
  LColonPos: Integer;
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
      
      // Check for parsing errors from DelphiAST
      if LIndexer.Problems.Count > 0 then
      begin
        for LLoopIndex := 0 to LIndexer.Problems.Count - 1 do
        begin
          LProblem := LIndexer.Problems[LLoopIndex];
          LDescription := LProblem.Description;
          LLine := 0;
          LCol := 0;
          LErrorMessage := LDescription;
          
          // Parse "Line X, Column Y: message" format
          LParts := LDescription.Split(['Line ', ', Column ', ': ']);
          if Length(LParts) >= 3 then
          begin
            if TryStrToInt(LParts[1], LLine) and 
               TryStrToInt(LParts[2], LCol) then
            begin
              // Extract the actual error message (everything after ": ")
              LColonPos := Pos(': ', LDescription);
              if LColonPos > 0 then
                LErrorMessage := Copy(LDescription, LColonPos + 2, MaxInt)
              else
                LErrorMessage := LDescription;
            end;
          end;
          
          AErrorManager.AddError(NP_ERROR_COMPILATION, LLine, LCol, 
            LProblem.FileName, LErrorMessage);
        end;
        Exit;  // Return False
      end;
      
      { Convert to JSON }
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
