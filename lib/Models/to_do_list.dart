import 'package:intl/intl.dart';

import '../Utils/keys.dart';

class ToDoList {
  final String id;
  final String userID;
  bool hasDeadline;
  String title;
  DateTime creationDate;
  DateTime deadline;
  int totalItems;
  int accomplishedItems;

  ToDoList({
    required this.id,
    required this.userID,
    required this.hasDeadline,
    required this.title,
    required this.creationDate,
    required this.deadline,
    required this.totalItems,
    required this.accomplishedItems,
  });

  bool get isAchieved {
    return (accomplishedItems >= totalItems && totalItems > 0) ||
        (hasDeadline && DateTime.now().isAfter(deadline));
  }

  factory ToDoList.fromMap(Map<String, dynamic> map) {
    return ToDoList(
      id: map[Keys.id],
      userID: map[Keys.userID],
      hasDeadline: map[Keys.hasDeadline] == 1 ? true : false,
      title: map[Keys.title],
      creationDate:
          DateFormat(Keys.creationDateFormat).parse(map[Keys.creationDate]),
      deadline: DateFormat(Keys.listDateFormat).parse(map[Keys.deadline]),
      totalItems: map[Keys.totalItems],
      accomplishedItems: map[Keys.accomplishedItems],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      Keys.id: id,
      Keys.userID: userID,
      Keys.title: title,
      Keys.hasDeadline: hasDeadline ? 1 : 0,
      Keys.creationDate:
          DateFormat(Keys.creationDateFormat).format(creationDate),
      Keys.deadline: DateFormat(Keys.listDateFormat).format(deadline),
      Keys.totalItems: totalItems,
      Keys.accomplishedItems: accomplishedItems,
    };
  }

  ToDoList copyWith({
    String? id,
    String? userID,
    bool? hasDeadline,
    String? title,
    DateTime? creationDate,
    DateTime? deadline,
    int? totalItems,
    int? accomplishedItems,
  }) {
    return ToDoList(
      id: id ?? this.id,
      userID: userID ?? this.userID,
      hasDeadline: hasDeadline ?? this.hasDeadline,
      title: title ?? this.title,
      creationDate: creationDate ?? this.creationDate,
      deadline: deadline ?? this.deadline,
      totalItems: totalItems ?? this.totalItems,
      accomplishedItems: accomplishedItems ?? this.accomplishedItems,
    );
  }
}
