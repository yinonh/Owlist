import 'package:intl/intl.dart';

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
      'id': id,
      'listId': listId,
      'notificationIndex': notificationIndex,
      'notificationDateTime':
          DateFormat('yyyy-MM-dd HH:mm').format(notificationDateTime),
      'disabled': disabled ? 1 : 0,
    };
  }

  // Convert Map object to a Notifications object
  static Notifications fromMap(Map<String, dynamic> map) {
    return Notifications(
      id: map['id'],
      listId: map['listId'],
      notificationIndex: map['notificationIndex'],
      notificationDateTime:
          DateFormat('yyyy-MM-dd HH:mm').parse(map['notificationDateTime']),
      disabled: map['disabled'] == 1,
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
