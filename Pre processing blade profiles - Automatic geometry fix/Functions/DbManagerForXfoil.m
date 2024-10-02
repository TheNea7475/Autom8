
%% main function definition
    
function status=DbManagerForXfoil(ProfilesDir,PolarsDir,xfoilDir,aDensity,ReDensity,MachDensity,killtime, DatabasePath,LogXfoilDebug,ncrit,n_iter)
    
    arguments
    ProfilesDir string
    PolarsDir string
    xfoilDir string
    aDensity double
    ReDensity double
    MachDensity double
    killtime int32
    DatabasePath string
    LogXfoilDebug logical
    ncrit int64
    n_iter int64
    end
        

        %How many xfoil calls can go wrong before declaring an entire
        %profile broken. 2 rows seems reasonable
        MaxNanStreak=aDensity*2;

        %getting every profile, extracting the paths
        Profiles = dir(fullfile(ProfilesDir, '*.txt'));

        %preallocating an array for profile names
        ProfilesNamesArray=strings([1,length(Profiles)]);
        
        
        for i=1:length(Profiles)
            [~,ProfilesNamesArray(i),~] = fileparts(ProfilesDir+Profiles(i).name);
        end


        % Extract max Re,Mach,R
        BladeDet=ReadBladeDet();
    

        maxRe=BladeDet.maxRe;
        maxR=BladeDet.maxR; %#ok<NASGU>  Not useful actually, but might be
        maxMach=BladeDet.maxMach;
        
        
        %% This is used in overeshoot. Every profile uses all the ranges
        
        a_range=linspace(-5,12,aDensity);
        Re_range=linspace(maxRe*0.05,maxRe*1.05,ReDensity);
        Mach_range=linspace(0,maxMach*1.05,MachDensity);

        dbDensity=aDensity*ReDensity*MachDensity;
        
        %% calling xfoil
        
        %This function builds the entire database
        status=BuildPolars(ProfilesDir,ProfilesNamesArray,PolarsDir,xfoilDir,a_range,Re_range,Mach_range,killtime,dbDensity,DatabasePath,LogXfoilDebug,MaxNanStreak,ncrit,n_iter);

end


%% xfoil launcher

function status=BuildPolars(ProfilesDir,ProfilesNamesArray,PolarsDir,xfoilDir,a_range,Re_range,Mach_range, killtime,dbDensity,DatabasePath,LogXfoilDebug,MaxNanStreak,ncrit,n_iter)


    ProfilesNumber=length(ProfilesNamesArray);
    
    profilecounter=0; %to track success rate for every profile, cycling into profilestruct

    progress=0; %counter for displaying total progress in db generation

    %not needed cause polars should be deleted after reading
    %but prevents problems with writing to the same file
    profileOperations=0;    %#ok<NASGU> %counter to name the writing files polars different eachother,
    
    %To store info about every profile calculus and its success rate
    ProfileStruct=struct();

    %Loading aerodinamic database
    load(DatabasePath); %#ok<LOAD>

    %adding to database the grid necessary for interpolation
    
    Database.grid.ProfilesNamesArray=ProfilesNamesArray;
    Database.grid.a=a_range;
    Database.grid.Re=Re_range;
    Database.grid.Mach=Mach_range;

    % Running for every combination of dimensions, for every profile

    for ProfileName = ProfilesNamesArray

        profilecounter=profilecounter+1;
        fprintf("\n--Starting database generation for %s--\n\n",ProfileName);
        ProfilePath = sprintf("%s%s.txt",ProfilesDir,ProfileName);

        %Resetting counter for every profile
        profileOperations=0;    

        %Initializing profile struct fields
        ProfileStruct(profilecounter).name=ProfileName;
        ProfileStruct(profilecounter).success=0;
        ProfileStruct(profilecounter).successPolar=0;
        ProfileStruct(profilecounter).nanStreak=0;

        for a = a_range
            for Re = Re_range
                for Mach = Mach_range

                    %Prevent running xfoil if profile is broken

                    if ProfileStruct(profilecounter).nanStreak < MaxNanStreak
                    
                        % Readying variables for input file

                        profileOperations = profileOperations +1;
                        PolarFilePath=sprintf("%s%s%d.txt", PolarsDir,ProfileName,profileOperations);

                        % Displaying total progress and info section

                        progress=progress+1;
                        percProgress=((progress/ ((dbDensity)*ProfilesNumber)) *100);
                        fprintf("Processing profile %s -alpha: %d -Re: %d -Mach: %d\nTotal progress: %.2f%% \n",ProfileName,a,Re,Mach,percProgress)

                        % calling xfoil with killtime set

                        XfoilSuccess=XfoilRunnerNoFile(killtime,xfoilDir,PolarFilePath,ProfilePath,LogXfoilDebug,a,Re,Mach,n_iter,ncrit);
                
                        % Reading formatted values in polar, with double check
                    
                        Values=Read1Polar(PolarFilePath,XfoilSuccess);

                    else

                        Values.alpha = NaN;
                        Values.CL = NaN;
                        Values.CD = NaN;
                        Values.CDp = NaN;
                        Values.CM = NaN;
                        Values.XTRT = NaN;
                        Values.XTRB = NaN;
                        Values.IsNaN=true;
                        XfoilSuccess=false;

                        fprintf(2,"Profile %s is mostly broken, skipping xfoil call\n",ProfileStruct(profilecounter).name)
                        

                        progress=progress+1;

                    end
                    %% adding data to database, in a matrix passing the grid and the ids
                    
                    Database=UpdateDb(a,Re,Mach,ProfileName,Database,Values);
                    
                    %% Success checks

                    %Se xfoil ha finito l'esecuzione
                    if XfoilSuccess
                        ProfileStruct(profilecounter).success=ProfileStruct(profilecounter).success + 1;
                    end

                    %Se la polare contiene dati validi (IsNaN is not a mehtod but a strct field that is tree or false)
                    if not(Values.IsNaN)
                        ProfileStruct(profilecounter).successPolar=ProfileStruct(profilecounter).successPolar +1;
                        ProfileStruct(profilecounter).nanStreak=0;
                    else
                        ProfileStruct(profilecounter).nanStreak=ProfileStruct(profilecounter).nanStreak+1;
                    end

                end %Mach loop


            end %Re loop


        end %Alpha loop

    end%Profile loop

    % Post 4x loop operations

    %info about completion rate for every profile
    for i=1:ProfilesNumber
        TaskCompletionPerc=(ProfileStruct(i).success/(dbDensity))*100;
        PolarFilledPerc=(ProfileStruct(i).successPolar/(dbDensity))*100;
        fprintf("Xfoil task completion success for %s: %.2f%% with %.2f%% correct polars\n",ProfileStruct(i).name,TaskCompletionPerc,PolarFilledPerc)
    end

    %Saving database
    save(DatabasePath,"Database")

    status=1;
