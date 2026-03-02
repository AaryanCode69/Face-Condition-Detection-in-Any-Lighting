import 'package:flutter/material.dart';

/// Stub in Phase 1; wired to real metrics in Phase 6.
class FpsCounter extends StatelessWidget {
  const FpsCounter({
    super.key,
    this.fps = 0,
    this.latencyMs = 0,
  });

  final double fps;

  /// Pipeline latency in ms.
  final int latencyMs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '${fps.toStringAsFixed(1)} FPS | ${latencyMs}ms',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}
