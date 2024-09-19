function Values=ReadPadFromDB(Database,ProfileId)
        
        %Output
        Values.Twist=Database.grid.PAD(ProfileId).Twist;
        Values.Chord=Database.grid.PAD(ProfileId).Chord;
        Values.RadialPosition=Database.grid.PAD(ProfileId).RadialPosition;
        Values.x25=Database.grid.PAD(ProfileId).x25;
        Values.y25=Database.grid.PAD(ProfileId).y25;

    end
