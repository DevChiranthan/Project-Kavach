import 'package:flutter/material.dart';

class VitalSignWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String? unit;
  const VitalSignWidget(
      {super.key,
      required this.icon,
      required this.title,
      required this.value,
      this.unit});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, color: Colors.grey[600], size: 16),
          const SizedBox(width: 4),
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        ]),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(value,
                style:
                    const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            if (unit != null) const SizedBox(width: 2),
            if (unit != null)
              Text(unit!,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500)),
          ],
        )
      ],
    );
  }
}