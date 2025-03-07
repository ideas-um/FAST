function [Aircraft] = PreSpecProcessing(Aircraft)
%
% [Aircraft] = PreSpecProcessing(Aircraft)
% written by Max Arnson, marnson@umich.edu
% last updated: 04 mar 2025
%
% Instantiate any variables not specified in an aircraft data structure.
% This function allows users to neglect to assign NaN values to parameters
% they wish to be calculated using regressions
%
% INPUTS:
%     Aircraft - aircraft data structure as entered by a user
%                size/type/units: 1-by-1 / struct / []
%
% OUTPUTS:
%     Aircraft - aircraft data structure with all unspecified parameters
%                instantiated and assigned NaN
%                size/type/units: 1-by-1 / struct / []
%

%% Check Spec Fields

if ~ isfield(Aircraft,"Specs")
    Aircraft.Specs.TLAR.EIS = NaN;
    Aircraft.Specs.TLAR.Class = NaN;
    Aircraft.Specs.TLAR.MaxPax = NaN;
    Aircraft.Specs.Performance.Vels.Tko = NaN;
    Aircraft.Specs.Performance.Vels.Crs = NaN;
    Aircraft.Specs.Performance.Alts.Tko = NaN;
    Aircraft.Specs.Performance.Alts.Crs = NaN;
    Aircraft.Specs.Performance.RCMax = NaN;
    Aircraft.Specs.Performance.Range = NaN;
    Aircraft.Specs.Aero.L_D.Clb = NaN;
    Aircraft.Specs.Aero.L_D.Crs = NaN;
    Aircraft.Specs.Aero.L_D.Des = NaN;
    Aircraft.Specs.Aero.W_S.SLS = NaN;
    Aircraft.Specs.Weight.MTOW = NaN;
    Aircraft.Specs.Weight.EG = NaN;
    Aircraft.Specs.Weight.EM = NaN;
    Aircraft.Specs.Weight.Fuel = NaN;
    Aircraft.Specs.Weight.Batt = NaN;
    Aircraft.Specs.Weight.WairfCF = NaN;
    Aircraft.Specs.Weight.EAP = NaN;
    Aircraft.Specs.Propulsion.Engine = NaN;
    Aircraft.Specs.Propulsion.NumEngines = NaN;
    Aircraft.Specs.Propulsion.T_W.SLS = NaN;
    Aircraft.Specs.Propulsion.Thrust.SLS = NaN;
    Aircraft.Specs.Propulsion.Eta.Prop = NaN;
    Aircraft.Specs.Propulsion.MDotCF = NaN;
    Aircraft.Specs.Propulsion.PropArch.Type = NaN;
    Aircraft.Specs.Power.SpecEnergy.Fuel = NaN;
    Aircraft.Specs.Power.SpecEnergy.Batt = NaN;
    Aircraft.Specs.Power.Eta.EM = NaN;
    Aircraft.Specs.Power.Eta.EG = NaN;
    Aircraft.Specs.Power.Eta.Propeller = NaN;
    Aircraft.Specs.Power.P_W.SLS = NaN;
    Aircraft.Specs.Power.P_W.EM = NaN;
    Aircraft.Specs.Power.P_W.EG = NaN;
    Aircraft.Specs.Power.LamDwn.SLS = NaN;
    Aircraft.Specs.Power.LamUps.SLS = NaN;
    Aircraft.Specs.Power.Battery.ParCells = NaN;
    Aircraft.Specs.Power.Battery.SerCells =  NaN;
    Aircraft.Specs.Power.Battery.BegSOC = NaN;


