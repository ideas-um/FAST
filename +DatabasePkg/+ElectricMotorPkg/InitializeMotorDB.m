function [] = InitializeMotorDB()
%
% [] = InitializeMotorDB()
% written by Maxfield Arnson,
% Last modified: 19 nov 2025
%
% This function transforms a .xlsx data file into a nested matlab structure so it can be used
% with the regression functions in FAST. The data was collected by a former student in the IDEAS Lab 
% from SunnySky motors specification sheets on the website: https://sunnyskyusa.com/


% read in raw data, collected for this study
[~,~,RawData] = xlsread(fullfile("+DatabasePkg", "+ElectricMotorPkg", "RawMotorData.xlsx"));

% Loop thrugh rach motor on each row
for ii = 4:size(RawData,1)

    % for each motor, read each parameter
    for jj = 2:size(RawData,2)

        % first entry is the name, need to add unique kv since some motors share a name
        % TODO: can this line be moved outside of the jj loop into the ii?
        name = string((RawData{ii,1})) + "_KV" + string((RawData{ii,3}));

        % add other parameters
        ElectricMotors.(name).(RawData{2,jj}) =  RawData{ii,jj};

    end
end

% Create a unit reference structure for user convenience
for jj = 2:size(RawData,2)
    ElectricMotorUnitReference.(RawData{2,jj}) = RawData{3,jj};
end

% Save output
save(fullfile("+DatabasePkg", "+ElectricMotorPkg", "IDEAS_EM_DB.mat"),'ElectricMotors','ElectricMotorUnitReference')

% Output confirmation message
disp('Electric Motor Database has successfully been initialized.')

end % end DatabasePkg.ElectricMotorPkg.InitializeMotorDB