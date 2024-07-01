function [Success] = TestCreatePropArch()
%
% [Success] = TestCreatePropArch()
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 28 jun 2024
%
% Generate simple test cases to confirm that the propulsion architectures
% are being created properly. Assume all tests are for turboprop
% configurations unless otherwise specified in the section header(s).
%
% INPUTS:
%     none
%
% OUTPUTS:
%     Success - flag to show whether all of the tests passed (1) or not (0)
%
%% TEST CASE SETUP %%
%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% setup testing methods      %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% relative tolerance for checking if the tests passed
EPS06 = 1.0e-06;

% assume all tests passed
Pass = ones(12, 1);

% count the tests
itest = 1;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% setup aircraft structure   %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% get the aircraft class
TestIn.Specs.TLAR.Class = "Turboprop";

% assume an electric motor efficiency
EtaEM = 0.96;

% store the electric motor efficiency
TestIn.Specs.Power.Eta.EM = EtaEM;

% assume a propeller efficiency
EtaProp = 0.80;

% store the propeller efficiency
TestIn.Specs.Power.Eta.Propeller = EtaProp;


%% CASE 1A: CONVENTIONAL, 2 ENGINES %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% setup the inputs           %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% set the architecture
TestIn.Specs.Propulsion.Arch.Type = "C";

% set the number of engines
TestIn.Specs.Propulsion.NumEngines = 2;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% run the test               %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% create the propulsion architecture
TestOut = PropulsionPkg.CreatePropArch(TestIn);

% remember the correct architecture matrices
CorrectTSPS = eye( 2   );
CorrectPSPS = eye( 2   );
CorrectPSES = ones(2, 1);

% check the architecture matrices
FooPass( 1) = CheckTest(TestOut.Specs.Propulsion.PropArch.TSPS, CorrectTSPS, EPS06);
FooPass( 2) = CheckTest(TestOut.Specs.Propulsion.PropArch.PSPS, CorrectPSPS, EPS06);
FooPass( 3) = CheckTest(TestOut.Specs.Propulsion.PropArch.PSES, CorrectPSES, EPS06);

% remember the correct operational matrix for thrust splits
CorrectTS = repmat(0.5, 1, 2);

% check the operational matrices (same as architecture matrices)
FooPass( 4) = CheckTest(TestOut.Specs.Propulsion.Oper.TS(  ), CorrectTS  , EPS06);
FooPass( 5) = CheckTest(TestOut.Specs.Propulsion.Oper.TSPS(), CorrectTSPS, EPS06);
FooPass( 6) = CheckTest(TestOut.Specs.Propulsion.Oper.PSPS(), CorrectPSPS, EPS06);
FooPass( 7) = CheckTest(TestOut.Specs.Propulsion.Oper.PSES(), CorrectPSES, EPS06);

% remember the correct efficiency matrices
CorrectTSPS = ones(2   ) - (1 - EtaProp) .* eye(2);
CorrectPSPS = ones(2   ) ;
CorrectPSES = ones(2, 1) ;

% check the efficiency matrices (propeller aircraft)
FooPass( 8) = CheckTest(TestOut.Specs.Propulsion.Eta.TSPS, CorrectTSPS, EPS06);
FooPass( 9) = CheckTest(TestOut.Specs.Propulsion.Eta.PSPS, CorrectPSPS, EPS06);
FooPass(10) = CheckTest(TestOut.Specs.Propulsion.Eta.PSES, CorrectPSES, EPS06);

% correct energy and power source types
CorrectESType =      1    ;
CorrectPSType = ones(1, 2);

% check the energy and power source types
FooPass(11) = CheckTest(TestOut.Specs.Propulsion.PropArch.ESType, CorrectESType, EPS06);
FooPass(12) = CheckTest(TestOut.Specs.Propulsion.PropArch.PSType, CorrectPSType, EPS06);

% check that all tests passed
if (~any(FooPass))
    
    % one or more of the tests failed
    Pass(itest) = 0;
    
else
    
    % all tests passed
    Pass(itest) = 1;
    
end

% increment the test number
itest = itest + 1;


%% CASE 1B: CONVENTIONAL, 3 ENGINES %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% setup the inputs           %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% set the architecture
TestIn.Specs.Propulsion.Arch.Type = "C";

% set the number of engines
TestIn.Specs.Propulsion.NumEngines = 3;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% run the test               %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% create the propulsion architecture
TestOut = PropulsionPkg.CreatePropArch(TestIn);

% remember the correct architecture matrices
CorrectTSPS = eye( 3   );
CorrectPSPS = eye( 3   );
CorrectPSES = ones(3, 1);

% check the architecture matrices
FooPass( 1) = CheckTest(TestOut.Specs.Propulsion.PropArch.TSPS, CorrectTSPS, EPS06);
FooPass( 2) = CheckTest(TestOut.Specs.Propulsion.PropArch.PSPS, CorrectPSPS, EPS06);
FooPass( 3) = CheckTest(TestOut.Specs.Propulsion.PropArch.PSES, CorrectPSES, EPS06);

% remember the correct operational matrix for thrust splits
CorrectTS = repmat(1/3, 1, 3);

