import 'package:flutter/material.dart';
import 'package:smarthome/services/device_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ControlPanelScreen extends StatefulWidget {
  const ControlPanelScreen({super.key});

  @override
  _ControlPanelScreenState createState() => _ControlPanelScreenState();
}

class _ControlPanelScreenState extends State<ControlPanelScreen> with SingleTickerProviderStateMixin {
  final DeviceService _deviceService = DeviceService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> devices = [];
  List<Map<String, dynamic>> filteredDevices = [];
  bool isLoading = true;

  // Filtreleme ve gruplama için
  String selectedRoomFilter = 'Tüm Odalar';
  String selectedTypeFilter = 'Tüm Cihazlar';
  late TabController _tabController;
  List<String> roomsList = ['Tüm Odalar'];
  List<String> deviceTypes = ['Tüm Cihazlar', 'Işık', 'Kilit', 'Sensör', 'Kamera', 'Termostat', 'TV'];
  
  Map<String, String> typeTitles = {
    'light': 'Işık',
    'lock': 'Kilit',
    'sensor': 'Sensör',
    'camera': 'Kamera',
    'thermostat': 'Termostat',
    'tv': 'TV',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadDevices();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDevices() async {
    setState(() => isLoading = true);
    try {
      final allDevices = await _deviceService.getAllDevices();
      
      // Oda listesini oluştur
      Set<String> roomsSet = {'Tüm Odalar'};
      for (var device in allDevices) {
        roomsSet.add(device['roomName']);
      }
      
      setState(() {
        devices = allDevices;
        filteredDevices = allDevices;
        roomsList = roomsSet.toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showErrorSnackbar('Cihazlar yüklenirken bir hata oluştu');
    }
  }

  void _filterDevices() {
    setState(() {
      filteredDevices = devices.where((device) {
        bool roomMatch = selectedRoomFilter == 'Tüm Odalar' || device['roomName'] == selectedRoomFilter;
        bool typeMatch = selectedTypeFilter == 'Tüm Cihazlar' ||
            typeTitles[device['type']] == selectedTypeFilter;
        return roomMatch && typeMatch;
      }).toList();
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

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Aktif cihaz sayısı
    final activeDevices = devices.where((d) => d['isActive'] == true).length;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Kontrol Paneli'),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadDevices,
            tooltip: 'Yenile',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(100),
          child: Container(
            color: Theme.of(context).primaryColor,
            child: Column(
              children: [
                TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.white,
                  indicatorWeight: 3,
                  tabs: [
                    Tab(
                      icon: Icon(Icons.grid_view_rounded),
                      text: 'Hızlı Erişim',
                    ),
                    Tab(
                      icon: Icon(Icons.devices),
                      text: 'Tüm Cihazlar',
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildFilterDropdown(
                          'Oda',
                          selectedRoomFilter,
                          roomsList,
                          (value) {
                            setState(() {
                              selectedRoomFilter = value!;
                            });
                            _filterDevices();
                          },
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: _buildFilterDropdown(
                          'Cihaz Tipi',
                          selectedTypeFilter,
                          deviceTypes,
                          (value) {
                            setState(() {
                              selectedTypeFilter = value!;
                            });
                            _filterDevices();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDevices,
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Hızlı Erişim Sekmesi
                  _buildQuickAccessTab(activeDevices),
                  
                  // Cihazlar Sekmesi
                  _buildDevicesTab(),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showAddDeviceDialog();
        },
        backgroundColor: Theme.of(context).primaryColor,
        icon: Icon(Icons.add),
        label: Text('Cihaz Ekle'),
      ),
    );
  }

  Widget _buildFilterDropdown(
    String label,
    String value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: Theme.of(context).primaryColor,
          style: TextStyle(color: Colors.white),
          icon: Icon(Icons.arrow_drop_down, color: Colors.white),
          isExpanded: true,
          hint: Text(label, style: TextStyle(color: Colors.white70)),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item, style: TextStyle(color: Colors.white)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildQuickAccessTab(int activeDevices) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Özet Bilgiler
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Toplam Cihaz',
                  '${devices.length}',
                  Icons.devices,
                  Theme.of(context).primaryColor,
                ),
                _buildStatItem(
                  'Aktif Cihaz',
                  '$activeDevices',
                  Icons.power,
                  Colors.green,
                ),
                _buildStatItem(
                  'Oda Sayısı',
                  '${devices.map((d) => d['roomName']).toSet().length}',
                  Icons.meeting_room,
                  Colors.orange,
                ),
              ],
            ),
          ),
          SizedBox(height: 24),

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
                () {
                  setState(() {
                    selectedRoomFilter = 'Tüm Odalar';
                    selectedTypeFilter = 'Tüm Cihazlar';
                    _filterDevices();
                    _tabController.animateTo(1);
                  });
                },
              ),
              _buildQuickAccessCard(
                'Işıklar',
                Icons.lightbulb_outline,
                '${devices.where((d) => d['type'] == 'light').length} Adet',
                Colors.orange,
                () {
                  setState(() {
                    selectedRoomFilter = 'Tüm Odalar';
                    selectedTypeFilter = 'Işık';
                    _filterDevices();
                    _tabController.animateTo(1);
                  });
                },
              ),
              _buildQuickAccessCard(
                'Güvenlik',
                Icons.security,
                '${devices.where((d) => d['type'] == 'lock' || d['type'] == 'camera').length} Adet',
                Colors.red,
                () {
                  setState(() {
                    selectedRoomFilter = 'Tüm Odalar';
                    selectedTypeFilter = 'Kilit';
                    _filterDevices();
                    _tabController.animateTo(1);
                  });
                },
              ),
              _buildQuickAccessCard(
                'Sensörler',
                Icons.sensors,
                '${devices.where((d) => d['type'] == 'sensor').length} Adet',
                Colors.green,
                () {
                  setState(() {
                    selectedRoomFilter = 'Tüm Odalar';
                    selectedTypeFilter = 'Sensör';
                    _filterDevices();
                    _tabController.animateTo(1);
                  });
                },
              ),
            ],
          ),
          
          SizedBox(height: 24),
          
          // Hızlı kontrol bölümü
          Text(
            'Hızlı Kontroller',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          
          // Odaya göre hızlı kontroller
          ...roomsList.where((room) => room != 'Tüm Odalar').map((room) {
            final roomDevices = devices.where((d) => d['roomName'] == room).toList();
            final activeCount = roomDevices.where((d) => d['isActive'] == true).length;
            
            return _buildRoomQuickControlCard(
              room, 
              roomDevices, 
              activeCount,
              () {
                setState(() {
                  selectedRoomFilter = room;
                  selectedTypeFilter = 'Tüm Cihazlar';
                  _filterDevices();
                  _tabController.animateTo(1);
                });
              }
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: color,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildRoomQuickControlCard(
    String roomName, 
    List<Map<String, dynamic>> roomDevices,
    int activeCount,
    VoidCallback onTap,
  ) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.meeting_room,
                      color: Theme.of(context).primaryColor,
                    ),
                    SizedBox(width: 8),
                    Text(
                      roomName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: onTap,
                  child: Text('Detaylar'),
                ),
              ],
            ),
            Divider(),
            Text(
              '$activeCount/${roomDevices.length} cihaz aktif',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: roomDevices.map((device) {
                  Color deviceColor = _getDeviceColor(device['type']);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: _buildQuickDeviceControl(device, deviceColor),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickDeviceControl(Map<String, dynamic> device, Color color) {
    return GestureDetector(
      onTap: () async {
        final success = await _deviceService.updateDeviceStatus(
          device['roomId'],
          device['id'],
          !device['isActive'],
        );
        if (success) {
          setState(() {
            device['isActive'] = !device['isActive'];
          });
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: device['isActive'] ? color : Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              _getDeviceIcon(device['type']),
              color: device['isActive'] ? Colors.white : Colors.grey[700],
              size: 18,
            ),
            SizedBox(width: 8),
            Text(
              device['name'],
              style: TextStyle(
                color: device['isActive'] ? Colors.white : Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDevicesTab() {
    return filteredDevices.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.devices_other,
                  size: 64,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 16),
                Text(
                  'Hiç cihaz bulunamadı',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    _showAddDeviceDialog();
                  },
                  icon: Icon(Icons.add),
                  label: Text('Cihaz Ekle'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          )
        : ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: filteredDevices.length,
            itemBuilder: (context, index) {
              return _buildDeviceCard(filteredDevices[index]);
            },
          );
  }

  Widget _buildQuickAccessCard(
    String title,
    IconData icon,
    String status,
    Color color,
    VoidCallback onTap,
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
          onTap: onTap,
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
    final bool isActive = device['isActive'] ?? false;
    
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Dismissible(
        key: Key(device['id']),
        background: Container(
          alignment: Alignment.centerRight,
          padding: EdgeInsets.only(right: 20),
          color: Colors.red,
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
            filteredDevices.remove(device);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cihaz silindi'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        child: ExpansionTile(
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
            '${device['roomName']} · ${typeTitles[device['type']] ?? device['type']}',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
          trailing: Switch.adaptive(
            value: isActive,
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
          children: [
            // Cihaz detay bilgileri
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Durum:',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Chip(
                        label: Text(
                          isActive ? 'Aktif' : 'Pasif',
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                        backgroundColor: isActive ? Colors.green : Colors.grey,
                        padding: EdgeInsets.symmetric(horizontal: 4),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        icon: Icon(Icons.edit),
                        label: Text('Düzenle'),
                        onPressed: () {
                          _showEditDeviceDialog(device);
                        },
                      ),
                      TextButton.icon(
                        icon: Icon(Icons.delete),
                        label: Text('Sil'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
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
                          
                          if (confirm == true) {
                            await _deviceService.deleteDevice(device['roomId'], device['id']);
                            setState(() {
                              devices.remove(device);
                              filteredDevices.remove(device);
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Cihaz silindi'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddDeviceDialog() {
    String? selectedRoom = roomsList.length > 1 ? roomsList[1] : null;
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
                  prefixIcon: Icon(Icons.device_hub),
                ),
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedRoom,
                decoration: InputDecoration(
                  labelText: 'Oda',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.meeting_room),
                  hintText: 'Oda seçin',
                ),
                items: roomsList
                    .where((room) => room != 'Tüm Odalar')
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
                  prefixIcon: Icon(Icons.category),
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
                  SnackBar(
                    content: Text('Lütfen cihaz adını girin'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }

              if (selectedRoom == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Lütfen bir oda seçin'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }

              final roomData = devices.firstWhere(
                (d) => d['roomName'] == selectedRoom,
                orElse: () => {} as Map<String, dynamic>,
              );

              if (roomData.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Seçilen oda bulunamadı'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }

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
                  SnackBar(
                    content: Text('Cihaz eklendi'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Cihaz eklenirken bir hata oluştu'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
            ),
            child: Text('Ekle'),
          ),
        ],
      ),
    );
  }

  void _showEditDeviceDialog(Map<String, dynamic> device) {
    String selectedType = device['type'];
    final TextEditingController nameController = TextEditingController(text: device['name']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cihazı Düzenle'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Cihaz Adı',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.device_hub),
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Oda: ${device['roomName']}',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: InputDecoration(
                  labelText: 'Cihaz Tipi',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
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
                  SnackBar(
                    content: Text('Lütfen cihaz adını girin'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }

              try {
                // Firestore'da cihazı güncelle (updateDevice metodunu DeviceService'e eklemeniz gerekecek)
                await _firestore
                    .collection('rooms')
                    .doc(device['roomId'])
                    .collection('devices')
                    .doc(device['id'])
                    .update({
                  'name': nameController.text,
                  'type': selectedType,
                });

                // Yerel listeyi güncelle
                setState(() {
                  device['name'] = nameController.text;
                  device['type'] = selectedType;
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Cihaz güncellendi'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Cihaz güncellenirken bir hata oluştu'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
            ),
            child: Text('Güncelle'),
          ),
        ],
      ),
    );
  }
} 