import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

/// A single slide in a guide walkthrough.
///
/// [assetName] is the filename under `assets/images/guides/`. When null, the
/// slide renders a completion icon instead (for the final "you're done" step
/// that has no screenshot).
class GuideSlide {
  final int index;
  final String text;
  final String? assetName;
  final IconData? completionIcon;

  const GuideSlide({
    required this.index,
    required this.text,
    this.assetName,
    this.completionIcon,
  });
}

/// Step-by-step slideshow for the Manual Input guide sheets.
///
/// Shows one step at a time with a zoomable screenshot (tap to open full-screen
/// pan/zoom viewer). Users navigate via swipe or prev/next chevrons; a page
/// indicator and "Step X of Y" label show position.
class GuideSlideshow extends StatefulWidget {
  final List<GuideSlide> slides;
  const GuideSlideshow({super.key, required this.slides});

  @override
  State<GuideSlideshow> createState() => _GuideSlideshowState();
}

class _GuideSlideshowState extends State<GuideSlideshow> {
  late final PageController _controller;
  int _current = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    _controller.animateToPage(
      page,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final slides = widget.slides;
    final canPrev = _current > 0;
    final canNext = _current < slides.length - 1;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 480,
          child: PageView.builder(
            controller: _controller,
            itemCount: slides.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (context, i) => _SlideBody(slide: slides[i]),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            IconButton(
              onPressed: canPrev ? () => _goTo(_current - 1) : null,
              icon: const Icon(Icons.chevron_left_rounded),
              tooltip: 'Previous step',
            ),
            Expanded(
              child: Center(
                child: SmoothPageIndicator(
                  controller: _controller,
                  count: slides.length,
                  effect: ExpandingDotsEffect(
                    dotHeight: 6,
                    dotWidth: 6,
                    expansionFactor: 3,
                    activeDotColor: theme.colorScheme.primary,
                    dotColor: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: canNext ? () => _goTo(_current + 1) : null,
              icon: const Icon(Icons.chevron_right_rounded),
              tooltip: 'Next step',
            ),
          ],
        ),
        Text(
          'Step ${_current + 1} of ${slides.length}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

class _SlideBody extends StatelessWidget {
  final GuideSlide slide;
  const _SlideBody({required this.slide});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${slide.index}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(slide.text, style: theme.textTheme.bodyMedium),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: slide.assetName != null
              ? _ZoomableGuideImage(assetName: slide.assetName!)
              : slide.completionIcon != null
                  ? _CompletionBlock(icon: slide.completionIcon!)
                  : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _CompletionBlock extends StatelessWidget {
  final IconData icon;
  const _CompletionBlock({required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Icon(
        icon,
        size: 80,
        color: theme.colorScheme.primary.withValues(alpha: 0.7),
      ),
    );
  }
}

class _ZoomableGuideImage extends StatelessWidget {
  final String assetName;
  const _ZoomableGuideImage({required this.assetName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final path = 'assets/images/guides/$assetName';

    return GestureDetector(
      onTap: () => _openZoomViewer(context, path),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              path,
              fit: BoxFit.contain,
              alignment: Alignment.topCenter,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, _, _) => Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.12),
                  ),
                ),
                child: Text(
                  'Screenshot pending\n$assetName',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    fontFamily: 'monospace',
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
                color: theme.colorScheme.surface.withValues(alpha: 0.85),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.zoom_in_rounded,
                size: 18,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openZoomViewer(BuildContext context, String assetPath) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (context) => _ZoomViewerDialog(assetPath: assetPath),
    );
  }
}

class _ZoomViewerDialog extends StatefulWidget {
  final String assetPath;
  const _ZoomViewerDialog({required this.assetPath});

  @override
  State<_ZoomViewerDialog> createState() => _ZoomViewerDialogState();
}

class _ZoomViewerDialogState extends State<_ZoomViewerDialog>
    with SingleTickerProviderStateMixin {
  static const double _minScale = 1.0;
  static const double _maxScale = 8.0;
  static const double _doubleTapScale = 2.5;

  final TransformationController _controller = TransformationController();
  late final AnimationController _animController;
  Animation<Matrix4>? _animation;
  TapDownDetails? _lastDoubleTapDetails;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )..addListener(() {
        if (_animation != null) {
          _controller.value = _animation!.value;
        }
      });
  }

  @override
  void dispose() {
    _animController.dispose();
    _controller.dispose();
    super.dispose();
  }

  double get _currentScale =>
      _controller.value.getMaxScaleOnAxis().clamp(_minScale, _maxScale);

  void _animateTo(Matrix4 target) {
    _animation = Matrix4Tween(begin: _controller.value, end: target)
        .animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    ));
    _animController.forward(from: 0);
  }

  void _handleDoubleTap() {
    if (_currentScale > _minScale + 0.01) {
      _animateTo(Matrix4.identity());
      return;
    }
    final localPos = _lastDoubleTapDetails?.localPosition;
    final Matrix4 target = Matrix4.identity();
    if (localPos != null) {
      target
        ..translate(-localPos.dx * (_doubleTapScale - 1),
            -localPos.dy * (_doubleTapScale - 1))
        ..scale(_doubleTapScale);
    } else {
      target.scale(_doubleTapScale);
    }
    _animateTo(target);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Stack(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).pop(),
            child: Container(color: Colors.transparent),
          ),
          Center(
            child: GestureDetector(
              onDoubleTapDown: (d) => _lastDoubleTapDetails = d,
              onDoubleTap: _handleDoubleTap,
              child: InteractiveViewer(
                transformationController: _controller,
                minScale: _minScale,
                maxScale: _maxScale,
                child: Image.asset(
                  widget.assetPath,
                  fit: BoxFit.contain,
                  errorBuilder: (context, _, _) => Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'Screenshot pending',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded, color: Colors.white),
              tooltip: 'Close',
            ),
          ),
        ],
      ),
    );
  }
}
