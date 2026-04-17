import 'package:animations/animations.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:cupertino_tabbar/cupertino_tabbar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:safe_opensig/core/router/app_router.dart';
import 'package:safe_opensig/core/theme/theme_config.dart';
import 'package:safe_opensig/features/verify_safe_transaction/widgets/safe_tx_api_guide_sheet.dart';
import 'package:safe_opensig/features/verify_safe_transaction/widgets/safe_tx_api_input.dart';
import 'package:safe_opensig/features/verify_safe_transaction/widgets/safe_tx_calldata_guide_sheet.dart';
import 'package:safe_opensig/features/verify_safe_transaction/widgets/safe_tx_calldata_input.dart';
import 'package:safe_opensig/features/verify_safe_transaction/widgets/safe_tx_json_guide_sheet.dart';
import 'package:safe_opensig/features/verify_safe_transaction/widgets/safe_tx_json_input.dart';
import 'package:safe_opensig/core/storage/network_config_box.dart';
import 'package:safe_opensig/shared/models/safe_account_model.dart';
import 'package:safe_opensig/shared/models/safe_transaction_model.dart';
import 'package:safe_opensig/shared/utils/utilities.dart';
import 'package:version/version.dart';

enum _SimulationDialogResult { goBack, skipToHashes, useDefault }
enum _NoSecondaryNodesResult { goBack, continueAnyway, useDefault }

class SafeTransactionFormScreen extends StatefulWidget {
  final SafeAccount safeAccount;
  const SafeTransactionFormScreen({super.key, required this.safeAccount});

  @override
  State<SafeTransactionFormScreen> createState() =>
      _SafeTransactionFormScreenState();
}

class _SafeTransactionFormScreenState extends State<SafeTransactionFormScreen> {
  final String _jsonInputHint = '''
{
  "to": "0x....",
  "value": "...",
  "data": "0x...",
  "operation": ...,
  "baseGas": "...",
  "gasPrice": "...",
  "gasToken": "0x...",
  "refundReceiver": "0x...",
  "nonce": ...,
  "safeTxGas": "..."
}
''';
  final String _callDataInputHint = '''0x6a7612020000000000000000000000007abc22d179a5f21d563a6e70da8bb9c4bc8b212700000000000000000000000000000000000000000000000000000....''';
  final TextEditingController _jsonController = TextEditingController();
  final FocusNode _jsonFocusNode = FocusNode();
  final TextEditingController _callDataController = TextEditingController();
  final FocusNode _callDataFocusNode = FocusNode();
  late final TextStyle tabSelectedTextStyle;
  late final TextStyle tabDeselectedTextStyle;
  SafeTransaction? safeTransaction;
  int lastIndex = 0;
  int currentIndex = 0;
  int lastManualInputSubIndex = 0;
  int manualInputSubIndex = 0;
  int cupertinoTabBarValueGetter() => currentIndex;
  int manualInputSubTabBarValueGetter() => manualInputSubIndex;

  bool get isLegacyJson => Version.parse(widget.safeAccount.version) < Version.parse("1.0.0");

  @override
  void initState() {
    var navigatorContext = router.configuration.navigatorKey.currentContext!;
    tabSelectedTextStyle = TextStyle(color: Theme.of(navigatorContext).colorScheme.primary, fontSize: 15, fontWeight: FontWeight.bold,);
    tabDeselectedTextStyle = TextStyle(color: Theme.of(navigatorContext).colorScheme.onPrimary, fontSize: 15, fontWeight: FontWeight.w600,);
    super.initState();
  }

  @override
  void dispose() {
    _jsonController.dispose();
    _callDataController.dispose();
    super.dispose();
  }

