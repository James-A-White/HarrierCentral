import 'package:hcportal/imports.dart';

// all tabs defined here
enum AppTabKeyEnums {
  tabDescription(
      key: 'appTabDescription',
      title: 'Description',
      description:
          "Please provide a title, description and optional image for this application.\r\n\r\nAlthough the image is not required, having a compelling visual reference to your proposal will help evaluators remember your application.",
      idx: 0,
      isTabLockable: true,
      icon: MaterialCommunityIcons.notebook_edit,
      hasCustomTabStatusFunction: false,
      showTabInSubmitSummary: true),
  tabProposals(
      key: 'appTabProposals',
      title: 'Proposals',
      description:
          "Upload your proposals here.\r\n\r\nYour proposals must be PDF files. The quad chart can have only a single page and the proposal itself a maximum of 4 pages.",
      idx: 1,
      isTabLockable: true,
      icon: FontAwesome5Solid.file_pdf,
      hasCustomTabStatusFunction: false,
      showTabInSubmitSummary: true),
  tabCvs(
      key: 'appTabCvs',
      title: 'CVs',
      description:
          "Upload your proposals here.\r\n\r\nYour proposals must be PDF files. The quad chart can have only a single page and the proposal itself a maximum of 4 pages.",
      idx: 2,
      isTabLockable: true,
      icon: FontAwesome5Solid.file_pdf,
      hasCustomTabStatusFunction: false,
      showTabInSubmitSummary: true),
  tabForms(
      key: 'appTabForms',
      title: 'Forms',
      description:
          "If your propsal includes diagrams, please upload them here.\r\n\r\nYou can include up to 6 diagrams in your proposal. Diagrams can be .jpg, .png, .webp, or .pdf files but files must not be greater than 3Mb each.",
      idx: 3,
      isTabLockable: true,
      icon: FontAwesome.wpforms,
      hasCustomTabStatusFunction: false,
      showTabInSubmitSummary: true),
  // tabDiagrams(
  //   key: 'appTabDiagrams',
  //   title: 'Diagrams',
  //   description:
  //       "If your propsal includes diagrams, please upload them here.\r\n\r\nYou can include up to 6 diagrams in your proposal. Diagrams can be .jpg, .png, .webp, or .pdf files but files must not be greater than 3Mb each.",
  //   idx: 4,
  //   icon: Entypo.flow_tree,
  // ),
  tabTags(
      key: 'appTabTags',
      title: 'Tags',
      description:
          "If your propsal includes diagrams, please upload them here.\r\n\r\nYou can include up to 6 diagrams in your proposal. Diagrams can be .jpg, .png, .webp, or .pdf files but files must not be greater than 3Mb each.",
      idx: 4,
      isTabLockable: true,
      icon: FontAwesome.tags,
      hasCustomTabStatusFunction: false,
      showTabInSubmitSummary: true),
  tabConsent(
      key: 'appTabConsent',
      title: 'Consent',
      description:
          "If your propsal includes diagrams, please upload them here.\r\n\r\nYou can include up to 6 diagrams in your proposal. Diagrams can be .jpg, .png, .webp, or .pdf files but files must not be greater than 3Mb each.",
      idx: 5,
      isTabLockable: true,
      icon: Octicons.law,
      hasCustomTabStatusFunction: false,
      showTabInSubmitSummary: true),
  tabSubmit(
      key: 'appTabSubmit',
      title: 'Submit',
      description:
          "If your propsal includes diagrams, please upload them here.\r\n\r\nYou can include up to 6 diagrams in your proposal. Diagrams can be .jpg, .png, .webp, or .pdf files but files must not be greater than 3Mb each.",
      idx: 6,
      isTabLockable: false,
      icon: Octicons.law,
      hasCustomTabStatusFunction: true,
      showTabInSubmitSummary: false),
  ;

  const AppTabKeyEnums({
    required this.key,
    required this.title,
    required this.description,
    required this.idx,
    required this.icon,
    required this.hasCustomTabStatusFunction,
    required this.showTabInSubmitSummary,
    required this.isTabLockable,
  });

  final String key;
  final String title;
  final String description;
  final int idx;
  final IconData icon;
  final bool hasCustomTabStatusFunction;
  final bool showTabInSubmitSummary;
  final bool isTabLockable;
}

enum AppFormTypes {
  formOverivew(
    key: 'appFormOverivew',
    title: 'Overview',
    description:
        "This is an overview of your product and proposal. This is one of the most important areas to focus on as this is where you can capture the imagination of our evaluation team.\r\n\r\nPlease use this as an opportunity to demonstrate why your company and product should receive a DIANA contract and acceleration keeping in mind that we will select around 150 companies out of thousands of submissions.",
    idx: 0,
    minFormWordCount: 1000,
    maxFormWordCount: 1500,
    icon: FontAwesome5Solid.binoculars,
  ),
  formTechnical(
    key: 'appFormTechnical',
    title: 'Technical Description',
    description:
        "This section is where you describe the technical innovation that you are proposing.\r\n\r\nPlease make sure to outline how it can be used for both defence and security and commercial purposes.\r\n\r\nThis is also a section where you can highlight any intellectual property you may have regarding the innovation.\r\n\r\nIMPORTANT: Please do not provide any proprietry information here.",
    idx: 1,
    minFormWordCount: 1500,
    maxFormWordCount: 2500,
    icon: MaterialCommunityIcons.tools,
  ),
  formCommercial(
    key: 'appFormCommercial',
    title: 'Commercial Viability',
    description:
        "This section is where you describe the commercial market potential of your innovation.\r\n\r\nFor example, you can highlight pathways to commercialization, estimated market sizes for commercial and defence and security use, and partnerships you may have.",
    idx: 2,
    minFormWordCount: 1000,
    maxFormWordCount: 2500,
    icon: FontAwesome.shopping_cart,
  ),
  formProject(
    key: 'appFormProject',
    title: 'Project Plan',
    description:
        "If you are selected for DIANA acceleration, you will be awarded a contract for €100,000.\r\n\r\nHere's where you can tell us how you will use these funds to further enhance your product and make it more useful for commercial and/or defence and security users.",
    idx: 3,
    minFormWordCount: 2000,
    maxFormWordCount: 3000,
    icon: MaterialCommunityIcons.chart_gantt,
  ),
  ;

  const AppFormTypes({
    required this.key,
    required this.title,
    required this.description,
    required this.minFormWordCount,
    required this.maxFormWordCount,
    required this.idx,
    required this.icon,
  });

  final String key;
  final String title;
  final int minFormWordCount;
  final int maxFormWordCount;
  final String description;
  final int idx;
  final IconData icon;
}

enum AppExperienceGroups {
  groupErAdvComputing(
    groupKey: 'groupErAdvComputing',
    label: 'Advanced computing and methods',
    challengeIdx: [1, 6],
  ),
  groupErAdvComponentsMaterialsManufacturing(
    groupKey: 'groupErAdvComponentsMaterialsManufacturing',
    label: 'Advanced components, material and manufacturing',
    challengeIdx: [1, 6],
  ),
  groupErAIandML(
    groupKey: 'groupErAIandML',
    label: 'Artificial intelligence and machine learning',
    challengeIdx: [1, 6],
  ),
  groupErAutonomousSystemsRobotics(
    groupKey: 'groupErAutonomousSystemsRobotics',
    label: 'Autonomous systems and robotics',
    challengeIdx: [1, 6],
  ),
  groupErCommsNetworking(
    groupKey: 'groupErCommsNetworking',
    label: 'Communication and networking technologies',
    challengeIdx: [1, 6],
  ),
  groupErEnergyPowerTransmission(
    groupKey: 'groupErEnergyPowerTransmission',
    label: 'Energy and power transmission',
    challengeIdx: [1, 6],
  ),
  groupErEnergyGeneration(
    groupKey: 'groupErEnergyGeneration',
    label: 'Energy generation',
    challengeIdx: [1, 6],
  ),
  groupErEnergyStorage(
    groupKey: 'groupErEnergyStorage',
    label: 'Energy storage',
    challengeIdx: [1, 6],
  ),
  groupErGridIntegration(
    groupKey: 'groupErGridIntegration',
    label: 'Grid integration',
    challengeIdx: [1, 6],
  ),
  groupErHybridEnergyPower(
    groupKey: 'groupErHybridEnergyPower',
    label: 'Hybrid energy and power',
    challengeIdx: [1, 6],
  ),
  groupErMicrogrids(
    groupKey: 'groupErMicrogrids',
    label: 'Microgrids',
    challengeIdx: [1, 6],
  ),
  groupErPropulsion(
    groupKey: 'groupErPropulsion',
    label: 'Propulsion',
    challengeIdx: [1, 6],
  ),
  groupErSensorsDetectors(
    groupKey: 'groupErSensorsDetectors',
    label: 'Sensors and detectors',
    challengeIdx: [1, 6],
  ),
  groupErSpaceBasedEnergy(
    groupKey: 'groupErSpaceBasedEnergy',
    label: 'Space-based energy',
    challengeIdx: [1, 6],
  ),
  groupErSpace(
    groupKey: 'groupErSpace',
    label: 'Space',
    challengeIdx: [1, 6],
  ),
  groupErResilience(
    groupKey: 'groupErResilience',
    label: 'Resilience',
    challengeIdx: [1, 6],
  ),
  groupErSustainability(
    groupKey: 'groupErSustainability',
    label: 'Sustainability',
    challengeIdx: [1, 6],
  ),
  groupErOther(
    groupKey: 'groupErOther',
    label: 'Other',
    challengeIdx: [1, 6],
  ),