% check the operational matrices (same as architecture matrices)
FooPass( 4) = CheckTest(TestOut.Specs.Propulsion.Oper.TS(  ), CorrectTS  , EPS06);
FooPass( 5) = CheckTest(TestOut.Specs.Propulsion.Oper.TSPS(), CorrectTSPS, EPS06);
FooPass( 6) = CheckTest(TestOut.Specs.Propulsion.Oper.PSPS(), CorrectPSPS, EPS06);
FooPass( 7) = CheckTest(TestOut.Specs.Propulsion.Oper.PSES(), CorrectPSES, EPS06);

% remember the correct efficiency matrices
CorrectTSPS = ones(3   ) - (1 - EtaProp) .* eye(3);
CorrectPSPS = ones(3   ) ;
CorrectPSES = ones(3, 1) ;

% check the efficiency matrices (propeller aircraft)
FooPass( 8) = CheckTest(TestOut.Specs.Propulsion.Eta.TSPS, CorrectTSPS, EPS06);
FooPass( 9) = CheckTest(TestOut.Specs.Propulsion.Eta.PSPS, CorrectPSPS, EPS06);
FooPass(10) = CheckTest(TestOut.Specs.Propulsion.Eta.PSES, CorrectPSES, EPS06);

% correct energy and power source types
CorrectESType =      1    ;
CorrectPSType = ones(1, 3);

% check the energy and power source types
FooPass(11) = CheckTest(TestOut.Specs.Propulsion.PropArch.ESType, CorrectESType, EPS06);
FooPass(12) = CheckTest(TestOut.Specs.Propulsion.PropArch.PSType, CorrectPSType, EPS06);

% check that all tests passed
if (~any(FooPass))
    
    % one or more of the tests failed
    Pass(itest) = 0;
    
else
    
    % all tests passed
    Pass(itest) = 1;
    
end

% increment the test number
itest = itest + 1;


%% CASE 1C: CONVENTIONAL, 3 ENGINES, TURBOFAN %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% setup the inputs           %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% set the architecture
TestIn.Specs.Propulsion.Arch.Type = "C";

% set the number of engines
TestIn.Specs.Propulsion.NumEngines = 3;

% set the aircraft class
TestIn.Specs.TLAR.Class = "Turbofan";

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% run the test               %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% create the propulsion architecture
TestOut = PropulsionPkg.CreatePropArch(TestIn);

% remember the correct architecture matrices
CorrectTSPS = eye( 3   );
CorrectPSPS = eye( 3   );
CorrectPSES = ones(3, 1);

% check the architecture matrices
FooPass( 1) = CheckTest(TestOut.Specs.Propulsion.PropArch.TSPS, CorrectTSPS, EPS06);
FooPass( 2) = CheckTest(TestOut.Specs.Propulsion.PropArch.PSPS, CorrectPSPS, EPS06);
FooPass( 3) = CheckTest(TestOut.Specs.Propulsion.PropArch.PSES, CorrectPSES, EPS06);

% remember the correct operational matrix for thrust splits
CorrectTS = repmat(1/3, 1, 3);

% check the operational matrices (same as architecture matrices)
FooPass( 4) = CheckTest(TestOut.Specs.Propulsion.Oper.TS(  ), CorrectTS  , EPS06);
FooPass( 5) = CheckTest(TestOut.Specs.Propulsion.Oper.TSPS(), CorrectTSPS, EPS06);
FooPass( 6) = CheckTest(TestOut.Specs.Propulsion.Oper.PSPS(), CorrectPSPS, EPS06);
FooPass( 7) = CheckTest(TestOut.Specs.Propulsion.Oper.PSES(), CorrectPSES, EPS06);

% remember the correct efficiency matrices
CorrectTSPS = ones(3   );
CorrectPSPS = ones(3   );
CorrectPSES = ones(3, 1);

% check the efficiency matrices (propeller aircraft)
FooPass( 8) = CheckTest(TestOut.Specs.Propulsion.Eta.TSPS, CorrectTSPS, EPS06);
FooPass( 9) = CheckTest(TestOut.Specs.Propulsion.Eta.PSPS, CorrectPSPS, EPS06);
FooPass(10) = CheckTest(TestOut.Specs.Propulsion.Eta.PSES, CorrectPSES, EPS06);

% correct energy and power source types
CorrectESType =      1    ;
CorrectPSType = ones(1, 3);

% check the energy and power source types
FooPass(11) = CheckTest(TestOut.Specs.Propulsion.PropArch.ESType, CorrectESType, EPS06);
FooPass(12) = CheckTest(TestOut.Specs.Propulsion.PropArch.PSType, CorrectPSType, EPS06);

% check that all tests passed
if (~any(FooPass))
    
    % one or more of the tests failed
    Pass(itest) = 0;
    
else
    
    % all tests passed
    Pass(itest) = 1;
    
end

% increment the test number
itest = itest + 1;


%% CASE 2A: ELECTRIC, 2 ENGINES %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% setup the inputs           %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% set the architecture
TestIn.Specs.Propulsion.Arch.Type = "E";

% set the number of engines
TestIn.Specs.Propulsion.NumEngines = 2;

% reset the aircraft class
TestIn.Specs.TLAR.Class = "Turboprop";

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% run the test               %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% create the propulsion architecture
TestOut = PropulsionPkg.CreatePropArch(TestIn);

