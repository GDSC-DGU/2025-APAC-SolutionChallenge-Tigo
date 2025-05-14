import 'package:flutter/material.dart';

class TempPlanCard extends StatelessWidget {
  final String iconAssetPath;
  final String title;
  final String date;
  final Color bgColor;
  final VoidCallback? onTap;

  const TempPlanCard({
    required this.iconAssetPath,
    required this.title,
    required this.date,
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
            SizedBox(
              width: 48,
              height: 48,
              child: Image.asset(
                iconAssetPath,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(
              date,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