  // DATA AND INFORMATION SHARING

  groupDisAdvComputing(
    groupKey: 'groupDisAdvComputing',
    label: 'Advanced Computing and Methods',
    challengeIdx: [2, 7],
  ),
  groupDisAI(
    groupKey: 'groupDisAI',
    label: 'Artificial Intelligence and Machine Learning',
    challengeIdx: [2, 7],
  ),
  groupDisCommsNetworking(
    groupKey: 'groupDisCommsNetworking',
    label: 'Communication and Networking Technologies',
    challengeIdx: [2, 7],
  ),
  groupDisCyberSecurity(
    groupKey: 'groupDisCyberSecurity',
    label: 'Cyber Security',
    challengeIdx: [2, 7],
  ),
  groupDisData(
    groupKey: 'groupDisData',
    label: 'Data',
    challengeIdx: [2, 7],
  ),
  groupDisIoT(
    groupKey: 'groupDisIoT',
    label: 'Internet of Things',
    challengeIdx: [2, 7],
  ),
  groupDisHardware(
    groupKey: 'groupDisHardware',
    label: 'Hardware',
    challengeIdx: [2, 7],
  ),
  groupDisHMI(
    groupKey: 'groupDisHMI',
    label: 'Human Machine Interfaces',
    challengeIdx: [2, 7],
  ),
  groupDisPlatforms(
    groupKey: 'groupDisPlatforms',
    label: 'Platforms',
    challengeIdx: [2, 7],
  ),
  groupDisQuantum(
    groupKey: 'groupDisQuantum',
    label: 'Quantum',
    challengeIdx: [2, 7],
  ),
  groupDisSpace(
    groupKey: 'groupDisSpace',
    label: 'Space',
    challengeIdx: [2, 7],
  ),
  groupDisResilience(
    groupKey: 'groupDisResilience',
    label: 'Resilience',
    challengeIdx: [2, 7],
  ),
  groupDisSustainability(
    groupKey: 'groupDisSustainability',
    label: 'Sustainability',
    challengeIdx: [2, 7],
  ),
  groupDisOther(
    groupKey: 'groupDisOther',
    label: 'Other',
    challengeIdx: [2, 7],
  ),

// GROUP SENSING AND SURVEILLANCE

  groupSnsAdvComputing(
    groupKey: 'groupSnsAdvComputing',
    label: 'Advanced Computing and Methods',
    challengeIdx: [3, 8],
  ),
  groupSnsAdvComponentsMaterialsManufacturing(
    groupKey: 'groupSnsAdvComponentsMaterialsManufacturing',
    label: 'Advanced Components, Material and Manufacturing',
    challengeIdx: [3, 8],
  ),
  groupSnsAI(
    groupKey: 'groupSnsAI',
    label: 'Artificial Intelligence and Machine Learning',
    challengeIdx: [3, 8],
  ),
  groupSnsAutonomousSystemsRobotics(
    groupKey: 'groupSnsAutonomousSystemsRobotics',
    label: 'Autonomous Systems and Robotics',
    challengeIdx: [3, 8],
  ),
  groupSnsData(
    groupKey: 'groupSnsData',
    label: 'Data',
    challengeIdx: [3, 8],
  ),
  groupSnsElectronicMeasures(
    groupKey: 'groupSnsElectronicMeasures',
    label: 'Electronic Measures (ECM, EPM, ESM)',
    challengeIdx: [3, 8],
  ),
  groupSnsPositioningNavigation(
    groupKey: 'groupSnsPositioningNavigation',
    label: 'Positioning and Navigation Technologies',
    challengeIdx: [3, 8],
  ),
  groupSnsRemoteSensing(
    groupKey: 'groupSnsRemoteSensing',
    label: 'Remote Sensing',
    challengeIdx: [3, 8],
  ),
  groupSnsSensors(
    groupKey: 'groupSnsSensors',
    label: 'Sensors',
    challengeIdx: [3, 8],
  ),
  groupSnsSpaceSurveillance(
    groupKey: 'groupSnsSpaceSurveillance',
    label: 'Space Surveillance Awareness & Tracking (SSA/SST)',
    challengeIdx: [3, 8],
  ),
  groupSnsTargetTracking(
    groupKey: 'groupSnsTargetTracking',
    label: 'Target Detection, Tracking, Classification and Recognition',
    challengeIdx: [3, 8],
  ),
  groupSnsSpace(
    groupKey: 'groupSnsSpace',
    label: 'Space',
    challengeIdx: [3, 8],
  ),
  groupSnsResilience(
    groupKey: 'groupSnsResilience',
    label: 'Resilience',
    challengeIdx: [3, 8],
  ),
  groupSnsSustainability(
    groupKey: 'groupSnsSustainability',
    label: 'Sustainability',
    challengeIdx: [3, 8],
  ),
  groupSnsOther(
    groupKey: 'groupSnsOther',
    label: 'Other',
    challengeIdx: [3, 8],
  ),

  groupCiAdvComputing(
    groupKey: 'groupCiAdvComputing',
    label: 'Advanced Computing and Methods',
    challengeIdx: [4, 9],
  ),
  groupCiAdvComponentsMaterialsManufacturing(
    groupKey: 'groupCiAdvComponentsMaterialsManufacturing',
    label: 'Advanced Components, Material and Manufacturing',
    challengeIdx: [4, 9],
  ),
  groupCiAI(
    groupKey: 'groupCiAI',
    label: 'Artificial Intelligence and Machine Learning',
    challengeIdx: [4, 9],
  ),
  groupCiAutonomousSystemsRobotics(
    groupKey: 'groupCiAutonomousSystemsRobotics',
    label: 'Autonomous Systems and Robotics',
    challengeIdx: [4, 9],
  ),
  groupCiCommsNetworking(
    groupKey: 'groupCiCommsNetworking',
    label: 'Communication and Networking Technologies',
    challengeIdx: [4, 9],
  ),
  groupCiEnergyPower(
    groupKey: 'groupCiEnergyPower',
    label: 'Energy and Power Technology',
    challengeIdx: [4, 9],
  ),
  groupCiHMI(
    groupKey: 'groupCiHMI',
    label: 'Human Machine Interfaces',
    challengeIdx: [4, 9],
  ),
  groupCiInspectionMonitoringRepair(
    groupKey: 'groupCiInspectionMonitoringRepair',
    label: 'Inspection, Monitoring and/or In-Situ Repair',
    challengeIdx: [4, 9],
  ),
  groupCiIntegratedComponentsSystems(
    groupKey: 'groupCiIntegratedComponentsSystems',
    label: 'Integrated Components and Systems',
    challengeIdx: [4, 9],
  ),
  groupCiIoT(
    groupKey: 'groupCiIoT',
    label: 'Internet of Things',
    challengeIdx: [4, 9],
  ),
  groupCiLogistics(
    groupKey: 'groupCiLogistics',
    label: 'Logistics',
    challengeIdx: [4, 9],
  ),
  groupCiNuclearTechnology(
    groupKey: 'groupCiNuclearTechnology',
    label: 'Nuclear Technology',
    challengeIdx: [4, 9],
  ),
  groupCiPositioningNavigation(
    groupKey: 'groupCiPositioningNavigation',
    label: 'Positioning and Navigation Technologies',
    challengeIdx: [4, 9],
  ),
  groupCiQuantum(
    groupKey: 'groupCiQuantum',
    label: 'Quantum',
    challengeIdx: [4, 9],
  ),
  groupCiRemoteSensing(
    groupKey: 'groupCiRemoteSensing',
    label: 'Remote Sensing',
    challengeIdx: [4, 9],
  ),
  groupCiSensors(
    groupKey: 'groupCiSensors',
    label: 'Sensors',
    challengeIdx: [4, 9],
  ),
  groupCiTransportation(
    groupKey: 'groupCiTransportation',
    label: 'Transportation Technologies',
    challengeIdx: [4, 9],
  ),
  groupCiWaterTreatment(
    groupKey: 'groupCiWaterTreatment',
    label: 'Water and Wastewater Treatment Techniques',
    challengeIdx: [4, 9],
  ),
  groupCiSpace(
    groupKey: 'groupCiSpace',
    label: 'Space',
    challengeIdx: [4, 9],
  ),
  groupCiResilience(
    groupKey: 'groupCiResilience',
    label: 'Resilience',
    challengeIdx: [4, 9],
  ),
  groupCiSustainability(
    groupKey: 'groupCiSustainability',
    label: 'Sustainability',
    challengeIdx: [4, 9],
  ),
  groupCiOther(
    groupKey: 'groupCiOther',
    label: 'Other',
    challengeIdx: [4, 9],
  ),

