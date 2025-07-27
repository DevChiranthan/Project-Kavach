import 'package:flutter/material.dart';
import 'package:project_kavach_app/widgets/vital_sign_widget.dart';

class VitalsCard extends StatelessWidget {
  const VitalsCard({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
          color: Colors.grey[100], borderRadius: BorderRadius.circular(12.0)),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          VitalSignWidget(
              icon: Icons.favorite_border, title: 'Heart', value: '72', unit: 'BPM'),
          VitalSignWidget(icon: Icons.thermostat, title: 'SpO2', value: '98%'),
          VitalSignWidget(
              icon: Icons.sentiment_very_dissatisfied,
              title: 'Low',
              value: 'Anxiety'),
        ],
      ),
    );
  }
}