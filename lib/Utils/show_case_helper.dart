import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';

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
      description: ShowCaseHelper.instance.addListDescription,
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

  void toggleIsActive() {
    if (instance.isActive) {
      instance.isActive = false;
    } else {
      instance.isActive = true;
    }

    instance.listShowCaseSteps = 0;
    instance.notificationsShowCaseSteps = 0;
    instance.contentShowCaseSteps = 0;
    print("#######${instance.listShowCaseSteps}");
  }

  void isShowCaseDone() {
    final stepsDone = instance.listShowCaseSteps +
        instance.notificationsShowCaseSteps +
        instance.contentShowCaseSteps;
    const totalSteps = 8;
    print("########## $stepsDone");
    if (stepsDone == totalSteps) {
      instance.isActive = false;
    }
  }

  String get addListDescription =>
      "To add a new list, click on the + button, enter a title, adjust the deadline with the date icon, then save.";

  String get editListDescription =>
      "To edit the list title, deadline and reorder the list items, you can press here and don't forget to save the changes.";

  String get addItemDescription =>
      "You can add a new item to the list or add list notifications, click on the + button.";

  String get notificationsDescription =>
      "Here, you can view all notifications for this list. You can add up to four notifications for the list, unless it's already archived. You can edit, delete, and add new notifications as needed.";

  String get contentDescription =>
      "Here you can add text, links and phone numbers content to your items.";

  void startShowCaseBeginning(BuildContext context) {
    ShowCaseWidget.of(context).startShowCase([addListKey]);
  }

  void startShowCaseListAdded(BuildContext context) {
    final listAddedShowCaseList = [editList, addItemKey];
    print("#####${instance.listShowCaseSteps}");
    if (instance.listShowCaseSteps < listAddedShowCaseList.length) {
      ShowCaseWidget.of(context).startShowCase(
        listAddedShowCaseList.sublist(instance.listShowCaseSteps),
      );
    }
  }

  void startShowCaseNotifications(BuildContext context) {
    final notificationsShowCaseList = [
      notificationsKey,
      notificationsStatusKey
    ];
    if (instance.notificationsShowCaseSteps <
        notificationsShowCaseList.length) {
      ShowCaseWidget.of(context).startShowCase(
        notificationsShowCaseList.sublist(instance.notificationsShowCaseSteps),
      );
    }
  }

  void startShowCaseContentAdded(BuildContext context) {
    final contentShowCaseList = [addContentKey];
    if (instance.contentShowCaseSteps < contentShowCaseList.length) {
      ShowCaseWidget.of(context).startShowCase(contentShowCaseList);
    }
  }
}