  groupHhpAdvComputing(
    groupKey: 'groupHhpAdvComputing',
    label: 'Advanced Computing and Methods',
    challengeIdx: [5, 10],
  ),
  groupHhpAdvComponentsMaterialsManufacturing(
    groupKey: 'groupHhpAdvComponentsMaterialsManufacturing',
    label: 'Advanced Components, Material and Manufacturing',
    challengeIdx: [5, 10],
  ),
  groupHhpAI(
    groupKey: 'groupHhpAI',
    label: 'Artificial Intelligence and Machine Learning',
    challengeIdx: [5, 10],
  ),
  groupHhpAutonomousSystemsRobotics(
    groupKey: 'groupHhpAutonomousSystemsRobotics',
    label: 'Autonomous Systems and Robotics',
    challengeIdx: [5, 10],
  ),
  groupHhpBioManufacturingMaterials(
    groupKey: 'groupHhpBioManufacturingMaterials',
    label: 'Bio-Manufacturing and Biomaterials',
    challengeIdx: [5, 10],
  ),
  groupHhpBiosensors(
    groupKey: 'groupHhpBiosensors',
    label: 'Biosensors and Physiological Detectors and Sensors',
    challengeIdx: [5, 10],
  ),
  groupHhpCBRN(
    groupKey: 'groupHhpCBRN',
    label: 'Chemical, Biological, Radiological and Nuclear (CBRN)',
    challengeIdx: [5, 10],
  ),
  groupHhpEmergencyMedicine(
    groupKey: 'groupHhpEmergencyMedicine',
    label: 'Emergency Medicine',
    challengeIdx: [5, 10],
  ),
  groupHhpExoskeletons(
    groupKey: 'groupHhpExoskeletons',
    label: 'Exoskeletons',
    challengeIdx: [5, 10],
  ),
  groupHhpHMI(
    groupKey: 'groupHhpHMI',
    label: 'Human Machine Interfaces',
    challengeIdx: [5, 10],
  ),
  groupHhpHumanSustainability(
    groupKey: 'groupHhpHumanSustainability',
    label: 'Human Sustainability',
    challengeIdx: [5, 10],
  ),
  groupHhpInternalMedicine(
    groupKey: 'groupHhpInternalMedicine',
    label: 'Internal Medicine',
    challengeIdx: [5, 10],
  ),
  groupHhpMedicalDevices(
    groupKey: 'groupHhpMedicalDevices',
    label: 'Medical Devices',
    challengeIdx: [5, 10],
  ),
  groupHhpMedicinesPharmaVaccines(
    groupKey: 'groupHhpMedicinesPharmaVaccines',
    label: 'Medicines, Pharmaceuticals and Vaccines',
    challengeIdx: [5, 10],
  ),
  groupHhpNeurology(
    groupKey: 'groupHhpNeurology',
    label: 'Neurology',
    challengeIdx: [5, 10],
  ),
  groupHhpPathology(
    groupKey: 'groupHhpPathology',
    label: 'Pathology',
    challengeIdx: [5, 10],
  ),
  groupHhpPhysicalMedicine(
    groupKey: 'groupHhpPhysicalMedicine',
    label: 'Physical Medicine and Rehabilitation',
    challengeIdx: [5, 10],
  ),
  groupHhpPreventiveMedicine(
    groupKey: 'groupHhpPreventiveMedicine',
    label: 'Preventive Medicine',
    challengeIdx: [5, 10],
  ),
  groupHhpRegulatedHealthApplications(
    groupKey: 'groupHhpRegulatedHealthApplications',
    label: 'Regulated Health Applications',
    challengeIdx: [5, 10],
  ),
  groupHhpSurgery(
    groupKey: 'groupHhpSurgery',
    label: 'Surgery',
    challengeIdx: [5, 10],
  ),
  groupHhpWearables(
    groupKey: 'groupHhpWearables',
    label: 'Wearables',
    challengeIdx: [5, 10],
  ),
  groupHhpSpace(
    groupKey: 'groupHhpSpace',
    label: 'Space',
    challengeIdx: [5, 10],
  ),
  groupHhpResilience(
    groupKey: 'groupHhpResilience',
    label: 'Resilience',
    challengeIdx: [5, 10],
  ),
  groupHhpSustainability(
    groupKey: 'groupHhpSustainability',
    label: 'Sustainability',
    challengeIdx: [5, 10],
  ),
  groupHhpOther(
    groupKey: 'groupHhpOther',
    label: 'Other',
    challengeIdx: [5, 10],
  ),
  ;

  const AppExperienceGroups({
    required this.groupKey,
    required this.label,
    required this.challengeIdx,
    //required this.tags,
  });

  final String groupKey;
  final String label;
  final List<int> challengeIdx;
  //final List<AppExperienceTags> tags;
}

enum AppExperienceTags {
// Advanced computing and methods
  subItemErAdvComputingAllAreas(
    key: 'subItemErAdvComputingAllAreas',
    title: 'All Areas',
    description:
        'Advanced computing and methods encompass a wide range of technologies and methodologies. This includes high-performance computing, quantum computing, and innovative approaches to complex problem-solving. These areas aim to revolutionize the way data and processes are handled.',
    parentKey: 'groupErAdvComputing',
    icon: FontAwesome5Solid.desktop,
  ),

  // Advanced components, material and manufacturing
  subItemErAdvComponentsAllAreas(
    key: 'subItemErAdvComponentsAllAreas',
    title: 'All Areas',
    description:
        'This group focuses on cutting-edge components, materials, and manufacturing methods. From additive manufacturing to advanced composites, these innovations drive efficiency and sustainability in production. The aim is to enhance performance while reducing environmental impact.',
    parentKey: 'groupErAdvComponentsMaterialsManufacturing',
    icon: FontAwesome5Solid.industry,
  ),

  // Artificial intelligence and machine learning
  subItemErAIAllAreas(
    key: 'subItemErAIAllAreas',
    title: 'All Areas',
    description:
        'Artificial intelligence and machine learning explore intelligent systems capable of decision-making and learning. These technologies enable breakthroughs in automation, prediction, and optimization across industries. AI continues to reshape the way humans interact with machines.',
    parentKey: 'groupErAIandML',
    icon: FontAwesome5Solid.robot,
  ),

  // Autonomous systems and robotics
  subItemErAutonomousSystemsAllAreas(
    key: 'subItemErAutonomousSystemsAllAreas',
    title: 'All Areas',
    description:
        'Autonomous systems and robotics include self-operating machines and software. Applications range from unmanned vehicles to industrial automation, enhancing efficiency and safety. These systems are designed to function independently while adapting to complex environments.',
    parentKey: 'groupErAutonomousSystemsRobotics',
    icon: FontAwesome5Solid.robot,
  ),

  // Communication and networking technologies
  subItemErCommsNetworkingAllAreas(
    key: 'subItemErCommsNetworkingAllAreas',
    title: 'All Areas',
    description:
        'This category covers the development of advanced communication protocols and networking infrastructure. It includes wireless, satellite, and fiber-optic technologies designed to improve connectivity. These advancements enable faster, more reliable data transmission globally.',
    parentKey: 'groupErCommsNetworking',
    icon: FontAwesome5Solid.network_wired,
  ),

  // Energy and power transmission
  subItemErEnergyPowerTransmissionAllAreas(
    key: 'subItemErEnergyPowerTransmissionAllAreas',
    title: 'All Areas',
    description:
        'Energy and power transmission focus on transferring energy efficiently and reliably across distances. This includes innovations in grid systems, renewable energy integration, and smart transmission technologies. Advances aim to reduce losses and improve system resilience.',
    parentKey: 'groupErEnergyPowerTransmission',
    icon: FontAwesome5Solid.plug,
  ),
  subItemErEnergyPowerCables(
    key: 'subItemErEnergyPowerCables',
    title: 'Cables',
    description:
        'Energy power cables are the backbone of traditional power transmission systems. These cables enable the transport of electricity over long distances, connecting generation sites with consumption points. Innovations aim to make them more durable and efficient.',
    parentKey: 'groupErEnergyPowerTransmission',
    icon: FontAwesome5Solid.plug,
  ),
  subItemErEnergyPowerWireless(
    key: 'subItemErEnergyPowerWireless',
    title: 'Wireless Power Transmission',
    description:
        'Wireless power transmission eliminates the need for physical cables, enabling energy transfer through the air. This technology is particularly useful in remote or hard-to-access areas. Advances in this field promise a future with reduced reliance on traditional infrastructure.',
    parentKey: 'groupErEnergyPowerTransmission',
    icon: FontAwesome5Solid.wifi,
  ),

