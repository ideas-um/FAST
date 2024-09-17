function [Aircraft] = CreatePropArch(Aircraft)
%
% [Aircraft] = CreatePropArch(Aircraft)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 17 sep 2024
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
EtaEG = Specs.Power.Eta.EG;


%% DEVELOP THE PROPULSION ARCHITECTURE %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% get the number of engines
NumEng = Aircraft.Specs.Propulsion.NumEngines;

% check the architecture type
if     (strcmpi(ArchName, "C"  ) == 1)
    
    % architecture matrix
    Arch = [0, ones(1, NumEng), zeros(1, NumEng), 0; ...
            zeros(NumEng, NumEng+1), eye(NumEng), zeros(NumEng, 1); ...
            zeros(NumEng, 2*NumEng+1), ones(NumEng, 1); ...
            zeros(1, 2*NumEng+2)];
        
    % upstream power splits
    LambdaU = @() [0, ones(1, NumEng) ./ NumEng, zeros(1, NumEng), 0; ...
               zeros(NumEng, NumEng+1), eye(NumEng), zeros(NumEng, 1); ...
               zeros(NumEng, 2*NumEng+1), ones(NumEng, 1); ...
               zeros(1, 2*NumEng+2)];
           
    % downstream power splits
    LambdaD = @() [zeros(1, 2*NumEng+2); ...
               ones(NumEng, 1), zeros(NumEng, 2*NumEng1); ...
               zeros(NumEng, 1), eye(NumEng), zeros(NumEng, NumEng+1); ...
               zeros(1, NumEng+1), ones(1, NumEng) ./ NumEng, 0];
           
    % check the aircraft class
    if (strcmpi(aclass, "Turbofan") == 1)
        
        % get the fan efficiency
        EtaTS = Aircraft.Specs.Propulsion.Engine.EtaPoly.Fan;
        
    elseif ((strcmpi(aclass, "Turboprop") == 1) || ...
            (strcmpi(aclass, "Piston"   ) == 1) )
        
        % get the propeller efficiency
        EtaTS = Aircraft.Specs.Power.Eta.Propeller;
        
    end
           
    % efficiency matrix
    Eta = [ones(1, 2*NumEng+2); ...
           ones(NumEng, NumEng+1), ones(NumEng) - eye(NumEng) .* (1 - EtaTS), ones(NumEng, 1); ...
           ones(NumEng+1, 2*NumEng+2)];
        
    % energy source type (1 = fuel, 0 = battery)
    ESType = 1;
    
    % power source type (1 = engine, 0 = electric motor, 2 = propeller/fan)
    PTType = [ones(1, NumEng), repmat(2, 1, NumEng)];
        
elseif (strcmpi(ArchName, "E"  ) == 1)
        
    % architecture matrix
    Arch = [0, ones(1, NumEng), zeros(1, NumEng), 0; ...
            zeros(NumEng, NumEng+1), eye(NumEng), zeros(NumEng, 1); ...
            zeros(NumEng, 2*NumEng+1), ones(NumEng, 1); ...
            zeros(1, 2*NumEng+2)];
        
    % upstream power splits
    LambdaU = @() [0, ones(1, NumEng) ./ NumEng, zeros(1, NumEng), 0; ...
               zeros(NumEng, NumEng+1), eye(NumEng), zeros(NumEng, 1); ...
               zeros(NumEng, 2*NumEng+1), ones(NumEng, 1); ...
               zeros(1, 2*NumEng+2)];
           
    % downstream power splits
    LambdaD = @() [zeros(1, 2*NumEng+2); ...
               ones(NumEng, 1), zeros(NumEng, 2*NumEng1); ...
               zeros(NumEng, 1), eye(NumEng), zeros(NumEng, NumEng+1); ...
               zeros(1, NumEng+1), ones(1, NumEng) ./ NumEng, 0];
           
    % check the aircraft class
    if (strcmpi(aclass, "Turbofan") == 1)
        
        % get the fan efficiency
        EtaTS = Aircraft.Specs.Propulsion.Engine.EtaPoly.Fan;
        
    elseif ((strcmpi(aclass, "Turboprop") == 1) || ...
            (strcmpi(aclass, "Piston"   ) == 1) )
        
        % get the propeller efficiency
        EtaTS = Aircraft.Specs.Power.Eta.Propeller;
        
    end
           
    % efficiency matrix
    Eta = [1, repmat(EtaEM, 1, NumEng), ones(1, NumEng+1); ...
           ones(NumEng, NumEng+1), ones(NumEng) - eye(NumEng) .* (1 - EtaTS), ones(NumEng, 1); ...
           ones(NumEng+1, 2*NumEng+2)];
        
    % energy source type (1 = fuel, 0 = battery)
    ESType = 0;
    
    % power source type (1 = engine, 0 = electric motor, 2 = propeller/fan)
    PTType = [zeros(1, NumEng), repmat(2, 1, NumEng)];
        
