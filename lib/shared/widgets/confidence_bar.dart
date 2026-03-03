import 'package:flutter/material.dart';

class ConfidenceBar extends StatelessWidget {
  const ConfidenceBar({
    required this.label,
    required this.value,
    super.key,
    this.color,
    this.height = 20,
  });

  final String label;
  final double value;
  final Color? color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final fillColor = color ?? Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: height,
                child: LinearProgressIndicator(
                  value: value.clamp(0, 1),
                  backgroundColor: fillColor.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(fillColor),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 44,
            child: Text(
              '${(value * 100).toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
