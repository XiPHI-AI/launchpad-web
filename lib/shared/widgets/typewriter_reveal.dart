import 'dart:async';

import 'package:flutter/material.dart';

/// Reveals text progressively for a typewriter effect.
///
/// Use [enabled=false] to render full text immediately.
class TypewriterReveal extends StatefulWidget {
  final String text;
  final bool enabled;
  final Widget Function(String visibleText) builder;
  final VoidCallback? onTick;
  final VoidCallback? onComplete;

  const TypewriterReveal({
    super.key,
    required this.text,
    required this.enabled,
    required this.builder,
    this.onTick,
    this.onComplete,
  });

  @override
  State<TypewriterReveal> createState() => _TypewriterRevealState();
}

class _TypewriterRevealState extends State<TypewriterReveal> {
  Timer? _timer;
  int _visibleCount = 0;

  @override
  void initState() {
    super.initState();
    _restartAnimation();
  }

  @override
  void didUpdateWidget(covariant TypewriterReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text || oldWidget.enabled != widget.enabled) {
      _restartAnimation();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.onComplete?.call();
    super.dispose();
  }

  int _stepForLength(int length) {
    if (length > 1200) return 8;
    if (length > 700) return 6;
    if (length > 350) return 3;
    return 1;
  }

  void _restartAnimation() {
    _timer?.cancel();

    final text = widget.text;
    if (!widget.enabled || text.isEmpty) {
      _visibleCount = text.length;
      if (mounted) setState(() {});
      widget.onComplete?.call();
      return;
    }

    _visibleCount = 0;
    if (mounted) setState(() {});

    final step = _stepForLength(text.length);
    _timer = Timer.periodic(const Duration(milliseconds: 22), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_visibleCount >= text.length) {
        timer.cancel();
        widget.onComplete?.call();
        return;
      }

      setState(() {
        _visibleCount = (_visibleCount + step).clamp(0, text.length);
      });
      widget.onTick?.call();
      if (_visibleCount >= text.length) {
        widget.onComplete?.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final end = _visibleCount.clamp(0, widget.text.length);
    return widget.builder(widget.text.substring(0, end));
  }
}