% remember the correct architecture matrices
CorrectTSPS = eye( 2   );
CorrectPSPS = eye( 2   );
CorrectPSES = ones(2, 1);

% check the architecture matrices
FooPass( 1) = CheckTest(TestOut.Specs.Propulsion.PropArch.TSPS, CorrectTSPS, EPS06);
FooPass( 2) = CheckTest(TestOut.Specs.Propulsion.PropArch.PSPS, CorrectPSPS, EPS06);
FooPass( 3) = CheckTest(TestOut.Specs.Propulsion.PropArch.PSES, CorrectPSES, EPS06);

% remember the correct operational matrix for thrust splits
CorrectTS = repmat(0.5, 1, 2);

% check the operational matrices (same as architecture matrices)
FooPass( 4) = CheckTest(TestOut.Specs.Propulsion.Oper.TS(  ), CorrectTS  , EPS06);
FooPass( 5) = CheckTest(TestOut.Specs.Propulsion.Oper.TSPS(), CorrectTSPS, EPS06);
FooPass( 6) = CheckTest(TestOut.Specs.Propulsion.Oper.PSPS(), CorrectPSPS, EPS06);
FooPass( 7) = CheckTest(TestOut.Specs.Propulsion.Oper.PSES(), CorrectPSES, EPS06);

% remember the correct efficiency matrices
CorrectTSPS = ones(2   ) - (1 - EtaProp) .* eye(2);
CorrectPSPS = ones(2   ) ;
CorrectPSES = repmat(EtaEM, 2, 1);

% check the efficiency matrices (propeller aircraft)
FooPass( 8) = CheckTest(TestOut.Specs.Propulsion.Eta.TSPS, CorrectTSPS, EPS06);
FooPass( 9) = CheckTest(TestOut.Specs.Propulsion.Eta.PSPS, CorrectPSPS, EPS06);
FooPass(10) = CheckTest(TestOut.Specs.Propulsion.Eta.PSES, CorrectPSES, EPS06);

% correct energy and power source types
CorrectESType =       0    ;
CorrectPSType = zeros(1, 2);

% check the energy and power source types
FooPass(11) = CheckTest(TestOut.Specs.Propulsion.PropArch.ESType, CorrectESType, EPS06);
FooPass(12) = CheckTest(TestOut.Specs.Propulsion.PropArch.PSType, CorrectPSType, EPS06);

% check that all tests passed
if (~any(FooPass))
    
    % one or more of the tests failed
    Pass(itest) = 0;
    
else
    
    % all tests passed
    Pass(itest) = 1;
    
end

% increment the test number
itest = itest + 1;


%% CASE 2B: ELECTRIC, 3 ENGINES %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% setup the inputs           %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% set the architecture
TestIn.Specs.Propulsion.Arch.Type = "E";

% set the number of engines
TestIn.Specs.Propulsion.NumEngines = 3;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% run the test               %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% create the propulsion architecture
TestOut = PropulsionPkg.CreatePropArch(TestIn);

% remember the correct architecture matrices
CorrectTSPS = eye( 3   );
CorrectPSPS = eye( 3   );
CorrectPSES = ones(3, 1);

% check the architecture matrices
FooPass( 1) = CheckTest(TestOut.Specs.Propulsion.PropArch.TSPS, CorrectTSPS, EPS06);
FooPass( 2) = CheckTest(TestOut.Specs.Propulsion.PropArch.PSPS, CorrectPSPS, EPS06);
FooPass( 3) = CheckTest(TestOut.Specs.Propulsion.PropArch.PSES, CorrectPSES, EPS06);

% remember the correct operational matrix for thrust splits
CorrectTS = repmat(1/3, 1, 3);

% check the operational matrices (same as architecture matrices)
FooPass( 4) = CheckTest(TestOut.Specs.Propulsion.Oper.TS(  ), CorrectTS  , EPS06);
FooPass( 5) = CheckTest(TestOut.Specs.Propulsion.Oper.TSPS(), CorrectTSPS, EPS06);
FooPass( 6) = CheckTest(TestOut.Specs.Propulsion.Oper.PSPS(), CorrectPSPS, EPS06);
FooPass( 7) = CheckTest(TestOut.Specs.Propulsion.Oper.PSES(), CorrectPSES, EPS06);

% remember the correct efficiency matrices
CorrectTSPS = ones(3   ) - (1 - EtaProp) .* eye(3);
CorrectPSPS = ones(3   ) ;
CorrectPSES = repmat(EtaEM, 3, 1) ;

% check the efficiency matrices (propeller aircraft)
FooPass( 8) = CheckTest(TestOut.Specs.Propulsion.Eta.TSPS, CorrectTSPS, EPS06);
FooPass( 9) = CheckTest(TestOut.Specs.Propulsion.Eta.PSPS, CorrectPSPS, EPS06);
FooPass(10) = CheckTest(TestOut.Specs.Propulsion.Eta.PSES, CorrectPSES, EPS06);

% correct energy and power source types
CorrectESType =       0    ;
CorrectPSType = zeros(1, 3);

