import 'package:flutter/material.dart';

class BottomPaddingWrapper extends StatelessWidget {
  const BottomPaddingWrapper({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewPadding.bottom,
      ),
      child: child,
    );
  }
}
