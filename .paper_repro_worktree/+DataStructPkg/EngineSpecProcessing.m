function [Aircraft] = EngineSpecProcessing(Aircraft)
%
% [Aircraft] = EngineSpecProcessing(Aircraft)
% written by Maxfield Arnson, marnson@umich.edu
% last updated 24 apr 2024
%
% This function only creates and engine in the case that a
% user did not provide an engine specification file. If so, this
% function will modify the aircraft structure by adding a engine designed
% using default values and regressions. If a specification file was
% provided, it will not execute any code and will return the aircraft
% structure unmodified
%
% INPUTS:
%     Aircraft - aircraft data structure without a valid
%                Aircraft.Specs.Propulsion.Engine field
%                size/type/units: 1-by-1 / struct / []
%
% OUTPUTS:
%     Aircraft - aircraft data structure with a valid engine field
%                size/type/units: 1-by-1 / struct / []
%


% Read in data for use in the regressions. This data will have been
% assigned in SpecProcessing()
Data = Aircraft.HistData.Eng;

if ~isstruct(Aircraft.Specs.Propulsion.Engine)
    switch Aircraft.Specs.TLAR.Class
        case "Turbofan"
            %% Default Values
            % Flight Conditions
            Engine.Mach = 0.05;
            Engine.Alt = 0;
            Engine.DesignThrust = Aircraft.Specs.Propulsion.Thrust.SLS/Aircraft.Specs.Propulsion.NumEngines;

            % Other default specs
            Engine.Tt4Max = 1800;
            Engine.NoSpools = 2;
            Engine.FanGearRatio = NaN;
            Engine.FanBoosters = false;
            Engine.MaxIter = 300;

            % Core Flows
            Engine.CoreFlow.PaxBleed = 0.03;
            Engine.CoreFlow.Leakage = 0.01;
            Engine.CoreFlow.Cooling = 0.2;

            % Efficiencies
            Engine.EtaPoly.Inlet = 0.99;
            Engine.EtaPoly.Diffusers = 0.99;
            Engine.EtaPoly.Fan = 0.95;
            Engine.EtaPoly.Compressors = 0.95;
            Engine.EtaPoly.BypassNozzle = 0.99;
            Engine.EtaPoly.Combustor = 0.995;
            Engine.EtaPoly.Turbines = 0.95;
            Engine.EtaPoly.CoreNozzle = 0.99;
            Engine.EtaPoly.Nozzles = 0.99;
            Engine.EtaPoly.Mixing = 0;

            %% Regressions
            % Perform regressions on OPR, FPR, BPR, and RPM
            [TwoSpoolData,~] = RegressionPkg.SearchDB(Data,"LPCStages",0);
            [LPRPM,~] = RegressionPkg.NLGPR(TwoSpoolData,{["Thrust_SLS"],["LP100"]},Engine.DesignThrust);
            [HPRPM,~] = RegressionPkg.NLGPR(TwoSpoolData,{["Thrust_SLS"],["HP100"]},Engine.DesignThrust);
            Engine.RPMs = [LPRPM, HPRPM];

            [Engine.OPR,~] = RegressionPkg.NLGPR(Data,{["Thrust_SLS"],["OPR_SLS"]},Engine.DesignThrust);
            [Engine.BPR,~] = RegressionPkg.NLGPR(Data,{["Thrust_SLS"],["BPR"]},Engine.DesignThrust);
            [Engine.FPR,~] = RegressionPkg.NLGPR(Data,{["Thrust_SLS"],["FPR"]},Engine.DesignThrust);
        case "Turboprop"

            %% Default Values

            % Flight Conditions
            Engine.Mach = 0.05;
            Engine.Alt = 0;
            Engine.ReqPower = Aircraft.Specs.Power.SLS/Aircraft.Specs.Propulsion.NumEngines;

            % Other specifications
            Engine.Tt4Max = 1200;% kelvin
            Engine.NPR = 1.3;
            Engine.NoSpools = 2;


            % Efficiencies
            Engine.EtaPoly.Inlet = 0.99;
            Engine.EtaPoly.Diffusers = 0.99;
            Engine.EtaPoly.Compressors = 0.9;
            Engine.EtaPoly.Combustor = 0.995;
            Engine.EtaPoly.Turbines = 0.9;
            Engine.EtaPoly.Nozzles = 0.985;

            %% Regressions

            % Perform regressions on OPR and RPM
            [Engine.OPR,~] = RegressionPkg.NLGPR(Data,{["Power_SLS"],["OPR_SLS"]},Engine.ReqPower);
            [IPRPM,~] = RegressionPkg.NLGPR(Data,{["Power_SLS"],["IPMaxTO"]},Engine.ReqPower);
            [HPRPM,~] = RegressionPkg.NLGPR(Data,{["Power_SLS"],["HPMaxTO"]},Engine.ReqPower);
            Engine.RPMs = [HPRPM,IPRPM];

    end

    % Assign Output
    Aircraft.Specs.Propulsion.Engine = Engine;
end


end