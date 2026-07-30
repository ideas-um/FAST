function [Aircraft] = ProcessPropArch(Aircraft)
%
% [Aircraft] = ProcessPropArch(Aircraft)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 10 mar 2026
%
% given a propulsion architecture, find how each gas turbine engine is
% connected to a propeller. the power required at the propeller is
% necessary for determining the gas turbine engine power output.
% additionally, compute the hybrid electric coefficients for the gas
% turbine engine to run in the BADA equation.
%
% INPUTS:
%     Aircraft - information about the aircraft and its propulsion
%                architecture.
%                size/type/units: 1-by-1 / struct / []
%
% OUTPUTS:
%     Aircraft - information updated with the propeller connections and
%                hybrid electric coefficients for each engine to be
%                analyzed.
%                size/type/units: 1-by-1 / struct / []
%

% get the propulsion archcitecture
Arch = Aircraft.Specs.Propulsion.PropArch.Arch;

% get the source and transmitter types
SrcType = Aircraft.Specs.Propulsion.PropArch.SrcType;
TrnType = Aircraft.Specs.Propulsion.PropArch.TrnType;

% get the number of components
[ncomp, ~] = size(Arch);

% get the number of sources and transmitters
nsrc = length(SrcType);
ntrn = length(TrnType);

% compute the number of sinks
nsnk = ncomp - nsrc - ntrn;

% get the power requirements from sizing
SLSPower  = Aircraft.Specs.Propulsion.SLSPower;

% get the downstream sizing splits
LamSLS = Aircraft.Specs.Power.LamDwn.SLS;

% convert to a cell array
LamCell = num2cell(LamSLS);

% get the downstream power splits
LamDwn = Aircraft.Specs.Propulsion.PropArch.OperDwn(LamCell{:});

% assume perfect efficiencies for computing thrust ratios
EtaDwn = ones(ncomp, ncomp);

% allocate memory for indexed transmitter arrays
WhichProp = zeros(1, ntrn);
HEcoeff   = zeros(1, ntrn);

% create logical array transmitters
itrn = logical([zeros(nsrc, 1);  ones(ntrn, 1); zeros(nsnk, 1)]);

% combine types to form an ID
ID = [SrcType'; TrnType'; zeros(nsnk, 1)];

% get the propeller and gas turbine engine IDs
PropIdx = find(TrnType == 2) + nsrc;
 EngIdx = find(TrnType == 1) + nsrc;

% define a power vector
PowerVector = zeros(ncomp, 1);

% remember the "required" and "SLS" power demands
Preq = zeros(ncomp, 1);
PSLS = zeros(ncomp, 1);

% loop through all propellers to find indirect gas turbine engines
for iprop = PropIdx
        
    % remember a copy of the index
    jprop = iprop;
        
    % remember the index
    krow = jprop;
    
    % loop until gas turbine engine is found
    while (~isempty(krow))
        
        % check if any are gas turbine engines
        AnyGTE = logical(sum(Arch(:, krow) > 0 & ID == 1 & itrn, 2));
        
        if (any(AnyGTE)) % assume only 1 GTE per fan
            
            % get its index
            igte = find(AnyGTE);

            % perturb the power vector
            PowerVector(iprop) = SLSPower(iprop - nsrc);

            % propagate power downstream
            Pout = PropulsionPkg.PowerFlow(PowerVector, Arch', LamDwn, EtaDwn, -1, 1.0e-06);
            
            % remember the power output by the engine and the total power
            % required
            Preq(igte) = Preq(igte) + Pout(igte);
            PSLS(igte) = PSLS(igte) + SLSPower(iprop - nsrc);
            
            % remove the perturbation
            PowerVector(iprop) = 0;

            % break out of the loop
            break;
            
        else
            
            % remember the indices
            jrow = krow;
            
            % search a level deeper
            [krow, ~] = find(Arch(:, jrow));
            
        end
    end    
end

% loop through all propellers to find directly connected gas turbine engines
for iprop = PropIdx
    
    % find gas turbine engines
    GTEIdx = find(Arch(:, iprop) > 0 & ID == 1 & itrn);

    % check for an index
    if (~isempty(GTEIdx))

       % remember the index
       WhichProp(GTEIdx - nsrc) = iprop;
       
    end
    
end

% compute the HE coefficient
HEcoeff(EngIdx - nsrc) = 2 - Preq(EngIdx) ./ PSLS(EngIdx);

% correct for NaN -- set to 0
HEcoeff(isnan(HEcoeff)) = 0;

% remember the coefficients
Aircraft.Specs.Propulsion.Engine.HEcoeff = HEcoeff;
Aircraft.Specs.Propulsion.PropArch.WhichProp = WhichProp;

end