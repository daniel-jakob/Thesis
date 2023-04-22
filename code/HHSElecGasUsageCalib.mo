within Thesis_Project.Experiments;
model HHSElecGasUsageCalib
  "Model of a hydronic heating system with energy storage"
  extends Modelica.Icons.Example;
 replaceable package MediumA = Buildings.Media.Air(T_default=293.15)
    "Medium model for air";
 replaceable package MediumW = Buildings.Media.Water "Medium model";
 constant Modelica.Units.SI.Volume RoomVols[:] = {29.85,13.5,6,13.5,78.625,61.2,30.225,15.7*2.5,4.83*2.5,5.85*2.5,10.14*2.5,13.72*2.5,14.06*2.5};
 constant Modelica.Units.SI.Volume TotRoomVols = sum(RoomVols) - RoomVols[3];
 parameter Modelica.Units.SI.MassFlowRate m_flow_nominal[:]=1.29*0.8/3600*RoomVols[:] "Design mass flow rate";
 parameter Modelica.Units.SI.Power Q_flow_nominal=7000
    "Nominal power of heating plant";
 // Due to the night setback, in which the radiator do not provide heat input into the room,
 // we scale the design power of the radiator loop
 parameter Real scaFacRad = 1.5
    "Scaling factor to scale the power (and mass flow rate) of the radiator loop";
  parameter Modelica.Units.SI.Temperature TSup_nominal=273.15 + 40 + 5
    "Nominal supply temperature for radiators";
  parameter Modelica.Units.SI.Temperature TRet_nominal=273.15 + 30 + 5
    "Nominal return temperature for radiators";
  parameter Modelica.Units.SI.Temperature THPSup_nominal=273.15 + 32 + 5
    "Nominal supply temperature for radiators";
  parameter Modelica.Units.SI.Temperature THPRet_nominal=273.15 + 22 + 5
    "Nominal return temperature for radiators";
  parameter Modelica.Units.SI.Temperature dTRad_nominal=TSup_nominal -
      TRet_nominal "Nominal temperature difference for radiator loop";
  parameter Modelica.Units.SI.Temperature dTBoi_nominal=20
    "Nominal temperature difference for boiler loop";
  parameter Modelica.Units.SI.MassFlowRate mRad_flow_nominal=scaFacRad*
      Q_flow_nominal/dTRad_nominal/4200
    "Nominal mass flow rate of radiator loop";
  parameter Modelica.Units.SI.MassFlowRate mBoi_flow_nominal=scaFacRad*
      Q_flow_nominal/dTBoi_nominal/4200 "Nominal mass flow rate of boiler loop";
  parameter Modelica.Units.SI.PressureDifference dpPip_nominal=10000
    "Pressure difference of pipe (without valve)";
  parameter Modelica.Units.SI.PressureDifference dpVal_nominal=6000
    "Pressure difference of valve";
  parameter Modelica.Units.SI.PressureDifference dpRoo_nominal=6000
    "Pressure difference of flow leg that serves a room";
  parameter Modelica.Units.SI.PressureDifference dpThrWayVal_nominal=6000
    "Pressure difference of three-way valve";
  parameter Modelica.Units.SI.PressureDifference dp_nominal=dpPip_nominal +
      dpVal_nominal + dpRoo_nominal + dpThrWayVal_nominal
    "Pressure difference of loop";
  // Room model

 parameter Modelica.Units.SI.Temperature TempBlockBoi= 273.15 + 7;
 parameter Modelica.Units.SI.Temperature TempBlockHP = 273.15 - 2;

  Buildings.Fluid.Movers.SpeedControlled_y pumBoi(
    redeclare package Medium = MediumW,
    per(pressure(V_flow=mBoi_flow_nominal/1000*{0.5,1}, dp=(3000 + 2000)*{2,1})),
    use_inputFilter=false,
    energyDynamics=Modelica.Fluid.Types.Dynamics.SteadyState)
    "Pump for boiler circuit" ));  Buildings.Fluid.Movers.SpeedControlled_y pumRad(
    redeclare package Medium = MediumW,
    per(pressure(V_flow=mRad_flow_nominal/1000*{0,2}, dp=dp_nominal*{2,0})),
    energyDynamics=Modelica.Fluid.Types.Dynamics.SteadyState)
    "Pump that serves the radiators" ));  Buildings.Fluid.Boilers.BoilerPolynomial boi(
    allowFlowReversal=false,
    a={0.93},
    effCur=Buildings.Fluid.Types.EfficiencyCurves.Constant,
    redeclare package Medium = MediumW,
    Q_flow_nominal=Q_flow_nominal,
    m_flow_nominal=mBoi_flow_nominal,
    fue=Buildings.Fluid.Data.Fuels.HeatingOilLowerHeatingValue(),
    dp_nominal=3000 + 2000,
    energyDynamics=Modelica.Fluid.Types.Dynamics.FixedInitial,
    T_start=293.15) "Boiler"
    ));
  Modelica.Thermal.HeatTransfer.Sensors.TemperatureSensor TRoo1
    ));
  Buildings.Controls.OBC.CDL.Continuous.PIDWithReset conPum(
    yMax=1,
    Td=60,
    yMin=0.05,
    k=0.5,
    Ti=15) "Controller for pump"
    ));
  Buildings.Fluid.Sensors.RelativePressure dpSen(redeclare package Medium =
        MediumW)
    ));  Buildings.Fluid.Actuators.Valves.TwoWayEqualPercentage val1(
    redeclare package Medium = MediumW,
    allowFlowReversal=false,
    dpValve_nominal(displayUnit="Pa") = dpVal_nominal,
    m_flow_nominal=mRad_flow_nominal*(RoomVols[1]/TotRoomVols),
    dpFixed_nominal=dpRoo_nominal,
    from_dp=true,
    use_inputFilter=false) "Radiator valve"
    ));
  Buildings.Controls.OBC.CDL.Continuous.PID conRoo1(
    yMax=1,
    yMin=0,
    Ti=60,
    Td=60,
    controllerType=Modelica.Blocks.Types.SimpleController.P,
    k=0.5) "Controller for room temperature"
    ));
  Modelica.Thermal.HeatTransfer.Sensors.TemperatureSensor TRoo2
    ));
  Buildings.Fluid.Actuators.Valves.TwoWayEqualPercentage val2(
    redeclare package Medium = MediumW,
    allowFlowReversal=false,
    dpValve_nominal(displayUnit="Pa") = dpVal_nominal,
    m_flow_nominal=mRad_flow_nominal*(RoomVols[2]/TotRoomVols),
    dpFixed_nominal=dpRoo_nominal,
    from_dp=true,
    use_inputFilter=false) "Radiator valve"
    ));
  Buildings.Controls.OBC.CDL.Continuous.PID conRoo2(
    yMax=1,
    yMin=0,
    Ti=60,
    Td=60,
    controllerType=Modelica.Blocks.Types.SimpleController.P,
    k=0.5) "Controller for room temperature"
    ));
  Buildings.Fluid.HeatExchangers.Radiators.RadiatorEN442_2 rad2(
    redeclare package Medium = MediumW,
    allowFlowReversal=false,
    fraRad=0,
    Q_flow_nominal=scaFacRad*Q_flow_nominal*(RoomVols[2]/TotRoomVols),
    energyDynamics=Modelica.Fluid.Types.Dynamics.FixedInitial,
    T_a_nominal=323.15,
    T_b_nominal=313.15,
    n=1.3) "Radiator"
    ));
  Buildings.Fluid.HeatExchangers.Radiators.RadiatorEN442_2 rad1(
    redeclare package Medium = MediumW,
    allowFlowReversal=false,
    fraRad=0,
    Q_flow_nominal=scaFacRad*Q_flow_nominal*(RoomVols[1]/TotRoomVols),
    energyDynamics=Modelica.Fluid.Types.Dynamics.FixedInitial,
    T_a_nominal=323.15,
    T_b_nominal=313.15,
    n=1.3)   "Radiator"
    ));
  Buildings.Fluid.Actuators.Valves.ThreeWayEqualPercentageLinear thrWayVal(
    redeclare package Medium = MediumW,
    dpValve_nominal=dpThrWayVal_nominal,
    l={0.01,0.01},
    tau=10,
    m_flow_nominal=mRad_flow_nominal,
    dpFixed_nominal={100,0},
    use_inputFilter=false,
    energyDynamics=Modelica.Fluid.Types.Dynamics.SteadyState) "Three-way valve"
    ));  Buildings.Controls.OBC.CDL.Continuous.PIDWithReset conVal(
    yMax=1,
    yMin=0,
    xi_start=1,
    Td=60,
    k=0.1,
    Ti=120) "Controller for pump"
    ));
  Buildings.Fluid.Storage.Stratified tan(
    allowFlowReversal=true,
    m_flow_nominal=mRad_flow_nominal,
    dIns=0.10,
    redeclare package Medium = MediumW,
    hTan=1.7,
    nSeg=10,
    show_T=true,
    VTan=0.5,
    energyDynamics=Modelica.Fluid.Types.Dynamics.FixedInitial) "Storage tank"
    ));

  Modelica.Thermal.HeatTransfer.Sensors.TemperatureSensor tanTemBot
    "Tank temperature"
    ));
  Modelica.Thermal.HeatTransfer.Sensors.TemperatureSensor tanTemTop
    "Tank temperature"
    ));
  Buildings.Controls.OBC.CDL.Continuous.GreaterThreshold greThrBoi(t=
        TSup_nominal + 5) "Check for temperature at the bottom of the tank"
    ));
  Buildings.Controls.OBC.CDL.Conversions.BooleanToReal booToReaPum "Signal converter for pump"
    ));
  Buildings.Controls.OBC.CDL.Continuous.Greater lesThr
    "Check for temperature at the top of the tank"
    ));
  Buildings.Fluid.Sensors.TemperatureTwoPort temSup(
    redeclare package Medium = MediumW,
    allowFlowReversal=false,
    m_flow_nominal=mRad_flow_nominal)
    ));  Buildings.Fluid.Sensors.TemperatureTwoPort temRet(
    redeclare package Medium = MediumW,
    allowFlowReversal=false,
    m_flow_nominal=mRad_flow_nominal)
    ));  Buildings.Controls.SetPoints.SupplyReturnTemperatureReset heaChaBoi(
    TRoo_nominal=296.15,
    dTOutHeaBal=3,
    use_TRoo_in=true,
    TSup_nominal=TSup_nominal,
    TRet_nominal=TRet_nominal,
    TOut_nominal=268.15)
    ));
  Buildings.Controls.SetPoints.OccupancySchedule occSch(occupancy=3600*{7,19})"Occupancy schedule"
    ));
  Buildings.Controls.OBC.CDL.Continuous.Switch swi "Switch to select set point"
    ));
  Buildings.Controls.OBC.CDL.Continuous.Sources.Constant TRooNig(k=273.15 + 18)
    "Room temperature set point at night"
    ));
  Buildings.Controls.OBC.CDL.Continuous.Sources.Constant TRooSet(k=273.15 + 24)
    ));
  Buildings.Controls.OBC.CDL.Continuous.MultiMax mulMax(nin=12) "Maximum radiator valve position" ));
  Buildings.Controls.OBC.CDL.Continuous.Hysteresis hysPum(uLow=0.01, uHigh=0.20)
    "Hysteresis for pump"
    ));
  Modelica.Blocks.MathBoolean.Or pumOnSig(nu=4) "Signal for pump being on"
    ));
  Buildings.Controls.OBC.CDL.Continuous.Sources.Constant dTThr(k=1)
    "Threshold to switch boiler off"
    ));
  Buildings.Controls.OBC.CDL.Continuous.Subtract sub1
    ));
  Buildings.Controls.OBC.CDL.Continuous.Sources.Constant TRooOff(k=273.15 - 5)
    "Low room temperature set point to switch heating off"
    ));
  Buildings.Controls.OBC.CDL.Continuous.Switch swi1 "Switch to select set point"
    ));
  Modelica.Blocks.Logical.OnOffController onOff(bandwidth=2) "On/off switch"
    ));
  Buildings.Controls.OBC.CDL.Continuous.Sources.Constant TOutSwi(k=16 + 293.15)
    "Outside air temperature to switch heating on or off"
    ));
  Buildings.Fluid.Sources.Boundary_pT bou1(
    T=288.15,
    nPorts=1,
    redeclare package Medium = MediumW)
    "Fixed boundary condition, needed to provide a pressure in the system"
    ));
  Buildings.Controls.OBC.CDL.Continuous.MultiplyByParameter gain(k=1/dp_nominal)
    "Gain used to normalize pressure measurement signal"
    ));
  Buildings.Fluid.FixedResistances.Junction splVal(
    dp_nominal={dpPip_nominal,0,0},
    m_flow_nominal=mRad_flow_nominal*{1,-1,-1},
    redeclare package Medium = MediumW,
    energyDynamics=Modelica.Fluid.Types.Dynamics.SteadyState)
    "Flow splitter" ));  Buildings.Fluid.FixedResistances.Junction splVal1(
    m_flow_nominal=mRad_flow_nominal*{1,-1,-1},
    redeclare package Medium = MediumW,
    dp_nominal={0,0,0},
    energyDynamics=Modelica.Fluid.Types.Dynamics.SteadyState)
    "Flow splitter" ));  Buildings.Fluid.FixedResistances.Junction splVal2(
    m_flow_nominal=mRad_flow_nominal*{1,-1,-1},
    redeclare package Medium = MediumW,
    dp_nominal={0,0,0},
    energyDynamics=Modelica.Fluid.Types.Dynamics.SteadyState)
    "Flow splitter" ));  Modelica.Blocks.Logical.LessThreshold lesThrTRoo(threshold=19 + 273.15)
    "Test to block boiler pump if room air temperature is sufficiently high"
    ));
  Buildings.Controls.OBC.CDL.Logical.And and1
    "Logical test to enable pump and subsequently the boiler"
    ));

  Modelica.StateGraph.TransitionWithSignal T1 "Transition to pump on"
    ));
  Modelica.StateGraph.StepWithSignal pumOn(nOut=1, nIn=1)
 "Pump on"
    ));
  Modelica.StateGraph.StepWithSignal boiOn(nIn=1, nOut=1) "Boiler on"
    ));
  Modelica.StateGraph.TransitionWithSignal T2(enableTimer=false, waitTime=300)
    "Transition that switches HP off"
    ));
  Modelica.StateGraph.StepWithSignal pumOn2(        nIn=1, nOut=1)
  "Pump on"
    ));
  Modelica.StateGraph.Transition T4(enableTimer=true, waitTime=10)
    "Transition to boiler on"
    ));
  inner Modelica.StateGraph.StateGraphRoot stateGraphRoot
    "Root of the state graph"
    ));
  Buildings.Controls.OBC.CDL.Conversions.BooleanToReal booToRea
    "Conversion from boolean to real signal"
    ));
  Buildings.Controls.OBC.CDL.Continuous.MovingAverage aveTOut(delta=12*3600)
    "Time averaged outdoor air temperature"
    ));
  inner Buildings.ThermalZones.EnergyPlus_9_6_0.Building building(
    idfName="E:/Documents/ThesisNumericalSim/Reference_Home/Irish_Reference_Home(v960)_Minimal_No_Int_Gains.idf",
    epwName="E:/Documents/ThesisNumericalSim/Weather/Clones/IRL_Clones.039740_IWEC_Attempt2.epw",
    weaName="E:/Documents/ThesisNumericalSim/Weather/Clones/IRL_Clones.039740_IWEC_Attempt2.mos",
    usePrecompiledFMU=false,
    computeWetBulbTemperature=false) "Building model"
    ));

  Buildings.BoundaryConditions.WeatherData.Bus weaBus ));  Building.irishReferenceHouse irishReferenceHouse(zone1_floor1(zoneName="zone1_floor1"))
    ));
  Buildings.Fluid.Sources.MassFlowSource_WeatherData bou[13](
    redeclare package Medium = MediumA,
    m_flow=m_flow_nominal,
    nPorts=13)
   "Boundary condition"
    ));
  Buildings.Fluid.Sources.Outside out(redeclare package Medium = MediumA, nPorts=
       1)
    "Outside condition"
    ));
  Modelica.Thermal.HeatTransfer.Celsius.FromKelvin fromKelvin
    ));
  Modelica.Thermal.HeatTransfer.Celsius.PrescribedTemperature
    prescribedTemperature
    ));
  Buildings.Fluid.FixedResistances.Junction splVal3(
    m_flow_nominal=mRad_flow_nominal*{1,-1,-1},
    redeclare package Medium = MediumW,
    dp_nominal={0,0,0},
    energyDynamics=Modelica.Fluid.Types.Dynamics.SteadyState)
    "Flow splitter" ));  Buildings.Fluid.Actuators.Valves.TwoWayEqualPercentage val4(
    redeclare package Medium = MediumW,
    allowFlowReversal=false,
    dpValve_nominal(displayUnit="Pa") = dpVal_nominal,
    m_flow_nominal=mRad_flow_nominal*(RoomVols[4]/TotRoomVols),
    dpFixed_nominal=dpRoo_nominal,
    from_dp=true,
    use_inputFilter=false) "Radiator valve"
    ));
  Buildings.Fluid.HeatExchangers.Radiators.RadiatorEN442_2 rad4(
    redeclare package Medium = MediumW,
    allowFlowReversal=false,
    fraRad=0,
    Q_flow_nominal=scaFacRad*Q_flow_nominal*(RoomVols[4]/TotRoomVols),
    energyDynamics=Modelica.Fluid.Types.Dynamics.FixedInitial,
    T_a_nominal=323.15,
    T_b_nominal=313.15,
    n=1.3) "Radiator"
    ));
  Buildings.Fluid.FixedResistances.Junction splVal5(
    m_flow_nominal=mRad_flow_nominal*{1,-1,-1},
    redeclare package Medium = MediumW,
    dp_nominal={0,0,0},
    energyDynamics=Modelica.Fluid.Types.Dynamics.SteadyState) "Flow splitter"
    ));  Buildings.Fluid.FixedResistances.Junction splVal4(
    m_flow_nominal=mRad_flow_nominal*{1,-1,-1},
    redeclare package Medium = MediumW,
    dp_nominal={0,0,0},
    energyDynamics=Modelica.Fluid.Types.Dynamics.SteadyState)
    "Flow splitter" ));  Buildings.Fluid.FixedResistances.Junction splVal6(
    m_flow_nominal=mRad_flow_nominal*{1,-1,-1},
    redeclare package Medium = MediumW,
    dp_nominal={0,0,0},
    energyDynamics=Modelica.Fluid.Types.Dynamics.SteadyState)
    "Flow splitter" ));  Modelica.Thermal.HeatTransfer.Sensors.TemperatureSensor TRoo4
    ));
  Buildings.Controls.OBC.CDL.Continuous.PID conRoo4(
    yMax=1,
    yMin=0,
    Ti=60,
    Td=60,
    controllerType=Modelica.Blocks.Types.SimpleController.P,
    k=0.5) "Controller for room temperature"
    ));
  Buildings.Fluid.FixedResistances.Junction splVal7(
    m_flow_nominal=mRad_flow_nominal*{1,-1,-1},
    redeclare package Medium = MediumW,
    dp_nominal={0,0,0},
    energyDynamics=Modelica.Fluid.Types.Dynamics.SteadyState)
    "Flow splitter" ));  Buildings.Fluid.FixedResistances.Junction splVal8(
    m_flow_nominal=mRad_flow_nominal*{1,-1,-1},
    redeclare package Medium = MediumW,
    dp_nominal={0,0,0},
    energyDynamics=Modelica.Fluid.Types.Dynamics.SteadyState)
    "Flow splitter" ));  Buildings.Fluid.Actuators.Valves.TwoWayEqualPercentage val5(
    redeclare package Medium = MediumW,
    allowFlowReversal=false,
    dpValve_nominal(displayUnit="Pa") = dpVal_nominal,
    m_flow_nominal=mRad_flow_nominal*(RoomVols[5]/TotRoomVols),
    dpFixed_nominal=dpRoo_nominal,
    from_dp=true,
    use_inputFilter=false) "Radiator valve"
    ));
  Buildings.Fluid.HeatExchangers.Radiators.RadiatorEN442_2 rad5(
    redeclare package Medium = MediumW,
    allowFlowReversal=false,
    fraRad=0,
    Q_flow_nominal=scaFacRad*Q_flow_nominal*(RoomVols[5]/TotRoomVols),
    energyDynamics=Modelica.Fluid.Types.Dynamics.FixedInitial,
    T_a_nominal=323.15,
    T_b_nominal=313.15,
    n=1.3) "Radiator"
    ));
  Modelica.Thermal.HeatTransfer.Sensors.TemperatureSensor TRoo5
    ));
  Buildings.Controls.OBC.CDL.Continuous.PID conRoo5(
    yMax=1,
    yMin=0,
    Ti=60,
    Td=60,
    controllerType=Modelica.Blocks.Types.SimpleController.P,
    k=0.5) "Controller for room temperature"
    ));
  Buildings.Fluid.FixedResistances.Junction splVal9(
    m_flow_nominal=mRad_flow_nominal*{1,-1,-1},
    redeclare package Medium = MediumW,
    dp_nominal={0,0,0},
    energyDynamics=Modelica.Fluid.Types.Dynamics.SteadyState)
    "Flow splitter" ));  Buildings.Fluid.FixedResistances.Junction splVal10(
    m_flow_nominal=mRad_flow_nominal*{1,-1,-1},
    redeclare package Medium = MediumW,
    dp_nominal={0,0,0},
    energyDynamics=Modelica.Fluid.Types.Dynamics.SteadyState)
    "Flow splitter" ));  Buildings.Fluid.Actuators.Valves.TwoWayEqualPercentage val6(
    redeclare package Medium = MediumW,
    allowFlowReversal=false,
    dpValve_nominal(displayUnit="Pa") = dpVal_nominal,
    m_flow_nominal=mRad_flow_nominal*(RoomVols[6]/TotRoomVols),
    dpFixed_nominal=dpRoo_nominal,
    from_dp=true,
    use_inputFilter=false) "Radiator valve"
    ));
  Buildings.Fluid.HeatExchangers.Radiators.RadiatorEN442_2 rad6(
    redeclare package Medium = MediumW,
    allowFlowReversal=false,
    fraRad=0,
    Q_flow_nominal=scaFacRad*Q_flow_nominal*(RoomVols[6]/TotRoomVols),
    energyDynamics=Modelica.Fluid.Types.Dynamics.FixedInitial,
    T_a_nominal=323.15,
    T_b_nominal=313.15,
    n=1.3) "Radiator"
    ));
  Modelica.Thermal.HeatTransfer.Sensors.TemperatureSensor TRoo6
    ));
  Buildings.Controls.OBC.CDL.Continuous.PID conRoo6(
    yMax=1,
    yMin=0,
    Ti=60,
    Td=60,
    controllerType=Modelica.Blocks.Types.SimpleController.P,
    k=0.5) "Controller for room temperature"
    ));
  Buildings.Fluid.FixedResistances.Junction splVal11(
    m_flow_nominal=mRad_flow_nominal*{1,-1,-1},
    redeclare package Medium = MediumW,
    dp_nominal={0,0,0},
    energyDynamics=Modelica.Fluid.Types.Dynamics.SteadyState)
    "Flow splitter" ));  Buildings.Fluid.FixedResistances.Junction splVal12(
    m_flow_nominal=mRad_flow_nominal*{1,-1,-1},
    redeclare package Medium = MediumW,
    dp_nominal={0,0,0},
    energyDynamics=Modelica.Fluid.Types.Dynamics.SteadyState)
    "Flow splitter" ));  Buildings.Fluid.Actuators.Valves.TwoWayEqualPercentage val7(
    redeclare package Medium = MediumW,
    allowFlowReversal=false,
    dpValve_nominal(displayUnit="Pa") = dpVal_nominal,
    m_flow_nominal=mRad_flow_nominal*(RoomVols[7]/TotRoomVols),
    dpFixed_nominal=dpRoo_nominal,
    from_dp=true,
    use_inputFilter=false) "Radiator valve"
    ));
  Buildings.Fluid.HeatExchangers.Radiators.RadiatorEN442_2 rad7(
    redeclare package Medium = MediumW,
    allowFlowReversal=false,
    fraRad=0,
    Q_flow_nominal=scaFacRad*Q_flow_nominal*(RoomVols[7]/TotRoomVols),
    energyDynamics=Modelica.Fluid.Types.Dynamics.FixedInitial,
    T_a_nominal=323.15,
    T_b_nominal=313.15,
    n=1.3) "Radiator"
    ));
  Modelica.Thermal.HeatTransfer.Sensors.TemperatureSensor TRoo7
    ));
  Buildings.Controls.OBC.CDL.Continuous.PID conRoo7(
    yMax=1,
    yMin=0,
    Ti=60,
    Td=60,
    controllerType=Modelica.Blocks.Types.SimpleController.P,
    k=0.5) "Controller for room temperature"
    ));
  Buildings.Fluid.FixedResistances.Junction splVal13(
    m_flow_nominal=mRad_flow_nominal*{1,-1,-1},
    redeclare package Medium = MediumW,
    dp_nominal={0,0,0},
    energyDynamics=Modelica.Fluid.Types.Dynamics.SteadyState)
    "Flow splitter" ));  Buildings.Fluid.FixedResistances.Junction splVal14(
    m_flow_nominal=mRad_flow_nominal*{1,-1,-1},
    redeclare package Medium = MediumW,
    dp_nominal={0,0,0},
    energyDynamics=Modelica.Fluid.Types.Dynamics.SteadyState)
    "Flow splitter" ));  Buildings.Fluid.Actuators.Valves.TwoWayEqualPercentage val8(
    redeclare package Medium = MediumW,
    allowFlowReversal=false,
    dpValve_nominal(displayUnit="Pa") = dpVal_nominal,
    m_flow_nominal=mRad_flow_nominal*(RoomVols[8]/TotRoomVols),
    dpFixed_nominal=dpRoo_nominal,
    from_dp=true,
    use_inputFilter=false) "Radiator valve"
    ));
  Buildings.Fluid.HeatExchangers.Radiators.RadiatorEN442_2 rad8(
    redeclare package Medium = MediumW,
    allowFlowReversal=false,
    fraRad=0,
    Q_flow_nominal=scaFacRad*Q_flow_nominal*(RoomVols[8]/TotRoomVols),
    energyDynamics=Modelica.Fluid.Types.Dynamics.FixedInitial,
    T_a_nominal=323.15,
    T_b_nominal=313.15,
    n=1.3) "Radiator"
    ));
  Modelica.Thermal.HeatTransfer.Sensors.TemperatureSensor TRoo8
    ));
  Buildings.Controls.OBC.CDL.Continuous.PID conRoo8(
    yMax=1,
    yMin=0,
    Ti=60,
    Td=60,
    controllerType=Modelica.Blocks.Types.SimpleController.P,
    k=0.5) "Controller for room temperature"
    ));
  Buildings.Fluid.FixedResistances.Junction splVal15(
    m_flow_nominal=mRad_flow_nominal*{1,-1,-1},
    redeclare package Medium = MediumW,
    dp_nominal={0,0,0},
    energyDynamics=Modelica.Fluid.Types.Dynamics.SteadyState)
    "Flow splitter" ));  Buildings.Fluid.FixedResistances.Junction splVal16(
    m_flow_nominal=mRad_flow_nominal*{1,-1,-1},
    redeclare package Medium = MediumW,
    dp_nominal={0,0,0},
    energyDynamics=Modelica.Fluid.Types.Dynamics.SteadyState)
    "Flow splitter" ));  Buildings.Fluid.Actuators.Valves.TwoWayEqualPercentage val9(
    redeclare package Medium = MediumW,
    allowFlowReversal=false,
    dpValve_nominal(displayUnit="Pa") = dpVal_nominal,
    m_flow_nominal=mRad_flow_nominal*(RoomVols[9]/TotRoomVols),
    dpFixed_nominal=dpRoo_nominal,
    from_dp=true,
    use_inputFilter=false) "Radiator valve"
    ));
  Buildings.Fluid.HeatExchangers.Radiators.RadiatorEN442_2 rad9(
    redeclare package Medium = MediumW,
    allowFlowReversal=false,
    fraRad=0,
    Q_flow_nominal=scaFacRad*Q_flow_nominal*(RoomVols[9]/TotRoomVols),
    energyDynamics=Modelica.Fluid.Types.Dynamics.FixedInitial,
    T_a_nominal=323.15,
    T_b_nominal=313.15,
    n=1.3) "Radiator"
    ));
  Modelica.Thermal.HeatTransfer.Sensors.TemperatureSensor TRoo9
    ));
  Buildings.Controls.OBC.CDL.Continuous.PID conRoo9(
    yMax=1,
    yMin=0,
    Ti=60,
    Td=60,
    controllerType=Modelica.Blocks.Types.SimpleController.P,
    k=0.5) "Controller for room temperature"
    ));
  Buildings.Fluid.FixedResistances.Junction splVal17(
    m_flow_nominal=mRad_flow_nominal*{1,-1,-1},
    redeclare package Medium = MediumW,
    dp_nominal={0,0,0},
    energyDynamics=Modelica.Fluid.Types.Dynamics.SteadyState)
    "Flow splitter" ));  Buildings.Fluid.FixedResistances.Junction splVal18(
    m_flow_nominal=mRad_flow_nominal*{1,-1,-1},
    redeclare package Medium = MediumW,
    dp_nominal={0,0,0},
    energyDynamics=Modelica.Fluid.Types.Dynamics.SteadyState)
    "Flow splitter" ));  Buildings.Fluid.Actuators.Valves.TwoWayEqualPercentage val10(
    redeclare package Medium = MediumW,
    allowFlowReversal=false,
    dpValve_nominal(displayUnit="Pa") = dpVal_nominal,
    m_flow_nominal=mRad_flow_nominal*(RoomVols[10]/TotRoomVols),
    dpFixed_nominal=dpRoo_nominal,
    from_dp=true,
    use_inputFilter=false) "Radiator valve"
    ));
  Buildings.Fluid.HeatExchangers.Radiators.RadiatorEN442_2 rad10(
    redeclare package Medium = MediumW,
    allowFlowReversal=false,
    fraRad=0,
    Q_flow_nominal=scaFacRad*Q_flow_nominal*(RoomVols[10]/TotRoomVols),
    energyDynamics=Modelica.Fluid.Types.Dynamics.FixedInitial,
    T_a_nominal=323.15,
    T_b_nominal=313.15,
    n=1.3) "Radiator"
    ));
  Modelica.Thermal.HeatTransfer.Sensors.TemperatureSensor TRoo10
    ));
  Buildings.Controls.OBC.CDL.Continuous.PID conRoo10(
    yMax=1,
    yMin=0,
    Ti=60,
    Td=60,
    controllerType=Modelica.Blocks.Types.SimpleController.P,
    k=0.5) "Controller for room temperature"
    ));
  Buildings.Fluid.FixedResistances.Junction splVal20(
    m_flow_nominal=mRad_flow_nominal*{1,-1,-1},
    redeclare package Medium = MediumW,
    dp_nominal={0,0,0},
    energyDynamics=Modelica.Fluid.Types.Dynamics.SteadyState)
    "Flow splitter" ));  Buildings.Fluid.Actuators.Valves.TwoWayEqualPercentage val11(
    redeclare package Medium = MediumW,
    allowFlowReversal=false,
    dpValve_nominal(displayUnit="Pa") = dpVal_nominal,
    m_flow_nominal=mRad_flow_nominal*(RoomVols[11]/TotRoomVols),
    dpFixed_nominal=dpRoo_nominal,
    from_dp=true,
    use_inputFilter=false) "Radiator valve"
    ));
  Buildings.Fluid.HeatExchangers.Radiators.RadiatorEN442_2 rad11(
    redeclare package Medium = MediumW,
    allowFlowReversal=false,
    fraRad=0,
    Q_flow_nominal=scaFacRad*Q_flow_nominal*(RoomVols[11]/TotRoomVols),
    energyDynamics=Modelica.Fluid.Types.Dynamics.FixedInitial,
    T_a_nominal=323.15,
    T_b_nominal=313.15,
    n=1.3) "Radiator"
    ));
  Modelica.Thermal.HeatTransfer.Sensors.TemperatureSensor TRoo11
    ));
  Buildings.Controls.OBC.CDL.Continuous.PID conRoo11(
    yMax=1,
    yMin=0,
    Ti=60,
    Td=60,
    controllerType=Modelica.Blocks.Types.SimpleController.P,
    k=0.5) "Controller for room temperature"
    ));
  Buildings.Fluid.Actuators.Valves.TwoWayEqualPercentage val12(
    redeclare package Medium = MediumW,
    allowFlowReversal=false,
    dpValve_nominal(displayUnit="Pa") = dpVal_nominal,
    m_flow_nominal=mRad_flow_nominal*(RoomVols[12]/TotRoomVols),
    dpFixed_nominal=dpRoo_nominal,
    from_dp=true,
    use_inputFilter=false) "Radiator valve"
    ));
  Buildings.Fluid.HeatExchangers.Radiators.RadiatorEN442_2 rad12(
    redeclare package Medium = MediumW,
    allowFlowReversal=false,
    fraRad=0,
    Q_flow_nominal=scaFacRad*Q_flow_nominal*(RoomVols[12]/TotRoomVols),
    energyDynamics=Modelica.Fluid.Types.Dynamics.FixedInitial,
    T_a_nominal=323.15,
    T_b_nominal=313.15,
    n=1.3) "Radiator"
    ));
  Modelica.Thermal.HeatTransfer.Sensors.TemperatureSensor TRoo12
    ));
  Buildings.Controls.OBC.CDL.Continuous.PID conRoo12(
    yMax=1,
    yMin=0,
    Ti=60,
    Td=60,
    controllerType=Modelica.Blocks.Types.SimpleController.P,
    k=0.5) "Controller for room temperature"
    ));
  Buildings.Fluid.FixedResistances.Junction splVal19(
    m_flow_nominal=mRad_flow_nominal*{1,-1,-1},
    redeclare package Medium = MediumW,
    dp_nominal={0,0,0},
    energyDynamics=Modelica.Fluid.Types.Dynamics.SteadyState)
    "Flow splitter" ));  Buildings.Fluid.Actuators.Valves.TwoWayEqualPercentage val13(
    redeclare package Medium = MediumW,
    allowFlowReversal=false,
    dpValve_nominal(displayUnit="Pa") = dpVal_nominal,
    m_flow_nominal=mRad_flow_nominal*(RoomVols[13]/TotRoomVols),
    dpFixed_nominal=dpRoo_nominal,
    from_dp=true,
    use_inputFilter=false) "Radiator valve"
    ));
  Buildings.Fluid.HeatExchangers.Radiators.RadiatorEN442_2 rad13(
    redeclare package Medium = MediumW,
    allowFlowReversal=false,
    fraRad=0,
    Q_flow_nominal=scaFacRad*Q_flow_nominal*(RoomVols[13]/TotRoomVols),
    energyDynamics=Modelica.Fluid.Types.Dynamics.FixedInitial,
    T_a_nominal=323.15,
    T_b_nominal=313.15,
    n=1.3) "Radiator"
    ));
  Modelica.Thermal.HeatTransfer.Sensors.TemperatureSensor TRoo13
    ));
  Buildings.Controls.OBC.CDL.Continuous.PID conRoo13(
    yMax=1,
    yMin=0,
    Ti=60,
    Td=60,
    controllerType=Modelica.Blocks.Types.SimpleController.P,
    k=0.5) "Controller for room temperature"
    ));
  Buildings.Fluid.FixedResistances.Junction splVal21(
    m_flow_nominal=mRad_flow_nominal*{1,-1,-1},
    redeclare package Medium = MediumW,
    dp_nominal={0,0,0},
    energyDynamics=Modelica.Fluid.Types.Dynamics.SteadyState)
    "Flow splitter" ));  Buildings.Fluid.FixedResistances.Junction splVal22(
    m_flow_nominal=mRad_flow_nominal*{1,-1,-1},
    redeclare package Medium = MediumW,
    dp_nominal={0,0,0},
    energyDynamics=Modelica.Fluid.Types.Dynamics.SteadyState)
    "Flow splitter" ));  Modelica.Blocks.Continuous.Integrator TESQLossIntegrator
    ));
  Modelica.Thermal.HeatTransfer.Sources.PrescribedTemperature TReturn
    ));
  Buildings.Controls.OBC.CDL.Continuous.Sources.Constant HPOnSetpoint(k=
        THPSup_nominal + 5)
 "Setpoint HP"
    ));
  Buildings.Controls.OBC.CDL.Continuous.Switch swi2 "Switch for HP setpoint"
    ));
  Buildings.Controls.OBC.CDL.Continuous.Sources.Constant HPOffSetpoint(k=273.15 -
        10) "Setpoint HP"
    ));
  Components.HP_AirWater_TSet hP_AirWater_TSet(
    redeclare package Medium = MediumW,
    QNom=7000,
    tauHeatLoss=3600,
    mWater=3,
    cDry=4000,
    m_flow_nominal=mBoi_flow_nominal,
    betaFactor=0.65,
    modulation_min=5,
    modulation_start=12.5)
    ));  inner IDEAS.BoundaryConditions.SimInfoManager sim(filNam="E:/Documents/ThesisNumericalSim/Weather/Clones/IRL_Clones.039740_IWEC_Attempt2.mos")
    ));
  Buildings.Fluid.Sensors.TemperatureTwoPort TempPreHP(redeclare package Medium
      = MediumW,
    allowFlowReversal=false,
      m_flow_nominal=mBoi_flow_nominal) ));  Buildings.Fluid.Sensors.TemperatureTwoPort TemPostHP(redeclare package Medium
      = MediumW,
    allowFlowReversal=false,
      m_flow_nominal=mBoi_flow_nominal) ));  Modelica.Blocks.Logical.LessThreshold lesThrTOut(threshold=TempBlockBoi)
    "Test to block boiler if TOut > 7C"
    ));
  Modelica.StateGraph.TransitionWithSignal T3(enableTimer=true, waitTime=10)
    "Transition to boiler on"
    ));
  Modelica.Blocks.Logical.GreaterThreshold greaterThreshold(threshold=
        TempBlockHP)
    "Block HP if TOut is less than 2C"
    ));
  Buildings.Controls.OBC.CDL.Continuous.Switch swi3
    "Switch for Supply Temp setpoint"
    ));
  Buildings.Controls.SetPoints.SupplyReturnTemperatureReset heaChaHP(
    TRoo_nominal=296.15,
    dTOutHeaBal=6,
    use_TRoo_in=true,
    TSup_nominal=THPSup_nominal,
    TRet_nominal=THPRet_nominal,
    TOut_nominal=268.15) "Supply Temp Calc for HP"
    ));
  Modelica.StateGraph.StepWithSignal HPOn(nIn=1, nOut=1) "HP on"
    ));
  Modelica.StateGraph.TransitionWithSignal T5(enableTimer=true, waitTime=10)
    "Transition to HP on"
    ));
  Buildings.Controls.OBC.CDL.Logical.Switch logSwi
    ));
  Buildings.Controls.OBC.CDL.Continuous.GreaterThreshold greThrHP(t=
        THPSup_nominal + 3)
  "Check for temperature at the bottom of the tank"
    ));
  Modelica.StateGraph.TransitionWithSignal T6(enableTimer=false, waitTime=300)
    "Transition that switches boiler off"
    ));
  Modelica.StateGraph.StepWithSignal pumOn1(nIn=1, nOut=1)
  "Pump on"
    ));
  Modelica.StateGraph.StepWithSignal pumOn3(nOut=1, nIn=1)
 "Pump on"
    ));
  Modelica.StateGraph.Transition T7(enableTimer=true, waitTime=10)
    "Transition to boiler on"
    ));
  Modelica.StateGraph.TransitionWithSignal T8 "Transition to pump on"
    ));
  Buildings.Controls.OBC.CDL.Continuous.Less les
    ));
  Buildings.Controls.OBC.CDL.Logical.And and2
    "Boiler on if <7C & TPostHP > TSupplySetpoint"
    ));  Modelica.StateGraph.InitialStepWithSignal off(nOut=1, nIn=1)
    "Pump and furnace off"
    ));
  Modelica.StateGraph.InitialStepWithSignal off1(nOut=1, nIn=1)
    "Pump and furnace off"
    ));
  Buildings.Controls.OBC.CDL.Logical.Nor Nor
    ));
  Buildings.Controls.OBC.CDL.Logical.And and3
    ));
  Buildings.Utilities.Math.Average roomAvgTemp(nin=11)
     ));  Modelica.Blocks.MathBoolean.Or pumOnSig1(nu=3)
      "Signal for pump being on"
    ));
  Modelica.Blocks.Logical.GreaterThreshold greaterThreshold1(threshold=
        TempBlockBoi)
    "Block HP if TOut is less than 2C"
    ));
  Buildings.Controls.OBC.CDL.Continuous.GreaterThreshold greThr(t=0.1)
    ));  Buildings.Controls.OBC.CDL.Continuous.LessThreshold lesThr1(t=273.15 + 2)
    ));  Buildings.Controls.OBC.CDL.Logical.And and4 ));  Buildings.Controls.OBC.CDL.Logical.TimerAccumulating accTim(t=60*60)
    ));  Buildings.Controls.OBC.CDL.Logical.Timer tim(t=5*60)  ));  Buildings.Controls.OBC.CDL.Continuous.GreaterThreshold greThr1(t=273.15 + 3)
    ));  Buildings.Controls.OBC.CDL.Logical.TrueHoldWithReset truHol(duration=10*60)
    ));
  Buildings.Controls.OBC.CDL.Logical.Not not1
    ));
  Buildings.Controls.OBC.CDL.Logical.And and5
    ));
  Buildings.Controls.OBC.CDL.Continuous.PID BoiPI(
    yMax=1,
    yMin=0,
    Ti=60,
    Td=60,
    controllerType=Buildings.Controls.OBC.CDL.Types.SimpleController.PID,
    k=0.25)
