import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class DropdownLanguageItem extends DropdownMenuItem<String> {
  final String value;
  final String text;
  final String svgPath;

  DropdownLanguageItem({
    required this.value,
    required this.text,
    required this.svgPath,
  }) : super(
          value: value,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  text,
                  style: TextStyle(color: Colors.white),
                ),
                SvgPicture.asset(
                  svgPath,
                  width: 60,
                )
              ],
            ),
          ),
        );
}