% check the energy and power source types
FooPass(11) = CheckTest(TestOut.Specs.Propulsion.PropArch.ESType, CorrectESType, EPS06);
FooPass(12) = CheckTest(TestOut.Specs.Propulsion.PropArch.PSType, CorrectPSType, EPS06);

% check that all tests passed
if (~any(FooPass))
    
    % one or more of the tests failed
    Pass(itest) = 0;
    
else
    
    % all tests passed
    Pass(itest) = 1;
    
end

% increment the test number
itest = itest + 1;


%% CASE 2C: ELECTRIC, 3 ENGINES, TURBOFAN %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% setup the inputs           %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% set the architecture
TestIn.Specs.Propulsion.Arch.Type = "E";

% set the number of engines
TestIn.Specs.Propulsion.NumEngines = 3;

% change the aircraft class
TestIn.Specs.TLAR.Class = "Turbofan";

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% run the test               %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% create the propulsion architecture
TestOut = PropulsionPkg.CreatePropArch(TestIn);

% remember the correct architecture matrices
CorrectTSPS = eye( 3   );
CorrectPSPS = eye( 3   );
CorrectPSES = ones(3, 1);

% check the architecture matrices
FooPass( 1) = CheckTest(TestOut.Specs.Propulsion.PropArch.TSPS, CorrectTSPS, EPS06);
FooPass( 2) = CheckTest(TestOut.Specs.Propulsion.PropArch.PSPS, CorrectPSPS, EPS06);
FooPass( 3) = CheckTest(TestOut.Specs.Propulsion.PropArch.PSES, CorrectPSES, EPS06);

% remember the correct operational matrix for thrust splits
CorrectTS = repmat(1/3, 1, 3);

% check the operational matrices (same as architecture matrices)
FooPass( 4) = CheckTest(TestOut.Specs.Propulsion.Oper.TS(  ), CorrectTS  , EPS06);
FooPass( 5) = CheckTest(TestOut.Specs.Propulsion.Oper.TSPS(), CorrectTSPS, EPS06);
FooPass( 6) = CheckTest(TestOut.Specs.Propulsion.Oper.PSPS(), CorrectPSPS, EPS06);
FooPass( 7) = CheckTest(TestOut.Specs.Propulsion.Oper.PSES(), CorrectPSES, EPS06);

% remember the correct efficiency matrices
CorrectTSPS = ones(3   );
CorrectPSPS = ones(3   );
CorrectPSES = repmat(EtaEM, 3, 1);

% check the efficiency matrices (propeller aircraft)
FooPass( 8) = CheckTest(TestOut.Specs.Propulsion.Eta.TSPS, CorrectTSPS, EPS06);
FooPass( 9) = CheckTest(TestOut.Specs.Propulsion.Eta.PSPS, CorrectPSPS, EPS06);
FooPass(10) = CheckTest(TestOut.Specs.Propulsion.Eta.PSES, CorrectPSES, EPS06);

% correct energy and power source types
CorrectESType =       0    ;
CorrectPSType = zeros(1, 3);

% check the energy and power source types
FooPass(11) = CheckTest(TestOut.Specs.Propulsion.PropArch.ESType, CorrectESType, EPS06);
FooPass(12) = CheckTest(TestOut.Specs.Propulsion.PropArch.PSType, CorrectPSType, EPS06);

% check that all tests passed
if (~any(FooPass))
    
    % one or more of the tests failed
    Pass(itest) = 0;
    
else
    
    % all tests passed
    Pass(itest) = 1;
    
end

% increment the test number
itest = itest + 1;


%% CASE 3A: PARALLEL HYBRID, 2 ENGINES %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% setup the inputs           %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% set the architecture
TestIn.Specs.Propulsion.Arch.Type = "PHE";

% set the number of engines
TestIn.Specs.Propulsion.NumEngines = 2;

% reset the aircraft class
TestIn.Specs.TLAR.Class = "Turboprop";

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% run the test               %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% create the propulsion architecture
TestOut = PropulsionPkg.CreatePropArch(TestIn);

% remember the correct architecture matrices
CorrectTSPS = repmat(eye(2), 1, 2);
CorrectPSPS = eye(4);
CorrectPSES = [ones(2, 1), zeros(2, 1); zeros(2, 1), ones(2, 1)];

% check the architecture matrices
FooPass( 1) = CheckTest(TestOut.Specs.Propulsion.PropArch.TSPS, CorrectTSPS, EPS06);
FooPass( 2) = CheckTest(TestOut.Specs.Propulsion.PropArch.PSPS, CorrectPSPS, EPS06);
FooPass( 3) = CheckTest(TestOut.Specs.Propulsion.PropArch.PSES, CorrectPSES, EPS06);

% use an arbitrary power split
Lambda = 0.07;

% remember the correct operational matrices
CorrectTS   = repmat(0.5, 1, 2);
CorrectTSPS = [1 - Lambda, 0, Lambda, 0; 0, 1 - Lambda, 0, Lambda];

% check the operational matrices (same as architecture matrices)
FooPass( 4) = CheckTest(TestOut.Specs.Propulsion.Oper.TS(        ), CorrectTS  , EPS06);
FooPass( 5) = CheckTest(TestOut.Specs.Propulsion.Oper.TSPS(Lambda), CorrectTSPS, EPS06);
FooPass( 6) = CheckTest(TestOut.Specs.Propulsion.Oper.PSPS(      ), CorrectPSPS, EPS06);
FooPass( 7) = CheckTest(TestOut.Specs.Propulsion.Oper.PSES(      ), CorrectPSES, EPS06);

