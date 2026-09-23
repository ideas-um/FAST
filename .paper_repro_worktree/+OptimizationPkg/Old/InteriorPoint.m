function [xopt, fopt, xhist, fhist, optim, feas, info] = InteriorPoint(ObjFun, x0, ConFun)
%
% [xopt, fopt, xhist, fhist, optim, feas, info] = InteriorPoint(ObjFun, x0, ConFun)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 27 mar 2024
%
% Optimize an (un)constrained problem using interior point methods. For the
% inputs/outputs below, nx and niter represent the number of design
% variables and number of iterations to converge, respectively.
%
% INPUTS:
%     ObjFun - function handle to the objective.
%              size/type/units: 1-by-1 / function handle / []
%
%     x0     - initial guess.
%              size/type/units: nx-by-1 / double / []
%
%     ConFun - function handle to the constraints (if any).
%              size/type/units: 1-by-1 / function handle / []
%
% OUTPUTS:
%     xopt   - optimum point.
%              size/type/units: nx-by-1 / double / []
%
%     fopt   - optimum function value.
%              size/type/units: 1-by-1 / double / []
%
%     xhist  - history of optimum points.
%              size/type/units: nx-by-niter / double / []
%
%     fhist  - history of objective function values.
%              size/type/units: 1-by-niter / double / []
%
%     optim  - optimality  value.
%              size/type/units: 1-by-1 / double / []
%
%     feas   - feasibility value.
%              size/type/units: 1-by-1 / double / []
%
%     info   - information from the objective function evaluation.
%              size/type/units: 1-by-1 / struct / []
%


%% OPTIMIZATION SETUP %%
%%%%%%%%%%%%%%%%%%%%%%%%

% set a convergence tolerance
EPS = 1.0e-03;

% assume a maximum number of iterations
MaxIter = 99;

% check if a constraint function is provided
if (nargin < 3)
    
    % turn constraint flag off
    HaveCons = 0;
    
else
    
    % turn constraint flag on
    HaveCons = 1;
    
    % assume penalty parameter and decrease factor (can be tuned later)
    mu  = 10   ; % was 100
    rho =  0.50; % was 0.99
    
end

% count the iterations
iter = 0;

% remember the initial guess
x = x0;

% get the number of design variables
nx = length(x);

% initialize the hessian approximation
H = eye(nx);

% assume an unconstrained problem
ndim = nx;

% initialize optimization path
xhist = x0;
fhist = [];
ghist = [];
dfdxhist = [];
dgdxhist = [];
LamHist = [];
SigHist = [];


%% OPTIMIZE %%
%%%%%%%%%%%%%%

