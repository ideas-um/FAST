function [Plane] = CalcFanVals(Plane,unitsflag,AssumedM)
%
% [Plane] = CalcFanVals(Plane,units)
% Written by Maxfield Arnson
% Updated 10/19/2023
%
% This function takes an aircraft structure from the IDEAS database and
% processes it to add additional fields that can be calculated from the raw
% data. Depending on the units flag, it will either calculate the values
% mentioned or assign them their units.
%
% This function is for turbofan aircraft ONLY. To process turboprops there
% is a second function, called CalcPropVals() also located in the
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
% Cruise L/D
% OEW/MTOW
% MZFW/MTOW
% T/W
% Update Aircraft Thrust to reflect all engines in use
% Add cruise thrust
% W/S
% Engine Weight Fraction
% Fuel Fraction
% Flags:
%   Single vs Double Aisle
%   Short vs. medium vs. long range/haul
%   Baseline vs. variant
% Monikers
% Taper Ratio
% Aspect Ratio



switch unitsflag
    case "Vals"
        %% 1: L/D
        % Two methods of calculating L/D at cruise; BRE and weight/thrust

        % BRE method (for reference, not currently in use)
        c = Plane.Specs.Propulsion.Engine.TSFC_Crs*0.453592/4.44822/3600*9.81;
        R = Plane.Specs.Performance.Range*1e3;
        Wrat = log((Plane.Specs.Weight.MTOW)/(Plane.Specs.Weight.MTOW-Plane.Specs.Weight.Fuel));
        %Plane.Specs.Performance.Alts.Crs
        T = MissionSegsPkg.StdAtm(Plane.Specs.Performance.Alts.Crs);
        M = Plane.Specs.Performance.Vels.Crs;
        a = sqrt(1.4*287*T);
        V = M*a;
        Plane.Specs.Aero.L_D.CrsBRE = R*c/V/Wrat;

        % weight/thrust method
        W = Plane.Specs.Weight.MTOW*0.995*0.985*9.81;
        Th = Plane.Specs.Propulsion.Engine.Thrust_Crs*Plane.Specs.Propulsion.NumEngines;
        Plane.Specs.Aero.L_D.Crs = W/Th;
        %Plane.Specs.Aero.L_D.Crs = R*9.81/(4.3e7*0.4*log(1/(1-Plane.Specs.Weight.Fuel/Plane.Specs.Weight.MTOW)));
        Plane.Specs.Aero.L_D.Clb = NaN;
        Plane.Specs.Aero.L_D.Des = NaN;

        AR = Plane.Specs.Aero.Span^2/Plane.Specs.Aero.S;

        cmac = UnitConversionPkg.ConvLength(Plane.Specs.Aero.MAC,'m','ft');
        z = UnitConversionPkg.ConvLength(Plane.Specs.Performance.Alts.Crs,'m','ft');


        M = Plane.Specs.Performance.Vels.Crs;
        if isnan(M)
            M = AssumedM;
        end

        Re = 7.093e6*cmac*M*(1-0.5*(z/23500)^0.7);

        Plane.Specs.Aero.L_D.CrsMAC = 0.321*(AR^2*Re)^(3/16)*(1+3.6*AR^(-9/4))^(-0.5);

        if isnan(Plane.Specs.Aero.WingtipDevice)
            AReff = AR;
        elseif Plane.Specs.Aero.WingtipDevice == "none"
            AReff = AR;
        else
            AReff = 1.2*AR;
        end
        Plane.Specs.Aero.L_D.CrsMAC2 = 0.321*(AReff^2*Re)^(3/16)*(1+3.6*AReff^(-9/4))^(-0.5);

        %% 2: Airframe Weight, OEW/MTOW and MZFW/MTOW
        Plane.Specs.Weight.Airframe = Plane.Specs.Weight.OEW - Plane.Specs.Propulsion.Engine.DryWeight*...
            Plane.Specs.Propulsion.NumEngines;
        Plane.Specs.Weight.OEW_MTOW = Plane.Specs.Weight.OEW/Plane.Specs.Weight.MTOW;
        Plane.Specs.Weight.MZFW_MTOW = Plane.Specs.Weight.MZFW/Plane.Specs.Weight.MTOW;
        %% 3: T/W

        if isnan(Plane.Specs.Propulsion.Thrust.SLS)
            Plane.Specs.Propulsion.T_W.SLS = Plane.Specs.Propulsion.Engine.Thrust_Max*Plane.Specs.Propulsion.NumEngines...
                /Plane.Specs.Weight.MTOW/9.81;
        else
            Plane.Specs.Propulsion.T_W.SLS = Plane.Specs.Propulsion.Thrust.Max*Plane.Specs.Propulsion.NumEngines...
                /Plane.Specs.Weight.MTOW/9.81;
        end

        %% 3.1 Update thrusts
        if isnan(Plane.Specs.Propulsion.Thrust.SLS)
            Plane.Specs.Propulsion.Thrust.SLS = Plane.Specs.Propulsion.Engine.Thrust_SLS*Plane.Specs.Propulsion.NumEngines;
        else
            Plane.Specs.Propulsion.Thrust.SLS = Plane.Specs.Propulsion.Thrust.SLS*Plane.Specs.Propulsion.NumEngines;
        end

        if isnan(Plane.Specs.Propulsion.Thrust.Max)
            Plane.Specs.Propulsion.Thrust.Max = Plane.Specs.Propulsion.Engine.Thrust_Max*Plane.Specs.Propulsion.NumEngines;
        else
            Plane.Specs.Propulsion.Thrust.Max = Plane.Specs.Propulsion.Thrust.Max*Plane.Specs.Propulsion.NumEngines;
        end

        Plane.Specs.Propulsion.Thrust.Crs = Plane.Specs.Propulsion.Engine.Thrust_Crs*Plane.Specs.Propulsion.NumEngines;
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
            Plane.Overview.Aisle = "";
            Plane.Overview.RangeCapability = "";
            Plane.Overview.ModelType = "Variant";
            Plane.Overview.PassengerType = "";
        else

            % 7: Single/Double Aisle
            if contains(KeyWords,"single",'IgnoreCase',true)
                Plane.Overview.Aisle = "Single";
            elseif contains(KeyWords,"double",'IgnoreCase',true)
                Plane.Overview.Aisle = "Double";
            else
                Plane.Overview.Aisle = "";
            end

            % 8: Short/Med/Long Haul  (needs updating based on explicit
            % range definitions.
            if contains(KeyWords,"extended",'IgnoreCase',true)
                Plane.Overview.RangeCapability = "Extended Range";
            elseif contains(KeyWords,"long",'IgnoreCase',true)
                Plane.Overview.RangeCapability = "Long Range";
            elseif contains(KeyWords,"medium",'IgnoreCase',true)
                Plane.Overview.RangeCapability = "Medium Range";
            elseif contains(KeyWords,"short",'IgnoreCase',true)
                Plane.Overview.RangeCapability = "Short Range";
            else
                Plane.Overview.RangeCapability = "";
            end

            % 9: Baseline
            if contains(KeyWords,"baseline",'IgnoreCase',true)
                Plane.Overview.ModelType = "Baseline";
            else
                Plane.Overview.ModelType = "Variant";
            end


            if contains(KeyWords,"business",'IgnoreCase',true)

                Plane.Overview.PayloadType = "Passenger";
                Plane.Overview.PassengerType = "Business";

            end
        end

        % 10: Business/Commercial

        switch Plane.Overview.PayloadType
            case 'P'
                Plane.Overview.PayloadType = "Passenger";
                Plane.Overview.PassengerType = "Commercial";
            case 'C'
                Plane.Overview.PayloadType = "Cargo";
                Plane.Overview.PassengerType = "N/A";
                Plane.Overview.Aisle = NaN;
            case 'M'
                Plane.Overview.PayloadType = "Mixed Pax and Cargo";
                Plane.Overview.PassengerType = "Commercial";
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
        Plane.Specs.Aero.AR = AR;

        %% 13: Switch takeoff speed to m/s from kts

        Plane.Specs.Performance.Vels.Tko = UnitConversionPkg.ConvLength(Plane.Specs.Performance.Vels.Tko,'naut mi','m')/3600;
        %% 14: Cargo Weight and Payload Weight
        if isnan(Plane.Specs.Weight.Cargo)
            Plane.Specs.Weight.Cargo = 0;
        end
        Plane.Specs.Weight.Payload = Plane.Specs.Weight.Cargo + Plane.Specs.TLAR.MaxPax*95;

        %% Change Range from km to meters
        Plane.Specs.Performance.Range = 1e3*Plane.Specs.Performance.Range;
        %% FAST Inputs
        % These allow aircraft in the database to be directly sized by the
        % FAST tool. They assign flags and values that are only used by
        % FAST and are not universally known aircraft identifiers. They
        % assume a conventional aircraft (no electrification/hydrogen/fuel
        % cells) and provide default setting values for the tool

        % Flags and default values for the sizing tool
        Plane.Specs.TLAR.Class = "Turbofan";
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
        Plane.Specs.Power.P_W.SLS = Plane.Specs.Propulsion.T_W.SLS*Plane.Specs.Performance.Vels.Tko;
        Plane.Specs.Power.P_W.EM = NaN;
        Plane.Specs.Power.P_W.EG = NaN;

        % Default setting values for the sizing tool.
        Plane.Settings.TkoPoints = NaN;
        Plane.Settings.ClbPoints = NaN;
        Plane.Settings.CrsPoints = NaN;
        Plane.Settings.DesPoints = NaN;
        Plane.Settings.OEW.MaxIter = NaN;
        Plane.Settings.OEW.Tol = NaN;
        Plane.Settings.Analysis.MaxIter = NaN;
        Plane.Settings.Analysis.Type = +1;
        Plane.Settings.Plotting = 0;

        DTindex = randi(100,1,1);

        if DTindex > 95
            Plane.Settings.DataTypeValidation = "Validation";
        else
            Plane.Settings.DataTypeValidation = "Training";
        end


    case "Units"
        Plane.Specs.Performance.Range = "m";
        Plane.Specs.Aero.L_D.CrsBRE = "ratio";
        Plane.Specs.Aero.L_D.Crs = "ratio";
        Plane.Specs.Aero.L_D.Clb = "ratio";
        Plane.Specs.Aero.L_D.Des = "ratio";
        Plane.Specs.Aero.L_D.CrsMAC = "ratio";
        Plane.Specs.Aero.L_D.CrsMAC2 = "ratio";
        Plane.Specs.Weight.Airframe = "kg";
        Plane.Specs.Weight.OEW_MTOW = "ratio";
        Plane.Specs.Weight.MZFW_MTOW = "ratio";
        Plane.Specs.Propulsion.T_W.SLS = "ratio";
        Plane.Specs.Propulsion.Thrust.Crs = "N";
        Plane.Specs.Aero.W_S.SLS = "kg/m2";
        Plane.Specs.Weight.EngFrac = "ratio";
        Plane.Specs.Weight.FuelFrac = "ratio";
        Plane.Overview.Aisle = "type";
        Plane.Overview.RangeCapability = "type";
        Plane.Overview.ModelType = "type";
        Plane.Overview.PayloadType = "type";
        Plane.Overview.PassengerType = "type";
        Plane.Specs.Aero.TaperRatio = "ratio";
        Plane.Specs.Aero.AR = "ratio";
        Plane.Specs.Performance.Vels.Tko = "m/s";
        Plane.Specs.Power.SpecEnergy.Fuel = "kWh/kg";


        Plane.Specs.TLAR.Class = "flag";
        Plane.Specs.Propulsion.Arch.Type = "flag";
        Plane.Specs.Propulsion.Eta.Prop = "efficiency";
        Plane.Specs.Performance.Alts.Tko = "m";
        Plane.Specs.Performance.RCMax = "m/s";

        Plane.Specs.Weight.Batt = "kg";
        Plane.Specs.Weight.EM = "kg";
        Plane.Specs.Weight.EG = "kg";

        Plane.Specs.Weight.Payload = "kg";

        Plane.Specs.Power.SpecEnergy.Batt = "kWh/kg";
        Plane.Specs.Power.Eta.EM = "efficiency";
        Plane.Specs.Power.Eta.EG = "efficiency";
        Plane.Specs.Power.Phi.SLS = "ratio";
        Plane.Specs.Power.Phi.Tko = "ratio";
        Plane.Specs.Power.Phi.Clb = "ratio";
        Plane.Specs.Power.Phi.Crs = "ratio";
        Plane.Specs.Power.Phi.Des = "ratio";
        Plane.Specs.Power.Phi.Lnd = "ratio";
        Plane.Specs.Power.P_W.AC = "W/kg";
        Plane.Specs.Power.P_W.EM = "kW/kg";
        Plane.Specs.Power.P_W.EG = "kW/kg";

        Plane.Settings.TkoPoints = "count";
        Plane.Settings.ClbPoints = "count";
        Plane.Settings.CrsPoints = "count";
        Plane.Settings.DesPoints = "count";
        Plane.Settings.OEW.MaxIter = "count";
        Plane.Settings.OEW.Tol = "ratio";
        Plane.Settings.Analysis.MaxIter = "count";
        Plane.Settings.Analysis.Type = "flag";
        Plane.Settings.Plotting = "flag";
        
        Plane.Settings.DataTypeValidation = "data type";
        Plane.Specs.Propulsion.Engine.DataTypeValidation = "data type";

        Plane.Overview = rmfield(Plane.Overview,"KeyWords");

    otherwise
        error('Enter either "Units" or "Vals" for the unitsflag input.')
end

end
