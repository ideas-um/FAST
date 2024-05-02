function [known, unknown] = VaryUserInputs(Aircraft,FanPropFlag)
% function [known, unknown] = VaryUserInputs(Aircraft)
% GPR pre-processing function
% Written by Maxfield Arnson
%
% This low level function is called while preprocessing user inputs before
% they are sized by main and eapSizing. Based on a user input file, it
% decides which fields are independent and dependent variables for the
% Gaussian process regression.
%
%
% INPUTS:
% Aircraft = the structure defined by the user after running an
%   initialization function, such as CustomAircraft()
%
%
% OUTPUTS:
% known = structure with subfields
%   names = names of independent variables as they appear in the aircraft
%       database
%   values = numerical values of the independent variables
%
% unknown = names of dependent variables as they appear in the aircraft
%   database

%% Assign universal (regardless of class) values from the aircraft struct
values.vto  = Aircraft.Specs.Performance.Vels.Tko;
values.vcr  = Aircraft.Specs.Performance.Vels.Crs;
values.hcr  = Aircraft.Specs.Performance.Alts.Crs;
values.mtow = Aircraft.Specs.Weight.MTOW;
values.ws = Aircraft.Specs.Aero.W_S.SLS;
        values.ldcr = Aircraft.Specs.Aero.L_D.Crs;

names.vto  = ["Specs","Performance","Vels","Tko"];
names.vcr  = ["Specs","Performance","Vels","Crs"];
names.hcr  = ["Specs","Performance","Alts","Crs"];
names.mtow = ["Specs","Weight","MTOW"];
names.ws = ["Specs","Aero","W_S","SLS"];
        names.ldcr = ["Specs","Aero","L_D","Crs"];

%% Assign class specific parameters from the aircraft struct
switch FanPropFlag
    case "Turbofan"
        values.tw  = Aircraft.Specs.Propulsion.T_W.SLS;
        values.tsls  = Aircraft.Specs.Propulsion.Thrust.SLS;
        names.tw  = ["Specs","Propulsion","T_W","SLS"];
        names.tsls  = ["Specs","Propulsion","Thrust","Crs"];


    case "Turboprop"
        values.pw = Aircraft.Specs.Power.P_W.SLS;
        values.psls  = Aircraft.Specs.Power.SLS;      
        names.pw = ["Specs","Power","P_W","SLS"];
        names.psls  = ["Specs","Power","Crs"];     
end

%% Initialize known and unknown parameters
known.names = {};
known.values = nan(1,20);
unknown = {};

%% Loop through all parameters and assign known or unknown
% the parameter is assumed unknown if its value is NaN
fields = fieldnames(values);

for i = 1:length(fields)
    if isnan(values.(fields{i}))
        unknown{end+1} = names.(fields{i});
    else
        known.names{end+1} = names.(fields{i});
        known.values(i) = values.(fields{i});
    end

end

%% Remove missing values from the initialized known structure
% these were added as placeholders
known.values = rmmissing(known.values);

% add fuel weight to the unknowns since this is not user specified
unknown{end+1} = ["Specs","Weight","Fuel"];

end