  // Energy generation
  subItemErEnergyGenerationAllAreas(
    key: 'subItemErEnergyGenerationAllAreas',
    title: 'All Areas',
    description:
        'Energy generation encompasses technologies and methods to produce energy sustainably and efficiently. It includes both conventional and renewable sources such as nuclear, solar, and wind. The goal is to meet global energy demands while minimizing environmental impact.',
    parentKey: 'groupErEnergyGeneration',
    icon: FontAwesome5Solid.atom,
  ),
  subItemErEnergyGenerationHydrogen(
    key: 'subItemErEnergyGenerationHydrogen',
    title: 'Hydrogen',
    description:
        'Hydrogen energy focuses on producing and utilizing hydrogen as a clean energy source. This includes fuel cells and hydrogen-powered systems for vehicles and industries. The technology aims to reduce carbon emissions and increase energy efficiency.',
    parentKey: 'groupErEnergyGeneration',
    icon: FontAwesome5Solid.atom,
  ),
  subItemErEnergyGenerationNuclear(
    key: 'subItemErEnergyGenerationNuclear',
    title: 'Nuclear',
    description:
        'Nuclear energy is a powerful source of electricity derived from splitting atoms. This technology provides a steady and reliable energy supply while reducing greenhouse gas emissions. Innovations are improving reactor safety and waste management.',
    parentKey: 'groupErEnergyGeneration',
    icon: FontAwesome5Solid.radiation,
  ),
  subItemErEnergyGenerationBioFuels(
    key: 'subItemErEnergyGenerationBioFuels',
    title: 'Renewable Bio-Fuels',
    description:
        'Renewable bio-fuels are derived from organic matter, offering a sustainable energy alternative. Applications range from transportation fuels to electricity generation. Research focuses on improving efficiency and scalability of these solutions.',
    parentKey: 'groupErEnergyGeneration',
    icon: MaterialCommunityIcons.leaf,
  ),
  subItemErEnergyGenerationRenewables(
    key: 'subItemErEnergyGenerationRenewables',
    title: 'Renewables',
    description:
        'Renewable energy sources encompass solar, wind, hydro, and bioenergy. These technologies are essential for reducing carbon emissions and mitigating climate change. Research focuses on increasing efficiency and integration into the grid.',
    parentKey: 'groupErEnergyGeneration',
    icon: FontAwesome5Solid.seedling,
  ),
  subItemErEnergyGenerationRenewablesHardware(
    key: 'subItemErEnergyGenerationRenewablesHardware',
    title: 'Renewables Hardware',
    description:
        'Hardware innovations for renewable energy systems include solar panels, wind turbines, and storage devices. These components improve efficiency and reliability of energy generation. Continued advancements aim to lower costs and enhance durability.',
    parentKey: 'groupErEnergyGeneration',
    icon: FontAwesome5Solid.toolbox,
  ),
  subItemErEnergyGenerationRenewablesSoftware(
    key: 'subItemErEnergyGenerationRenewablesSoftware',
    title: 'Renewables Software',
    description:
        'Software solutions for renewable energy optimize performance, predict maintenance, and manage resources. They include grid integration tools and energy forecasting models. These advancements enhance the reliability and sustainability of renewable systems.',
    parentKey: 'groupErEnergyGeneration',
    icon: FontAwesome5Solid.code,
  ),
  subItemErEnergyGenerationSolar(
    key: 'subItemErEnergyGenerationSolar',
    title: 'Solar',
    description:
        'Solar energy harnesses sunlight to produce electricity or heat. Photovoltaic cells and solar thermal systems are key technologies in this area. These systems contribute significantly to reducing fossil fuel dependency and carbon emissions.',
    parentKey: 'groupErEnergyGeneration',
    icon: FontAwesome5Solid.sun,
  ),
  subItemErEnergyGenerationWind(
    key: 'subItemErEnergyGenerationWind',
    title: 'Wind',
    description:
        'Wind energy uses turbines to convert wind into electricity. This renewable energy source is highly scalable and suitable for both onshore and offshore installations. Continued advancements aim to enhance turbine efficiency and durability.',
    parentKey: 'groupErEnergyGeneration',
    icon: FontAwesome.windows,
  ),

  // Additional Categories
  subItemErGridIntegrationAllAreas(
    key: 'subItemErGridIntegrationAllAreas',
    title: 'All Areas',
    description:
        'Grid integration focuses on connecting various energy sources to create stable and efficient power systems. This includes balancing supply and demand and integrating renewables. Advanced grid technologies improve resilience and reduce energy losses.',
    parentKey: 'groupErGridIntegration',
    icon: FontAwesome5Solid.network_wired,
  ),
  subItemErHybridEnergyPowerAllAreas(
    key: 'subItemErHybridEnergyPowerAllAreas',
    title: 'All Areas',
    description:
        'Hybrid energy systems combine multiple energy sources to optimize performance and reliability. These systems integrate renewables with conventional sources for stable output. They play a key role in transitioning to a sustainable energy future.',
    parentKey: 'groupErHybridEnergyPower',
    icon: FontAwesome5Solid.plug,
  ),
  subItemErMicrogridsAllAreas(
    key: 'subItemErMicrogridsAllAreas',
    title: 'All Areas',
    description:
        'Microgrids are localized energy systems capable of operating independently or connected to the grid. They are vital for providing energy to remote areas and enhancing energy security. Innovations aim to improve their scalability and cost-effectiveness.',
    parentKey: 'groupErMicrogrids',
    icon: FontAwesome5Solid.industry,
  ),
  subItemErSensorsDetectorsAllAreas(
    key: 'subItemErSensorsDetectorsAllAreas',
    title: 'All Areas',
    description:
        'Sensors and detectors enable monitoring and data collection across a variety of applications. From industrial automation to environmental monitoring, they provide critical insights. Advances focus on improving accuracy, sensitivity, and integration capabilities.',
    parentKey: 'groupErSensorsDetectors',
    icon: FontAwesome5Solid.eye,
  ),
  subItemErSpaceBasedEnergyAllAreas(
    key: 'subItemErSpaceBasedEnergyAllAreas',
    title: 'All Areas',
    description:
        'Space-based energy focuses on harnessing energy from space, including solar power satellites. These systems aim to deliver consistent and renewable energy to Earth. Research focuses on cost-effective deployment and transmission technologies.',
    parentKey: 'groupErSpaceBasedEnergy',
    icon: FontAwesome5Solid.globe,
  ),
  subItemErSpaceAllAreas(
    key: 'subItemErSpaceAllAreas',
    title: 'All Areas',
    description:
        'Space technologies encompass satellite communication, exploration, and earth observation. These systems are integral to advancing knowledge and capabilities beyond Earth. Innovations focus on improving efficiency and expanding human presence in space.',
    parentKey: 'groupErSpace',
    icon: FontAwesome5Solid.space_shuttle,
  ),
  subItemErResilienceAllAreas(
    key: 'subItemErResilienceAllAreas',
    title: 'All Areas',
    description:
        'Resilience technologies focus on adapting systems to withstand and recover from disruptions. Applications include disaster management, critical infrastructure protection, and climate adaptation. Research aims to create robust and adaptive solutions for complex challenges.',
    parentKey: 'groupErResilience',
    icon: FontAwesome5Solid.shield_alt,
  ),
  subItemErSustainabilityAllAreas(
    key: 'subItemErSustainabilityAllAreas',
    title: 'All Areas',
    description:
        'Sustainability initiatives focus on balancing economic growth, environmental health, and social well-being. They include reducing resource consumption, minimizing waste, and promoting renewable energy. Advances aim to create long-term, impactful change.',
    parentKey: 'groupErSustainability',
    icon: FontAwesome5Solid.recycle,
  ),
  subItemErOtherAllAreas(
    key: 'subItemErOtherAllAreas',
    title: 'All Areas',
    description:
        'This category covers miscellaneous areas that do not fit into specific predefined groups. It encompasses diverse and innovative topics that push the boundaries of current knowledge. Research in these areas often paves the way for groundbreaking advancements.',
    parentKey: 'groupErOther',
    icon: FontAwesome5Solid.question,
  ),

  // DATA AND INFORMATION SHARING

  // Advanced Computing and Methods
  subItemDisAdvComputingAllAreas(
    key: 'subItemDisAdvComputingAllAreas',
    title: 'All Areas',
    description:
        'Covers all areas of advanced computing and methods, focusing on innovation in algorithms, processing, and modeling.',
    parentKey: 'groupDisAdvComputing',
    icon: FontAwesome5Solid.desktop,
  ),
  subItemDisAdvComputingAlgorithms(
    key: 'subItemDisAdvComputingAlgorithms',
    title: 'Advanced Algorithms',
    description:
        'Focuses on advanced algorithms, including NLP, neuromorphic computing, and complex computational models.',
    parentKey: 'groupDisAdvComputing',
    icon: FontAwesome5Solid.code,
  ),
  subItemDisDigitalTwinning(
    key: 'subItemDisDigitalTwinning',
    title: 'Digital Twinning',
    description:
        'Explores the creation of digital replicas for simulation, optimization, and monitoring of physical systems.',
    parentKey: 'groupDisAdvComputing',
    icon: FontAwesome5Solid.project_diagram,
  ),
  subItemDisEdgeComputing(
    key: 'subItemDisEdgeComputing',
    title: 'Edge Computing',
    description:
        'Focuses on decentralized data processing near the source to reduce latency and bandwidth use.',
    parentKey: 'groupDisAdvComputing',
    icon: FontAwesome5Solid.network_wired,
  ),

  // Artificial Intelligence and Machine Learning
  subItemDisAIAllAreas(
    key: 'subItemDisAIAllAreas',
    title: 'All Areas',
    description:
        'Covers all areas of AI and machine learning, focusing on enhancing decision-making and automation.',
    parentKey: 'groupDisAI',
    icon: FontAwesome5Solid.robot,
  ),
  subItemDisDeepFakeDetection(
    key: 'subItemDisDeepFakeDetection',
    title: 'Deep Fake Detection',
    description:
        'Focuses on detecting and mitigating deep fake media, ensuring authenticity and trust in digital content.',
    parentKey: 'groupDisAI',
    icon: FontAwesome5Solid.eye_slash,
  ),

  // Communication and Networking Technologies
  subItemDisCommsNetworkingAllAreas(
    key: 'subItemDisCommsNetworkingAllAreas',
    title: 'All Areas',
    description:
        'Covers all aspects of communication and networking technologies for secure and reliable data exchange.',
    parentKey: 'groupDisCommsNetworking',
    icon: FontAwesome5Solid.network_wired,
  ),
  subItemDisNextGenWireless(
    key: 'subItemDisNextGenWireless',
    title: 'Next Generation Wireless Networks',
    description:
        'Explores advancements in wireless technologies, including 5G and 6G, for enhanced connectivity.',
    parentKey: 'groupDisCommsNetworking',
    icon: FontAwesome5Solid.wifi,
  ),
  subItemDisOpticalWireless(
    key: 'subItemDisOpticalWireless',
    title: 'Optical Wireless Communication',
    description:
        'Covers wireless communication systems using optical technologies for high-speed and interference-free transmission.',
    parentKey: 'groupDisCommsNetworking',
    icon: FontAwesome5Solid.lightbulb,
  ),
  subItemDisRFSATCOM(
    key: 'subItemDisRFSATCOM',
    title: 'RF / SATCOM Wireless Communication',
    description:
        'Includes RF and satellite-based systems for robust, long-range communication.',
    parentKey: 'groupDisCommsNetworking',
    icon: FontAwesome5Solid.satellite_dish,
  ),