  void _onSubmit() async {
    var cancelLoad = BotToast.showLoading();
    await safeTransaction!.ensureNonce(widget.safeAccount);
    cancelLoad();
    if (!mounted) return;

    // If we still have no nonce (calldata path + offline), skip simulation
    // and let the user set it manually on the hashes screen.
    if (safeTransaction!.nonce == null) {
      GoRouter.of(context).push(
        "/verify-transaction/hashes",
        extra: (widget.safeAccount, safeTransaction!),
      );
      return;
    }

    if (NetworkConfigBox.hasCustomConfig(widget.safeAccount.chainId)) {
      final config = NetworkConfigBox.getConfig(widget.safeAccount.chainId)!;
      cancelLoad = BotToast.showLoading();
      final supported = await Utilities.checkDebugTraceCallSupport(config.primaryNodeUrl);
      cancelLoad();
      if (!mounted) return;

      if (!supported) {
        final result = await _showSimulationUnavailableDialog();
        if (!mounted) return;
        switch (result) {
          case _SimulationDialogResult.goBack:
            return;
          case _SimulationDialogResult.skipToHashes:
            GoRouter.of(context).push(
              "/verify-transaction/hashes",
              extra: (widget.safeAccount, safeTransaction!),
            );
            return;
          case _SimulationDialogResult.useDefault:
            await NetworkConfigBox.removeConfig(widget.safeAccount.chainId);
            break; // fall through to simulation navigation
        }
      } else if (config.secondaryNodeUrls.isEmpty) {
        final result = await _showNoSecondaryNodesDialog();
        if (!mounted) return;
        switch (result) {
          case _NoSecondaryNodesResult.goBack:
            return;
          case _NoSecondaryNodesResult.continueAnyway:
            break; // fall through to simulation navigation
          case _NoSecondaryNodesResult.useDefault:
            await NetworkConfigBox.removeConfig(widget.safeAccount.chainId);
            break; // fall through to simulation navigation
        }
      }
    }

    GoRouter.of(context).push(
      "/verify-transaction/simulation-loading",
      extra: (widget.safeAccount, safeTransaction!),
    );
  }

