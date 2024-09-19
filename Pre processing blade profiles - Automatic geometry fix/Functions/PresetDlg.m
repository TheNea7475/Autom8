function Values=PresetDlg(Labels,Defaults)

    Values=struct();
    Number=length(Labels);
    BoxSizes=ones(Number,2);
    BoxSizes(:,2)=BoxSizes(:,2).*45;
    answer = inputdlg(Labels,"Insert values",BoxSizes,Defaults);
    for i=1:length(Labels)
        Values.(string(Labels(i)))=answer(i);
    end

end