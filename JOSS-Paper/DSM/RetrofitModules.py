"""

RetrofitModules.py
written by Max Arnson, marnson@umich.edu
last updated: 24 oct 2024

Provide the components for an N2 diagram to be made for the retrofitting procedure (LM100J).

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

    Retrofit settings.

    """

    def setup(self):
        self.add_input("PayloadDecrease")
        self.add_input("ThrustSplit")
        self.add_input("MissionProfile")
        self.add_input("ConventionalLM")
        self.add_output("ElectrifiedLM")


    # end setup
# end Initialization

# ----------------------------------------------------------

##############################
#                            #
# Iteration CLASS            #
#                            #
##############################

class Iteration(om.Group):
    """
    
    *Iteration:

    weight Iteration

    """

    def setup(self):
        self.add_subsystem("FlyMission",FlyMission(),)
        self.add_subsystem("Update",Update(),  )

        self.connect("FlyMission.FuelBurn","Update.TOGW")
        self.connect("Update.BatteryUpdate","FlyMission.BatteryWeight")



    # end setup
# end Iteration

# ----------------------------------------------------------

##############################
#                            #
# FlyMission CLASS              #
#                            #
##############################

class FlyMission(om.ExplicitComponent):
    """
    
    *Iteration:

    weight Iteration

    """

    def setup(self):
        self.add_input("MaximumPower")
        self.add_input("EMWeight")
        self.add_input("BatteryWeight")
        self.add_output("FuelBurn")



    # end setup
# end FlyMission

# ----------------------------------------------------------

##############################
#                            #
# Update  CLASS              #
#                            #
##############################

class Update(om.ExplicitComponent):
    """
    
    *Update:

    update battery weight with new MTOW - TOGW

    """

    def setup(self):
        self.add_input("TOGW")
        self.add_output("BatteryUpdate")



    # end setup
# end FlyMission