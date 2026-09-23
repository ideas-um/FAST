function [K] = SquareExKernel(x,y,hyperparams)
% 
% [K] = SquareExKernel(x,y,hyperparams)
% Covariance Kernel Function
% Written by Maxfield Arnson
%
% This (internal) function evaluates the squared exponential covariance  
% kernel between two sets of multidimensional input data. It is used in the
% RegressionPkg.NLGPR() function to build the RegressionPkg.
%
%
% INPUTS:
% x = first set of data
%   size: 1xN array of doubles
% y = second set of data
%   size: 1xN array of doubles
% hyperparams = set of tuned length and magnitude scales for each dimension
%   of the input data
%   size: 1x(N+1) array of doubles
%
%
% OUTPUTS:
% K = covariance between data set 1 and data set 2
%   This output is normalized by the magnitude of hyperparams(N+1)

K = hyperparams(end)*exp(-0.3*sum((x-y).^2./hyperparams(1:end-1)));
end