import 'package:face_mood_light_detector/domain/enums/detection_state.dart';
import 'package:flutter/material.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({required this.state, super.key});

  final DetectionState state;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = _stateVisuals(state);

    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(label, style: TextStyle(color: color, fontSize: 12)),
      backgroundColor: color.withValues(alpha: 0.12),
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  (String, Color, IconData) _stateVisuals(DetectionState s) {
    return switch (s) {
      DetectionState.idle => ('Idle', Colors.grey, Icons.pause_circle_outline),
      DetectionState.detecting => (
        'Detecting',
        Colors.green,
        Icons.visibility,
      ),
      DetectionState.paused => ('Paused', Colors.orange, Icons.pause),
      DetectionState.error => ('Error', Colors.red, Icons.error_outline),
    };
  }
}
