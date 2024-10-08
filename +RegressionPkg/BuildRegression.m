
function [mu_post,sig2_post] =...
BuildRegression(data,mu_prior,target,hyperparams,InverseTerm)

% sig2_prior = (mu_prior*5e-2)^2;
% 
% % INVERSE DATA MATRIX
PS = size(data,1);
% Kbarbar = zeros(PS);
% for i = 1:PS
%     for j = 1:PS
%         Kbarbar(i,j) = RegressionPkg.SquareExKernel(data(i,1:end-1),...
%             data(j,1:end-1),hyperparams);
%     end
% end
% 
% InverseTerm = inv(Kbarbar + sig2_prior.*eye(PS));

Kbarstar = zeros(1,PS);
for ii = 1:PS
    Kbarstar(ii) = RegressionPkg.SquareExKernel(data(ii,1:end-1),target,hyperparams);
end

mu_post = mu_prior + Kbarstar*InverseTerm*(data(:,end) - mu_prior);

sig2_post = RegressionPkg.SquareExKernel(target,target,hyperparams)...
    - Kbarstar*InverseTerm*Kbarstar';
end
