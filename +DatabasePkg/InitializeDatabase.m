function [] = InitializeDatabase(AssumedM)
% [] = InitalizeDatabase()
%
% Written By Maxfield Arnson; marnson@umich.edu
% Last updated 11/20/2023
%
% This function reads in the IDEAS Lab database and writes the data to the
% aircraft structures that are used in the FAST sizing code. These are 
% stored in the DatabasesV2 package in IDEAS_DB.mat. In addition, it
% calculates useful ratios for the aircraft structures such as thrust to
% weight and wingloading for each of the aircraft. It has no inputs and no
% outputs.
%
% It also creates excel files intended to be used as an inputs in the JMP
% application for data analysis. These files are located in the
% DatabasesV2 Package.
%
%


clc; close all;

switch nargin
    case 1
    case 0
        AssumedM = 0.8;
end

%% Read in AC Data, assign variables

% Fans
[~,~,RawTF] = xlsread(fullfile("+DatabasePkg", "EAP_Databases_Offline.xlsx"),'Jet Aircraft');

for ii = 8:size(RawTF,2) % change upper value later on
    if isnan(RawTF{2,ii})
        continue
    end
    for jj = 3:58
        if isnan(RawTF{jj,3})
            continue
        end
        SubStructs = sum(isnan(RawTF{jj,5})) + sum(isnan(RawTF{jj,6}));
        switch SubStructs
            case 0
                TurbofanAC.(RawTF{2,ii}).(RawTF{jj,3}).(RawTF{jj,4}).(RawTF{jj,5}).(RawTF{jj,6}) = RawTF{jj,ii};
            case 1
                TurbofanAC.(RawTF{2,ii}).(RawTF{jj,3}).(RawTF{jj,4}).(RawTF{jj,5}) = RawTF{jj,ii};
            case 2
                TurbofanAC.(RawTF{2,ii}).(RawTF{jj,3}).(RawTF{jj,4}) = RawTF{jj,ii};
        end
        
    end
end

% Props
[~,~,RawTP] = xlsread(fullfile("+DatabasePkg", "EAP_Databases_Offline.xlsx"),'Propeller Aircraft');

for ii = 8:size(RawTP,2) % change upper value later on
    if isnan(RawTP{2,ii})
        continue
    end
    for jj = 3:66
        if isnan(RawTP{jj,3})
            continue
        end
        SubStructs = sum(isnan(RawTP{jj,5})) + sum(isnan(RawTP{jj,6}));
        switch SubStructs
            case 0
                TurbopropAC.(RawTP{2,ii}).(RawTP{jj,3}).(RawTP{jj,4}).(RawTP{jj,5}).(RawTP{jj,6}) = RawTP{jj,ii};
            case 1
                TurbopropAC.(RawTP{2,ii}).(RawTP{jj,3}).(RawTP{jj,4}).(RawTP{jj,5}) = RawTP{jj,ii};
            case 2
                TurbopropAC.(RawTP{2,ii}).(RawTP{jj,3}).(RawTP{jj,4}) = RawTP{jj,ii};
        end
        
    end
end



%% Assign AC Units

% Fans
for kk = 3:61
    if isnan(RawTF{kk,2})
        continue
    end
    SubStructs = sum(isnan(RawTF{kk,5})) + sum(isnan(RawTF{kk,6}));
    switch SubStructs
        case 0
            FanUnitsReference.(RawTF{kk,3}).(RawTF{kk,4}).(RawTF{kk,5}).(RawTF{kk,6}) = RawTF{kk,2};
        case 1
            FanUnitsReference.(RawTF{kk,3}).(RawTF{kk,4}).(RawTF{kk,5}) = RawTF{kk,2};
        case 2
            FanUnitsReference.(RawTF{kk,3}).(RawTF{kk,4}) = RawTF{kk,2};
    end
end

% Props
for kk = 3:66
    if isnan(RawTP{kk,2})
        continue
    end
    SubStructs = sum(isnan(RawTP{kk,5})) + sum(isnan(RawTP{kk,6}));
    switch SubStructs
        case 0
            PropUnitsReference.(RawTP{kk,3}).(RawTP{kk,4}).(RawTP{kk,5}).(RawTP{kk,6}) = RawTP{kk,2};
        case 1
            PropUnitsReference.(RawTP{kk,3}).(RawTP{kk,4}).(RawTP{kk,5}) = RawTP{kk,2};
        case 2
            PropUnitsReference.(RawTP{kk,3}).(RawTP{kk,4}) = RawTP{kk,2};
    end
end


%% Read In Engines

% Fans
[~,~,RawTFE] = xlsread(fullfile("+DatabasePkg", "EAP_Databases_Offline.xlsx"),'Jet Engines');

for ii = 5:size(RawTFE,2)
    if strcmp(RawTFE{2,ii},'IGNORECOLUMN')
        continue
    elseif isnan(RawTFE{2,ii})
        continue
    end
    for jj = 4:60
        if isnan(RawTFE{jj,3})
            continue
        end
        TurbofanEngines.(RawTFE{2,ii}).(RawTFE{jj,3}) = RawTFE{jj,ii};
    end
end

% Add pressure per stage

FanEngineFields = fieldnames(TurbofanEngines);

for ii = 1:length(FanEngineFields)
TurbofanEngines.(FanEngineFields{ii}).PresPerStage = ...
    TurbofanEngines.(FanEngineFields{ii}).OPR_SLS^(1/(TurbofanEngines.(FanEngineFields{ii}).FanStages+TurbofanEngines.(FanEngineFields{ii}).LPCStages+TurbofanEngines.(FanEngineFields{ii}).IPCStages+TurbofanEngines.(FanEngineFields{ii}).HPCStages+TurbofanEngines.(FanEngineFields{ii}).RCStages));
