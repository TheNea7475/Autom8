function FillDatabase(DatabasePath,RemovingTreshold,PercTreshold)

    %Caused by interpolating with interp1 when there are nans. 
    %This is controlled by the following code, its not necessary and will
    %be set back on at the end of the script
    warning('off','MATLAB:interp1:NaNstrip')

    load(DatabasePath,"Database");

    %Prevent code break when interpoalting on less than 2 values
    if RemovingTreshold < 2
        RemovingTreshold = 2;
    end


    %% Database corrupted polar indices scanner
    %Get where are located Corrupted polars (CPindices)
    CPInd=struct();

    a_range=Database.grid.a;
    Re_range=Database.grid.Re;
    Mach_range=Database.grid.Mach;
    ProfilesNamesArray=Database.grid.ProfilesNamesArray;

    %Builds a structure with indices of broken polars in db. Using CL as
    %sample to find indices

    i=0;
    for Profi=1:length(ProfilesNamesArray)
        for ai=1:length(a_range)
            for rei=1:length(Re_range)
                for machi=1:length(Mach_range)
                    if isnan(Database.CL(Profi,ai,rei,machi))
                        i=i+1;
                        CPInd(i).Profile=Profi;
                        CPInd(i).a=ai;
                        CPInd(i).Re=rei;
                        CPInd(i).Mach=machi;
                    end
                end
            end
        end
    end

%% Database filling
% Filling strategy: run over a row (3 inxs equal) and interpolate with the other safe values of the row

    
    %Cycle in the known broken polars 
    i=1;

    %when a profile is removed all profiles ahead are scaled down by 1 position
    RemovedProfiles=0;

    if length(CPInd) == 1
        fprintf("No interpolation needed, all clear!\n")
    end

    while i<length(CPInd)

        %Splitting struct in values for faster use
        pi=CPInd(i).Profile-RemovedProfiles;
        ai=CPInd(i).a;
        rei=CPInd(i).Re;
        machi=CPInd(i).Mach;
        
        %get the number of broken values when 1 value changes to decide if
        %profile should be removed from interpolation or not. All dbs are
        %parallel, so if theres a NaN in Cl theres a NaN in CD and so on...

        % Same should be done 3 times
        %if all interp are unsuccessfull then discard profile!
        
        %Choose the direction of interpolation based on where are less NaNs
        interpdir="none";
        
        Row1=squeeze(Database.CL(pi,ai,rei,:))';
        Row2=squeeze(Database.CL(pi,ai,:,machi))';
        Row3=squeeze(Database.CL(pi,:,rei,machi))';
        
        Stats1=NansStats(Row1);
        Stats2=NansStats(Row2);
        Stats3=NansStats(Row3);
        

        %% Choose interpolation direction, where is possible, prefering Mach, then Re then alpha.
        %This function can additionally be fine-tuned

        if Stats1.NNotNans >= RemovingTreshold && Stats1.NOfNansPerc <= PercTreshold
            interpdir="mach";
            Stats=Stats1;
        elseif Stats2.NNotNans >= RemovingTreshold && Stats2.NOfNansPerc <= PercTreshold
            interpdir="re";
            Stats=Stats2;
        elseif Stats3.NNotNans >= RemovingTreshold && Stats3.NOfNansPerc <= PercTreshold
            interpdir="a";
            Stats=Stats3;
        end