  // Cyber Security
  subItemDisCyberSecurityForensics(
    key: 'subItemDisCyberSecurityForensics',
    title: 'Forensics',
    description:
        'Focuses on cyber forensics to investigate and analyze digital crimes and security breaches.',
    parentKey: 'groupDisCyberSecurity',
    icon: FontAwesome5Solid.search,
  ),
  subItemDisThreatDetectionPrevention(
    key: 'subItemDisThreatDetectionPrevention',
    title: 'Threat Detection & Prevention',
    description:
        'Includes advanced tools and methodologies to identify and mitigate cyber threats.',
    parentKey: 'groupDisCyberSecurity',
    icon: FontAwesome5Solid.shield_alt,
  ),

  // Data
  subItemDisDataAllAreas(
    key: 'subItemDisDataAllAreas',
    title: 'All Areas',
    description:
        'Covers all areas of data management, security, and analytics for decision-making.',
    parentKey: 'groupDisData',
    icon: FontAwesome5Solid.database,
  ),
  subItemDisDataSecurityDataCentric(
    key: 'subItemDisDataSecurityDataCentric',
    title: 'Data Centric Security',
    description:
        'Focuses on securing data directly rather than securing the systems that store or process it.',
    parentKey: 'groupDisData',
    icon: FontAwesome5Solid.lock,
  ),
  subItemDisDataSecurityEncryption(
    key: 'subItemDisDataSecurityEncryption',
    title: 'Encryption',
    description:
        'Explores secure encryption methods to protect data at rest and in transit.',
    parentKey: 'groupDisData',
    icon: FontAwesome5Solid.key,
  ),
  subItemDisZeroTrustArchitectures(
    key: 'subItemDisZeroTrustArchitectures',
    title: 'Zero Trust Architectures',
    description:
        'Focuses on zero trust models to secure data and systems from unauthorized access.',
    parentKey: 'groupDisData',
    icon: FontAwesome5Solid.user_shield,
  ),
  subItemDisBigDataAnalytics(
    key: 'subItemDisBigDataAnalytics',
    title: 'Big Data and Analytics',
    description:
        'Covers the use of big data analytics to extract insights and drive decision-making.',
    parentKey: 'groupDisData',
    icon: FontAwesome5Solid.chart_bar,
  ),
  subItemDisIntegrationInteroperability(
    key: 'subItemDisIntegrationInteroperability',
    title: 'Integration and Interoperability',
    description:
        'Explores the seamless integration of diverse data sources and ensuring interoperability.',
    parentKey: 'groupDisData',
    icon: FontAwesome5Solid.exchange_alt,
  ),
  subItemDisSyntheticDataGeneration(
    key: 'subItemDisSyntheticDataGeneration',
    title: 'Synthetic Data Generation',
    description:
        'Includes techniques for generating synthetic data to train, test, and validate systems.',
    parentKey: 'groupDisData',
    icon: FontAwesome5Solid.cogs,
  ),

  // Internet of Things
  subItemDisIoTHardware(
    key: 'subItemDisIoTHardware',
    title: 'IoT Hardware',
    description:
        'Focuses on IoT hardware, including sensors and connected devices for data collection and monitoring.',
    parentKey: 'groupDisIoT',
    icon: FontAwesome5Solid.microchip,
  ),

  // Hardware
  subItemDisHardwareOptical(
    key: 'subItemDisHardwareOptical',
    title: 'Optical Based Hardware',
    description:
        'Explores optical technologies for high-speed computing and communication systems.',
    parentKey: 'groupDisHardware',
    icon: FontAwesome5Solid.lightbulb,
  ),
  subItemDisHardwareSilicon(
    key: 'subItemDisHardwareSilicon',
    title: 'Silicon Based Hardware',
    description:
        'Covers silicon-based architectures, including RISC-V, FPGA, and ARM processors.',
    parentKey: 'groupDisHardware',
    icon: FontAwesome5Solid.microchip,
  ),

  // Human Machine Interfaces
  subItemDisVirtualAugmentedReality(
    key: 'subItemDisVirtualAugmentedReality',
    title: 'Virtual or Augmented Reality',
    description:
        'Includes VR/AR systems for training, simulations, and enhanced user interaction.',
    parentKey: 'groupDisHMI',
    icon: FontAwesome5Solid.vr_cardboard,
  ),

  // Platforms
  subItemDisPlatformsAirborne(
    key: 'subItemDisPlatformsAirborne',
    title: 'Airborne Platforms',
    description:
        'Covers drones, high-altitude platforms, and satellites for sensing and data collection.',
    parentKey: 'groupDisPlatforms',
    icon: FontAwesome5Solid.dragon,
  ),
  subItemDisPlatformsLandUndersea(
    key: 'subItemDisPlatformsLandUndersea',
    title: 'Land / Undersea Platforms',
    description:
        'Focuses on platforms for terrestrial and underwater data collection and monitoring.',
    parentKey: 'groupDisPlatforms',
    icon: FontAwesome5Solid.truck,
  ),

  // Quantum
  subItemDisQuantumAllAreas(
    key: 'subItemDisQuantumAllAreas',
    title: 'All Areas',
    description:
        'Explores all areas of quantum science, including computation, cryptography, and sensing.',
    parentKey: 'groupDisQuantum',
    icon: FontAwesome5Solid.atom,
  ),
  subItemDisQuantumCryptography(
    key: 'subItemDisQuantumCryptography',
    title: 'Cryptography / Quantum Safe Cryptography',
    description:
        'Focuses on quantum-safe cryptographic methods for secure data communication.',
    parentKey: 'groupDisQuantum',
    icon: FontAwesome5Solid.key,
  ),
  subItemDisQuantumHardware(
    key: 'subItemDisQuantumHardware',
    title: 'Quantum Hardware',
    description:
        'Covers hardware for quantum computation, simulation, and sensing.',
    parentKey: 'groupDisQuantum',
    icon: FontAwesome5Solid.server,
  ),
  subItemDisQuantumPNT(
    key: 'subItemDisQuantumPNT',
    title: 'Positioning, Navigation, and Timing (PNT)',
    description:
        'Explores quantum technologies for precise positioning and navigation.',
    parentKey: 'groupDisQuantum',
    icon: FontAwesome5Solid.map_marker_alt,
  ),
  subItemDisQuantumKeyDistribution(
    key: 'subItemDisQuantumKeyDistribution',
    title: 'Quantum Key Distribution',
    description:
        'Includes secure communication protocols using quantum mechanics for key exchange.',
    parentKey: 'groupDisQuantum',
    icon: FontAwesome5Solid.exchange_alt,
  ),

  // Space
  subItemDisSpaceAllAreas(
    key: 'subItemDisSpaceAllAreas',
    title: 'All Areas',
    description:
        'Includes all aspects of space exploration, sensing, and satellite systems.',
    parentKey: 'groupDisSpace',
    icon: FontAwesome5Solid.space_shuttle,
  ),

  // Resilience
  subItemDisResilienceAllAreas(
    key: 'subItemDisResilienceAllAreas',
    title: 'All Areas',
    description:
        'Focuses on building resilient systems to recover from and withstand disruptions.',
    parentKey: 'groupDisResilience',
    icon: FontAwesome5Solid.shield_alt,
  ),

  // Sustainability
  subItemDisSustainabilityAllAreas(
    key: 'subItemDisSustainabilityAllAreas',
    title: 'All Areas',
    description:
        'Covers sustainable practices for data security and system longevity.',
    parentKey: 'groupDisSustainability',
    icon: FontAwesome5Solid.recycle,
  ),

  // Other
  subItemDisOtherAllAreas(
    key: 'subItemDisOtherAllAreas',
    title: 'All Areas',
    description:
        'Includes emerging and miscellaneous topics in data and information security.',
    parentKey: 'groupDisOther',
    icon: FontAwesome5Solid.question,
  ),

  // SENSING AND SURVEILLANCE

  // Advanced Computing and Methods
  subItemSnsAdvComputingAllAreas(
    key: 'subItemSnsAdvComputingAllAreas',
    title: 'All Areas',
    description:
        'Covers all areas of advanced computing and methods, focusing on signal processing and computational efficiency.',
    parentKey: 'groupSnsAdvComputing',
    icon: FontAwesome5Solid.desktop,
  ),
  subItemSnsDigitalSignalProcessing(
    key: 'subItemSnsDigitalSignalProcessing',
    title: 'Digital Signal Processing',
    description:
        'Focuses on processing digital signals for applications such as image, sound, and sensor data.',
    parentKey: 'groupSnsAdvComputing',
    icon: FontAwesome5Solid.wifi,
  ),

  // Advanced Components, Material and Manufacturing
  subItemSnsAdvComponentsAllAreas(
    key: 'subItemSnsAdvComponentsAllAreas',
    title: 'All Areas',
    description:
        'Encompasses advanced components, materials, and manufacturing methods for sensing technologies.',
    parentKey: 'groupSnsAdvComponentsMaterialsManufacturing',
    icon: FontAwesome5Solid.industry,
  ),

