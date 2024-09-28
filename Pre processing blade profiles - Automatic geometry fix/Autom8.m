function Autom8(AppParameters)

    arguments
    AppParameters struct
    end

    %Conversion from AppData
    Filename=AppParameters.FileName;
    ExtractProfiles=AppParameters.ExtractorBool;
    GenerateXfoilDatabase=AppParameters.XfoilDbBool;
    RunDatabaseFiller=AppParameters.DbFillerBool;
    STLPath="STL/"+AppParameters.StlPath;
 

%% Debug suppressing and variables/pointers cleaning

%#ok<*UNRCH>

close all
fclose all;

%% Adding Functions folder to path

FunctionsDir="Functions/";
addpath(FunctionsDir)

%% Save paths

PolarsDir="Polars\\";
AirfsDir="Profiles/";
GraphsDir="Graphs/";
ProfilesAerodinamicDataDir="PAD/";
xfoilDir="xfoil\\";
BenchmarkAeroacousticDir="aeroacoustic benchmark graphs/";
DatabasePath=strcat(Filename,".mat");
gifFile="Sequence.gif";


%% constants and parameters

range_rpm=AppParameters.range_rpm;
Soundspeed=AppParameters.Soundspeed;
UnitFactor=AppParameters.uf;
ni=AppParameters.ni;

%% Profile extractor options

%Number of slices
Steps=AppParameters.Steps;

%Radial cut percentage before root. Avoid unnecessary geometries
cutoff=AppParameters.cutoff;

%Trail cut in a 2D profile
TrailCutPerc=AppParameters.TrailCutPerc;

Delta=AppParameters.Delta; %Radial scanning radius percentage

%% Xfoil database options

%chose if xfoil should open new windows and log its output into console
%(Only for debug, leave it false to avoid crash when not converging)
DebugLogXfoil=AppParameters.dbxf;

killtime_s=AppParameters.killtime;

% >4 recommended
%Must all be the same or interp3 wont work
dbdens=AppParameters.dbdens;
aDensity=dbdens;
MachDensity=dbdens;
ReDensity=dbdens;

n_iter=AppParameters.niter;
ncrit=AppParameters.ncrit;

%% Database filler options

%If number of valid values in a row is less than this the profile is removed from
%interpolation. Minimum supported 2 (very raw interpolation) to Row size
RemovingTreshold=AppParameters.rmt;

%Additional check, to interpolate on more consistent rows. If percentage of nans
%value is above this percentage skip this interpolation. Set to 100 to
%turn this check off. Low values might cause everything to be discarded.
PercTreshold=AppParameters.perct;


%% Folder checker

%Time to wait after each print, just for logs reading facility
FolderWait=0.1;

%Returns a structure with info about paths and files position
FolderCheck=FolderManager(Steps,ExtractProfiles,gifFile,GenerateXfoilDatabase,PolarsDir,AirfsDir,GraphsDir,ProfilesAerodinamicDataDir,xfoilDir,BenchmarkAeroacousticDir,FunctionsDir,STLPath,DatabasePath,aDensity,ReDensity,MachDensity,FolderWait);

tic
%% Running section


%Profile extractor
if ExtractProfiles && FolderCheck.stl && FolderCheck.functions
    disp("Running the profile extractor...")
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
    disp("Running the aerodinamic database manager with xfoil...")
    FolderCheck.dbmanager=DbManagerForXfoil(AirfsDir,PolarsDir,xfoilDir,aDensity,ReDensity,MachDensity,killtime_s,DatabasePath,DebugLogXfoil,ncrit,n_iter);
end

%Database filler
if RunDatabaseFiller && FolderCheck.db
    fprintf("Running database filler with interpolation...\n")
    FillDatabase(DatabasePath,RemovingTreshold,PercTreshold)
end


%Autom8 function end
t=toc;

disp('Geometry Extraction time (s):')
disp(t)
end