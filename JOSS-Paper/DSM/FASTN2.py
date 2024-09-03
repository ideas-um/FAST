"""

FASTN2.py
written by Paul Mokotoff, prmoko@umich.edu
last updated: 30 Aug 2024

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

        # add the groups
        
        # add the subsystems
        self.add_subsystem("Initialization", FM.Initialization(), promotes_inputs=[("A/C_Specs", "A/C_Specs"), ("Mission_Profile", "Mission_Profile"), ("Run_Settings", "Run_Settings")])
        self.add_subsystem("Airframe_Propulsion_System_Sizing", FM.PointPerformance())
        self.add_subsystem("OEW_Iteration", FM.OEWIteration())
        self.add_subsystem("Mission", FM.EvaluateMission())
        self.add_subsystem("ES_Sizing", FM.EnergySourceSizing())
        self.add_subsystem("MTOW_Update", FM.MTOWIteration())

        # make connections
        self.connect("Initialization.Point_Performance_Parameters", ["Airframe_Propulsion_System_Sizing.T/W_or_P/W", "Airframe_Propulsion_System_Sizing.W/S"])
        self.connect("Airframe_Propulsion_System_Sizing.T_or_P", "OEW_Iteration.T_or_P")
        self.connect("Airframe_Propulsion_System_Sizing.S", "OEW_Iteration.S")
        self.connect("OEW_Iteration.Updated_MTOW", "Airframe_Propulsion_System_Sizing.MTOW")
        self.connect("MTOW_Update.MTOW", "Initialization.MTOW_Guess")
        self.connect("OEW_Iteration.Sized_A/C", ["Mission.A/C", "MTOW_Update.A/C_Weights"])
        self.connect("Initialization.Validated_Mission_Profile", ["Mission.Mission_Profile", "Mission.Mission_Targets"])
        self.connect("Mission.Mission_History", "ES_Sizing.Mission_History")
        self.connect("ES_Sizing.ES_Weights", "MTOW_Update.ES_Weights")

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
Model.add_subsystem("FAST", FAST(), promotes_inputs=[("A/C_Specs", "A/C_Specs"), ("Mission_Profile", "Mission_Profile"), ("Run_Settings", "Run_Settings")])

# setup the problem
Problem.setup()

# create the n2 diagram
om.n2(Problem)