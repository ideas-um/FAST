"""

FASTModules.py
written by Paul Mokotoff, prmoko@umich.edu
last updated: 06 sep 2024

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

class Initialization(om.Group):
    """
    
    Initialization:

    Illustrates how FAST processes the user inputs and prepares it for analysis in FAST.

    """

    def setup(self):

        # subsystems
        self.add_subsystem("SpecificationFile",SpecificationFile(),promotes_inputs=[("A/C_Specs"),("Mission_Profile"),("Run_Settings")],promotes_outputs=[("Pre-Processed_Specifications")])
        self.add_subsystem("InputProcessing",InputProcessing(),promotes_outputs=[("Processed_Specifications")])
        self.add_subsystem("ModifiedInputs",ModifiedInputs(),promotes_inputs=[("MTOW_Guess")],promotes_outputs=[("Point_Performance_Parameters"),("Candidate_A/C_Design"),("Validated_Mission_Profile")])

        # make connections
        self.connect("Pre-Processed_Specifications",[("InputProcessing.Variable_Instantiation"),("InputProcessing.Regressions"),("InputProcessing.Default_Settings")])
        self.connect("Processed_Specifications","ModifiedInputs.Processed_Specifications")



    # end setup
# end Initialization
   
   
# ----------------------------------------------------------


##############################
#                            #
# Specification File CLASS   #
#                            #
##############################

class SpecificationFile(om.ExplicitComponent):
    """
    
    SpecificationFile:

    User inputted files and values.

    """

    def setup(self):
        self.add_input("A/C_Specs")
        self.add_input("Mission_Profile")
        self.add_input("Run_Settings")
        self.add_output("Pre-Processed_Specifications")

        

    # end setup
# end Specification File


# ----------------------------------------------------------


##############################
#                            #
# Input Processing CLASS     #
#                            #
##############################

class InputProcessing(om.ExplicitComponent):
    """
    
    InputProcessing:

    Regressions and instatiation.

    """

    def setup(self):
        self.add_input("Variable_Instantiation")
        self.add_input("Regressions")
        self.add_input("Default_Settings")
        self.add_output("Processed_Specifications")

        

    # end setup
# end Specification File


# ----------------------------------------------------------

##############################
#                            #
# Modified Inputs CLASS      #
#                            #
##############################

class ModifiedInputs(om.ExplicitComponent):
    """
    
    ModifiedInputs:

    Inputs after being processed.

    """

    def setup(self):
        self.add_input("Processed_Specifications")
        self.add_input("MTOW_Guess")
        self.add_output("Point_Performance_Parameters")
        self.add_output("Candidate_A/C_Design")
        self.add_output("Validated_Mission_Profile")

        

    # end setup
# end ModifiedInputs


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

class OEWIteration(om.Group):
    """
    
    OEW_Iteration:
    
    Estimate the aircraft's airframe and propulsion system weights.
    
    """

    def setup(self):
        self.add_subsystem("WeightBuildUp",WeightBuildUp(),promotes_inputs=["MTOW","T_or_P","S"],promotes_outputs=["Updated_MTOW","Sized_A/C"])
        self.add_subsystem("PropulsionOnDesign",PropulsionOnDesign())

    # end setup
# end OEWIteration


# ----------------------------------------------------------

##############################
#                            #
# Smaller OEW CLASS          #
#                            #
##############################

class WeightBuildUp(om.ExplicitComponent):
    """
    
    OEW_Iteration:
    
    Estimate the aircraft's airframe and propulsion system weights.
    
    """

    def setup(self):
        self.add_input("MTOW")
        self.add_input("T_or_P")
        self.add_input("S")
        self.add_output("OEW")
        self.add_output("Updated_MTOW")
        self.add_output("Sized_A/C")

    # end setup
# end WeightBuildUp


# ----------------------------------------------------------

##############################
#                            #
# Propulsion On Design CLASS #
#                            #
##############################

class PropulsionOnDesign(om.ExplicitComponent):
    """
    
    PropulsionOnDesign:
    
    Design.
    
    """

    def setup(self):
        self.add_input("DesignPerformance")
        self.add_input("EngineDesignConditions")
        self.add_input("DesignPowerSplit")
        self.add_output("PropulsionSystemWeights")

    # end setup
# end PropulsionOnDesign


# ----------------------------------------------------------


##############################
#                            #
# Battery Sizing CLASS       #
#                            #
##############################

class BatterySizing(om.ExplicitComponent):
    """
    
    Battery Sizing:
    
    Show how the battery is re-sized.
    
    """

    def setup(self):

        # add inputs and outputs
        self.add_input("Battery_Energy_Expended")
        self.add_input("Final_SOC")
        self.add_input("Minimum_SOC")
        self.add_input("System_Voltage")
        self.add_input("Gravimetric_Specific_Energy")
        self.add_output("Battery_Weight")
        self.add_output("Cells_in_Series/Parallel")

    # end setup
# end BatterySizing


# ----------------------------------------------------------


##############################
#                            #
# Fuel Sizing CLASS          #
#                            #
##############################

class FuelSizing(om.ExplicitComponent):
    """
    
    Fuel Sizing:
    
    Show how much fuel should be carried.
    
    """

    def setup(self):

        # add inputs and oututs
        self.add_input("Fuel_Energy_Expended")
        self.add_input("Gravimetric_Specific_Energy")
        self.add_output("Fuel_Weight")

    # end setup
# end FuelSizing


# ----------------------------------------------------------


##############################
#                            #
# ENERGY SOURCE SIZING CLASS #
#                            #
##############################

class EnergySourceSizing(om.Group):
    """
    
    Energy Source Sizing:
    
    Size the fuel, battery, hydrogen, etc. that stores energy on the aircraft.
    
    """

    def setup(self):

        # add subsystems
        self.add_subsystem("Fuel_Sizing", FuelSizing(), promotes_inputs=[("Fuel_Energy_Expended"), ("Gravimetric_Specific_Energy")], promotes_outputs=[("Fuel_Weight")])
        self.add_subsystem("Battery_Sizing", BatterySizing(), promotes_inputs=[("Battery_Energy_Expended"), ("Final_SOC"), ("Minimum_SOC"), ("System_Voltage"), ("Gravimetric_Specific_Energy")], promotes_outputs=[("Battery_Weight")])

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
        self.add_input("Fuel_Weight")
        self.add_input("Battery_Weight")
        self.add_input("A/C_Weights")
        self.add_output("MTOW")

    # end setup
# end MTOWIteration


# ----------------------------------------------------------


##############################
#                            #
# Aircraft Sizing CLASS      #
#                            #
##############################

class AircraftSizing(om.Group):
    """
    
    Aircraft Sizing:
    
    Show how the aircraft is sized (outer MTOW iteration)
    
    """

    def setup(self):

        # add the subsystems
        self.add_subsystem("Airframe_Propulsion_System_Sizing", PointPerformance(), promotes_inputs=[("T/W_or_P/W", "T/W_or_P/W"), ("W/S", "W/S")])
        self.add_subsystem("OEW_Iteration", OEWIteration())
        self.add_subsystem("Mission_Analysis", EvaluateMission(), promotes_inputs=[("Mission_Profile", "Mission_Profile"), ("Mission_Targets", "Mission_Targets")])
        self.add_subsystem("ES_Sizing", EnergySourceSizing(), promotes_inputs=[("Gravimetric_Specific_Energy", "Gravimetric_Specific_Energy"), ("Minimum_SOC", "Minimum_SOC"), ("System_Voltage", "System_Voltage")])
        self.add_subsystem("MTOW_Update", MTOWIteration(), promotes_outputs=[("MTOW", "MTOW")])

        # make connections
        self.connect("Airframe_Propulsion_System_Sizing.T_or_P", "OEW_Iteration.T_or_P")
        self.connect("Airframe_Propulsion_System_Sizing.S", "OEW_Iteration.S")
        self.connect("OEW_Iteration.Updated_MTOW", "Airframe_Propulsion_System_Sizing.MTOW")
        self.connect("OEW_Iteration.Sized_A/C", ["Mission_Analysis.A/C", "MTOW_Update.A/C_Weights"])
        self.connect("Mission_Analysis.Mission_History", ["ES_Sizing.Fuel_Energy_Expended", "ES_Sizing.Battery_Energy_Expended", "ES_Sizing.Final_SOC"])
        self.connect("ES_Sizing.Fuel_Weight", "MTOW_Update.Fuel_Weight")
        self.connect("ES_Sizing.Battery_Weight", "MTOW_Update.Battery_Weight")
        self.connect("OEW_Iteration.PropulsionOnDesign.PropulsionSystemWeights","OEW_Iteration.MTOW")
        self.connect("Airframe_Propulsion_System_Sizing.T_or_P","OEW_Iteration.PropulsionOnDesign.DesignPerformance")

    # end setup
# end AircraftSizing


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
        self.add_subsystem("Segment_Analysis", MissionAnalysis())

        # establish connections
        self.connect("Segment_Analysis.Distance/Time_Flown", "Mission_Iteration.Distance/Time_Flown")
        self.connect("Mission_Iteration.Mission_Segment_To_Fly", "Segment_Analysis.Flight_Conditions")

    # end setup
# end EvaluateMission