enum SimulationPhase {
  fetchingPrestate,
  verifyingState,
  simulating,
  wrappingUp,
  completed,
}

extension SimulationPhaseExtension on SimulationPhase {
  String get displayName {
    switch (this) {
      case SimulationPhase.fetchingPrestate:
        return 'Fetching Prestate';
      case SimulationPhase.verifyingState:
        return 'Verifying State';
      case SimulationPhase.simulating:
        return 'Simulating Transaction';
      case SimulationPhase.wrappingUp:
        return 'Wrapping Up';
      case SimulationPhase.completed:
        return 'Completed';
    }
  }

  String get description {
    switch (this) {
      case SimulationPhase.fetchingPrestate:
        return 'Gathering blockchain state data...';
      case SimulationPhase.verifyingState:
        return 'Verifying state integrity...';
      case SimulationPhase.simulating:
        return 'Running transaction simulation...';
      case SimulationPhase.wrappingUp:
        return 'Processing simulation results...';
      case SimulationPhase.completed:
        return 'Simulation complete!';
    }
  }

  double get progress {
    switch (this) {
      case SimulationPhase.fetchingPrestate:
        return 0.25;
      case SimulationPhase.verifyingState:
        return 0.50;
      case SimulationPhase.simulating:
        return 0.75;
      case SimulationPhase.wrappingUp:
        return 0.90;
      case SimulationPhase.completed:
        return 1.0;
    }
  }
}
