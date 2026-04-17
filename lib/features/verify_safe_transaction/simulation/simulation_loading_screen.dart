import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:safe_opensig/shared/models/safe_account_model.dart';
import 'package:safe_opensig/shared/models/safe_transaction_model.dart';
import 'package:safe_opensig/shared/models/simulation/simulation_phase.dart';
import 'package:safe_opensig/core/storage/network_config_box.dart';
import 'package:safe_opensig/shared/widgets/trust_minimized_note.dart';

// Toggle this to add a delay between phases for better visibility
const bool _enablePhaseDelay = true;

class SimulationLoadingScreen extends StatefulWidget {
  final SafeAccount safeAccount;
  final SafeTransaction transaction;

  const SimulationLoadingScreen({
    super.key,
    required this.safeAccount,
    required this.transaction,
  });

  @override
  State<SimulationLoadingScreen> createState() => _SimulationLoadingScreenState();
}

class _SimulationLoadingScreenState extends State<SimulationLoadingScreen> {
  SimulationPhase _currentPhase = SimulationPhase.fetchingPrestate;
  String? _errorMessage;
  final List<SimulationPhase> _phaseQueue = [];
  bool _isProcessingQueue = false;
  bool _isCancelled = false;

  @override
  void initState() {
    super.initState();
    _startSimulation();
  }

  @override
  void dispose() {
    _isCancelled = true;
    super.dispose();
  }

  void _queuePhaseChange(SimulationPhase phase) {
    if (_isCancelled) return;
    _phaseQueue.add(phase);
    if (!_isProcessingQueue) {
      _processPhaseQueue();
    }
  }

  Future<void> _processPhaseQueue() async {
    _isProcessingQueue = true;

    while (_phaseQueue.isNotEmpty && mounted && !_isCancelled) {
      final phase = _phaseQueue.removeAt(0);

      setState(() {
        _currentPhase = phase;
      });

      // Optional delay between phases for better visibility
      if (_enablePhaseDelay && !_isCancelled) {
        await Future.delayed(const Duration(milliseconds: 750));
      }
    }

    _isProcessingQueue = false;
  }

  void _handleBack() {
    setState(() {
      _isCancelled = true;
      _phaseQueue.clear();
    });
    if (mounted) {
      GoRouter.of(context).go('/verify-transaction', extra: widget.safeAccount);
    }
  }

  void _handleSkipSimulation() {
    setState(() {
      _isCancelled = true;
      _phaseQueue.clear();
    });
    if (mounted) {
      GoRouter.of(context).pushReplacement(
        '/verify-transaction/hashes',
        extra: (widget.safeAccount, widget.transaction),
      );
    }
  }

