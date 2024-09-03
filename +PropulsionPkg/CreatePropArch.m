function [Aircraft] = CreatePropArch(Aircraft)
%
% [Aircraft] = CreatePropArch(Aircraft)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 27 aug 2024
%
% Given a propulsion architecture, create the necessary interdependency,
% operation and efficiency matrices to perform a propulsion system
% analysis.
%
% INPUTS:
%     Aircraft - structure with information about the propulsion
%                architecture and component efficiencies.
%                size/type/units: 1-by-1 / struct / []
%
% OUTPUTS:
%     Aircraft - structure with the filled propulsion architecture,
%                operation, and efficiency matrices.
%                size/type/units: 1-by-1 / struct / []
%


%% INFORMATION FROM AIRCRAFT STRUCTURE %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% shorthand for the aircraft specifications
Specs = Aircraft.Specs;

% get the aircraft class
aclass = Specs.TLAR.Class;

% check for a specified propulsion architecture
if (isfield(Specs.Propulsion.Arch, "Type"))
    
    % get the "pre-built" architecture
    ArchName = Specs.Propulsion.Arch.Type;
    
else
    
    % assume a custom architecture
    ArchName = "O";
    
end
    
% get the electrical component efficiencies
EtaEM = Specs.Power.Eta.EM;


%% DEVELOP THE PROPULSION ARCHITECTURE %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% get the number of engines
NumEng = Aircraft.Specs.Propulsion.NumEngines;

