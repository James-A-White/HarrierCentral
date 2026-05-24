import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Captures all debugPrint output during app startup and exposes it for
/// the on-screen boot log overlay.
///
/// Call [install] once at the very top of main() before runApp.
/// Remove this file and its callers once the boot hang is diagnosed.
class BootLogger {
  BootLogger._();

  static final List<String> _lines = [];
  static final StreamController<int> _controller =
      StreamController<int>.broadcast();

  static Stream<int> get onChanged => _controller.stream;
  static List<String> get lines => _lines;

  static void install() {
    final DebugPrintCallback original = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      original(message, wrapWidth: wrapWidth);
      if (message != null && !_controller.isClosed) {
        _lines.add(message);
        _controller.add(_lines.length);
      }
    };
  }
}

/// Scrolling debug log panel. Pin it to the bottom of any screen via a Stack
/// + Positioned while troubleshooting the boot sequence.
class BootLogOverlay extends StatefulWidget {
  const BootLogOverlay({super.key});

  @override
  State<BootLogOverlay> createState() => _BootLogOverlayState();
}

class _BootLogOverlayState extends State<BootLogOverlay> {
  final ScrollController _scroll = ScrollController();
  late final StreamSubscription<int> _sub;
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    _sub = BootLogger.onChanged.listen((_) {
      if (!mounted) return;
      setState(() {});
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.jumpTo(_scroll.position.maxScrollExtent);
        }
      });
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _copyToClipboard() async {
    final text = BootLogger.lines.join('\n');
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final lines = BootLogger.lines;
    return Container(
      color: const Color.fromRGBO(0, 0, 0, 0.80),
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
      child: Column(
        children: [
          Expanded(
            child: lines.isEmpty
                ? const Center(
                    child: Text(
                      'Waiting for boot log…',
                      style: TextStyle(color: Color(0xFF888888), fontSize: 11),
                    ),
                  )
                : ListView.builder(
                    controller: _scroll,
                    itemCount: lines.length,
                    itemBuilder: (context, i) => Text(
                      lines[i],
                      style: const TextStyle(
                        color: Color(0xFF88FF88),
                        fontSize: 10,
                        fontFamily: 'Courier',
                        height: 1.4,
                      ),
                    ),
                  ),
          ),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: lines.isEmpty ? null : _copyToClipboard,
              icon: Icon(
                _copied ? Icons.check : Icons.copy,
                size: 14,
                color: _copied ? Colors.greenAccent : Colors.white70,
              ),
              label: Text(
                _copied ? 'Copied!' : 'Copy log to clipboard',
                style: TextStyle(
                  fontSize: 12,
                  color: _copied ? Colors.greenAccent : Colors.white70,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
