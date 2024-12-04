function [Aircraft] = CreatePropArch(Aircraft)
%
% [Aircraft] = CreatePropArch(Aircraft)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 04 dec 2024
%
% Given a propulsion architecture, create the necessary architecture,
% operation and efficiency matrices to perform a propulsion system
% analysis. For all matrices created, the convention is to order the
% components as: sources, transmitters, and sinks.
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
if (isfield(Specs.Propulsion.PropArch, "Type"))
    
    % get the "pre-built" architecture
    ArchName = Specs.Propulsion.PropArch.Type;
    
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
    Arch = [zeros(     1, 1),  ones(     1, NumEng), zeros(     1, NumEng), zeros(     1, 1); ... % connect fuel to gas-turbine engines
            zeros(NumEng, 1), zeros(NumEng, NumEng),   eye(NumEng, NumEng), zeros(NumEng, 1); ... % connect gas-turbine engines to propellers/fans
            zeros(NumEng, 1), zeros(NumEng, NumEng), zeros(NumEng, NumEng),  ones(NumEng, 1); ... % connect propellers/fans to the sink
            zeros(     1, 1), zeros(     1, NumEng), zeros(     1, NumEng), zeros(     1, 1)] ;   % the sink connects to nothing
        
    % upstream operational matrix
    OperUps = @() ...
              [zeros(     1, 1), repmat(1 / NumEng,      1, NumEng), zeros(     1, NumEng), zeros(     1, 1); ... % split fuel evenly amongst gas-turbine engines
               zeros(NumEng, 1), zeros(             NumEng, NumEng),   eye(NumEng, NumEng), zeros(NumEng, 1); ... % each gas-turbine engine sends all power to one propeller/fan
               zeros(NumEng, 1), zeros(             NumEng, NumEng), zeros(NumEng, NumEng),  ones(NumEng, 1); ... % all propellers/fans send their power to the sink
               zeros(     1, 1), zeros(                  1, NumEng), zeros(     1, NumEng), zeros(     1, 1)] ;   % the sink sends no power
           
    % downstream operational matrix
    OperDwn = @() ...
              [zeros(     1, 1), zeros(     1, NumEng), zeros(                  1, NumEng), zeros(     1, 1); ... % the fuel is not powered by anything
                ones(NumEng, 1), zeros(NumEng, NumEng), zeros(             NumEng, NumEng), zeros(NumEng, 1); ... % all gas-turbine engines are powered by fuel
               zeros(NumEng, 1),   eye(NumEng, NumEng), zeros(             NumEng, NumEng), zeros(NumEng, 1); ... % each propeller/fan is powered by a gas-turbine engine
               zeros(     1, 1), zeros(     1, NumEng), repmat(1 / NumEng,      1, NumEng), zeros(     1, 1)] ;   % split the power at the sink equally amongst all propellers/fans
           
    % check the aircraft class
    if (strcmpi(aclass, "Turbofan") == 1)
        
        % get the fan efficiency
        EtaTS = Aircraft.Specs.Propulsion.Engine.EtaPoly.Fan;
        
    elseif ((strcmpi(aclass, "Turboprop") == 1) || ...
            (strcmpi(aclass, "Piston"   ) == 1) )
        
        % get the propeller efficiency
        EtaTS = Aircraft.Specs.Power.Eta.Propeller;
        
    end
           
    % upstream efficiency matrix
    EtaUps = [ones(     1, 1), ones(     1, NumEng), ones(     1, NumEng)                                    , ones(     1, 1); ... % assume gas-turbine engine efficiency of 1 (not used)
              ones(NumEng, 1), ones(NumEng, NumEng), ones(NumEng, NumEng) - eye(NumEng, NumEng) * (1 - EtaTS), ones(NumEng, 1); ... % account for the propeller/fan efficiency
              ones(NumEng, 1), ones(NumEng, NumEng), ones(NumEng, NumEng)                                    , ones(NumEng, 1); ... % no efficiency for the sink
              ones(     1, 1), ones(     1, NumEng), ones(     1, NumEng)                                    , ones(     1, 1)] ;   % no efficiency - end of flow
          
    % downstream efficiency matrix
    EtaDwn = [ones(     1, 1), ones(     1, NumEng)                                    , ones(     1, NumEng), ones(     1, 1); ... % no efficiency for the fuel
              ones(NumEng, 1), ones(NumEng, NumEng)                                    , ones(NumEng, NumEng), ones(NumEng, 1); ... % assume gas-turbine efficiency of 1 (not used)
              ones(NumEng, 1), ones(NumEng, NumEng) - eye(NumEng, NumEng) * (1 - EtaTS), ones(NumEng, NumEng), ones(NumEng, 1); ... % account for the propeller/fan efficiency
              ones(     1, 1), ones(     1, NumEng)                                    , ones(     1, NumEng), ones(     1, 1)] ;   % no efficiency for the sink
        
    % source type (1 = fuel, 0 = battery)
    SrcType = 1;
    
    % transmitter type (1 = engine, 0 = electric motor, 2 = propeller/fan)
    TrnType = [ones(1, NumEng), repmat(2, 1, NumEng)];
        
