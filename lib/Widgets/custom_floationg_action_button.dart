import 'dart:math' as math;

import 'package:flutter/material.dart';

class CustomFloatingActionButton extends StatelessWidget {
  final Function()? onPressed;
  final Widget? child;
  final Object? heroTag;
  final double screenWidth;
  final double screenHeight;
  final Icon icon;

  const CustomFloatingActionButton({
    Key? key,
    this.onPressed,
    this.child,
    this.heroTag,
    required this.screenWidth,
    required this.screenHeight,
    required this.icon,
    required bool isExtended,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Transform.rotate(
        angle: -math.pi / 4,
        child: Material(
          color: Colors.transparent,
          child: Container(
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  blurRadius: 25,
                  offset: const Offset(0, 5),
                  color: const Color(0xFF635985)..withValues(alpha: 0.5),
                )
              ],
              borderRadius: const BorderRadius.all(Radius.circular(18)),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF634999),
                  Color(0xFF635985),
                ],
              ),
            ),
            height: getRelativeWidth(0.15),
            width: getRelativeWidth(0.15),
            child: Center(
              child: Transform.rotate(
                angle: math.pi / 4,
                child: icon,
              ),
            ),
          ),
        ),
      ),
    );
  }

  double getRelativeHeight(double percentage) {
    return percentage * screenHeight;
  }

  double getRelativeWidth(double percentage) {
    return percentage * screenWidth;
  }
}
