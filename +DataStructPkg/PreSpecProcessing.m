function [Aircraft] = PreSpecProcessing(Aircraft)
%
% [Aircraft] = PreSpecProcessing(Aircraft)
% written by Max Arnson, marnson@umich.edu
% last updated: 29 mar 2024
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
    Aircraft.Specs.Propulsion.Engine = NaN;
    Aircraft.Specs.Propulsion.NumEngines = NaN;
    Aircraft.Specs.Propulsion.T_W.SLS = NaN;
    Aircraft.Specs.Propulsion.Thrust.SLS = NaN;
    Aircraft.Specs.Propulsion.Eta.Prop = NaN;
    Aircraft.Specs.Propulsion.MDotCF = NaN;
    Aircraft.Specs.Propulsion.Arch.Type = NaN;
    Aircraft.Specs.Power.SpecEnergy.Fuel = NaN;
    Aircraft.Specs.Power.SpecEnergy.Batt = NaN;
    Aircraft.Specs.Power.Eta.EM = NaN;
    Aircraft.Specs.Power.Eta.EG = NaN;
    Aircraft.Specs.Power.Eta.Propeller = NaN;
    Aircraft.Specs.Power.P_W.SLS = NaN;
    Aircraft.Specs.Power.P_W.EM = NaN;
    Aircraft.Specs.Power.P_W.EG = NaN;
    Aircraft.Specs.Power.LamTS.Split = NaN;
    Aircraft.Specs.Power.LamTS.SLS = NaN;
    Aircraft.Specs.Power.LamTSPS.Split = NaN;
    Aircraft.Specs.Power.LamTSPS.SLS = NaN;
    Aircraft.Specs.Power.LamPSES.Split = NaN;
    Aircraft.Specs.Power.LamPSES.SLS = NaN;
    Aircraft.Specs.Power.LamPSPS.Split = NaN;
    Aircraft.Specs.Power.LamPSPS.SLS = NaN;
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
    end


    % Propulsion


    if ~isfield(Aircraft.Specs,"Propulsion")
        Aircraft.Specs.Propulsion.Engine = NaN;
        Aircraft.Specs.Propulsion.NumEngines = NaN;
        Aircraft.Specs.Propulsion.T_W.SLS = NaN;
        Aircraft.Specs.Propulsion.Thrust.SLS = NaN;
        Aircraft.Specs.Propulsion.Eta.Prop = NaN;
        Aircraft.Specs.Propulsion.MDotCF = NaN;
        Aircraft.Specs.Propulsion.Arch.Type = NaN;
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
        if ~isfield(Aircraft.Specs.Propulsion,"Arch")
            Aircraft.Specs.Propulsion.Arch.Type = NaN;
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
        Aircraft.Specs.Power.LamTS.Split = NaN;
        Aircraft.Specs.Power.LamTS.Alt = NaN;
        Aircraft.Specs.Power.LamTS.SLS = NaN;
        Aircraft.Specs.Power.LamTSPS.Split = NaN;
        Aircraft.Specs.Power.LamTSPS.Alt = NaN;
        Aircraft.Specs.Power.LamTSPS.SLS = NaN;
        Aircraft.Specs.Power.LamPSES.Split = NaN;
        Aircraft.Specs.Power.LamPSES.Alt = NaN;
        Aircraft.Specs.Power.LamPSES.SLS = NaN;
        Aircraft.Specs.Power.LamPSPS.Split = NaN;
        Aircraft.Specs.Power.LamPSPS.Alt = NaN;
        Aircraft.Specs.Power.LamPSPS.SLS = NaN;
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

        if ~isfield(Aircraft.Specs.Power,"LamTS")
            Aircraft.Specs.Power.LamTS.Alt = NaN;
            Aircraft.Specs.Power.LamTS.SLS = NaN;
            Aircraft.Specs.Power.LamTS.Split = NaN;
        else
            if ~isfield(Aircraft.Specs.Power.LamTS,"Split")
                Aircraft.Specs.Power.LamTS.Split = NaN;
            end
            if ~isfield(Aircraft.Specs.Power.LamTS,"Alt")
                Aircraft.Specs.Power.LamTS.Alt = NaN;
            end
            if ~isfield(Aircraft.Specs.Power.LamTS,"SLS")
                Aircraft.Specs.Power.LamTS.SLS = NaN;
            end
        end

        if ~isfield(Aircraft.Specs.Power,"LamTSPS")
            Aircraft.Specs.Power.LamTSPS.Alt = NaN;
            Aircraft.Specs.Power.LamTSPS.SLS = NaN;
            Aircraft.Specs.Power.LamTSPS.Split = NaN;
        else
            if ~isfield(Aircraft.Specs.Power.LamTSPS,"Split")
                Aircraft.Specs.Power.LamTSPS.Split = NaN;
            end
            if ~isfield(Aircraft.Specs.Power.LamTSPS,"Alt")
                Aircraft.Specs.Power.LamTSPS.Alt = NaN;
            end
            if ~isfield(Aircraft.Specs.Power.LamTSPS,"SLS")
                Aircraft.Specs.Power.LamTSPS.SLS = NaN;
            end
        end

        if ~isfield(Aircraft.Specs.Power,"LamPSPS")
            Aircraft.Specs.Power.LamPSPS.Alt = NaN;
            Aircraft.Specs.Power.LamPSPS.SLS = NaN;
            Aircraft.Specs.Power.LamPSPS.Split = NaN;
        else
            if ~isfield(Aircraft.Specs.Power.LamPSPS,"Split")
                Aircraft.Specs.Power.LamPSPS.Split = NaN;
            end
            if ~isfield(Aircraft.Specs.Power.LamPSPS,"Alt")
                Aircraft.Specs.Power.LamPSPS.Alt = NaN;
            end
            if ~isfield(Aircraft.Specs.Power.LamPSPS,"SLS")
                Aircraft.Specs.Power.LamPSPS.SLS = NaN;
            end
        end

        if ~isfield(Aircraft.Specs.Power,"LamPSES")
            Aircraft.Specs.Power.LamPSES.Alt = NaN;
            Aircraft.Specs.Power.LamPSES.SLS = NaN;
            Aircraft.Specs.Power.LamPSES.Split = NaN;
        else
            if ~isfield(Aircraft.Specs.Power.LamPSES,"Split")
                Aircraft.Specs.Power.LamPSES.Split = NaN;
            end
            if ~isfield(Aircraft.Specs.Power.LamPSES,"Alt")
                Aircraft.Specs.Power.LamPSES.Alt = NaN;
            end
            if ~isfield(Aircraft.Specs.Power.LamPSES,"SLS")
                Aircraft.Specs.Power.LamPSES.SLS = NaN;
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