  // Artificial Intelligence and Machine Learning
  subItemSnsAIAllAreas(
    key: 'subItemSnsAIAllAreas',
    title: 'All Areas',
    description:
        'Includes all areas of AI and ML, with a focus on enhancing surveillance and sensing capabilities.',
    parentKey: 'groupSnsAI',
    icon: FontAwesome5Solid.robot,
  ),

  // Autonomous Systems and Robotics
  subItemSnsAutonomousSystemsAllAreas(
    key: 'subItemSnsAutonomousSystemsAllAreas',
    title: 'All Areas',
    description:
        'Covers autonomous systems, including UAVs, UAS, USVs, UGVs, and RPAs for surveillance and sensing tasks.',
    parentKey: 'groupSnsAutonomousSystemsRobotics',
    icon: FontAwesome5Solid.robot,
  ),
  subItemSnsUnmannedSystems(
    key: 'subItemSnsUnmannedSystems',
    title: 'Unmanned Systems',
    description:
        'Focuses on unmanned systems, such as UAVs, USVs, and RPAs, for surveillance and operational tasks.',
    parentKey: 'groupSnsAutonomousSystemsRobotics',
    icon: FontAwesome5Solid.robot,
  ),

  // Data
  subItemSnsDataAllAreas(
    key: 'subItemSnsDataAllAreas',
    title: 'All Areas',
    description:
        'Covers all areas of data, focusing on processing, fusion, and analytics for sensing and surveillance.',
    parentKey: 'groupSnsData',
    icon: FontAwesome5Solid.database,
  ),
  subItemSnsImageProcessing(
    key: 'subItemSnsImageProcessing',
    title: 'Image Processing',
    description:
        'Focuses on image processing techniques, including pattern recognition and computer vision.',
    parentKey: 'groupSnsData',
    icon: FontAwesome5Solid.image,
  ),
  subItemSnsSensorDataFusion(
    key: 'subItemSnsSensorDataFusion',
    title: 'Sensor Data Processing and Fusion',
    description:
        'Explores methods to process and integrate data from multiple sensors for enhanced decision-making.',
    parentKey: 'groupSnsData',
    icon: FontAwesome5Solid.cogs,
  ),

  // Electronic Measures
  subItemSnsECM(
    key: 'subItemSnsECM',
    title: 'Electronic Counter Measure (ECM)',
    description:
        'Includes methods to disrupt or deceive enemy electronic systems to gain operational advantage.',
    parentKey: 'groupSnsElectronicMeasures',
    icon: FontAwesome5Solid.bolt,
  ),
  subItemSnsEPM(
    key: 'subItemSnsEPM',
    title: 'Electronic Protective Measure (EPM)',
    description:
        'Focuses on techniques to protect electronic systems from jamming and interference.',
    parentKey: 'groupSnsElectronicMeasures',
    icon: FontAwesome5Solid.shield_alt,
  ),
  subItemSnsESM(
    key: 'subItemSnsESM',
    title: 'Electronic Support Measure (ESM)',
    description:
        'Covers methods to detect and analyze enemy electronic emissions for intelligence and targeting.',
    parentKey: 'groupSnsElectronicMeasures',
    icon: FontAwesome5Solid.search,
  ),

  // Positioning and Navigation
  subItemSnsPositioningNavigation(
    key: 'subItemSnsPositioningNavigation',
    title: 'Positioning and Navigation Technologies',
    description:
        'Explores advanced positioning and navigation systems for precise location tracking in various environments.',
    parentKey: 'groupSnsPositioningNavigation',
    icon: FontAwesome5Solid.map_marker_alt,
  ),

  // Remote Sensing
  subItemSnsImagingSystems(
    key: 'subItemSnsImagingSystems',
    title: 'Imaging Systems (Visible, Infrared, Ultraviolet)',
    description:
        'Includes imaging systems for remote sensing in visible, infrared, and ultraviolet spectra.',
    parentKey: 'groupSnsRemoteSensing',
    icon: FontAwesome5Solid.camera,
  ),

  // Sensors
  subItemSnsSensorsAllAreas(
    key: 'subItemSnsSensorsAllAreas',
    title: 'All Areas',
    description:
        'Encompasses all sensor types, including acoustic, radar, biosensors, and more, for surveillance tasks.',
    parentKey: 'groupSnsSensors',
    icon: FontAwesome5Solid.eye,
  ),
  subItemSnsAcousticPassive(
    key: 'subItemSnsAcousticPassive',
    title: 'Acoustic Passive Sensors',
    description:
        'Focuses on passive acoustic sensors for sound detection and localization.',
    parentKey: 'groupSnsSensors',
    icon: FontAwesome5Solid.microphone,
  ),
  subItemSnsActivePassiveRadar(
    key: 'subItemSnsActivePassiveRadar',
    title: 'Active and Passive Radar',
    description:
        'Covers radar systems for active signal transmission and passive signal reception.',
    parentKey: 'groupSnsSensors',
    icon: FontAwesome5Solid.satellite,
  ),
  subItemSnsBiosensors(
    key: 'subItemSnsBiosensors',
    title: 'Biosensors',
    description:
        'Includes biosensors for detecting biological agents and monitoring physiological states.',
    parentKey: 'groupSnsSensors',
    icon: FontAwesome5Solid.dna,
  ),
  subItemSnsLidarLadar(
    key: 'subItemSnsLidarLadar',
    title: 'LIDAR / LADAR',
    description:
        'Explores light detection and ranging (LIDAR) and laser detection and ranging (LADAR) systems.',
    parentKey: 'groupSnsSensors',
    icon: FontAwesome5Solid.ruler,
  ),

  // Space Surveillance
  subItemSnsSpaceSurveillanceAllAreas(
    key: 'subItemSnsSpaceSurveillanceAllAreas',
    title: 'All Areas',
    description:
        'Includes all aspects of space surveillance, awareness, and tracking technologies.',
    parentKey: 'groupSnsSpaceSurveillance',
    icon: FontAwesome5Solid.satellite_dish,
  ),

  // Target Detection and Tracking
  subItemSnsTargetTracking(
    key: 'subItemSnsTargetTracking',
    title: 'Target Detection, Tracking, Classification, and Recognition',
    description:
        'Focuses on identifying, monitoring, and classifying targets in dynamic environments.',
    parentKey: 'groupSnsTargetTracking',
    icon: FontAwesome5Solid.crosshairs,
  ),

  // Space
  subItemSnsSpaceAllAreas(
    key: 'subItemSnsSpaceAllAreas',
    title: 'All Areas',
    description:
        'Includes space exploration, tracking, and satellite systems for sensing applications.',
    parentKey: 'groupSnsSpace',
    icon: FontAwesome5Solid.space_shuttle,
  ),

  // Resilience
  subItemSnsResilienceAllAreas(
    key: 'subItemSnsResilienceAllAreas',
    title: 'All Areas',
    description:
        'Focuses on building resilient systems capable of withstanding and recovering from disruptions.',
    parentKey: 'groupSnsResilience',
    icon: FontAwesome5Solid.shield_alt,
  ),

  // Sustainability
  subItemSnsSustainabilityAllAreas(
    key: 'subItemSnsSustainabilityAllAreas',
    title: 'All Areas',
    description:
        'Covers sustainable technologies and practices for long-term sensing and surveillance capabilities.',
    parentKey: 'groupSnsSustainability',
    icon: FontAwesome5Solid.recycle,
  ),

  // Other
  subItemSnsOtherAllAreas(
    key: 'subItemSnsOtherAllAreas',
    title: 'All Areas',
    description:
        'Covers miscellaneous and emerging topics in sensing and surveillance.',
    parentKey: 'groupSnsOther',
    icon: FontAwesome5Solid.question,
  ),

  // CRITICAL INFRASTRUCTURE

  // Advanced Computing and Methods
  subItemCiAdvComputingAllAreas(
    key: 'subItemCiAdvComputingAllAreas',
    title: 'All Areas',
    description:
        'Covers all areas of advanced computing and methods, focusing on infrastructure optimization and resilience.',
    parentKey: 'groupCiAdvComputing',
    icon: FontAwesome5Solid.desktop,
  ),

  // Advanced Components, Materials, and Manufacturing
  subItemCiAdvComponentsAllAreas(
    key: 'subItemCiAdvComponentsAllAreas',
    title: 'All Areas',
    description:
        'Includes advanced components, materials, and manufacturing methods to enhance critical infrastructure durability.',
    parentKey: 'groupCiAdvComponentsMaterialsManufacturing',
    icon: FontAwesome5Solid.industry,
  ),

  // Artificial Intelligence and Machine Learning
  subItemCiAIAllAreas(
    key: 'subItemCiAIAllAreas',
    title: 'All Areas',
    description:
        'Focuses on all areas of artificial intelligence and machine learning for predictive maintenance and optimization.',
    parentKey: 'groupCiAI',
    icon: FontAwesome5Solid.robot,
  ),

