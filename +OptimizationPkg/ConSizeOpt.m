function [g, h, dgdx, dhdx] = ConSizeOpt(x, NeedGrad, Aircraft)
%
% [g, h, dgdx, dhdx] = ConSizeOpt(x, NeedGrad, Aircraft)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 27 mar 2024
%
% Constraints while sizing the HEA and optimizing the design power split.
% For the inputs/outputs below, nx, ng, and nh are the number of design
% variables, inequality constraints, and equality constraints,
% respectively.
%
% INPUTS:
%     x        - design variable vector.
%                size/type/units: nx-by-1 / double / []
%
%     NeedGrad - flag to compute gradients (1) or not (0).
%                size/type/units: 1-by-1 / int / []
%
%     Aircraft - aircraft structure with information about the design and
%                optimization.
%                size/type/units: 1-by-1 / struct / []
%
% OUTPUTS:
%     g        - inequality constraint values.
%                size/type/units: ng-by-1 / double / []
%
%     h        -   equality constraint values.
%                size/type/units: nh-by-1 / double / []
%
%     dgdx     - gradient of inequality constraints.
%                size/type/units: ng-by-nx / double / []
%
%     dhdx     - gradient of   equality constraints.
%                size/type/units: nh-by-nx / double / []
%


%% CHECK FOR SPLITS BEING OPTIMIZED %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% get the optimization sub-structure
Opt = Aircraft.PowerOpt;

% check thrust operation splits
OptDesnTS   = OptimizationPkg.CheckFlag(Opt.Settings, "DesnTS"  );
OptOperTS   = OptimizationPkg.CheckFlag(Opt.Settings, "OperTS"  );

% check thrust-power splits
OptDesnTSPS = OptimizationPkg.CheckFlag(Opt.Settings, "DesnTSPS");
OptOperTSPS = OptimizationPkg.CheckFlag(Opt.Settings, "OperTSPS");

% check power-power splits
OptDesnPSPS = OptimizationPkg.CheckFlag(Opt.Settings, "DesnPSPS");
OptOperPSPS = OptimizationPkg.CheckFlag(Opt.Settings, "OperPSPS");

% check power-energy
OptDesnPSES = OptimizationPkg.CheckFlag(Opt.Settings, "DesnPSES");
OptOperPSES = OptimizationPkg.CheckFlag(Opt.Settings, "OperPSES");

% get the perturbation
EPS = 1.0e-06;


%% CONSTRAINT ON ELECTRIC MOTOR POWER %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% check that the electric    %
% motor power available is   %
% not exceeded               %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% check for an electric motor
if (any(Aircraft.Specs.Propulsion.PropArch.PSType == 0))
    
    % get the electric motor power used during the mision
    Pem = Aircraft.PowerOpt.Constraints.DesPem;
    
    % get the available electric motor power
    PemAv = Aircraft.PowerOpt.Constraints.DesPemAv;
    
    % use at least 0 power, but use no more than PemAv
    g01a = -Pem ./ PemAv    ; % scaled by 1 / PemAv for conditioning
    g01b =  Pem ./ PemAv - 1;
    
    % set any NaN or Inf to real numbers
    g01a(isnan(g01a)) = 0  ;
    g01b(isnan(g01b)) = 0  ;
    g01a(isinf(g01a)) = EPS;
    g01b(isinf(g01b)) = EPS;
    
else
    
    % no constraints are needed
    g01a = [];
    g01b = [];
    
end


%% CONSTRAINT ON GAS-TURBINE ENGINE POWER %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% check that the gas-turbine %
% engine power available is  %
% not exceeded               %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% check for a gas-turbine engine
if (any(Aircraft.Specs.Propulsion.PropArch.PSType == 1))
    
    % get the gas-turbine power used during the mission
    Pgt = Aircraft.PowerOpt.Constraints.DesPgt;
    
    % get the available gas-turbine power
    PgtAv = Aircraft.PowerOpt.Constraints.DesPgtAv;
    
    % use at least 0 power, but use no more than PgtAv
    g02a = -Pgt ./ PgtAv    ; % (scaled by 1/PgtAv for conditioning)
    g02b =  Pgt ./ PgtAv - 1;
    
    % set any NaN or Inf to real numbers
    g02a(isnan(g02a)) = 0  ;
    g02b(isnan(g02b)) = 0  ;
    g02a(isinf(g02a)) = EPS;
    g02b(isinf(g02b)) = EPS;
    