%% Interpolate in the best direction eligible if possible
        if interpdir ~="none"

            if Stats.NumOfNans==0
                fprintf("Alredy filled\n")
            else
                %in this case interpolate for that row
                fprintf("Interpoaltion direction chosen: %s\nNumber of Nans: %d\nNumber of correct values: %d\nNans percent: %.0f%%\n\n",interpdir,Stats.NumOfNans,Stats.NNotNans,Stats.NOfNansPerc)
                Database=FillAllDatabases(pi,ai,rei,machi,Database,interpdir);
            end

        else
        %% If no inteprolation direction avaliable delete the faulty profile!
            
            fprintf(2,"Unable to interpolate, removing %s\n",ProfilesNamesArray(pi+RemovedProfiles))

            Stats=Stats1;
            fprintf(2,"Mach variating interpolation\nNumber of Nans: %d\nNumber of correct values: %d\nNans percent: %.0f%%\n\n",Stats.NumOfNans,Stats.NNotNans,Stats.NOfNansPerc)
            Stats=Stats2;
            fprintf(2,"Re variating interpolation\nNumber of Nans: %d\nNumber of correct values: %d\nNans percent: %.0f%%\n\n",Stats.NumOfNans,Stats.NNotNans,Stats.NOfNansPerc)
            Stats=Stats3;
            fprintf(2,"Alpha variating interpolation\nNumber of Nans: %d\nNumber of correct values: %d\nNans percent: %.0f%%\n\n",Stats.NumOfNans,Stats.NNotNans,Stats.NOfNansPerc)
            
            Fields=fieldnames(Database);

            %Removing grid from fieldlist
            Mask=strcmp(Fields,"grid");
            Fields(Mask)=[];

            %removing profile from database values
            for k=1:length(Fields)
                Field=Fields{k};
                Database.(Field)(pi,:,:,:)=[];
            end

            %removing profile from Db.grid
            Database.grid.ProfilesNamesArray(pi)=[];

            %removing profile from PAD in database
            Database.grid.PAD(pi)=[];

            %Removing all broken polars that contain this profile, give up
            %on interpolation.
        
            Mask=[CPInd(:).Profile]==(pi+RemovedProfiles);
            CPInd(Mask)=[];

            %Prevent skipping a line.
            %% i must be placed where the new indices start! WHAT FOLLOWS MIGHT BREAK THINGS

            ToFind=pi+RemovedProfiles+1;
            NextIndex=find([CPInd.Profile]==ToFind,1);

            if NextIndex
                i=NextIndex-1;
            else
                %If id not found interpolation is finished (last profile is removed and its going out of boundaries)
                i=length(CPInd);
            end
            %to shift the rest of profiles
            RemovedProfiles=RemovedProfiles+1;
        end
        
       
        i=i+1;

    end

        %Updating database after processing
        save(DatabasePath,"Database");

        %turning warning back on
        warning('on','MATLAB:interp1:NaNstrip')

end
  



%% fucntions

%%Function to iterate for CL CD CM and so on when filling is needed

function Value=FillAllDatabases(pi,ai,rei,machi,Database,interpdir)

            %Cicle trough all values of database except the grid

            %this should be a char list of the fields

            Fields={"CL" "CD"};

            for i=1:length(Fields)

                Field=Fields{i};
    
                if interpdir=="mach"
                    Row=squeeze(Database.(Field)(pi,ai,rei,:))';
                elseif interpdir=="re"
                    Row=squeeze(Database.(Field)(pi,ai,:,machi))';
                elseif interpdir=="a"
                    Row=squeeze(Database.(Field)(pi,:,rei,machi))';
                end

                RangeIds=1:length(Row);

                InterpValues=interp1(RangeIds,Row,RangeIds,"pchip");    

                %Substitution of row into the row of the database with
                %interpolated values

                for k=1:length(Row)

                    if interpdir=="mach"
                        Database.(Field)(pi,ai,rei,k)=InterpValues(k);
                    elseif interpdir=="re"
                        Database.(Field)(pi,ai,k,machi)=InterpValues(k);
                    elseif interpdir=="a"
                        Database.(Field)(pi,k,rei,machi)=InterpValues(k);
                    end

                end

            end
            
    


            %Output
            Value=Database;
end


%Function to inspect content of a row

function Value=NansStats(Row)

        Value=struct();

        Nans=isnan(Row);
        

        Value.NumOfNans=nnz(Row(Nans));
        
        Value.NOfNansPerc=(Value.NumOfNans)/(length(Row))*100;
        
        Value.NNotNans=length(Row)-Value.NumOfNans;

        
end