end

% Props
[~,~,RawTPE] = xlsread(fullfile("+DatabasePkg", "EAP_Databases_Offline.xlsx"),'Propeller Engines');

for ii = 5:size(RawTPE,2)
    if strcmp(RawTPE{2,ii},'IGNORECOLUMN')
        continue
    elseif isnan(RawTPE{2,ii})
        continue
    end
    for jj = 4:66
        if isnan(RawTPE{jj,3})
            continue
        end
        TurbopropEngines.(RawTPE{2,ii}).(RawTPE{jj,3}) = RawTPE{jj,ii};
    end
end


%% Assign Engines to AC

% Fans
FanFields = fieldnames(TurbofanAC);
for ii = 1:length(FanFields)
    TurbofanAC.(FanFields{ii}).Specs.Propulsion.Engine = TurbofanEngines.(TurbofanAC.(FanFields{ii}).Specs.Propulsion.EngineDesignation);
end

% Props
PropFields = fieldnames(TurbopropAC);
for ii = 1:length(PropFields)
    TurbopropAC.(PropFields{ii}).Specs.Propulsion.Engine = TurbopropEngines.(TurbopropAC.(PropFields{ii}).Specs.Propulsion.EngineDesignation);
end

%% Assign Engine Units
% from the databse extract the units and create structures that mimic the
% format of the data such that a reference is created to check which values
% in the data structures are in which units

% Fans
for ii = 4:60
    if isnan(RawTFE{ii,3})
        continue
    end
FanEngineUnits.(RawTFE{ii,3}) = RawTFE{ii,2};
end
FanEngineUnits.PresPerStage = "ratio";



% Props
for ii = 4:66
    if isnan(RawTPE{ii,3})
        continue
    end
PropEngineUnits.(RawTPE{ii,3}) = RawTPE{ii,2};
end

%% Manual Touch ups

% these aircraft were assigned the wrong units in the database
TurbopropAC.D228_100.Specs.Performance.Vels.Crs = 0.4;%UnitConversionPkg.ConvLength(223,'naut mi','m')/3600;
TurbopropAC.D228_101.Specs.Performance.Vels.Crs = 0.4;%UnitConversionPkg.ConvLength(223,'naut mi','m')/3600;
TurbopropAC.D228_200.Specs.Performance.Vels.Crs = 0.4;%UnitConversionPkg.ConvLength(223,'naut mi','m')/3600;
TurbopropAC.D228_201.Specs.Performance.Vels.Crs = 0.4;%UnitConversionPkg.ConvLength(223,'naut mi','m')/3600;
TurbopropAC.D228_202.Specs.Performance.Vels.Crs = 0.4;%UnitConversionPkg.ConvLength(223,'naut mi','m')/3600;

%% Calculated Values
% Call functions that calculate all desired ratios from the data in the
% database. e.g. taper ratio or AR. Additionally process the units to match
% the updated values

% Fans
for ll = 1:length(FanFields)
    TurbofanAC.(FanFields{ll}) = DatabasePkg.CalcFanVals(TurbofanAC.(FanFields{ll}),"Vals",AssumedM);
end

FanUnitsReference.Specs.Propulsion.Engine = FanEngineUnits;
FanUnitsReference = DatabasePkg.CalcFanVals(FanUnitsReference,"Units",AssumedM);

% Props

for ll = 1:length(PropFields)
    TurbopropAC.(PropFields{ll}) = DatabasePkg.CalcPropVals(TurbopropAC.(PropFields{ll}),"Vals");
end

PropUnitsReference.Specs.Propulsion.Engine = PropEngineUnits;
PropUnitsReference = DatabasePkg.CalcPropVals(PropUnitsReference,"Units");


%% Create JMP Files
% these are excel sheets 


% Fans
[JMPCellFans] = DatabasePkg.StructTreeSearch(FanUnitsReference);
for mm = 1:length(FanFields)
    ParamValues = DatabasePkg.StructTreeSearch(TurbofanAC.(FanFields{mm}));
    JMPCellFans(mm+2,:) = ParamValues(2,:);
end

FanFields = [cell(2,1);FanFields];
JMPCellFans = [FanFields,JMPCellFans];
JMPCellFans{1,1} = "AircraftDesignation";
JMPCellFans{2,1} = "name";

% Props
[JMPCellProps] = DatabasePkg.StructTreeSearch(PropUnitsReference);
for mm = 1:length(PropFields)
    ParamValues = DatabasePkg.StructTreeSearch(TurbopropAC.(PropFields{mm}));
    JMPCellProps(mm+2,:) = ParamValues(2,:);
end

PropFields = [cell(2,1);PropFields];
JMPCellProps = [PropFields,JMPCellProps];
JMPCellProps{1,1} = "AircraftDesignation";
JMPCellProps{2,1} = "name";

% write JMP matrices to excel files
writecell(JMPCellFans,  fullfile("+DatabasePkg", "JMPInputSheetFANS.xlsx" ))
writecell(JMPCellProps, fullfile("+DatabasePkg", "JMPInputSheetPROPS.xlsx"))


%% Write Databases to .mat file

save(fullfile("+DatabasePkg", "IDEAS_DB.mat"),'TurbofanAC','TurbofanEngines','TurbopropAC','TurbopropEngines','FanUnitsReference','PropUnitsReference')

disp('Databases successfully initialized.')

end







