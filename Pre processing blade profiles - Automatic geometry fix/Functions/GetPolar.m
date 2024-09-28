%% CURRENTLY IN OVERSHOOT. EVERY PROFILE IS CALCULATED FOR THE WHOLE RANGES!
    
function Values=GetPolar(r,a,re,mach,Database)
    
    %Preparing arrays for interpolation
    a_range=Database.grid.a;
    Re_range=Database.grid.Re;
    Mach_range=Database.grid.Mach;
    ProfilesNamesArray=Database.grid.ProfilesNamesArray;

    %Limiting values outside range

    a(a<min(a_range))=min(a_range);
    a(a>max(a_range))=max(a_range);
    re(re<min(Re_range))=min(Re_range);
    re(re>max(Re_range))=max(Re_range);
    mach(mach<min(Mach_range))=min(Mach_range);
    mach(mach>max(Mach_range))=max(Mach_range);

    %Generating meshgrid for interp3
    [X,Y,Z]=meshgrid(Re_range,a_range,Mach_range);
    
    
    [ProfileId,ProfileId2,Accuracy,r1,r2,InsideFlag]=Find2ClosestProfileS(r,ProfilesNamesArray,Database);
            
    if InsideFlag
        Values1=Polar(ProfileId,a,re,mach,X,Y,Z,Database);
        Values2=Polar(ProfileId2,a,re,mach,X,Y,Z,Database);
        Values=struct();
        Values.CL=interp1([r1,r2],[Values1.CL,Values2.CL],r);
        Values.CD=interp1([r1,r2],[Values1.CD,Values2.CD],r);
        Values.ProfileName=ProfilesNamesArray(ProfileId)+"-"+ProfilesNamesArray(ProfileId2);
    else
        Values=Polar(ProfileId,a,re,mach,X,Y,Z,Database);
        Values.ProfileName=ProfilesNamesArray(ProfileId);
    end
    %Adding profile name and accuracy to profiles
    Values.Accuracy=Accuracy;

end



function Values=Polar(ProfileId,a,Re,Mach,X,Y,Z,Database)

    CLDB=squeeze(Database.CL(ProfileId,:,:,:));
    CDDB=squeeze(Database.CD(ProfileId,:,:,:));

    CL=interp3(X,Y,Z,CLDB,Re,a,Mach);
    CD=interp3(X,Y,Z,CDDB,Re,a,Mach);

    Values.CL=CL;
    Values.CD=CD;

end


function [ProfileId,ProfileId2,Accuracy,r1,r2,isInside]=Find2ClosestProfileS(InputR,ProfilesNamesArray,Database)

    %Need to find the closest profile to given r, extract his name to give it to the database
    %so the database can know wich profile is more suitable
    OldDist=1;

    for i=1:length(ProfilesNamesArray)

        Data=ReadPadFromDB(Database,i);
        readR=Data.RadialPosition;
        Dist=abs(readR-InputR);
        if OldDist>Dist
            r1=readR;
            ChosenProfileId=i;
            OldDist=Dist;
        end
    end

    BestDist=OldDist;

    OldDist=1;

    for j=1:length(ProfilesNamesArray)

        if j==ChosenProfileId
            %Skipping first nearest
            continue
        end

        Data=ReadPadFromDB(Database,j);
        readR=Data.RadialPosition;
        Dist=abs(readR-InputR);
        if OldDist>Dist
            r2=readR;
            SecondChosenProfileId=j;
            OldDist=Dist;
        end
    end



    ProfileId=ChosenProfileId;
    ProfileId2=SecondChosenProfileId;
    Accuracy=BestDist;

    %Verify that the given r is actually inside the extracted profiles
    if (InputR<r2 && InputR>r1) || (InputR<r1 && InputR>r2)
        isInside=true;
    else
        isInside=false;
    end


end