elseif (strcmpi(ArchName, "PHE") == 1)
    
    % architecture matrix
    Arch = [0, 0, ones(1, NumEng), zeros(1, 2*NumEng+1); ...
            zeros(1, NumEng+2), ones(1, NumEng), zeros(1, NumEng+1); ...
            zeros(NumEng, 2*NumEng+2), eye(NumEng), zeros(NumEng, 1); ...
            zeros(NumEng, 2*NumEng+2), eye(NumEng), zeros(NumEng, 1); ...
            zeros(NumEng, 3*NumEng+2), ones(NumEng, 1); ...
            zeros(1, 3*NumEng+3)];
        
    % upstream power splits
    LambdaU = @() [0, 0, ones(1, NumEng) ./NumEng, zeros(1, 2*NumEng+1); ...
            zeros(1, NumEng+2), ones(1, NumEng) ./NumEng, zeros(1, NumEng+1); ...
            zeros(NumEng, 2*NumEng+2), eye(NumEng), zeros(NumEng, 1); ...
            zeros(NumEng, 2*NumEng+2), eye(NumEng), zeros(NumEng, 1); ...
            zeros(NumEng, 3*NumEng+2), ones(NumEng, 1); ...
            zeros(1, 3*NumEng+3)];
           
    % downstream power splits
    LambdaD = @(lam) [zeros(2, 3*NumEng+3); ...
                   ones(NumEng, 1), zeros(3*NumEng+2); ...
                   zeros(NumEng, 1), ones(NumEng, 1), zeros(3*NumEng+1); ...
                   zeros(NumEng), eye(NumEng) .* (1 - lam), eye(NumEng) .* lam, zeros(NumEng, NumEng+1); ...
                   zeros(1, 2*NumEng+2), ones(1, NumEng) ./ NumEng, 0];
           
    % check the aircraft class
    if (strcmpi(aclass, "Turbofan") == 1)
        
        % get the fan efficiency
        EtaTS = Aircraft.Specs.Propulsion.Engine.EtaPoly.Fan;
        
    elseif ((strcmpi(aclass, "Turboprop") == 1) || ...
            (strcmpi(aclass, "Piston"   ) == 1) )
        
        % get the propeller efficiency
        EtaTS = Aircraft.Specs.Power.Eta.Propeller;
        
    end
           
    % efficiency matrix
    Eta = [ones(1, 3*NumEng+3); ...
           ones(1, NumEng+2), repmat(EtaEM, 1, NumEng), ones(1, NumEng+1); ...
           ones(NumEng, 2*NumEng+2), ones(NumEng) - eye(NumEng) .* (1 - EtaTS), ones(NumEng, 1); ...
           ones(NumEng, 2*NumEng+2), ones(NumEng) - eye(NumEng) .* (1 - EtaTS), ones(NumEng, 1); ...
           ones(NumEng+1, 3*NumEng+3)];
        
    % energy source type (1 = fuel, 0 = battery)
    ESType = [1, 0];
    
    % power source type (1 = engine, 0 = electric motor, 2 = propeller/fan)
    PTType = [ones(1, NumEng), zeros(1, NumEng), repmat(2, 1, NumEng)];
    
