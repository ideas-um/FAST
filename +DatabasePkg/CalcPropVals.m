function [Plane] = CalcPropVals(Plane,units)
%
% [Plane] = CalcPropVals(Plane,units)
% Written by Maxfield Arnson
% Updated 10/19/2023
%
% This function takes an aircraft structure from the IDEAS database and
% processes it to add additional fields that can be calculated from the raw
% data. Depending on the units flag, it will either calculate the values
% mentioned or assign them their units.
%
% This function is for turboprop aircraft ONLY. To process turbofans there
% is a second function, called CalcFanVals() also located in the
% DatabasesV2 Package
%
% INPUTS:
%
% Plane = Aircraft in need of updated values
%       size: 1x1 struct
%
% unitsflag = flag to tell the function whether to calculate missing values
%           or just assign the type of units to the new structure fields.
%           useful for consistency/user information
%       size: 1x1 string
%       options:
%           {"Vals"   }
%           {"Units"  }
%
%
% OUTPUTS:
%
% Plane = Modified input structure including the new values calculated
%       size: 1x1 struct
%
%
% List of Updated/New Values:
% ---------------------------
%
% OEW/MTOW
% MZFW/MTOW
% P/W
% Update Aircraft Power to reflect all engines in use
% W/S
% Engine Weight Fraction
% Fuel Fraction
% Flags:
%   Baseline vs. variant
%   Payload Type
%   Passenger Type
% Monikers
% Taper Ratio
% Aspect Ratio
% Cruise L/D

