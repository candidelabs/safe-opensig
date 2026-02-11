import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:safe_opensig/core/storage/network_config_box.dart';
import 'package:safe_opensig/core/theme/theme_config.dart';
import 'package:safe_opensig/shared/constants/network_constants.dart';
import 'package:safe_opensig/shared/models/custom_network_config.dart';
import 'package:safe_opensig/shared/models/network_model.dart';
import 'package:safe_opensig/shared/utils/extensions/string_extensions.dart';
import 'package:safe_opensig/shared/utils/utilities.dart';
import 'package:safe_opensig/shared/widgets/network_logo.dart';

class NetworkConfigOverrideScreen extends StatefulWidget {
  final int chainId;

  const NetworkConfigOverrideScreen({super.key, required this.chainId});

  @override
  State<NetworkConfigOverrideScreen> createState() =>
      _NetworkConfigOverrideScreenState();
}

class _NetworkConfigOverrideScreenState
    extends State<NetworkConfigOverrideScreen> {
  final _formKey = GlobalKey<FormState>();
  late Network _network;
  bool _isChecking = false;
  bool _showDuplicateWarnTrailingIcon = false;

  late TextEditingController _primaryUrlController;
  late TextEditingController _explorerUrlController;
  final List<TextEditingController> _secondaryUrlControllers = [];
  late bool _hasCustomConfig;

  // Chain ID verification state: url -> null (not checked), true (ok), false (failed)
  final Map<String, bool?> _chainIdResults = {};
  bool _chainIdChecked = false;

  // eth_getProof support state for secondary nodes: url -> true (ok), false (failed)
  final Map<String, bool?> _ethGetProofResults = {};
  bool _ethGetProofChecked = false;

  @override
  void initState() {
    super.initState();
    _network = getDefaultNetwork(widget.chainId);
    _hasCustomConfig = NetworkConfigBox.hasCustomConfig(widget.chainId);

    final existing = NetworkConfigBox.getConfig(widget.chainId);

    _primaryUrlController = TextEditingController(
      text: existing?.primaryNodeUrl ?? '',
    );
    _explorerUrlController = TextEditingController(
      text: existing?.explorerUrl ?? '',
    );

    if (existing != null && existing.secondaryNodeUrls.isNotEmpty) {
      for (final url in existing.secondaryNodeUrls) {
        _secondaryUrlControllers.add(TextEditingController(text: url));
      }
    } else {
      // Always start with at least one secondary node field
      _secondaryUrlControllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    _primaryUrlController.dispose();
    _explorerUrlController.dispose();
    for (final c in _secondaryUrlControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addSecondaryUrl() {
    setState(() {
      _secondaryUrlControllers.add(TextEditingController());
    });
  }

  void _removeSecondaryUrl(int index) {
    setState(() {
      _secondaryUrlControllers[index].dispose();
      _secondaryUrlControllers.removeAt(index);
    });
  }

  Future<bool> _showDebugTraceWarningDialog() async {
    final theme = Theme.of(context);
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            icon: const Icon(
              Icons.warning_amber_rounded,
              color: Colors.amber,
              size: 40,
            ),
            title: const Text('Simulation Not Supported'),
            content: Text(
              'This RPC node does not appear to support debug_traceCall, '
              'which is required for transaction simulation.\n\n'
              'You can still save this configuration, but simulation '
              'will not work with this node.',
              style: theme.textTheme.bodyMedium,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Save Anyway'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<bool> _showDuplicateNodesWarningDialog(int duplicatesRemoved) async {
    final theme = Theme.of(context);
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            icon: const Icon(
              Icons.warning_amber_rounded,
              color: Colors.amber,
              size: 40,
            ),
            title: const Text('Duplicate Nodes Detected'),
            content: Text(
              '$duplicatesRemoved duplicate secondary node URL(s) will be '
              'removed before saving. Duplicates of the primary node or of '
              'other secondary nodes provide no additional verification.',
              style: theme.textTheme.bodyMedium,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Go Back'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Save Anyway'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _verifyAllChainIds() async {
    final primaryUrl = _primaryUrlController.text.trim();
    final allUrls = <String>[
      if (primaryUrl.isNotEmpty) primaryUrl,
      ..._secondaryUrlControllers
          .map((c) => c.text.trim())
          .where((u) => u.isNotEmpty),
    ];

    setState(() {
      _isChecking = true;
      _chainIdResults.clear();
      _chainIdChecked = false;
    });

    final futures = <Future<void>>[];
    for (final url in allUrls) {
      futures.add(
        Utilities.verifyChainId(url, widget.chainId).then((ok) {
          if (mounted) {
            setState(() => _chainIdResults[url] = ok);
          }
        }),
      );
    }
    await Future.wait(futures);

    if (mounted) {
      setState(() {
        _isChecking = false;
        _chainIdChecked = true;
      });
    }
  }

  bool get _primaryChainIdFailed {
    final url = _primaryUrlController.text.trim();
    return _chainIdChecked && _chainIdResults[url] == false;
  }

  List<String> get _failedSecondaryUrls {
    if (!_chainIdChecked) return [];
    return _secondaryUrlControllers
        .map((c) => c.text.trim())
        .where((url) => url.isNotEmpty && _chainIdResults[url] == false)
        .toList();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // Step 1: Verify chain IDs for all RPC URLs
    await _verifyAllChainIds();
    if (!mounted) return;

    // Block save if primary node failed chain ID check
    if (_primaryChainIdFailed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Primary node failed chain ID verification. '
            'Please replace it before saving.',
          ),
        ),
      );
      return;
    }

    final primaryUrl = _primaryUrlController.text.trim();

    // Step 2: Check debug_traceCall support on primary
    setState(() => _isChecking = true);
    try {
      final supported = await Utilities.checkDebugTraceCallSupport(primaryUrl);
      if (!supported && mounted) {
        setState(() => _isChecking = false);
        final proceed = await _showDebugTraceWarningDialog();
        if (!proceed) return;
      }
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }

    // Collect and deduplicate secondary URLs, excluding chain ID failures
    final failedUrls = _failedSecondaryUrls.toSet();
    final allSecondary = _secondaryUrlControllers
        .map((c) => c.text.trim())
        .where((url) => url.isNotEmpty && !failedUrls.contains(url))
        .toList();

    final seen = <String>{primaryUrl};
    final deduplicatedSecondary = <String>[
      for (final url in allSecondary)
        if (seen.add(url)) url,
    ];

    final duplicatesRemoved = allSecondary.length - deduplicatedSecondary.length;
    if (duplicatesRemoved > 0 && mounted) {
      final proceed = await _showDuplicateNodesWarningDialog(duplicatesRemoved);
      if (!proceed) return;
    }

    // Step 3: Verify eth_getProof support on all secondary nodes
    setState(() {
      _isChecking = true;
      _ethGetProofResults.clear();
      _ethGetProofChecked = false;
    });

    final proofFutures = <Future<void>>[];
    for (final url in deduplicatedSecondary) {
      proofFutures.add(
        Utilities.checkEthGetProofSupport(url).then((ok) {
          if (mounted) {
            setState(() => _ethGetProofResults[url] = ok);
          }
        }),
      );
    }
    await Future.wait(proofFutures);

    if (mounted) {
      setState(() {
        _isChecking = false;
        _ethGetProofChecked = true;
      });
    }
    if (!mounted) return;

    final proofFailedUrls = deduplicatedSecondary
        .where((url) => _ethGetProofResults[url] == false)
        .toList();

    if (proofFailedUrls.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${proofFailedUrls.length} secondary node(s) do not support '
            'eth_getProof, which is required for state verification. '
            'Replace the failing node(s) before saving.',
          ),
        ),
      );
      return;
    }

    // Require at least 1 unique secondary node after deduplication
    if (deduplicatedSecondary.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'At least 1 secondary node is required for state verification. '
              'Add a node that differs from the primary.',
            ),
          ),
        );
      }
      setState(() {
        _showDuplicateWarnTrailingIcon = true;
      });
      return;
    }

    final config = CustomNetworkConfig(
      chainId: widget.chainId,
      primaryNodeUrl: primaryUrl,
      secondaryNodeUrls: deduplicatedSecondary,
      explorerUrl: _explorerUrlController.text.trim().isEmpty
          ? null
          : _explorerUrlController.text.trim(),
    );

    await NetworkConfigBox.setConfig(config);
    if (mounted) {
      final discardedCount = failedUrls.length;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            discardedCount > 0
                ? 'Configuration saved ($discardedCount node(s) discarded due to chain ID mismatch)'
                : 'Configuration saved',
          ),
        ),
      );
      context.pop();
    }
  }

  Future<void> _revertToRecommended() async {
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            icon: const Icon(
              Icons.restore,
              color: Colors.blue,
              size: 40,
            ),
            title: const Text('Revert to Recommended?'),
            content: Text(
              'This will remove your custom configuration for '
              '${_network.name} and restore the recommended defaults.',
              style: theme.textTheme.bodyMedium,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Revert'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed || !mounted) return;

    await NetworkConfigBox.removeConfig(widget.chainId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_network.name} reverted to recommended configuration',
          ),
        ),
      );
      context.pop();
    }
  }

  static const _inputBorderRadius = 12.0;

  InputDecoration _styledInputDecoration({
    required String hintText,
    required IconData prefixIcon,
    String? helperText,
  }) {
    return InputDecoration(
      hintText: hintText,
      helperText: helperText,
      prefixIcon: Icon(prefixIcon, size: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_inputBorderRadius),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_inputBorderRadius),
        borderSide: BorderSide(color: Theme.of(context).dividerColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_inputBorderRadius),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_inputBorderRadius),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_inputBorderRadius),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.error,
          width: 2,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Override Configuration'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(ThemeConfig.spacingMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildNetworkHeader(theme),
                    const SizedBox(height: ThemeConfig.spacingLarge),
                    _buildWarningCard(theme),
                    const SizedBox(height: ThemeConfig.spacingLarge),
                    _buildSectionLabel(
                      theme,
                      'Primary node',
                      infoText:
                          'The primary node is used to fetch the state of the '
                          'blockchain before simulation. It must support '
                          'debug_traceCall for transaction simulation to work.',
                    ),
                    const SizedBox(height: ThemeConfig.spacingSmall),
                    _buildPrimaryNodeField(theme),
                    const SizedBox(height: ThemeConfig.spacingLarge),
                    _buildSectionLabel(
                      theme,
                      'Secondary nodes (min. 1 required)',
                      infoText:
                          'Secondary nodes are used to independently verify, '
                          'through Merkle tree proofs, that the state fetched '
                          'from the primary node is correct. The more secondary '
                          'nodes you add, the stronger the verification.',
                    ),
                    const SizedBox(height: ThemeConfig.spacingSmall),
                    _buildSecondaryNodesSection(theme),
                    const SizedBox(height: ThemeConfig.spacingLarge),
                    _buildSectionLabel(theme, 'Block explorer'),
                    const SizedBox(height: ThemeConfig.spacingSmall),
                    _buildExplorerField(theme),
                  ],
                ),
              ),
            ),
          ),

          // Bottom actions
          _buildBottomActions(theme),
        ],
      ),
    );
  }

  Widget _buildNetworkHeader(ThemeData theme) {
    return Row(
      children: [
        NetworkLogo(network: _network, size: 32),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _network.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Chain ID: ${_network.chainId}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color
                      ?.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWarningCard(ThemeData theme) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Colors.amber.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.amber.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 20, color: Colors.amber),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Advanced Configuration',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Changing the default node configuration can break '
                    'transaction simulation and state verification. '
                    'Only proceed if you know what you are doing.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(ThemeData theme, String label, {String? infoText}) {
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      letterSpacing: 0.5,
      color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
    );
    if (infoText == null) {
      return Text(label, style: labelStyle);
    }
    return Row(
      children: [
        Text(label, style: labelStyle),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: () => _showInfoDialog(label, infoText),
          child: Icon(
            Icons.info_outline,
            size: 14,
            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.4),
          ),
        ),
      ],
    );
  }

  void _showInfoDialog(String title, String body) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryNodeField(ThemeData theme) {
    final url = _primaryUrlController.text.trim();
    final chainResult = _chainIdChecked ? _chainIdResults[url] : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _primaryUrlController,
          onChanged: (_) => _resetChainIdCheck(),
          decoration: _styledInputDecoration(
            hintText: 'https://your-node-url.com',
            prefixIcon: Icons.circle,
          ).copyWith(
            prefixIcon: Icon(
              Icons.circle,
              size: 10,
              color: theme.colorScheme.primary,
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 0,
            ),
            suffixIcon: _buildChainIdStatusIcon(chainResult, false),
          ),
          keyboardType: TextInputType.url,
          validator: (value) => value?.validateHttpsUrl(),
        ),
        if (chainResult == false)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Row(
              children: [
                Icon(Icons.error_outline, size: 14, color: theme.colorScheme.error),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Chain ID mismatch or unreachable. Replace this URL.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _resetChainIdCheck() {
    if (_chainIdChecked) {
      setState(() {
        _chainIdChecked = false;
        _chainIdResults.clear();
      });
    }
    if (_ethGetProofChecked) {
      setState(() {
        _ethGetProofChecked = false;
        _ethGetProofResults.clear();
      });
    }
    if (_showDuplicateWarnTrailingIcon){
      setState(() {
        _showDuplicateWarnTrailingIcon = false;
      });
    }
  }

  Widget? _buildChainIdStatusIcon(bool? result, bool isSecondary, {String? url}) {
    if (isSecondary && _showDuplicateWarnTrailingIcon){
      return const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20);
    }
    if (isSecondary && url != null && _ethGetProofChecked && _ethGetProofResults[url] == false) {
      return const Icon(Icons.cancel, color: Colors.red, size: 20);
    }
    if (result == null) return null;
    if (result) {
      return const Icon(Icons.check_circle, color: Colors.green, size: 20);
    }
    return const Icon(Icons.cancel, color: Colors.red, size: 20);
  }

  Widget _buildSecondaryNodesSection(ThemeData theme) {
    return Column(
      children: [
        ..._secondaryUrlControllers.asMap().entries.map((entry) {
          final index = entry.key;
          final controller = entry.value;
          final url = controller.text.trim();
          final chainResult = _chainIdChecked ? _chainIdResults[url] : null;

          return Padding(
            padding: EdgeInsets.only(
              bottom: index < _secondaryUrlControllers.length - 1
                  ? ThemeConfig.spacingSmall
                  : 0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: controller,
                        onChanged: (_) => _resetChainIdCheck(),
                        decoration: _styledInputDecoration(
                          hintText: 'https://secondary-node.com',
                          prefixIcon: Icons.circle,
                        ).copyWith(
                          prefixIcon: Icon(
                            Icons.circle,
                            size: 10,
                            color: Colors.amber.shade700,
                          ),
                          prefixIconConstraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 0,
                          ),
                          suffixIcon: _buildChainIdStatusIcon(chainResult, true, url: url),
                        ),
                        keyboardType: TextInputType.url,
                        validator: (value) =>
                            value?.validateHttpsUrl(required: true),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: _secondaryUrlControllers.length > 1
                            ? theme.colorScheme.error
                            : theme.disabledColor,
                        size: 20,
                      ),
                      onPressed: _secondaryUrlControllers.length > 1
                          ? () => _removeSecondaryUrl(index)
                          : null,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                if (chainResult == false)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 4, bottom: 4),
                    child: Text(
                      'Will be discarded — chain ID mismatch or unreachable',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.amber.shade700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                if (_ethGetProofChecked && _ethGetProofResults[url] == false)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 4, bottom: 4),
                    child: Text(
                      'Does not support eth_getProof — required for state verification',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
        if (_secondaryUrlControllers.isNotEmpty)
          const SizedBox(height: ThemeConfig.spacingSmall),
        // Add button
        OutlinedButton.icon(
          onPressed: _addSecondaryUrl,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add Secondary Node'),
        ),
      ],
    );
  }

  Widget _buildExplorerField(ThemeData theme) {
    return TextFormField(
      controller: _explorerUrlController,
      decoration: _styledInputDecoration(
        hintText: 'e.g., https://etherscan.io',
        prefixIcon: Icons.explore_outlined,
      ),
      keyboardType: TextInputType.url,
      validator: (value) => value?.validateHttpsUrl(required: false)
    );
  }

  Widget _buildBottomActions(ThemeData theme) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          ThemeConfig.spacingMedium,
          ThemeConfig.spacingSmall,
          ThemeConfig.spacingMedium,
          ThemeConfig.spacingMedium,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isChecking ? null : _save,
                child: _isChecking
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Save Network Configuration'),
              ),
            ),
            if (_hasCustomConfig) ...[
              const SizedBox(height: 4),
              TextButton.icon(
                onPressed: _isChecking ? null : _revertToRecommended,
                icon: const Icon(Icons.restore, size: 16),
                label: const Text('Revert to Recommended'),
              ),
            ],
            const SizedBox(height: 4),
            TextButton(
              onPressed: () => context.pop(),
              child: Text(
                'Cancel',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