  Future<void> _startSimulation() async {
    try {
      final (success, simulationResult, errorMessage) = await widget.transaction.simulate(
        widget.safeAccount,
        onPhaseChange: (phase) {
          _queuePhaseChange(phase);
        },
      );
      if (_isCancelled) return;
      if (!success || simulationResult == null) {
        if (mounted && !_isCancelled) {
          setState(() {
            _errorMessage = errorMessage.isNotEmpty
                ? errorMessage
                : 'Simulation failed';
          });
        }
        return;
      }
      _queuePhaseChange(SimulationPhase.wrappingUp);
      await simulationResult.loadTokenMetadatas();
      if (_isCancelled) return;
      _queuePhaseChange(SimulationPhase.completed);
      while ((_phaseQueue.isNotEmpty || _isProcessingQueue) && !_isCancelled) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      if (_isCancelled) return;
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted && !_isCancelled) {
        GoRouter.of(context).pushReplacement(
          "/verify-transaction/simulation-results",
          extra: (widget.safeAccount, widget.transaction, simulationResult),
        );
      }
    } catch (e) {
      if (mounted && !_isCancelled) {
        setState(() {
          _errorMessage = 'An unexpected error occurred: ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Simulation Error'),
          backgroundColor: Colors.transparent,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 24),
                Text(
                  'Simulation Failed',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    GoRouter.of(context).pushReplacement(
                      "/verify-transaction/hashes",
                      extra: (widget.safeAccount, widget.transaction),
                    );
                  },
                  child: const Text('Continue to Hashes'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    GoRouter.of(context).pop();
                  },
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Simulating Transaction'),
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 4.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                PageTransitionSwitcher(
                  duration: const Duration(milliseconds: 600),
                  reverse: false,
                  transitionBuilder: (
                    child,
                    animation,
                    secondaryAnimation,
                  ) {
                    return SharedAxisTransition(
                      animation: animation,
                      secondaryAnimation: secondaryAnimation,
                      transitionType: SharedAxisTransitionType.horizontal,
                      fillColor: Colors.transparent,
                      child: child,
                    );
                  },
                  child: Column(
                    key: ValueKey<SimulationPhase>(_currentPhase),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _PhaseIcon(phase: _currentPhase),
                      const SizedBox(height: 32),
                      Text(
                        _currentPhase.displayName,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _currentPhase.description,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.grey[400],
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.easeInOut,
                      tween: Tween<double>(
                        begin: 0,
                        end: _currentPhase.progress,
                      ),
                      builder: (context, value, _) => Column(
                        children: [
                          LinearProgressIndicator(
                            value: value,
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${(value * 100).toInt()}%',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                _PhaseChecklist(
                  currentPhase: _currentPhase,
                  stateVerificationSkipped:
                      NetworkConfigBox.hasCustomConfig(widget.safeAccount.chainId) &&
                      (NetworkConfigBox.getConfig(widget.safeAccount.chainId)?.secondaryNodeUrls.isEmpty ?? true),
                ),
                const SizedBox(height: 24),
                if (!NetworkConfigBox.hasCustomConfig(widget.safeAccount.chainId) ||
                    (NetworkConfigBox.getConfig(widget.safeAccount.chainId)?.secondaryNodeUrls.isNotEmpty ?? false))
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28.0),
                    child: TrustMinimizedNote(),
                  ),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _handleBack,
                        icon: const Icon(Icons.arrow_back, size: 18),
                        label: const Text('Back'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _handleSkipSimulation,
                        icon: const Icon(Icons.skip_next, size: 18),
                        label: const Text('Skip Simulation'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PhaseIcon extends StatelessWidget {
  final SimulationPhase phase;

  const _PhaseIcon({required this.phase});

  @override
  Widget build(BuildContext context) {
    IconData iconData;
    Color iconColor;

    switch (phase) {
      case SimulationPhase.fetchingPrestate:
        iconData = Icons.cloud_download;
        iconColor = Colors.blue;
        break;
      case SimulationPhase.verifyingState:
        iconData = Icons.verified_user;
        iconColor = Colors.purple;
        break;
      case SimulationPhase.simulating:
        iconData = Icons.play_circle_outline;
        iconColor = Colors.orange;
        break;
      case SimulationPhase.wrappingUp:
        iconData = Icons.auto_awesome;
        iconColor = Colors.teal;
        break;
      case SimulationPhase.completed:
        iconData = Icons.check_circle;
        iconColor = Colors.green;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(
          color: iconColor.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Icon(
        iconData,
        size: 64,
        color: iconColor,
      ),
    );
  }
}

class _PhaseChecklist extends StatelessWidget {
  final SimulationPhase currentPhase;
  final bool stateVerificationSkipped;

  const _PhaseChecklist({required this.currentPhase, this.stateVerificationSkipped = false});

  bool _isPhaseCompleted(SimulationPhase phase) {
    return phase.index <= currentPhase.index;
  }

  bool _isCurrentPhase(SimulationPhase phase) {
    return phase == currentPhase;
  }

  @override
  Widget build(BuildContext context) {
    final phases = [
      SimulationPhase.fetchingPrestate,
      SimulationPhase.verifyingState,
      SimulationPhase.simulating,
      SimulationPhase.wrappingUp,
    ];

    return Wrap(
      spacing: 0,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: phases.asMap().entries.map((entry) {
        final index = entry.key;
        final phase = entry.value;
        final isCompleted = _isPhaseCompleted(phase);
        final isCurrent = _isCurrentPhase(phase);
        final isLast = index == phases.length - 1;
        final isWarn = phase == SimulationPhase.verifyingState
            && stateVerificationSkipped
            && isCompleted
            && !isCurrent;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isWarn
                    ? Colors.amber.withValues(alpha: 0.15)
                    : isCurrent
                        ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)
                        : (isCompleted
                            ? Colors.green.withValues(alpha: 0.15)
                            : Colors.grey.withValues(alpha: 0.1)),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isWarn
                      ? Colors.amber.withValues(alpha: 0.4)
                      : isCurrent
                          ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.4)
                          : (isCompleted
                              ? Colors.green.withValues(alpha: 0.4)
                              : Colors.grey.withValues(alpha: 0.3)),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: isCurrent
                        ? CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).colorScheme.primary,
                            ),
                          )
                        : Icon(
                            isWarn
                                ? Icons.warning_amber_rounded
                                : isCompleted ? Icons.check_circle : Icons.circle_outlined,
                            size: 14,
                            color: isWarn
                                ? Colors.amber
                                : isCompleted ? Colors.green : Colors.grey[600],
                          ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _getShortName(phase),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                          color: isWarn
                              ? Colors.amber[300]
                              : isCurrent
                                  ? Theme.of(context).colorScheme.primary
                                  : (isCompleted ? Colors.grey[300] : Colors.grey[600]),
                        ),
                  ),
                ],
              ),
            ),
            // Connector line (except for last item)
            if (!isLast)
              Container(
                width: 16,
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                color: isWarn
                    ? Colors.amber.withValues(alpha: 0.4)
                    : isCompleted ? Colors.green.withValues(alpha: 0.4) : Colors.grey.withValues(alpha: 0.3),
              ),
          ],
        );
      }).toList(),
    );
  }

  String _getShortName(SimulationPhase phase) {
    switch (phase) {
      case SimulationPhase.fetchingPrestate:
        return 'Fetch';
      case SimulationPhase.verifyingState:
        return 'Verify';
      case SimulationPhase.simulating:
        return 'Simulate';
      case SimulationPhase.wrappingUp:
        return 'Finalize';
      case SimulationPhase.completed:
        return 'Done';
    }
  }
}
