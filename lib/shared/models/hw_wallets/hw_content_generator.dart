import 'package:safe_verify/shared/models/safe_account_model.dart';
import 'package:safe_verify/shared/models/safe_transaction_model.dart';
import 'package:version/version.dart';

enum HardwareWallet {
  ledger_nano("Ledger Nano");

  const HardwareWallet(this.name);
  final String name;
}

class HWScreenConfiguration {
  int screenLines;
  int lineWidth;
  int? lineMaxCharacters;
  int leadWidth;
  int trailWidth;

  HWScreenConfiguration({
    required this.screenLines,
    required this.lineWidth,
    this.lineMaxCharacters,
    required this.leadWidth,
    required this.trailWidth
  });

}

class HWPageContent {
  String lead;
  String trail;
  List<String> lines;

  HWPageContent({
    required this.lead,
    required this.trail,
    required this.lines,
  });

}

abstract class HWContentGenerator {
  late HWScreenConfiguration screenConfiguration;

  HWContentGenerator();

  Future<List<HWPageContent>> generateVerificationPages(
    Version appVersion,
    SafeAccount account,
    SafeTransaction transaction,
  );
}