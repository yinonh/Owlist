import 'package:flutter/cupertino.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:flutter/material.dart';

class ShowCaseHelper {
  ShowCaseHelper._();

  final addListKey = GlobalKey();
  final editList = GlobalKey();
  final addItemKey = GlobalKey();
  final addContentKey = GlobalKey();
  final notificationsKey = GlobalKey();
  final notificationsStatusKey = GlobalKey();
  bool isActive = false;
  int listShowCaseSteps = 0;
  int contentShowCaseSteps = 0;

  static final ShowCaseHelper instance = ShowCaseHelper._();

  Showcase customShowCase(
      {required GlobalKey key,
      required String description,
      required BuildContext context,
      required Widget child,
      bool? showArrow,
      ShapeBorder? targetShapeBorder,
      double? overlayOpacity}) {
    return Showcase(
      key: key,
      description: ShowCaseHelper.instance.addListDescription,
      descriptionAlignment: TextAlign.center,
      tooltipBackgroundColor: Theme.of(context).primaryColorLight,
      textColor: Colors.white,
      blurValue: 1,
      showArrow: showArrow ?? true,
      targetShapeBorder: targetShapeBorder ?? const RoundedRectangleBorder(),
      overlayOpacity: overlayOpacity ?? 0.75,
      child: child,
    );
  }

  void toggleIsActive() {
    if (instance.isActive) {
      instance.isActive = false;
    } else {
      instance.isActive = true;
    }
    instance.listShowCaseSteps = 0;
    instance.contentShowCaseSteps = 0;
  }

  String get addListDescription =>
      "To add a new list, click on the + button, enter a title, adjust the deadline with the date icon, then save.";

  String get editListDescription =>
      "To edit the list title, deadline and reorder the list items, you can press here and don't forget to save the changes.";

  String get addItemDescription =>
      "You can add a new item to the list or add list notifications, click on the + button.";

  String get notificationsDescription =>
      "Here, you can view all notifications for this list. You can add up to four notifications for the list, unless it's already archived. You can edit, delete, and add new notifications as needed.";

  void startShowCaseBeginning(BuildContext context) {
    ShowCaseWidget.of(context).startShowCase([addListKey]);
  }

  void startShowCaseListAdded(BuildContext context) {
    ShowCaseWidget.of(context).startShowCase(
      [editList, addItemKey],
    );
  }

  void startShowCaseNotifications(BuildContext context) {
    ShowCaseWidget.of(context).startShowCase(
      [notificationsKey, notificationsStatusKey],
    );
  }

  void startShowCaseContentAdded(BuildContext context) {
    ShowCaseWidget.of(context).startShowCase([addContentKey]);
  }
}