elseif (strcmpi(ArchName, "E"  ) == 1)
        
    % architecture matrix
    Arch = [zeros(     1, 1),  ones(     1, NumEng), zeros(     1, NumEng), zeros(     1, 1); ... % connect battery to electric motors
            zeros(NumEng, 1), zeros(NumEng, NumEng),   eye(NumEng, NumEng), zeros(NumEng, 1); ... % connect electric motors to propellers/fans
            zeros(NumEng, 1), zeros(NumEng, NumEng), zeros(NumEng, NumEng),  ones(NumEng, 1); ... % connect propellers/fans to the sink
            zeros(     1, 1), zeros(     1, NumEng), zeros(     1, NumEng), zeros(     1, 1)] ;   % the sink connects to nothing
        
    % upstream operational matrix
    OperUps = @() ...
              [zeros(     1, 1), repmat(1 / NumEng,      1, NumEng), zeros(     1, NumEng), zeros(     1, 1); ... % split battery evenly amongst electric motors
               zeros(NumEng, 1), zeros(             NumEng, NumEng),   eye(NumEng, NumEng), zeros(NumEng, 1); ... % each electric motor sends all power to one propeller/fan
               zeros(NumEng, 1), zeros(             NumEng, NumEng), zeros(NumEng, NumEng),  ones(NumEng, 1); ... % all propellers/fans send their power to the sink
               zeros(     1, 1), zeros(                  1, NumEng), zeros(     1, NumEng), zeros(     1, 1)] ;   % the sink sends no power
           
    % downstream operational matrix
    OperDwn = @() ...
              [zeros(     1, 1), zeros(     1, NumEng), zeros(                  1, NumEng), zeros(     1, 1); ... % the battery is not powered by anything
                ones(NumEng, 1), zeros(NumEng, NumEng), zeros(             NumEng, NumEng), zeros(NumEng, 1); ... % all electric motors are powered by battery
               zeros(NumEng, 1),   eye(NumEng, NumEng), zeros(             NumEng, NumEng), zeros(NumEng, 1); ... % each propeller/fan is powered by an electric motor
               zeros(     1, 1), zeros(     1, NumEng), repmat(1 / NumEng,      1, NumEng), zeros(     1, 1)] ;   % split the power at the sink equally amongst all propellers/fans
           
    % check the aircraft class
    if (strcmpi(aclass, "Turbofan") == 1)
        
        % get the fan efficiency
        EtaTS = Aircraft.Specs.Propulsion.Engine.EtaPoly.Fan;
        
    elseif ((strcmpi(aclass, "Turboprop") == 1) || ...
            (strcmpi(aclass, "Piston"   ) == 1) )
        
        % get the propeller efficiency
        EtaTS = Aircraft.Specs.Power.Eta.Propeller;
        
    end
           
    % upstream efficiency matrix
    EtaUps = [ones(     1, 1), repmat(EtaEM,      1, NumEng), ones(     1, NumEng)                                    , ones(     1, 1); ... % account for the electric motor efficiency
              ones(NumEng, 1), ones(         NumEng, NumEng), ones(NumEng, NumEng) - eye(NumEng, NumEng) * (1 - EtaTS), ones(NumEng, 1); ... % account for the propeller/fan efficiency
              ones(NumEng, 1), ones(         NumEng, NumEng), ones(NumEng, NumEng)                                    , ones(NumEng, 1); ... % no efficiency for the sink
              ones(     1, 1), ones(              1, NumEng), ones(     1, NumEng)                                    , ones(     1, 1)] ;   % no efficiency - end of the flow
          
    % downstream efficiency matrix
    EtaDwn = [ones(              1, 1), ones(     1, NumEng)                                    , ones(     1, NumEng), ones(     1, 1); ... % no efficiency for the battery
              repmat(EtaEM, NumEng, 1), ones(NumEng, NumEng)                                    , ones(NumEng, NumEng), ones(NumEng, 1); ... % account for the electric motor efficiency
              ones(         NumEng, 1), ones(NumEng, NumEng) - eye(NumEng, NumEng) * (1 - EtaTS), ones(NumEng, NumEng), ones(NumEng, 1); ... % account for the propeller/fan efficiency
              ones(              1, 1), ones(     1, NumEng)                                    , ones(     1, NumEng), ones(     1, 1)] ;   % no efficiency for the sink
        
    % source type (1 = fuel, 0 = battery)
    SrcType = 0;
    
    % transmitter type (1 = engine, 0 = electric motor, 2 = propeller/fan)
    TrnType = [zeros(1, NumEng), repmat(2, 1, NumEng)];
        