else

    % Top Level Aircraft Requirements

    if ~isfield(Aircraft.Specs,"TLAR")
        Aircraft.Specs.TLAR.EIS = NaN;
        Aircraft.Specs.TLAR.Class = NaN;
        Aircraft.Specs.TLAR.MaxPax = NaN;
    else
        if ~isfield(Aircraft.Specs.TLAR,"EIS")
            Aircraft.Specs.TLAR.EIS = NaN;
        end
        if ~isfield(Aircraft.Specs.TLAR,"Class")
            Aircraft.Specs.TLAR.Class = NaN;
        end
        if ~isfield(Aircraft.Specs.TLAR,"MaxPax")
            Aircraft.Specs.TLAR.MaxPax = NaN;
        end
    end

    % Performance

    if ~isfield(Aircraft.Specs,"Performance")
        Aircraft.Specs.Performance.Vels.Tko = NaN;
        Aircraft.Specs.Performance.Vels.Crs = NaN;
        Aircraft.Specs.Performance.Alts.Tko = NaN;
        Aircraft.Specs.Performance.Alts.Crs = NaN;
        Aircraft.Specs.Performance.RCMax = NaN;
        Aircraft.Specs.Performance.Range = NaN;

    else
        if ~isfield(Aircraft.Specs.Performance,"Vels")
            Aircraft.Specs.Performance.Vels.Tko = NaN;
            Aircraft.Specs.Performance.Vels.Crs = NaN;
        elseif ~isfield(Aircraft.Specs.Performance.Vels,"Tko")
            Aircraft.Specs.Performance.Vels.Tko = NaN;
        elseif ~isfield(Aircraft.Specs.Performance.Vels,"Crs")
            Aircraft.Specs.Performance.Vels.Crs = NaN;
        end
        if ~isfield(Aircraft.Specs.Performance,"Alts")
            Aircraft.Specs.Performance.Alts.Tko = NaN;
            Aircraft.Specs.Performance.Alts.Crs = NaN;
        else
            if ~isfield(Aircraft.Specs.Performance.Alts,"Tko")
                Aircraft.Specs.Performance.Alts.Tko = NaN;
            end
            if ~isfield(Aircraft.Specs.Performance.Alts,"Crs")
                Aircraft.Specs.Performance.Alts.Crs = NaN;
            end
        end
        if ~isfield(Aircraft.Specs.Performance,"RCMax")
            Aircraft.Specs.Performance.RCMax = NaN;
        end
        if ~isfield(Aircraft.Specs.Performance,"Range")
            Aircraft.Specs.Performance.Range = NaN;
        end
    end

    % Aerodynamics

    if ~isfield(Aircraft.Specs,"Aero")
        Aircraft.Specs.Aero.L_D.Clb = NaN;
        Aircraft.Specs.Aero.L_D.Crs = NaN;
        Aircraft.Specs.Aero.L_D.Des = NaN;
        Aircraft.Specs.Aero.W_S.SLS = NaN;
    else
        if ~isfield(Aircraft.Specs.Aero,"L_D")
            Aircraft.Specs.Aero.L_D.Clb = NaN;
            Aircraft.Specs.Aero.L_D.Crs = NaN;
            Aircraft.Specs.Aero.L_D.Des = NaN;
        else
            if ~isfield(Aircraft.Specs.Aero.L_D,"Clb")
                Aircraft.Specs.Aero.L_D.Clb = NaN;
            end
            if ~isfield(Aircraft.Specs.Aero.L_D,"Crs")
                Aircraft.Specs.Aero.L_D.Crs = NaN;
            end
            if ~isfield(Aircraft.Specs.Aero.L_D,"Des")
                Aircraft.Specs.Aero.L_D.Des = NaN;
            end
        end
        if ~isfield(Aircraft.Specs.Aero,"W_S")
            Aircraft.Specs.Aero.W_S.SLS = NaN;
        end
    end

    % Weight

    if ~isfield(Aircraft.Specs,"Weight")
        Aircraft.Specs.Weight.MTOW = NaN;
        Aircraft.Specs.Weight.EG = NaN;
        Aircraft.Specs.Weight.EM = NaN;
        Aircraft.Specs.Weight.Fuel = NaN;
        Aircraft.Specs.Weight.Batt = NaN;
        Aircraft.Specs.Weight.WairfCF = NaN;
        Aircraft.Specs.Weight.EAP = NaN;
    else
        if ~isfield(Aircraft.Specs.Weight,"MTOW")
            Aircraft.Specs.Weight.MTOW = NaN;
        end
        if ~isfield(Aircraft.Specs.Weight,"EG")
            Aircraft.Specs.Weight.EG = NaN;
        end
        if ~isfield(Aircraft.Specs.Weight,"EM")
            Aircraft.Specs.Weight.EM = NaN;
        end
        if ~isfield(Aircraft.Specs.Weight,"Fuel")
            Aircraft.Specs.Weight.Fuel = NaN;
        end
        if ~isfield(Aircraft.Specs.Weight,"Batt")
            Aircraft.Specs.Weight.Batt = NaN;
        end
        if ~isfield(Aircraft.Specs.Weight,"WairfCF")
            Aircraft.Specs.Weight.WairfCF = NaN;
        end
        if ~isfield(Aircraft.Specs.Weight,"EAP")
            Aircraft.Specs.Weight.EAP = NaN;
        end
    end


    % Propulsion


    if ~isfield(Aircraft.Specs,"Propulsion")
        Aircraft.Specs.Propulsion.Engine = NaN;
        Aircraft.Specs.Propulsion.NumEngines = NaN;
        Aircraft.Specs.Propulsion.T_W.SLS = NaN;
        Aircraft.Specs.Propulsion.Thrust.SLS = NaN;
        Aircraft.Specs.Propulsion.Eta.Prop = NaN;
        Aircraft.Specs.Propulsion.MDotCF = NaN;
        Aircraft.Specs.Propulsion.PropArch.Type = NaN;
    else
        if ~isfield(Aircraft.Specs.Propulsion,"Engine")
            Aircraft.Specs.Propulsion.Engine = NaN;
        end
        if ~isfield(Aircraft.Specs.Propulsion,"NumEngines")
            Aircraft.Specs.Propulsion.NumEngines = NaN;
        end
        if ~isfield(Aircraft.Specs.Propulsion,"T_W")
            Aircraft.Specs.Propulsion.T_W.SLS = NaN;
        end
        if ~isfield(Aircraft.Specs.Propulsion,"Thrust")
            Aircraft.Specs.Propulsion.Thrust.SLS = NaN;
        end
        if ~isfield(Aircraft.Specs.Propulsion,"Eta")
            Aircraft.Specs.Propulsion.Eta.Prop = NaN;
        end
        if ~isfield(Aircraft.Specs.Propulsion,"MDotCF")
            Aircraft.Specs.Propulsion.MDotCF = NaN;
        end
        if ~isfield(Aircraft.Specs.Propulsion,"PropArch")
            Aircraft.Specs.Propulsion.PropArch.Type = NaN;
        end
    end



    % Power

    if ~isfield(Aircraft.Specs,"Power")
        Aircraft.Specs.Power.SLS = NaN;
        Aircraft.Specs.Power.SpecEnergy.Fuel = NaN;
        Aircraft.Specs.Power.SpecEnergy.Batt = NaN;
        Aircraft.Specs.Power.Eta.EM = NaN;
        Aircraft.Specs.Power.Eta.EG = NaN;
        Aircraft.Specs.Power.Eta.Propeller = NaN;
        Aircraft.Specs.Power.P_W.SLS = NaN;
        Aircraft.Specs.Power.P_W.EM = NaN;
        Aircraft.Specs.Power.P_W.EG = NaN;
        Aircraft.Specs.Power.LamDwn.SLS = NaN;
        Aircraft.Specs.Power.LamUps.SLS = NaN;
        Aircraft.Specs.Power.Battery.ParCells = NaN;
        Aircraft.Specs.Power.Battery.SerCells =  NaN;
        Aircraft.Specs.Power.Battery.BegSOC = NaN;
    else
        if ~isfield(Aircraft.Specs.Power,"SLS")
            Aircraft.Specs.Power.SLS = NaN;
        end
        if ~isfield(Aircraft.Specs.Power,"SpecEnergy")
            Aircraft.Specs.Power.SpecEnergy.Fuel = NaN;
            Aircraft.Specs.Power.SpecEnergy.Batt = NaN;
        else
            if ~isfield(Aircraft.Specs.Power.SpecEnergy,"Fuel")
                Aircraft.Specs.Power.SpecEnergy.Fuel = NaN;
            end
            if ~isfield(Aircraft.Specs.Power.SpecEnergy,"Batt")
                Aircraft.Specs.Power.SpecEnergy.Batt = NaN;
            end
        end

        if ~isfield(Aircraft.Specs.Power,"Eta")
            Aircraft.Specs.Power.Eta.EM = NaN;
            Aircraft.Specs.Power.Eta.EG = NaN;
            Aircraft.Specs.Power.Eta.Propeller = NaN;
        else
            if ~isfield(Aircraft.Specs.Power.Eta,"EM")
                Aircraft.Specs.Power.Eta.EM = NaN;
            end
            if ~isfield(Aircraft.Specs.Power.Eta,"EG")
                Aircraft.Specs.Power.Eta.EG = NaN;
            end
            if ~isfield(Aircraft.Specs.Power.Eta,"Propeller")
                Aircraft.Specs.Power.Eta.Propeller = NaN;
            end
        end

        if ~isfield(Aircraft.Specs.Power,"SLS")
            Aircraft.Specs.Power.P_W.SLS = NaN;
            Aircraft.Specs.Power.P_W.EM = NaN;
            Aircraft.Specs.Power.P_W.EG = NaN;
        else
            if ~isfield(Aircraft.Specs.Power.P_W,"SLS")
                Aircraft.Specs.Power.P_W.SLS = NaN;
            end
            if ~isfield(Aircraft.Specs.Power.P_W,"EM")
                Aircraft.Specs.Power.P_W.EM = NaN;
            end
            if ~isfield(Aircraft.Specs.Power.P_W,"EG")
                Aircraft.Specs.Power.P_W.EG = NaN;
            end
        end

        if ~isfield(Aircraft.Specs.Power,"LamDwn")
            Aircraft.Specs.Power.LamDwn.SLS = NaN;
            Aircraft.Specs.Power.LamDwn.Tko = NaN;
            Aircraft.Specs.Power.LamDwn.Clb = NaN;
            Aircraft.Specs.Power.LamDwn.Crs = NaN;
            Aircraft.Specs.Power.LamDwn.Des = NaN;
            Aircraft.Specs.Power.LamDwn.Lnd = NaN;
        else
            if ~isfield(Aircraft.Specs.Power.LamDwn,"SLS")
                Aircraft.Specs.Power.LamDwn.SLS = NaN;
            end
            if ~isfield(Aircraft.Specs.Power.LamDwn,"Tko")
                Aircraft.Specs.Power.LamDwn.Tko = NaN;
            end
            if ~isfield(Aircraft.Specs.Power.LamDwn,"Clb")
                Aircraft.Specs.Power.LamDwn.Clb = NaN;
            end
            if ~isfield(Aircraft.Specs.Power.LamDwn,"Crs")
                Aircraft.Specs.Power.LamDwn.Crs = NaN;
            end
            if ~isfield(Aircraft.Specs.Power.LamDwn,"Des")
                Aircraft.Specs.Power.LamDwn.Des = NaN;
            end
            if ~isfield(Aircraft.Specs.Power.LamDwn,"Lnd")
                Aircraft.Specs.Power.LamDwn.Lnd = NaN;
            end
        end

        if ~isfield(Aircraft.Specs.Power,"LamUps")
            Aircraft.Specs.Power.LamUps.SLS = NaN;
            Aircraft.Specs.Power.LamUps.Tko = NaN;
            Aircraft.Specs.Power.LamUps.Clb = NaN;
            Aircraft.Specs.Power.LamUps.Crs = NaN;
            Aircraft.Specs.Power.LamUps.Des = NaN;
            Aircraft.Specs.Power.LamUps.Lnd = NaN;
        else
            if ~isfield(Aircraft.Specs.Power.LamUps,"SLS")
                Aircraft.Specs.Power.LamUps.SLS = NaN;
            end
            if ~isfield(Aircraft.Specs.Power.LamUps,"Tko")
                Aircraft.Specs.Power.LamUps.Tko = NaN;
            end
            if ~isfield(Aircraft.Specs.Power.LamUps,"Clb")
                Aircraft.Specs.Power.LamUps.Clb = NaN;
            end
            if ~isfield(Aircraft.Specs.Power.LamUps,"Crs")
                Aircraft.Specs.Power.LamUps.Crs = NaN;
            end
            if ~isfield(Aircraft.Specs.Power.LamUps,"Des")
                Aircraft.Specs.Power.LamUps.Des = NaN;
            end
            if ~isfield(Aircraft.Specs.Power.LamUps,"Lnd")
                Aircraft.Specs.Power.LamUps.Lnd = NaN;
            end
        end
        
        if ~isfield(Aircraft.Specs.Power,"Battery")
            Aircraft.Specs.Power.Battery.ParCells = NaN;
            Aircraft.Specs.Power.Battery.SerCells =  NaN;
            Aircraft.Specs.Power.Battery.BegSOC = NaN;
        else
            if ~isfield(Aircraft.Specs.Power.Battery,"ParCells")
                Aircraft.Specs.Power.Battery.ParCells = NaN;
            end
            if ~isfield(Aircraft.Specs.Power.Battery,"SerCells")
                Aircraft.Specs.Power.Battery.SerCells =  NaN;
            end
            if ~isfield(Aircraft.Specs.Power.Battery,"BegSOC")
                Aircraft.Specs.Power.Battery.BegSOC = NaN;
            end
        end
    end
