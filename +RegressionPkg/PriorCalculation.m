function [Prior] = PriorCalculation(DataStruct,IOspace)
%
% [Prior] = PriorCalculation(DataStruct,IOspace)
% written by Maxfield Arnson,
% last updated: 19 nov 2025
%
% This function creates a simple version of a prior distribution for a given regression.
% The prior is simply the mean of all recorded data for the output parameter
% in the database, ignoring NaN entries.
%
% INPUTS:
%     DataStruct    - a historical database structure.
%                     size/type/units: 1-by-1 / structure / []
%
%     IOSpace       - cell array where each entry is a string array carrying
%                     the structure path to each of the inputs. These
%                     structure paths are listed in the read me for this
%                     package: RegressionPkg.NLGPR. The last entry in this
%                     cell array is the path for the desired output. N is
%                     the number of inputs
%                     size/type/units: 1-by-N+1 / cell array / []
%
% OUTPUTS:
%     Prior         - value to use as a guess for the desired output.
%                     size/type/units: 1-by-1 / double / [output units]


% Get output parameter data from database
[~,priordata] = RegressionPkg.SearchDB(DataStruct,IOspace{end});

% Transform to numeric array
priordata = cell2mat(priordata(:,2));

% initialize index counter
c = 1;

% only if there are NaN entries, find and remove them
if sum(isnan(priordata)) > 0

    % loop through prior data to find NaN entries
    for i = 1:length(priordata)

        % check if entry is NaN
        if isnan(priordata(i))

            % add index at index array
            indexc(c) = i; %#ok<*AGROW> 
            
            % increment counter
            c = c+1; 
        end
    end

    % remove NaN entries from prior data
    priordata(indexc) = [];
end

% assign output prior value as mean of prior data
Prior = mean(priordata);

end % RegressionPkg.PriorCalculation