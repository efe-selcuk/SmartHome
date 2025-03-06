import 'package:flutter/material.dart';
import 'package:smarthome/services/device_service.dart';

class ControlPanelScreen extends StatefulWidget {
  const ControlPanelScreen({super.key});

  @override
  _ControlPanelScreenState createState() => _ControlPanelScreenState();
}

class _ControlPanelScreenState extends State<ControlPanelScreen> {
  final DeviceService _deviceService = DeviceService();
  List<Map<String, dynamic>> devices = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    setState(() => isLoading = true);
    final allDevices = await _deviceService.getAllDevices();
    setState(() {
      devices = allDevices;
      isLoading = false;
    });
  }

  // Cihaz tipine göre ikon getir
  IconData _getDeviceIcon(String type) {
    switch (type.toLowerCase()) {
      case 'light':
        return Icons.lightbulb_outline;
      case 'lock':
        return Icons.lock_outline;
      case 'sensor':
        return Icons.sensors;
      case 'camera':
        return Icons.videocam_outlined;
      case 'thermostat':
        return Icons.thermostat;
      case 'tv':
        return Icons.tv;
      default:
        return Icons.devices;
    }
  }

  // Cihaz tipine göre renk getir
  Color _getDeviceColor(String type) {
    switch (type.toLowerCase()) {
      case 'light':
        return Colors.orange;
      case 'lock':
        return Colors.blue;
      case 'sensor':
        return Colors.green;
      case 'camera':
        return Colors.red;
      case 'thermostat':
        return Colors.purple;
      case 'tv':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Aktif cihaz sayısı
    final activeDevices = devices.where((d) => d['isActive'] == true).length;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Kontrol Paneli'),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadDevices,
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDevices,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hızlı Erişim Kartları
                    Text(
                      'Hızlı Erişim',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    GridView.count(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1.5,
                      children: [
                        _buildQuickAccessCard(
                          'Tüm Cihazlar',
                          Icons.devices,
                          '$activeDevices/${devices.length} Aktif',
                          Colors.blue,
                        ),
                        _buildQuickAccessCard(
                          'Güvenlik',
                          Icons.security,
                          'Aktif',
                          Colors.green,
                        ),
                        _buildQuickAccessCard(
                          'Sensörler',
                          Icons.sensors,
                          '${devices.where((d) => d['type'] == 'sensor').length} Adet',
                          Colors.orange,
                        ),
                        _buildQuickAccessCard(
                          'Oda Durumu',
                          Icons.meeting_room,
                          '${devices.map((d) => d['roomName']).toSet().length} Oda',
                          Colors.purple,
                        ),
                      ],
                    ),
                    SizedBox(height: 24),

                    // Cihazlar (Odalara göre gruplandırılmış)
                    ...devices.fold<Map<String, List<Map<String, dynamic>>>>(
                      {},
                      (map, device) {
                        if (!map.containsKey(device['roomName'])) {
                          map[device['roomName']] = [];
                        }
                        map[device['roomName']]!.add(device);
                        return map;
                      }
                    ).entries.map((entry) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            entry.key,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                        ...entry.value.map((device) => _buildDeviceCard(device)),
                      ],
                    )),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Yeni cihaz ekleme dialogu
          _showAddDeviceDialog();
        },
        backgroundColor: Theme.of(context).primaryColor,
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildQuickAccessCard(
    String title,
    IconData icon,
    String status,
    Color color,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      status,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceCard(Map<String, dynamic> device) {
    final Color deviceColor = _getDeviceColor(device['type']);
    
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Dismissible(
        key: Key(device['id']),
        background: Container(
          alignment: Alignment.centerRight,
          padding: EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.delete, color: Colors.white),
        ),
        direction: DismissDirection.endToStart,
        confirmDismiss: (direction) async {
          return await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Cihazı Sil'),
              content: Text('Bu cihazı silmek istediğinizden emin misiniz?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('İptal'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text('Sil', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );
        },
        onDismissed: (direction) async {
          await _deviceService.deleteDevice(device['roomId'], device['id']);
          setState(() {
            devices.remove(device);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Cihaz silindi')),
          );
        },
        child: ListTile(
          leading: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: deviceColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getDeviceIcon(device['type']),
              color: deviceColor,
              size: 24,
            ),
          ),
          title: Text(
            device['name'],
            style: TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            device['roomName'],
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
          trailing: Switch(
            value: device['isActive'] ?? false,
            onChanged: (value) async {
              final success = await _deviceService.updateDeviceStatus(
                device['roomId'],
                device['id'],
                value,
              );
              if (success) {
                setState(() {
                  device['isActive'] = value;
                });
              }
            },
            activeColor: deviceColor,
          ),
        ),
      ),
    );
  }

  void _showAddDeviceDialog() {
    String selectedRoom = devices.isNotEmpty ? devices.first['roomName'] : '';
    String selectedType = 'light';
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Yeni Cihaz Ekle'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Cihaz Adı',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedRoom,
                decoration: InputDecoration(
                  labelText: 'Oda',
                  border: OutlineInputBorder(),
                ),
                items: devices
                    .map((d) => d['roomName'] as String)
                    .toSet()
                    .map((room) => DropdownMenuItem<String>(
                          value: room,
                          child: Text(room),
                        ))
                    .toList(),
                onChanged: (value) {
                  selectedRoom = value!;
                },
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: InputDecoration(
                  labelText: 'Cihaz Tipi',
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(value: 'light', child: Text('Işık')),
                  DropdownMenuItem(value: 'lock', child: Text('Kilit')),
                  DropdownMenuItem(value: 'sensor', child: Text('Sensör')),
                  DropdownMenuItem(value: 'camera', child: Text('Kamera')),
                  DropdownMenuItem(value: 'thermostat', child: Text('Termostat')),
                  DropdownMenuItem(value: 'tv', child: Text('TV')),
                ],
                onChanged: (value) {
                  selectedType = value!;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lütfen cihaz adını girin')),
                );
                return;
              }

              final roomData = devices.firstWhere(
                (d) => d['roomName'] == selectedRoom,
              );

              final success = await _deviceService.addDevice(
                roomData['roomId'],
                {
                  'name': nameController.text,
                  'type': selectedType,
                  'isActive': false,
                },
              );

              if (success) {
                Navigator.pop(context);
                _loadDevices();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Cihaz eklendi')),
                );
              }
            },
            child: Text('Ekle'),
          ),
        ],
      ),
    );
  }
} 