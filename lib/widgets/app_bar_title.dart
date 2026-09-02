import 'package:flutter/material.dart';

class AppBarTitle extends StatelessWidget {
  final IconData icon;
  final String label;

  const AppBarTitle({
    super.key,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = DefaultTextStyle.of(context).style.color;

    return Row(
      children: [
        Icon(icon, size: 24, color: titleColor),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
