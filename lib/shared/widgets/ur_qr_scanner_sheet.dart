import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:bc_ur/bc_ur.dart';
import 'package:safe_opensig/shared/models/safe_transaction_model.dart';
import 'package:safe_opensig/shared/utils/ur_payload_decoder.dart';

/// A continuous QR scanner that reconstructs an ERC-4527 / BC-UR
/// fountain-coded signing payload from a stream of animated QR frames.
///
/// Unlike [AddressQrScannerSheet], which closes after a single valid
/// scan, this sheet stays open and keeps feeding every scanned
/// `ur:...` frame into a [BCURFountainDecoder]. The Luby-transform
/// decoder reassembles the original message from *any sufficient subset*
/// of frames (you do not need to catch them in order, and duplicates are
/// harmless), so the camera just runs until `isComplete` flips true.
///
/// Once complete, the reconstructed [BCUR] is decoded into a
/// [SafeTransaction] via [UrPayloadDecoder] and handed to [onComplete].
class UrQrScannerSheet extends StatefulWidget {
  /// True for Safe accounts < 1.0.0 (uses `dataGas` instead of `baseGas`).
  final bool legacyJson;

  /// Called with the reconstructed [SafeTransaction] once the fountain
  /// decode succeeds. The sheet pops itself first.
  final Function(SafeTransaction) onComplete;

  const UrQrScannerSheet({
    super.key,
    required this.legacyJson,
    required this.onComplete,
  });

  @override
  State<UrQrScannerSheet> createState() => _UrQrScannerSheetState();
}

class _UrQrScannerSheetState extends State<UrQrScannerSheet>
    with WidgetsBindingObserver {
  final GlobalKey _qrKey = GlobalKey();
  MobileScannerController? controller;
  bool? cameraPermissionDenied;

  late BCURFountainDecoder _decoder;
  String _lastPart = '';
  String? _error;
  bool _done = false;
  String _detectedType = '';

  @override
  void initState() {
    _decoder = BCURFountainDecoder();
    _permissionRequest();
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _done = true;
    controller?.dispose();
    super.dispose();
  }

  void _initController() {
    controller = MobileScannerController(
      autoStart: true,
      formats: [BarcodeFormat.qrCode],
    );
    controller!.barcodes.listen(_onDetect);
  }

  Future<void> _permissionRequest() async {
    var permissionResult = await Permission.camera.request();
    cameraPermissionDenied = !permissionResult.isGranted;
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        if (cameraPermissionDenied != false) _permissionRequest();
        break;
      default:
        break;
    }
  }

  /// Handle every barcode frame. This is the hot loop: it runs many
  /// times per second while the animated QR cycles, so it must be cheap.
  /// Duplicates are skipped; only `ur:` frames are accepted.
  void _onDetect(event) {
    if (!mounted || _done) return;
    if (event.barcodes.isEmpty) return;
    var raw = event.barcodes.first.rawValue ?? '';
    if (raw.isEmpty) return;
    // BC-UR bytewords encoding is case-insensitive; some wallets emit
    // uppercase "UR:". Normalise to lowercase for the bc_ur library.
    raw = raw.toLowerCase();
    if (!raw.startsWith('ur:')) return;
    if (raw == _lastPart) return; // dedupe the same frame held in view
    _lastPart = raw;

    try {
      final segments = raw.substring(3).split('/');

      // Single-part UR: ur:type/payload  (no seqNum-seqLength segment)
      if (segments.length == 2) {
        _detectedType = segments[0];
        setState(() {});
        _finish(BCUR.fromString(raw));
        return;
      }

      // Multipart / fountain-coded UR: ur:type/seqNum-seqLength/fragment
      if (segments.length != 3) return;
      _detectedType = segments[0];
      _decoder.receivePart(raw);
      setState(() {}); // refresh progress UI

      if (_decoder.isComplete) {
        final result = _decoder.getResult();
        if (result != null) {
          _finish(result);
        } else {
          // Checksum / metadata mismatch — reset and keep scanning.
          setState(() {
            _error = 'Reconstruction failed (checksum mismatch). '
                'Re-scan from the start of the sequence.';
          });
          _decoder.reset();
          _lastPart = '';
        }
      }
    } catch (e) {
      setState(() => _error = 'Scan error: $e');
    }
  }

  /// Decode the reconstructed UR into a SafeTransaction and finish.
  /// On decode failure, surface the error and let the user re-scan
  /// rather than closing the sheet.
  void _finish(BCUR ur) {
    if (_done) return;
    try {
      final tx = UrPayloadDecoder.decode(ur, legacyJson: widget.legacyJson);
      _done = true; // stop _onDetect from processing further frames
      Navigator.of(context).pop();
      widget.onComplete(tx);
    } catch (e) {
      setState(() {
        _error = 'Decoded a "$_detectedType" UR, but it is not a valid '
            'Safe signing payload:\n$e';
        _done = false;
      });
      _decoder.reset();
      _lastPart = '';
    }
  }

  void _reset() {
    setState(() {
      _decoder.reset();
      _lastPart = '';
      _error = null;
      _detectedType = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: cameraPermissionDenied == null
          ? const FittedBox(
              fit: BoxFit.scaleDown,
              child: CircularProgressIndicator(),
            )
          : cameraPermissionDenied!
              ? _buildPermissionDenied()
              : Builder(
                  builder: (context) {
                    if (controller == null) _initController();
                    return _buildScanner();
                  },
                ),
    );
  }

  Widget _buildPermissionDenied() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      margin: const EdgeInsets.symmetric(horizontal: 15),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.warning, size: 40, color: Colors.amber),
          const SizedBox(height: 10),
          const Text(
            'Camera permission is required to scan ERC-4527 QR frames.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => openAppSettings(),
            child: const Text('Open settings'),
          ),
        ],
      ),
    );
  }

  Widget _buildScanner() {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height * 0.75,
      child: Stack(
        children: [
          // Camera feed — stays running the whole time.
          MobileScanner(
            key: _qrKey,
            controller: controller,
            fit: BoxFit.cover,
          ),
          // Scanning reticle + progress overlay.
          _buildOverlay(),
        ],
      ),
    );
  }

  Widget _buildOverlay() {
    final theme = Theme.of(context);
    final expected = _decoder.expectedCount;
    final received = _decoder.receivedCount;
    final progress = _decoder.progress;

    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Header
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.qr_code_scanner, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _detectedType.isEmpty
                        ? 'Point at the animated QR stream…'
                        : 'Reconstructing "$_detectedType"',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (expected > 0)
                  Text(
                    '$received / $expected',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
              ],
            ),
          ),
          const Spacer(),
          // Reticle
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _error != null
                      ? Colors.redAccent
                      : theme.colorScheme.primary.withValues(alpha: 0.9),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const Spacer(),
          // Progress bar + status
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_error != null) ...[
                  Text(
                    _error!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _reset,
                    icon: const Icon(Icons.refresh, size: 16, color: Colors.white),
                    label: const Text('Retry', style: TextStyle(color: Colors.white)),
                  ),
                ] else if (expected > 0) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white24,
                      valueColor: AlwaysStoppedAnimation(
                        theme.colorScheme.primary.withValues(alpha: 0.9),
                      ),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(progress * 100).round()}% — keep the camera steady',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ] else ...[
                  const Text(
                    'Waiting for first frame…',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
