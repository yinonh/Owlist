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
    return 50; //percentage * screenHeight;
  }

  double getRelativeWidth(double percentage) {
    return 50; //percentage * screenWidth;
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
            onTap: onTap != null
                ? () {
                    onTap!();
                  }
                : null,
            child: Container(
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    blurRadius: 25,
                    offset: const Offset(0, 5),
                    color: const Color(0xFF635985).withOpacity(0.5),
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
              height: 50, //getRelativeWidth(0.15),
              width: 50, //getRelativeWidth(0.15),
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
    );
  }
}