"Controller for room temperature"
    ));
  Buildings.Controls.OBC.CDL.Continuous.Switch swi4
    ));
  Buildings.Controls.OBC.CDL.Continuous.Sources.Constant dTThr1(k=0)
    "Threshold to switch boiler off"
    ));
  Buildings.Controls.OBC.CDL.Logical.Pre pre
    ));
  Buildings.Controls.OBC.CDL.Logical.Or or2
    ));
  Buildings.Fluid.Boilers.BoilerPolynomial boi1(
    allowFlowReversal=false,
    a={0.93},
    effCur=Buildings.Fluid.Types.EfficiencyCurves.Constant,
    redeclare package Medium = MediumW,
    Q_flow_nominal=832,
    m_flow_nominal=mBoi_flow_nominal,
    fue=Buildings.Fluid.Data.Fuels.HeatingOilLowerHeatingValue(),
    dp_nominal=3000 + 2000,
    energyDynamics=Modelica.Fluid.Types.Dynamics.FixedInitial,
    T_start=293.15) "Boiler"
    ));
  Buildings.Controls.OBC.CDL.Conversions.BooleanToReal booToReaPum1
   "Signal converter for pump"
    ));
  Buildings.Fluid.Sources.Boundary_pT bou2(
    T=288.15,
    nPorts=1,
    redeclare package Medium = MediumW)
    "Fixed boundary condition, needed to provide a pressure in the system"
    ));
  Buildings.Fluid.Sources.Boundary_pT bou3(
    T=288.15,
    nPorts=1,
    redeclare package Medium = MediumW)
    "Fixed boundary condition, needed to provide a pressure in the system"
    ));
  Buildings.Fluid.Movers.SpeedControlled_y pumBoi1(
    redeclare package Medium = MediumW,
    per(pressure(V_flow=mBoi_flow_nominal/1000*{0.5,1}, dp=(3000 + 2000)*{2,1})),

    use_inputFilter=false,
    energyDynamics=Modelica.Fluid.Types.Dynamics.SteadyState)
    "Pump for boiler circuit" ));  connect(pumRad.port_b, dpSen.port_a)
    ));      smooth=Smooth.None));
  connect(dpSen.port_b, pumRad.port_a)
    ));      smooth=Smooth.None));
  connect(val2.port_b, rad2.port_a) ));      smooth=Smooth.None));
  connect(val1.port_b,rad1. port_a) ));      smooth=Smooth.None));
  connect(conRoo2.y, val2.y) ));      smooth=Smooth.None));
  connect(conRoo1.y, val1.y) ));      smooth=Smooth.None));
  connect(pumRad.port_a, thrWayVal.port_2)
        ));      smooth=Smooth.None));
  connect(boi.port_b,pumBoi. port_a) ));      smooth=Smooth.None));
  connect(tan.heaPorVol[1], tanTemTop.port) ));      points={{228,-171.08},{256,-171.08},{256,-170},{282,-170}},
      color={191,0,0},
      smooth=Smooth.None));
  connect(tanTemBot.port, tan.heaPorVol[tan.nSeg]) ));      smooth=Smooth.None));
  connect(temSup.T, conVal.u_m) ));      smooth=Smooth.None));
  connect(mulMax.y, hysPum.u) ));      smooth=Smooth.None));
  connect(conRoo2.y, mulMax.u[1]) ));      points={{560,358},{560,352},{576,352},{576,376},{-26,376},{-26,71.8333},{
          -2,71.8333}},
      color={0,0,127},
      smooth=Smooth.None));
  connect(conRoo1.y, mulMax.u[2]) ));      points={{562,250},{562,280},{-26,280},{-26,71.5},{-2,71.5}},
      color={0,0,127},
      smooth=Smooth.None));
  connect(conVal.y, thrWayVal.y) ));      smooth=Smooth.None));
  connect(booToReaPum.y, pumBoi.y)
          ));      smooth=Smooth.None));
  connect(swi.y, heaChaBoi.TRoo_in) ));          {24.1,-44}},
      color={0,0,127},
      smooth=Smooth.None));
  connect(pumRad.port_b, temSup.port_a) ));      smooth=Smooth.None));
  connect(sub1.y, lesThr.u2) ));      smooth=Smooth.None));
  connect(tanTemTop.T, sub1.u1) ));      smooth=Smooth.None));
  connect(dTThr.y, sub1.u2) ));      smooth=Smooth.None));
  connect(tanTemBot.T, greThrBoi.u) ));      smooth=Smooth.None));
  connect(TRooSet.y, swi1.u1) ));      smooth=Smooth.None));
  connect(swi1.u2, occSch.occupied) ));      smooth=Smooth.None));
  connect(TRooNig.y, swi1.u3) ));      smooth=Smooth.None));
  connect(TOutSwi.y, onOff.reference) ));      smooth=Smooth.None));
  connect(swi1.y, swi.u1) ));      smooth=Smooth.None));
  connect(onOff.y, swi.u2) ));      smooth=Smooth.None));
  connect(TRooOff.y, swi.u3) ));      smooth=Smooth.None));
  connect(conPum.y, pumRad.y) ));      smooth=Smooth.None));
  connect(TRoo2.T,conRoo2. u_m) ));      smooth=Smooth.None));
  connect(TRoo1.T, conRoo1.u_m) ));      smooth=Smooth.None));
  connect(bou1.ports[1], boi.port_a) ));      smooth=Smooth.None));
  connect(gain.u, dpSen.p_rel) ));      smooth=Smooth.None));
  connect(gain.y, conPum.u_m) ));      smooth=Smooth.None));
  connect(pumBoi.port_b, tan.port_a) ));      smooth=Smooth.None));
  connect(pumBoi.port_b, thrWayVal.port_1) ));      smooth=Smooth.None));
  connect(temRet.port_b, splVal.port_1) ));      smooth=Smooth.None));
  connect(thrWayVal.port_3, splVal.port_3) ));      smooth=Smooth.None));
  connect(splVal.port_2, tan.port_b) ));      smooth=Smooth.None));
  connect(splVal1.port_3,val1. port_a) ));      smooth=Smooth.None));
  connect(splVal1.port_1, temSup.port_b) ));      smooth=Smooth.None));
  connect(temRet.port_a, splVal2.port_1) ));      smooth=Smooth.None));
  connect(splVal2.port_3,rad1. port_b) ));      smooth=Smooth.None));

  connect(lesThr.y, and1.u2) ));      smooth=Smooth.None));
  connect(lesThrTRoo.y, and1.u1) ));      smooth=Smooth.None));
  connect(and1.y, T1.condition) ));  connect(pumOn2.active, pumOnSig.u[1]) ));          {654,-4},{654,-84.75},{660,-84.75}},
     color={255,0,255}));
  connect(pumOn.active, pumOnSig.u[2]) ));          {654,-4},{654,-88.25},{660,-88.25}},
     color={255,0,255}));
  connect(hysPum.y, conPum.trigger) ));  connect(hysPum.y, booToRea.u)
    );
  connect(booToRea.y, conPum.u_s)
    );
  connect(conVal.trigger, hysPum.y) ));  connect(onOff.u, aveTOut.y) ));  connect(weaBus,building. weaBus) ));      thickness=0.5));
  connect(weaBus.TDryBul,aveTOut. u) ));      thickness=0.5), Text(
      string="%first",
      index=-1,
      extent={{-6,3},{-6,3}},
      horizontalAlignment=TextAlignment.Right));
  connect(weaBus.TDryBul, heaChaBoi.TOut) ));      thickness=0.5,
      smooth=Smooth.None));
  connect(weaBus, bou[1].weaBus) ));      points={{-55,157},{-55,156.2},{66,156.2}},
      color={255,204,51},
      thickness=0.5), Text(
      string="%second",
      index=1,
      extent={{-6,3},{-6,3}},
      horizontalAlignment=TextAlignment.Right));
  connect(weaBus, bou[2].weaBus);
  connect(weaBus, bou[3].weaBus);
  connect(weaBus, bou[4].weaBus);
  connect(weaBus, bou[5].weaBus);
  connect(weaBus, bou[6].weaBus);
  connect(weaBus, bou[7].weaBus);
  connect(weaBus, bou[8].weaBus);
  connect(weaBus, bou[9].weaBus);
  connect(weaBus, bou[10].weaBus);
  connect(weaBus, bou[11].weaBus);
  connect(weaBus, bou[12].weaBus);
  connect(weaBus, bou[13].weaBus);
  connect(irishReferenceHouse.port_a, bou.ports[1]));
  connect(irishReferenceHouse.port_b, out.ports[1]));
  connect(out.weaBus, weaBus) ));      points={{64,138.2},{0,138.2},{0,156},{-28,156},{-28,157},{-55,157}},
      color={255,204,51},
      thickness=0.5));
  connect(rad2.heatPortCon, irishReferenceHouse.heat_port_a[2]) ));      Line(points={{360,331.2},{360,348},{436,348},{436,106.931},{366.3,106.931}},
        color={191,0,0}));
  connect(rad1.heatPortCon, irishReferenceHouse.heat_port_a[1]) ));      Line(points={{378,221.2},{378,230},{436,230},{436,108},{402,108},{402,
          106.577},{366.3,106.577}},
        color={191,0,0}));
  connect(TRoo1.port, irishReferenceHouse.heat_port_a[1]) ));        points={{478,230},{436,230},{436,108},{402,108},{402,106.577},{366.3,
          106.577}},
        color={191,0,0}));
  connect(TRoo2.port, irishReferenceHouse.heat_port_a[2]) ));        points={{468,332},{436,332},{436,106.931},{366.3,106.931}},
