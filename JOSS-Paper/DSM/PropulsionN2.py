"""

FASTN2.py
written by Max Arnson, marnson@umich.edu
last updated: 02 oct 2024

Create an N2 diagram for FAST's Propulsion Code.

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

# import the FAST modules
import FASTPropulsionModules as FPM

# ----------------------------------------------------------


##############################
#                            #
# FAST Prop CLASS            #
#                            #
##############################

class Propulsion(om.Group):
    """
    
    FAST:
    
    Show how all major code components are connected together.
    
    """

    def setup(self):
       
        # add the subsystems
        self.add_subsystem("Initialization", FPM.Initialization(), promotes_inputs = [("UserInput"), ("AircraftSizing"), ("RunSettings")])
        self.add_subsystem("EngineFunction", FPM.EngineFunction())
        self.add_subsystem("ThermodynamicCycle", FPM.ThermodynamicCycle())
        self.add_subsystem("Iteration",FPM.Iteration())
        self.add_subsystem("Outputs",FPM.Outputs())

        # make connections
        # connections
        self.connect("Initialization.FlightConditions",       "EngineFunction.FlightConditions",      )
        self.connect("Initialization.PerformanceRequirement", "EngineFunction.PerformanceRequirement",)
        self.connect("Initialization.DesignParameters",       "EngineFunction.DesignParameters",      )

        self.connect("EngineFunction.Specifications","ThermodynamicCycle.Specifications")
        self.connect("ThermodynamicCycle.Performance","Iteration.Performance")
        self.connect("ThermodynamicCycle.SizedEngine","Outputs.SizedEngine")

        self.connect("Iteration.MassFlowUpdate","ThermodynamicCycle.AirMassFlow")

    # end setup
# end FAST


# ----------------------------------------------------------


##############################
#                            #
# CREATE N2 DIAGRAM          #
#                            #
##############################

# initialize the OpenMDAO problem
Problem = om.Problem()

# get the model
Model = Problem.model

# set the inputs
Model.set_input_defaults("UserInput")
Model.set_input_defaults("AircraftSizing")
Model.set_input_defaults("RunSettings")

# add a subsystem
Model.add_subsystem("PropulsionModel", Propulsion(), promotes_inputs = [("UserInput"), ("AircraftSizing"), ("RunSettings")])

# setup the problem
Problem.setup()

# create the n2 diagram
om.n2(Problem)