elseif (strcmpi(ArchName, "PHE") == 1)
    
    % architecture matrix
    Arch = [zeros(     1, 1), zeros(     1, 1),  ones(     1, NumEng), zeros(     1, NumEng), zeros(     1, NumEng), zeros(     1, 1); ... % fuel powers the gas-turbine engines
            zeros(     1, 1), zeros(     1, 1), zeros(     1, NumEng),  ones(     1, NumEng), zeros(     1, NumEng), zeros(     1, 1); ... % battery powers the electric motors
            zeros(NumEng, 1), zeros(NumEng, 1), zeros(NumEng, NumEng), zeros(NumEng, NumEng),   eye(NumEng, NumEng), zeros(NumEng, 1); ... % each gas-turbine engine spins a propeller/fan
            zeros(NumEng, 1), zeros(NumEng, 1), zeros(NumEng, NumEng), zeros(NumEng, NumEng),   eye(NumEng, NumEng), zeros(NumEng, 1); ... % each electric motor spins a propeller/fan
            zeros(NumEng, 1), zeros(NumEng, 1), zeros(NumEng, NumEng), zeros(NumEng, NumEng), zeros(NumEng, NumEng),  ones(NumEng, 1); ... % all propellers/fans connect to the sink
            zeros(     1, 1), zeros(     1, 1), zeros(     1, NumEng), zeros(     1, NumEng), zeros(     1, NumEng), zeros(     1, 1)] ;   % the sink does not connect to anything
        
    % upstream power splits
    OperUps = @() ...
              [zeros(     1, 1), zeros(     1, 1), repmat(1 / NumEng,      1, NumEng),  zeros(                 1, NumEng), zeros(     1, NumEng), zeros(     1, 1); ... % fuel powers the gas-turbine engines
               zeros(     1, 1), zeros(     1, 1),  zeros(                 1, NumEng), repmat(1 / NumEng,      1, NumEng), zeros(     1, NumEng), zeros(     1, 1); ... % battery powers the electric motors
               zeros(NumEng, 1), zeros(NumEng, 1),  zeros(            NumEng, NumEng),  zeros(            NumEng, NumEng),   eye(NumEng, NumEng), zeros(NumEng, 1); ... % each gas-turbine engine spins a propeller/fan
               zeros(NumEng, 1), zeros(NumEng, 1),  zeros(            NumEng, NumEng),  zeros(            NumEng, NumEng),   eye(NumEng, NumEng), zeros(NumEng, 1); ... % each electric motor spins a propeller/fan
               zeros(NumEng, 1), zeros(NumEng, 1),  zeros(            NumEng, NumEng),  zeros(            NumEng, NumEng), zeros(NumEng, NumEng),  ones(NumEng, 1); ... % all propellers/fans connect to the sink
               zeros(     1, 1), zeros(     1, 1),  zeros(                 1, NumEng),  zeros(                 1, NumEng), zeros(     1, NumEng), zeros(     1, 1)] ;   % the sink does not connect to anything
           
    % downstream power splits
    OperDwn = @(lam) ...
              [zeros(     1, 1), zeros(     1, 1), zeros(     1, NumEng)            , zeros(     1, NumEng)      , zeros(                  1, NumEng), zeros(     1, 1); ... % the fuel requires nothing
               zeros(     1, 1), zeros(     1, 1), zeros(     1, NumEng)            , zeros(     1, NumEng)      , zeros(                  1, NumEng), zeros(     1, 1); ... % the battery requires nothing
                ones(NumEng, 1), zeros(NumEng, 1), zeros(NumEng, NumEng)            , zeros(NumEng, NumEng)      , zeros(             NumEng, NumEng), zeros(NumEng, 1); ... % the gas-turbine engines are powered by the fuel
               zeros(NumEng, 1),  ones(NumEng, 1), zeros(NumEng, NumEng)            , zeros(NumEng, NumEng)      , zeros(             NumEng, NumEng), zeros(NumEng, 1); ... % the electric motors are powered by the battery
               zeros(NumEng, 1), zeros(NumEng, 1),   eye(NumEng, NumEng) * (1 - lam),   eye(NumEng, NumEng) * lam, zeros(             NumEng, NumEng), zeros(NumEng, 1); ... % the propeller/fan power is split between the gas-turbine engines and electric motors
               zeros(     1, 1), zeros(     1, 1), zeros(     1, NumEng)            , zeros(     1, NumEng)      , repmat(1 / NumEng,      1, NumEng), zeros(     1, 1)] ;   % the sink power is split evenly between the propellers/fans
           
    % check the aircraft class
    if (strcmpi(aclass, "Turbofan") == 1)
        
        % get the fan efficiency
        EtaTS = Aircraft.Specs.Propulsion.Engine.EtaPoly.Fan;
        
    elseif ((strcmpi(aclass, "Turboprop") == 1) || ...
            (strcmpi(aclass, "Piston"   ) == 1) )
        
        % get the propeller efficiency
        EtaTS = Aircraft.Specs.Power.Eta.Propeller;
        
    end
           
    % upstream efficiency matrix
    EtaUps = [ones(     1, 1), ones(     1, 1), ones(     1, NumEng), ones(              1, NumEng), ones(1     , NumEng)                                    , ones(     1, 1); ... % assume gas-turbine engine efficiency of 1 (not used)
              ones(     1, 1), ones(     1, 1), ones(     1, NumEng), repmat(EtaEM,      1, NumEng), ones(1     , NumEng)                                    , ones(     1, 1); ... % account for electric motor efficiency
              ones(NumEng, 1), ones(NumEng, 1), ones(NumEng, NumEng), ones(         NumEng, NumEng), ones(NumEng, NumEng) - eye(NumEng, NumEng) * (1 - EtaTS), ones(NumEng, 1); ... % account for propeller/fan efficiency
              ones(NumEng, 1), ones(NumEng, 1), ones(NumEng, NumEng), ones(         NumEng, NumEng), ones(NumEng, NumEng) - eye(NumEng, NumEng) * (1 - EtaTS), ones(NumEng, 1); ... % account for propeller/fan efficiency
              ones(NumEng, 1), ones(NumEng, 1), ones(NumEng, NumEng), ones(         NumEng, NumEng), ones(NumEng, NumEng)                                    , ones(NumEng, 1); ... % no efficiency for the sink
              ones(     1, 1), ones(     1, 1), ones(     1, NumEng), ones(              1, NumEng), ones(1     , NumEng)                                    , ones(     1, 1)] ;   % no efficiency - end of the flow
    
    % downstream efficiency matrix
    EtaDwn = [ones(     1, 1), ones(              1, 1), ones(     1, NumEng)                                    , ones(     1, NumEng)                                    , ones(     1, NumEng), ones(     1, 1); ... % no efficiency for the fuel
              ones(     1, 1), ones(              1, 1), ones(     1, NumEng)                                    , ones(     1, NumEng)                                    , ones(     1, NumEng), ones(     1, 1); ... % no efficiency for the battery
              ones(NumEng, 1), ones(         NumEng, 1), ones(NumEng, NumEng)                                    , ones(NumEng, NumEng)                                    , ones(NumEng, NumEng), ones(NumEng, 1); ... % assume gas-turbine engine efficiency of 1 (not used)
              ones(NumEng, 1), repmat(EtaEM, NumEng, 1), ones(NumEng, NumEng)                                    , ones(NumEng, NumEng)                                    , ones(NumEng, NumEng), ones(NumEng, 1); ... % account for the electric motor efficiency
              ones(NumEng, 1), ones(         NumEng, 1), ones(NumEng, NumEng) - eye(NumEng, NumEng) * (1 - EtaTS), ones(NumEng, NumEng) - eye(NumEng, NumEng) * (1 - EtaTS), ones(NumEng, NumEng), ones(NumEng, 1); ... % account for the propeller/fan efficiency
              ones(     1, 1), ones(              1, 1), ones(     1, NumEng)                                    , ones(     1, NumEng)                                    , ones(     1, NumEng), ones(     1, 1)] ;   % no efficiency for the sink
    
    % source type (1 = fuel, 0 = battery)
    SrcType = [1, 0];
    
    % transmitter type (1 = engine, 0 = electric motor, 2 = propeller/fan)
    TrnType = [ones(1, NumEng), zeros(1, NumEng), repmat(2, 1, NumEng)];
    