else
    
    % no constraints needed
    g02a = [];
    g02b = [];
    
end


%% CONSTRAINT ON BATTERY ENERGY EXPENDED %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% check that the battery     %
% energy expended is not     %
% exceeded                   %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% check for a battery
if (any(Aircraft.Specs.Propulsion.PropArch.ESType == 0))
    
    % get the battery energy expended during the mission
    Ebatt = Aircraft.PowerOpt.Constraints.DesEbatt;
    
    % get the battery energy available
    EbattAv = Aircraft.PowerOpt.Constraints.DesEbattAv;
    
    % use at least 0 battery, but use no more than EbattAv
    g03a = -Ebatt / EbattAv    ; % scaled for conditioning
    g03b =  Ebatt / EbattAv - 1;
    
    % set any NaN or Inf to real numbers
    g03a(isnan(g03a)) = 0  ;
    g03b(isnan(g03b)) = 0  ;
    g03a(isinf(g03a)) = EPS;
    g03b(isinf(g03b)) = EPS;
    
else
    
    % no constraints needed
    g03a = [];
    g03b = [];
    
end

%% CONSTRAINT ON ALL DESIGN SPLITS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% all design splits must be  %
% between 0 and 1            %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ((OptDesnTS   == 1) || (OptDesnTSPS == 1) || ...
    (OptDesnPSPS == 1) || (OptDesnPSES == 1)  )
    
    % use the number of operational splits for an index
    nopers = Aircraft.PowerOpt.nopers;

    % design splits must be between 0 and 1
    g04a = -x(nopers + 1 : end)    ;
    g04b =  x(nopers + 1 : end) - 1;
    
else
    
    % no constraints needed
    g04a = [];
    g04b = [];

end