elseif (strcmpi(ArchName, "SHE") == 1)
    
    % architecture matrix
    Arch = [0, 0, ones(1, NumEng), zeros(1, 2*NumEng+1); ...
            zeros(1, NumEng+2), ones(1, NumEng), zeros(1, NumEng+1); ...
            zeros(NumEng, NumEng+2), eye(NumEng), zeros(NumEng, NumEng+1); ...
            zeros(NumEng, 2*NumEng+2), eye(NumEng), zeros(NumEng, 1); ...
            zeros(NumEng, 3*NumEng+2), ones(NumEng, 1); ...
            zeros(1, 3*NumEng+3)];
        
    % upstream power splits
    LambdaU = @() [0, 0, ones(1, NumEng) ./ NumEng, zeros(1, 2*NumEng+1); ...
            zeros(1, NumEng+2), ones(1, NumEng) ./ NumEng, zeros(1, NumEng+1); ...
            zeros(NumEng, NumEng+2), eye(NumEng), zeros(NumEng, NumEng+1); ...
            zeros(NumEng, 2*NumEng+2), eye(NumEng), zeros(NumEng, 1); ...
            zeros(NumEng, 3*NumEng+2), ones(NumEng, 1); ...
            zeros(1, 3*NumEng+3)];
           
    % downstream power splits
    LambdaD = @(lam) [zeros(2, 3*NumEng+3); ...
              ones(NumEng, 1), zeros(NumEng, 3*NumEng+2); ...
              zeros(NumEng, 1), repmat(lam, NumEng, 1), eye(NumEng) .* (1 - lam), zeros(NumEng, 2*NumEng+1); ...
              zeros(NumEng, 2*NumEng+2), eye(NumEng), zeros(NumEng, NumEng+1); ...
              zeros(1, 2*NumEng+2), ones(1, NumEng) ./ NumEng, 0];
           
    % check the aircraft class
    if (strcmpi(aclass, "Turbofan") == 1)
        
        % get the fan efficiency
        EtaTS = Aircraft.Specs.Propulsion.Engine.EtaPoly.Fan;
        
    elseif ((strcmpi(aclass, "Turboprop") == 1) || ...
            (strcmpi(aclass, "Piston"   ) == 1) )
        
        % get the propeller efficiency
        EtaTS = Aircraft.Specs.Power.Eta.Propeller;
        
    end
           
    % efficiency matrix
    Eta = [ones(1, 3*NumEng+3); ...
        ones(1, NumEng+2), repmat(EtaEM, 1, NumEng), ones(1, NumEng+1); ...
        ones(NumEng, NumEng+2), ones(NumEng) - eye(NumEng) .* (1 - EtaEM), ones(NumEng, NumEng+1); ...
        ones(NumEng, 2*NumEng+2), ones(NumEng) - eye(NumEng) .* (1 - EtaTS), ones(NumEng, 1); ...
        ones(NumEng+1, 3*NumEng+3)];
        
    % energy source type (1 = fuel, 0 = battery)
    ESType = [1, 0];
    
    % power source type (1 = engine, 0 = electric motor, 2 = propeller/fan)
    PTType = [ones(1, NumEng), zeros(1, NumEng), repmat(2, 1, NumEng)];
    
