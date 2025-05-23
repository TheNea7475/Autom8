
%#ok<*UNRCH>    
%#ok<*AGROW>    Autoincremento matrice
%#ok<*VUNUS>    Variabile non usata

function Report=GeometryExtractor_debug(stlPath,AirfDir,GraphDir,PADDir,GenerateGif,steps,d,Holdgraphs,DebugGraphNumbered,range_rpm,UnitFactor,Soundspeed,ni)
    
    arguments
    
    stlPath string
    AirfDir string
    GraphDir string
    PADDir string
    GenerateGif logical
    steps int32
    d double
    Holdgraphs logical
    DebugGraphNumbered logical
    range_rpm double
    UnitFactor double
    Soundspeed double
    ni double
    
    end
    
    
    %% Options
    
    TrailCutPerc=99;                    %Perc after the trail is cut. Additional behaviour in function
    cutoff=0.1;                         %Perc of ctoff from min z (near root)
    gifFile = 'Sequence.gif';           %Name of the gif
    
    
    %% Pre run operations

    Report=struct();
    intersections=[];
    
    %% Stl geometry reading
    
    %Reading STL file

    [TR] = stlread(stlPath);
    
    
    % Automatic rotation and repositioning for geometry

    
    Output=StlGeometryAutomaticFix(TR);
    XX=Output.Points;
    Connections=Output.ConnectivityList;



    %getting z of tip and root
    zmin=min(XX(:,3));
    zmax=0;
    halfz=zmax-zmin;
    
    %% scanning trough z coords

    %zmin=tip, zmax = root
    zscan=linspace(zmin,(zmax-((zmax-zmin)*cutoff)),steps);

    reald_delta=abs(zmax-zmin)*(d/100);

    stepnum=0;
    for z = zscan
        stepnum=stepnum+1;
    
    
        if (z==zmin || z==zmax)                 %prevent use of delta at geometry borders
            d_used=0;
        else
            d_used=reald_delta;
        end
    
        L1=XX(:,3)<=z+d_used;                 %Logical values 0 1, for every row
        L2=XX(:,3)>=z-d_used;                  
        L3=L1 & L2;
    
        XXX=XX(L3,:);               %points in delta
    
        %To nondimentionalize coordinates
        xmax=max(XXX(:,1));         %#ok<NASGU>
        ymax=max(XXX(:,2));         %#ok<NASGU>
    
    
        %check if every point has a connection that intersects the exact value of z
        %then in that case calculate z and build a matrix of points in x & y
       

        %% Try to avoid looping the whole c

           c_v=find((XX(:,3)<=z+d_used) && (XX(:,3)>=z-d_used));
    
      
          
                                                                                 
            








          
     

           
    if isempty(c_v)
        intersections=false;
    else
       for c=c_v
        
           for iii=1:length(c_v)                                                                      %wich connections the point has
            c_c(iii)=find(Connections==c_v(iii));
            [c_c_row(iii),~]=ind2sub(size(Connections),c_c(iii));
           end                                                                   %scan whole connections matrix
           for a=c_c_row
                    Row=Connections(a,:);                                       %get a row
            
                    for value=Row                                               %scan a row to check points id
                
                        if value==c
    
                                                                                %this iterates for every row that
                            p1=XX(Row(1),:);                                    %contains the id of the requested point
                            p2=XX(Row(2),:);                                    %aka all the connections the point has
                            p3=XX(Row(3),:);
    
    
                            result=GetIntersectWithLine(p1,p2,z);
    
                            if result
                                intersections=vertcat(intersections,result);
                            end
    
                            result=GetIntersectWithLine(p1,p3,z);
                            if result
                                intersections=vertcat(intersections,result);
                            end
    
                            result=GetIntersectWithLine(p2,p3,z);
                            if result
                                intersections=vertcat(intersections,result);
                            end
    
                        end %endif
                    end %endfor
                %end %endfor
            end %endfor
        end
    end
    
    
    
        %% data organization
    
        XXX;
        %XXX_adim=XXX(:,1:2)/xmax;
        intersections;
    
        RTSRD_dict=ProfileRepositioning(XXX,TrailCutPerc);
    
        RTSRD=RTSRD_dict{"matrix"};
        theta=RTSRD_dict{"theta"};
    
        if intersections
            %intersections_adim=intersections(:,1:2)/(max(intersections(:,1)));
    
            RTSGI_dict=ProfileRepositioning(intersections,TrailCutPerc);
    
            RTSGI=RTSGI_dict{"matrix"};
            theta=RTSGI_dict{"theta"};
            
            TargetProfile=RTSGI;
        else
            TargetProfile=RTSRD;        
        end
        
        TargetProfile;              %corrected profile
        alpha=theta;                %angle of rotation
        XY25=FindXY25(XXX);           %x and y of 25% chord, in base reference system
        ChordLen=GetChordLen(XXX);  %get chord len
    
        %% --- plot generator ---
    
        f=figure('Name','Step '+string(stepnum)+' for z='+string(z),'NumberTitle','off');
        f.Position(1:4) = [0 0 1024 1024];
        tiledlayout(4,2)
    
        nexttile
        hold on;
        plot(XXX(:,1),XXX(:,2),".");
        plot(XY25(1,1),XY25(1,2),".");
        hold off;
        axis equal;
        title('Real measures')
    
    
    
        if intersections
            nexttile
            plot(intersections(:,1),intersections(:,2),'.');
            axis equal;
            title('Generated intersections (dim)')
    
        else
            nexttile
            title('Unable to generate intersections')
        end
    
        nexttile
        plot(RTSRD(:,1),RTSRD(:,2),'.');
        xlim([-0.1 1.1])
        ylim([-0.3 0.3])
        axis equal;
        title('Rotated translated scaled raw data (nondim)*')
    
        if intersections
            nexttile
            plot(RTSGI(:,1),RTSGI(:,2),'.');
            xlim([-0.1 1.1])
            ylim([-0.3 0.3])
            axis equal;
            title('Rotated translated scaled generated intersections (nodim)*')
        else
            nexttile
            title('Unable to generate intersections')
        end
    
    
        nexttile
        plot(TargetProfile(:,1),TargetProfile(:,2));
        xlim([-0.1 1.1])
        ylim([-0.3 0.3])
        axis equal
        title('Final result before polyroot','Profile n° ' + string(stepnum) + " alpha " + string(alpha)+"°");
   

        nexttile


        %Reference graph, rotated for better visual
        xx=XX(:,1);
        yy=XX(:,2);
        zz=XX(:,3);

        plot3(zz,yy,-xx,'.')
        xlabel("x")
        ylabel("y")
        zlabel("z")
        title("3D reference visualization")
        axis equal

        hold on
        %Plot cutting plane
        xpmin=min(xx);
        xpmax=max(xx);
        ypmin=min(yy);
        ypmax=max(yy);

        [xp,yp] = meshgrid([xpmin xpmax],[ypmin ypmax]);
        zp = 0.*xp + 0.*xp + z;
        surf(zp,yp,-xp);
        hold off

        %Custom interpolation
        nexttile
        InterpProfile=CustomInterp(TargetProfile);  %This func produces a plot
        title("Polyroot interpolation")

        nexttile
        plot(InterpProfile(:,1),InterpProfile(:,2))
        title("Final result")
        xlim([-0.1 1.1])
        ylim([-0.3 0.3])
        axis equal;

        %% gif saver
        
        if GenerateGif
            for c00=1:10
                exportgraphics(gcf, gifFile, Append=true);
            end
        end
    
        %% img saver

        saveas(gcf,GraphDir+'Profile'+string(stepnum)+'.png');
    
    
        %% debug graph with numbered points, not saved only shown if required
    

            if DebugGraphNumbered

                %Chose wich matrix to debug
                DebugProfile=TargetProfile;

                figure('Name','Debug graph/step '+string(stepnum)+' for z='+string(z),'NumberTitle','off');
                hold on
                plot(DebugProfile(:,1),DebugProfile(:,2));
                plot(DebugProfile(:,1),DebugProfile(:,2),'o');
                title('Debug graph with numbered points, not saved')
                hold off
                grid on
                axis equal
            
    
                for i=1:size(DebugProfile)
                    text(DebugProfile(i,1),DebugProfile(i,2),string(i),FontSize=6)
                end
            end
    
    
        
    
        %% --- Txt writer for xfoil ---
    
        fileID = fopen(AirfDir+'Profile'+string(stepnum)+'.txt','w');
        fprintf(fileID,'Profile'+string(stepnum)+'.txt\r\n');
        for i=1:size(InterpProfile)
            fprintf(fileID,'%6.5f %6.5f\r\n',InterpProfile(i,1),InterpProfile(i,2));
        end
        fclose(fileID);
    
    
        %Reset intersections every z scan loop and close open graphs if needed
    
        intersections=[];     
    
        if not(Holdgraphs || DebugGraphNumbered)
            close all;
        end
    
    
        %% --- Profile aerodinamic data PAD info writing ---

        %old writer
        if true

        Report=dictionary(["Profile number" "Radial position" "attack angle" "x25" "y25" "Chord/R"],{num2str(stepnum)+"/"+num2str(steps) (abs(z/halfz)) theta XY25(1,1) XY25(1,2) (ChordLen/halfz)});

        %PAD writer
        fileID = fopen(PADDir+'Profile'+string(stepnum)+'.txt','w');
        fprintf(fileID,"Radial position: "+num2str(Report{"Radial position"})+'\r\n');
        fprintf(fileID,"attack angle: "+num2str(Report{"attack angle"})+'\r\n');
        fprintf(fileID,"x25: "+num2str(Report{"x25"})+'\r\n');
        fprintf(fileID,"y25: "+num2str(Report{"y25"})+'\r\n');
        fprintf(fileID,"Chord/R: "+num2str(Report{"Chord/R"})+'\r\n');
        fclose(fileID);

        else %new writer

        %Variable top return with all profiles data. Not needed for now
        Report(stepnum).ProfileProgress=num2str(stepnum)+"/"+num2str(steps);
        Report(stepnum).RadPos=(1-z/halfz);
        Report(stepnum).alpha=theta;
        Report(stepnum).X25=XY25(1,1);
        Report(stepnum).Y25=XY25(1,2);
        Report(stepnum).ChordR=(ChordLen/halfz);


    
        %Console logging
        fprintf("--Writing pad data for profile %s--\nRadial position: %.2f\nattack angle: %.0f\nx25: %0.2f\ny25: %0.2f\nChord/R: %0.4f\n\n",Report(stepnum).ProfileProgress,Report(stepnum).RadPos,Report(stepnum).alpha,Report(stepnum).X25,Report(stepnum).Y25,Report(stepnum).ChordR);

        %New pad writer
        fileID = fopen(PADDir+'Profile'+string(stepnum)+'.txt','w');
        fprintf(fileID,"Radial position: %.2f\nattack angle: %.0f\nx25: %.2f\ny25: %.2f\nChord/R: %.4f\n",Report(stepnum).RadPos,Report(stepnum).alpha,Report(stepnum).X25,Report(stepnum).Y25,Report(stepnum).ChordR);
        fclose(fileID);
        end

    end
        

    %% Re, M, w and blade analysis, blade details file building
    
    %converting coords in lenght in meters
    MaxRMt=(abs(zmax-zmin))*UnitFactor;

    RpmMax=max(range_rpm);

    %w of rotor
    wMax=(RpmMax*2*3.14)/60;
    
    %Adim parameters of rotor

    PADsInfo=dir(PADDir);
    MaxChord=0;

    %Getting max chord

    for ij=1:length(PADsInfo)
        if PADsInfo(ij).isdir
            continue
        end

        Values=ReadPad(string(PADsInfo(ij).folder) + "\" + string(PADsInfo(ij).name));
        AdimChord=Values.Chord;

        if AdimChord>=MaxChord
            MaxChord=AdimChord;
        end

    end
    
    MaxRe=(wMax*MaxRMt*MaxRMt*MaxChord)/ni;
    
    MaxMach=(wMax*MaxRMt)/Soundspeed;
    
    %Writing rotor details on a txt, for database building
    fileID = fopen('Blade details.txt','w');
    fprintf(fileID,"Max Radius in meters: "+num2str(MaxRMt)+'\r\n');
    fprintf(fileID,"Max Re: "+num2str(MaxRe)+'\r\n');
    fprintf(fileID,"Max Mach: "+num2str(MaxMach)+'\r\n');
    fclose(fileID);


    end
    

    
    
    %% --- Functions definitions---
    
    %--- Main profile repositioning function
    %--- uses almost every other funcitons defined afterwards
    
    function result=ProfileRepositioning(PointsMatrix,TrailCutPerc)
    
    
        PointsMatrix=PointsMatrix(:,1:2);   %assures its a xy matrix
    
        PointsMatrix=RemoveDuplicates(PointsMatrix);    %deletes duplicates
    
        translation_data = translateToX(PointsMatrix,0,true);

        translatedMatrix = translation_data{"matrix"};
        
        Rotation = RotateToZero(translatedMatrix);    %rotates until most left point of airfoil is on y=0
        
        TotalRemovedTheta = Rotation{"thetaremoved"};
    
        while Rotation{"thetaremoved"} ~= 0  % avoid unnecessary loops, Need to iterate until theres no rotation
        
            Rotation = RotateToZero(Rotation{"matrix"});
    
            TotalRemovedTheta = TotalRemovedTheta + Rotation{"thetaremoved"};
    
            RotatedMatrix = Rotation{"matrix"};
    
        end
    
        %scales and moves the profile to x1=0 & x2=1
        ScaledMatrix=scaleTo0_1(RotatedMatrix);      

        %Places leading eedge on 0,0
        LEFix=AtkBorderOnZero(ScaledMatrix);    
    
        %orders points for xfoil and for plot
        OrderedMatrix=PointsOrderingV2(LEFix);     
    
        %fixes trail
        FinalMatrix=TrailFix(OrderedMatrix,TrailCutPerc);                 

        result=dictionary(["matrix" "theta"],{FinalMatrix TotalRemovedTheta});
    
    end
    
    
    
    %Function to calculate x and y position of the 25% chord point in original
    %coordinates
    
    function result=FindXY25(Matrix)
    
        Matrix=Matrix(:,1:2);   %assures its a xy matrix
    
        Matrix=RemoveDuplicates(Matrix);    %deletes duplicates
    
    
        Translation = translateToX(Matrix,0,true); %move last trail point to 0,0
    
        Matrix = Translation{"matrix"};
    
        xshift = Translation{"xshift"};
    
        yshift = Translation{"yshift"};
    
    
        Rotation = RotateToZero(Matrix);    %rotates until most left point of airfoil is on y=0
        
        TotalRemovedTheta = Rotation{"thetaremoved"};
    
        while Rotation{"thetaremoved"} ~= 0 %avoid unnecessary loops
        
        Rotation = RotateToZero(Rotation{"matrix"});
    
        TotalRemovedTheta = TotalRemovedTheta + Rotation{"thetaremoved"};
    
        Matrix = Rotation{"matrix"};
    
        end
    
        xmax=max(Matrix(:,1));
        xmin=min(Matrix(:,1));
    
        airf_len=xmax-xmin;
        airf25_perc=airf_len*0.25;
    
        %start from min and go 25% right
        X25flat = xmin + airf25_perc;
    
        %rotate and translate x25 and y25 along with the previous rotation 
        X25rotated=X25flat*cosd(abs(TotalRemovedTheta));
    
        Y25rotated=-X25flat*sind(abs(TotalRemovedTheta));
    
        X25translated= X25rotated - xshift;
    
        Y25translated= Y25rotated - yshift;
    
        result=[X25translated Y25translated];
    
    end
    
    
    %function to get chord lenght
    
    function result=GetChordLen(Matrix)
    
        Matrix=Matrix(:,1:2);   %assures its a xy matrix
    
        Matrix=RemoveDuplicates(Matrix);    %deletes duplicates
    
    
        Translation = translateToX(Matrix,0,true); %move last trail point to 0,0
    
        Matrix = Translation{"matrix"};
    
        Rotation = RotateToZero(Matrix);    %rotates until most left point of airfoil is on y=0
        
        TotalRemovedTheta = Rotation{"thetaremoved"};
    
        while Rotation{"thetaremoved"} ~= 0 %avoid unnecessary loops
        
        Rotation = RotateToZero(Rotation{"matrix"});
    
        TotalRemovedTheta = TotalRemovedTheta + Rotation{"thetaremoved"};
    
        Matrix = Rotation{"matrix"};
    
        end
    
        xmax=max(Matrix(:,1));
        xmin=min(Matrix(:,1));
    
        result=(abs(xmax - xmin));
    
    end
    
    
    
    %% Linear transformations 2D geometry------
    
    %translation to a X on Y = 0
    
    function result=translateToX(Matrix,x,outputXshift)
    
        xshift=-max(Matrix(:,1)) + x;
    
        [id]=find(Matrix(:,1)==max(Matrix(:,1)),1);
    
        yshift=-Matrix(id,2);
    
        resultMatrix=[Matrix(:,1) + xshift, Matrix(:,2) + yshift];
        
        %If shifts are needed then output a dict with shifts and shifted matrix
        if outputXshift
            result=dictionary(["matrix" "xshift" "yshift"],{resultMatrix xshift yshift});
        else
            result=resultMatrix;
        end
           
    end
    
    
    
    function result=RotateToZero(Matrix)
    
            %This function rotates the profile to make the most left point in
            %the original profile on y=0
            %trail must be on (1,0)
    
            tol=0.002;
    
            xmin=min(Matrix(:,1));
    
            [id]=find(Matrix(:,1)==xmin,1);
    
            theta=atan2d(Matrix(id,2),Matrix(id,1));                      
    
            theta=theta-180;
    
            if abs(theta) == 360  %because sometimes generates -360 or 360 instead of 0
                theta=0;
            end
    
            if (theta < 0 + tol) && (theta > 0 - tol)                % needs adjustment cause its never 0 
                convergence = true;
            else
                convergence = false;
            end
    
            R = [cosd(theta) -sind(theta); sind(theta) cosd(theta)];
    
            RotatedMatrix=Matrix*R;
    
            result=dictionary(["matrix" "convergence" "thetaremoved"],{RotatedMatrix convergence -theta});
            
    end
    
    
    %scale in 0-1
    
    function result=scaleTo0_1(Matrix)
    
        %makes the profile x-width exaclty 1 and move it in position
        %0-1 on x axis
    
        Matrix=Matrix(:,1:2);
    
        Matrix=translateToX(Matrix,0,false);
    
        ProfWidth=max(Matrix(:,1)) - min(Matrix(:,1));
    
        sf=1/ProfWidth;
    
        ScaleMatrix=diag([sf sf]);
    
        Matrix=Matrix*ScaleMatrix;
    
        result=translateToX(Matrix,1,false);
    
    end
    
    
    %% Points reordering function

    %Places exactly atk border on 0,0
    function result=AtkBorderOnZero(Matrix)
    
    xmin=min(Matrix(:,1));

    Id=find(Matrix(:,1)==xmin,1);

    Matrix(Id,1)=0;
    Matrix(Id,2)=0;

    result=Matrix;
    end

    

    
    % THE CHOSEN ONE

    % Trying different logics cause nothing is working

    function result=PointsOrderingV2(Matrix)
    

    %Using angular logic

    tM=sortrows(Matrix,1,"descend");

    %Strategy: remove top and then simply order bottom

    %For every pair of points check if te line that connects them
    %intercepts x axis out of 0:1. If yes it is on border

    x1=tM(1,1);
    y1=tM(1,2);

    topLogic=[];
    topLogic=logical(topLogic);

    for k=1:length(tM)
        
        x2=tM(k,1);
        y2=tM(k,2);
        
        if x1==x2 && y1==y2
            %Skip initial point check for identical points on (1,0)
            topLogic(k)=1;
            continue
        end
        
        %y = mx + b
        m=(y2-y1)/(x2-x1);
        b=y2-m*x2;
        
        %vertical line, skip
        if x1==x2
            topLogic(k)=0;
            continue
        end
        
        %Intercetta con y = 0
        x0=(-b)/m;

        %(x0 <= 0 || x0 >= 1) non passa dentro il profilo!
       
        if y2>=0 && (x0 <= 0 || x0 >= 0.97)

            x1=x2;
            y1=y2;

            topLogic(k)=1;
        else
            topLogic(k)=0;
        end

        

    end
    
    botLogic=not(topLogic);

    top=tM(topLogic,:);
    bot=flip(tM(botLogic,:),1);

    result=vertcat(top,bot);

    end



    %--- Trail edge fix ---
    
    function result=TrailFix(Matrix,CutPercentage)
    
        %cuts the trail edge and rewrites it
        %in a better way for xfoil to be read
    
        %POST PROCESS ONLY!
    

        P=[1,0];

        Perc=CutPercentage/100;
    
        IdToBeCut=Matrix(:,1)>Perc;
    
        Matrix(IdToBeCut,:)=[];

        FirstCut=Matrix(1,:);
        LastCut=Matrix(end,:);
        
        
        xt=[P(1),FirstCut(1)];
        yt=[P(2),FirstCut(2)];
        yintt=interp1(xt,yt,Perc);

            
        %Xfoil works better with a smooth lower traling edge

        %xb=[Last(1),LastCut(1)];
        %yb=[Last(2),LastCut(2)];
        %yintb=interp1(xb,yb,Perc);

        CutMatrix=vertcat([Perc,yintt],Matrix);
        CutMatrix=vertcat(CutMatrix,[Perc,LastCut(2)]);

        result=CutMatrix;
    end
    
    
    %--- Remove duplicate points ---
    
    function result=RemoveDuplicates(Matrix)
    
        %This function removes points too close to eachother

        Umatrix=[];
        Matrix=sortrows(Matrix,1,"descend");

        base=1;

        xmax=max(Matrix(:,1));
        xmin=min(Matrix(:,1));
        c=abs(xmax-xmin);

        %Each point is removed if its close to another one by c*base
        %percentage of chord
        MaxToleratedDist=c*(base/100);
    
        for i=1:size(Matrix)
    
            x=Matrix(i,1);
            y=Matrix(i,2);
    
            found=false;
            for c=1:size(Umatrix)

                xu=Umatrix(c,1);
                yu=Umatrix(c,2);

                distance=sqrt((x-xu)^2 + (y-yu)^2);

                if distance<MaxToleratedDist
                    found=true;
                    continue
                end
            end

            if not(found)
                Umatrix=vertcat(Umatrix,[x y]);
            end
    
        end

        result=Umatrix;
        
    end


    %- profile interpolation function
    %grado max 8, polyval e polyfit, aggiungere a0 * rad(x) come grado
    %aggiuntivo.
    function Matrix=CustomInterp(Matrix)

        Sorted=sortrows(Matrix,1,"ascend");
        AtkBorderPoint=Sorted(1,:);

        Id=find(Matrix(:,:)==AtkBorderPoint,1);

        Top=Matrix(1:Id,:);
        Bottom=Matrix(Id:end,:);
        
        Xtop=Top(:,1);
        Ytop=Top(:,2);

        Xbot=Bottom(:,1);
        Ybot=Bottom(:,2);

        xint=cosspace(0,1,100);
        
        ptop=polyroot(Xtop,Ytop,2,8);

        yinttop=polyrootval(ptop,xint,2);

        pbot=polyroot(Xbot,Ybot,2,4);

        yintbot=polyrootval(pbot,xint,2);



        plot(Matrix(:,1),Matrix(:,2),".")
        
        xlim([-0.1 1.1])
        ylim([-0.3 0.3])
        axis equal
        hold on
        
        plot(xint,yinttop)
        plot(xint,yintbot)

        hold off


        NewTop=flip(horzcat(xint',yinttop'));
        NewBot=horzcat(xint',yintbot');

        NewBot(1,:)=[];

        Matrix=vertcat(NewTop,NewBot);

    end
    


    %--- 3D Geometry functions---
    
    function point=GetIntersectWithLine(p1,p2,z)
        %Gives back coords of a point that has the z given coordinate
        %and x,y coords calculated in a line that connects the 2 points, if that
        %intersection exists
    
        z1=p1(3);
    
        z2=p2(3);
    
        if z1 ~= z2                 %check for perfectly vertical lines
            if (z1<z && z<z2) || (z2<z && z<z1) %exclude non intersecting
    
                r=p2-p1;            %line vector
        
                t=(z-p1(3))/r(3);    %parameter
    
                point=p1 + r*t;      %point
            else
                point=false;
            end
        else
            point=false;
        end
    end