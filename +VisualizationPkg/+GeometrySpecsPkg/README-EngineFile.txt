Visualization Add-On for the Future Aircraft Sizing Tool (FAST)

Written by: Nawa Khailany, nawakhai@umich.edu
            Paul Mokotoff, prmoko@umich.edu

Last Updated: 2/29/2024

-------------------------------------------------------------------

Engine File:
------------

In order for an aircraft's engines to be drawn, a file specifying
the engine types, their position, and their nominal size must be
provided. There are two parts to the file:

    (1) a header line indicating how many engines are in the
        configuration.

    (2) an engine specification portion, detailing the name,
        position, engine type, and nominal size for each engine.
        The engine specification portion must be repeated for
        however many engines are in the configruation (without
        any vertical space, for current file formatting purposes).

An example file (bounded by the lines of "======") is
presented below with parameter names instead of numerical values.
The parameters will be explained after the example file is shared.

==============================|
NumberOfEngines=neng          | --> header line from (1)
                              | --> required blank line
EngineName                    | --> engine specification from (2)
xloc yloc zloc                | --> engine specification from (2)
LSF RSF                       | --> engine specification from (2)
EngineType                    | --> engine specification from (2)
==============================|

--------------------------------------------------------------------

Engine File Parameters:
-----------------------

For the header line, there is only one parameter:

    (1) neng: the number of engines in the file that will be drawn.

For the engine specification, seven pieces of information are needed:

    (1) EngineName: the name of the engine, which is provided for 
                    user-convenience. The geometry creation code
                    will not use the EngineName at all, but must
                    be provided (for file formatting purposes).

    (2) xloc: the x-position of the center of the inlet (for a
              turbofan) or the center of the propeller (for a 
              turboprop).

    (3) yloc: the y-position of the center of the inlet (for a
              turbofan) or the center of the propeller (for a 
              turboprop).

    (4) zloc: the z-position of the center of the inlet (for a
              turbofan) or the center of the propeller (for a 
              turboprop).

    (5) LSF: a length scale factor, which scales the .Length value
             provided in the geometry specification file for the
             engines. This is useful if there are engines of a
             similar shape, but a different size.

    (6) RSF: a radius scale factor, which scales the
             .EngineInletRadii and .EngineOutletRadii values
             provided in the geometry specification file for the
             engines. Again, this is useful if there are engines of
             a similar shape, but a different size.

    (7) EngineType: the type of engine to be drawn. These can either
                    be "TURBOFAN" for turbofan engines, or
                    "TURBOPROP" for turboprop/piston engines.

--------------------------------------------------------------------

Additional Examples:
--------------------

In the GeometrySpecsPkg (contained within the VisualizationPkg),
additional engine files can be found and used as examples. Two
recommended files are:

    (1) LM100J_Engines.dat: creates four turboprop engines.

    (2) TransportEngines.dat: creates two turbofan engines.