% check the architecture type
if     (strcmpi(ArchName, "C"  ) == 1)
        
    % thrust-power source architecture
    ArchTSPS = eye(NumEng);
    
    % power-power  source architecture
    ArchPSPS = eye(NumEng);
    
    % power-energy source architecture
    ArchPSES = ones(NumEng, 1);
    
    % thrust       source operation
    OperTS   = @() ones(1, NumEng) ./ NumEng;
    
    % thrust-power source operation
    OperTSPS = @() eye(NumEng);
    
    % power-power  source operation
    OperPSPS = @() eye(NumEng);
    
    % power-energy source operation
    OperPSES = @() ones(NumEng, 1);
    
    % thrust-power  source efficiency (assume it's perfect)
    EtaTSPS = ones(NumEng, NumEng);
    
    % check if a turboprop is being flown
    if ((strcmpi(aclass, "Turboprop") == 1) || ...
        (strcmpi(aclass, "Piston"   ) == 1) )
    
        % get the propeller efficiency
        EtaPropeller = Aircraft.Specs.Power.Eta.Propeller;
        
        % use the propeller efficiency in the TSPS efficiency
        EtaTSPS = EtaTSPS + (EtaPropeller - 1) .* eye(NumEng);
        
    elseif (strcmpi(aclass, "Turbofan") == 1)
        
        % account for the fan efficiency
        EtaTSPS = EtaTSPS + (Aircraft.Specs.Propulsion.Engine.EtaPoly.Fan - 1) .* eye(NumEng);
        
    end
    
    % power -power  source efficiency
    EtaPSPS = ones(NumEng, NumEng);
    
    % power -energy source efficiency
    EtaPSES = ones(NumEng, 1);
    
    % energy source type (1 = fuel, 0 = battery)
    ESType = 1;
    
    % power source type (1 = engine, 0 = electric motor)
    PSType = ones(1, NumEng);
        
elseif (strcmpi(ArchName, "E"  ) == 1)
        
    % thrust-power source architecture
    ArchTSPS = eye(NumEng);
    
    % power-power  source architecture
    ArchPSPS = eye(NumEng);
    
    % power-energy source architecture
    ArchPSES = ones(NumEng, 1);
    
    % thrust       source operation
    OperTS   = @() ones(1, NumEng) ./ NumEng;
    
    % thrust-power source operation
    OperTSPS = @() eye(NumEng);
    
    % power-power  source operation
    OperPSPS = @() eye(NumEng);
    
    % power-energy source operation
    OperPSES = @() ones(NumEng, 1);
    
    % thrust-power  source efficiency (assume it's perfect)
    EtaTSPS = ones(NumEng, NumEng);
    
    % check if a turboprop is being flown
    if ((strcmpi(aclass, "Turboprop") == 1) || ...
        (strcmpi(aclass, "Piston"   ) == 1) )
    
        % get the propeller efficiency
        EtaPropeller = Aircraft.Specs.Power.Eta.Propeller;
        
        % use the propeller efficiency in the TSPS efficiency
        EtaTSPS = EtaTSPS + (EtaPropeller - 1) .* eye(NumEng);
        
    elseif (strcmpi(aclass, "Turbofan") == 1)
        
        % account for the fan efficiency
        EtaTSPS = EtaTSPS + (Aircraft.Specs.Propulsion.Engine.EtaPoly.Fan - 1) .* eye(NumEng);
        
    end
    
    % power -power  source efficiency
    EtaPSPS = ones(NumEng, NumEng);
    
    % power -energy source efficiency
    EtaPSES = repmat(EtaEM, NumEng, 1);
    
    % energy source type (1 = fuel, 0 = battery)
    ESType = 0;
    
    % power source type (1 = engine, 0 = electric motor)
    PSType = zeros(1, NumEng);
        
elseif (strcmpi(ArchName, "PHE") == 1)
    
    % thrust-power source matrix
    ArchTSPS = repmat(eye(NumEng), 1, 2);
    
    % power-power source matrix
    ArchPSPS = eye(2 * NumEng);
    
    % power-energy source matrix (first group - fuel; second group - batt)
    ArchPSES = [ones(NumEng, 1), zeros(NumEng, 1); zeros(NumEng, 1), ones(NumEng, 1)];
    
    % thrust      source operation
    OperTS   = @() ones(1, NumEng) ./ NumEng;
    
    % thrust-power source operation
    OperTSPS = @(lambda) [(1 - lambda) .* eye(NumEng), lambda .* eye(NumEng)];
    
    % power-power  source operation
    OperPSPS = @() eye(2 * NumEng);
    
    % power-energy source operation
    OperPSES = @() [ones(NumEng, 1), zeros(NumEng, 1); zeros(NumEng, 1), ones(NumEng, 1)];
    
    % thrust-power  source efficiency (assume it's perfect)
    EtaTSPS = ones(NumEng, 2 * NumEng);
    
    % check if a turboprop is being flown
    if ((strcmpi(aclass, "Turboprop") == 1) || ...
        (strcmpi(aclass, "Piston"   ) == 1) )
    
        % get the propeller efficiency
        EtaPropeller = Aircraft.Specs.Power.Eta.Propeller;
        
        % use the propeller efficiency in the TSPS efficiency
        EtaTSPS = EtaTSPS + (EtaPropeller - 1) .* repmat(eye(NumEng), 1, 2);
        
    elseif (strcmpi(aclass, "Turbofan") == 1)
        
        % account for the fan efficiency
        EtaTSPS = EtaTSPS + (Aircraft.Specs.Propulsion.Engine.EtaPoly.Fan - 1) .* repmat(eye(NumEng), 1, 2);
        
    end
        
    % power -power  source efficiency
    EtaPSPS  = ones(2 * NumEng, 2 * NumEng);
    
    % power -energy source efficiency
    EtaPSES  = [ones(NumEng, 2); ones(NumEng, 1), repmat(EtaEM, NumEng, 1)];
    
    % energy source type (1 = fuel, 0 = battery)
    ESType = [1, 0];
    
    % power source type (1 = engine, 0 = electric motor)
    PSType = [ones(1, NumEng), zeros(1, NumEng)];
    
elseif (strcmpi(ArchName, "SHE") == 1)
    
    % thrust-power source matrix
    ArchTSPS = [zeros(NumEng), eye(NumEng)];
    
    % power-power source matrix
    ArchPSPS = [eye(NumEng), zeros(NumEng); eye(NumEng), eye(NumEng)];
    
    % power-energy source matrix (first group - fuel; second group - batt)
    ArchPSES = [ones(NumEng, 1), zeros(NumEng, 1); zeros(NumEng, 1), ones(NumEng, 1)];
    
    % thrust      source operation
    OperTS   = @() ones(1, NumEng) ./ NumEng;
    
    % thrust-power source operation
    OperTSPS = @() [zeros(NumEng), eye(NumEng)];
    
    % power-power  source operation
    OperPSPS = @(lambda) [eye(NumEng), zeros(NumEng); (1 - lambda) .* eye(NumEng), eye(NumEng)];
    
    % power-energy source operation
    OperPSES = @(lambda) [ones(NumEng, 1), zeros(NumEng, 1); zeros(NumEng, 1), lambda .* ones(NumEng, 1)];
    
    % thrust-power  source efficiency (assume it's perfect)
    EtaTSPS = ones(NumEng, 2 * NumEng);
    
    % check if a turboprop is being flown
    if ((strcmpi(aclass, "Turboprop") == 1) || ...
        (strcmpi(aclass, "Piston"   ) == 1) )
    
        % get the propeller efficiency
        EtaPropeller = Aircraft.Specs.Power.Eta.Propeller;
        
        % use the propeller efficiency in the TSPS efficiency
        EtaTSPS(:, NumEng+1:end) = EtaTSPS(:, NumEng+1:end) + (EtaPropeller - 1) .* eye(NumEng);
        
    end
        
    % power -power  source efficiency
    EtaPSPS  = ones(2 * NumEng);
    
    % power -energy source efficiency
    EtaPSES  = [ones(NumEng, 2); ones(NumEng, 1), repmat(EtaEM, NumEng, 1)];
    
    % energy source type (1 = fuel, 0 = battery)
    ESType = [1, 0];
    
    % power source type (1 = engine, 0 = electric motor)
    PSType = [ones(1, NumEng), zeros(1, NumEng)];
    
elseif (strcmpi(ArchName, "TE" ) == 1)
    
    % thrust-power source matrix
    ArchTSPS = [zeros(NumEng), eye(NumEng)];
    
    % power-power source matrix
    ArchPSPS = [eye(NumEng), zeros(NumEng); eye(NumEng), eye(NumEng)];
    
    % power-energy source matrix (first group - fuel; second group - batt)
    ArchPSES = [ones(NumEng, 1); zeros(NumEng, 1)];
    
    % thrust      source operation
    OperTS   = @() ones(1, NumEng) ./ NumEng;
    
    % thrust-power source operation
    OperTSPS = @() [zeros(NumEng), eye(NumEng)];
    
    % power-power  source operation
    OperPSPS = @() [eye(NumEng), zeros(NumEng); eye(NumEng), eye(NumEng)];
    
    % power-energy source operation
    OperPSES = @() [ones(NumEng, 1); zeros(NumEng, 1)];
    
    % thrust-power  source efficiency (assume it's perfect)
    EtaTSPS = ones(NumEng, 2 * NumEng);
    
    % check if a turboprop is being flown
    if ((strcmpi(aclass, "Turboprop") == 1) || ...
        (strcmpi(aclass, "Piston"   ) == 1) )
    
        % get the propeller efficiency
        EtaPropeller = Aircraft.Specs.Power.Eta.Propeller;
        
        % use the propeller efficiency in the TSPS efficiency
        EtaTSPS(:, NumEng+1:end) = EtaTSPS(:, NumEng+1:end) + (EtaPropeller - 1) .* eye(NumEng);
        
    end
        
    % power -power  source efficiency is initialized to all 1
    EtaPSPS = ones(2 * NumEng);
    
    % account for the electric motor efficiency
    EtaPSPS(NumEng+1:end, 1:NumEng) = EtaPSPS(NumEng+1:end, 1:NumEng) - (1 - EtaEM) .* eye(NumEng);
    
    % power -energy source efficiency
    EtaPSES  = ones(2 * NumEng, 1);
    
    % energy source type (1 = fuel, 0 = battery)
    ESType = 1;
    
    % power source type (1 = engine, 0 = electric motor)
    PSType = [ones(1, NumEng), zeros(1, NumEng)];
    
elseif (strcmpi(ArchName, "PE" ) == 1)
    
    % thrust-power source matrix
    ArchTSPS = eye(2 * NumEng);
    
    % power-power source matrix
    ArchPSPS = [eye(NumEng), zeros(NumEng); eye(NumEng), eye(NumEng)];
    
    % power-energy source matrix (first group - fuel; second group - batt)
    ArchPSES = [ones(NumEng, 1); zeros(NumEng, 1)];
    
    % thrust      source operation
    OperTS   = @() ones(1, 2 * NumEng) ./ 2 * NumEng;
    
    % thrust-power source operation
    OperTSPS = @() eye(2 * NumEng);
    
    % power-power  source operation
    OperPSPS = @() [eye(NumEng), zeros(NumEng); eye(NumEng), eye(NumEng)];
    
    % power-energy source operation
    OperPSES = @() [ones(NumEng, 1); zeros(NumEng, 1)];
    
    % thrust-power  source efficiency (assume it's perfect)
    EtaTSPS = ones(2 * NumEng);
    
    % check if a turboprop is being flown
    if ((strcmpi(aclass, "Turboprop") == 1) || ...
        (strcmpi(aclass, "Piston"   ) == 1) )
    
        % get the propeller efficiency
        EtaPropeller = Aircraft.Specs.Power.Eta.Propeller;
        
        % use the propeller efficiency in the TSPS efficiency
        EtaTSPS = EtaTSPS + (EtaPropeller - 1) .* eye(2 * NumEng);
        
    end
        
    % power -power  source efficiency is initialized to all 1
    EtaPSPS = ones(2 * NumEng);
    
    % account for the electric motor efficiency
    EtaPSPS(NumEng+1:end, 1:NumEng) = EtaPSPS(NumEng+1:end, 1:NumEng) - (1 - EtaEM) .* eye(NumEng);
    
    % power -energy source efficiency
    EtaPSES  = ones(2 * NumEng, 1);
    
    % energy source type (1 = fuel, 0 = battery)
    ESType = 1;
    
    % power source type (1 = engine, 0 = electric motor)
    PSType = [ones(1, NumEng), zeros(1, NumEng)];
    
elseif (strcmpi(ArchName, "O"  ) == 1)
    
    % check for the architectures
    HaveArch = isfield(Specs.Propulsion.PropArch, ["TSPS"; "PSPS"; "PSES"]);
    
    % confirm that they're all present
    if (sum(HaveArch) ~= 3)
        error("ERROR - CreatePropArch: check that 'PropArch.TSPS', 'PropArch.PSPS', and 'PropArch.PSES' in 'Specs.Propulsion' are initialized.");
    end
                       
    % check for the operational matrices
    HaveOper = isfield(Specs.Propulsion.Oper, ["TS"; "TSPS"; "PSPS"; "PSES"]);
    
    % confirm that they're all present
    if (sum(HaveOper) ~= 4)
        error("ERROR - CreatePropArch: check that 'Oper.TS', 'Oper.TSPS', 'Oper.PSPS', and 'Oper.PSES' in 'Specs.Propulsion' are initialized.");
    end
    
    % check for the upstream operational matrices
    HaveUpOper = isfield(Specs.Propulsion.Oper, ["TSPS"; "PSPS"; "PSES"]);
    
    % confirm that they're all present
    if (sum(HaveUpOper) ~= 3)
        error("ERROR - CreatePropArch: check that 'Upstream.TSPS', 'Upstream.PSPS', and 'Upstream.PSES' in 'Specs.Propulsion' are initialized.");
    end
    
    % check for the efficiencies
    HaveEtas = isfield(Specs.Propulsion.Eta, ["TSPS"; "PSPS"]);
    
    % confirm that they're all present
    if (sum(HaveEtas) ~= 2)
        error("ERROR - CreatePropArch: check that 'Eta.TSPS' and 'Eta.PSPS' in 'Specs.Propulsion' are initialized.");
    end
    
    % check for the component types
    HaveType = isfield(Specs.Propulsion.PropArch, ["ESType", "PSType"]);
    
    % confirm that they're all present
    if (sum(HaveType) ~= 2)
        error("ERROR - CreatePropArch: check that 'PropArch.ESType' and 'PropArch.PSType' in 'Specs.Propulsion' are initialized.");
    end
    
    % get number of arguments for each (potential) split
    Aircraft.Settings.nargTS   = nargin(Aircraft.Specs.Propulsion.Oper.TS  );
    Aircraft.Settings.nargTSPS = nargin(Aircraft.Specs.Propulsion.Oper.TSPS);
    Aircraft.Settings.nargPSPS = nargin(Aircraft.Specs.Propulsion.Oper.PSPS);
    Aircraft.Settings.nargPSES = nargin(Aircraft.Specs.Propulsion.Oper.PSES);
    
    % if we've succeeded, exit the function (architecture already stored)
    return
    
else
    
    % throw error
    error("ERROR - CreatePropArch: invalid propulsion architecture provided.");
    
end


%% FILL THE STRCTURE %%
%%%%%%%%%%%%%%%%%%%%%%%

% remember the architectures
Aircraft.Specs.Propulsion.PropArch.TSPS = ArchTSPS;
Aircraft.Specs.Propulsion.PropArch.PSPS = ArchPSPS;
Aircraft.Specs.Propulsion.PropArch.PSES = ArchPSES;

% remember the operation (downstream splits)
Aircraft.Specs.Propulsion.Oper.TS   = OperTS  ;
Aircraft.Specs.Propulsion.Oper.TSPS = OperTSPS;
Aircraft.Specs.Propulsion.Oper.PSPS = OperPSPS;
Aircraft.Specs.Propulsion.Oper.PSES = OperPSES;

% remember the efficiencies
Aircraft.Specs.Propulsion.Eta.TSPS = EtaTSPS;
Aircraft.Specs.Propulsion.Eta.PSPS = EtaPSPS;
Aircraft.Specs.Propulsion.Eta.PSES = EtaPSES;

% remember the component types in the architecture
Aircraft.Specs.Propulsion.PropArch.ESType = ESType;
Aircraft.Specs.Propulsion.PropArch.PSType = PSType;

% get number of arguments for each (potential) split
Aircraft.Settings.nargTS   = nargin(Aircraft.Specs.Propulsion.Oper.TS  );
Aircraft.Settings.nargTSPS = nargin(Aircraft.Specs.Propulsion.Oper.TSPS);
Aircraft.Settings.nargPSPS = nargin(Aircraft.Specs.Propulsion.Oper.PSPS);
Aircraft.Settings.nargPSES = nargin(Aircraft.Specs.Propulsion.Oper.PSES);

% ----------------------------------------------------------
    
end