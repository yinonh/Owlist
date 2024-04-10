import 'package:intl/intl.dart';

import '../Utils/keys.dart';

class Notifications {
  String id;
  String listId;
  int notificationIndex;
  DateTime notificationDateTime;
  bool disabled;

  Notifications({
    required this.id,
    required this.listId,
    required this.notificationIndex,
    required this.notificationDateTime,
    required this.disabled,
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
    );
  }

  // CopyWith function to create a copy of Notifications with updated values
  Notifications copyWith({
    String? id,
    String? listId,
    int? notificationIndex,
    DateTime? notificationDateTime,
    bool? disabled,
  }) {
    return Notifications(
      id: id ?? this.id,
      listId: listId ?? this.listId,
      notificationIndex: notificationIndex ?? this.notificationIndex,
      notificationDateTime: notificationDateTime ?? this.notificationDateTime,
      disabled: disabled ?? this.disabled,
    );
  }
}