  // Autonomous Systems and Robotics
  subItemCiAutonomousSystemsAllAreas(
    key: 'subItemCiAutonomousSystemsAllAreas',
    title: 'All Areas',
    description:
        'Includes all autonomous systems for air, surface, and space applications in infrastructure management.',
    parentKey: 'groupCiAutonomousSystemsRobotics',
    icon: FontAwesome5Solid.robot,
  ),
  subItemCiAutonomousSystemsAir(
    key: 'subItemCiAutonomousSystemsAir',
    title: 'Air',
    description:
        'Covers autonomous systems for aerial applications, including UAVs and high-altitude platforms.',
    parentKey: 'groupCiAutonomousSystemsRobotics',
    icon: FontAwesome5Solid.dragon,
  ),
  subItemCiAutonomousSystemsDrones(
    key: 'subItemCiAutonomousSystemsDrones',
    title: 'Drones',
    description:
        'Focuses on drones for inspection, monitoring, and operational support in critical infrastructure.',
    parentKey: 'groupCiAutonomousSystemsRobotics',
    icon: FontAwesome5Solid.helicopter,
  ),
  subItemCiAutonomousSystemsSpace(
    key: 'subItemCiAutonomousSystemsSpace',
    title: 'Space',
    description:
        'Explores space-based autonomous systems for infrastructure resilience and monitoring.',
    parentKey: 'groupCiAutonomousSystemsRobotics',
    icon: FontAwesome5Solid.space_shuttle,
  ),
  subItemCiAutonomousSystemsSurfaces(
    key: 'subItemCiAutonomousSystemsSurfaces',
    title: 'Surfaces',
    description:
        'Includes surface-based systems such as UGVs for inspection and operational efficiency.',
    parentKey: 'groupCiAutonomousSystemsRobotics',
    icon: FontAwesome5Solid.truck,
  ),

  // Communication and Networking Technologies
  subItemCiCommsNetworkingAllAreas(
    key: 'subItemCiCommsNetworkingAllAreas',
    title: 'All Areas',
    description:
        'Covers all aspects of communication and networking technologies, including wireless and cable-based systems.',
    parentKey: 'groupCiCommsNetworking',
    icon: FontAwesome5Solid.network_wired,
  ),
  subItemCiNextGenWireless(
    key: 'subItemCiNextGenWireless',
    title: 'Next Generation Wireless Networks',
    description:
        'Focuses on 5G, 6G, and other advanced wireless technologies for reliable communication.',
    parentKey: 'groupCiCommsNetworking',
    icon: FontAwesome5Solid.wifi,
  ),
  subItemCiTerrestrialUnderseaCables(
    key: 'subItemCiTerrestrialUnderseaCables',
    title: 'Terrestrial / Undersea Cables',
    description:
        'Explores terrestrial and undersea cable systems for global communication and data transmission.',
    parentKey: 'groupCiCommsNetworking',
    icon: FontAwesome5Solid.network_wired,
  ),

  // Energy and Power Technology
  subItemCiEnergyPowerAllAreas(
    key: 'subItemCiEnergyPowerAllAreas',
    title: 'All Areas',
    description:
        'Covers all areas of energy and power technologies, focusing on sustainable and reliable solutions.',
    parentKey: 'groupCiEnergyPower',
    icon: FontAwesome5Solid.bolt,
  ),
  subItemCiEnergyPowerBatteries(
    key: 'subItemCiEnergyPowerBatteries',
    title: 'Batteries',
    description:
        'Focuses on advanced battery technologies for energy storage and grid integration.',
    parentKey: 'groupCiEnergyPower',
    icon: FontAwesome5Solid.battery_full,
  ),
  subItemCiEnergyPowerStorage(
    key: 'subItemCiEnergyPowerStorage',
    title: 'Energy Storage',
    description:
        'Covers all aspects of energy storage, including batteries and alternative storage solutions.',
    parentKey: 'groupCiEnergyPower',
    icon: FontAwesome5Solid.charging_station,
  ),
  subItemCiEnergyPowerGridIntegration(
    key: 'subItemCiEnergyPowerGridIntegration',
    title: 'Grid Integration',
    description:
        'Focuses on integrating renewable energy sources into existing grid systems.',
    parentKey: 'groupCiEnergyPower',
    icon: FontAwesome5Solid.plug,
  ),
  subItemCiEnergyPowerRenewables(
    key: 'subItemCiEnergyPowerRenewables',
    title: 'Renewables',
    description:
        'Explores renewable energy technologies, including solar and wind, for sustainable power generation.',
    parentKey: 'groupCiEnergyPower',
    icon: FontAwesome5Solid.seedling,
  ),

  // Human Machine Interfaces
  subItemCiHMIAllAreas(
    key: 'subItemCiHMIAllAreas',
    title: 'All Areas',
    description:
        'Includes all human-machine interfaces, focusing on virtual and augmented reality technologies.',
    parentKey: 'groupCiHMI',
    icon: FontAwesome5Solid.vr_cardboard,
  ),
  subItemCiVirtualAugmentedReality(
    key: 'subItemCiVirtualAugmentedReality',
    title: 'Virtual or Augmented Reality',
    description:
        'Explores the use of VR/AR for immersive interaction and operational efficiency in critical infrastructure.',
    parentKey: 'groupCiHMI',
    icon: FontAwesome5Solid.eye,
  ),

  // Inspection, Monitoring, and/or In-Situ Repair
  subItemCiInspectionMonitoringRepairAllAreas(
    key: 'subItemCiInspectionMonitoringRepairAllAreas',
    title: 'All Areas',
    description:
        'Focuses on technologies and systems for inspecting, monitoring, and repairing critical infrastructure.',
    parentKey: 'groupCiInspectionMonitoringRepair',
    icon: FontAwesome5Solid.search,
  ),

  // Integrated Components and Systems
  subItemCiIntegratedComponentsSystemsAllAreas(
    key: 'subItemCiIntegratedComponentsSystemsAllAreas',
    title: 'All Areas',
    description:
        'Covers all aspects of integrating components and systems for optimized performance.',
    parentKey: 'groupCiIntegratedComponentsSystems',
    icon: FontAwesome5Solid.cogs,
  ),

  // Internet of Things
  subItemCiIoTAllAreas(
    key: 'subItemCiIoTAllAreas',
    title: 'All Areas',
    description:
        'Covers IoT applications, including smart devices and connected infrastructure.',
    parentKey: 'groupCiIoT',
    icon: FontAwesome5Solid.microchip,
  ),

  // Logistics
  subItemCiLogisticsAllAreas(
    key: 'subItemCiLogisticsAllAreas',
    title: 'All Areas',
    description:
        'Focuses on logistics systems for supply chain optimization and operational efficiency.',
    parentKey: 'groupCiLogistics',
    icon: FontAwesome5Solid.truck,
  ),

  // Nuclear Technology
  subItemCiNuclearTechnologyAllAreas(
    key: 'subItemCiNuclearTechnologyAllAreas',
    title: 'All Areas',
    description:
        'Includes all nuclear technologies for energy production and infrastructure resilience.',
    parentKey: 'groupCiNuclearTechnology',
    icon: FontAwesome5Solid.atom,
  ),

  // Positioning and Navigation
  subItemCiPositioningNavigationAllAreas(
    key: 'subItemCiPositioningNavigationAllAreas',
    title: 'All Areas',
    description:
        'Covers positioning and navigation technologies for precise tracking and location services.',
    parentKey: 'groupCiPositioningNavigation',
    icon: FontAwesome5Solid.map_marker_alt,
  ),

  // Quantum
  subItemCiQuantumAllAreas(
    key: 'subItemCiQuantumAllAreas',
    title: 'All Areas',
    description:
        'Focuses on quantum technologies for computation, cryptography, and navigation.',
    parentKey: 'groupCiQuantum',
    icon: FontAwesome5Solid.atom,
  ),

  // Remote Sensing
  subItemCiRemoteSensingAllAreas(
    key: 'subItemCiRemoteSensingAllAreas',
    title: 'All Areas',
    description:
        'Covers all remote sensing technologies for monitoring and surveillance.',
    parentKey: 'groupCiRemoteSensing',
    icon: FontAwesome5Solid.camera,
  ),

  // Sensors
  subItemCiSensorsAllAreas(
    key: 'subItemCiSensorsAllAreas',
    title: 'All Areas',
    description:
        'Includes all sensor types, focusing on reliability and scalability for critical infrastructure.',
    parentKey: 'groupCiSensors',
    icon: FontAwesome5Solid.eye,
  ),

  // Transportation
  subItemCiTransportationAllAreas(
    key: 'subItemCiTransportationAllAreas',
    title: 'All Areas',
    description:
        'Focuses on transportation technologies to optimize mobility and reduce environmental impact.',
    parentKey: 'groupCiTransportation',
    icon: FontAwesome5Solid.bus,
  ),

  // Water and Wastewater Treatment
  subItemCiWaterTreatmentAllAreas(
    key: 'subItemCiWaterTreatmentAllAreas',
    title: 'All Areas',
    description:
        'Covers all water and wastewater treatment technologies for sustainable infrastructure.',
    parentKey: 'groupCiWaterTreatment',
    icon: FontAwesome5Solid.water,
  ),

  // Space
  subItemCiSpaceAllAreas(
    key: 'subItemCiSpaceAllAreas',
    title: 'All Areas',
    description:
        'Includes space-based systems for critical infrastructure monitoring and management.',
    parentKey: 'groupCiSpace',
    icon: FontAwesome5Solid.space_shuttle,
  ),

  // Resilience
  subItemCiResilienceAllAreas(
    key: 'subItemCiResilienceAllAreas',
    title: 'All Areas',
    description:
        'Focuses on creating resilient infrastructure to withstand and recover from disruptions.',
    parentKey: 'groupCiResilience',
    icon: FontAwesome5Solid.shield_alt,
  ),

