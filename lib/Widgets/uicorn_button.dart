import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

import '../Utils/show_case_helper.dart';
import '../Widgets/custom_floationg_action_button.dart';

class UnicornButton {
  final FloatingActionButton currentButton;

  UnicornButton({
    required this.currentButton,
  }) : assert(currentButton != null);

  Widget build(BuildContext context) {
    return currentButton;
  }
}

class UnicornDialer extends StatefulWidget {
  final Icon parentButton;
  final Icon finalButtonIcon;
  final bool hasBackground;
  final List<UnicornButton> childButtons;
  final int animationDuration;
  final int mainAnimationDuration;
  final double childPadding;
  final Color backgroundColor;
  final Function onMainButtonPressed;
  final Object parentHeroTag;
  final bool hasNotch;

  const UnicornDialer(
      {super.key,
      required this.parentButton,
      required this.childButtons,
      required this.onMainButtonPressed,
      this.hasBackground = true,
      this.backgroundColor = Colors.white30,
      this.parentHeroTag = "parent",
      required this.finalButtonIcon,
      this.animationDuration = 180,
      this.mainAnimationDuration = 200,
      this.childPadding = 0.0,
      this.hasNotch = false})
      : assert(parentButton != null);

  @override
  _UnicornDialer createState() => _UnicornDialer();
}

class _UnicornDialer extends State<UnicornDialer>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _parentController;

  bool isOpen = false;

  @override
  void initState() {
    _animationController = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: widget.animationDuration));

    _parentController = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: widget.mainAnimationDuration));

    super.initState();
  }

  @override
  dispose() {
    _animationController.dispose();
    _parentController.dispose();
    super.dispose();
  }

  void mainActionButtonOnPressed() {
    if (_animationController.isDismissed) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    _animationController.reverse();

    var hasChildButtons = widget.childButtons.isNotEmpty;

    if (!_parentController.isAnimating) {
      if (_parentController.isCompleted) {
        _parentController.forward().then((s) {
          _parentController.reverse().then((e) {
            _parentController.forward();
          });
        });
      }
      if (_parentController.isDismissed) {
        _parentController.reverse().then((s) {
          _parentController.forward();
        });
      }
    }

    var mainFAB = AnimatedBuilder(
      animation: _parentController,
      builder: (BuildContext context, Widget? child) {
        return Transform(
          transform: Matrix4.diagonal3(
            vector.Vector3(
              _parentController.value,
              _parentController.value,
              _parentController.value,
            ),
          ),
          alignment: FractionalOffset.center,
          child: CustomFloatingActionButton(
            icon: widget.parentButton,
            isExtended: false,
            heroTag: widget.parentHeroTag,
            onPressed: () {
              mainActionButtonOnPressed();
              if (widget.onMainButtonPressed != null) {
                widget.onMainButtonPressed();
              }
            },
            screenWidth: MediaQuery.of(context).size.width,
            screenHeight: MediaQuery.of(context).size.height,
            child: !hasChildButtons
                ? widget.parentButton
                : AnimatedBuilder(
                    animation: _animationController,
                    builder: (BuildContext context, Widget? child) {
                      return Transform(
                        transform:
                            Matrix4.rotationZ(_animationController.value * 0.8),
                        alignment: FractionalOffset.center,
                        child: Icon(
                          _animationController.isDismissed
                              ? widget.parentButton.icon
                              : widget.finalButtonIcon == null
                                  ? Icons.close_rounded
                                  : widget.finalButtonIcon.icon,
                        ),
                      );
                    },
                  ),
          ),
        );
      },
    );

    if (hasChildButtons) {
      var mainFloatingButton = AnimatedBuilder(
        animation: _animationController,
        builder: (BuildContext context, Widget? child) {
          // Change Widget to Widget?
          return Transform.rotate(
            angle: _animationController.value * 0.8,
            child: mainFAB,
          );
        },
      );

      var childButtonsList = widget.childButtons == null ||
              widget.childButtons.isEmpty
          ? []
          : List.generate(widget.childButtons.length, (index) {
              var intervalValue = index == 0
                  ? 0.9
                  : ((widget.childButtons.length - index) /
                          widget.childButtons.length) -
                      0.2;

              intervalValue =
                  intervalValue < 0.0 ? (1 / index) * 0.5 : intervalValue;

              var childFAB = FloatingActionButton(
                  onPressed: () {
                    if (widget.childButtons[index].currentButton.onPressed !=
                        null) {
                      widget.childButtons[index].currentButton.onPressed!();
                    }

                    _animationController.reverse();
                  },
                  heroTag: widget.childButtons[index].currentButton.heroTag,
                  backgroundColor:
                      widget.childButtons[index].currentButton.backgroundColor,
                  mini: widget.childButtons[index].currentButton.mini,
                  tooltip: widget.childButtons[index].currentButton.tooltip,
                  key: widget.childButtons[index].currentButton.key,
                  elevation: widget.childButtons[index].currentButton.elevation,
                  foregroundColor:
                      widget.childButtons[index].currentButton.foregroundColor,
                  highlightElevation: widget
                      .childButtons[index].currentButton.highlightElevation,
                  isExtended:
                      widget.childButtons[index].currentButton.isExtended,
                  shape: widget.childButtons[index].currentButton.shape,
                  child: widget.childButtons[index].currentButton.child);

              return Positioned(
                bottom: MediaQuery.of(context).size.height * 0.1,
                right: MediaQuery.of(context).size.width / 2 -
                    24.0 -
                    (MediaQuery.of(context).size.width * 0.1) +
                    (index * MediaQuery.of(context).size.width * 0.2),
                child: Row(
                  children: [
                    ScaleTransition(
                        scale: CurvedAnimation(
                          parent: _animationController,
                          curve: Interval(intervalValue, 1.0,
                              curve: Curves.linear),
                        ),
                        alignment: FractionalOffset.center,
                        child: Container()),
                    ScaleTransition(
                        scale: CurvedAnimation(
                          parent: _animationController,
                          curve: Interval(intervalValue, 1.0,
                              curve: Curves.linear),
                        ),
                        alignment: FractionalOffset.center,
                        child: childFAB)
                  ],
                ),
              );
            });

      var unicornDialWidget = Container(
        margin: null,
        height: MediaQuery.of(context).size.height * 0.3,
        width: MediaQuery.of(context).size.height * 0.5,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: childButtonsList.cast<Widget>().toList()
            ..add(Positioned(
              right: null,
              bottom: null,
              child: mainFloatingButton,
            )),
        ),
      );
      var modal = ScaleTransition(
        scale: CurvedAnimation(
          parent: _animationController,
          curve: const Interval(1.0, 1.0, curve: Curves.linear),
        ),
        alignment: FractionalOffset.center,
        child: InkWell(
          onTap: mainActionButtonOnPressed,
          child: Container(),
        ),
      );
      return widget.hasBackground
          ? Stack(
              alignment: Alignment.topCenter,
              children: [
                Positioned(right: 1.0, bottom: 1.0, child: modal),
                unicornDialWidget
              ],
            )
          : unicornDialWidget;
    }
    return mainFAB;
  }
}
