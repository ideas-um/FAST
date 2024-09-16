"""

FASTN2.py
written by Paul Mokotoff, prmoko@umich.edu
last updated: 16 sep 2024

Create an N2 diagram for FAST.

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
import FASTModules as FM

# ----------------------------------------------------------


##############################
#                            #
# FAST CLASS                 #
#                            #
##############################

class FAST(om.Group):
    """
    
    FAST:
    
    Show how all major code components are connected together.
    
    """

    def setup(self):
       
        # add the subsystems
        self.add_subsystem("Initialization", FM.Initialization(), promotes_inputs = [("A/C_Specs"), ("Mission_Profile"), ("Run_Settings")], promotes_outputs = [("Processed_Specifications")])
        self.add_subsystem("Aircraft_Sizing", FM.AircraftSizing())

        # make connections
        self.connect("Initialization.Point_Performance_Parameters", ["Aircraft_Sizing.T/W_or_P/W", "Aircraft_Sizing.W/S"])
        self.connect("Aircraft_Sizing.MTOW", "Initialization.MTOW_Guess")
        self.connect("Initialization.Validated_Mission_Profile", ["Aircraft_Sizing.Mission_Profile", "Aircraft_Sizing.Mission_Targets"])
        self.connect("Initialization.Candidate_A/C_Design", ["Aircraft_Sizing.System_Voltage", "Aircraft_Sizing.Minimum_SOC", "Aircraft_Sizing.Gravimetric_Specific_Energy"])
        self.connect("Processed_Specifications", ["Aircraft_Sizing.OEW_Iteration.PropulsionOnDesign.EngineDesignConditions", "Aircraft_Sizing.OEW_Iteration.PropulsionOnDesign.DesignPowerSplit"])

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
Model.set_input_defaults("A/C_Specs")
Model.set_input_defaults("Mission_Profile")
Model.set_input_defaults("Run_Settings")

# add a subsystem
Model.add_subsystem("FAST", FAST(), promotes_inputs = [("A/C_Specs"), ("Mission_Profile"), ("Run_Settings")])

# setup the problem
Problem.setup()

# create the n2 diagram
om.n2(Problem)