elseif (strcmpi(ArchName, "TE" ) == 1)
    
    % architecture matrix
    Arch = [0, ones(1, NumEng), zeros(1, 2*NumEng+1); ...
            zeros(NumEng, NumEng+1), eye(NumEng), zeros(NumEng, NumEng+1); ...
            zeros(NumEng, 2*NumEng+1), eye(NumEng), zeros(NumEng, 1); ...
            zeros(NumEng, 3*NumEng+1), ones(NumEng, 1); ...
            zeros(1, 3*NumEng+2)];
        
    % upstream power splits
    LambdaU = @() [0, ones(1, NumEng) ./ NumEng, zeros(1, 2*NumEng+1); ...
            zeros(NumEng, NumEng+1), eye(NumEng), zeros(NumEng, NumEng+1); ...
            zeros(NumEng, 2*NumEng+1), eye(NumEng), zeros(NumEng, 1); ...
            zeros(NumEng, 3*NumEng+1), ones(NumEng, 1); ...
            zeros(1, 3*NumEng+2)];
           
    % downstream power splits
    LambdaD = @(lam) [zeros(1, 3*NumEng+2); ...
        ones(NumEng, 1), zeros(NumEng, 3*NumEng+1); ...
        zeros(NumEng, 1), eye(NumEng), zeros(NumEng, 2*NumEng+1); ...
        zeros(NumEng, NumEng+1), eye(NumEng), zeros(NumEng, NumEng+1); ...
        zeros(1, 2*NumEng+1), ones(1, NumEng) ./ NumEng, 0];
           
    % check the aircraft class
    if (strcmpi(aclass, "Turbofan") == 1)
        
        % get the fan efficiency
        EtaTS = Aircraft.Specs.Propulsion.Engine.EtaPoly.Fan;
        
    elseif ((strcmpi(aclass, "Turboprop") == 1) || ...
            (strcmpi(aclass, "Piston"   ) == 1) )
        
        % get the propeller efficiency
        EtaTS = Aircraft.Specs.Power.Eta.Propeller;
        
    end
           
    % efficiency matrix
    Eta = [ones(1, 3*NumEng+2); ...
        ones(NumEng, NumEng+1), ones(NumEng) - eye(NumEng) .* (1 - EtaEM), ones(NumEng, NumEng+1); ...
        ones(NumEng, 2*NumEng+1), ones(NumEng) - eye(NumEng) .* (1 - EtaTS), ones(NumEng, 1); ...
        ones(NumEng+1, 3*NumEng+2)];
        
    % energy source type (1 = fuel, 0 = battery)
    ESType = 1;
    
    % power source type (1 = engine, 0 = electric motor, 2 = propeller/fan)
    PTType = [ones(1, NumEng), zeros(1, NumEng), repmat(2, 1, NumEng)];
    
