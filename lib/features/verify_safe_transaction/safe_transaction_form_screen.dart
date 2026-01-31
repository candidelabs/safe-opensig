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
import 'package:safe_opensig/shared/models/safe_account_model.dart';
import 'package:safe_opensig/shared/models/safe_transaction_model.dart';
import 'package:version/version.dart';

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
    final (success, error) = await safeTransaction!.ensureNonce(widget.safeAccount);
    cancelLoad();
    if (!mounted) return;

    if (!success) {
      BotToast.showText(text: error);
      return;
    }

    GoRouter.of(context).push(
      "/verify-transaction/simulation-loading",
      extra: (widget.safeAccount, safeTransaction!),
    );
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