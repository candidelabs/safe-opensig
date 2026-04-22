import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:safe_opensig/features/verify_safe_transaction/ledger_verification/ledger_content_verification_screen.dart';
import 'package:safe_opensig/shared/constants/analytics_events.dart';
import 'package:safe_opensig/shared/models/hw_wallets/hw_content_generator.dart';
import 'package:safe_opensig/shared/models/hw_wallets/ledger/ledger_nano_s_plus.dart';
import 'package:safe_opensig/shared/models/safe_account_model.dart';
import 'package:safe_opensig/shared/models/safe_transaction_model.dart';
import 'package:safe_opensig/shared/services/analytics_service.dart';
import 'package:safe_opensig/shared/widgets/offline_capability_note.dart';
import 'package:version/version.dart';

class SafeLedgerVerifyScreen extends StatefulWidget {
  final SafeAccount safeAccount;
  final SafeTransaction safeTransaction;
  const SafeLedgerVerifyScreen({
    super.key,
    required this.safeAccount,
    required this.safeTransaction,
  });

  @override
  State<SafeLedgerVerifyScreen> createState() => _SafeLedgerVerifyScreenState();
}

class _SafeLedgerVerifyScreenState extends State<SafeLedgerVerifyScreen> {
  int currentPageIndex = 0;
  int previousPageIndex = 0;
  bool _hwPreviewTracked = false;
  late HWContentGenerator contentGenerator;

  @override
  void initState() {
    contentGenerator = LedgerNanoSPlusContentGenerator();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: currentPageIndex == 0 ? null : IconButton(
          icon: const Icon(Icons.arrow_back_outlined),
          onPressed: () => setState(() {previousPageIndex=1;currentPageIndex = 0;}),
        ),
        title: const Text('Hardware Verification'),
        actions: [
          IconButton(
            icon: const Icon(Icons.airplanemode_active),
            tooltip: 'Can work offline',
            onPressed: () => showOfflineCapabilitySheet(context),
          ),
        ],
      ),
      body: PageTransitionSwitcher(
        duration: const Duration(milliseconds: 500),
        reverse: currentPageIndex < previousPageIndex,
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
        child: currentPageIndex == 0 ? _hwSelectionPage() : FutureBuilder<List<HWPageContent>>(
          future: contentGenerator.generateVerificationPages(
            Version.parse("0.0.0"), // todo add actual version
            widget.safeAccount,
            widget.safeTransaction,
          ),
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || snapshot.data == null) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48),
                    const SizedBox(height: 16),
                    const Text(
                      "Couldn't build the Ledger preview.",
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error ?? "Unknown error"}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 24),
                    OutlinedButton(
                      onPressed: () => setState(() {
                        previousPageIndex = 1;
                        currentPageIndex = 0;
                      }),
                      child: const Text('Back'),
                    ),
                  ],
                ),
              );
            }
            return LedgerContentVerificationScreen(
              pages: snapshot.data,
            );
          },
        ),
      ),
    );
  }

  Widget _hwSelectionPage() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: constraints.maxWidth,
              minHeight: constraints.maxHeight,
            ),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _HardwareWalletSelectionPage(
                  onProceed: () {
                    if (!_hwPreviewTracked) {
                      _hwPreviewTracked = true;
                      Analytics.trackHardwarePreviewViewed(
                        widget.safeAccount.network.chainPrefix,
                        AnalyticsDevices.ledgerNanoSPlus,
                      );
                    }
                    setState(() {
                      currentPageIndex = 1;
                    });
                  },
                  onSkip: () {
                    GoRouter.of(context).go("/accounts");
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HardwareWalletSelectionPage extends StatelessWidget {
  final VoidCallback onProceed;
  final VoidCallback onSkip;
  const _HardwareWalletSelectionPage({
    required this.onProceed,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Ledger Nano (Classics)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text("S, S Plus, X", style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color)),
                  ],
                ),
              ),
              Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary),
            ],
          ),
        ),
        SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {
              launchUrl(Uri.parse('https://github.com/candidelabs/safe-opensig/issues/new?title=Hardware+wallet+support+request&labels=enhancement'));
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Don't see your device? Request support", style: TextStyle(fontSize: 12)),
                SizedBox(width: 4),
                Icon(Icons.open_in_new, size: 12),
              ],
            ),
          ),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Icon(Icons.info_outline),
            SizedBox(width: 4,),
            Text("Ledger Version Info", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),)
          ],
        ),
        SizedBox(height: 4),
        Card(
          elevation: 4,
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Text("Firmware"),
                    Spacer(),
                    Text("v2.5.0+", style: TextStyle(fontWeight: FontWeight.bold),),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Text("Ethereum App"),
                    Spacer(),
                    Text("v0.18.0+", style: TextStyle(fontWeight: FontWeight.bold),),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Icon(Icons.settings),
            SizedBox(width: 4,),
            Text("Required Ledger Settings", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),)
          ],
        ),
        SizedBox(height: 4),
        Card(
          elevation: 4,
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Text("Blind Signing"),
                    Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                          border: Border.all(
                              color: Colors.green
                          ),
                          borderRadius: BorderRadius.circular(25)
                      ),
                      child: Text("Enabled", style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold),),
                    )
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Text("Debug Contract Data"),
                    Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                          border: Border.all(
                              color: Colors.green
                          ),
                          borderRadius: BorderRadius.circular(25)
                      ),
                      child: Text("Enabled", style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold),),
                    )
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Text("Raw Messages (EIP-712)"),
                    Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                          border: Border.all(
                              color: Colors.grey.withValues(alpha: 0.6)
                          ),
                          borderRadius: BorderRadius.circular(25)
                      ),
                      child: Text("Disabled", style: TextStyle(fontSize: 12, color: Colors.grey.withValues(alpha: 0.6), fontWeight: FontWeight.bold),),
                    )
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Text("Transaction Hash Display"),
                    Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                          border: Border.all(
                              color: Colors.green
                          ),
                          borderRadius: BorderRadius.circular(25)
                      ),
                      child: Text("Enabled", style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold),),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                builder: (context) => Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Why these settings?", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      SizedBox(height: 12),
                      Text(
                        "These settings provide an optimal balance of security and usability when signing Safe transactions.\n\n"
                        "• Transaction Hash Display and Debug Contract Data allow you to verify domain and message hashes.\n\n"
                        "• Keeping EIP-712 Raw Messages disabled avoids review fatigue from overly verbose displays.",
                        style: TextStyle(fontSize: 14, height: 1.5),
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              );
            },
            icon: Icon(Icons.help_outline, size: 16),
            label: Text("Why these settings?", style: TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),
        Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton(
              onPressed: () => onSkip.call(),
              child: const Text('Skip', style: TextStyle(color: Colors.white)),
            ),
            SizedBox(width: 4),
            ElevatedButton(
              onPressed: () => onProceed.call(),
              child: const Text('Proceed'),
            ),
          ],
        ),
      ],
    );
  }
}
