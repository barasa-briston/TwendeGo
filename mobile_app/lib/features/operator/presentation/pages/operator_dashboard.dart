import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/dio_client.dart';
import '../forms/vehicle_form.dart';
import '../forms/schedule_form.dart';

class OperatorDashboard extends StatefulWidget {
  const OperatorDashboard({super.key});

  @override
  State<OperatorDashboard> createState() => _OperatorDashboardState();
}

class _OperatorDashboardState extends State<OperatorDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _api = ApiClient();

  List<Map<String, dynamic>> _vehicles = [];
  List<Map<String, dynamic>> _schedules = [];
  List<Map<String, dynamic>> _manifest = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      final vehiclesRes = await _api.dio.get('/operator/vehicles/');
      final schedulesRes = await _api.dio.get('/operator/schedules/');
      setState(() {
        _vehicles = List<Map<String, dynamic>>.from(vehiclesRes.data);
        _schedules = List<Map<String, dynamic>>.from(schedulesRes.data);
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _showVehicleForm([Map<String, dynamic>? data]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => VehicleForm(initialData: data, onSuccess: _loadAllData),
    );
  }

  void _showScheduleForm([Map<String, dynamic>? data]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => ScheduleForm(initialData: data, onSuccess: _loadAllData),
    );
  }

  Future<void> _deleteVehicle(String id) async {
    await _api.dio.delete('/operator/vehicles/$id/');
    _loadAllData();
  }

  Future<void> _deleteSchedule(String id) async {
    await _api.dio.delete('/operator/schedules/$id/');
    _loadAllData();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Operator Dashboard'),
        actions: [
          IconButton(onPressed: _loadAllData, icon: const Icon(Icons.refresh), tooltip: 'Refresh'),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.directions_bus), text: 'Vehicles'),
            Tab(icon: Icon(Icons.schedule), text: 'Schedules'),
            Tab(icon: Icon(Icons.list_alt), text: 'Manifest'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildVehiclesTab(isWide),
                _buildSchedulesTab(isWide),
                _buildManifestTab(),
              ],
            ),
    );
  }

  Widget _buildVehiclesTab(bool isWide) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${_vehicles.length} Vehicle(s) registered', style: const TextStyle(fontWeight: FontWeight.w600)),
              ElevatedButton.icon(
                onPressed: _showVehicleForm,
                icon: const Icon(Icons.add),
                label: const Text('Add Vehicle'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _vehicles.isEmpty
              ? const Center(child: Text('No vehicles yet. Add your first vehicle.'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _vehicles.length,
                  itemBuilder: (context, index) {
                    final v = _vehicles[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          child: const Icon(Icons.directions_bus, color: AppColors.primary),
                        ),
                        title: Text(v['plate_number'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${v['vehicle_type']} • ${v['seat_capacity']} seats'),
                        trailing: PopupMenuButton<String>(
                          onSelected: (val) {
                            if (val == 'edit') _showVehicleForm(v);
                            if (val == 'delete') _deleteVehicle(v['id']);
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('Edit')),
                            PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSchedulesTab(bool isWide) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${_schedules.length} Schedule(s)', style: const TextStyle(fontWeight: FontWeight.w600)),
              ElevatedButton.icon(
                onPressed: _showScheduleForm,
                icon: const Icon(Icons.add),
                label: const Text('Add Schedule'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _schedules.isEmpty
              ? const Center(child: Text('No schedules yet. Add your first trip schedule.'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _schedules.length,
                  itemBuilder: (context, index) {
                    final s = _schedules[index];
                    final route = s['route'] as Map<String, dynamic>?;
                    final vehicle = s['vehicle'] as Map<String, dynamic>?;
                    final departure = s['departure_datetime'] != null
                        ? DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(s['departure_datetime']))
                        : 'N/A';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.secondary.withOpacity(0.1),
                          child: const Icon(Icons.departure_board, color: AppColors.secondary),
                        ),
                        title: Text(
                          route != null ? '${route['origin']} → ${route['destination']}' : 'Unknown Route',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('$departure\n${vehicle?['plate_number'] ?? 'No vehicle'} • KES ${s['fare']}'),
                        isThreeLine: true,
                        trailing: PopupMenuButton<String>(
                          onSelected: (val) {
                            if (val == 'edit') _showScheduleForm(s);
                            if (val == 'delete') _deleteSchedule(s['id']);
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('Edit')),
                            PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildManifestTab() {
    // Show bookings from the schedules with today's date
    final today = DateFormat('dd MMM yyyy').format(DateTime.now());
    final todaySchedules = _schedules.where((s) {
      if (s['departure_datetime'] == null) return false;
      final depDate = DateFormat('dd MMM yyyy').format(DateTime.parse(s['departure_datetime']));
      return depDate == today;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Today's Trips — $today",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.print),
                label: const Text('Print Manifest'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (todaySchedules.isEmpty)
            const Center(child: Padding(
              padding: EdgeInsets.all(40),
              child: Text('No trips scheduled for today.'),
            ))
          else
            ...todaySchedules.map((s) {
              final route = s['route'] as Map<String, dynamic>?;
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ExpansionTile(
                  title: Text(
                    route != null ? '${route['origin']} → ${route['destination']}' : 'Unknown Route',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Departs: ${DateFormat('hh:mm a').format(DateTime.parse(s['departure_datetime']))} • ${s['available_seats_count'] ?? 0} seats left',
                  ),
                  children: [
                    DataTable(
                      columnSpacing: 16,
                      columns: const [
                        DataColumn(label: Text('Ref')),
                        DataColumn(label: Text('Passenger')),
                        DataColumn(label: Text('Seat')),
                        DataColumn(label: Text('Status')),
                      ],
                      rows: const [
                        DataRow(cells: [
                          DataCell(Text('—')),
                          DataCell(Text('No data loaded')),
                          DataCell(Text('—')),
                          DataCell(Text('—')),
                        ]),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }
}