%% CONSTRAINT ON ALL OPERATIONAL SPLITS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% bound the operational      %
% splits (all must be        %
% greater than or equal to 0 %
% and less than or equal to  %
% the design split)          %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% check for operational splits
if ((OptOperTS   == 1) || (OptOperTSPS == 1) || ...
    (OptOperPSPS == 1) || (OptOperPSES == 1) )

    % use the number of operational power splits and control points
    nopers = Aircraft.PowerOpt.nopers;
    npoint = Aircraft.PowerOpt.npoint;
    
    % power splits must be greater than 0
    g05a = -x(1:nopers);
    
    % count the splits
    tsplit = 1;
    
    % get the number of TS   splits
    nsplit = Aircraft.Settings.nargTS  ;
    
    % check for TS   design splits
    if (OptOperTS   == 1)
        if (OptDesnTS   == 1)
                
            % memory for the constraints
            g05b = zeros(npoint * nsplit, 1);
            
            % loop through the splits and constraint
            for isplit = 1:nsplit
                
                % compute the constraint
                g05b((tsplit - 1) * npoint + 1: tsplit * npoint) = ...
                   x((tsplit - 1) * npoint + 1: tsplit * npoint) ./ x(nopers + tsplit) - 1;
                
                % account for the split
                tsplit = tsplit + 1;
                
            end
            
        else
            
            % use the prescribed design split
            LamMax = Aircraft.Specs.Power.LamTS.SLS;
            
            % compute the constraint
            g05b = x((tsplit - 1) * npoint + 1 : (tsplit + nsplit - 1) * npoint) ./ LamMax - 1;
            
            % account for the splits
            tsplit = tsplit + nsplit;
            
        end
        
    else
        
        % no constraints needed
        g05b = [];
        
    end
    
    % get the number of TSPS splits
    nsplit = Aircraft.Settings.nargTSPS;
    
    % check for TS   design splits
    if (OptOperTSPS == 1)
        if (OptDesnTSPS == 1)
                
            % memory for the constraints
            g05c = zeros(npoint * nsplit, 1);
            
            % loop through the splits and constraint
            for isplit = 1:nsplit
                
                % compute the constraint
                g05c((tsplit - 1) * npoint + 1: tsplit * npoint) = ...
                   x((tsplit - 1) * npoint + 1: tsplit * npoint) ./ x(nopers + tsplit) - 1;
                
                % account for the split
                tsplit = tsplit + 1;
                
            end
            
        else
            
            % use the prescribed design split
            LamMax = Aircraft.Specs.Power.LamTSPS.SLS;
            
            % compute the constraint
            g05c = x((tsplit - 1) * npoint + 1 : (tsplit + nsplit - 1) * npoint) ./ LamMax - 1;
            
            % account for the splits
            tsplit = tsplit + nsplit;
            
        end
        
    else
        
        % no constraints needed
        g05c = [];
        
    end
    
    % get the number of PSPS splits
    nsplit = Aircraft.Settings.nargPSPS;
    
    % check for PSPS design splits
    if (OptOperPSPS == 1)
        if (OptDesnPSPS == 1)
                
            % memory for the constraints
            g05d = zeros(npoint * nsplit, 1);
            
            % loop through the splits and constraint
            for isplit = 1:nsplit
                
                % compute the constraint
                g05d((tsplit - 1) * npoint + 1: tsplit * npoint) = ...
                   x((tsplit - 1) * npoint + 1: tsplit * npoint) ./ x(nopers + tsplit) - 1;
                
                % account for the split
                tsplit = tsplit + 1;
                
            end
            
        else
            
            % use the prescribed design split
            LamMax = Aircraft.Specs.Power.LamPSPS.SLS;
            
            % compute the constraint
            g05d = x((tsplit - 1) * npoint + 1 : (tsplit + nsplit - 1) * npoint) ./ LamMax - 1;
            
            % account for the splits
            tsplit = tsplit + nsplit;
            
        end
        
    else
        
        % no constraints needed
        g05d = [];
        
    end
    
    % get the number of PSES splits
    nsplit = Aircraft.Settings.nargPSES;
    
    % check for PSES design splits
    if (OptOperPSES == 1)
        if (OptDesnPSES == 1)
                
            % memory for the constraints
            g05e = zeros(npoint * nsplit, 1);
            
            % loop through the splits and constraint
            for isplit = 1:nsplit
                
                % compute the constraint
                g05e((tsplit - 1) * npoint + 1: tsplit * npoint) = ...
                   x((tsplit - 1) * npoint + 1: tsplit * npoint) ./ x(nopers + tsplit) - 1;
                
                % account for the split
                tsplit = tsplit + 1;
                
            end
            
        else
            
            % use the prescribed design split
            LamMax = Aircraft.Specs.Power.LamPSES.SLS;
            
            % compute the constraint
            g05e = x((tsplit - 1) * npoint + 1 : (tsplit + nsplit - 1) * npoint) ./ LamMax - 1;
            
        end
        
    else
        
        % no constraints needed
        g05e = [];
        
    end
    
    % set any NaN or Inf to real numbers
    g05a(isnan(g05a)) = 0  ;
    g05b(isnan(g05b)) = 0  ;
    g05c(isnan(g05c)) = 0  ;
    g05d(isnan(g05d)) = 0  ;
    g05e(isnan(g05e)) = 0  ;
    g05a(isinf(g05a)) = EPS;
    g05b(isinf(g05b)) = EPS;
    g05c(isinf(g05c)) = EPS;
    g05d(isinf(g05d)) = EPS;
    g05e(isinf(g05e)) = EPS;
    
else
    
    % no constraints are needed
    g05a = [];
    g05b = [];
    g05c = [];
    g05d = [];
    g05e = [];
    
end


%% CONSTRAINT ON SIZED GAS-TURBINE ENGINE %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% check that the available   %
% engine power at cruise is  %
% enough to sustain flight   %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% check if the on-design mission is being performed
if (Aircraft.Settings.Analysis.Type == 1)

    % get the SLS power from the engine, and the required power at cruise
    PowEng = Aircraft.PowerOpt.Constraints.DesPavGT ;
    PowCrs = Aircraft.PowerOpt.Constraints.DesCrsPow;
    
    % constraint: must have enough power to cruise
    g06 = PowCrs / PowEng - 1;
    
else
    
    % no constraint needed
    g06 = [];
    
end
        

%% ASSEMBLE CONSTRAINTS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