color={191,0,0}));
  connect(fromKelvin.Kelvin, irishReferenceHouse.TAir[3]) ));          376,130},{366.2,130},{366.2,129.585}},
      color={0,0,127}));
  connect(fromKelvin.Celsius, prescribedTemperature.T)
    );
  connect(prescribedTemperature.port, boi.heatPort) ));          -138},{26,-138},{26,-150},{12,-150},{12,-162.8}}, color={191,0,0}));
  connect(prescribedTemperature.port, tan.heaPorTop) ));          -138},{230,-138},{230,-155.2},{232,-155.2}}, color={191,0,0}));
  connect(prescribedTemperature.port, tan.heaPorBot) ));          -138},{242,-138},{242,-192},{232,-192},{232,-184.8}}, color={191,0,0}));
  connect(prescribedTemperature.port, tan.heaPorSid) ));          -138},{242,-138},{242,-170},{239.2,-170}}, color={191,0,0}));
  connect(splVal1.port_2, splVal3.port_1)
    );
  connect(splVal3.port_3, val2.port_a) ));      smooth=Smooth.Bezier));
  connect(splVal3.port_2, splVal5.port_1)
    );
  connect(splVal5.port_3, val4.port_a)
    );
  connect(val4.port_b, rad4.port_a) );
  connect(splVal2.port_2,splVal4. port_1) ));  connect(rad2.port_b,splVal4. port_3) ));  connect(rad4.port_b, splVal6.port_3) ));  connect(splVal6.port_1,splVal4. port_2) );
  connect(TRoo4.port, irishReferenceHouse.heat_port_a[4]) ));        points={{466,426},{436,426},{436,107.638},{366.3,107.638}}, color={191,0,
          0}));
  connect(TRoo4.T, conRoo4.u_m) );
  connect(swi.y, conRoo4.u_s) ));  connect(conRoo4.y, val4.y) ));  connect(conRoo4.y, mulMax.u[3]) ));          {570,470},{-26,470},{-26,71.1667},{-2,71.1667}},
          color={0,0,127}));
  connect(rad4.heatPortCon, irishReferenceHouse.heat_port_a[4]) ));      Line(points={{358,439.2},{358,444},{436,444},{436,108},{382,108},{382,
          107.638},{366.3,107.638}},
      color={191,0,0}));
  connect(swi.y, conRoo2.u_s) ));  connect(swi.y, conRoo1.u_s) ));  connect(splVal8.port_1, splVal6.port_2) );
  connect(splVal5.port_2, splVal7.port_1) );
  connect(splVal7.port_3, val5.port_a) );

  connect(val5.port_b, rad5.port_a) );
  connect(rad5.port_b, splVal8.port_3) ));  connect(TRoo5.T, conRoo5.u_m) );
  connect(conRoo5.y, val5.y) ));  connect(TRoo5.port, irishReferenceHouse.heat_port_a[5]) ));        points={{460,546},{436,546},{436,108},{402,108},{402,107.992},{366.3,
          107.992}},
        color={191,0,0}));
  connect(rad5.heatPortCon, irishReferenceHouse.heat_port_a[5]) ));      Line(points={{364,551.2},{364,560},{436,560},{436,108},{402,108},{402,
          107.992},{366.3,107.992}},
      color={191,0,0}));
  connect(conRoo5.u_s, swi.y) ));  connect(conRoo5.y, mulMax.u[4]) ));          {568,594},{-26,594},{-26,70.8333},{-2,70.8333}},
          color={0,0,127}));

  connect(conRoo6.y, val6.y);
  connect(TRoo6.port, irishReferenceHouse.heat_port_a[6]);
  connect(rad6.heatPortCon, irishReferenceHouse.heat_port_a[6]);
  connect(conRoo6.u_s, swi.y);
  connect(conRoo6.y, mulMax.u[5]);
  connect(val6.port_b, rad6.port_a);
  connect(TRoo6.T, conRoo6.u_m);

  connect(conRoo7.y, val7.y);
  connect(TRoo7.port, irishReferenceHouse.heat_port_a[7]);
  connect(rad7.heatPortCon, irishReferenceHouse.heat_port_a[7]);
  connect(conRoo7.u_s, swi.y);
  connect(conRoo7.y, mulMax.u[6]);
  connect(val7.port_b, rad7.port_a);
  connect(TRoo7.T, conRoo7.u_m);

  connect(conRoo8.y, val8.y);
  connect(TRoo8.port, irishReferenceHouse.heat_port_a[8]);
  connect(rad8.heatPortCon, irishReferenceHouse.heat_port_a[8]);
  connect(conRoo8.u_s, swi.y);
  connect(conRoo8.y, mulMax.u[7]);
  connect(val8.port_b, rad8.port_a);
  connect(TRoo8.T, conRoo8.u_m);

  connect(conRoo9.y, val9.y);
  connect(TRoo9.port, irishReferenceHouse.heat_port_a[9]);
  connect(rad9.heatPortCon, irishReferenceHouse.heat_port_a[9]);
  connect(conRoo9.u_s, swi.y);
  connect(conRoo9.y, mulMax.u[8]);
  connect(val9.port_b, rad9.port_a);
  connect(TRoo9.T, conRoo9.u_m);

  connect(conRoo10.y, val10.y);
  connect(TRoo10.port, irishReferenceHouse.heat_port_a[10]);
  connect(rad10.heatPortCon, irishReferenceHouse.heat_port_a[10]);
  connect(conRoo10.u_s, swi.y);
  connect(conRoo10.y, mulMax.u[9]);
  connect(val10.port_b, rad10.port_a);
  connect(TRoo10.T, conRoo10.u_m);

  connect(conRoo11.y, val11.y);
  connect(TRoo11.port, irishReferenceHouse.heat_port_a[11]);
  connect(rad11.heatPortCon, irishReferenceHouse.heat_port_a[11]);
  connect(conRoo11.u_s, swi.y);
  connect(conRoo11.y, mulMax.u[10]);
  connect(val11.port_b, rad11.port_a);
  connect(TRoo11.T, conRoo11.u_m);

  connect(conRoo12.y, val12.y);
  connect(TRoo12.port, irishReferenceHouse.heat_port_a[12]);
  connect(rad12.heatPortCon, irishReferenceHouse.heat_port_a[12]);
  connect(conRoo12.u_s, swi.y);
  connect(conRoo12.y, mulMax.u[11]);
  connect(val12.port_b, rad12.port_a);
  connect(TRoo12.T, conRoo12.u_m);

  connect(conRoo13.y, val13.y);
  connect(TRoo13.port, irishReferenceHouse.heat_port_a[13]);
  connect(rad13.heatPortCon, irishReferenceHouse.heat_port_a[13]);
  connect(conRoo13.u_s, swi.y);
  connect(conRoo13.y, mulMax.u[12]);
  connect(val13.port_b, rad13.port_a);
  connect(TRoo13.T, conRoo13.u_m);

  connect(splVal8.port_2, splVal10.port_1) );
  connect(splVal10.port_2, splVal12.port_1) ));  connect(splVal12.port_2, splVal14.port_1) ));  connect(splVal14.port_2, splVal16.port_1) );
  connect(splVal16.port_2, splVal18.port_1) ));  connect(splVal18.port_2, splVal20.port_1) ));  connect(splVal7.port_2, splVal9.port_1) ));  connect(splVal9.port_2, splVal11.port_1) ));  connect(splVal11.port_2, splVal13.port_1) ));  connect(splVal13.port_2, splVal15.port_1) ));  connect(splVal15.port_2, splVal17.port_1) ));  connect(rad11.port_b, splVal20.port_3) ));  connect(rad10.port_b, splVal18.port_3) ));  connect(rad9.port_b, splVal16.port_3) ));  connect(rad8.port_b, splVal14.port_3) ));  connect(rad7.port_b, splVal12.port_3) ));  connect(rad6.port_b, splVal10.port_3) ));  connect(splVal9.port_3, val6.port_a) ));  connect(splVal11.port_3, val7.port_a) ));  connect(splVal13.port_3, val8.port_a) ));  connect(splVal15.port_3, val9.port_a) ));  connect(splVal17.port_3, val10.port_a) ));  connect(splVal17.port_2, splVal19.port_1) );
  connect(splVal19.port_3, val11.port_a) ));  connect(splVal20.port_2, splVal22.port_1) ));  connect(splVal19.port_2, splVal21.port_1) ));  connect(splVal21.port_2, val13.port_a) ));  connect(splVal22.port_2, rad13.port_b) ));  connect(splVal21.port_3, val12.port_a) ));  connect(rad12.port_b, splVal22.port_3) ));  connect(TESQLossIntegrator.u, tan.Ql_flow) ));          {278,-155.6},{250,-155.6}}, color={0,0,127}));
  connect(weaBus.TDryBul, TReturn.T) ));      thickness=0.5));
  connect(HPOnSetpoint.y, swi2.u1) ));  connect(HPOffSetpoint.y, swi2.u3) ));  connect(swi2.y, hP_AirWater_TSet.TSet) ));  connect(TReturn.port, hP_AirWater_TSet.heatPort) ));  connect(hP_AirWater_TSet.port_a, TempPreHP.port_b)
    );
  connect(TempPreHP.port_a, tan.port_b) ));  connect(hP_AirWater_TSet.port_b, TemPostHP.port_a)
    );
  connect(TemPostHP.port_b, boi.port_a) ));  connect(weaBus.TDryBul, lesThrTOut.u) ));      thickness=0.5));
  connect(weaBus.TDryBul, greaterThreshold.u) ));      thickness=0.5));
  connect(swi3.y, lesThr.u1) ));  connect(swi.y, heaChaHP.TRoo_in) ));          {658,46},{304,46},{304,-16},{-8,-16},{-8,-82},{20.1,-82}},
        color={0,0,127}));
  connect(weaBus.TDryBul, heaChaHP.TOut) ));      thickness=0.5));
  connect(swi3.y, conVal.u_s) ));  connect(T5.outPort, HPOn.inPort[1])
    );
  connect(greaterThreshold.y, T5.condition) ));  connect(tanTemBot.T, greThrHP.u) ));  connect(logSwi.y, T2.condition) ));  connect(T3.outPort, boiOn.inPort[1])
    );
  connect(T6.condition, logSwi.y) ));  connect(boiOn.outPort[1], T6.inPort)
    );
  connect(HPOn.outPort[1], T2.inPort)
    );
  connect(pumOn1.active, pumOnSig.u[3]) ));          -44},{654,-44},{654,-91.75},{660,-91.75}},
    color={255,0,255}));
  connect(T2.outPort, pumOn1.inPort[1])
    );
  connect(pumOn.outPort[1], T3.inPort)
    );
  connect(T6.outPort, pumOn2.inPort[1])
    );
  connect(pumOn3.outPort[1], T5.inPort)
    );
  connect(pumOn3.active, pumOnSig.u[4]) ));          -44},{654,-44},{654,-95.25},{660,-95.25}},
         color={255,0,255}));
  connect(pumOn2.outPort[1], T4.inPort)
    );
  connect(pumOn1.outPort[1], T7.inPort));
  connect(T1.outPort, pumOn.inPort[1])
    );
  connect(T8.outPort, pumOn3.inPort[1])
    );
  connect(and1.y, T8.condition) ));  connect(greaterThreshold.y, logSwi.u2) ));  connect(greThrBoi.y, logSwi.u3) ));  connect(heaChaHP.TSup, swi3.u1) ));  connect(heaChaBoi.TSup, swi3.u3) ));  connect(greThrHP.y, logSwi.u1) ));  connect(les.u1, TemPostHP.T) ));  connect(swi3.y, les.u2) ));  connect(lesThrTOut.y, and2.u2) ));  connect(les.y, and2.u1) ));  connect(and2.y, T3.condition) ));  connect(off.outPort[1], T1.inPort)
    );
  connect(T4.outPort, off.inPort[1]));
  connect(T8.inPort, off1.outPort[1])
    );
  connect(T7.outPort, off1.inPort[1]));
  connect(off.active, Nor.u1) ));  connect(off1.active, Nor.u2) ));  connect(and3.u1, pumOnSig.y) ));          -90},{681.5,-90}}, color={255,0,255}));
  connect(Nor.y, and3.u2) ));  connect(roomAvgTemp.y, lesThrTRoo.u) ));  connect(TRoo1.T, roomAvgTemp.u[1]) ));          230},{504,176},{400,176},{400,66},{350.182,66},{350.182,8}},
     color={0,0,127}));
  connect(TRoo2.T, roomAvgTemp.u[2]);
  connect(TRoo4.T, roomAvgTemp.u[3]);
  connect(TRoo5.T, roomAvgTemp.u[4]);
  connect(TRoo6.T, roomAvgTemp.u[5]);
  connect(TRoo7.T, roomAvgTemp.u[6]);
  connect(TRoo8.T, roomAvgTemp.u[7]);
  connect(TRoo9.T, roomAvgTemp.u[8]);
  connect(TRoo10.T, roomAvgTemp.u[9]);
  connect(TRoo11.T, roomAvgTemp.u[10]);
  connect(TRoo12.T, roomAvgTemp.u[11]);

  connect(pumOnSig1.y, booToReaPum.u));
  connect(pumOnSig1.u[1], and3.y));
  connect(boiOn.active, pumOnSig1.u[2]) ));  connect(weaBus.TDryBul, greaterThreshold1.u) ));      thickness=0.5));
  connect(greaterThreshold1.y, swi3.u2) ));  connect(hP_AirWater_TSet.HPCOP, greThr.u));
  connect(weaBus.TDryBul, lesThr1.u) ));      thickness=0.5), Text(
      string="%first",
      index=-1,
      extent={{-3,-6},{-3,-6}},
      horizontalAlignment=TextAlignment.Right));

  connect(lesThr1.y, and4.u1) ));  connect(greThr.y, and4.u2)
    );
  connect(and4.y, accTim.u)
    );
  connect(tim.u, greThr1.y)
    );
  connect(weaBus.TDryBul, greThr1.u) ));      thickness=0.5), Text(
      string="%first",
      index=-1,
      extent={{-6,3},{-6,3}},
      horizontalAlignment=TextAlignment.Right));
  connect(accTim.passed, truHol.u)
    );
  connect(truHol.y, not1.u)
    );
  connect(not1.y, and5.u2) ));  connect(HPOn.active, and5.u1) ));  connect(and5.y, swi2.u2) ));  connect(and5.y, pumOnSig1.u[3]) ));          {90,-402},{236,-402},{236,-344},{578,-344},{578,-120.667},{566,
          -120.667}},
        color={255,0,255}));
  connect(TemPostHP.T, BoiPI.u_m) ));  connect(swi3.y, BoiPI.u_s) ));  connect(boiOn.active, swi4.u2) ));  connect(BoiPI.y, swi4.u1) ));  connect(swi4.u3, dTThr1.y) ));  connect(accTim.passed, pre.u) ));  connect(tim.passed, or2.u1) ));  connect(pre.y, or2.u2) ));  connect(or2.y, accTim.reset));
  connect(swi4.y, boi.y) ));  connect(truHol.y, booToReaPum1.u) ));  connect(booToReaPum1.y, boi1.y) ));  connect(boi1.port_b, bou3.ports[1]) ));  connect(bou2.ports[1], pumBoi1.port_a) ));  connect(pumBoi1.port_b, boi1.port_a) ));  connect(booToReaPum1.y, pumBoi1.y) ));  connect(prescribedTemperature.port, boi1.heatPort) ));          -422.8},{186,-422.8}}, color={191,0,0}));
  ), Icon(
        coordinateSystem(extent={{-100,-360},{760,1080}})),
    experiment(
      StopTime=31536000,
      Tolerance=1e-06,
      __Dymola_Algorithm="Radau"),
    __Dymola_experimentFlags(
      Advanced(GenerateVariableDependencies=false, OutputModelicaCode=false),
      Evaluate=false,
      OutputCPUtime=false,
      OutputFlatModelica=false));
end HHSElecGasUsageCalib;