% remember the correct efficiency matrices
CorrectTSPS = ones(2, 4) - (1 - EtaProp) .* repmat(eye(2), 1, 2);
CorrectPSPS = ones(4   ) ;
CorrectPSES = [ones(2, 2); ones(2, 1) , repmat(EtaEM, 2, 1)];

% check the efficiency matrices (propeller aircraft)
FooPass( 8) = CheckTest(TestOut.Specs.Propulsion.Eta.TSPS, CorrectTSPS, EPS06);
FooPass( 9) = CheckTest(TestOut.Specs.Propulsion.Eta.PSPS, CorrectPSPS, EPS06);
FooPass(10) = CheckTest(TestOut.Specs.Propulsion.Eta.PSES, CorrectPSES, EPS06);

% correct energy and power source types
CorrectESType = [1, 0];
CorrectPSType = [ones(1, 2), zeros(1, 2)];

% check the energy and power source types
FooPass(11) = CheckTest(TestOut.Specs.Propulsion.PropArch.ESType, CorrectESType, EPS06);
FooPass(12) = CheckTest(TestOut.Specs.Propulsion.PropArch.PSType, CorrectPSType, EPS06);

% check that all tests passed
if (~any(FooPass))
    
    % one or more of the tests failed
    Pass(itest) = 0;
    
else
    
    % all tests passed
    Pass(itest) = 1;
    
end

% increment the test number
itest = itest + 1;


%% CASE 3B: PARALLEL HYBRID, 3 ENGINES %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% setup the inputs           %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% set the architecture
TestIn.Specs.Propulsion.Arch.Type = "PHE";

% set the number of engines
TestIn.Specs.Propulsion.NumEngines = 3;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% run the test               %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% create the propulsion architecture
TestOut = PropulsionPkg.CreatePropArch(TestIn);

% remember the correct architecture matrices
CorrectTSPS = repmat(eye(3), 1, 2);
CorrectPSPS = eye(6);
CorrectPSES = [ones(3, 1), zeros(3, 1); zeros(3, 1), ones(3, 1)];

% check the architecture matrices
FooPass( 1) = CheckTest(TestOut.Specs.Propulsion.PropArch.TSPS, CorrectTSPS, EPS06);
FooPass( 2) = CheckTest(TestOut.Specs.Propulsion.PropArch.PSPS, CorrectPSPS, EPS06);
FooPass( 3) = CheckTest(TestOut.Specs.Propulsion.PropArch.PSES, CorrectPSES, EPS06);

% remember the correct operational matrix for thrust splits
CorrectTS   = repmat(1/3, 1, 3);
CorrectTSPS = [1 - Lambda, 0, 0, Lambda, 0, 0 ; ...
               0, 1 - Lambda, 0, 0, Lambda, 0 ; ...
               0, 0, 1 - Lambda, 0, 0, Lambda];

% check the operational matrices
FooPass( 4) = CheckTest(TestOut.Specs.Propulsion.Oper.TS(        ), CorrectTS  , EPS06);
FooPass( 5) = CheckTest(TestOut.Specs.Propulsion.Oper.TSPS(Lambda), CorrectTSPS, EPS06);
FooPass( 6) = CheckTest(TestOut.Specs.Propulsion.Oper.PSPS(      ), CorrectPSPS, EPS06);
FooPass( 7) = CheckTest(TestOut.Specs.Propulsion.Oper.PSES(      ), CorrectPSES, EPS06);

% remember the correct efficiency matrices
CorrectTSPS = ones(3, 6) - (1 - EtaProp) .* repmat(eye(3), 1, 2);
CorrectPSPS = ones(6   ) ;
CorrectPSES = [ones(3, 2); ones(3, 1) , repmat(EtaEM, 3, 1)];

% check the efficiency matrices (propeller aircraft)
FooPass( 8) = CheckTest(TestOut.Specs.Propulsion.Eta.TSPS, CorrectTSPS, EPS06);
FooPass( 9) = CheckTest(TestOut.Specs.Propulsion.Eta.PSPS, CorrectPSPS, EPS06);
FooPass(10) = CheckTest(TestOut.Specs.Propulsion.Eta.PSES, CorrectPSES, EPS06);

% correct energy and power source types
CorrectESType = [1, 0];
CorrectPSType = [ones(1, 3), zeros(1, 3)];

% check the energy and power source types
FooPass(11) = CheckTest(TestOut.Specs.Propulsion.PropArch.ESType, CorrectESType, EPS06);
FooPass(12) = CheckTest(TestOut.Specs.Propulsion.PropArch.PSType, CorrectPSType, EPS06);

% check that all tests passed
if (~any(FooPass))
    
    % one or more of the tests failed
    Pass(itest) = 0;
    
else
    
    % all tests passed
    Pass(itest) = 1;
    
end

% increment the test number
itest = itest + 1;


%% CASE 3C: PARALLEL HYBRID, 3 ENGINES, TURBOFAN %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% setup the inputs           %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% set the architecture
TestIn.Specs.Propulsion.Arch.Type = "PHE";

