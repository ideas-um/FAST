function [PostMu,PostVar] = NLGPR(DataStruct,IOspace,Target,varargin)
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


% Default values for settings

Options.Weights = ones(1,length(IOspace)-1);
Options.Prior = ones(length(Target),1) .* RegressionPkg.PriorCalculation(DataStruct,IOspace);
Options.Iteration = false;
Options.Preprocessing = NaN;

OptionNames = fieldnames(Options);

for ii = 1:2:length(varargin)
    name = varargin{ii};
    value = varargin{ii+1};

    if any(strcmpi(name, OptionNames))
        Options.(name) = value;
    else
        error('Regression, unknown setting: %s', name);
    end
end

% Need to check that if iteration variable is set, information needed to
% run the regression is provided
if Options.Iteration 
    if ~isstruct(Options.Preprocessing)
    error('Regression Settings: If iteration is set to true, preprocessed data matrices must also be set')
    end
    
    DataMatrix  = Options.Preprocessing.DataMatrix ;
    HyperParams = Options.Preprocessing.HyperParams;
    InverseTerm = Options.Preprocessing.InverseTerm;
else % If not in an iteration, the Posterior variables will need to be calculated here

    [DataMatrix,HyperParams,InverseTerm] =...
    RegressionPkg.RegProcessing(DataStruct,IOspace, Options.Prior, Options.Weights);

end

% Initialize Posterior distribution(s)
PostMu = zeros(size(Target,1),1);
PostVar = PostMu;

% I believe there is a way to do this more efficiently but right now I just
% look through each target case. The math inside this is not that
% cumbersome so it goes by pretty quick
for i = 1:length(PostMu)
[PostMu(i),PostVar(i)] = ...
    RegressionPkg.BuildRegression(DataMatrix,Options.Prior(i),Target(i,:),HyperParams,InverseTerm);
end


end












