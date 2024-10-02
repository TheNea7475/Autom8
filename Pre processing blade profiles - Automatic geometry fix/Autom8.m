function Autom8(Parameters)

    arguments
    Parameters struct
    end

%% Debug suppressing and variables/pointers cleaning

%#ok<*UNRCH>

close all
fclose all;

%% Adding Functions folder to path

FunctionsDir="Functions/";
addpath(FunctionsDir)

%% All parameters tuning and explanation

%save locations and folder names
Filename=Parameters.FileName;
DatabasePath=strcat(Filename,".mat");
PolarsDir="Polars\\";
AirfsDir="Profiles/";
GraphsDir="Graphs/";
ProfilesAerodinamicDataDir="PAD/";
xfoilDir="xfoil\\";
BenchmarkAeroacousticDir="aeroacoustic benchmark graphs/";
gifFile="Sequence.gif";
STLPath="STL/"+Parameters.StlPath;
LogsPath="Logs/"+Parameters.LogsFileName+".txt";

%External factors, not tied to geometry shape
range_rpm=Parameters.range_rpm;
Soundspeed=Parameters.Soundspeed;
UnitFactor=Parameters.uf;
ni=Parameters.ni;

%Modules running flags
ExtractProfiles=Parameters.ExtractorBool;
GenerateXfoilDatabase=Parameters.XfoilDbBool;
RunDatabaseFiller=Parameters.DbFillerBool;

% Profile extractor options
Steps=Parameters.Steps;     %Number of slices
cutoff=Parameters.cutoff;   %Radial cut percentage before root. Avoid unnecessary geometries
TrailCutPerc=Parameters.TrailCutPerc;%Trail cut in a 2D profile
Delta=Parameters.Delta; %Radial scanning radius percentage

%Xfoil database options
DebugLogXfoil=Parameters.dbxf;%chose if xfoil should open new windows and log its output into console (Only for debug, leave it false to avoid crash when not converging)
killtime_s=Parameters.killtime;
dbdens=Parameters.dbdens; % >4 recommended
    aDensity=dbdens;
    MachDensity=dbdens;
    ReDensity=dbdens;
n_iter=Parameters.niter;%see xfoil manual
ncrit=Parameters.ncrit;%see xfoil manual

% Database filler options
RemovingTreshold=Parameters.rmt;%If number of valid values in a row is less than this the profile is removed from interpolation. Minimum supported 2 (very raw interpolation, max Row size
PercTreshold=Parameters.perct;%Additional check, to interpolate on more consistent rows. If percentage of nans value is above this percentage skip this interpolation. Set to 100 to turn this check off. Low values might cause everything to be discarded.

% Folder checker
FolderWait=0.1;%Time to wait after each print, just for logs reading facility
FolderCheck=FolderManager(Steps,ExtractProfiles,gifFile,GenerateXfoilDatabase,PolarsDir,AirfsDir,GraphsDir,ProfilesAerodinamicDataDir,xfoilDir,BenchmarkAeroacousticDir,FunctionsDir,STLPath,DatabasePath,aDensity,ReDensity,MachDensity,FolderWait);%Returns a structure with info about paths and files position


%% start timing
tic

%Preparing logs file
diary(LogsPath)

%% Running section



%Profile extractor
if ExtractProfiles && FolderCheck.stl && FolderCheck.functions
    fprintf("Running the profile extractor...\n")
    CompletePlotData=GeometryExtractor_fast(STLPath,AirfsDir,ProfilesAerodinamicDataDir,Steps,Delta,range_rpm,UnitFactor,Soundspeed,ni,cutoff,TrailCutPerc);

    %Adding PAD data to database so it wont need other stuff when running
    %polar
    InsertPadInDatabase(DatabasePath,ProfilesAerodinamicDataDir,AirfsDir);

    %Adding Profiles plotting data into Database
    if not(isempty(CompletePlotData.PlotData))
    InsertPlotDataInDatabase(DatabasePath,CompletePlotData);
    end
   
end

%Xf database
if GenerateXfoilDatabase && FolderCheck.bladedet && FolderCheck.xfoil && FolderCheck.functions
    fprintf("Running the aerodinamic database manager with xfoil...\n")
    FolderCheck.dbmanager=DbManagerForXfoil(AirfsDir,PolarsDir,xfoilDir,aDensity,ReDensity,MachDensity,killtime_s,DatabasePath,DebugLogXfoil,ncrit,n_iter);
end

%Database filler
if RunDatabaseFiller && FolderCheck.db
    fprintf("Running database filler with interpolation...\n")
    FillDatabase(DatabasePath,RemovingTreshold,PercTreshold)
end

%% Function end operation
%End timing
t=toc;

fprintf("Code execution completed\nGeometry Extraction time (s): %d\n",t);
diary off
end