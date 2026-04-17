import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:safe_opensig/shared/models/hw_wallets/hw_content_generator.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class LedgerContentVerificationScreen extends StatefulWidget {
  final List<HWPageContent> pages;
  const LedgerContentVerificationScreen({super.key, required this.pages});

  @override
  State<LedgerContentVerificationScreen> createState() => _LedgerContentVerificationScreenState();
}

class _LedgerContentVerificationScreenState extends State<LedgerContentVerificationScreen> {
  int currentLedgerPage = 0;

  void _showZoomSheet(BuildContext context) async {
    int zoomPage = currentLedgerPage;
    await showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final page = widget.pages[zoomPage];
          final canPrev = zoomPage > 0;
          final canNext = zoomPage < widget.pages.length - 1;
          return Dialog(
            insetPadding: const EdgeInsets.all(20),
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).pop(),
              child: Stack(
                children: [
                  Center(
                    // Absorb taps on the content so taps on the black rectangle
                    // or its controls do not dismiss the dialog.
                    child: GestureDetector(
                      onTap: () {},
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AspectRatio(
                            aspectRatio: 132 / 64,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  width: 1,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: FittedBox(
                                  fit: BoxFit.contain,
                                  alignment: Alignment.center,
                                  child: SizedBox(
                                    width: 132,
                                    height: 64,
                                    child: DefaultTextStyle(
                                      style: const TextStyle(color: Colors.white),
                                      child: IconTheme(
                                        data: const IconThemeData(color: Colors.white),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 2),
                                          child: Column(
                                            children: [
                                              for (var line in page.lines)
                                                _LedgerLinePainter(line: line),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.chevron_left_rounded,
                                    color: Colors.white, size: 32),
                                onPressed: canPrev
                                    ? () => setModalState(() => zoomPage--)
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '${zoomPage + 1} / ${widget.pages.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 12),
                              IconButton(
                                icon: const Icon(Icons.chevron_right_rounded,
                                    color: Colors.white, size: 32),
                                onPressed: canNext
                                    ? () => setModalState(() => zoomPage++)
                                    : null,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    if (mounted && zoomPage != currentLedgerPage) {
      setState(() => currentLedgerPage = zoomPage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.shield_outlined),
                    SizedBox(width: 4),
                    Text(
                      "Review on your Ledger device",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(height: 6),
                Text(
                  'Every character must match your device. If anything differs, do not sign.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.color
                        ?.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8),
          Card(
            elevation: 8,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => _showZoomSheet(context),
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 5),
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height * 0.5,
                child: Stack(
                  children: [
                    Center(
                      child: Image.asset("assets/hardware_wallets/ledger_nano_light.png")
                    ),
                    Positioned(
                      top: 7,
                      bottom: 0,
                      right: 89.5,
                      left: 0,
                      child: Center(
                        child: SizedBox(
                          width: 132,
                          height: 64,
                          // color: Colors.white.withValues(alpha: 0.9),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Column(
                              children: [
                                for (var line in widget.pages[currentLedgerPage].lines)
                                  _LedgerLinePainter(line: line),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surface
                              .withValues(alpha: 0.85),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.zoom_in_rounded,
                          size: 18,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 10),
          AnimatedSmoothIndicator(
            activeIndex: currentLedgerPage,
            count: widget.pages.length,
            effect: WormEffect(
              activeDotColor: Colors.green.shade900,
              dotColor: Colors.green.shade900.withValues(alpha: 0.25),
              dotHeight: 10,
              dotWidth: 10,
            ),
          ),
          Spacer(),
          if (currentLedgerPage <= widget.pages.length-1)
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: OutlinedButton(
                    onPressed: () => context.go('/accounts'),
                    child: Text("Close"),
                  ),
                ),
                Spacer(),
                Card(
                  margin: EdgeInsets.only(bottom: 16),
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50)
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton(
                          onPressed: currentLedgerPage > 0 ? () => setState(() => currentLedgerPage--) : null,
                          style: ButtonStyle(
                            shape: WidgetStatePropertyAll(CircleBorder()),
                            padding: WidgetStatePropertyAll(EdgeInsets.all(0)),
                            minimumSize: WidgetStatePropertyAll(Size(48, 48)),
                            visualDensity: VisualDensity.compact,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Icon(Icons.chevron_left_rounded, size: 32),
                        ),
                        SizedBox(width: 8,),
                        Builder(
                            builder: (context) {
                              if (currentLedgerPage == widget.pages.length-1){
                                return ElevatedButton(
                                  onPressed: (){
                                    GoRouter.of(context).go("/accounts");
                                  },
                                  style: ButtonStyle(
                                    shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(64)
                                    )),
                                    padding: WidgetStatePropertyAll(EdgeInsets.all(12)),
                                    minimumSize: WidgetStatePropertyAll(Size(0, 48)),
                                    visualDensity: VisualDensity.compact,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text("Finish"),
                                );
                              }
                              return ElevatedButton(
                                onPressed: () => setState(() => currentLedgerPage++),
                                style: ButtonStyle(
                                  shape: WidgetStatePropertyAll(CircleBorder()),
                                  padding: WidgetStatePropertyAll(EdgeInsets.all(0)),
                                  minimumSize: WidgetStatePropertyAll(Size(48, 48)),
                                  visualDensity: VisualDensity.compact,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Icon(Icons.chevron_right_rounded, size: 32),
                              );
                            }
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
        ],
      ),
    );
  }
}

class _LedgerLinePainter extends StatelessWidget {
  final String line;
  const _LedgerLinePainter({super.key, required this.line});

  @override
  Widget build(BuildContext context) {
    var parts = line.split(":");
    var type = parts[0];
    String iconName = "";
    String fontWeight = "";
    String content = "";
    if (type == "text"){
      fontWeight = parts[1];
      content = parts[2];
    }else{
      iconName = parts[1];
    }
    if (type == "icon"){
      IconData iconData;
      if (iconName == "eye"){
        iconData = Icons.remove_red_eye_rounded;
      }else{
        iconData = Icons.question_mark; // default
      }
      return Icon(iconData);
    }
    if (type == "text"){
      FontWeight _fontWeight = FontWeight.normal;
      if (fontWeight == "bold"){
        _fontWeight = FontWeight.bold;
      }
      return Text(
        content,
        style: TextStyle(fontSize: 11, height: 1.25, fontWeight: _fontWeight)
      );
    }
    return SizedBox.shrink();
  }
}