% iterate until convergence
while (iter < MaxIter)
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %                            %
    % evaluate the objective     %
    % function and constraints   %
    %                            %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % evaluate the function (and check for gradients)
    [f, dfdx, info] = ObjFun(x, 1);
    
    % remember the objective and derivatives
    fhist    = [fhist   ,  f  ];
    dfdxhist = [dfdxhist, dfdx];
    
    % check for constraints
    if (HaveCons == 1)
        
        % check if any info is provided from the objective function
        if (isempty(info) == 1)
            
            % evaluate the constraints (no   extra information)
            [g, h, dgdx, dhdx] = ConFun(x, 1);
            
        else
            
            % evaluate the constraints (with extra information)
            [g, h, dgdx, dhdx] = ConFun(x, 1, info);
            
        end
        
        % remember the constraint history
        ghist    = [ghist   ,  g  ];
        dgdxhist = [dgdxhist; dgdx];
                
        % assume no constraints are violated
        feas = 0;
        
        % find the most violated   equality constraint
        if (~isempty(h))
            feas = max(feas, max(abs(h)));
        end            
    end
    
    % ------------------------------------------------------
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %                            %
    % set lagrange multipliers,  %
    % slack variables, and       %
    % matrix sizes               %
    %                            %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % check if this is the first iteration
    if (iter < 1)
        
        % get the number of constraints
        ng = length(g);
        nh = length(h);
        
        % update the size of the linear system to be solved
        ndim = ndim + nh + 2 * ng;
        
        % memory for   equality lagrange multipliers
        if (nh > 0)
            Lam = zeros(nh, 1);
            
        else
            Lam = [];
            
        end
        
        % memory for inequality lagrange multipliers and slack vars.
        if (ng > 0)
            Sig = zeros(ng, 1);
            s   = ones( ng, 1);
            
        else
            Sig = [];
            s   = [];
            
        end
        
        % size of the linear system for computing step sizes
        A = zeros(ndim, ndim);
        b = zeros(ndim,    1);
        
    end
    
    % ------------------------------------------------------
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %                            %
    % check optimality and       %
    % feasibility                %
    %                            %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % check inequality constraints
    if (ng > 0)
                
        % scale the gradient by the lagrange multipliers
        dLdx_g = dgdx' * Sig;
        
    else
        
        % no inequality constraints
        dLdx_g = 0;
        
    end
    
    % check   equality constraints
    if (nh > 0)
                
        % scale the gradient by the lagrange multipliers
        dLdx_h = dhdx' * Lam;
        
    else
        
        % no   equality constraints
        dLdx_h = 0;
        
    end
    
    % compute the gradient of the lagrangian
    dLdx = dfdx + dLdx_g + dLdx_h;
    
    % check optimality
    optim = max(abs(dLdx));

    % check convergence
    if ((optim < EPS) && (feas < EPS))
        break;
    end
    
    % ------------------------------------------------------
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %                            %
    % setup linear system to     %
    % step towards the minimum   %
    %                            %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % hessian contribution to the coefficient matrix (block [1,1] position)
    A(1:nx, 1:nx) = H;
    
    % gradient of lagrangian for the righthand side (block [1] position)
    b(1:nx) = -dLdx;
    
    %   equality constraint gradient contribution to coefficient matrix
    if (~isempty(dhdx))
        
        % update the coefficient matrix (block [2,1] and [1,2] positions)
        A(nx+1:nx+nh, 1:nx) = dhdx ;
        A(1:nx, nx+1:nx+nh) = dhdx';
        
        % update the righthand side (block [2] position)
        b(nx+1:nx+nh) = -h;
        
    end
    
    % inequality constraint gradient contribution to coefficient matrix
    if (~isempty(dgdx))
        
        % update the coefficient matrix (block [3,1] and [1,3] position)
        A(nx+nh+1:nx+nh+ng, 1:nx) = dgdx ;
        A(1:nx, nx+nh+1:nx+nh+ng) = dgdx';
        
        % update the coefficient matrix (block [4,3] and [3,4] position)
        A(nx+nh+1:nx+nh+ng, nx+nh+ng+1:end) = eye(ng);
        A(nx+nh+ng+1:end, nx+nh+1:nx+nh+ng) = eye(ng);
        
        % update the coefficient matrix (block [4,4] position)
        A(nx+nh+ng+1:end, nx+nh+ng+1:end) = diag(Sig ./ s);
        
        % update the righthand side (block [3] position)
        b(nx+nh+1:nx+nh+ng) = -(g + s);
        
        % update the righthand side (block [4] position)
        b(nx+nh+ng+1:end) = -(Sig - mu ./ s);
        
    end
    
    % ------------------------------------------------------
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %                            %
    % solve the linear system,   %
    % extract the search         %
    % directions, and figure out %
    % how far to step in those   %
    % directions                 %
    %                            %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % solve the system
    p = A \ b;
    
    % extract the search directions
    px   = p(               1 : nx              );
    plam = p(nx           + 1 : nx + nh         );
    psig = p(nx + nh      + 1 : nx + nh +     ng);
    ps   = p(nx + nh + ng + 1 : nx + nh + 2 * ng);
    
    % find the maximum step size for the slack variables and lagrange mult.
    amaxs   = OptimizationPkg.FeasStep(ng, s  , ps  );
    amaxsig = OptimizationPkg.FeasStep(ng, Sig, psig);
    
    % create a merit function for the line search
    if (ng > 0)
        MerFun = @(x) OptimizationPkg.MeritFunction(ObjFun, x, ConFun, s, mu);
        
    elseif (nh > 0)
        MerFun = @(x) OptimizationPkg.MeritFunction(ObjFun, x, ConFun);
        
    else
        MerFun = @(x) OptimizationPkg.MeritFunction(ObjFun, x);
        
    end
    
    % line search
    ax = OptimizationPkg.GoldenSection(MerFun, x, px, amaxs);

    % step forward with the design and slack variables
    Newx = x + ax .* px;
    News = s + ax .* ps;
    
    % step forward with the lagrange multipliers
    NewLam = Lam + amaxsig .* plam;
    NewSig = Sig + amaxsig .* psig;
    
    % ------------------------------------------------------
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %                            %
    % update the hessian for the %
    % next iteration             %
    %                            %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % compute the difference in design variables
    Delx = Newx - x;
    
    % re-compute the function value
    [Newf, Newdfdx, info] = ObjFun(Newx, 1);
    
    % re-compute for constraints
    if (HaveCons == 1)
        
        % check if there's info to be passed from the objective function
        if (isempty(info) == 1)
            
            % evaluate the constraints (no   extra info)
            [~, ~, Newdgdx, Newdhdx] = ConFun(Newx, 1);
            
        else
            
            % evaluate the constraints (with extra info)
            [~, ~, Newdgdx, Newdhdx] = ConFun(Newx, 1, info);
            
        end

        % check for inequality constraints
        if (ng > 0)
            
            % scale the gradient by the lagrange multipliers
            NewdLdx_g = Newdgdx' * NewSig;
            foodLdx_g =    dgdx' * NewSig;
            
        else
            
            % no inequality constraints
            NewdLdx_g = 0;
            foodLdx_g = 0;
            
        end
        
        % check for   equality constraints
        if (nh > 0)
            
            % scale the gradient by the lagrange multipliers
            NewdLdx_h = Newdhdx' * NewLam;
            foodLdx_h =    dhdx' * NewLam;
            
        else
            
            % no   equality constraints
            NewdLdx_h = 0;
            foodLdx_h = 0;
            
        end            
    end
    
    % compute modified lagrangian gradients
    dLdx_1 = Newdfdx + NewdLdx_g + NewdLdx_h;
    dLdx_2 =    dfdx + foodLdx_g + foodLdx_h;
    
    % compute the difference between the gradients
    DeldL = dLdx_1 - dLdx_2;
    
    % update the hessian and reset it every few iterations
    if (mod(iter, 5) == 0)
        
        % reset the hessian to an identity matrix
        H = eye(nx);
        
    else
        
        % use a hessian update from quasi-newton methods
        H = OptimizationPkg.HessUpd(H, Delx, DeldL);
        
    end
    
    % ------------------------------------------------------
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %                            %
    % iterate                    %
    %                            %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % update the barrier parameter
    mu = mu * rho;
    
    % count the iteration
    iter = iter + 1;
    
    % update the design/slack variables and lagrange multipliers
    x   = Newx  ;
    s   = News  ;
    Lam = NewLam;
    Sig = NewSig;
    f   = Newf  ;
    
    % update the optimization history
    xhist = [xhist, x];
    
    % update the lagrange multiplier history
    LamHist = [LamHist, Lam];
    SigHist = [SigHist, Sig];
    
end


%% GET THE OPTIMIUM POINT/VALUE %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% optimum point
xopt = x;

% optimum value
fopt = f;

% ----------------------------------------------------------
save("OptimizationWorkspace.mat");
end