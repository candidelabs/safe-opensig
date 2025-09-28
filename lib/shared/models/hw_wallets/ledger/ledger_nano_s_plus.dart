import 'package:safe_verify/shared/models/hw_wallets/hw_content_generator.dart';
import 'package:safe_verify/shared/models/safe_account_model.dart';
import 'package:safe_verify/shared/models/safe_transaction_model.dart';
import 'package:version/version.dart';

class LedgerNanoSPlusContentGenerator extends HWContentGenerator {
  // The width of each letter in pixels according to
  // https://github.com/LedgerHQ/ledger-secure-sdk/tree/6fa8509ffcfb6816ff92e2ab39a272c280eb171c/lib_nbgl/fonts/nbgl_font_open_sans_regular_11px_1bpp_unicode
  static final Map<String, int> _letterWidthMap = {
    ' ': 4,
    //
    '0': 7,
    '1': 7,
    '2': 7,
    '3': 7,
    '4': 9,
    '5': 7,
    '6': 7,
    '7': 7,
    '8': 7,
    '9': 7,
    //
    'a': 7,
    'b': 8,
    'd': 6,
    'c': 8,
    'e': 7,
    'f': 6,
    'g': 7,
    'h': 8,
    'i': 4,
    'j': 4,
    'k': 7,
    'l': 4,
    'm': 11,
    'n': 8,
    'o': 8,
    'p': 8,
    'q': 8,
    'r': 5,
    's': 6,
    't': 5,
    'u': 8,
    'v': 7,
    'w': 10,
    'x': 7,
    'y': 7,
    'z': 6,
    //
    'A': 8,
    'B': 8,
    'C': 8,
    'D': 9,
    'E': 7,
    'F': 7,
    'G': 9,
    'H': 9,
    'I': 4,
    'J': 4,
    'K': 8,
    'L': 7,
    'M': 11,
    'N': 9,
    'O': 10,
    'P': 8,
    'Q': 10,
    'R': 8,
    'S': 7,
    'T': 8,
    'U': 9,
    'V': 8,
    'W': 11,
    'X': 8,
    'Y': 7,
    'Z': 7,
  };

  LedgerNanoSPlusContentGenerator() {
    screenConfiguration = HWScreenConfiguration(
      leadWidth: 10,
      trailWidth: 10,
      lineWidth: 132,
      lineMaxCharacters: 18,
      screenLines: 4,
    );
  }

  List<String> _getLinesForString(String input){
    List<String> lines = [];
    String currentLine = "";
    int currentWidth = 0;
    for (int charCode in input.codeUnits){
      String char = String.fromCharCode(charCode);
      if (!_letterWidthMap.containsKey(char)) continue;
      var letterWidth = _letterWidthMap[char]!;
      var maxWidthReached = currentWidth + letterWidth >= 131;
      var maxCharsReached = screenConfiguration.lineMaxCharacters != null && currentLine.length >= screenConfiguration.lineMaxCharacters!;
      if (maxWidthReached || maxCharsReached){
        lines.add(currentLine);
        currentLine = "";
        currentWidth = 0;
      }
      currentLine = currentLine+char;
      currentWidth = currentWidth + letterWidth;
    }
    if (currentLine.isNotEmpty){
      lines.add(currentLine);
    }
    return lines;
  }

  @override
  Future<List<HWPageContent>> generateVerificationPages(
    Version appVersion,
    SafeAccount account,
    SafeTransaction transaction,
    BigInt nonce
  ) async {
    List<HWPageContent> result = [];
    result.add(HWPageContent(
      lead: "",
      lines: [
        "icon:eye",
        "text:normal:Review",
        "text:normal:typed message",
      ],
      trail: "icon:chevron-right"
    ));
    //
    result.add(HWPageContent(
      lead: "icon:chevron-left",
      lines: [
        "text:bold:chainId",
        "text:normal:${account.chainId}",
      ],
      trail: "icon:chevron-right"
    ));
    //
    var verifyingContractLines = _getLinesForString(account.address);
    verifyingContractLines = verifyingContractLines.map((e) => "text:normal:$e").toList();
    result.add(HWPageContent(
      lead: "icon:chevron-left",
      lines: [
        "text:bold:verifyingContract",
        ...verifyingContractLines
      ],
      trail: "icon:chevron-right"
    ));
    //
    var (_, messageHash) = await transaction.getMessageHash(account, nonce: nonce);
    var messageHashLines = _getLinesForString(messageHash);
    messageHashLines = messageHashLines.map((e) => "text:normal:$e").toList();
    result.add(HWPageContent(
      lead: "icon:chevron-left",
      lines: [
        "text:bold:Message hash(1/2)",
        ...(messageHashLines.sublist(0, 3)),
      ],
      trail: "icon:chevron-right"
    ));
    result.add(HWPageContent(
      lead: "icon:chevron-left",
      lines: [
        "text:bold:Message hash(2/2)",
        ...(messageHashLines.sublist(3)),
      ],
      trail: "icon:chevron-right"
    ));
    //
    var domainHash = account.getDomainHash();
    var domainHashLines = _getLinesForString(domainHash);
    domainHashLines = domainHashLines.map((e) => "text:normal:$e").toList();
    result.add(HWPageContent(
        lead: "icon:chevron-left",
        lines: [
          "text:bold:Domain hash(1/2)",
          ...(domainHashLines.sublist(0, 3)),
        ],
        trail: "icon:chevron-right"
    ));
    result.add(HWPageContent(
        lead: "icon:chevron-left",
        lines: [
          "text:bold:Domain hash(2/2)",
          ...(domainHashLines.sublist(3)),
        ],
        trail: "icon:chevron-right"
    ));
    //
    result.add(HWPageContent(
        lead: "icon:chevron-left",
        lines: [
          "text:bold:Message hash(1/2)",
          ...(messageHashLines.sublist(0, 3)),
        ],
        trail: "icon:chevron-right"
    ));
    result.add(HWPageContent(
        lead: "icon:chevron-left",
        lines: [
          "text:bold:Message hash(2/2)",
          ...(messageHashLines.sublist(3)),
        ],
        trail: "icon:chevron-right"
    ));
    return result;
  }

}