% set the number of engines
TestIn.Specs.Propulsion.NumEngines = 3;

% change the aircraft class
TestIn.Specs.TLAR.Class = "Turbofan";

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% run the test               %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% create the propulsion architecture
TestOut = PropulsionPkg.CreatePropArch(TestIn);

% remember the correct architecture matrices
CorrectTSPS = repmat(eye(3), 1, 2);
CorrectPSPS = eye(6);
CorrectPSES = [ones(3, 1), zeros(3, 1); zeros(3, 1), ones(3, 1)];

% check the architecture matrices
FooPass( 1) = CheckTest(TestOut.Specs.Propulsion.PropArch.TSPS, CorrectTSPS, EPS06);
FooPass( 2) = CheckTest(TestOut.Specs.Propulsion.PropArch.PSPS, CorrectPSPS, EPS06);
FooPass( 3) = CheckTest(TestOut.Specs.Propulsion.PropArch.PSES, CorrectPSES, EPS06);

% remember the correct operational matrix for thrust splits
CorrectTS   = repmat(1/3, 1, 3);
CorrectTSPS = [1 - Lambda, 0, 0, Lambda, 0, 0 ; ...
               0, 1 - Lambda, 0, 0, Lambda, 0 ; ...
               0, 0, 1 - Lambda, 0, 0, Lambda];

% check the operational matrices (same as architecture matrices)
FooPass( 4) = CheckTest(TestOut.Specs.Propulsion.Oper.TS(        ), CorrectTS  , EPS06);
FooPass( 5) = CheckTest(TestOut.Specs.Propulsion.Oper.TSPS(Lambda), CorrectTSPS, EPS06);
FooPass( 6) = CheckTest(TestOut.Specs.Propulsion.Oper.PSPS(      ), CorrectPSPS, EPS06);
FooPass( 7) = CheckTest(TestOut.Specs.Propulsion.Oper.PSES(      ), CorrectPSES, EPS06);

% remember the correct efficiency matrices
CorrectTSPS = ones(3, 6) ;
CorrectPSPS = ones(6   ) ;
CorrectPSES = [ones(3, 2); ones(3, 1) , repmat(EtaEM, 3, 1)];

% check the efficiency matrices (propeller aircraft)
FooPass( 8) = CheckTest(TestOut.Specs.Propulsion.Eta.TSPS, CorrectTSPS, EPS06);
FooPass( 9) = CheckTest(TestOut.Specs.Propulsion.Eta.PSPS, CorrectPSPS, EPS06);
FooPass(10) = CheckTest(TestOut.Specs.Propulsion.Eta.PSES, CorrectPSES, EPS06);

% correct energy and power source types
CorrectESType = [1, 0];
CorrectPSType = [ones(1, 3), zeros(1, 3)];

% check the energy and power source types
FooPass(11) = CheckTest(TestOut.Specs.Propulsion.PropArch.ESType, CorrectESType, EPS06);
FooPass(12) = CheckTest(TestOut.Specs.Propulsion.PropArch.PSType, CorrectPSType, EPS06);

% check that all tests passed
if (~any(FooPass))
    
    % one or more of the tests failed
    Pass(itest) = 0;
    
else
    
    % all tests passed
    Pass(itest) = 1;
    
end

% increment the test number
itest = itest + 1;


%% CASE 4A: SERIES HYBRID, 2 ENGINES %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% setup the inputs           %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% set the architecture
TestIn.Specs.Propulsion.Arch.Type = "SHE";

% set the number of engines
TestIn.Specs.Propulsion.NumEngines = 2;

% reset the aircraft class
TestIn.Specs.TLAR.Class = "Turboprop";

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% run the test               %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% create the propulsion architecture
TestOut = PropulsionPkg.CreatePropArch(TestIn);

% remember the correct architecture matrices
CorrectTSPS = [zeros(2), eye(2)];
CorrectPSPS = [eye(2), zeros(2); repmat(eye(2), 1, 2)];
CorrectPSES = [ones(2, 1), zeros(2, 1); zeros(2, 1), ones(2, 1)];

% check the architecture matrices
FooPass( 1) = CheckTest(TestOut.Specs.Propulsion.PropArch.TSPS, CorrectTSPS, EPS06);
FooPass( 2) = CheckTest(TestOut.Specs.Propulsion.PropArch.PSPS, CorrectPSPS, EPS06);
FooPass( 3) = CheckTest(TestOut.Specs.Propulsion.PropArch.PSES, CorrectPSES, EPS06);

% use an arbitrary power split
Lambda = 0.07;

% remember the correct operational matrices
CorrectTS   = repmat(0.5, 1, 2);
CorrectPSPS = [eye(2), zeros(2); (1 - Lambda) .* eye(2), eye(2)];
CorrectPSES = [ones(2, 1), zeros(2, 1); zeros(2, 1), repmat(Lambda, 2, 1)];

% check the operational matrices (same as architecture matrices)
FooPass( 4) = CheckTest(TestOut.Specs.Propulsion.Oper.TS(        ), CorrectTS  , EPS06);
FooPass( 5) = CheckTest(TestOut.Specs.Propulsion.Oper.TSPS(      ), CorrectTSPS, EPS06);
FooPass( 6) = CheckTest(TestOut.Specs.Propulsion.Oper.PSPS(Lambda), CorrectPSPS, EPS06);
FooPass( 7) = CheckTest(TestOut.Specs.Propulsion.Oper.PSES(Lambda), CorrectPSES, EPS06);

