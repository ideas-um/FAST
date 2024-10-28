"""

FASTN2.py
written by Max Arnson, marnson@umich.edu
last updated: 24 oct 2024

Create an N2 diagram for FAST's Retrofit Code.

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
import RetrofitModules as RM

# ----------------------------------------------------------


##############################
#                            #
# FAST Prop CLASS            #
#                            #
##############################

class Retrofit(om.Group):
    """
    
    FAST:
    
    Show how all major code components are connected together.
    
    """

    def setup(self):
       
        # add the subsystems
        self.add_subsystem("Initialization", RM.Initialization(), promotes_inputs = [("PayloadDecrease"), ("ThrustSplit"), ("MissionProfile"),("ConventionalLM")])
        self.add_subsystem("Iteration",RM.Iteration())

        # make connections
        # connections
        self.connect("Initialization.ElectrifiedLM",["Iteration.FlyMission.MaximumPower","Iteration.FlyMission.EMWeight"])

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
Model.set_input_defaults("PayloadDecrease")
Model.set_input_defaults("ThrustSplit")
Model.set_input_defaults("MissionProfile")
Model.set_input_defaults("ConventionalLM")

# add a subsystem
Model.add_subsystem("RetrofitModel", Retrofit(), promotes_inputs = [("PayloadDecrease"), ("ThrustSplit"), ("MissionProfile"),("ConventionalLM")])

# setup the problem
Problem.setup()

# create the n2 diagram
om.n2(Problem)