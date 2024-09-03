"""

FASTModules.py
written by Paul Mokotoff, prmoko@umich.edu
last updated: 30 Aug 2024

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
# INITIALIZATION CLASS       #
#                            #
##############################

class Initialization(om.ExplicitComponent):
    """
    
    Initialization:

    Illustrates how FAST processes the user inputs and prepares it for analysis in FAST.

    """

    def setup(self):
        self.add_input("A/C_Specs")
        self.add_input("Mission_Profile")
        self.add_input("Run_Settings")
        self.add_input("MTOW_Guess")
        self.add_output("Point_Performance_Parameters")
        self.add_output("Candidate_A/C_Design")
        self.add_output("Validated_Mission_Profile")

    # end setup
# end Initialization


# ----------------------------------------------------------


##############################
#                            #
# Point_Performance CLASS    #
#                            #
##############################

class PointPerformance(om.ExplicitComponent):
    """
    
    Point_Performance:
    
    Uses T/W or P/W, W/S, and MTOW to estimate thrust/power and wing area.
    
    """

    def setup(self):
        self.add_input("T/W_or_P/W")
        self.add_input("W/S")
        self.add_input("MTOW")
        self.add_output("T_or_P")
        self.add_output("S")

    # end setup
# end PointPerformance


# ----------------------------------------------------------


##############################
#                            #
# OEW_Iteration CLASS        #
#                            #
##############################

class OEWIteration(om.ExplicitComponent):
    """
    
    OEW_Iteration:
    
    Estimate the aircraft's airframe and propulsion system weights.
    
    """

    def setup(self):
        self.add_input("T_or_P")
        self.add_input("S")
        self.add_output("OEW")
        self.add_output("Updated_MTOW")
        self.add_output("Sized_A/C")

    # end setup
# end OEWIteration


# ----------------------------------------------------------


##############################
#                            #
# ENERGY SOURCE SIZING CLASS #
#                            #
##############################

class EnergySourceSizing(om.ExplicitComponent):
    """
    
    Energy Source Sizing:
    
    Size the fuel, battery, hydrogen, etc. that stores energy on the aircraft.
    
    """

    def setup(self):
        self.add_input("Mission_History")
        self.add_output("ES_Weights")

    # end setup
# end EnergySourceSizing


# ----------------------------------------------------------


##############################
#                            #
# MTOW ITERATION CLASS       #
#                            #
##############################

class MTOWIteration(om.ExplicitComponent):
    """
    
    MTOW Iteration:
    
    Update MTOW based on the energy source sizes.
    
    """

    def setup(self):
        self.add_input("ES_Weights")
        self.add_input("A/C_Weights")
        self.add_output("MTOW")

    # end setup
# end MTOWIteration


# ----------------------------------------------------------


##############################
#                            #
# Propulsion System          #
# Performance CLASS          #
#                            #
##############################

class PropulsionPerformance(om.ExplicitComponent):
    """
    
    Propulsion Performance:
    
    Show how the propulsion system is analyzed.
    
    """

    def setup(self):
        self.add_input("Flight_Conditions")
        self.add_output("Power_Available")
        self.add_output("Propulsion_System_Performance")

    # end setup
# end PropulsionPerformance


# ----------------------------------------------------------


##############################
#                            #
# Aerodynamics CLASS         #
#                            #
##############################

class Aerodynamics(om.ExplicitComponent):
    """
    
    Aerodynamics:
    
    Show how the aerodynamic performance is computed.
    
    """

    def setup(self):
        self.add_input("Weight")
        self.add_input("Flight_Conditions")
        self.add_output("L/D")
        self.add_output("Lift")
        self.add_output("Drag")

    # end setup
# end Aerodynamics


##############################
#                            #
# Power Balance CLASS        #
#                            #
##############################

class PowerBalance(om.ExplicitComponent):
    """
    
    Power Balance:
    
    Show how the power balance is computed.
    
    """

    def setup(self):
        self.add_input("Flight_Conditions")
        self.add_input("Power_Available")
        self.add_input("Drag")
        self.add_input("Weight")
        self.add_output("Specific_Excess_Power")

    # end setup
# end PowerBalance


# ----------------------------------------------------------


##############################
#                            #
# Flight Performance CLASS   #
#                            #
##############################

class FlightPerformance(om.ExplicitComponent):
    """
    
    Flight Performance:
    
    Show how the flight performance is computed.
    
    """

    def setup(self):
        self.add_input("Propulsion_System_Performance")
        self.add_input("Flight_Conditions")
        self.add_input("Specific_Excess_Power")
        self.add_output("Rate_of_Climb")
        self.add_output("Acceleration")
        self.add_output("Updated_Weight")
        self.add_output("Distance/Time_Flown")

    # end setup
# end FlightPerformance


# ----------------------------------------------------------


##############################
#                            #
# MISSION ITERATION CLASS    #
#                            #
##############################

class MissionIteration(om.ExplicitComponent):
    """
    
    Mission Iteration:

    Show how the mission is iterated upon.

    """

    def setup(self):

        # state the inputs/outputs
        self.add_input("A/C")
        self.add_input("Distance/Time_Flown")
        self.add_input("Mission_Profile")
        self.add_input("Mission_Targets")
        self.add_output("Mission_Segment_To_Fly")
        self.add_output("Updated_Mission_Targets")
        self.add_output("Mission_History")

    # end setup
# end MissionIteration


# ----------------------------------------------------------


##############################
#                            #
# Mission Analysis CLASS     #
#                            #
##############################

class MissionAnalysis(om.Group):
    """
    
    Mission Analysis:
    
    Show how the components of the mission analysis are arranged.
    
    """

    def setup(self):
        
        # add the subsystems
        self.add_subsystem("Propulsion_Performance", PropulsionPerformance(), promotes_inputs=[("Flight_Conditions", "Flight_Conditions")])
        self.add_subsystem("Aerodynamics", Aerodynamics(), promotes_inputs=[("Flight_Conditions", "Flight_Conditions")])
        self.add_subsystem("Power_Balance", PowerBalance(), promotes_inputs=[("Flight_Conditions", "Flight_Conditions")])
        self.add_subsystem("Flight_Performance", FlightPerformance(), promotes_inputs=[("Flight_Conditions", "Flight_Conditions")], promotes_outputs=[("Distance/Time_Flown", "Distance/Time_Flown")])
        
        # estblish connections
        self.connect("Propulsion_Performance.Power_Available", "Power_Balance.Power_Available")
        self.connect("Propulsion_Performance.Propulsion_System_Performance", "Flight_Performance.Propulsion_System_Performance")
        self.connect("Aerodynamics.Drag", "Power_Balance.Drag")
        self.connect("Power_Balance.Specific_Excess_Power", "Flight_Performance.Specific_Excess_Power")      
        self.connect("Flight_Performance.Updated_Weight", ["Aerodynamics.Weight", "Power_Balance.Weight"])

    # end setup
# end MissionAnalysis


# ----------------------------------------------------------


##############################
#                            #
# Evaluate Mission CLASS     #
#                            #
##############################

class EvaluateMission(om.Group):
    """
    
    Evaluate Mission:

    Show how the mission is evaluated.

    """

    def setup(self):

        # add subsystems
        self.add_subsystem("Mission_Iteration", MissionIteration(), promotes_inputs=[("A/C", "A/C"), ("Mission_Profile", "Mission_Profile"), ("Mission_Targets", "Mission_Targets")], promotes_outputs=[("Mission_History", "Mission_History")])
        self.add_subsystem("Mission_Analysis", MissionAnalysis())

        # establish connections
        self.connect("Mission_Analysis.Distance/Time_Flown", "Mission_Iteration.Distance/Time_Flown")
        self.connect("Mission_Iteration.Mission_Segment_To_Fly", "Mission_Analysis.Flight_Conditions")

    # end setup
# end EvaluateMission