elseif (strcmpi(ArchName, "SHE") == 1)
    
    % architecture matrix
    Arch = [zeros(     1, 1), zeros(     1, 1),  ones(     1, NumEng), zeros(     1, NumEng), zeros(     1, NumEng), zeros(     1, NumEng), zeros(     1, 1); ... % fuel powers the gas-turbine engines
            zeros(     1, 1), zeros(     1, 1), zeros(     1, NumEng), zeros(     1, NumEng),  ones(     1, NumEng), zeros(     1, NumEng), zeros(     1, 1); ... % battery powers the electric motors
            zeros(NumEng, 1), zeros(NumEng, 1), zeros(NumEng, NumEng),   eye(NumEng, NumEng), zeros(NumEng, NumEng), zeros(NumEng, NumEng), zeros(NumEng, 1); ... % gas-turbine engines power the electric generators
            zeros(NumEng, 1), zeros(NumEng, 1), zeros(NumEng, NumEng), zeros(NumEng, NumEng),   eye(NumEng, NumEng), zeros(NumEng, NumEng), zeros(NumEng, 1); ... % electric generators power the electric motors
            zeros(NumEng, 1), zeros(NumEng, 1), zeros(NumEng, NumEng), zeros(NumEng, NumEng), zeros(NumEng, NumEng),   eye(NumEng, NumEng), zeros(NumEng, 1); ... % electric motors spin the propellers/fans
            zeros(NumEng, 1), zeros(NumEng, 1), zeros(NumEng, NumEng), zeros(NumEng, NumEng), zeros(NumEng, NumEng), zeros(NumEng, NumEng),  ones(NumEng, 1); ... % propellers/fans connect to the sink
            zeros(     1, 1), zeros(     1, 1), zeros(     1, NumEng), zeros(     1, NumEng), zeros(     1, NumEng), zeros(     1, NumEng), zeros(     1, 1)] ;   % the sink powers nothing
            
        
    % upstream power splits
    OperUps = @() ...
              [zeros(     1, 1), zeros(     1, 1), repmat(1 / NumEng,      1, NumEng), zeros(     1, NumEng),  zeros(                 1, NumEng), zeros(     1, NumEng), zeros(     1, 1); ... % fuel splits its power evenly amongst the gas-turbine engines
               zeros(     1, 1), zeros(     1, 1),  zeros(                 1, NumEng), zeros(     1, NumEng), repmat(1 / NumEng,      1, NumEng), zeros(     1, NumEng), zeros(     1, 1); ... % battery splits its power evenly amongst the electric motors
               zeros(NumEng, 1), zeros(NumEng, 1),  zeros(            NumEng, NumEng),   eye(NumEng, NumEng),  zeros(            NumEng, NumEng), zeros(NumEng, NumEng), zeros(NumEng, 1); ... % gas-turbine engines each power an electric generator
               zeros(NumEng, 1), zeros(NumEng, 1),  zeros(            NumEng, NumEng), zeros(NumEng, NumEng),    eye(            NumEng, NumEng), zeros(NumEng, NumEng), zeros(NumEng, 1); ... % electric generators each power an electric motor
               zeros(NumEng, 1), zeros(NumEng, 1),  zeros(            NumEng, NumEng), zeros(NumEng, NumEng),  zeros(            NumEng, NumEng),   eye(NumEng, NumEng), zeros(NumEng, 1); ... % electric motors each power a propeller/fan
               zeros(NumEng, 1), zeros(NumEng, 1),  zeros(            NumEng, NumEng), zeros(NumEng, NumEng),  zeros(            NumEng, NumEng), zeros(NumEng, NumEng),  ones(NumEng, 1); ... % propellers/fans send all their power to the sink
               zeros(     1, 1), zeros(     1, 1),  zeros(                 1, NumEng), zeros(     1, NumEng),  zeros(                 1, NumEng), zeros(     1, NumEng), zeros(     1, 1)] ;   % the sink sends no power
           
    % downstream power splits
    OperDwn = @(lam) ...
              [zeros(     1, 1),  zeros(          1, 1), zeros(     1, NumEng), zeros(     1, NumEng)            , zeros(     1, NumEng),  zeros(                 1, NumEng), zeros(     1, 1); ... % fuel requires no power
               zeros(     1, 1),  zeros(          1, 1), zeros(     1, NumEng), zeros(     1, NumEng)            , zeros(     1, NumEng),  zeros(                 1, NumEng), zeros(     1, 1); ... % battery requires no power
                ones(NumEng, 1),  zeros(     NumEng, 1), zeros(NumEng, NumEng), zeros(NumEng, NumEng)            , zeros(NumEng, NumEng),  zeros(            NumEng, NumEng), zeros(NumEng, 1); ... % gas-turbine engines require fuel
               zeros(NumEng, 1),  zeros(     NumEng, 1),   eye(NumEng, NumEng), zeros(NumEng, NumEng)            , zeros(NumEng, NumEng),  zeros(            NumEng, NumEng), zeros(NumEng, 1); ... % electric generators require gas-turbine engines
               zeros(NumEng, 1), repmat(lam, NumEng, 1), zeros(NumEng, NumEng),   eye(NumEng, NumEng) * (1 - lam), zeros(NumEng, NumEng),  zeros(            NumEng, NumEng), zeros(NumEng, 1); ... % electric motors require battery and the electric generators
               zeros(NumEng, 1),  zeros(     NumEng, 1), zeros(NumEng, NumEng), zeros(NumEng, NumEng)            ,   eye(NumEng, NumEng),  zeros(            NumEng, NumEng), zeros(NumEng, 1); ... % propellers/fans require the electric motors
               zeros(     1, 1),  zeros(          1, 1), zeros(     1, NumEng), zeros(     1, NumEng)            , zeros(     1, NumEng), repmat(1 / NumEng,      1, NumEng), zeros(     1, 1)] ;   % the sink requires the propellers/fans
           
    % check the aircraft class
    if (strcmpi(aclass, "Turbofan") == 1)
        
        % get the fan efficiency
        EtaTS = Aircraft.Specs.Propulsion.Engine.EtaPoly.Fan;
        
    elseif ((strcmpi(aclass, "Turboprop") == 1) || ...
            (strcmpi(aclass, "Piston"   ) == 1) )
        
        % get the propeller efficiency
        EtaTS = Aircraft.Specs.Power.Eta.Propeller;
        
    end
           
    % upstream efficiency matrix
    EtaUps = [ones(     1, 1), ones(     1, 1), ones(     1, NumEng), ones(     1, NumEng)                                    ,   ones(            1, NumEng)                                    , ones(     1, NumEng)                                    , ones(     1, 1); ... % assume a gas-turbine efficiency of 1 (not used)
              ones(     1, 1), ones(     1, 1), ones(     1, NumEng), ones(     1, NumEng)                                    , repmat(EtaEM,      1, NumEng)                                    , ones(     1, NumEng)                                    , ones(     1, 1); ... % account for the electric motor efficiency
              ones(NumEng, 1), ones(NumEng, 1), ones(NumEng, NumEng), ones(NumEng, NumEng) - eye(NumEng, NumEng) * (1 - EtaEG),   ones(       NumEng, NumEng)                                    , ones(NumEng, NumEng)                                    , ones(NumEng, 1); ... % account for the electric generator efficiency
              ones(NumEng, 1), ones(NumEng, 1), ones(NumEng, NumEng), ones(NumEng, NumEng)                                    ,   ones(       NumEng, NumEng) - eye(NumEng, NumEng) * (1 - EtaEM), ones(NumEng, NumEng)                                    , ones(NumEng, 1); ... % account for the electric motor efficiency
              ones(NumEng, 1), ones(NumEng, 1), ones(NumEng, NumEng), ones(NumEng, NumEng)                                    ,   ones(       NumEng, NumEng)                                    , ones(NumEng, NumEng) - eye(NumEng, NumEng) * (1 - EtaTS), ones(NumEng, 1); ... % account for the propeller/fan efficiency
              ones(NumEng, 1), ones(NumEng, 1), ones(NumEng, NumEng), ones(NumEng, NumEng)                                    ,   ones(       NumEng, NumEng)                                    , ones(NumEng, NumEng)                                    , ones(NumEng, 1); ... % no efficiencies for the sink
              ones(     1, 1), ones(     1, 1), ones(     1, NumEng), ones(     1, NumEng)                                    ,   ones(            1, NumEng)                                    , ones(     1, NumEng)                                    , ones(     1, 1)] ;   % no efficiencies - end of the flow
        
    % downstream efficiency matrix
    EtaDwn = [ones(     1, 1),   ones(            1, 1), ones(     1, NumEng)                                    , ones(     1, NumEng)                                    , ones(     1, NumEng)                                    , ones(     1, NumEng), ones(     1, 1); ... % no efficiency for fuel
              ones(     1, 1),   ones(            1, 1), ones(     1, NumEng)                                    , ones(     1, NumEng)                                    , ones(     1, NumEng)                                    , ones(     1, NumEng), ones(     1, 1); ... % no efficiency for battery
              ones(NumEng, 1),   ones(       NumEng, 1), ones(NumEng, NumEng)                                    , ones(NumEng, NumEng)                                    , ones(NumEng, NumEng)                                    , ones(NumEng, NumEng), ones(NumEng, 1); ... % assume a gas-turbine engine efficiency of 1 (not used)
              ones(NumEng, 1),   ones(       NumEng, 1), ones(NumEng, NumEng) - eye(NumEng, NumEng) * (1 - EtaEG), ones(NumEng, NumEng)                                    , ones(NumEng, NumEng)                                    , ones(NumEng, NumEng), ones(NumEng, 1); ... % account for the electric generator efficiency
              ones(NumEng, 1), repmat(EtaEM, NumEng, 1), ones(NumEng, NumEng)                                    , ones(NumEng, NumEng) - eye(NumEng, NumEng) * (1 - EtaEM), ones(NumEng, NumEng)                                    , ones(NumEng, NumEng), ones(NumEng, 1); ... % account for the electric motor efficiency
              ones(NumEng, 1),   ones(       NumEng, 1), ones(NumEng, NumEng)                                    , ones(NumEng, NumEng)                                    , ones(NumEng, NumEng) - eye(NumEng, NumEng) * (1 - EtaTS), ones(NumEng, NumEng), ones(NumEng, 1); ... % account for the propeller/fan efficiency
              ones(     1, 1),   ones(            1, 1), ones(     1, NumEng)                                    , ones(     1, NumEng)                                    , ones(     1, NumEng)                                    , ones(     1, NumEng), ones(     1, 1)] ;   % no efficiency for the sink
    
    % source type (1 = fuel, 0 = battery)
    SrcType = [1, 0];
    
    % transmitter type (1 = engine, 0 = electric motor, 2 = propeller/fan)
    TrnType = [ones(1, NumEng), zeros(1, NumEng), repmat(3, 1, NumEng), repmat(2, 1, NumEng)];
    
