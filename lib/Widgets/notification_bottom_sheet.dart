import 'package:flutter/material.dart';

class NotificationBottomSheet extends StatefulWidget {
  @override
  _NotificationBottomSheetState createState() =>
      _NotificationBottomSheetState();
}

class _NotificationBottomSheetState extends State<NotificationBottomSheet> {
  late TextEditingController _oneDayController;
  late TextEditingController _oneWeekController;
  late TextEditingController _twoWeeksController;
  late TextEditingController _oneMonthController;

  @override
  void initState() {
    super.initState();
    _oneDayController = TextEditingController();
    _oneWeekController = TextEditingController();
    _twoWeeksController = TextEditingController();
    _oneMonthController = TextEditingController();
  }

  @override
  void dispose() {
    _oneDayController.dispose();
    _oneWeekController.dispose();
    _twoWeeksController.dispose();
    _oneMonthController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Notifications',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            SizedBox(height: 16),
            _buildNotificationItem(context, "One day before deadline",
                Icons.notifications_active, Icons.edit, _oneDayController),
            _buildNotificationItem(context, "One week before deadline",
                Icons.notifications, Icons.edit, _oneWeekController),
            _buildNotificationItem(context, "Two weeks before deadline",
                Icons.notifications, Icons.edit, _twoWeeksController),
            _buildNotificationItem(context, "One month before deadline",
                Icons.notifications, Icons.edit, _oneMonthController),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(BuildContext context, String title,
      IconData icon, IconData trailingIcon, TextEditingController controller) {
    return ListTile(
      leading: Icon(
        icon,
        color: icon == Icons.notifications_active ? Colors.purple : Colors.grey,
      ),
      title: Text(title),
      trailing: IconButton(
        icon: Icon(trailingIcon),
        onPressed: () => _openDatePicker(context, controller),
      ),
    );
  }

  Future<void> _openDatePicker(
      BuildContext context, TextEditingController controller) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(Duration(days: 365)),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (pickedDate != null) {
      controller.text =
          pickedDate.toString(); // You can format the date as needed
    }
  }
}
