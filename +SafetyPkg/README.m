function [] = README()
%
% Copyright 2024 The Regents of the University of Michigan,
% The Integrated Design of Efficient Aerospace Systems
% Laboratory
% 
% Safety Package (+SafetyPkg)
%
% Written by the IDEAS Lab at the University of Michigan. 
% https://ideas.engin.umich.edu
%
% Principal Authors: 
%     Paul Mokotoff, prmoko@umich.edu
%     Max Arnson, marnson@umich.edu
%
% Principal Investigator: 
%     Dr. Gokcin Cinar, cinar@umich.edu
%
% Additional Contributors: 
%     Huseyin Acar
%     Yi-Chih (Arenas) Wang
%     Miranda Stockhausen
%     Emma Cassidy
%     Nawa Khailany
%     Janki Patel
%     Michael Tsai
%     Vaibhav Rau
% 
% README last updated: 06 Oct 2025
% 
% -------------------------------------------------------------------------
%
% (I) Overview
%
% The SafetyPkg allows users to execute a fault tree analysis (FTA) on a
% system architecture. The FTA identifies minimum combinations of
% components required to cause a system-level failure in the system
% architecture.
%
% This package includes only the analysis and does not include any FT
% plotting capabilities. However, this may be added in a future release or
% upon request. Additionally, since FAST is open-source, a user could
% create their own plotting routines.
%
% -------------------------------------------------------------------------
%
% (II) Using this Package
%
% The FTA requires two key inputs: 1) an architecture matrix, describing
% the connections between components; and 2) a data structure describing
% the components in the system architecture, their failure probabilities, 
% and their failure modes.
%
% -------------------------------------------------------------------------
%
% (II.A) Architecture Matrix
%
% The architecture matrix is an n-by-n matrix describing the connections
% between components, where n is the number of components in the system
% architecture. Entries in the architecture matrix may be a zero 
% (indicating no connection between components) or a positive integer
% (indicating that a connection exists between components). More
% information about which positive integer to use is discussed shortly.
%
% To learn more about constructing an architecture matrix, please refer to
% the following paper:
%
% Mokotoff, P. R., & Cinar, G. (2025). A Graph-based Framework for Advanced
% Aircraft Propulsion System Analysis. Aerospace Science and Technology,
% 110798. https://doi.org/10.1016/j.ast.2025.110798
%
% For example, using a simple system architecture:
%
%            ---> B --->
%           /           \
%     A --->             ---> D
%           \           /
%            ---> C --->
%
% the archtiecture matrix is:
%
%          (A)   (B)   (C)   (D)
%         [ 0     1     1     0] (A)
%     A = [ 0     0     0     1] (B)
%         [ 0     0     0     1] (C)
%         [ 0     0     0     0] (D)
%
% However, there is a small complication when defining an architecture
% matrix for a FTA. The values in each column must match the number of
% components that must fail in order for the system-level failure mode to
% be triggered.
%
% In the previous example, the entries in the fourth column are 1. This
% means that Component D fails if 1 downstream component fails - either
% Component B or C. If both components must fail to cause a failure in
% Component D, then the architecture matrix is:
%
%          (A)   (B)   (C)   (D)
%         [ 0     1     1     0] (A)
%     A = [ 0     0     0     2] (B)
%         [ 0     0     0     2] (C)
%         [ 0     0     0     0] (D)
%
% This concept can be expanded for more complicated systems and component
% connections.
%
% -------------------------------------------------------------------------
%
% (II. B) Data Structure
%
% The data structure fields must be formatted as n-by-1 arrays, where n is
% the number of components in the system architecture. Three fields are
% necessary:
%
%     1) Name     - the name of the components, as a cell array of
%                   characters.
%
%     2) FailMode - the failure mode for the component, as a cell array of
%                   characters. If there is no failure mode for a given
%                   component, input an empty character ('').
%
%     3) FailRate - the failure probability per flight for an internal
%                   failure, as a doublearray. If there is no failure mode
%                   for a given component, input 0.
%
% -------------------------------------------------------------------------
%
% (III) Additional Capabilities
%
% Aside from its core FTA capabilities, the SafetyPkg also contains a
% component database that lists the failure rates for components that could
% be included in an electrified propulsion system. Though this is not
% coupled into the FTA, it could be useful for identifying reasonable
% failure rates for unknown components. See the "ComponentDatabase.m"
% function for this capability.
%
% Additionally, for components with time-varying failure rates, the
% "FailureModel.m" function allows a user to input a failure probability
% and exposure time to determine the probability that the component fails.
%
% The "FailureModel.m" function assumes that the component has a constant
% failure rate and that the reliability of the component is represented by
% an exponential distribution. See Nikolaos Limnios' book on Fault Trees
% (IBSN: 978-1-905209-30-9) for more information.
%
% -------------------------------------------------------------------------
%
% end SafetyPkg.README
%
end