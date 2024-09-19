function report=TwistAndChordDist(PADDir,ReferenceCSVDir)
%% Message suppression

    %#ok<*AGROW>

%% Initializations

    report=true;
    ReadTwist=[];
    ReadChord=[];
    RadialPosition=[];
    
    %% Reading chord twist and radial pos

    PADFilesPaths= dir(fullfile(PADDir, '*.txt'));

    %Scanning every pad file and extracting data

    for i = 1:length(PADFilesPaths)

        PADPath = fullfile(PADDir, PADFilesPaths(i).name);
        
        
        % Open the file for reading
        fileID = fopen(PADPath, 'r');
        % Read the lines from the file

        line = fgetl(fileID);
        while ischar(line)
            % Check if the line contains "Max R"
            if contains(line, 'Chord/R')
                % Extract the double value after ":"
                Chord_R_l = str2double(strsplit(line, ': '));
            elseif contains(line, 'attack angle')
                attack_angle_l = str2double(strsplit(line, ': '));
            elseif contains(line, 'Radial position')
                radial_position_l = str2double(strsplit(line, ': '));
            end
            line = fgetl(fileID);
        end
        fclose(fileID);

        ReadTwist=[ReadTwist,attack_angle_l(2)];
        ReadChord=[ReadChord,Chord_R_l(2)];
        RadialPosition=[RadialPosition,radial_position_l(2)];

    end

        %% Sorting on base chord/R with a matrix

        matrix=[ReadTwist.',ReadChord.',RadialPosition.'];
        matrix=sortrows(matrix,3);

        %% reading csv twist and chord
    
        Chord=readtable(ReferenceCSVDir+"Chord.csv");
        Twist=readtable(ReferenceCSVDir+"Twist.csv");

            
        %% Plotting
       
        tiledlayout(1,2);

        nexttile;
        title("Chord distributions");
        hold on;
        plot(matrix(:,3),matrix(:,2));
        plot(Chord.Var1,Chord.Var2);
        xlabel("r/R")
        ylabel("c/R")
        legend("Calculated chord","Benchmark chord")
        hold off;

        nexttile;
        title("Twist distributions");
        hold on;
        plot(matrix(:,3),matrix(:,1));
        plot(Twist.Var1,Twist.Var2);
        ylim([0,50])
        xlabel("r/R")
        ylabel("\alpha°")
        
        legend("Calculated twist","Benchmark twist")
        hold off;

        saveas(gcf,"Distributions.png")

        close all;
end