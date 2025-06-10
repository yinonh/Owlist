import 'package:intl/intl.dart';

import '../Utils/keys.dart';

class Notifications {
  String id;
  String listId;
  int notificationIndex;
  DateTime notificationDateTime;
  bool disabled;
  String? notificationType;
  String? periodicInterval;

  Notifications({
    required this.id,
    required this.listId,
    required this.notificationIndex,
    required this.notificationDateTime,
    required this.disabled,
    this.notificationType,
    this.periodicInterval,
  });

  // Convert Notifications object to a Map object
  Map<String, dynamic> toMap() {
    return {
      Keys.id: id,
      Keys.listId: listId,
      Keys.notificationIndex: notificationIndex,
      Keys.notificationDateTime: DateFormat(Keys.notificationDateTimeFormat)
          .format(notificationDateTime),
      Keys.disabled: disabled ? 1 : 0,
      Keys.notificationType: notificationType,
      Keys.periodicInterval: periodicInterval,
    };
  }

  // Convert Map object to a Notifications object
  static Notifications fromMap(Map<String, dynamic> map) {
    return Notifications(
      id: map[Keys.id],
      listId: map[Keys.listId],
      notificationIndex: map[Keys.notificationIndex],
      notificationDateTime: DateFormat(Keys.notificationDateTimeFormat)
          .parse(map[Keys.notificationDateTime]),
      disabled: map[Keys.disabled] == 1,
      notificationType: map[Keys.notificationType],
      periodicInterval: map[Keys.periodicInterval],
    );
  }

  // CopyWith function to create a copy of Notifications with updated values
  Notifications copyWith({
    String? id,
    String? listId,
    int? notificationIndex,
    DateTime? notificationDateTime,
    bool? disabled,
    String? notificationType,
    String? periodicInterval,
  }) {
    return Notifications(
      id: id ?? this.id,
      listId: listId ?? this.listId,
      notificationIndex: notificationIndex ?? this.notificationIndex,
      notificationDateTime: notificationDateTime ?? this.notificationDateTime,
      disabled: disabled ?? this.disabled,
      notificationType: notificationType ?? this.notificationType,
      periodicInterval: periodicInterval ?? this.periodicInterval,
    );
  }
}
