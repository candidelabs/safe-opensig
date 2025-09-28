import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:safe_verify/features/verify_safe_transaction/ledger_verification/ledger_content_verification_screen.dart';
import 'package:safe_verify/shared/models/hw_wallets/hw_content_generator.dart';
import 'package:safe_verify/shared/models/hw_wallets/ledger/ledger_nano_s_plus.dart';
import 'package:safe_verify/shared/models/safe_account_model.dart';
import 'package:safe_verify/shared/models/safe_transaction_model.dart';
import 'package:version/version.dart';

class SafeLedgerVerifyScreen extends StatefulWidget {
  final SafeAccount safeAccount;
  final SafeTransaction safeTransaction;
  final BigInt nonce;
  const SafeLedgerVerifyScreen({super.key, required this.safeAccount, required this.safeTransaction, required this.nonce});

  @override
  State<SafeLedgerVerifyScreen> createState() => _SafeLedgerVerifyScreenState();
}

class _SafeLedgerVerifyScreenState extends State<SafeLedgerVerifyScreen> {
  int currentPageIndex = 0;
  int previousPageIndex = 0;
  HardwareWallet selectedHardwareWallet = HardwareWallet.ledger_nano;
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
          icon: const Icon(Icons.close),
          onPressed: () {
            context.go('/accounts');
          },
        ),
        title: const Text('Hardware Verification')
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
            widget.nonce
          ),
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if (snapshot.connectionState != ConnectionState.done){
              return CircularProgressIndicator();
            }
            return LedgerContentVerificationScreen(
              pages: snapshot.data,
            );
          },
        ),
      ),
    );
  }

  Widget _hwSelectionPage(){
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: _HardwareWalletSelectionPage(
        onChange: (newValue){
          setState(() {
            selectedHardwareWallet = newValue;
          });
        },
        onProceed: (){
          setState(() {
            currentPageIndex = 1;
          });
        },
        onSkip: (){
          GoRouter.of(context).go("/accounts");
        },
        value: selectedHardwareWallet,
      ),
    );
  }

}

class _HardwareWalletSelectionPage extends StatelessWidget {
  final HardwareWallet value;
  final Function(HardwareWallet) onChange;
  final VoidCallback onProceed;
  final VoidCallback onSkip;
  const _HardwareWalletSelectionPage({super.key, required this.value, required this.onChange, required this.onProceed, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        DropdownButtonFormField<HardwareWallet>(
          value: value,
          decoration: const InputDecoration(
            labelText: 'Hardware Wallet',
            border: OutlineInputBorder(),
          ),
          items: HardwareWallet.values.map((HardwareWallet hw) {
            return DropdownMenuItem<HardwareWallet>(
                value: hw,
                child: Text(hw.name)
            );
          }).toList(),
          onChanged: (HardwareWallet? newValue) {
            if (newValue == null) return;
            onChange.call(newValue);
          },
        ),
        SizedBox(height: 16,),
        Row(
          children: [
            Icon(Icons.settings),
            SizedBox(width: 4,),
            Text("Required Ledger Settings", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),)
          ],
        ),
        SizedBox(height: 4,),
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
        Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton(
              onPressed: () => onSkip.call(),
              child: const Text('Skip', style: TextStyle(color: Colors.white),),
            ),
            SizedBox(width: 4,),
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

