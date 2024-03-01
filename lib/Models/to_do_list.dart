import 'package:intl/intl.dart';

class ToDoList {
  final String id;
  final String userID;
  // final int notificationIndex;
  bool hasDeadline;
  String title;
  DateTime creationDate;
  DateTime deadline;
  int totalItems;
  int accomplishedItems;

  ToDoList({
    required this.id,
    required this.userID,
    // required this.notificationIndex,
    required this.hasDeadline,
    required this.title,
    required this.creationDate,
    required this.deadline,
    required this.totalItems,
    required this.accomplishedItems,
  });

  // Method to convert a ToDoList object to a Map
  Map<String, dynamic> toMap() {
    return {
      'userID': userID,
      'title': title,
      // 'notificationIndex': notificationIndex,
      'hasDeadline': hasDeadline ? 1 : 0,
      'creationDate': DateFormat('yyyy-MM-dd').format(creationDate),
      'deadline': DateFormat('yyyy-MM-dd').format(deadline),
      'totalItems': totalItems,
      'accomplishedItems': accomplishedItems,
    };
  }
}
