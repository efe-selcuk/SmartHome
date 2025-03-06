import 'package:flutter/material.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> notifications = [
    {
      'title': 'Güvenlik Uyarısı',
      'message': 'Ön kapı açıldı',
      'time': '10:30',
      'type': 'security',
      'isRead': false,
    },
    {
      'title': 'Cihaz Durumu',
      'message': 'Salon ışıkları açık kaldı',
      'time': '09:15',
      'type': 'device',
      'isRead': true,
    },
    {
      'title': 'Sistem Bildirimi',
      'message': 'Yazılım güncellemesi mevcut',
      'time': 'Dün',
      'type': 'system',
      'isRead': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bildirimler'),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          IconButton(
            icon: Icon(Icons.done_all),
            onPressed: () {
              setState(() {
                for (var notification in notifications) {
                  notification['isRead'] = true;
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Bildirim Ayarları
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.notifications_active,
                  color: Theme.of(context).primaryColor,
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Bildirim Ayarları',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Switch(
                  value: true,
                  onChanged: (value) {
                    // Bildirim ayarlarını güncelle
                  },
                  activeColor: Theme.of(context).primaryColor,
                ),
              ],
            ),
          ),
          
          // Bildirim Listesi
          Expanded(
            child: notifications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_off_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Bildirim bulunmuyor',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      return Dismissible(
                        key: Key(index.toString()),
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: EdgeInsets.only(right: 20),
                          child: Icon(
                            Icons.delete,
                            color: Colors.white,
                          ),
                        ),
                        direction: DismissDirection.endToStart,
                        onDismissed: (direction) {
                          setState(() {
                            notifications.removeAt(index);
                          });
                        },
                        child: _buildNotificationCard(notification),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    IconData getNotificationIcon() {
      switch (notification['type']) {
        case 'security':
          return Icons.security;
        case 'device':
          return Icons.devices;
        case 'system':
          return Icons.system_update;
        default:
          return Icons.notifications;
      }
    }

    Color getNotificationColor() {
      switch (notification['type']) {
        case 'security':
          return Colors.red;
        case 'device':
          return Colors.orange;
        case 'system':
          return Colors.blue;
        default:
          return Colors.grey;
      }
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: notification['isRead'] ? Colors.white : Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: getNotificationColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            getNotificationIcon(),
            color: getNotificationColor(),
            size: 24,
          ),
        ),
        title: Text(
          notification['title'],
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text(
              notification['message'],
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 4),
            Text(
              notification['time'],
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        onTap: () {
          setState(() {
            notification['isRead'] = true;
          });
        },
      ),
    );
  }
} 