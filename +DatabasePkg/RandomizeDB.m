function [DBStruct] = RandomizeDB(DBStruct,percent)
% randomizes database validation and training flags


Names = fieldnames(DBStruct);

for ii = 1:length(Names)
    DTindex = randi(100,1,1);

    if DTindex > percent
        DBStruct.(Names{ii}).Settings.DataTypeValidation = "Validation";
    else
        DBStruct.(Names{ii}).Settings.DataTypeValidation = "Training";
    end
end

end