elseif (strcmpi(ArchName, "PE" ) == 1)
    
    % architecture matrix
    Arch = [0, ones(1, NumEng), zeros(1, 4*NumEng), 0; ...
        zeros(NumEng, 1), zeros(NumEng), eye(NumEng), zeros(NumEng), eye(NumEng), zeros(NumEng, NumEng+1); ...
        zeros(NumEng, 2*NumEng+1), eye(NumEng), zeros(NumEng, 2*NumEng+1); ...
        zeros(NumEng, 4*NumEng+1), eye(NumEng), zeros(NumEng, 1); ...
        zeros(2*NumEng, 5*NumEng+1), ones(2*NumEng, 1); ...
        zeros(1, 5*NumEng+2)];
        
    % upstream power splits
    LambdaU = @(LamU) [0, ones(1, NumEng) ./ NumEng, zeros(1, 4*NumEng), 0; ...
        zeros(NumEng, 1), zeros(NumEng), eye(NumEng) .* (1 - LamU), zeros(NumEng), eye(NumEng) .* LamU, zeros(NumEng+1); ...
        zeros(NumEng, 2*NumEng+1), eye(NumEng), zeros(NumEng, 2*NumEng+1); ...
        zeros(NumEng, 4*NumEng+1), eye(NumEng), zeros(NumEng, 1); ...
        zeros(2*NumEng, 5*NumEng+1), ones(2*NumEng, 1); ...
        zeros(1, 5*NumEng+2)];
           
    % downstream power splits
    LambdaD = @(LamD) [zeros(1, 5*NumEng+2); ...
        ones(NumEng, 1), zeros(NumEng, 5*NumEng+1); ...
        zeros(NumEng, 1), eye(NumEng), zeros(4*NumEng+1); ...
        zeros(NumEng, NumEng+1), eye(NumEng), zeros(NumEng, 3*NumEng+1); ...
        zeros(NumEng, 1), eye(NumEng), zeros(4*NumEng+1); ...
        zeros(NumEng, 2*NumEng+1), eye(NumEng), zeros(NumEng, 2*NumEng+1); ...
        zeros(1, 3*NumEng+1), repmat(1 - LamD, 1, NumEng), repmat(LamD, 1, NumEng), 0];
           
    % check the aircraft class
    if (strcmpi(aclass, "Turbofan") == 1)
        
        % get the fan efficiency
        EtaTS = Aircraft.Specs.Propulsion.Engine.EtaPoly.Fan;
        
    elseif ((strcmpi(aclass, "Turboprop") == 1) || ...
            (strcmpi(aclass, "Piston"   ) == 1) )
        
        % get the propeller efficiency
        EtaTS = Aircraft.Specs.Power.Eta.Propeller;
        
    end
           
    % efficiency matrix
    Eta = [1, ones(1, NumEng), ones(1, 4*NumEng+1); ...
        ones(NumEng, NumEng+1), ones(NumEng) - eye(NumEng) .* (1 - EtaEG), ones(NumEng), ones(NumEng) - eye(NumEng) .* (1 - EtaTS), ones(NumEng, NumEng+1); ...
        ones(NumEng, 2*NumEng+1), ones(NumEng) - eye(NumEng) .* (1 - EtaEM), ones(NumEng, 2*NumEng+1); ...
        ones(NumEng, 4*NumEng+1), ones(NumEng) - eye(NumEng) .* (1 - EtaTS), ones(NumEng, 1); ...
        ones(2*NumEng+1, 5*NumEng+2)];
        
    % energy source type (1 = fuel, 0 = battery)
    ESType = 1;
    
    % power source type (1 = engine, 0 = electric motor, 2 = propeller/fan, 3 = electric generator)
    PTType = [ones(1, NumEng), repmat(3, 1, NumEng), zeros(1, NumEng), repmat(2, 1, 2*NumEng)];
    