% remember the correct efficiency matrices
CorrectTSPS = ones(2, 4) + [zeros(2), (EtaProp - 1) .* eye(2)];
CorrectPSPS = ones(4   ) ;
CorrectPSES = [ones(2, 2); ones(2, 1) , repmat(EtaEM, 2, 1)];

% check the efficiency matrices (propeller aircraft)
FooPass( 8) = CheckTest(TestOut.Specs.Propulsion.Eta.TSPS, CorrectTSPS, EPS06);
FooPass( 9) = CheckTest(TestOut.Specs.Propulsion.Eta.PSPS, CorrectPSPS, EPS06);
FooPass(10) = CheckTest(TestOut.Specs.Propulsion.Eta.PSES, CorrectPSES, EPS06);

% correct energy and power source types
CorrectESType = [1, 0];
CorrectPSType = [ones(1, 2), zeros(1, 2)];

% check the energy and power source types
FooPass(11) = CheckTest(TestOut.Specs.Propulsion.PropArch.ESType, CorrectESType, EPS06);
FooPass(12) = CheckTest(TestOut.Specs.Propulsion.PropArch.PSType, CorrectPSType, EPS06);

% check that all tests passed
if (~any(FooPass))
    
    % one or more of the tests failed
    Pass(itest) = 0;
    
else
    
    % all tests passed
    Pass(itest) = 1;
    
end

% increment the test number
itest = itest + 1;


%% CASE 4B: SERIES HYBRID, 3 ENGINES %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% setup the inputs           %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% set the architecture
TestIn.Specs.Propulsion.Arch.Type = "SHE";

% set the number of engines
TestIn.Specs.Propulsion.NumEngines = 3;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% run the test               %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% create the propulsion architecture
TestOut = PropulsionPkg.CreatePropArch(TestIn);

% remember the correct architecture matrices
CorrectTSPS = [zeros(3), eye(3)];
CorrectPSPS = [eye(3), zeros(3); repmat(eye(3), 1, 2)];
CorrectPSES = [ones(3, 1), zeros(3, 1); zeros(3, 1), ones(3, 1)];

% check the architecture matrices
FooPass( 1) = CheckTest(TestOut.Specs.Propulsion.PropArch.TSPS, CorrectTSPS, EPS06);
FooPass( 2) = CheckTest(TestOut.Specs.Propulsion.PropArch.PSPS, CorrectPSPS, EPS06);
FooPass( 3) = CheckTest(TestOut.Specs.Propulsion.PropArch.PSES, CorrectPSES, EPS06);

% remember the correct operational matrix for thrust splits
CorrectTS   = repmat(1/3, 1, 3);
CorrectPSPS = [eye(3), zeros(3); (1 - Lambda) .* eye(3), eye(3)];
CorrectPSES = [ones(3, 1), zeros(3, 1); zeros(3, 1), repmat(Lambda, 3, 1)];

% check the operational matrices
FooPass( 4) = CheckTest(TestOut.Specs.Propulsion.Oper.TS(        ), CorrectTS  , EPS06);
FooPass( 5) = CheckTest(TestOut.Specs.Propulsion.Oper.TSPS(      ), CorrectTSPS, EPS06);
FooPass( 6) = CheckTest(TestOut.Specs.Propulsion.Oper.PSPS(Lambda), CorrectPSPS, EPS06);
FooPass( 7) = CheckTest(TestOut.Specs.Propulsion.Oper.PSES(Lambda), CorrectPSES, EPS06);

% remember the correct efficiency matrices
CorrectTSPS = ones(3, 6) + [zeros(3), (EtaProp - 1) .* eye(3)];
CorrectPSPS = ones(6   ) ;
CorrectPSES = [ones(3, 2); ones(3, 1) , repmat(EtaEM, 3, 1)];

% check the efficiency matrices (propeller aircraft)
FooPass( 8) = CheckTest(TestOut.Specs.Propulsion.Eta.TSPS, CorrectTSPS, EPS06);
FooPass( 9) = CheckTest(TestOut.Specs.Propulsion.Eta.PSPS, CorrectPSPS, EPS06);
FooPass(10) = CheckTest(TestOut.Specs.Propulsion.Eta.PSES, CorrectPSES, EPS06);

% correct energy and power source types
CorrectESType = [1, 0];
CorrectPSType = [ones(1, 3), zeros(1, 3)];

% check the energy and power source types
FooPass(11) = CheckTest(TestOut.Specs.Propulsion.PropArch.ESType, CorrectESType, EPS06);
FooPass(12) = CheckTest(TestOut.Specs.Propulsion.PropArch.PSType, CorrectPSType, EPS06);

% check that all tests passed
if (~any(FooPass))
    
    % one or more of the tests failed
    Pass(itest) = 0;
    
else
    
    % all tests passed
    Pass(itest) = 1;
    
end

% increment the test number
itest = itest + 1;


