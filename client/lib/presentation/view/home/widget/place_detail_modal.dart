import 'package:flutter/material.dart';
import 'package:tigo/core/constant/assets.dart';
class PlaceDetailModal extends StatelessWidget {
  const PlaceDetailModal({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          color: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  Image.asset(
                    Assets.parisBackgroundImage,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 300,
                  ),

                  const Positioned(
                    top: 16,
                    left: 16,
                    child: Image(
                      image: AssetImage(Assets.flagFranceImage),
                      width: 60,
                      height: 45,
                    ),
                  ),
                ],
              ),
              // 텍스트 설명
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: const [
                    Text(
                      'About France 🇫🇷',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'France is a romantic country in Europe, known for its iconic landmarks such as the Eiffel Tower, the Louvre Museum, and the Seine River.'
                          'It is also renowned as a center of delicious cuisine, art, and fashion, with Paris standing at the heart of its rich cultural heritage.',
                      style: TextStyle(fontSize: 14, color: Colors.black87),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
