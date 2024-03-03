import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:to_do/Providers/notification_provider.dart';

import '../Models/notification.dart';

class NotificationBottomSheet extends StatefulWidget {
  final String listId;

  const NotificationBottomSheet({required this.listId, Key? key})
      : super(key: key);

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
    final provider = Provider.of<NotificationProvider>(context);
    return FutureBuilder<List<Notifications>>(
      future: provider.getNotificationsByListId(widget.listId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator(); // Placeholder while loading
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (snapshot.hasData && snapshot.data!.isEmpty) {
          return Text('No notifications found');
        } else {
          return ListView.builder(
            shrinkWrap: true,
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final notification = snapshot.data![index];
              return _buildNotificationItem(context, notification);
            },
          );
        }
      },
    );
  }

  Widget _buildNotificationItem(
      BuildContext context, Notifications notification) {
    final title = 'Notification ${notification.notificationIndex}';
    final trailingIcon = Icons.edit;
    final controller = TextEditingController(
      text: DateFormat('yyyy-MM-dd HH:mm')
          .format(notification.notificationDateTime),
    );

    return ListTile(
      leading: Icon(
        notification.disabled
            ? Icons.notifications_off
            : Icons.notifications_active,
        color: notification.disabled ? Colors.grey : Colors.purple,
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
      controller.text = DateFormat('yyyy-MM-dd').format(pickedDate);
    }
  }
}
