import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

import '../Widgets/custom_floationg_action_button.dart';

class UnicornButton {
  final FloatingActionButton currentButton;

  UnicornButton({
    required this.currentButton,
  }) : assert(currentButton != null);

  Widget build(BuildContext context) {
    return this.currentButton;
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

  UnicornDialer(
      {required this.parentButton,
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

  _UnicornDialer createState() => _UnicornDialer();
}

class _UnicornDialer extends State<UnicornDialer>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _parentController;

  bool isOpen = false;

  @override
  void initState() {
    this._animationController = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: widget.animationDuration));

    this._parentController = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: widget.mainAnimationDuration));

    super.initState();
  }

  @override
  dispose() {
    this._animationController.dispose();
    this._parentController.dispose();
    super.dispose();
  }

  void mainActionButtonOnPressed() {
    if (this._animationController.isDismissed) {
      this._animationController.forward();
    } else {
      this._animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    this._animationController.reverse();

    var hasChildButtons =
        widget.childButtons != null && widget.childButtons.length > 0;

    if (!this._parentController.isAnimating) {
      if (this._parentController.isCompleted) {
        this._parentController.forward().then((s) {
          this._parentController.reverse().then((e) {
            this._parentController.forward();
          });
        });
      }
      if (this._parentController.isDismissed) {
        this._parentController.reverse().then((s) {
          this._parentController.forward();
        });
      }
    }

    var mainFAB = AnimatedBuilder(
      animation: this._parentController,
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
                    animation: this._animationController,
                    builder: (BuildContext context, Widget? child) {
                      return Transform(
                        transform: Matrix4.rotationZ(
                            this._animationController.value * 0.8),
                        alignment: FractionalOffset.center,
                        child: Icon(
                          this._animationController.isDismissed
                              ? widget.parentButton.icon
                              : widget.finalButtonIcon == null
                                  ? Icons.close
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
        animation: this._animationController,
        builder: (BuildContext context, Widget? child) {
          // Change Widget to Widget?
          return Transform.rotate(
            angle: this._animationController.value * 0.8,
            child: mainFAB,
          );
        },
      );

      var childButtonsList = widget.childButtons == null ||
              widget.childButtons.length == 0
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

                    this._animationController.reverse();
                  },
                  child: widget.childButtons[index].currentButton.child,
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
                  shape: widget.childButtons[index].currentButton.shape);

              return Positioned(
                right:
                    widget.childButtons[index].currentButton.mini ? 4.0 : 0.0,
                bottom: ((widget.childButtons.length - index) * 55.0) + 15,
                child: Row(
                  children: [
                    ScaleTransition(
                        scale: CurvedAnimation(
                          parent: this._animationController,
                          curve: Interval(intervalValue, 1.0,
                              curve: Curves.linear),
                        ),
                        alignment: FractionalOffset.center,
                        child: Container()),
                    ScaleTransition(
                        scale: CurvedAnimation(
                          parent: this._animationController,
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
        height: double.infinity,
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
          parent: this._animationController,
          curve: Interval(1.0, 1.0, curve: Curves.linear),
        ),
        alignment: FractionalOffset.center,
        child: InkWell(
          onTap: mainActionButtonOnPressed,
          child: Container(),
        ),
      );
      return widget.hasBackground
          ? Container(
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  Positioned(right: 1.0, bottom: 1.0, child: modal),
                  unicornDialWidget
                ],
              ),
            )
          : unicornDialWidget;
    }
    return mainFAB;
  }
}
