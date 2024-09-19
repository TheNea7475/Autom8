function Values=ReadBladeDet()
        % Open the file to extract max Re,Mach,R
        fileID = fopen('Blade details.txt', 'r');

        line = fgetl(fileID);
        while ischar(line)
            % Check if the line contains "Max R"
            if contains(line, 'Radius')
                % Extract the double value after ":"
                maxR_l = str2double(strsplit(line, ': '));
            elseif contains(line, 'Re')
                maxRe_l = str2double(strsplit(line, ': '));
            elseif contains(line, 'Mach')
                maxMach_l = str2double(strsplit(line, ': '));
            end
            line = fgetl(fileID);
        end
        % Close the file
        fclose(fileID);
    

        Values.maxRe=maxRe_l(2);
        Values.maxR=maxR_l(2);
        Values.maxMach=maxMach_l(2);
end