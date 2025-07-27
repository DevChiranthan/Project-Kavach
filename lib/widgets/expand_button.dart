import 'package:flutter/material.dart';

class ExpandButton extends StatelessWidget {
  const ExpandButton({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30.0),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withAlpha((255 * 0.2).round()),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Tap to Expand',
              style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(width: 40),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
                color: Colors.grey[200], shape: BoxShape.circle),
            child: const Icon(Icons.arrow_forward_ios, size: 14),
          ),
        ],
      ),
    );
  }
}