  // Sustainability
  subItemCiSustainabilityAllAreas(
    key: 'subItemCiSustainabilityAllAreas',
    title: 'All Areas',
    description:
        'Explores sustainable practices for building and maintaining critical infrastructure.',
    parentKey: 'groupCiSustainability',
    icon: FontAwesome5Solid.recycle,
  ),

  // Other
  subItemCiOtherAllAreas(
    key: 'subItemCiOtherAllAreas',
    title: 'All Areas',
    description:
        'Covers emerging and miscellaneous topics in critical infrastructure.',
    parentKey: 'groupCiOther',
    icon: FontAwesome5Solid.question,
  ),

  // Advanced Computing and Methods
  subItemHhpAdvComputingAllAreas(
    key: 'subItemHhpAdvComputingAllAreas',
    title: 'All Areas',
    description:
        'Covers all areas of advanced computing and methods, with a focus on healthcare applications.',
    parentKey: 'groupHhpAdvComputing',
    icon: FontAwesome5Solid.desktop,
  ),
  subItemHhpPredictiveHealthcareModelling(
    key: 'subItemHhpPredictiveHealthcareModelling',
    title: 'Predictive Healthcare Modelling',
    description:
        'Focuses on advanced computational models to predict healthcare outcomes and optimize treatments.',
    parentKey: 'groupHhpAdvComputing',
    icon: FontAwesome5Solid.chart_line,
  ),

  // Advanced Components, Materials, and Manufacturing
  subItemHhpAdvComponentsAllAreas(
    key: 'subItemHhpAdvComponentsAllAreas',
    title: 'All Areas',
    description:
        'Explores innovative materials and manufacturing methods for medical applications.',
    parentKey: 'groupHhpAdvComponentsMaterialsManufacturing',
    icon: FontAwesome5Solid.industry,
  ),

  // Artificial Intelligence and Machine Learning
  subItemHhpAIAllAreas(
    key: 'subItemHhpAIAllAreas',
    title: 'All Areas',
    description:
        'Covers all areas of AI and ML in healthcare, including diagnostics, treatment planning, and drug discovery.',
    parentKey: 'groupHhpAI',
    icon: FontAwesome5Solid.robot,
  ),
  subItemHhpBiomedicalAI(
    key: 'subItemHhpBiomedicalAI',
    title: 'Multi-Modal Biomedical AI',
    description:
        'Focuses on AI systems integrating diverse biomedical data to improve healthcare decision-making.',
    parentKey: 'groupHhpAI',
    icon: FontAwesome5Solid.brain,
  ),

  // Autonomous Systems and Robotics
  subItemHhpAutonomousSystemsAllAreas(
    key: 'subItemHhpAutonomousSystemsAllAreas',
    title: 'All Areas',
    description:
        'Includes autonomous systems and robotics for healthcare applications such as surgery and diagnostics.',
    parentKey: 'groupHhpAutonomousSystemsRobotics',
    icon: FontAwesome5Solid.robot,
  ),
  subItemHhpDrones(
    key: 'subItemHhpDrones',
    title: 'Drones',
    description:
        'Covers drones for delivering medical supplies and performing remote monitoring in healthcare.',
    parentKey: 'groupHhpAutonomousSystemsRobotics',
    icon: FontAwesome5Solid.helicopter,
  ),
  subItemHhpSurgicalRobotics(
    key: 'subItemHhpSurgicalRobotics',
    title: 'Surgery',
    description:
        'Focuses on robotic systems for precision surgery and minimally invasive procedures.',
    parentKey: 'groupHhpAutonomousSystemsRobotics',
    icon: FontAwesome5Solid.cut,
  ),

  // Bio-Manufacturing and Biomaterials
  subItemHhpBioManufacturingAllAreas(
    key: 'subItemHhpBioManufacturingAllAreas',
    title: 'All Areas',
    description:
        'Explores bio-manufacturing and biomaterials for regenerative medicine and advanced medical devices.',
    parentKey: 'groupHhpBioManufacturingMaterials',
    icon: FontAwesome5Solid.dna,
  ),

  // Biosensors and Physiological Detectors and Sensors
  subItemHhpBiosensorsAllAreas(
    key: 'subItemHhpBiosensorsAllAreas',
    title: 'All Areas',
    description:
        'Covers biosensors and physiological detectors for health monitoring and diagnostics.',
    parentKey: 'groupHhpBiosensors',
    icon: FontAwesome5Solid.heartbeat,
  ),

  // Chemical, Biological, Radiological, and Nuclear (CBRN)
  subItemHhpCBRNAllAreas(
    key: 'subItemHhpCBRNAllAreas',
    title: 'All Areas',
    description:
        'Includes detection, characterization, and defense against CBRN threats in healthcare settings.',
    parentKey: 'groupHhpCBRN',
    icon: FontAwesome5Solid.biohazard,
  ),

  // Emergency Medicine
  subItemHhpEmergencyMedicineAllAreas(
    key: 'subItemHhpEmergencyMedicineAllAreas',
    title: 'All Areas',
    description:
        'Focuses on emergency medicine techniques, tools, and technologies for rapid response care.',
    parentKey: 'groupHhpEmergencyMedicine',
    icon: FontAwesome5Solid.ambulance,
  ),

  // Exoskeletons
  subItemHhpExoskeletonsAllAreas(
    key: 'subItemHhpExoskeletonsAllAreas',
    title: 'All Areas',
    description:
        'Explores exoskeleton technologies for rehabilitation and enhancing physical capabilities.',
    parentKey: 'groupHhpExoskeletons',
    icon: FontAwesome5Solid.walking,
  ),

  // Human Machine Interfaces
  subItemHhpHMIAllAreas(
    key: 'subItemHhpHMIAllAreas',
    title: 'All Areas',
    description:
        'Covers all human-machine interfaces, with applications in telemedicine, VR, and human-machine teaming.',
    parentKey: 'groupHhpHMI',
    icon: FontAwesome5Solid.vr_cardboard,
  ),
  subItemHhpHumanMachineTeaming(
    key: 'subItemHhpHumanMachineTeaming',
    title: 'Human-Machine Teaming',
    description:
        'Focuses on collaboration between humans and machines for enhanced healthcare outcomes.',
    parentKey: 'groupHhpHMI',
    icon: FontAwesome5Solid.handshake,
  ),
  subItemHhpTelemedicine(
    key: 'subItemHhpTelemedicine',
    title: 'Tele-Medicine',
    description:
        'Explores telemedicine systems to enable remote healthcare delivery and monitoring.',
    parentKey: 'groupHhpHMI',
    icon: FontAwesome5Solid.video,
  ),
  subItemHhpVirtualAugmentedReality(
    key: 'subItemHhpVirtualAugmentedReality',
    title: 'Virtual or Augmented Reality',
    description:
        'Includes VR/AR systems for training, diagnostics, and immersive patient care.',
    parentKey: 'groupHhpHMI',
    icon: FontAwesome5Solid.eye,
  ),

  // Human Sustainability
  subItemHhpHumanSustainabilityAllAreas(
    key: 'subItemHhpHumanSustainabilityAllAreas',
    title: 'All Areas',
    description:
        'Focuses on sustaining human health and performance in diverse and challenging environments.',
    parentKey: 'groupHhpHumanSustainability',
    icon: FontAwesome5Solid.recycle,
  ),

  // Medical Devices
  subItemHhpMedicalDevicesAllAreas(
    key: 'subItemHhpMedicalDevicesAllAreas',
    title: 'All Areas',
    description:
        'Covers medical devices for diagnostics, treatment, and rehabilitation.',
    parentKey: 'groupHhpMedicalDevices',
    icon: FontAwesome5Solid.stethoscope,
  ),
  subItemHhpProsthetics(
    key: 'subItemHhpProsthetics',
    title: 'Prosthetics',
    description:
        'Focuses on advanced prosthetics to improve mobility and quality of life.',
    parentKey: 'groupHhpMedicalDevices',
    icon: FontAwesome5Solid.hand_pointer,
  ),

  // Other Categories
  subItemHhpSpaceAllAreas(
    key: 'subItemHhpSpaceAllAreas',
    title: 'All Areas',
    description:
        'Explores healthcare challenges and innovations in space environments.',
    parentKey: 'groupHhpSpace',
    icon: FontAwesome5Solid.space_shuttle,
  ),
  subItemHhpResilienceAllAreas(
    key: 'subItemHhpResilienceAllAreas',
    title: 'All Areas',
    description:
        'Focuses on building resilient healthcare systems for crisis situations.',
    parentKey: 'groupHhpResilience',
    icon: FontAwesome5Solid.shield_alt,
  ),
  subItemHhpSustainabilityAllAreas(
    key: 'subItemHhpSustainabilityAllAreas',
    title: 'All Areas',
    description:
        'Covers sustainable practices for healthcare systems and medical technologies.',
    parentKey: 'groupHhpSustainability',
    icon: FontAwesome5Solid.leaf,
  ),
  subItemHhpOtherAllAreas(
    key: 'subItemHhpOtherAllAreas',
    title: 'All Areas',
    description:
        'Includes emerging and miscellaneous topics in health and human performance.',
    parentKey: 'groupHhpOther',
    icon: FontAwesome5Solid.question,
  ),
  ;

  const AppExperienceTags({
    required this.key,
    required this.title,
    required this.description,
    required this.parentKey,
    required this.icon,
  });

  final String key;
  final String title;
  final String description;
  final String parentKey;
  final IconData icon;
}