end

%% Check Settings Fields

if ~isfield(Aircraft,"Settings")
    Aircraft.Settings.TkoPoints = NaN;
    Aircraft.Settings.ClbPoints = NaN;
    Aircraft.Settings.CrsPoints = NaN;
    Aircraft.Settings.DesPoints = NaN;
    Aircraft.Settings.OEW.MaxIter = NaN;
    Aircraft.Settings.OEW.Tol = NaN;
    Aircraft.Settings.Analysis.MaxIter = NaN;
    Aircraft.Settings.Analysis.Type = NaN;
    Aircraft.Settings.Plotting = NaN;
    Aircraft.Settings.Table = NaN;
    Aircraft.Settings.VisualizeAircraft = NaN;
    Aircraft.Settings.Dir.Size = NaN;
    Aircraft.Settings.Dir.Oper = NaN;
else
    if ~isfield(Aircraft.Settings,"TkoPoints")
        Aircraft.Settings.TkoPoints = NaN;
    end
    if ~isfield(Aircraft.Settings,"ClbPoints")
        Aircraft.Settings.ClbPoints = NaN;
    end
    if ~isfield(Aircraft.Settings,"CrsPoints")
        Aircraft.Settings.CrsPoints = NaN;
    end
    if ~isfield(Aircraft.Settings,"DesPoints")
        Aircraft.Settings.DesPoints = NaN;
    end
    if ~isfield(Aircraft.Settings,"OEW")
        Aircraft.Settings.OEW.MaxIter = NaN;
        Aircraft.Settings.OEW.Tol = NaN;
    else
        if ~isfield(Aircraft.Settings.OEW,"MaxIter")
            Aircraft.Settings.OEW.MaxIter = NaN;
        end
        if ~isfield(Aircraft.Settings.OEW,"Tol")
            Aircraft.Settings.OEW.Tol = NaN;
        end
    end
    if ~isfield(Aircraft.Settings,"Analysis")
        Aircraft.Settings.Analysis.MaxIter = NaN;
        Aircraft.Settings.Analysis.Type = NaN;
    else
        if ~isfield(Aircraft.Settings.Analysis,"MaxIter")
            Aircraft.Settings.Analysis.MaxIter = NaN;
        end
        if ~isfield(Aircraft.Settings.Analysis,"Type")
            Aircraft.Settings.Analysis.Type = NaN;
        end
    end
    if ~isfield(Aircraft.Settings,"Plotting")
        Aircraft.Settings.Plotting = NaN;
    end
    if ~isfield(Aircraft.Settings,"Table")
        Aircraft.Settings.Table = NaN;
    end
    if ~isfield(Aircraft.Settings,"VisualizeAircraft")
        Aircraft.Settings.VisualizeAircraft = NaN;
    end
    if ~isfield(Aircraft.Settings, "Dir")
        Aircraft.Settings.Dir.Size = NaN;
        Aircraft.Settings.Dir.Oper = NaN;
    else
        if ~isfield(Aircraft.Settings.Dir,"Size")
            Aircraft.Settings.Dir.Size = NaN;
        end
        if ~isfield(Aircraft.Settings.Dir,"Oper")
            Aircraft.Settings.Dir.Oper = NaN;
        end
    end
end


%% Check Geometry fields
if ~isfield(Aircraft,"Geometry")
    Aircraft.Geometry.LengthSet = NaN;
    Aircraft.Geometry.Preset = NaN;
else
    if ~isfield(Aircraft.Geometry,"LengthSet")
        Aircraft.Geometry.LengthSet = NaN;
    end
    if ~isfield(Aircraft.Geometry,"Preset")
        Aircraft.Geometry.Preset = NaN;
    end
end


end