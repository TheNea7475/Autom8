%This function runs xfoil and writes the polars in PolarFilePath without
%the need of a input file. Also kills xfoil after killtime (seconds).
%Returns 1 if xfoil completes its task, else returns 0. Logs into console
%running data and task completion status

function status=XfoilRunnerNoFile(killtime,xfoilDir,PolarFilePath,ProfilePath,LogXfoilDebug,a,Re,Mach,n_iter,ncrit)

    arguments
        killtime int64
        xfoilDir string
        PolarFilePath string
        ProfilePath string
        LogXfoilDebug logical
        a double
        Re double
        Mach double
        n_iter int64
        ncrit int64
    end

    InputString=InputStringBuilder(a,Re,Mach,n_iter,ncrit,LogXfoilDebug,PolarFilePath,ProfilePath);

    status=startnkillV4(killtime,xfoilDir,LogXfoilDebug,InputString);


end

%Updated and best version of xfoil caller with killtime. Output is stored
%in a polar txt file
function status=startnkillV4(killtime,xfoilDir,logxfoildebug,InputArray)

    xfoilExePath=sprintf("%sxfoil.exe",xfoilDir);

    process = System.Diagnostics.Process();
    process.StartInfo.FileName = xfoilExePath;
    process.StartInfo.UseShellExecute = false;
    process.StartInfo.RedirectStandardInput = true;
    process.StartInfo.RedirectStandardOutput = true;

    %Prevent cmd window from opening
    process.StartInfo.CreateNoWindow = not(logxfoildebug);

    process.Start();
    stdin = process.StandardInput;
    stdout = process.StandardOutput;
    out = stdout.ReadToEndAsync;

    %input data
    for Line=InputArray
        stdin.WriteLine(Line); % send the input to xfoil.exe
    end
    stdin.Close()

    % wait until xfoil.exe has terminated or kill it
    %theese values are use to count time passing and for checking frequency
    c=0;
    tick=0.1;
    waitflag=true;
    %if proces has not completed:
    while(~process.HasExited)

        %c keeps track of current time, tick is the checking rate
        c=c+tick;
        pause(tick);

        %if current time exceeds 1 second start displaying waiting message
        if c>1
            if waitflag
                fprintf("Waiting for xfoil")
                waitflag=false;
            end
            fprintf(".")
        end

        %this happens when current time is greater than killtime
        if c>killtime
            fprintf("Killing process :(\n\n")
            status=0;
            break
        end
    end

    %If process is exited without killtime
    if (process.HasExited)
        fprintf("Task completed! :)\n\n")
        status=1;
    end


    try
        process.Kill; % kill the process if needed.
    catch
    end

    xfoil_out = char(out.Result);

    %This HAS to be muted, its just for debug.
    %If xfoil doesnt converge it floods everything and crashes the whole code
    if logxfoildebug
        disp(xfoil_out)
    end
end


function InputArray=InputStringBuilder(a,Re,Mach,n_iter,ncrit,LogXfoilDebug,PolarFilePath,ProfilePath)
                    
                    
                    %%NB STRINGS ALREDY CONTAIN NEWLINE AT THEIR END!
                    %I REMOVED EVERY \n AT THE END OF EVERY INPUT
                    %INSTRUCTION, count as there's one additional \n


                    if not(LogXfoilDebug)
                        InputArray=strings([1,13]);
                        InputArray(1)=sprintf('plop\ng\n');
                        k=0;
                    else
                        InputArray=strings([1,12]);
                        k=1;
                    end
                    
                    
                    InputArray(2-k)=sprintf('load %s',ProfilePath);
                    InputArray(3-k)=sprintf('PANE');
                    InputArray(4-k)=sprintf('OPER');
                    InputArray(5-k)=sprintf('v');
                    InputArray(6-k)=sprintf('%f', Re);
                    InputArray(7-k)=sprintf('M %f', Mach);
                    InputArray(8-k)=sprintf('vpar\nn\n%f\n',ncrit);
                    InputArray(9-k)=sprintf('iter %d', n_iter);
                    InputArray(10-k)=sprintf('PACC');
                    InputArray(11-k)=sprintf('%s\n',PolarFilePath);
                    InputArray(12-k)=sprintf('a %f\n', a);
                    InputArray(13-k)=sprintf('quit\n');



end