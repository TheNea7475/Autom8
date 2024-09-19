function suc=FolderManager(ProfilesNumber,ExtractProfiles,gifFile,GenerateXfoilDatabase,RunCTDist,RunInterpolationPolar,PolarsDir,AirfsDir,GraphsDir,ProfilesAerodinamicDataDir,xfoilDir,BenchmarkAeroacousticDir,FunctionsDir,STLPath,DatabasePath,aDensity,ReDensity,MachDensity,FolderWait)
%% error structure for reporting to main run module

suc.csv=true;
suc.xfoil=true;
suc.bladedet=true;
suc.pad=true;
suc.stl=true;
suc.db=true;
suc.functions=true;
    
%% Variables useful for checking

DirPaths=[PolarsDir,AirfsDir,GraphsDir,ProfilesAerodinamicDataDir,xfoilDir,BenchmarkAeroacousticDir];

    %% Checking existence of every folder and file needed, if it doesnt exist create one
   

    %directories
    
    for Path=DirPaths
        if not(exist(Path,"dir"))
            disp("Missing folder "+Path+", creating one")
            mkdir(Path)
        else
            disp("Folder "+Path+" found, proceeding..")
        end
        pause(FolderWait)
    end


    %files
    if not(exist(DatabasePath,"file"))

        disp("Rotor database not found, creating rotor database..")

        Database=struct();
        Database.CL=zeros(ProfilesNumber,aDensity,ReDensity,MachDensity);
        Database.CD=zeros(ProfilesNumber,aDensity,ReDensity,MachDensity);
        
        save(DatabasePath,"Database");

    end

    %% checking existence of crucial files for every module, that cannot be created by this module


    %General
    if not(exist(FunctionsDir,"dir"))
        fprintf("Functions directory not found! Correct execution not possible.")
        suc.functions=false;
    else
        fprintf("Functions directory found...\n")
        pause(FolderWait)
    end


    %Chord twist distribution
    if RunCTDist

        if not(exist(BenchmarkAeroacousticDir+"Chord.csv","file") && exist(BenchmarkAeroacousticDir+"Twist.csv","file"))
            disp("Missing reference csv files")
            suc.csv=false;
        else
            disp("Csv files found, proceeding..")
        end
        pause(FolderWait)

        if not(exist(ProfilesAerodinamicDataDir+"Profile1.txt","file"))
            disp("Missing profiles aerodinamic data files, run the profile extractor first!")
            suc.pad=false;
        else
            disp("Profiles aerodinamic data found, proceeding..")
        end
        pause(FolderWait)

    end


    % xfoil database
    if GenerateXfoilDatabase
        if not(exist(xfoilDir+"xfoil.exe","file"))
            disp("xfoil not found in "+xfoilDir)
            suc.xfoil=false;
        else
            disp("Xfoil found, proceeding..")
        end
        pause(FolderWait)

        if not(exist("Blade details.txt","file")) && not(ExtractProfiles)
            fprintf(2,"'Blade details.txt' file not found, run profile extractor or write some!\n")
            suc.bladedet=false;
        elseif not(exist("Blade details.txt","file")) && (ExtractProfiles)
            fprintf("Generating Blade details.txt\n")
            pause(FolderWait)
        else
            fprintf("'Blade details.txt' found...\n")
            pause(FolderWait)
        end
    end


    % profile extractor
    if ExtractProfiles
        if not(exist(STLPath,"file"))
            suc.stl=false;
            disp("Stl file not found: "+STLPath)
        else
            disp("Stl file found, proceeding...")
        end

        pause(FolderWait)
    end
    

    %Interpolation polar
    if RunInterpolationPolar
        if exist(DatabasePath,"file")
            fprintf("Rotor database found..\n")
        else
            fprintf("Rotor database not found, run database generator first!\n")
            suc.db=false;
        end
    end

    %% Clearing folder and files for execution


    %%Profile extractor cleaner
    if ExtractProfiles

        txtdirs=[ProfilesAerodinamicDataDir,AirfsDir];
       
        for dir=txtdirs
            delete(dir+"*.txt");
            disp(dir+" cleared...")
        end

        delete(GraphsDir+"*.png");
        disp(GraphsDir+" cleared...")

        if isfile("Blade details.txt")
            delete("Blade details.txt");
            fprintf("Blade details cleared..\n")
        end

        if isfile(gifFile)
            delete(gifFile);
        end


        pause(FolderWait)
    end


    %Xfoil database cleaner
    if GenerateXfoilDatabase
        
        
        delete(PolarsDir+"*.txt");
        fprintf("%s cleared...\n",PolarsDir)
        pause(FolderWait)

        if exist(DatabasePath,"file")
            Database=struct();
            Database.CL=zeros(ProfilesNumber,aDensity,ReDensity,MachDensity);
            Database.CD=zeros(ProfilesNumber,aDensity,ReDensity,MachDensity);
            Database.grid.ProfilesNamesArray=[];
            Database.grid.a=[];
            Database.grid.Re=[];
            Database.grid.Mach=[];
            delete(DatabasePath)
            save(DatabasePath,"Database")
            disp("Resetting rotor database..")
            pause(FolderWait)
        end

        
    end

end