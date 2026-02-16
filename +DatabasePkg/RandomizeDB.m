function [DBStruct] = RandomizeDB(DBStruct,percent)
%
% [DBStruct] = RandomizeDB(DBStruct,percent)
% Written by Maxfield Arnson
% Updated 19 nov 2025
%
% This function randomizes the DataTypeValidation field in the Settings
% substructure of each aircraft or engine in the input database structure.
% The purpose is to allow bootstrapping of training and validation datasets.
%
% INPUTS:
%
%   DBStruct = Structure tree containing the desired data. This is either the
%       TurbofanAC or TurbopropAC structure loaded from the IDEAS_DB.mat file.
%       size: 1x1 struct
%
%   percent = Percentage of data to be assigned to validation dataset
%       size: 1x1 scalar value (between 0 and 100)
%
% OUTPUTS:
%   DBStruct = Structure tree containing the randomized data.
%       size: 1x1 struct

% Get all aircraft names from the structure
Names = fieldnames(DBStruct);

% Loop through each aircraft
for ii = 1:length(Names)

    % Pick a random number between 1 and 100
    DTindex = randi(100,1,1);

    % if that index is greater than the percent value, assign this aircraft to validation
    if DTindex > percent
        DBStruct.(Names{ii}).Settings.DataTypeValidation = "Validation";

    % otherwise, assign it to training
    else
        DBStruct.(Names{ii}).Settings.DataTypeValidation = "Training";
    end
end

end % end DatabasePkg.RandomizeDB