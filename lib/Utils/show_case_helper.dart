import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';

import '../Utils/shared_preferences_helper.dart';
import '../Utils/strings.dart';

class ShowCaseHelper {
  ShowCaseHelper._();

  bool isActive = false;
  int listShowCaseSteps = 0;
  int notificationsShowCaseSteps = 0;
  int contentShowCaseSteps = 0;

  static final ShowCaseHelper instance = ShowCaseHelper._();

  Showcase customShowCase({
    required GlobalKey key,
    required String description,
    required BuildContext context,
    required Widget child,
    bool? showArrow,
    bool? disposeOnTap,
    void Function()? onTargetClick,
    ShapeBorder? targetShapeBorder,
    double? overlayOpacity,
  }) {
    return Showcase(
      key: key,
      description: description,
      descriptionAlignment: TextAlign.center,
      tooltipBackgroundColor: Theme.of(context).primaryColorLight,
      textColor: Colors.white,
      onTargetClick: onTargetClick,
      disposeOnTap: disposeOnTap,
      blurValue: 1,
      showArrow: showArrow ?? true,
      targetShapeBorder: targetShapeBorder ?? const RoundedRectangleBorder(),
      overlayOpacity: overlayOpacity ?? 0.75,
      child: child,
    );
  }

  void toggleIsActive([bool? state]) {
    if (state != null) {
      instance.isActive = state;
    } else if (instance.isActive) {
      instance.isActive = false;
    } else {
      instance.isActive = true;
    }

    instance.listShowCaseSteps = 0;
    instance.notificationsShowCaseSteps = 0;
    instance.contentShowCaseSteps = 0;
  }

  void isShowCaseDone() {
    final stepsDone = instance.listShowCaseSteps +
        instance.notificationsShowCaseSteps +
        instance.contentShowCaseSteps;
    final totalSteps =
        SharedPreferencesHelper.instance.notificationsActive ? 8 : 5;
    if (stepsDone >= totalSteps) {
      instance.isActive = false;
    }
  }

  String get homePageShowCaseDescription => Strings.homePageShowCaseDescription;

  String get singleListScreenEditListShowCaseDescription =>
      Strings.singleListScreenEditListShowCaseDescription;

  String get singleListScreenAddItemShowCaseDescription =>
      Strings.singleListScreenAddItemShowCaseDescription;

  String get notificationsShowCaseDescription =>
      Strings.notificationsShowCaseDescription;

  String get notificationsStateShowCaseDescription =>
      Strings.notificationsStateShowCaseDescription;

  String get contentShowCaseDescription => Strings.contentShowCaseDescription;

  void startShowCaseBeginning(
      BuildContext context, List<GlobalKey> homePageShowCaseList) {
    if (instance.isActive) {
      ShowCaseWidget.of(context).startShowCase(homePageShowCaseList);
    }
  }

  void startShowCaseListAdded(
      BuildContext context, List<GlobalKey> singleListShowCaseList) {
    if (instance.isActive &&
        instance.listShowCaseSteps < singleListShowCaseList.length) {
      ShowCaseWidget.of(context).startShowCase(
        singleListShowCaseList.sublist(instance.listShowCaseSteps),
      );
    }
  }

  void startShowCaseNotifications(
      BuildContext context, List<GlobalKey> notificationsShowCaseList) {
    if (instance.isActive &&
        instance.notificationsShowCaseSteps <
            notificationsShowCaseList.length) {
      ShowCaseWidget.of(context).startShowCase(
        notificationsShowCaseList.sublist(instance.notificationsShowCaseSteps),
      );
    }
  }

  void startShowCaseContentAdded(
      BuildContext context, List<GlobalKey> contentShowCaseList) {
    if (instance.isActive &&
        instance.contentShowCaseSteps < contentShowCaseList.length) {
      ShowCaseWidget.of(context).startShowCase(contentShowCaseList);
    }
  }
}
