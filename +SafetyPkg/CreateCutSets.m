function [Failures] = CreateCutSets(Arch, Components, icomp, ntrigger, ninput)
%
% [Failures] = CreateCutSets(Arch, Components, icomp, ntrigger, ninput)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 22 dec 2025
%
% List out all components in the minimum cut sets for a given system
% architecture. A [minimum] cut set is one (of possibly many) combinations 
% of [minimum] component failures required to cause a system-level failure.
%
% To find the [minimum] cut sets, check whether an internal failure mode
% exists and if there are any downstream components that need to be
% considered in each cut set.
%
% INPUTS:
%     Arch       - the architecture matrix representing the system
%                  architecture to be analyzed.
%                  size/type/units: n-by-n / int / []
%
%     Components - a structure array containing each component in the
%                  system architecture and the following information about
%                  it:
%                      a) the component name, a cell array of characters
%                      b) a column vector of failure rates
%                  size/type/units: 1-by-1 / struct / []
%
%     icomp      - the index of the component in the fault tree currently
%                  being assessed.
%                  size/type/units: 1-by-1 / integer / []
%
%     ntrigger   - number of components required to trigger the gate
%                  size/type/units: n-by-1 / integer / []
%
%     ninput     - number of components that input to the current
%                  component (or NaN if it is a source).
%                  size/type/units: n-by-1 / integer or NaN / []
%
% OUTPUTS:
%     Failures   - the matrix updated with all of the necessary failure
%                  mode IDs after recursively searching the system
%                  architecture.
%                  size/type/units: m-by-p / integer / []
%


%% CHECK FOR AN INTERNAL FAILURE %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% get the downstream components
idwn = Arch{icomp};

% check if there is an internal failure mode
if (~strcmpi(Components.FailMode{icomp}, ""))

    % add the component failure
    IntFails = Components.FailID(icomp);

    % flag the failure
    FailFlag = 1;

else

    % no failure
    IntFails = [];

    % turn off the failure flag
    FailFlag = 0;

end


%% CHECK FOR DOWNSTREAM FAILURES %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% get the number of downstream components
ndwn = length(idwn);

% allocate memory
DwnFails = cell(1, ndwn);

% loop through the downstream components
for i = 1:ndwn

    % search recursively and remember the downstream failures
    DwnFails{i} = SafetyPkg.CreateCutSets(Arch, Components, idwn(i), ntrigger, ninput);

end

% enumerate the downstream failures, if any exist
if (ndwn > 0)

    if (ndwn == 1) % OR gate

        % the only failure is the downstream failure, it is an OR gate
        FinalFails = DwnFails{1};

    else % AND or K/N gate

        % check for an AND gate (# of trigger events matches # of inputs)
        if (ntrigger(icomp) == ninput(icomp))

            % enumerate all failures in the AND gate
            FinalFails = SafetyPkg.AndGate(DwnFails, ndwn);

        else % K/N GATE

            % remember the number of events to trigger
            mtrigger = ntrigger(icomp);

            % get the number of combinations
            ncomb = factorial(ndwn) / (factorial(mtrigger) * factorial(ndwn - mtrigger));

            % get the number of indices
            Idx = 1 : mtrigger;

            % cell array for downstream failures
            NewDwn = cell(1, mtrigger);

            % switching value for running the law of absorbption
            SwitchVal = 0.10;

            % loop through each set of combinations
            for icomb = 1:ncomb

                % get current failures
                for itrigger = 1:mtrigger
                    NewDwn{itrigger} = DwnFails{Idx(itrigger)};
                end

                % enumerate the current failures
                if (mtrigger == 1)

                    % there is only one failure, do not use an AND gate
                    CurFails = NewDwn{itrigger};

                else

                    % use an AND gate to get all possible failures
                    CurFails = SafetyPkg.AndGate(NewDwn, mtrigger);

                end

                % append the current failures to the final ones
                if (icomb == 1)

                    % remember the current failures
                    FinalFails = CurFails;

                else

                    % get the size of each failure
                    [nrow1, ncol1] = size(FinalFails);
                    [nrow2, ncol2] = size(  CurFails);

                    % check for the larger array
                    if (ncol1 > ncol2)

                        % add more empty columns to CurFails
                        FinalFails = [FinalFails; CurFails, zeros(nrow2, ncol1 - ncol2)];

                    elseif (ncol1 < ncol2)

                        % add more empty columns to FinalFails
                        FinalFails = [FinalFails, zeros(nrow1, ncol2 - ncol1); CurFails];

                    else

                        % they are the same size, just append arrays
                        FinalFails = [FinalFails; CurFails];

                    end
                end

                % simplify with the law of absorption every 10% of combos
                if (icomb / ncomb >= SwitchVal)

                    % simplify
                    FinalFails = SafetyPkg.LawOfAbsorption(FinalFails);

                    % increase the switching value
                    SwitchVal = SwitchVal + 0.10;

                end

                % add one to the final index
                Idx(end) = Idx(end) + 1;

                % add a dummy index
                dummy = 0;

                % loop through all indices
                for itrigger = mtrigger : -1 : 2

                    % check if a current index exceeds its limit
                    if (Idx(itrigger) > (ndwn - dummy))

                        % increment the prior index
                        Idx(itrigger - 1) = Idx(itrigger - 1) + 1;

                        % reset indices beyond this one
                        if (dummy > 0)
                            Idx(itrigger:end) = Idx(itrigger - 1) + (1 : (mtrigger - itrigger + 1));
                        else
                            Idx(end) = Idx(itrigger - 1) + 1;
                        end

                    end

                    % incremement the dummy index
                    dummy = dummy + 1;

                end
            end
        end
    end

    % get the size of the downstream failures
    [~, ncol] = size(FinalFails);

    % add columns and append downstream failures
    if (FailFlag == 1)
        Failures = [FinalFails; IntFails, zeros(1, ncol - FailFlag)];

    else
        Failures = FinalFails;

    end

else

    % return only the internal failures
    Failures = IntFails;

end

% ----------------------------------------------------------

end
