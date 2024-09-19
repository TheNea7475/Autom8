function Autom8(Filename,ExtractProfiles,GenerateXfoilDatabase,RunChordTwistDist,RunDatabaseFiller,RunInterpolationPolar)

    arguments
    Filename string  % MC: I added an additional argument to save the structure RotorDatabase with a specific name. This should be extended for the other saves; graphs; airfoils; plots.  
    ExtractProfiles logical 
    GenerateXfoilDatabase logical
    RunChordTwistDist logical
    RunDatabaseFiller logical
    RunInterpolationPolar logical
    end

 

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
STLDir="STL/";
DatabasePath=strcat(Filename,".mat");
gifFile="Sequence.gif";


%% constants and parameters
%now into dlg to prevent incorrect unit factor

Cs=PresetDlg({'MinRpm','MaxRpm','Soundspeed','UnitFactor','ni'},{'2800','3200','330','1e-3','1.5e-5'});

range_rpm=str2double([Cs.MinRpm,Cs.MaxRpm]); %rpm
Soundspeed=str2double(Cs.Soundspeed); %m/s
UnitFactor=str2double(Cs.UnitFactor);   %mm default
ni=str2double(Cs.ni);   %I.S. default

%% Main options, choose wich module to run (now in func args)
%its heavily suggested to run all the modules togheter

%generate profiles from stl. Also runs geometry manual fixer

%ExtractProfiles;


%whether to generate database with xfoil or not

%GenerateXfoilDatabase;


%whether to run the twist and chord distribution comparation tool

%RunChordTwistDist;


%Whether to run database filler

%RunDatabaseFiller;


%Whether to run interpolation polar

%RunInterpolationPolar;

%% Profile extractor options

GenerateGif=false;

HoldGraphs=false;

% a detailed debug graph with numbers on every point
DebugGraphNumbered=false;

%Number of slices
Steps=20;

Delta=2; %Radial scanning radius percentage

%% Xfoil database options

%chose if xfoil should open new windows and log its output into console
%(Only for debug, leave it false to avoid crash when not converging)
DebugLogXfoil=false;

killtime_s=4;   %In seconds, must be > 1 and multiple of 1

% >4 recommended
%Must all be the same or interp3 wont work
aDensity=10;
MachDensity=10;
ReDensity=10;

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

%Skip stl check if theres no profile extracting need
if ExtractProfiles
    Value=PresetDlg("Stl_path","STL/5.STL");
    STLPath=string(Value.Stl_path);
else
    STLPath="";
end

%Returns a structure with info about paths and files position
FolderCheck=FolderManager(Steps,ExtractProfiles,gifFile,GenerateXfoilDatabase,RunChordTwistDist,RunInterpolationPolar,PolarsDir,AirfsDir,GraphsDir,ProfilesAerodinamicDataDir,xfoilDir,BenchmarkAeroacousticDir,FunctionsDir,STLPath,DatabasePath,aDensity,ReDensity,MachDensity,FolderWait);

tic
%% Running section


%Profile extractor
if ExtractProfiles && FolderCheck.stl && FolderCheck.functions
    disp("Running the profile extractor...")
    GeometryExtractor_fast(STLPath,AirfsDir,GraphsDir,ProfilesAerodinamicDataDir,GenerateGif,Steps,Delta,HoldGraphs,DebugGraphNumbered,range_rpm,UnitFactor,Soundspeed,ni);

    %Adding PAD data to database so it wont need other stuff when running
    %polar
    InsertPadInDatabase(DatabasePath,ProfilesAerodinamicDataDir,AirfsDir);

end

%Xf database
if GenerateXfoilDatabase && FolderCheck.bladedet && FolderCheck.xfoil && FolderCheck.functions
    disp("Running the aerodinamic database manager with xfoil...")
    FolderCheck.dbmanager=DbManagerForXfoil(AirfsDir,PolarsDir,xfoilDir,aDensity,ReDensity,MachDensity,killtime_s,DatabasePath,DebugLogXfoil,ncrit,n_iter);
end

%ChordTwistdistibution
if RunChordTwistDist && FolderCheck.pad && FolderCheck.csv && FolderCheck.functions
    disp("Running twist and chord distribution extractor...")
    FolderCheck.twist=TwistAndChordDist(ProfilesAerodinamicDataDir,BenchmarkAeroacousticDir); 
end

%Database filler
if RunDatabaseFiller && FolderCheck.db
    fprintf("Running database filler with interpolation...\n")
    FillDatabase(DatabasePath,RemovingTreshold,PercTreshold)
end

%Interpolation polar
if RunInterpolationPolar && FolderCheck.pad && FolderCheck.db && FolderCheck.bladedet && FolderCheck.functions

    if RunInterpolationPolar && not(ExtractProfiles)
        fprintf(2,"\nBe sure to have PAD folder synced with database content.\nDo not use the polar function if you started a new profile extraction and the database isn't updated!\n\n")
        pause(2)
    end

    load(DatabasePath);
    disp("Running interpolation polar calulator..")
    PolarMenu(Database);
end


%Autom8 function end
t=toc;

disp('Geometry Extraction time (s):')
disp(t)
end