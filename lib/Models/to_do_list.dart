import 'package:intl/intl.dart';

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
      id: map['id'],
      userID: map['userID'],
      hasDeadline: map['hasDeadline'] == 1 ? true : false,
      title: map['title'],
      creationDate: DateFormat('yyyy-MM-dd').parse(map['creationDate']),
      deadline: DateFormat('yyyy-MM-dd').parse(map['deadline']),
      totalItems: map['totalItems'],
      accomplishedItems: map['accomplishedItems'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userID': userID,
      'title': title,
      'hasDeadline': hasDeadline ? 1 : 0,
      'creationDate': DateFormat('yyyy-MM-dd').format(creationDate),
      'deadline': DateFormat('yyyy-MM-dd').format(deadline),
      'totalItems': totalItems,
      'accomplishedItems': accomplishedItems,
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