elseif (strcmpi(ArchName, "O"  ) == 1)
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %                            %
    % check that each matrix     %
    % exists                     %
    %                            %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
    % check for the architectures
    HaveArch = isfield(Specs.Propulsion.PropArch, "Arch");
    
    % confirm that they're all present
    if (HaveArch ~= 1)
        error("ERROR - CreatePropArch: check that 'Arch' in 'Specs.Propulsion.PropArch' is initialized.");
    end
                           
    % check for the operational matrices
    HaveOper = isfield(Specs.Propulsion.Oper, ["LambdaU"; "LambdaD"]);
    
    % confirm that they're all present
    if (sum(HaveOper) ~= 2)
        error("ERROR - CreatePropArch: check that 'Oper.LambdaU' and 'Oper.LambdaD' in 'Specs.Propulsion' are initialized.");
    end
    
    % check for the efficiencies
    HaveEtas = isfield(Specs.Propulsion, "Eta");
    
    % confirm that they're all present
    if (HaveEtas ~= 1)
        error("ERROR - CreatePropArch: check that 'Eta' in 'Specs.Propulsion' is initialized.");
    end
    
    % check for the component types
    HaveType = isfield(Specs.Propulsion.PropArch, ["ESType", "PTType"]);
    
    % confirm that they're all present
    if (sum(HaveType) ~= 2)
        error("ERROR - CreatePropArch: check that 'PropArch.ESType' and 'PropArch.PTType' in 'Specs.Propulsion' are initialized.");
    end
    
    % get number of arguments for each (potential) split
    Aircraft.Settings.nargLambdaU = nargin(Aircraft.Specs.Propulsion.Oper.LambdaU);
    Aircraft.Settings.nargLambdaD = nargin(Aircraft.Specs.Propulsion.Oper.LambdaD);
    
    % ------------------------------------------------------
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %                            %
    % get the matrices           %
    %                            %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % get the propulsion architecture
    Arch = Specs.Propulsion.PropArch.Arch;
    
    % get the operational matrices
    LambdaU = Specs.Propulsion.Oper.LambdaU;
    LambdaD = Specs.Propulsion.Oper.LambdaU;
    
    % get the efficiency matrix
    Eta = Specs.Propulsion.Eta;
    
    % get the ES and PT types
    ESType = Specs.Propulsion.PropArch.ESType;
    PTType = Specs.Propulsion.PropArch.PTType;
    
    % ------------------------------------------------------
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %                            %
    % check for the correct      %
    % matrix sizes               %
    %                            %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
    % get the size of the architecture matrix
    [nrow, ncol] = size(Arch);
    
    % check for the same number of rows/columns in the architecture matrix
    if (nrow ~= ncol)
        
        % throw an error
        error("ERROR - CreatePropArch: the architecture matrix must be square.");
        
    end
    
    % get the size of the downstream matrix
    [nrow, ncol] = size(LambdaD);
    
    % check for the same number of rows/columns in the downstream matrix
    if (nrow ~= ncol)
        
        % throw an error
        error("ERROR - CreatePropArch: the downstream operational matrix must be square.");
        
    end
    
    % get the size of the upstream matrix
    [nrow, ncol] = size(LambdaU);
    
    % check for the same number of rows/columns in the upstream matrix
    if (nrow ~= ncol)
        
        % throw an error
        error("ERROR - CreatePropArch: the upstream operational matrix must be square.");
        
    end
    
    % get the size of the efficiency matrix
    [nrow, ncol] = size(Eta);
    
    % check for the same number of rows/columns in the efficiency matrix
    if (nrow ~= ncol)
        
        % throw an error
        error("ERROR - CreatePropArch: the efficiency matrix must be square.");
        
    end
    
    % ------------------------------------------------------
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %                            %
    % check for the correct      %
    % number of energy sources,  %
    % power transmitters, and    %
    % power sinks                %
    %                            %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % number of energy sources
    nes = sum(sum(Arch, 1) == 0);
    
    % number of power sinks
    nps = sum(sum(Arch, 2) == 0);
    
    % number of power transmitters
    npt = nrow - nes - nps;
    
    % check that the number of energy sources match
    if (nes ~= length(ESType))
        
        % throw an error
        error("ERROR - CreatePropArch: incorrect number of energy sources prescribed.");
        
    end
    
    % check that the number of power transmitters match
    if (npt ~= length(PTType))
        
        % throw an error
        error("ERROR - CreatePropArch: incorrect number of power transmitters prescribed.");
        
    end
    
    % ------------------------------------------------------
    
    % if we've succeeded, exit the function (architecture already stored)
    return
    
else
    
    % throw error
    error("ERROR - CreatePropArch: invalid propulsion architecture provided.");
    
end


%% FILL THE STRCTURE %%
%%%%%%%%%%%%%%%%%%%%%%%

% remember the architectures
Aircraft.Specs.Propulsion.PropArch.Arch = Arch;

% remember the operation
Aircraft.Specs.Propulsion.Oper.LambdaU = LambdaU;
Aircraft.Specs.Propulsion.Oper.LambdaD = LambdaD;

% remember the efficiencies
Aircraft.Specs.Propulsion.Eta = Eta;

% remember the component types in the architecture
Aircraft.Specs.Propulsion.PropArch.ESType = ESType;
Aircraft.Specs.Propulsion.PropArch.PTType = PTType;

% get number of arguments for each (potential) split
Aircraft.Settings.nargLambdaU = nargin(Aircraft.Specs.Propulsion.Oper.LambdaU);
Aircraft.Settings.nargLambdaD = nargin(Aircraft.Specs.Propulsion.Oper.LambdaD);

% ----------------------------------------------------------
    
end