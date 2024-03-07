import 'package:day_night_time_picker/day_night_time_picker.dart';

class NotificationTime extends Time {
  NotificationTime({required super.hour, required super.minute});

  // Method to convert Time object to a single integer value
  int toInt() {
    return hour * 10000 + minute * 100;
  }

  Duration toDuration() {
    return Duration(hours: hour, minutes: minute);
  }

  // Static method to create a Time object from an integer value
  static NotificationTime fromInt(int value) {
    int hour = value ~/ 10000;
    int minute = (value % 10000) ~/ 100;
    return NotificationTime(hour: hour, minute: minute);
  }
}
