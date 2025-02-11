function [Aircraft] = OEWIteration(Aircraft)
%
% [Aircraft] = OEWIteration(Aircraft)
% written by Maxfield Arnson
% modified by Paul Mokotoff, prmoko@umich.edu
% last updated: 16 jan 2025
%
% This function takes the aircraft specification structure and performs
% regressions (using the regression package) based on the data in the
% IDEAS_DB.mat file to predict the OEW of an aircraft during the sizing
% process. The function uses the calculated OEW to update the MTOW and uses
% the MTOW to size the wing area based on the user input wing loading.
%
% INPUTS:
%     Aircraft - structure defining the aircraft specifications.
%                size/type/units: 1-by-1 / struct / []
%
%
% OUTPUTS:
%     Aircraft - structure defining the aircraft specifications. This
%                structure has been modified by the original version to
%                have an updated OEW, MTOW, component weights, sea-level
%                static thrust or power, and wing area.
%                size/type/units: 1-by-1 / struct / []
%


%% PRE-PROCESSING %%
%%%%%%%%%%%%%%%%%%%%

% acceleration due to gravity
g = 9.81; % m / s^2

% get the TLARs
Class = Aircraft.Specs.TLAR.Class;
EIS   = Aircraft.Specs.TLAR.EIS;

% get the wing loading
W_S = Aircraft.Specs.Aero.W_S.SLS;

% get the aircraft weights
Wfuel = Aircraft.Specs.Weight.Fuel   ;
Wbatt = Aircraft.Specs.Weight.Batt   ;

if isempty(Wbatt)
    Wbatt = 0;
end
Weg   = Aircraft.Specs.Weight.EG     ;
Wem   = Aircraft.Specs.Weight.EM     ;
Wpax  = Aircraft.Specs.Weight.Payload;
Wcrew = Aircraft.Specs.Weight.Crew   ;
Weng  = Aircraft.Specs.Weight.Engines;
Weap = Aircraft.Specs.Weight.EAP     ;

% check for a calibration factor on OEW/airframe weight
if (isfield(Aircraft.Specs.Weight, "WairfCF"))
    
    % update the airframe weight
    FrameCF = Aircraft.Specs.Weight.WairfCF;
    
else
    
    % assume no calibration factor
    FrameCF = 1;
        
end


%% OEW ITERATION %%
%%%%%%%%%%%%%%%%%%%

% compute the airframe weight (remove propulsion system from OEW)
WframeNew = Aircraft.Specs.Weight.OEW - Weng - Wem - Weg;

% If there is a bad initial guess such that OEW is negative, the code will
% converge on a negative solution. This line prevents that and nugdes the
% code towards a positive solution
if WframeNew < 0
    WframeNew = 0.4*Aircraft.Specs.Weight.MTOW;
end

% iteration settings
Tol     = Aircraft.Settings.OEW.Tol    ;
MaxIter = Aircraft.Settings.OEW.MaxIter;

% initialize the iteration
iter = 0;
err  = 1;

% perform OEW regression based on T/W for turbofans and P/W for
% turboprops. accept wing area, EIS, and MTOW as additional inputs
% for both regressions.