switch units
    case "Vals"
        %% 1: L/D
        % 
        %% 2: OEW/MTOW
        Plane.Specs.Weight.Airframe = Plane.Specs.Weight.OEW - Plane.Specs.Propulsion.Engine.DryWeight*...
            Plane.Specs.Propulsion.NumEngines;
        Plane.Specs.Weight.OEW_MTOW = Plane.Specs.Weight.OEW/Plane.Specs.Weight.MTOW;
        %% 3: Powers and P/W
        if isnan(Plane.Specs.Power.SLS)
            if isnan(Plane.Specs.Propulsion.Engine.Power_SLS_Eq)
                Plane.Specs.Power.SLS = 1000*Plane.Specs.Propulsion.Engine.Power_SLS*Plane.Specs.Propulsion.NumEngines;
            else
                Plane.Specs.Power.SLS = 1000*Plane.Specs.Propulsion.Engine.Power_SLS_Eq*Plane.Specs.Propulsion.NumEngines;
            end
        else
            Plane.Specs.Power.SLS = 1000*Plane.Specs.Power.SLS*Plane.Specs.Propulsion.NumEngines;
        end

        if isnan(Plane.Specs.Power.Cont)
            Plane.Specs.Power.Cont = 1000*Plane.Specs.Propulsion.Engine.Power_Cont_Eq*Plane.Specs.Propulsion.NumEngines;
        else
            Plane.Specs.Power.Cont = 1000*Plane.Specs.Power.Cont*Plane.Specs.Propulsion.NumEngines;
        end

        Plane.Specs.Power.Clb = 1000*Plane.Specs.Power.Clb*Plane.Specs.Propulsion.NumEngines;
        Plane.Specs.Power.Crs = 1000*Plane.Specs.Power.Crs*Plane.Specs.Propulsion.NumEngines;

        Plane.Specs.Power.P_W.SLS = Plane.Specs.Power.SLS...
            /Plane.Specs.Weight.MTOW/1000;

        %% 4: W/S
        Plane.Specs.Aero.W_S.SLS = Plane.Specs.Weight.MTOW/Plane.Specs.Aero.S;
        %% 5: Total Engine Weight Fraction
        Plane.Specs.Weight.EngineFrac = Plane.Specs.Propulsion.Engine.DryWeight*...
            Plane.Specs.Propulsion.NumEngines/Plane.Specs.Weight.MTOW;
        %% 6: Fuel Fraction
        Plane.Specs.Weight.FuelFrac = Plane.Specs.Weight.Fuel/Plane.Specs.Weight.MTOW;
        %% 7-10: Keywords

        KeyWords = Plane.Overview.KeyWords;
        if isnan(KeyWords)
            Plane.Overview.ModelType = "Variant";
            Plane.Overview.PayloadType = "";
            Plane.Overview.PassengerType = "";
        else
            % 9: Baseline
            if contains(KeyWords,"baseline",'IgnoreCase',true)
                Plane.Overview.ModelType = "Baseline";
            else
                Plane.Overview.ModelType = "Variant";
            end

            % 10: Business/Commercial

            switch Plane.Overview.PayloadType
                case 'P'
                    Plane.Overview.PayloadType = "Passenger";
                    Plane.Overview.PassengerType = "Commercial";
                case 'C'
                    Plane.Overview.PayloadType = "Cargo";
                    Plane.Overview.PassengerType = "N/A";
                case 'M'
                    Plane.Overview.PayloadType = "Mixed Pax and Cargo";
                    Plane.Overview.PassengerType = "Commercial";
                otherwise
                    Plane.Overview.PayloadType = "Unspecified";
                    Plane.Overview.PassengerType = "Unspecified";
            end
            if contains(KeyWords,"business",'IgnoreCase',true)

                Plane.Overview.PayloadType = "Passenger";
                Plane.Overview.PassengerType = "Business";

            end
        end

        % Lose the KeyWords field after the derivative fields have been filled in
        Plane.Overview = rmfield(Plane.Overview,"KeyWords");

        %% 11: Monikers and Alternate designations

        if isnan(Plane.Overview.Monikers)
            Plane.Overview.Monikers = "N/A";
        end
        if isnan(Plane.Overview.AlternateDesignation)
            Plane.Overview.AlternateDesignation = "N/A";
        end
        %% 12: Aerodynamic Ratios

        Plane.Specs.Aero.TaperRatio = Plane.Specs.Aero.TipChord/Plane.Specs.Aero.RootChord;
        Plane.Specs.Aero.AR = Plane.Specs.Aero.Span^2/Plane.Specs.Aero.S;
        %% 13: Cruise L/D

        % Thrust to weight method
        W = Plane.Specs.Weight.MTOW*0.995*0.985*9.81;
        [Temp,~,~] = MissionSegsPkg.StdAtm(7500);

        if isnan(Plane.Specs.Performance.Vels.Crs)
            M = 0.4;
        else
            M = Plane.Specs.Performance.Vels.Crs;
        end
        T = Plane.Specs.Power.Crs/(M*sqrt(1.4*287*Temp));
        Plane.Specs.Aero.L_D.Crs = W/T;

        %% 14: Switch takeoff speed to m/s from kts

        Plane.Specs.Performance.Vels.Tko = UnitConversionPkg.ConvLength(Plane.Specs.Performance.Vels.Tko,'naut mi','m')/3600;
        %% 15: Cargo Weight and Payload Weight
        if isnan(Plane.Specs.Weight.Cargo)
            Plane.Specs.Weight.Cargo = 0;
        end

        if isnan(Plane.Specs.Weight.MaxPayload)
        Plane.Specs.Weight.Payload = Plane.Specs.Weight.Cargo + Plane.Specs.TLAR.MaxPax*95;
        else
            Plane.Specs.Weight.Payload = Plane.Specs.Weight.MaxPayload;
        end

        %% Aircraft design group

        b = UnitConversionPkg.ConvLength(Plane.Specs.Aero.Span,'m','ft');
        th = UnitConversionPkg.ConvLength(Plane.Specs.Aero.Height,'m','ft');


        ADG = NaN;


        if b < 262 && th < 80
            ADG = "VI";
            bpercent = b/262;
            thpercent = th/80;
        end

        if b < 214 && th < 66
            ADG = "V";
            bpercent = b/214;
            thpercent = th/66;
        end
        if b < 171 && th < 60
            ADG = "IV";
            bpercent = b/171;
            thpercent = th/60;
        end
        if b < 118 && th < 45
            ADG = "III";
            bpercent = b/118;
            thpercent = th/45;
        end
        if b < 79 && th < 30
            ADG = "II";
            bpercent = b/79;
            thpercent = th/30;
        end
        if b < 49 && th < 20
            ADG = "I";
            bpercent = b/49;
            thpercent = th/20;
        end

        if isnan(b) || isnan(th)
            bpercent = NaN;
            thpercent = NaN;
        end


        if bpercent > thpercent
            ADGPercent = bpercent;
            ADGLimitor = "Wingspan";
        elseif bpercent == thpercent
            ADGPercent = bpercent;
            ADGLimitor = "Both";
        elseif bpercent < thpercent
            ADGPercent = thpercent;
            ADGLimitor = "TailHeight";
        else
            ADGPercent = NaN;
            ADGLimitor = NaN;
        end

        Plane.Specs.TLAR.ADG = ADG;
        Plane.Specs.TLAR.ADGPercent = ADGPercent;
        Plane.Specs.TLAR.ADGLimitor = ADGLimitor;

        %% FAST Inputs
        % These allow aircraft in the database to be directly sized by the
        % FAST tool. They assign flags and values that are only used by
        % FAST and are not universally known aircraft identifiers. They
        % assume a conventional aircraft (no electrification/hydrogen/fuel
        % cells) and provide default setting values for the tool

        % Flags and default values for the sizing tool        
        Plane.Specs.TLAR.Class = "Turboprop";
        Plane.Specs.Propulsion.Arch.Type = "C";
        Plane.Specs.Propulsion.Eta.Prop = NaN;
        Plane.Specs.Performance.Alts.Tko = 0;
        Plane.Specs.Performance.RCMax = NaN;

        % Power specifications needed for the sizing tool. all database
        % aircraft are fully conventional with no power split, battery,
        % motor, or generator
        Plane.Specs.Weight.Batt = NaN;
        Plane.Specs.Weight.EM = NaN;
        Plane.Specs.Weight.EG = NaN;

        Plane.Specs.Power.SpecEnergy.Fuel = (43.2e+6) / (3.6e+6);
        Plane.Specs.Power.SpecEnergy.Batt = NaN;
        Plane.Specs.Power.Eta.EM = NaN;
        Plane.Specs.Power.Eta.EG = NaN;
        Plane.Specs.Power.Phi.SLS = 0.00;
        Plane.Specs.Power.Phi.Tko = 0.00;
        Plane.Specs.Power.Phi.Clb = 0.00;
        Plane.Specs.Power.Phi.Crs = 0.00;
        Plane.Specs.Power.Phi.Des = 0.00;
        Plane.Specs.Power.Phi.Lnd = 0.00;
        Plane.Specs.Propulsion.T_W.SLS = Plane.Specs.Power.P_W.SLS/Plane.Specs.Performance.Vels.Tko/9.81;
        Plane.Specs.Power.P_W.EM = NaN;
        Plane.Specs.Power.P_W.EG = NaN;

        Plane.Settings.TkoPoints = NaN;
        Plane.Settings.ClbPoints = NaN;
        Plane.Settings.CrsPoints = NaN;
        Plane.Settings.DesPoints = NaN;
        Plane.Settings.OEW.MaxIter = NaN;
        Plane.Settings.OEW.Tol = NaN;
        Plane.Settings.Analysis.MaxIter = NaN;
        Plane.Settings.Analysis.Type = +1;
        Plane.Settings.Plotting = 0;

    case "Units"

        Plane.Specs.Performance.Vels.Crs = "Mach";
        Plane.Specs.Weight.Airframe = "kg";
        Plane.Specs.Weight.OEW_MTOW = "ratio";
        Plane.Specs.Power.P_W.SLS = "kW/kg";
        Plane.Specs.Power.SLS = "W";
        Plane.Specs.Power.Cont = "W";
        Plane.Specs.Power.Clb = "W";
        Plane.Specs.Power.Crs = "W";
        Plane.Specs.Aero.W_S.SLS = "kg/m2";
        Plane.Specs.Weight.EngFrac = "ratio";
        Plane.Specs.Weight.FuelFrac = "ratio";
        Plane.Overview.ModelType = "type";
        Plane.Overview.PayloadType = "type";
        Plane.Overview.PassengerType = "type";
        Plane.Specs.Aero.TaperRatio = "ratio";
        Plane.Specs.Aero.L_D.Crs = "ratio";
        Plane.Specs.Aero.AR = "ratio";



        Plane.Specs.TLAR.Class = "flag";
        Plane.Specs.TLAR.ADG = "Category I through VI";
        Plane.Specs.TLAR.ADGPercent = "Percent";
        Plane.Specs.TLAR.ADGLimitor = "Type";

        Plane.Specs.Propulsion.Arch.Type = "flag";
        Plane.Specs.Propulsion.Eta.Prop = "efficiency";
        Plane.Specs.Performance.Alts.Tko = "m";
        Plane.Specs.Performance.RCMax = "m/s";

        Plane.Specs.Weight.Batt = "kg";
        Plane.Specs.Weight.EM = "kg";
        Plane.Specs.Weight.EG = "kg";

        Plane.Specs.Weight.Payload = "kg";

        Plane.Specs.Power.SpecEnergy.Batt = "kWh/kg";
        Plane.Specs.Power.SpecEnergy.Fuel = "kWh/kg";
        Plane.Specs.Power.Eta.EM = "efficiency";
        Plane.Specs.Power.Eta.EG = "efficiency";
        Plane.Specs.Power.Phi.SLS = "ratio";
        Plane.Specs.Power.Phi.Tko = "ratio";
        Plane.Specs.Power.Phi.Clb = "ratio";
        Plane.Specs.Power.Phi.Crs = "ratio";
        Plane.Specs.Power.Phi.Des = "ratio";
        Plane.Specs.Power.Phi.Lnd = "ratio";
        Plane.Specs.Propulsion.T_W.SLS = "ratio";
        Plane.Specs.Power.P_W.EM = "kW/kg";
        Plane.Specs.Power.P_W.EG = "kW/kg";
        
        % Default setting values for the sizing tool.
        Plane.Settings.TkoPoints = "count";
        Plane.Settings.ClbPoints = "count";
        Plane.Settings.CrsPoints = "count";
        Plane.Settings.DesPoints = "count";
        Plane.Settings.OEW.MaxIter = "count";
        Plane.Settings.OEW.Tol = "ratio";
        Plane.Settings.Analysis.MaxIter = "count";
        Plane.Settings.Analysis.Type = "flag";
        Plane.Settings.Plotting = "flag";


        Plane.Specs.Propulsion.Engine.DataTypeValidation = "data type";

        Plane.Overview = rmfield(Plane.Overview,"KeyWords");

    otherwise
        error('Enter either <Units> or <Vals> for the flag input.')
end

Plane.Specs.Weight = rmfield(Plane.Specs.Weight,"MaxPayload");

end
