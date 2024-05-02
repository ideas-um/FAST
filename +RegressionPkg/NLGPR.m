function [PostMu,PostVar] = NLGPR(datastruct,IOspace,target,weights,prior)
%
% [PostMu,PostVar] = NLGPR(datastruct,class,IOspace,target)
% [PostMu,PostVar] = NLGPR(datastruct,class,IOspace,target,weights)
% [PostMu,PostVar] = NLGPR(datastruct,class,IOspace,target,weights,prior)
% Non-Linear Gaussian Process Regression
% Written by Maxfield Arnson
%
% This function predicts aircraft or engine parameters using the IDEAS
% historical database. Given as many known (and relevant) parameters as 
% possible, it will return a Gaussian distribution (mean and variance) 
% of the queried parameter.
%
%
% INPUTS:
% datastruct = choice of database. Is the queried parameter an aircraft
%    or an engine parameter? 
%    size: 1x1 String array
%    Options are:
%         {TurbofanAC                  }
%         {TurbofanEngines             }
%         {TurbopropAC                 }
%         {TurbopropEngines            }
%
%
% IOspace = OUT OF DATE Input/Output space. Cell array of string arrays with N known parameters
%   and 1 unknown parameter.
%   size: 1x(N+1) cell array
%   options: there are over 1e29 combinations that can be input for
%   IOspace. A tutorial is coming soon and will be available in
%   RegressionPkg.README
%         
% target = quantities of known values for the known parameters.
%    size: DxN array of doubles, where D is the number of sets of known
%    parameters that are being queried.
% weights = optional input if the user desires to prescribe custom weights
%   to each of the inputs. The function will normalize automatically. For
%   example, if N = 2, weights = [1, 2] is functionally identical to   
%   weights = [0.5, 1].
%   size: 1xN array of doubles. 
% prior = initial guess for the value of the parameter being estimated
%   size: Dx1 array of doubles
%
%
% OUTPUTS:
% PostMu = Posterior mean estimates for each queried point.
%    size: Dx1 array of doubles
% PostVar = Posterior variance estimates for each queried point.
%    size: Dx1 array of doubles


% Call Build Data Function (internal function)
% Create Matrix of known data, build prior distribution,
% and tune hyperparameters. If weights are prescribed, pass them into the
% function
switch nargin
    case 5
[DataMatrix,Prior,hypers] = ...
    RegressionPkg.BuildData(datastruct,IOspace,target,weights,prior);
    case 4
[DataMatrix,Prior,hypers] = ...
    RegressionPkg.BuildData(datastruct,IOspace,target,weights);
    case 3
[DataMatrix,Prior,hypers] = ...
    RegressionPkg.BuildData(datastruct,IOspace,target);
end


% Call Posterior Function (internal function)
% Calculate posterior mean and variance for each requested target
[PostMu,PostVar] =...
    RegressionPkg.CreatePosterior(DataMatrix,...
    Prior,target,hypers);
end