%% CASE 4C: SERIES HYBRID, 3 ENGINES, TURBOFAN %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% setup the inputs           %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% set the architecture
TestIn.Specs.Propulsion.Arch.Type = "SHE";

% set the number of engines
TestIn.Specs.Propulsion.NumEngines = 3;

% change the aircraft class
TestIn.Specs.TLAR.Class = "Turbofan";

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% run the test               %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% create the propulsion architecture
TestOut = PropulsionPkg.CreatePropArch(TestIn);

% remember the correct architecture matrices
CorrectTSPS = [zeros(3), eye(3)];
CorrectPSPS = [eye(3), zeros(3); repmat(eye(3), 1, 2)];
CorrectPSES = [ones(3, 1), zeros(3, 1); zeros(3, 1), ones(3, 1)];

% check the architecture matrices
FooPass( 1) = CheckTest(TestOut.Specs.Propulsion.PropArch.TSPS, CorrectTSPS, EPS06);
FooPass( 2) = CheckTest(TestOut.Specs.Propulsion.PropArch.PSPS, CorrectPSPS, EPS06);
FooPass( 3) = CheckTest(TestOut.Specs.Propulsion.PropArch.PSES, CorrectPSES, EPS06);

% remember the correct operational matrix for thrust splits
CorrectTS   = repmat(1/3, 1, 3);
CorrectPSPS = [eye(3), zeros(3); (1 - Lambda) .* eye(3), eye(3)];
CorrectPSES = [ones(3, 1), zeros(3, 1); zeros(3, 1), repmat(Lambda, 3, 1)];

% check the operational matrices (same as architecture matrices)
FooPass( 4) = CheckTest(TestOut.Specs.Propulsion.Oper.TS(        ), CorrectTS  , EPS06);
FooPass( 5) = CheckTest(TestOut.Specs.Propulsion.Oper.TSPS(      ), CorrectTSPS, EPS06);
FooPass( 6) = CheckTest(TestOut.Specs.Propulsion.Oper.PSPS(Lambda), CorrectPSPS, EPS06);
FooPass( 7) = CheckTest(TestOut.Specs.Propulsion.Oper.PSES(Lambda), CorrectPSES, EPS06);

% remember the correct efficiency matrices
CorrectTSPS = ones(3, 6) ;
CorrectPSPS = ones(6   ) ;
CorrectPSES = [ones(3, 2); ones(3, 1) , repmat(EtaEM, 3, 1)];

% check the efficiency matrices (propeller aircraft)
FooPass( 8) = CheckTest(TestOut.Specs.Propulsion.Eta.TSPS, CorrectTSPS, EPS06);
FooPass( 9) = CheckTest(TestOut.Specs.Propulsion.Eta.PSPS, CorrectPSPS, EPS06);
FooPass(10) = CheckTest(TestOut.Specs.Propulsion.Eta.PSES, CorrectPSES, EPS06);

% correct energy and power source types
CorrectESType = [1, 0];
CorrectPSType = [ones(1, 3), zeros(1, 3)];

% check the energy and power source types
FooPass(11) = CheckTest(TestOut.Specs.Propulsion.PropArch.ESType, CorrectESType, EPS06);
FooPass(12) = CheckTest(TestOut.Specs.Propulsion.PropArch.PSType, CorrectPSType, EPS06);

% check that all tests passed
if (~any(FooPass))
    
    % one or more of the tests failed
    Pass(itest) = 0;
    
else
    
    % all tests passed
    Pass(itest) = 1;
    
end

% increment the test number
itest = itest + 1;


%% CHECK THE TEST RESULTS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% identify any tests that failed
itest = find(~Pass);

% check whether any tests failed
if (isempty(itest))
    
    % all tests passed
    fprintf(1, "CreatePropArch tests passed!\n");
    
    % return success
    Success = 1;
    
else
    
    % print out header
    fprintf(1, "CreatePropArch tests failed:\n");
    
    % print which tests failed
    fprintf(1, "    Test %d\n", itest);
    
    % return failure
    Success = 0;
    
end

% ----------------------------------------------------------

end

% ----------------------------------------------------------
% ----------------------------------------------------------
% ----------------------------------------------------------

function [Pass] = CheckTest(TestValue, TrueValue, Tol)
%
% [Pass] = CheckTest(TestValue, TrueValue, Tol)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 27 jun 2024
%
% Helper function to check if a test passed.
%
% INPUTS:
%     TestValue - array of the returned values from the function.
%                 size/type/units: m-by-n / double / []
%
%     TrueValue - array of the expected values output from the function.
%                 size/type/units: m-by-n / double / []
%
%     Tol       - acceptable relative tolerance between the test and true
%                 values.
%                 size/type/units: 1-by-1 / double / []
%
% OUTPUTS:
%     Pass      - flag to show whether the test passed (1) or not (0)
%

% compute the relative tolerance
RelTol = abs(TestValue - TrueValue) ./ TrueValue;

% if dividing by zero, check for NaN or Inf
RelTol(isnan(RelTol)) = 0;
RelTol(isinf(RelTol)) = 0;

% check the tolerance
if (any(RelTol > Tol))
    
    % the test fails
    Pass = 0;
    
else
    
    % the test passes
    Pass = 1;
    
end

% ----------------------------------------------------------

end