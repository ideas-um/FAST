function [] = README()
% Visualization Add-On for the Future Aircraft Sizing Tool (FAST)
% 
% Written by: Nawa Khailany, nawakhai@umich.edu
%             Paul Mokotoff, prmoko@umich.edu
% 
% Last Updated: 29 Feb 2024
% 
% ----------------------------------------------------------------
% 
% Background:
% -----------
% 
% Visualizing aircraft geometries and powertrain architecture
% configurations is done by the VisualizationPkg within the FAST
% toolbox. The package is able to visualize an aircraft's
% aerodynamic surfaces, fuselage, and engines all created by the
% user. It can be run in "Standalone" Mode that allows the
% geometry to be visualized alone, or in "Integrated Mode" that
% intertwines the visuals with the sizing, allowing the user to
% visualize how changing an aircraft's parameters affects the
% design. Furthermore, the VisualizationPkg has the capability to
% visualize propulsion architectures specified by the user.
% 
% ----------------------------------------------------------------
% 
% Using the Package to Create Aircraft Geometries:
% ------------------------------------------------
% 
% The steps to using the VisualizationPkg to view aircraft are as
% follows:
% 
%     1) Create a geometry configuration or use a pre-existing
%        one in the +GeometrySpecsPkg. This will be inputted as a
%        function handle below. There are 3 types of components
%        that can be made consisting of 'liftingSurface', 
%        'bluntBody', and 'Engine'. Every component has different
%        parameters depending on this type.
% 
% 
%        There is no limit as to what and how many 
%        'liftingSurface' components a configutation has. The
%        'liftingSurface' components require the following inputs:
% 
%            ( 1) area: wing area
% 
%            ( 2) AR: wing aspect ratio
% 
%            ( 3) taper: taper ratio
% 
%            ( 4) sweep: quarter-chord sweep
% 
%            ( 5) dihedral: wing dihedral
% 
%            ( 6) xShiftWing: x-position at the midpoint of the
%                 root chord
% 
%            ( 7) yShiftWing: y-position at the midpoint of the
%                 root chord
% 
%            ( 8) zShiftWing: z-position at the midpoint of the
%                 root chord
% 
%            ( 9) symWing: a flag to mirror half of the wing
%                 (input 1) or not (input 0)
% 
%            (10) orientation: the plane to make the airfoil in
%                 (can either be 'xy', 'xz', or 'yz')
% 
%            (11) wingAfoil.airfoilName: a NACA 4-digit code (as
%                 characters or '0000' for a "thin" airfoil)
% 
%            (12) type: prescribe as a 'liftingSurface'
% 
% 
%        The 'bluntBody' are for fuselage-like components. The
%        'bluntBody' components require the following inputs:
% 
%            (1) Length: component length from end to end (this
%                length is in the "Standalone mode" and is
%                ignored in the "Integrated Mode")
% 
%            (2) type: prescribe as a 'bluntBody'
% 
%            (3) Style: component superellipse parameters in .dat
%                format
% 
% 
%        The 'Engine' components are for creating engines. While
%        they only take in one parameter, engines on the same
%        aircraft can be distinguished from each other using the
%        scale factors as described in the README-EngineFiles in
%        the GeometrySpecsPkg. The 'Engine' components require the
%        following inputs:
% 
%            (1): Length: length of the engine
% 
%            (2): EngineInletRadii: inlet radius of the the
%                 engine
% 
%            (3): EngineOutletRadii: outlet radius of the the
%                 engine
% 
%            (4): type: prescribe as an 'Engine'
% 
%            ( 5): Filename: Engine parameters in a .dat format
% 
% 
%        Refer to the LM100JNominalGeometry.m file in the
%        GeometrySpecsPkg folder for an example of how all these
%        parameters are used.
% 
% 
%        The user also needs to create a fuselage specification
%        file and engine specification file, or use one already
%        created by calling it for the 'Style' and 'Filename'
%        parameters of the Fuselage and Engine components,
%        respectively. Please refer to the README-FuselageFiles
%        and the README-EngineFiles in the +GeometrySpecsPkg on
%        how to create and manipulate these text files for
%        fuselage and engine creation. An example on how the
%        functions are called can be seen below (taken from the
%        LM100JNominalGeometry.m file in the +GeometrySpecsPkg
%        folder):
% 
%            Fuselage.Style  = '+VisualizationPkg\+GeometrySpecsPkg\LM100J.dat';
% 
%            Engine.Filename = '+VisualizationPkg\+GeometrySpecsPkg\LM100J_Engines.dat';
% 
% 
%     2a) In Standalone Mode, create a script that calls the
%         function handle of the configuration created followed by
%         a call to vGeometry.m. Refer to TestGeometry.m in the
%         +GeometryTestsPkg as an an example. Alternatively,
%         replace the aircraft configuration function call in
%         TestGeometry.m to view the geometry configuration
%         desired.
% 
%         An example script would look like:
% 	   
% 	    [Aircraft] = VisualizationPkg.GeometrySpecsPkg.LM100JNominalGeometry();
% 
%             [Aircraft, ~] = VisualizationPkg.vGeometry(Aircraft);
% 
% 
%     2b) To use Integrated Mode, specify "Aircraft.Preset" as the
%         desired configuration in the aircraft specification file
%         (all of which are found in the AircraftSpecsPkg folder)
%         of the aircraft being sized. If no preset is provided,
%         the tool will default to a single-aisle tube-and-wing
%         configuration. In addition, specify the length of the
%         aircraft fuselage if that information is known, or leave
%         it as NaN. If it is left as NaN, FAST will use a
%         regression relating the number of passengers to length
%         of the fuselage. To have the aircraft be plotted, set
%         Aircraft.Settings.VisualizeAircraft to 1 (or 0 to turn
%         it off). Refer to LM100J_Conventional.m in the
%         AircraftSpecsPkg folder to view an example.
% 
%         An example function call would look like:
% 
%             Aircraft.Preset = @(Aircraft)VisualizationPkg.GeometrySpecsPkg.LM100JNominalGeometry(Aircraft);
% 
%             Aircraft.LengthSet = 100.17;
% 
%         Then, run the Main function as done normally for
%         aircraft sizing.
% 
% ----------------------------------------------------------------
% 
% Using the Package to Visualize Propulsion Architectures:
% --------------------------------------------------------
% 
% The steps to using the VisualizationPkg to view propulsion 
% architectures are as follows:
% 
%     1) Specify B_PSES, B_PSPS, B_TSPS matrices in a .m file or
%        the command line.
% 
%     2) Use the following commands to view the architecture:
% 
%            Arch = VisualizationPkg.PropulsionArchitecture(B_PSES, B_PSPS, B_TSPS);
% 
%            VisualizationPkg.PlotArchitecture(Arch)
% 
%        where B_PSES, B_PSPS, and B_TSPS are the interdependency
%        matrices between the energy-power sources, power-power
%        sources, and power-thrust sources, respectively.
% 
% Refer to "+VisualizationPkg\+GeometryTestsPkg\PropArchTest.m" to
% view example propulsion architectures and how they are called.
% 
% ----------------------------------------------------------------
% 
% Notes and Disclaimers:
% ----------------------
% 
% 1) To run the visualization in "Integrated Mode", a 'Fuselage'
%    component must be specified. This is due to the fact that the
%    code requires knowing which component the fuselage is in
%    order to scale its length correctly.
% 
% 2) Superellipses are 2D shapes that are described by 4 radii
%    (eastern [r_e], northern [r_n], western [r_w], and southern
%    [r_s]) and powers (northeastern [n_ne], northwestern [n_nw],
%    southwestern [s_sw], and southeastern [n_se]). The radii
%    control the size of the superellipse (and must be scalars).
%    The powers control the curvature of the superellipse (and
%    must be greater than 0). An example superellipse is provided
%    below:
% 
% 
%                               r_n
%                               ___
%                              /   \
%                             /  ^  \
%                      n_nw  /   |   \  n_ne
%                           /    |    \
%                          /     |     \
%                    r_w  | <----+----> |  r_e
%                          \     |     /
%                           \    |    /
%                      n_sw  \   |   /  n_se
%                             \  v  /
%                              \___/
% 
%                               r_s
% 
%    An example .m file is also provided to show how superellipses
%    are plotted and generated. Run the following line of code to
%    see some example superellipses:
% 
%        VisualizationPkg.GeometryTestsPkg.SupellTests();
% 
%    Additionally, the parameters to generate the superellipses
%    are provided in
%    "+VisualizationPkg/+GeometryTestsPkg/SupellParams.m".
% 
% 3) The definition and use of the propulsion architecture
%    matrices to represent propulsion architectures is detailed in
%    the following journal paper:
% 
%    Cinar, G., Garcia, E., & Mavris, D. N. (2020). A framework
%    for electrified propulsion architecture and operation
%    analysis. Aircraft Engineering and Aerospace Technology,
%    92(5), 675-684.
% 
% 4) One of the propulsion architecture examples built in gives an
%    error in the plotting function. This does not mean that the
%    propulsion architecture visuals are improperly generated. It
%    is a bug caused by the function trying to generate non-
%    existent points due to a for-loop going past its bounds (and
%    will be fixed in a future release). Since the propulsion
%    architecture visualization runs separately from FAST, the
%    aircraft sizing code will not be impacted by this bug.
% 
% 5) Depending on the wing orientation, lifing surface components
%    may not look as expected based on the sweep provided. This
%    shows up most prominently for when components are not 'xz'.
%    To counter this, simply play around with the sweep in
%    Standalone Mode until the component looks as intended. (This
%    is a bug that is planned to be fixed in a future release.)
% 
% ----------------------------------------------------------------
% 
% end README
end

