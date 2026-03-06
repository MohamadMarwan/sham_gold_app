import 'dart:async';
import 'package:flutter/material.dart';

class LastUpdateTicker extends StatefulWidget {
  final DateTime? lastUpdate;
  final TextStyle? style;
  final bool showOnlySeconds; // New Flag

  const LastUpdateTicker({
    super.key,
    this.lastUpdate,
    this.style,
    this.showOnlySeconds = false,
  });

  @override
  State<LastUpdateTicker> createState() => _LastUpdateTickerState();
}

class _LastUpdateTickerState extends State<LastUpdateTicker> {
  Timer? _timer;
  String _text = '';

  @override
  void initState() {
    super.initState();
    _updateText();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateText());
  }

  @override
  void didUpdateWidget(covariant LastUpdateTicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.lastUpdate != oldWidget.lastUpdate) {
      _updateText();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateText() {
    if (widget.lastUpdate == null) {
      if (mounted) setState(() => _text = 'جارِ التحديث...');
      return;
    }

    final diff = DateTime.now().difference(widget.lastUpdate!);
    final seconds = diff.inSeconds;

    String newText;

    if (widget.showOnlySeconds) {
      if (seconds < 10) {
        newText = 'محدث الآن 🚀';
      } else if (seconds < 30) {
        newText = 'منذ ثوانٍ ⚡';
      } else if (seconds < 60) {
        newText = 'منذ $seconds ثانية ⚡';
      } else if (seconds < 3600) {
        final mins = seconds ~/ 60;
        newText = 'منذ $mins دقيقة ⚡';
      } else {
        newText = 'أكثر من ساعة ⚡';
      }
    } else {
      if (seconds < 10) {
        newText = 'محدث الآن ⚡';
      } else if (seconds < 60) {
        newText = 'منذ $seconds ثانية';
      } else if (seconds < 3600) {
        final mins = seconds ~/ 60;
        newText = 'منذ $mins دقيقة';
      } else {
        newText = 'أكثر من ساعة';
      }
    }

    if (mounted && _text != newText) {
      setState(() => _text = newText);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _text,
      style:
          widget.style ?? const TextStyle(color: Colors.white70, fontSize: 10),
    );
  }
}
