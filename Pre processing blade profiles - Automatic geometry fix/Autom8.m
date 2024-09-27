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
%now into dlg to prevent incorrect unit factor

Cs=PresetDlg({'MinRpm','MaxRpm','Soundspeed','UnitFactor','ni'},{'2800','3200','330','1e-3','1.5e-5'});

range_rpm=str2double([Cs.MinRpm,Cs.MaxRpm]); %rpm
Soundspeed=str2double(Cs.Soundspeed); %m/s
UnitFactor=str2double(Cs.UnitFactor);   %mm default
ni=str2double(Cs.ni);   %I.S. default

%% Profile extractor options

%Number of slices
Steps=AppParameters.Steps;

Delta=AppParameters.Delta; %Radial scanning radius percentage

%% Xfoil database options

%chose if xfoil should open new windows and log its output into console
%(Only for debug, leave it false to avoid crash when not converging)
DebugLogXfoil=false;

killtime_s=4;   %In seconds, must be > 1 and multiple of 1

% >4 recommended
%Must all be the same or interp3 wont work
aDensity=5;
MachDensity=5;
ReDensity=5;

n_iter=300;
ncrit=9;

%% Database filler options

%If number of valid values in a row is less than this the profile is removed from
%interpolation. Minimum supported 2 (very raw interpolation) to Row size
RemovingTreshold=2;

%Additional check, to interpolate on more consistent rows. If percentage of nans
%value is above this percentage skip this interpolation. Set to 100 to
%turn this check off. Low values might cause everything to be discarded.
PercTreshold=100;


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
    CompletePlotData=GeometryExtractor_fast(STLPath,AirfsDir,ProfilesAerodinamicDataDir,Steps,Delta,range_rpm,UnitFactor,Soundspeed,ni);

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