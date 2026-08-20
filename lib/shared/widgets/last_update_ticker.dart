import 'dart:async';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

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
      if (mounted) setState(() => _text = 'updating'.tr());
      return;
    }

    final diff = DateTime.now().difference(widget.lastUpdate!);
    final seconds = diff.inSeconds;
    final mins = seconds ~/ 60;

    String newText;

    if (widget.showOnlySeconds) {
      if (seconds < 10) {
        newText = 'updated_now'.tr();
      } else if (seconds < 60) {
        newText = 'seconds_ago'.tr();
      } else if (mins < 2) {
        newText = 'x_seconds_ago'.tr(args: [seconds.toString()]);
      } else if (mins < 60) {
        newText = 'x_minutes_ago'.tr(args: [mins.toString()]);
      } else {
        newText = 'more_than_hour'.tr();
      }
    } else {
      if (seconds < 10) {
        newText = 'updated_now_alt'.tr();
      } else if (seconds < 60) {
        newText = 'x_seconds_ago_alt'.tr(args: [seconds.toString()]);
      } else if (mins < 60) {
        newText = 'x_minutes_ago_alt'.tr(args: [mins.toString()]);
      } else {
        newText = 'more_than_hour_alt'.tr();
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
