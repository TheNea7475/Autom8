function InsertPadInDatabase(DatabasePath,PADDir,ProfilesDir)
    %Writes info about profiles into database for better reading and full
    %access to every data needed

    load(DatabasePath,"Database");




   %getting every profile, extracting the paths
   Profiles = dir(fullfile(ProfilesDir, '*.txt'));

   %preallocating an array for profile names
   ProfilesNamesArray=strings([1,length(Profiles)]);
        
        
    for i=1:length(Profiles)
        [~,ProfilesNamesArray(i),~] = fileparts(ProfilesDir+Profiles(i).name);
    end



    i=0;

    for Name = ProfilesNamesArray

        i=i+1;
        Values=ReadPad(PADDir+Name+".txt");
        Database.grid.PAD(i)=Values;

    end

    %Updating database after processing
    save(DatabasePath,"Database");

    fprintf("Profiles aerodinamic data PAD added successfully to Database!\n")

end