"""

FASTPropulsionModules.py
written by Max Arnson, marnson@umich.edu
last updated: 02 oct 2024

Provide the components for an N2 diagram to be made.

INPUTS : none
OUTPUTS: none

"""


# ----------------------------------------------------------


##############################
#                            #
# IMPORT PACKAGES            #
#                            #
##############################

# import OpenMDAO
import openmdao.api as om

# ----------------------------------------------------------


##############################
#                            #
# Initialization CLASS       #
#                            #
##############################

class Initialization(om.ExplicitComponent):
    """
    
    Initialization:

    User inputted files and values in addition to those from the aircraft sizing code.

    """

    def setup(self):
        self.add_input("UserInput")
        self.add_input("AircraftSizing")
        self.add_input("RunSettings")
        self.add_output("FlightConditions")
        self.add_output("PerformanceRequirement")
        self.add_output("DesignParameters")


    # end setup
# end Initialization

# ----------------------------------------------------------

##############################
#                            #
# EngineFunction CLASS       #
#                            #
##############################

class EngineFunction(om.ExplicitComponent):
    """
    
    EngineFunction:

    Engine function takes in inputs and outputs a spec function.

    """

    def setup(self):
        self.add_input("FlightConditions")
        self.add_input("PerformanceRequirement")
        self.add_input("DesignParameters")
        self.add_output("Specifications")


    # end setup
# end EngineFunction

# ----------------------------------------------------------


##############################
#                            #
# ThermodynamicCycle CLASS   #
#                            #
##############################

class ThermodynamicCycle(om.ExplicitComponent):
    """
    
    ThermodynamicCycle:

    User inputted files and values in addition to those from the aircraft sizing code.

    """

    def setup(self):
        self.add_input("Specifications")
        self.add_input("AirMassFlow")
        self.add_output("Performance")
        self.add_output("SizedEngine")
    # end setup
# end ThermodynamicCycle

# ----------------------------------------------------------


##############################
#                            #
# Iteration CLASS            #
#                            #
##############################

class Iteration(om.ExplicitComponent):
    """
    
    Iteration:

    Iterate on Mass Flow rate depending on thrust or power production.

    """

    def setup(self):
        self.add_input("Performance")
        self.add_output("MassFlowUpdate")
    # end setup
# end Iteration

# ----------------------------------------------------------


##############################
#                            #
# Outputs CLASS              #
#                            #
##############################

class Outputs(om.ExplicitComponent):
    """
    
    Outputs:

    Outputs outside of the propulsion system.

    """

    def setup(self):
        self.add_input("SizedEngine")
        self.add_output("Performance")
        self.add_output("Fuel Consumption")
        self.add_output("WeightEstimate")
        self.add_output("Geometry")
    # end setup
# end Outputs