  Future<_SimulationDialogResult> _showSimulationUnavailableDialog() async {
    final theme = Theme.of(context);
    return await showDialog<_SimulationDialogResult>(
          context: context,
          builder: (context) => AlertDialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 24),
            contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            titlePadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            iconPadding: const EdgeInsets.only(top: 16),
            actionsPadding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            icon: const Icon(
              Icons.warning_amber_rounded,
              color: Colors.amber,
              size: 36,
            ),
            title: Text(
              'Simulation Not Available',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Your custom RPC node does not support '
                  'debug_traceCall, which is required for '
                  'transaction simulation.',
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(_SimulationDialogResult.useDefault),
                    icon: const Icon(Icons.restart_alt_rounded, size: 18),
                    label: const Text('Use Default Config & Simulate'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      side: BorderSide(color: theme.colorScheme.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(_SimulationDialogResult.skipToHashes),
                    icon: const Icon(Icons.skip_next_rounded, size: 18),
                    label: const Text('Skip to Hashes'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      side: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(_SimulationDialogResult.goBack),
                    child: Text(
                      'Go Back',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ) ??
        _SimulationDialogResult.goBack;
  }

  Future<_NoSecondaryNodesResult> _showNoSecondaryNodesDialog() async {
    final theme = Theme.of(context);
    return await showDialog<_NoSecondaryNodesResult>(
          context: context,
          builder: (context) => AlertDialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 24),
            contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            titlePadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            iconPadding: const EdgeInsets.only(top: 16),
            actionsPadding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            icon: const Icon(
              Icons.info_outline_rounded,
              color: Colors.amber,
              size: 36,
            ),
            title: Text(
              'No State Verification',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Your custom configuration has no secondary '
                  'nodes. Without multiple independent nodes, '
                  'state verification cannot cross-check data, '
                  'reducing the trust assumptions of the '
                  'simulation.',
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(_NoSecondaryNodesResult.useDefault),
                    icon: const Icon(Icons.restart_alt_rounded, size: 18),
                    label: const Text('Use Default Config & Validate'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      side: BorderSide(color: theme.colorScheme.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(_NoSecondaryNodesResult.continueAnyway),
                    icon: const Icon(Icons.play_arrow_rounded, size: 18),
                    label: const Text('Continue Anyway'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      side: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(_NoSecondaryNodesResult.goBack),
                    child: Text(
                      'Go Back',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ) ??
        _NoSecondaryNodesResult.goBack;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Safe Transaction'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return KeyboardActions(
            config: KeyboardActionsConfig(
                keyboardActionsPlatform: KeyboardActionsPlatform.ALL,
                keyboardBarColor: Colors.grey[200],
                actions: currentIndex == 1 ? [
                  KeyboardActionsItem(
                    focusNode: manualInputSubIndex == 0 ? _jsonFocusNode : _callDataFocusNode,
                    toolbarButtons: [
                      (node) {
                        return TextButton.icon(
                          onPressed: () => node.unfocus(),
                          style: ButtonStyle(
                            padding: WidgetStatePropertyAll(const EdgeInsets.symmetric(horizontal: 20, vertical: 8)),
                          ),
                          label: Text("Done", style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
                          icon: Icon(Icons.check, color: Theme.of(context).colorScheme.onPrimary, size: 15,),
                        );
                      },
                    ]
                  ),
                ] : []
            ),
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth, minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      CupertinoTabBar(
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.onPrimary,
                        [
                          Text(
                            "Safe API",
                            style: currentIndex == 0 ? tabSelectedTextStyle : tabDeselectedTextStyle,
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            "Manual Input",
                            style: currentIndex == 1 ? tabSelectedTextStyle : tabDeselectedTextStyle,
                            textAlign: TextAlign.center,
                          ),
                        ],
                        cupertinoTabBarValueGetter,
                        (int index) {
                          if (currentIndex == 1) {
                            if (manualInputSubIndex == 0) {
                              _jsonController.clear();
                              _jsonFocusNode.unfocus();
                            } else if (manualInputSubIndex == 1) {
                              _callDataController.clear();
                              _callDataFocusNode.unfocus();
                            }
                          }
                          lastIndex = currentIndex;
                          setState(() {
                            safeTransaction = null;
                            currentIndex = index;
                          });
                        },
                        borderRadius: BorderRadius.circular(50),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: PageTransitionSwitcher(
                          duration: const Duration(milliseconds: 500),
                          reverse: currentIndex < lastIndex,
                          transitionBuilder: (
                            child,
                            animation,
                            secondaryAnimation,
                          ) {
                            return SharedAxisTransition(
                              animation: animation,
                              secondaryAnimation: secondaryAnimation,
                              transitionType: SharedAxisTransitionType.horizontal,
                              child: child,
                            );
                          },
                          child: currentIndex == 0
                            ? safeTxApiTab()
                            : manualInputTab(),
                        ),
                      ),
                      const Spacer(),
                      // Only show Submit button for Manual Input tab
                      if (currentIndex == 1) ...[
                        ElevatedButton(
                          onPressed: safeTransaction != null ? _onSubmit : null,
                          child: const Text('Submit'),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        }
      ),
    );
  }

  Widget safeTxJsonTab(){
    return Container(
      key: ValueKey<int>(manualInputSubIndex),
      child: Column(
        children: [
          SafeTxJsonInput(
            controller: _jsonController,
            focusNode: _jsonFocusNode,
            hintText: _jsonInputHint,
            legacyJson: isLegacyJson,
            onValidInput: (safeTx){
              setState(() => safeTransaction = safeTx);
            },
          ),
          const SizedBox(height: 10),
          Container(
            alignment: Alignment.centerRight,
            child: OutlinedButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) => const SafeTxJsonGuideSheet(),
                  isScrollControlled: true,
                  showDragHandle: true,
                  useSafeArea: true,
                  shape: RoundedRectangleBorder(
                    borderRadius: ThemeConfig.borderRadiusLarge,
                  )
                );
              },
              style: ButtonStyle(
                  padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
                  visualDensity: VisualDensity.compact,
                  shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                    borderRadius: ThemeConfig.borderRadiusSmall
                  ))
              ),
              child: Text(
                '💡 How to get this data',
                style: ThemeConfig.textTheme.bodySmall,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget safeTxCalldataTab(){
    return Container(
      key: ValueKey<int>(manualInputSubIndex),
      child: Column(
        children: [
          SafeTxCalldataInput(
            controller: _callDataController,
            focusNode: _callDataFocusNode,
            hintText: _callDataInputHint,
            legacyJson: isLegacyJson,
            onValidInput: (safeTx){
              setState(() => safeTransaction = safeTx);
            },
          ),
          const SizedBox(height: 10),
          Container(
            alignment: Alignment.centerRight,
            child: OutlinedButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) => const SafeTxCalldataGuideSheet(),
                  isScrollControlled: true,
                  showDragHandle: true,
                  useSafeArea: true,
                  shape: RoundedRectangleBorder(
                    borderRadius: ThemeConfig.borderRadiusLarge,
                  )
                );
              },
              style: ButtonStyle(
                  padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
                  visualDensity: VisualDensity.compact,
                  shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                    borderRadius: ThemeConfig.borderRadiusSmall
                  ))
              ),
              child: Text(
                '💡 How to get this data',
                style: ThemeConfig.textTheme.bodySmall,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget safeTxApiTab(){
    return Container(
      key: ValueKey<int>(currentIndex),
      child: Column(
        children: [
          SafeTxAPIInput(
            safeAccount: widget.safeAccount,
            onValidInput: (safeTx){
              setState(() => safeTransaction = safeTx);
              _onSubmit();
            },
          ),
          const SizedBox(height: 10),
          Container(
            alignment: Alignment.centerRight,
            child: OutlinedButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) => const SafeTxAPIGuideSheet(),
                  isScrollControlled: true,
                  showDragHandle: true,
                  useSafeArea: true,
                  shape: RoundedRectangleBorder(
                    borderRadius: ThemeConfig.borderRadiusLarge,
                  )
                );
              },
              style: ButtonStyle(
                  padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
                  visualDensity: VisualDensity.compact,
                  shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                    borderRadius: ThemeConfig.borderRadiusSmall
                  ))
              ),
              child: Text(
                '💡 About Safe API',
                style: ThemeConfig.textTheme.bodySmall,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget manualInputTab(){
    return Container(
      key: ValueKey<int>(currentIndex),
      child: Column(
        children: [
          const SizedBox(height: 10),
          CupertinoTabBar(
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.onPrimary,
            [
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: "Signing",
                      style: manualInputSubIndex == 0 ? tabSelectedTextStyle : tabDeselectedTextStyle
                    ),
                    TextSpan(
                      text: "\nJSON",
                      style: TextStyle(
                        color: manualInputSubIndex == 0
                          ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.6)
                          : Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.5),
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: "Executing",
                      style: manualInputSubIndex == 1 ? tabSelectedTextStyle : tabDeselectedTextStyle
                    ),
                    TextSpan(
                      text: "\nCallData",
                      style: TextStyle(
                        color: manualInputSubIndex == 1
                          ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.6)
                          : Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.5),
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            manualInputSubTabBarValueGetter,
            (int index) {
              if (manualInputSubIndex == 0) {
                _jsonController.clear();
                _jsonFocusNode.unfocus();
              } else if (manualInputSubIndex == 1) {
                _callDataController.clear();
                _callDataFocusNode.unfocus();
              }
              lastManualInputSubIndex = manualInputSubIndex;
              setState(() {
                safeTransaction = null;
                manualInputSubIndex = index;
              });
            },
            borderRadius: BorderRadius.circular(50),
          ),
          const SizedBox(height: 10),
          PageTransitionSwitcher(
            duration: const Duration(milliseconds: 500),
            reverse: manualInputSubIndex < lastManualInputSubIndex,
            transitionBuilder: (
              child,
              animation,
              secondaryAnimation,
            ) {
              return SharedAxisTransition(
                animation: animation,
                secondaryAnimation: secondaryAnimation,
                transitionType: SharedAxisTransitionType.horizontal,
                child: child,
              );
            },
            child: manualInputSubIndex == 0
              ? safeTxJsonTab()
              : safeTxCalldataTab(),
          ),
        ],
      ),
    );
  }

}