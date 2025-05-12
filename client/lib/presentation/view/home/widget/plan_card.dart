import 'package:flutter/material.dart';

class TempPlanCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String date;
  final Color iconColor;
  final Color bgColor;
  final VoidCallback? onTap;

  const TempPlanCard({
    required this.icon,
    required this.title,
    required this.date,
    required this.iconColor,
    required this.bgColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  backgroundColor: bgColor,
                  child: Icon(icon, color: iconColor),
                ),
                Switch(
                  value: true,
                  onChanged: (_) {},
                  activeColor: const Color(0xFF4A90E2),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(
              'created at $date',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
