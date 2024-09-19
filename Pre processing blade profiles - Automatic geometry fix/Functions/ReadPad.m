function Values=ReadPad(FilePath)
        
        % Open the file for reading
        fileID = fopen(FilePath, 'r');
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
            elseif contains(line, 'x25')
                x25_l = str2double(strsplit(line, ': '));
            elseif contains(line, 'y25')
                y25_l = str2double(strsplit(line, ': '));
            end
            line = fgetl(fileID);
        end
        fclose(fileID);

        %Output
        Values.Twist=attack_angle_l(2);
        Values.Chord=Chord_R_l(2);
        Values.RadialPosition=radial_position_l(2);
        Values.x25=x25_l(2);
        Values.y25=y25_l(2);

    end