% check the aircraft class
switch Class

    % turbofan aircraft
    case "Turbofan"
        
        % get the turbofan aircraft
        TurbofanAC = Aircraft.HistData.AC;
        
        % get the thrust-weight ratio
        T_W = Aircraft.Specs.Propulsion.T_W.SLS;
        
        % iterate on airframe weight until convergence
        while ((err > Tol) && (iter < MaxIter))
            
            % get the airframe weight
            WframeOld = WframeNew;
            
            % compute MTOW
            MTOW = WframeOld + Wfuel + Wbatt + Wpax + Wcrew + Wem + Weg + Weng + Weap;
            
            % get the necessary thrust and wing area
            T = MTOW * T_W * g;
            S = MTOW / W_S    ;
            
            % remember the SLS thrust
            Aircraft.Specs.Propulsion.Thrust.SLS = T;
                        
            % size the propulsion system
            Aircraft = PropulsionPkg.PropulsionSizing(Aircraft);
            
            % get the new engine weights
            WengNew = Aircraft.Specs.Weight.Engines;
            
            % get the new electric motor weights
            WemNew = Aircraft.Specs.Weight.EM;
            
            % get the new electric generator weights
            WegNew = Aircraft.Specs.Weight.EG;
                        
            % modify MTOW
            MTOW = MTOW + WengNew - Weng + WemNew - Wem + WegNew - Weg;
                        
            % list the targets for the airframe weight estimation
            target = [S, T, EIS, MTOW];
            
            % list parts of the aircraft structure to use in the regression
            IO = {["Specs", "Aero"      , "S"            ], ...
                  ["Specs", "Propulsion", "Thrust", "SLS"], ...
                  ["Specs", "TLAR"      , "EIS"          ], ...
                  ["Specs", "Weight"    , "MTOW"         ], ...
                  ["Specs", "Weight"    , "Airframe"     ]}   ;
              
             % estimate the new airframe weight with a regression
            WframeNew = RegressionPkg.NLGPR(TurbofanAC, IO, target, 'Iteration', true, 'Preprocessing',Aircraft.RegressionParams.OEW);

            % update the airframe weight with a calibration factor
            WframeNew = WframeNew * FrameCF;
            
            % check the convergence
            err = abs(WframeOld - WframeNew) / WframeOld;
            
            % iterate
            iter = iter +1;
            
            % remember the power source weights
            Weng = WengNew;
            Wem  =  WemNew;
            Weg  =  WegNew;
            
        end
      
    % turboprop aircraft
    case "Turboprop"
        
        % get the turboprop aircraft
        TurbopropAC = Aircraft.HistData.AC;
        
        % get the power-weight ratio
        P_W = Aircraft.Specs.Power.P_W.SLS;

        % Create Linear Airframe and MTOW fit
        [~,af] = RegressionPkg.SearchDB(TurbopropAC,["Specs","Weight","Airframe"]);
        af = cell2mat(af(:,2));
        [~,mtow] = RegressionPkg.SearchDB(TurbopropAC,["Specs","Weight","MTOW"]);
        mtow = cell2mat(mtow(:,2));
        cind = [];
        for ii = 1:length(mtow)
            if isnan(mtow(ii)) || isnan(af(ii))
                cind = [cind,ii]; %#ok<AGROW> 
            end
        end
        af(cind) = [];
        mtow(cind) = [];

        % function to estimate airframe weight as a function of MTOW
        Airframe_f_of_MTOW = polyfit(mtow,af,1);

        % run iteration
        while ((err > Tol) && (iter < MaxIter))
            
            % get the airframe weight
            WframeOld = WframeNew;
            
            % compute MTOW
            MTOW = WframeOld + Wfuel + Wbatt + Wpax + Wcrew + Wem + Weg + Weng + Weap;
            
            % get the necessary power and wing area
            P = MTOW * P_W;
            S = MTOW / W_S;

            % remember the SLS power
            Aircraft.Specs.Power.SLS = P;
            
            % size the propulsion system
            Aircraft = PropulsionPkg.PropulsionSizing(Aircraft);
            
            % get the new engine weights
            WengNew = Aircraft.Specs.Weight.Engines;
            
            % get the new electric motor weights
            WemNew = Aircraft.Specs.Weight.EM;
            
            % get the new electric generator weights
            WegNew = Aircraft.Specs.Weight.EG;
            
            % modify MTOW
            MTOW = MTOW + WengNew - Weng + WemNew - Wem + WegNew - Weg;
            
            % compute the new airframe weight
            WframeNew = polyval(Airframe_f_of_MTOW, MTOW);
            
            % update the airframe weight with a calibration factor
            WframeNew = WframeNew * FrameCF;
            
            % check for convergence
            err = abs(WframeOld - WframeNew) / WframeOld;
            
            % iterate 
            iter = iter +1;
            
            % remember the new power source weights
            Weng = WengNew;
            Wem  =  WemNew;
            Weg  =  WegNew;
            
        end
        
    otherwise
        
        % throw an error
        error('ERROR - OEWIteration: aircraft class not supported.');
        
end

% throw a warning if iteration limit was reached
if (iter >= MaxIter)
    warning('OEW failed to converge after %d iterations.', MaxIter)
end


%% POST-PROCESSING %%
%%%%%%%%%%%%%%%%%%%%%

% compute the OEW
OEW = WframeNew + WemNew + WegNew + WengNew + Weap;

% remember the new weights
Aircraft.Specs.Weight.Engines  = WengNew  ;
Aircraft.Specs.Weight.EM       = WemNew   ;
Aircraft.Specs.Weight.EG       = WegNew   ;
Aircraft.Specs.Weight.Airframe = WframeNew;
Aircraft.Specs.Weight.OEW      = OEW      ;
Aircraft.Specs.Weight.MTOW     = MTOW     ;

% remember the new wing area
Aircraft.Specs.Aero.S = S;

% ----------------------------------------------------------

end