elseif (strcmpi(ArchName, "TE" ) == 1)
    
    % architecture matrix
    Arch = [zeros(     1, 1),  ones(     1, NumEng), zeros(     1, NumEng), zeros(     1, NumEng), zeros(     1, NumEng), zeros(     1, 1); ... % fuel powers the gas-turbine engines
            zeros(NumEng, 1), zeros(NumEng, NumEng),   eye(NumEng, NumEng), zeros(NumEng, NumEng), zeros(NumEng, NumEng), zeros(NumEng, 1); ... % gas-turbine engines power the electic generators
            zeros(NumEng, 1), zeros(NumEng, NumEng), zeros(NumEng, NumEng),   eye(NumEng, NumEng), zeros(NumEng, NumEng), zeros(NumEng, 1); ... % electric generators power the electric motors
            zeros(NumEng, 1), zeros(NumEng, NumEng), zeros(NumEng, NumEng), zeros(NumEng, NumEng),   eye(NumEng, NumEng), zeros(NumEng, 1); ... % electric motors power the propellers/fans
            zeros(NumEng, 1), zeros(NumEng, NumEng), zeros(NumEng, NumEng), zeros(NumEng, NumEng), zeros(NumEng, NumEng),  ones(NumEng, 1); ... % propellers/fans connect to the sink
            zeros(     1, 1), zeros(     1, NumEng), zeros(     1, NumEng), zeros(     1, NumEng), zeros(     1, NumEng), zeros(     1, 1)] ;   % the sink connects to nothing
        
    % upstream power splits
    OperUps = @() ...
              [zeros(     1, 1), repmat(1 / NumEng,      1, NumEng), zeros(     1, NumEng), zeros(     1, NumEng), zeros(     1, NumEng), zeros(     1, 1); ... % fuel sends all its power to the gas-turbine engines
               zeros(NumEng, 1),  zeros(            NumEng, NumEng),   eye(NumEng, NumEng), zeros(NumEng, NumEng), zeros(NumEng, NumEng), zeros(NumEng, 1); ... % gas-turbine engines send all their power to the electic generators
               zeros(NumEng, 1),  zeros(            NumEng, NumEng), zeros(NumEng, NumEng),   eye(NumEng, NumEng), zeros(NumEng, NumEng), zeros(NumEng, 1); ... % electric generators send all their power to the electric motors
               zeros(NumEng, 1),  zeros(            NumEng, NumEng), zeros(NumEng, NumEng), zeros(NumEng, NumEng),   eye(NumEng, NumEng), zeros(NumEng, 1); ... % electric motors send all their power to the propellers/fans
               zeros(NumEng, 1),  zeros(            NumEng, NumEng), zeros(NumEng, NumEng), zeros(NumEng, NumEng), zeros(NumEng, NumEng),  ones(NumEng, 1); ... % propellers/fans send all their power to the sink
               zeros(     1, 1),  zeros(                 1, NumEng), zeros(     1, NumEng), zeros(     1, NumEng), zeros(     1, NumEng), zeros(     1, 1)] ;   % the sink powers nothing
           
    % downstream power splits
    OperDwn = @() ...
              [zeros(     1, 1), zeros(     1, NumEng), zeros(     1, NumEng), zeros(     1, NumEng), zeros(                  1, NumEng), zeros(     1, 1); ... % fuel requires no power
                ones(NumEng, 1), zeros(NumEng, NumEng), zeros(NumEng, NumEng), zeros(NumEng, NumEng), zeros(             NumEng, NumEng), zeros(NumEng, 1); ... % gas-turbine engines require fuel
               zeros(NumEng, 1),   eye(NumEng, NumEng), zeros(NumEng, NumEng), zeros(NumEng, NumEng), zeros(             NumEng, NumEng), zeros(NumEng, 1); ... % electric generators require the gas-turbine engines
               zeros(NumEng, 1), zeros(NumEng, NumEng),   eye(NumEng, NumEng), zeros(NumEng, NumEng), zeros(             NumEng, NumEng), zeros(NumEng, 1); ... % electric motors require the electric generators
               zeros(NumEng, 1), zeros(NumEng, NumEng), zeros(NumEng, NumEng),   eye(NumEng, NumEng), zeros(             NumEng, NumEng), zeros(NumEng, 1); ... % propellers/fans require the electric motors
               zeros(     1, 1), zeros(     1, NumEng), zeros(     1, NumEng), zeros(     1, NumEng), repmat(1 / NumEng,      1, NumEng), zeros(     1, 1)] ;   % the sink requires the propellers/fans
    
    % check the aircraft class
    if (strcmpi(aclass, "Turbofan") == 1)
        
        % get the fan efficiency
        EtaTS = Aircraft.Specs.Propulsion.Engine.EtaPoly.Fan;
        
    elseif ((strcmpi(aclass, "Turboprop") == 1) || ...
            (strcmpi(aclass, "Piston"   ) == 1) )
        
        % get the propeller efficiency
        EtaTS = Aircraft.Specs.Power.Eta.Propeller;
        
    end
           
    % upstream efficiency matrix
    EtaUps = [ones(     1, 1), ones(     1, NumEng), ones(     1, NumEng)                                    , ones(     1, NumEng)                                   , ones(     1, NumEng)                                    , ones(     1, 1); ... % assume perfect efficiency for gas-turbine engines (not used)
              ones(NumEng, 1), ones(NumEng, NumEng), ones(NumEng, NumEng) - eye(NumEng, NumEng) * (1 - EtaEG), ones(NumEng, NumEng)                                   , ones(NumEng, NumEng)                                    , ones(NumEng, 1); ... % account for the electric generator efficiency
              ones(NumEng, 1), ones(NumEng, NumEng), ones(NumEng, NumEng)                                    , ones(NumEng, NumEng) - eye(NumEng, NumEng) * (1- EtaEM), ones(NumEng, NumEng)                                    , ones(NumEng, 1); ... % account for the electric motor efficiency
              ones(NumEng, 1), ones(NumEng, NumEng), ones(NumEng, NumEng)                                    , ones(NumEng, NumEng)                                   , ones(NumEng, NumEng) - eye(NumEng, NumEng) * (1 - EtaTS), ones(NumEng, 1); ... % account for the propeller/fan efficiency
              ones(NumEng, 1), ones(NumEng, NumEng), ones(NumEng, NumEng)                                    , ones(NumEng, NumEng)                                   , ones(NumEng, NumEng)                                    , ones(NumEng, 1); ... % no efficiency for the sink
              ones(     1, 1), ones(     1, NumEng), ones(     1, NumEng)                                    , ones(     1, NumEng)                                   , ones(     1, NumEng)                                    , ones(     1, 1)] ;   % no efficiency - end of the flow
    
    % downstream efficiency matrix
    EtaDwn = [ones(     1, 1), ones(     1, NumEng)                                    , ones(     1, NumEng)                                    , ones(     1, NumEng)                                    , ones(     1, NumEng), ones(     1, 1); ... % no efficiency for fuel
              ones(NumEng, 1), ones(NumEng, NumEng)                                    , ones(NumEng, NumEng)                                    , ones(NumEng, NumEng)                                    , ones(NumEng, NumEng), ones(NumEng, 1); ... % assume perfect efficiency for gas-turbine engines (not used)
              ones(NumEng, 1), ones(NumEng, NumEng) - eye(NumEng, NumEng) * (1 - EtaEG), ones(NumEng, NumEng)                                    , ones(NumEng, NumEng)                                    , ones(NumEng, NumEng), ones(NumEng, 1); ... % account for the electric generator efficiency
              ones(NumEng, 1), ones(NumEng, NumEng)                                    , ones(NumEng, NumEng) - eye(NumEng, NumEng) * (1 - EtaEM), ones(NumEng, NumEng)                                    , ones(NumEng, NumEng), ones(NumEng, 1); ... % account for the electric motor efficiency
              ones(NumEng, 1), ones(NumEng, NumEng)                                    , ones(NumEng, NumEng)                                    , ones(NumEng, NumEng) - eye(NumEng, NumEng) * (1 - EtaTS), ones(NumEng, NumEng), ones(NumEng, 1); ... % account for the propeller/fan efficiency
              ones(     1, 1), ones(     1, NumEng)                                    , ones(     1, NumEng)                                    , ones(     1, NumEng)                                    , ones(     1, NumEng), ones(     1, 1)] ;   % no efficiency for the sink
    
    % source type (1 = fuel, 0 = battery)
    SrcType = 1;
    
    % transmitter type (1 = engine, 0 = electric motor, 2 = propeller/fan)
    TrnType = [ones(1, NumEng), repmat(3, 1, NumEng), zeros(1, NumEng), repmat(2, 1, NumEng)];
    
