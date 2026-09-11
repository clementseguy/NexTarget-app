import 'package:flutter/material.dart';

/// Identifie une session libre sans reprendre l'action de création.
const IconData simpleSessionIcon = Icons.scatter_plot_outlined;

/// Badge compact partagé par les vues de session.
class SessionChip extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color? color;
  final bool overrideBase;
  final bool compact;

  const SessionChip({
    super.key,
    required this.text,
    required this.icon,
    this.color,
    this.overrideBase = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color base = color ??
        (overrideBase
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7));
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: base.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: base.withValues(alpha: 0.55), width: 0.6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 12 : 14, color: base),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: compact ? 11 : 12,
                fontWeight: FontWeight.w500,
                color: base,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
