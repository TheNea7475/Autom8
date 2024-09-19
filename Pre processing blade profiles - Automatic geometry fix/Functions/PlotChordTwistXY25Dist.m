function PlotChordTwistXY25Dist(Database,DataMatrix)

    InputRadPos=DataMatrix(:,1);    
    InputChord=DataMatrix(:,2);
    InputTwist=DataMatrix(:,3);
    Inputx25=DataMatrix(:,4);
    Inputy25=DataMatrix(:,5);
    
    DatabaseRadPos=cell2mat({Database.grid.PAD.RadialPosition});
    DatabaseTwist=cell2mat({Database.grid.PAD.Twist});
    DatabaseChord=cell2mat({Database.grid.PAD.Chord});
    Databasex25=cell2mat({Database.grid.PAD.x25});
    Databasey25=cell2mat({Database.grid.PAD.y25});
    
    
    DbMatrix(:,1)=DatabaseRadPos;
    DbMatrix(:,2)=DatabaseChord;
    DbMatrix(:,3)=DatabaseTwist;
    DbMatrix(:,4)=Databasex25;
    DbMatrix(:,5)=Databasey25;
    
    DbMatrix=sortrows(DbMatrix,1);
    
    
    
    tiledlayout(2,2)
    
    %Chord
    nexttile()
    plot(DbMatrix(:,1),DbMatrix(:,2))
    hold on
    plot(InputRadPos,InputChord)
    title("Chord distribution")
    axis equal
    xlabel("r/R")
    ylabel("c/R")
    legend(["Calculated" "Reference"])
    
    %Twist
    nexttile()
    plot(DbMatrix(:,1),DbMatrix(:,3))
    hold on
    plot(InputRadPos,InputTwist)    
    title("Twist distribution")
    xlabel("r/R")
    ylabel("alpha°")
    legend(["Calculated" "Reference"])

    %x25
    nexttile()
    plot(DbMatrix(:,1),(DbMatrix(:,4)-abs(Inputx25(1)-DbMatrix(1,4))))
    hold on
    plot(InputRadPos,Inputx25)
    title("x25 distribution")
    xlabel("r/R")
    ylabel("mm")
    legend(["Calculated" "Reference"])

    %y25
    nexttile()
    plot(DbMatrix(:,1),DbMatrix(:,5)-abs(Inputy25(1)-DbMatrix(1,5)))
    hold on
    plot(InputRadPos,Inputy25)
    title("y25 distribution")
    xlabel("r/R")
    ylabel("mm")
    legend(["Calculated" "Reference"])
    hold off


end