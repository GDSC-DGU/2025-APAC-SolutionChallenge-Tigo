import 'package:flutter/material.dart';
import 'package:rive/rive.dart' as rive;
import 'package:tigo/core/constant/assets.dart';

class TigoPickTodaySection extends StatefulWidget {
  final VoidCallback? onInfoTap;

  const TigoPickTodaySection({super.key, this.onInfoTap});

  @override
  State<TigoPickTodaySection> createState() => _TigoPickTodaySectionState();
}

class _TigoPickTodaySectionState extends State<TigoPickTodaySection> {
  late rive.RiveAnimationController _controller;

  double _characterX = 130;
  double _characterY = 180;
  bool _isFlipped = false;

  @override
  void initState() {
    super.initState();
    _controller = rive.SimpleAnimation('Blink');
  }

  void _moveCharacter(Offset position) {
    final tappedX = position.dx - 50;

    setState(() {
      _isFlipped = tappedX < _characterX;
      _controller = rive.SimpleAnimation('walk_right');
      _characterX = tappedX;
      _characterY = 280 - position.dy - 50;
    });

    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _controller = rive.SimpleAnimation('Blink');
      });
    });
  }

  void _onCharacterTap() {
    setState(() {
      _controller = rive.SimpleAnimation('jump');
    });

    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _controller = rive.SimpleAnimation('Blink');
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Tigo's Pick Today",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              GestureDetector(
                onTap: widget.onInfoTap,
                child: const Text(
                  "About this place?",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                Image.asset(
                  Assets.parisBackgroundImage,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 320,
                ),
                Container(
                  width: double.infinity,
                  height: 320,
                  color: Colors.white.withOpacity(0.5),
                ),
                GestureDetector(
                  onTapDown: (details) {
                    _moveCharacter(details.localPosition);
                  },
                  child: Container(
                    width: double.infinity,
                    height: 320,
                    color: Colors.transparent,
                  ),
                ),
                const Positioned(
                  top: 12,
                  left: 12,
                  child: Image(
                    image: AssetImage(Assets.flagFranceImage),
                    width: 52,
                    height: 42,
                  ),
                ),

                AnimatedPositioned(
                  duration: const Duration(seconds: 2),
                  curve: Curves.easeInOut,
                  bottom: _characterY,
                  left: _characterX,
                  child: GestureDetector(
                    onTap: _onCharacterTap,
                    child: SizedBox(
                      width: 140,
                      height: 140,
                      child: Transform(
                        alignment: Alignment.center,
                        transform:
                            Matrix4.identity()
                              ..scale(_isFlipped ? -1.0 : 1.0, 1.0),
                        child: rive.RiveAnimation.asset(
                          Assets.walkRive,
                          fit: BoxFit.contain,
                          controllers: [_controller],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
