function InsertPlotDataInDatabase(DatabasePath,CompletePlotData)
%INSERTPROFILEDATAINDATABASE Summary of this function goes here
%   Detailed explanation goes here

    load(DatabasePath,"Database");
    Database.PlotData=CompletePlotData.PlotData;
    Database.TR=CompletePlotData.TR;
    save(DatabasePath,"Database");

    fprintf("Profiles plot data added successfully to Database!\n")

end