end

%% Xfoil exe appropriate launcher

%best option so far for xfoil calling with killtime
%this calls the process, waits for it to complete, checking with a tick
%rate its status, and killing when exceeds killtime. status=0 for killed,
%status=1 for completion. Doesnt mean that polar is correctly built tho

%NOW MOVED INTO XFOILRUNNERNOFILE


%% Database creation and interaction functions

%Adding a value to database
function Database=UpdateDb(a,Re,Mach,ProfileName,Database,Values)

    a_range=Database.grid.a;
    Re_range=Database.grid.Re;
    Mach_range=Database.grid.Mach;
    ProfilesNamesArray=Database.grid.ProfilesNamesArray;


    %Getting indices for every variable in the 4D grid
    ai=find(a_range==a);
    Rei=find(Re_range==Re);
    Machi=find(Mach_range==Mach);
    Profi=find(ProfilesNamesArray==ProfileName);

    Database.CL(Profi,ai,Rei,Machi)=Values.CL;
    Database.CD(Profi,ai,Rei,Machi)=Values.CD;

end




%Returns a sructure with every value printed in a polar, all vales NaN if
%polar is corrupted
function Values=Read1Polar(PolarFilePath,XfoilSuccess)


    if XfoilSuccess
        
        Values=struct();
        PolarFilePointer = fopen(PolarFilePath, 'r');

        %This fires if xfoil does not build polar at all
        if PolarFilePointer==-1
            fprintf(2,"Polar file not found. This could be a geometry issue. Setting all values to NAN..\n\n")
            Values.alpha = NaN;
            Values.CL = NaN;
            Values.CD = NaN;
            Values.CDp = NaN;
            Values.CM = NaN;
            Values.XTRT = NaN;
            Values.XTRB = NaN;
            Values.IsNaN=true;
            return
        end

        %Get the last line
        for i=1:13
            line=fgetl(PolarFilePointer);
        end

        if line ~= -1
            
            numeri = textscan(line, '%f');

            Values.alpha = numeri{1}(1);
            Values.CL = numeri{1}(2);
            Values.CD = numeri{1}(3);
            Values.CDp = numeri{1}(4);
            Values.CM = numeri{1}(5);
            Values.XTRT = numeri{1}(6);
            Values.XTRB = numeri{1}(7);
            Values.IsNaN=false;
        
        %This fires if xfoil completes but polar is empty
        else
            fprintf(2,"Corrupted polars detected, SETTING ALL VALUES TO NAN, temporary solution..\n\n")
            Values.alpha = NaN;
            Values.CL = NaN;
            Values.CD = NaN;
            Values.CDp = NaN;
            Values.CM = NaN;
            Values.XTRT = NaN;
            Values.XTRB = NaN;
            Values.IsNaN=true;
        end

        fclose(PolarFilePointer);

    %This fires if xfoil is killed
    else
            fprintf(2,"Xfoil killed, SETTING ALL VALUES TO NAN as temporary solution..\n\n")
            Values.alpha = NaN;
            Values.CL = NaN;
            Values.CD = NaN;
            Values.CDp = NaN;
            Values.CM = NaN;
            Values.XTRT = NaN;
            Values.XTRB = NaN;
            Values.IsNaN=true;
    end

    delete(PolarFilePath)
end










