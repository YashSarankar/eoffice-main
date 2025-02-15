import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});
  static const route = '/notification';

  @override
  Widget build(BuildContext context) {
    final messageData = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: ListTile(
                title: Text(messageData?['title'] ?? 'No Title'),
                subtitle: Text(messageData?['body'] ?? 'No Body'),
              ),
            ),
            const SizedBox(height: 16),
            Text('Data: ${messageData?['data'] ?? 'No Data'}'),
          ],
        ),
      ),
    );
  }
}
