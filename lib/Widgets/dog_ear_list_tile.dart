import 'package:flutter/material.dart';

class DogEarListTile extends StatelessWidget {
  final Widget leading;
  final Widget title;
  final Widget trailing;
  final Function()? onTap;

  const DogEarListTile({
    Key? key,
    required this.leading,
    required this.title,
    required this.trailing,
    this.onTap,
  }) : super(key: key);

  bool isRTL(BuildContext context) {
    return Directionality.of(context) == TextDirection.rtl;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              SizedBox(
                width: 10.0,
                height: 10.0,
                child: ClipPath(
                  clipper:
                      isRTL(context) ? DogEarRTLClipper() : DogEarLTRClipper(),
                  child: Container(
                    color: Colors.red,
                  ),
                ),
              ),
              SizedBox(
                width: 10.0,
                height: 10.0,
                child: ClipPath(
                  clipper: isRTL(context)
                      ? DogEarRTLClipper1()
                      : DogEarLTRClipper1(),
                  child: Container(
                    color: Theme.of(context).unselectedWidgetColor,
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: leading,
              title: title,
              trailing: trailing,
            ),
          ),
        ],
      ),
    );
  }
}

class DogEarLTRClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class DogEarLTRClipper1 extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, 0);

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class DogEarRTLClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class DogEarRTLClipper1 extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