elseif (strcmpi(ArchName, "PE" ) == 1)
    
    % architecture matrix
    Arch = [zeros(       1, 1),  ones(       1, NumEng), zeros(       1, NumEng), zeros(       1, NumEng), zeros(       1, NumEng), zeros(       1, NumEng), zeros(       1, 1); ... % fuel powers the gas-turbine engines
            zeros(  NumEng, 1), zeros(  NumEng, NumEng),   eye(  NumEng, NumEng), zeros(  NumEng, NumEng), zeros(  NumEng, NumEng),   eye(  NumEng, NumEng), zeros(  NumEng, 1); ... % gas-turbine engines power the electric generators and "outboard" propellers/fans
            zeros(  NumEng, 1), zeros(  NumEng, NumEng), zeros(  NumEng, NumEng),   eye(  NumEng, NumEng), zeros(  NumEng, NumEng), zeros(  NumEng, NumEng), zeros(  NumEng, 1); ... % electric generators power the electric motors
            zeros(  NumEng, 1), zeros(  NumEng, NumEng), zeros(  NumEng, NumEng), zeros(  NumEng, NumEng),   eye(  NumEng, NumEng), zeros(  NumEng, NumEng), zeros(  NumEng, 1); ... % electric motors power the "inboard" propellers/fans
            zeros(2*NumEng, 1), zeros(2*NumEng, NumEng), zeros(2*NumEng, NumEng), zeros(2*NumEng, NumEng), zeros(2*NumEng, NumEng), zeros(2*NumEng, NumEng),  ones(2*NumEng, 1); ... % propellers/fans power the sink
            zeros(       1, 1), zeros(       1, NumEng), zeros(       1, NumEng), zeros(       1, NumEng), zeros(       1, NumEng), zeros(       1, NumEng), zeros(       1, 1)] ;   % the sink powers nothing
        
    % upstream power splits
    OperUps = @(lam) ...
              [zeros(       1, 1), repmat(1 / NumEng,        1, NumEng), zeros(       1, NumEng)            , zeros(       1, NumEng), zeros(       1, NumEng), zeros(       1, NumEng)      , zeros(       1, 1); ... % fuel powers the gas-turbine engines
               zeros(  NumEng, 1), zeros(               NumEng, NumEng),   eye(  NumEng, NumEng) * (1 - lam), zeros(  NumEng, NumEng), zeros(  NumEng, NumEng),   eye(  NumEng, NumEng) * lam, zeros(  NumEng, 1); ... % gas-turbine engines power the electric generators and "outboard" propellers/fans
               zeros(  NumEng, 1), zeros(               NumEng, NumEng), zeros(  NumEng, NumEng)            ,   eye(  NumEng, NumEng), zeros(  NumEng, NumEng), zeros(  NumEng, NumEng)      , zeros(  NumEng, 1); ... % electric generators power the electric motors
               zeros(  NumEng, 1), zeros(               NumEng, NumEng), zeros(  NumEng, NumEng)            , zeros(  NumEng, NumEng),   eye(  NumEng, NumEng), zeros(  NumEng, NumEng)      , zeros(  NumEng, 1); ... % electric motors power the "inboard" propellers/fans
               zeros(2*NumEng, 1), zeros(             2*NumEng, NumEng), zeros(2*NumEng, NumEng)            , zeros(2*NumEng, NumEng), zeros(2*NumEng, NumEng), zeros(2*NumEng, NumEng)      ,  ones(2*NumEng, 1); ... % propellers/fans power the sink
               zeros(       1, 1), zeros(                    1, NumEng), zeros(       1, NumEng)            , zeros(       1, NumEng), zeros(       1, NumEng), zeros(       1, NumEng)      , zeros(       1, 1)] ;   % the sink powers nothing
           
    % downstream power splits
    OperDwn = @(lam) ...
              [zeros(     1, 1), zeros(     1, NumEng), zeros(     1, NumEng), zeros(     1, NumEng), zeros(                          1, NumEng), zeros(                    1, NumEng), zeros(     1, 1); ... % fuel requires nothing
                ones(NumEng, 1), zeros(NumEng, NumEng), zeros(NumEng, NumEng), zeros(NumEng, NumEng), zeros(                     NumEng, NumEng), zeros(               NumEng, NumEng), zeros(NumEng, 1); ... % gas-turbine engines reuqire fuel
               zeros(NumEng, 1),   eye(NumEng, NumEng), zeros(NumEng, NumEng), zeros(NumEng, NumEng), zeros(                     NumEng, NumEng), zeros(               NumEng, NumEng), zeros(NumEng, 1); ... % electric generators require gas-turbine engines
               zeros(NumEng, 1), zeros(NumEng, NumEng),   eye(NumEng, NumEng), zeros(NumEng, NumEng), zeros(                     NumEng, NumEng), zeros(               NumEng, NumEng), zeros(NumEng, 1); ... % electric motors require electric generators
               zeros(NumEng, 1), zeros(NumEng, NumEng), zeros(NumEng, NumEng),   eye(NumEng, NumEng), zeros(                     NumEng, NumEng), zeros(               NumEng, NumEng), zeros(NumEng, 1); ... % "inboard" propellers/fans require electric motors
               zeros(NumEng, 1),   eye(NumEng, NumEng), zeros(NumEng, NumEng), zeros(NumEng, NumEng), zeros(                     NumEng, NumEng), zeros(               NumEng, NumEng), zeros(NumEng, 1); ... % "outboard" propellers/fans require gas-turbine engines
               zeros(     1, 1), zeros(     1, NumEng), zeros(     1, NumEng), zeros(     1, NumEng), repmat((1 - lam) / NumEng,      1, NumEng), repmat(lam / NumEng,      1, NumEng), zeros(     1, 1)] ;   % sinks require all propellers
           
    % check the aircraft class
    if (strcmpi(aclass, "Turbofan") == 1)
        
        % get the fan efficiency
        EtaTS = Aircraft.Specs.Propulsion.Engine.EtaPoly.Fan;
        
    elseif ((strcmpi(aclass, "Turboprop") == 1) || ...
            (strcmpi(aclass, "Piston"   ) == 1) )
        
        % get the propeller efficiency
        EtaTS = Aircraft.Specs.Power.Eta.Propeller;
        
    end
           
    % upstream efficiency matrix
    EtaUps = [ones(       1, 1), ones(       1, NumEng), ones(       1, NumEng)                                    , ones(       1, NumEng)                                    , ones(       1, NumEng)                                    , ones(       1, NumEng)                                    , ones(       1, 1); ... % assume perfect efficiency for gas-turbine engines (not used)
              ones(  NumEng, 1), ones(  NumEng, NumEng), ones(  NumEng, NumEng) - eye(NumEng, NumEng) * (1 - EtaEG), ones(  NumEng, NumEng)                                    , ones(  NumEng, NumEng)                                    , ones(  NumEng, NumEng) - eye(NumEng, NumEng) * (1 - EtaTS), ones(  NumEng, 1); ... % account for the electric generator efficiency ("inboard") and propeller/fan efficiency ("outboard")
              ones(  NumEng, 1), ones(  NumEng, NumEng), ones(  NumEng, NumEng)                                    , ones(  NumEng, NumEng) - eye(NumEng, NumEng) * (1 - EtaEM), ones(  NumEng, NumEng)                                    , ones(  NumEng, NumEng)                                    , ones(  NumEng, 1); ... % account for electric motor efficiency
              ones(  NumEng, 1), ones(  NumEng, NumEng), ones(  NumEng, NumEng)                                    , ones(  NumEng, NumEng)                                    , ones(  NumEng, NumEng) - eye(NumEng, NumEng) * (1 - EtaTS), ones(  NumEng, NumEng)                                    , ones(  NumEng, 1); ... % account for the "inboard" propeller/fan efficiency
              ones(2*NumEng, 1), ones(2*NumEng, NumEng), ones(2*NumEng, NumEng)                                    , ones(2*NumEng, NumEng)                                    , ones(2*NumEng, NumEng)                                    , ones(2*NumEng, NumEng)                                    , ones(2*NumEng, 1); ... % no efficiency for the sink
              ones(       1, 1), ones(       1, NumEng), ones(       1, NumEng)                                    , ones(       1, NumEng)                                    , ones(       1, NumEng)                                    , ones(       1, NumEng)                                    , ones(       1, 1)] ;   % no efficiency - end of the flow
        
    % downstream efficiency matrix
    EtaDwn = [ones(     1, 1), ones(     1, NumEng)                                    , ones(     1, NumEng)                                    , ones(     1, NumEng)                                    , ones(     1, 2*NumEng), ones(     1, 1); ... % no efficiency for fuel
              ones(NumEng, 1), ones(NumEng, NumEng)                                    , ones(NumEng, NumEng)                                    , ones(NumEng, NumEng)                                    , ones(NumEng, 2*NumEng), ones(NumEng, 1); ... % assume perfect efficiency for gas-turbine engines (not used)
              ones(NumEng, 1), ones(NumEng, NumEng) - eye(NumEng, NumEng) * (1 - EtaEG), ones(NumEng, NumEng)                                    , ones(NumEng, NumEng)                                    , ones(NumEng, 2*NumEng), ones(NumEng, 1); ... % account for the electric generator efficiency
              ones(NumEng, 1), ones(NumEng, NumEng)                                    , ones(NumEng, NumEng) - eye(NumEng, NumEng) * (1 - EtaEM), ones(NumEng, NumEng)                                    , ones(NumEng, 2*NumEng), ones(NumEng, 1); ... % account for the electric motor efficiency
              ones(NumEng, 1), ones(NumEng, NumEng)                                    , ones(NumEng, NumEng)                                    , ones(NumEng, NumEng) - eye(NumEng, NumEng) * (1 - EtaTS), ones(NumEng, 2*NumEng), ones(NumEng, 1); ... % account for the  "inboard" propeller/fan efficiency
              ones(NumEng, 1), ones(NumEng, NumEng) - eye(NumEng, NumEng) * (1 - EtaTS), ones(NumEng, NumEng)                                    , ones(NumEng, NumEng)                                    , ones(NumEng, 2*NumEng), ones(NumEng, 1); ... % account for the "outboard" propeller/fan efficiency
              ones(     1, 1), ones(     1, NumEng)                                    , ones(     1, NumEng)                                    , ones(     1, NumEng)                                    , ones(     1, 2*NumEng), ones(     1, 1)] ;   % no efficiency for the sink
    
    % source type (1 = fuel, 0 = battery)
    SrcType = 1;
    
    % transmitter type (1 = engine, 0 = electric motor, 2 = propeller/fan, 3 = electric generator)
    TrnType = [ones(1, NumEng), repmat(3, 1, NumEng), zeros(1, NumEng), repmat(2, 1, 2*NumEng)];
    
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
    HaveOper = isfield(Specs.Propulsion.PropArch, ["OperUps"; "OperDwn"]);
    
    % confirm that they're all present
    if (sum(HaveOper) ~= 2)
        error("ERROR - CreatePropArch: check that 'OperUps' and 'OperDwn' in 'Specs.Propulsion.PropArch' are initialized.");
    end
    
    % check for the efficiencies
    HaveEtas = isfield(Specs.Propulsion.PropArch, ["EtaUps"; "EtaDwn"]);
    
    % confirm that they're all present
    if (HaveEtas ~= 1)
        error("ERROR - CreatePropArch: check that 'EtaUps' and 'EtaDwn' in 'Specs.Propulsion.PropArch' are initialized.");
    end
    
    % check for the component types
    HaveType = isfield(Specs.Propulsion.PropArch, ["SrcType", "TrnType"]);
    
    % confirm that they're all present
    if (sum(HaveType) ~= 2)
        error("ERROR - CreatePropArch: check that 'PropArch.SrcType' and 'PropArch.TrnType' in 'Specs.Propulsion.PropArch' are initialized.");
    end
    
    % get number of arguments for each (potential) split
    Aircraft.Settings.nargOperUps = nargin(Aircraft.Specs.Propulsion.OperUps);
    Aircraft.Settings.nargOperDwn = nargin(Aircraft.Specs.Propulsion.OperDwn);
    
    % ------------------------------------------------------
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %                            %
    % get the matrices           %
    %                            %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % get the propulsion architecture
    Arch = Specs.Propulsion.PropArch.Arch;
    
    % get the operational matrices
    OperUps = Specs.Propulsion.PropArch.OperUps;
    OperDwn = Specs.Propulsion.PropArch.OperDwn;
    
    % get the efficiency matrices
    EtaUps = Specs.Propulsion.PropArch.EtaUps;
    EtaDwn = Specs.Propulsion.PropArch.EtaDwn;
    
    % get the ES and PT types
    SrcType = Specs.Propulsion.PropArch.SrcType;
    TrnType = Specs.Propulsion.PropArch.TrnType;
    
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
    [nrow, ncol] = size(OperDwn);
    
    % check for the same number of rows/columns in the downstream matrix
    if (nrow ~= ncol)
        
        % throw an error
        error("ERROR - CreatePropArch: the downstream operational matrix must be square.");
        
    end
    
    % get the size of the upstream matrix
    [nrow, ncol] = size(OperUps);
    
    % check for the same number of rows/columns in the upstream matrix
    if (nrow ~= ncol)
        
        % throw an error
        error("ERROR - CreatePropArch: the upstream operational matrix must be square.");
        
    end
    
    % get the size of the upstream efficiency matrix
    [nrow, ncol] = size(EtaUps);
    
    % check for the same number of rows/columns
    if (nrow ~= ncol)
        
        % throw an error
        error("ERROR - CreatePropArch: the upstream efficiency matrix must be square.");
        
    end
    
    % get the size of the downstream efficiency matrix
    [nrow, ncol] = size(EtaDwn);
    
    % check for the same number of rows/columns
    if (nrow ~= ncol)
        
        % throw an error
        error("ERROR - CreatePropArch: the downstream efficiency matrix must be square.");
        
    end
    
    % ------------------------------------------------------
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %                            %
    % check for the correct      %
    % number of sources,         %
    % transmitters, and sinks    %
    %                            %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % number of energy sources
    nsrc = sum(sum(Arch, 1) == 0);
    
    % number of power sinks
    nsnk = sum(sum(Arch, 2) == 0);
    
    % number of power transmitters
    ntrn = nrow - nsrc - nsnk;
    
    % check that the number of energy sources match
    if (nsrc ~= length(SrcType))
        
        % throw an error
        error("ERROR - CreatePropArch: incorrect number of sources prescribed.");
        
    end
    
    % check that the number of power transmitters match
    if (ntrn ~= length(TrnType))
        
        % throw an error
        error("ERROR - CreatePropArch: incorrect number of transmitters prescribed.");
        
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
Aircraft.Specs.Propulsion.PropArch.OperUps = OperUps;
Aircraft.Specs.Propulsion.PropArch.OperDwn = OperDwn;

% remember the efficiencies
Aircraft.Specs.Propulsion.PropArch.EtaUps = EtaUps;
Aircraft.Specs.Propulsion.PropArch.EtaDwn = EtaDwn;

% remember the component types in the architecture
Aircraft.Specs.Propulsion.PropArch.SrcType = SrcType;
Aircraft.Specs.Propulsion.PropArch.TrnType = TrnType;

% get number of arguments for each (potential) split
Aircraft.Settings.nargOperUps = nargin(Aircraft.Specs.Propulsion.PropArch.OperUps);
Aircraft.Settings.nargOperDwn = nargin(Aircraft.Specs.Propulsion.PropArch.OperDwn);

% ----------------------------------------------------------
    
end