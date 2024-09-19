function Matrix=StlGeometryAutomaticFix(TR)


    %Adjustment settings for z coord in the zero point

    %Search range near 0 in radius percentage
    SearchRange=0.05;

    %Display for check

    XX=TR.Points;

    plot3(XX(:,1),XX(:,2),XX(:,3),".")
    xlabel("x")
    ylabel("y")
    zlabel("z")
    title("Read from STL")
    axis equal

    %retriving matrixes
    XX=TR.Points;
    ConnectivityList=TR.ConnectivityList;

    %General initializations
    OutputMatrix=XX;
    OutputConnections=ConnectivityList;

    c=0;
    Completed=false;
    while not(Completed)
        c=c+1;


            plot3(OutputMatrix(:,1),OutputMatrix(:,2),OutputMatrix(:,3),".")
            xlabel("x")
            ylabel("y")
            zlabel("z")
            title("Operation "+num2str(c-1))
            axis equal

        if c==1
            Action="move";
        elseif c==2
            Action="adjust";
        elseif c==3
            Action="rotate";
            Rotation="x";
        elseif c==4
            Action="rotate";
            Rotation="z";
        elseif c==5
            Action="rotate";
            Rotation="z";
            Completed=true;
        end




        switch Action
            case "rotate"

                 RotatedMatrix=[];

                    switch Rotation
                        case "x"
                            RotatedMatrix(:,1)=OutputMatrix(:,1);
                            RotatedMatrix(:,2)=-OutputMatrix(:,3);
                            RotatedMatrix(:,3)=OutputMatrix(:,2);
                        case "y"
                            RotatedMatrix(:,2)=OutputMatrix(:,2);
                            RotatedMatrix(:,1)=OutputMatrix(:,3);
                            RotatedMatrix(:,3)=-OutputMatrix(:,1);
                        case "z"
                            RotatedMatrix(:,3)=OutputMatrix(:,3);
                            RotatedMatrix(:,2)=OutputMatrix(:,1);
                            RotatedMatrix(:,1)=-OutputMatrix(:,2);
                    end

                    OutputMatrix=RotatedMatrix;


            case "move"

                MatrixToMove=OutputMatrix;

                xmin=min(MatrixToMove(:,1));
                xmax=max(MatrixToMove(:,1));
                xmid=(xmax+xmin)/2;

                ymin=min(MatrixToMove(:,2));
                ymax=max(MatrixToMove(:,2));
                ymid=(ymax+ymin)/2;

                zmin=min(MatrixToMove(:,3));
                zmax=max(MatrixToMove(:,3));
                zmid=(zmax+zmin)/2;
                
                OutputMatrix(:,1)=MatrixToMove(:,1)-xmid;
                OutputMatrix(:,2)=MatrixToMove(:,2)-ymid;
                OutputMatrix(:,3)=MatrixToMove(:,3)-zmid;


            case "mirror"

                MatrixToMirror=OutputMatrix;
                
                MatrixToMirror(:,1)=-MatrixToMirror(:,1);
                MatrixToMirror(:,2)=-MatrixToMirror(:,2);
                MatrixToMirror(:,3)=-MatrixToMirror(:,3);

                %Mirror display
                plot3(MatrixToMirror(:,1),MatrixToMirror(:,2),MatrixToMirror(:,3),".")
                xlabel("x")
                ylabel("y")
                zlabel("z")
                title("Mirrored matrix")
                axis equal
    
                %Updating
                OutputMatrix=MatrixToMirror;

            case "adjust"
                ymax=max(OutputMatrix(:,2));
                ymin=min(OutputMatrix(:,2));

                sr=(ymax-ymin)*SearchRange;

                ContainedPointsIds=abs(OutputMatrix(:,2))<sr;
                
                ContainedMatrix=OutputMatrix(ContainedPointsIds,:);

                zmax=max(ContainedMatrix(:,3));
                zmin=min(ContainedMatrix(:,3));

                zoffest=(zmin+zmax)/2;

                ShiftedMatrix(:,1)=OutputMatrix(:,1);
                ShiftedMatrix(:,2)=OutputMatrix(:,2);
                ShiftedMatrix(:,3)=OutputMatrix(:,3)-zoffest;

                
                OutputMatrix=ShiftedMatrix;


        end

    end



    %Final checks
    plot3(OutputMatrix(:,1),OutputMatrix(:,2),OutputMatrix(:,3),".")
    xlabel("x")
    ylabel("y")
    zlabel("z")
    title("Final Matrix")
    axis equal
    hold on
    dot=plot3(0,0,0);
    dot.Marker="*";
    dot.Color="red";
    hold off


    %Output
    Matrix.Points=OutputMatrix;
    Matrix.ConnectivityList=OutputConnections;

       
end