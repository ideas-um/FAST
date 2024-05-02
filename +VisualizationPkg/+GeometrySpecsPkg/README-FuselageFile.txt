Visualization Add-On for the Future Aircraft Sizing Tool (FAST)

Written by: Nawa Khailany, nawakhai@umich.edu
            Paul Mokotoff, prmoko@umich.edu

Last Updated: 2/29/2024

-------------------------------------------------------------------

Fuselage File:
--------------

In order for an aircraft's fuselage to be drawn, a file specifying
the fuselage cross-sections, their position, and their shape must be
provided. There are two parts to the file:

    (1) a header section to provide high-level parameters about the
        fuselage configruation provided.

    (2) a cross-section specificiation portion, in which the
        superellipses making up the fuselage are prescribed. This
        portion of the file must be repeated for however many
        superellipses are needed to make the fuselage (without
        any vertical space, for current file formatting purposes).

        For more information about superellipses, see the README
        file located in the VisualizationPkg folder.

An example file (bounded by the lines of "======") is presented
below with parameter names instead of numerical values. The
parameters will be explained after the example file is shared.

==============================|
x1=NoseEnd                    | --> header from (1)
x2=TailBeg                    | --> header from (1)
TLength=FuseLen               | --> header from (1)
SuperEllipseNum=nsupell       | --> header from (1)
                              | --> required blank line
SupellName                    | --> superellipse specification from (2)
r_n r_w r_s r_e               | --> superellipse specification from (2)
n_ne n_nw n_sw n_se           | --> superellipse specification from (2)
xcent ycent zcent             | --> superellipse specification from (2)
ViewSelection                 | --> superellipse specification from (2)
==============================|

--------------------------------------------------------------------

Fuselage File Parameters:
-------------------------

For the header section, there are four parameters that the user must
specify:

    (1) NoseEnd: the location that the nose ends and the cabin (to
                 hold the payload) begins.

    (2) TailBeg: the location that the tail begins and the cabin
                 ends.

    (3) FuseLen: the total length of the fuselage prescribed in this
                 configuration (and can be different from the
                 .Length parameter prescribed in the geometry
                 specification file).

    (4) nsupell: the number of superellipses to be described in the
                 remainder of the file.

The NoseEnd and TailBeg parameters are required because the geometry
code does not change the shape and size of the nose or tailcone; it
only changes the length/size of the cabin by scaling it up/down.
This is done to maintain the aircraft's nominal shape while allowing
flexibility to use one geometry for multiple payload configurations.
That way, the user can specify one fuselage configuration, but
modify the .Length parameter provided in the geometry specification
file only (without modifying the fuselage specifications).

For the cross-section specification, thirteen pieces of information
are needed:

    ( 1) SupellName: the name of the superellipse, which is provided
                     for convenience. The geometry creation code
                     will not use the SupellName at all, but must be
                     provided (for file formatting purposes).

    ( 2) r_n: northern radius of the superellipse.

    ( 3) r_w:  western radius of the superellipse.

    ( 4) r_s: southern radius of the superellipse.

    ( 5) r_e:  eastern radius of the superellipse.

    ( 6) n_ne: northeastern power of the superellipse.

    ( 7) n_nw: northwestern power of the superellipse.

    ( 8) n_sw: southwestern power of the superellipse.

    ( 9) n_se: southeastern power of the superellipse.

    (10) xcent: x-location of the superellipse center.

    (10) ycent: y-location of the superellipse center.

    (12) zcent: z-location of the superellipse center.

    (13) ViewSelection: whether the superellipse should be displayed in
                        the front view (by inputting "FVIEW") or not
                        (by inputting "NOTFVIEW").

--------------------------------------------------------------------

Additional Examples:
--------------------

In the GeometrySpecsPkg (contained within the VisualizationPkg),
additional fuselage files can be found and used as examples. Two
recommended files are:

    (1) LM100J.dat: creates a fuselage for the LM100J.

    (2) TransportFuselage.dat: creates a fuselage for a single-aisle
                               transport aircraft.