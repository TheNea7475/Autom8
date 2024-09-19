function PolarMenu(Database)
%This functions allows to plot graphs like CL-alpha, polars and likewise
    
    MaxAlpha=max(Database.grid.a);
    MinAlpha=min(Database.grid.a);
    MaxRe=max(Database.grid.Re);
    MinRe=min(Database.grid.Re);
    MaxM=max(Database.grid.Mach);
    MinM=min(Database.grid.Mach);


    hold on;
    legend_vec=[];
    PlotNum=0;


    fprintf(2,"\nVariables limits:\nr: 0 - 1\nAlpha %.2f - %.2f\nRe %.2f - %.2f\nMach %.2f - %.2f\n",MinAlpha,MaxAlpha,MinRe,MaxRe,MinM,MaxM)
    
    Main = questdlg('Chose type of calculation','Menu','Single value data','Graph','Quit','Quit');

    while Main~="Quit"
        
        switch Main
        
       
        case "Single value data"
            %% Single value inspection in database
            FieldName = questdlg('Choose field value','Menu','CL','CD','CL');
        
            Fields=raremachprompt();
            r=Fields.r;
            a=Fields.a;
            Re=Fields.Re;
            Mach=Fields.Mach;
        
            if checkfieldsOOB(MinAlpha,MaxAlpha,MinRe,MaxRe,MinM,MaxM,a,Re,Mach,r)
                continue
            end
        
            Values=GetPolar(r,a,Re,Mach,Database);
            Value=Values.(FieldName);
        
            fprintf("%s = %s for r=%.2f a=%.2f Re=%.2f Mach=%.2f\n",FieldName,Value,r,a,Re,Mach)
        

            case "Graph"
            %% Graphs-like outputs

                Graph = questdlg('Type of graph','Menu','CD-Alpha','CL-Alpha','CL-Alpha');

                switch Graph

                    case "Polar CL-CD"
                        fprintf(2,"Not implemented yet\n")
                        continue

                    case "CL-Alpha"
                        PlotNum=PlotNum+1;
                        Fields=ClAlphaPrompt();
                        r=Fields.r;
                        Re=Fields.Re;
                        Mach=Fields.Mach;
                         
                        if checkfieldsOOB(MinAlpha,MaxAlpha,MinRe,MaxRe,MinM,MaxM,(MaxAlpha+MinAlpha/2),Re,Mach,r)
                            continue
                        end

                        yax=zeros(1,6);
                        k=1;
                        
                        alphas=linspace(MinAlpha,MaxAlpha,6);
                        for a=alphas
                            Values=GetPolar(r,a,Re,Mach,Database);
                            yax(k)=Values.CL;
                            k=k+1;
                        end

                        fprintf("Profile chosen for r=%.2f -->%s\nRadius accuracy -->%.2f%%\n\n",r,Values.ProfileName,(100-(Values.Accuracy*100)))
                        plot(alphas,yax)
                        legend_string=sprintf("R=%.2f Re=%.0f Mach=%.2f",r,Re,Mach);
                        legend_vec=[legend_vec,legend_string]; %#ok<AGROW>
                        xlabel("Alpha")
                        ylabel("CL")
                        legend(legend_vec);

                        case "CD-Alpha"
                        PlotNum=PlotNum+1;
                        Fields=ClAlphaPrompt();
                        r=Fields.r;
                        Re=Fields.Re;
                        Mach=Fields.Mach;
                         
                        if checkfieldsOOB(MinAlpha,MaxAlpha,MinRe,MaxRe,MinM,MaxM,(MaxAlpha+MinAlpha/2),Re,Mach,r)
                            continue
                        end

                        yax=zeros(1,6);
                        k=1;
                        
                        alphas=linspace(MinAlpha,MaxAlpha,6);
                        for a=alphas
                            Values=GetPolar(r,a,Re,Mach,Database);
                            yax(k)=Values.CD;
                            k=k+1;
                        end

                        fprintf("Profile chosen for r=%.2f -->%s\nRadius accuracy -->%.2f%%\n\n",r,Values.ProfileName,(100-(Values.Accuracy*100)))
                        plot(alphas,yax)
                        legend_string=sprintf("R=%.2f Re=%.0f Mach=%.2f",r,Re,Mach);
                        legend_vec=[legend_vec,legend_string]; %#ok<AGROW>
                        xlabel("Alpha")
                        ylabel("CD")
                        legend(legend_vec);

                end
        end

        Main = questdlg('Chose type of calculation','Menu','Single value data','Graph','Quit','Quit');
        
    end
end




%% Prompt models and other functions
function Value=raremachprompt()
        prompt = {'R(from 0 to 1):','Alpha:','Re:','Mach:'};
        defiInp={'0.5','5','200000','0.1'};
        answer = inputdlg(prompt,"Insert values",[1 45; 1 45; 1 45; 1 45;],defiInp);
        answer=str2double(answer);
        Value.r=answer(1);
        Value.a=answer(2);
        Value.Re=answer(3);
        Value.Mach=answer(4);
end

function Value=ClAlphaPrompt()
        prompt = {'R(from 0 to 1):','Re:','Mach:'};
        defiInp={'0.5','200000','0.1'};
        answer = inputdlg(prompt,"Insert values",[1 45; 1 45; 1 45;],defiInp);
        answer=str2double(answer);
        Value.r=answer(1);
        Value.Re=answer(2);
        Value.Mach=answer(3);
end


%% Checking boundaries when input
function value=checkfieldsOOB(MinA,MaxA,MinRe,MaxRe,MinMach,MaxMach,a,Re,Mach,r)
    OutOfBOunds=false;

    if not(a<=MaxA && a>=MinA)
        OutOfBOunds=true;
        fprintf(2,"Alpha out of boundaries of database\n")
    end
    
    if not(Re<=MaxRe && Re>=MinRe)
        OutOfBOunds=true;
        fprintf(2,"Reynolds out of boundaries of database\n")
    end

    if not(Mach<=MaxMach && Mach>=MinMach)
        OutOfBOunds=true;
        fprintf(2,"Mach out of boundaries of database\n")
    end

    if not(r<=1 && r>=0)
        OutOfBOunds=true;
        fprintf(2,"Mach out of boundaries of database\n")
    end

    value=OutOfBOunds;
end
