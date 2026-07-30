function [] = InitializeICAO_DB()
%
% [] = InitializeICAO_DB()
% Written by Maxfield Arnson and Arenas Wang
% Updated 3 march 2025
%
% This function initializes a datastructure similar to the one in
% +DatabasePkg.InitializeDatabase. The output of this function is an update
% to a .mat file which will house the off-design engine coefficients and
% relevant input parameters for two sets of engines, one large group of 830
% engines and one smaller group of 30 engines (the smaller group has known
% TSFC at cruise). In the future this could also be used for emissions
% modeling as the raw data for the large sample does include some GHG
% emission data
% 
% INPUTS:
%
%       none
%
% OUTPUTS:
%
%       none (saves a .mat file with the spreadsheet data)

[~,~,Data32] = xlsread(fullfile("+EngineModelPkg", "+SurrogateOffDesignPkg","ICAO_DATA.xlsx"),'30 engines');
[~,~,Data830] = xlsread(fullfile("+EngineModelPkg", "+SurrogateOffDesignPkg","ICAO_DATA.xlsx"),'830 engines');

for ii = 2:size(Data32,1)
    ICAO_Known_Cffch.(Data32{ii,1}).Thrust = Data32{ii,6}*1e3; % convert from kN to N
    ICAO_Known_Cffch.(Data32{ii,1}).OPR = Data32{ii,8};
    ICAO_Known_Cffch.(Data32{ii,1}).BPR = Data32{ii,7};
    ICAO_Known_Cffch.(Data32{ii,1}).TSFC_Crs = Data32{ii,9};
    ICAO_Known_Cffch.(Data32{ii,1}).Cff1 = Data32{ii,4};
    ICAO_Known_Cffch.(Data32{ii,1}).Cff2 = Data32{ii,3};
    ICAO_Known_Cffch.(Data32{ii,1}).Cff3 = Data32{ii,2};
    ICAO_Known_Cffch.(Data32{ii,1}).Cffch = Data32{ii,5}; 
end

for ii = 2:size(Data830,1)
    ICAO_Unknown_Cffch.(Data830{ii,1}).Thrust =       Data830{ii,2}*1e3; % convert from kN to N
    ICAO_Unknown_Cffch.(Data830{ii,1}).OPR =          Data830{ii,7};
    ICAO_Unknown_Cffch.(Data830{ii,1}).BPR =          Data830{ii,6};
    ICAO_Unknown_Cffch.(Data830{ii,1}).Cff1 =         Data830{ii,5};
    ICAO_Unknown_Cffch.(Data830{ii,1}).Cff2 =         Data830{ii,4};
    ICAO_Unknown_Cffch.(Data830{ii,1}).Cff3 =         Data830{ii,3};
    ICAO_Unknown_Cffch.(Data830{ii,1}).Manufacturer = Data830{ii,8}; 
end

save(fullfile("+EngineModelPkg", "+SurrogateOffDesignPkg","ICAO_DATA.mat"),'ICAO_Known_Cffch','ICAO_Unknown_Cffch')

disp('ICAO database successfully initialized.')
end

