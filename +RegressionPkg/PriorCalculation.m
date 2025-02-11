function [Prior] = PriorCalculation(datastruct,IOspace)

% This section creates prior distributions for each queried point. It
% simply finds the mean of the target parameter and assigns it to a Dx1
% array, (the same initial guess for every point). The for loop/if statement
% excludes NaN values.
[~,priordata] = RegressionPkg.SearchDB(datastruct,IOspace{end});
priordata = cell2mat(priordata(:,2));
c = 1;

if sum(isnan(priordata)) > 0
    for i = 1:length(priordata)
        if isnan(priordata(i))
            indexc(c) = i; c = c+1; %#ok<*AGROW> 
        end
    end
    priordata(indexc) = [];
end

Prior = mean(priordata);
end