% setup the inequality constraints
g = [g01a; g01b; g02a; g02b; g03a; g03b; g04a; ...
     g04b; g05a; g05b; g05c; g05d; g05e; g06 ] ;

% setup the   equality constraints (none of them)
h = [];


%% COMPUTE THE GRADIENTS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

% check if gradients are needed
if (NeedGrad == 1)
        
    % check for an electric motor
    if (any(Aircraft.Specs.Propulsion.PropArch.PSType == 0))
        
        % get the parameters for the electric motor power constraint
        Pem   = Aircraft.PowerOpt.Constraints.SenPem  ;
        PemAv = Aircraft.PowerOpt.Constraints.SenPemAv;
        
        % compute the change in constraints
        Delg01a = -Pem ./ PemAv    ;
        Delg01b =  Pem ./ PemAv - 1;
        
        % set any NaN or Inf to real numbers
        Delg01a(isnan(Delg01a)) = 0  ;
        Delg01b(isnan(Delg01b)) = 0  ;
        Delg01a(isinf(Delg01a)) = EPS;
        Delg01b(isinf(Delg01b)) = EPS;
        
        % compute the gradients
        dg01adx = (Delg01a - g01a) ./ EPS;
        dg01bdx = (Delg01b - g01b) ./ EPS;
        
    else
        
        % no gradients needed
        dg01adx = [];
        dg01bdx = [];
        
    end
    
    % check for a gas-turbine engine
    if (any(Aircraft.Specs.Propulsion.PropArch.PSType == 1))
        
        % get the parameters for the gas-turbine power constraint
        Pgt   = Aircraft.PowerOpt.Constraints.SenPgt  ;
        PgtAv = Aircraft.PowerOpt.Constraints.SenPgtAv;
        
        % compute the change in constraints
        Delg02a = -Pgt ./ PgtAv    ;
        Delg02b =  Pgt ./ PgtAv - 1;
        
        % set any NaN or Inf to real numbers
        Delg02a(isnan(Delg02a)) = 0  ;
        Delg02b(isnan(Delg02b)) = 0  ;
        Delg02a(isinf(Delg02a)) = EPS;
        Delg02b(isinf(Delg02b)) = EPS;
        
        % compute the gradients
        dg02adx = (Delg02a - g02a) ./ EPS;
        dg02bdx = (Delg02b - g02b) ./ EPS;
        
    else
        
        % no gradients needed
        dg02adx = [];
        dg02bdx = [];
        
    end
    
    % check for a battery
    if (any(Aircraft.Specs.Propulsion.PropArch.ESType == 0))
        
        % get the parameters for the battery energy constraint
        Ebatt   = Aircraft.PowerOpt.Constraints.SenEbatt  ;
        EbattAv = Aircraft.PowerOpt.Constraints.SenEbattAv;
        
        % compute the change in constraint
        Delg03a = -Ebatt ./ EbattAv    ;
        Delg03b =  Ebatt ./ EbattAv - 1;
        
        % set any NaN or Inf to real numbers
        Delg03a(isnan(Delg03a)) = 0  ;
        Delg03b(isnan(Delg03b)) = 0  ;
        Delg03a(isinf(Delg03a)) = EPS;
        Delg03b(isinf(Delg03b)) = EPS;
        
        % compute the gradients
        dg03adx = (Delg03a - g03a) / EPS;
        dg03bdx = (Delg03b - g03b) / EPS;
        
    else
        
        % no gradients needed
        dg03adx = [];
        dg03bdx = [];
        
    end
            
    if ((OptDesnTS   == 1) || (OptDesnTSPS == 1) || ...
        (OptDesnPSPS == 1) || (OptDesnPSES == 1)  )
    
        % get the number of splits
        ndvars = Aircraft.PowerOpt.ndvars;
        ndesns = Aircraft.PowerOpt.ndesns;
        nopers = Aircraft.PowerOpt.nopers;
    
        % memory for the gradients
        dg04adx = zeros(ndesns, ndvars);
        dg04bdx = zeros(ndesns, ndvars);
        
        % the gradients apply to the design splits only
        dg04adx(:, nopers + 1 : end) = -eye(ndesns);
        dg04bdx(:, nopers + 1 : end) = +eye(ndesns);
    
    else
        
        % no gradients needed
        dg04adx = [];
        dg04bdx = [];
        
    end
        
    % check for operational splits
    if ((OptOperTS   == 1) || (OptOperTSPS == 1) || ...
        (OptOperPSPS == 1) || (OptOperPSES == 1) )
        
        % remember variables from the aircraft structure
        nopers = Aircraft.PowerOpt.nopers;
        npoint = Aircraft.PowerOpt.npoint;
        ndvars = Aircraft.PowerOpt.ndvars;
        
        % memory for the gradient
        dg05adx = zeros(nopers, ndvars);
        
        % gradient for power splits being greater than 0
        dg05adx(1:nopers, 1:nopers) = -eye(nopers);
        
        % count the splits
        tsplit = 1;
        
        % get the number of TS   splits
        nsplit = Aircraft.Settings.nargTS  ;
        
        % check for TS   design splits
        if (OptOperTS   == 1)
            if (OptDesnTS   == 1)
            
                % memory for the gradient
                dg05bdx = zeros(npoint * nsplit, ndvars);
                
                % loop through the splits and constraint
                for isplit = 1:nsplit
                    
                    % compute the indices
                    ibeg = (tsplit - 1) * npoint + 1;
                    iend =  tsplit      * npoint    ;
                    
                    % compute the gradient
                    dg05bdx(ibeg:iend, ibeg:iend    ) = diag(repmat(1 / x(nopers + tsplit), npoint, 1));
                    dg05bdx(ibeg:iend, nopers+tsplit) = -x(ibeg:iend) ./ x(nopers + tsplit) ^ 2;
                    
                    % account for the split
                    tsplit = tsplit + 1;
                    
                end
                
            else
                
                % use the prescribed design split
                LamMax = Aircraft.Specs.Power.LamTS.SLS;
                
                % beginning index
                ibeg = (tsplit          - 1) * npoint + 1;
                iend = (tsplit + nsplit - 1) * npoint    ;
                
                % compute the gradient
                dg05bdx = diag(repmat(1 / LamMax, iend - ibeg + 1, 1));
                
                % account for the splits
                tsplit = tsplit + nsplit;
                
            end
            
        else
            
            % no gradients needed
            dg05bdx = [];
            
        end
        
        % get the number of TSPS splits
        nsplit = Aircraft.Settings.nargTSPS;
        
        % check for TSPS design splits
        if (OptOperTSPS == 1)
            if (OptDesnTSPS == 1)
            
                % memory for the gradient
                dg05cdx = zeros(npoint * nsplit, ndvars);
                
                % loop through the splits and constraint
                for isplit = 1:nsplit
                    
                    % compute the indices
                    ibeg = (tsplit - 1) * npoint + 1;
                    iend =  tsplit      * npoint    ;
                    
                    % compute the gradient
                    dg05cdx(ibeg:iend, ibeg:iend    ) = diag(repmat(1 / x(nopers + tsplit), npoint, 1));
                    dg05cdx(ibeg:iend, nopers+tsplit) = -x(ibeg:iend) ./ x(nopers + tsplit) ^ 2;
                    
                    % account for the split
                    tsplit = tsplit + 1;
                    
                end
                
            else
                
                % use the prescribed design split
                LamMax = Aircraft.Specs.Power.LamTSPS.SLS;
                
                % beginning index
                ibeg = (tsplit          - 1) * npoint + 1;
                iend = (tsplit + nsplit - 1) * npoint    ;
                
                % compute the gradient
                dg05cdx = diag(repmat(1 / LamMax, iend - ibeg + 1, 1));
                
                % account for the splits
                tsplit = tsplit + nsplit;
                
            end
            
        else
            
            % no gradients needed
            dg05cdx = [];
            
        end
        
        % get the number of PSPS splits
        nsplit = Aircraft.Settings.nargPSPS;
        
        % check for PSPS design splits
        if (OptOperPSPS == 1)
            if (OptDesnPSPS == 1)
            
                % memory for the gradient
                dg05ddx = zeros(npoint * nsplit, ndvars);
                
                % loop through the splits and constraint
                for isplit = 1:nsplit
                    
                    % compute the indices
                    ibeg = (tsplit - 1) * npoint + 1;
                    iend =  tsplit      * npoint    ;
                    
                    % compute the gradient
                    dg05ddx(ibeg:iend, ibeg:iend    ) = diag(repmat(1 / x(nopers + tsplit), npoint, 1));
                    dg05ddx(ibeg:iend, nopers+tsplit) = -x(ibeg:iend) ./ x(nopers + tsplit) ^ 2;
                    
                    % account for the split
                    tsplit = tsplit + 1;
                    
                end
                
            else
                
                % use the prescribed design split
                LamMax = Aircraft.Specs.Power.LamPSPS.SLS;
                
                % beginning index
                ibeg = (tsplit          - 1) * npoint + 1;
                iend = (tsplit + nsplit - 1) * npoint    ;
                
                % compute the gradient
                dg05ddx = diag(repmat(1 / LamMax, iend - ibeg + 1, 1));
                
                % account for the splits
                tsplit = tsplit + nsplit;
                
            end
            
        else
            
            % no gradients needed
            dg05ddx = [];
            
        end
        
        % get the number of PSES splits
        nsplit = Aircraft.Settings.nargPSES;
        
        % check for PSES design splits
        if (OptOperPSES == 1)
            if (OptDesnPSES == 1)
            
                % memory for the gradient
                dg05edx = zeros(npoint * nsplit, ndvars);
                
                % loop through the splits and constraint
                for isplit = 1:nsplit
                    
                    % compute the indices
                    ibeg = (tsplit - 1) * npoint + 1;
                    iend =  tsplit      * npoint    ;
                    
                    % compute the gradient
                    dg05edx(ibeg:iend, ibeg:iend    ) = diag(repmat(1 / x(nopers + tsplit), npoint, 1));
                    dg05edx(ibeg:iend, nopers+tsplit) = -x(ibeg:iend) ./ x(nopers + tsplit) ^ 2;
                    
                    % account for the split
                    tsplit = tsplit + 1;
                    
                end
                
            else
                
                % use the prescribed design split
                LamMax = Aircraft.Specs.Power.LamPSES.SLS;
                
                % beginning index
                ibeg = (tsplit          - 1) * npoint + 1;
                iend = (tsplit + nsplit - 1) * npoint    ;
                
                % compute the gradient
                dg05edx = diag(repmat(1 / LamMax, iend - ibeg + 1, 1));
                
            end
            
        else
            
            % no gradients needed
            dg05edx = [];
            
        end
        
        % check for NaNs or Infs
        dg05adx(isnan(dg05adx)) = 0;
        dg05bdx(isnan(dg05bdx)) = 0;
        dg05cdx(isnan(dg05cdx)) = 0;
        dg05ddx(isnan(dg05ddx)) = 0;
        dg05edx(isnan(dg05edx)) = 0;
        dg05adx(isinf(dg05adx)) = 1;
        dg05bdx(isinf(dg05bdx)) = 1;
        dg05cdx(isinf(dg05cdx)) = 1;
        dg05ddx(isinf(dg05ddx)) = 1;
        dg05edx(isinf(dg05edx)) = 1;
        
    else
        
        % no constraints are needed
        dg05adx = [];
        dg05bdx = [];
        dg05cdx = [];
        dg05ddx = [];
        dg05edx = [];
        
    end

    % check for on-design mission
    if (Aircraft.Settings.Analysis.Type == 1)
        
        % get the parameters for the engine sizing constraint
        PowEng = Aircraft.PowerOpt.Constraints.SenPavGT ;
        PowCrs = Aircraft.PowerOpt.Constraints.SenCrsPow;
        
        % compute the change in constraint
        Delg06 = PowCrs ./ PowEng - 1;
        
        % compute the gradient
        dg06dx = (Delg06 - g06) ./ EPS;
        
    else
        
        % no gradients needed
        dg06dx = [];
        
    end
    
    % return the gradients
    dgdx = [dg01adx; dg01bdx; dg02adx; dg02bdx; dg03adx; dg03bdx; ...
            dg04adx; dg04bdx; dg05adx; dg05bdx; dg05cdx; dg05ddx; ...
            dg05edx; dg06dx ]                                   ;
    
    % no equality constraints, so no gradients
    dhdx = [];
    
else
    
    % no gradients are required
    dgdx = [];
    dhdx = [];
    
end

% ----------------------------------------------------------

end