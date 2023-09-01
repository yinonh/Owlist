import 'dart:math' as math;
import 'package:flutter/material.dart';

class DiamondButton extends StatelessWidget {
  final Icon icon;
  final Function? onTap;
  final double screenWidth;
  final double screenHeight;
  const DiamondButton(
      {required this.icon,
      required this.onTap,
      required this.screenWidth,
      required this.screenHeight,
      Key? key})
      : super(key: key);

  double getRelativeHeight(double percentage) {
    return percentage * screenHeight;
  }

  double getRelativeWidth(double percentage) {
    return percentage * screenWidth;
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Transform.rotate(
        angle: -math.pi / 4,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            customBorder: const CircleBorder(),
            child: GestureDetector(
              onTap: onTap != null
                  ? () {
                      onTap!();
                    }
                  : null,
              child: Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 25,
                      offset: const Offset(0, 5),
                      color: Color(0xFF635985).withOpacity(0.5),
                    )
                  ],
                  borderRadius: const BorderRadius.all(Radius.circular(18)),
                  gradient: LinearGradient(
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
        ),
      ),
    );
  }
}