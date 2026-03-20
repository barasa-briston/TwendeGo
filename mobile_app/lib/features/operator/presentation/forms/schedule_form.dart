import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/dio_client.dart';

class ScheduleForm extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  final VoidCallback onSuccess;
  const ScheduleForm({super.key, this.initialData, required this.onSuccess});

  @override
  State<ScheduleForm> createState() => _ScheduleFormState();
}

class _ScheduleFormState extends State<ScheduleForm> {
  final _formKey = GlobalKey<FormState>();
  final _fareController = TextEditingController();
  DateTime? _departureDateTime;
  String? _selectedRouteId;
  String? _selectedVehicleId;
  List<Map<String, dynamic>> _routes = [];
  List<Map<String, dynamic>> _vehicles = [];
  bool _isLoading = false;
  final _api = ApiClient();

  @override
  void initState() {
    super.initState();
    _loadDropdownData();
    if (widget.initialData != null) {
      _fareController.text = widget.initialData!['fare']?.toString() ?? '';
      _selectedRouteId = widget.initialData!['route']?['id']?.toString();
      _selectedVehicleId = widget.initialData!['vehicle']?['id']?.toString();
    }
  }

  Future<void> _loadDropdownData() async {
    try {
      final routesRes = await _api.dio.get('/operator/routes/');
      final vehiclesRes = await _api.dio.get('/operator/vehicles/');
      setState(() {
        _routes = List<Map<String, dynamic>>.from(routesRes.data);
        _vehicles = List<Map<String, dynamic>>.from(vehiclesRes.data);
      });
    } catch (_) {}
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
        context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
    if (date == null) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time == null) return;
    setState(() {
      _departureDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _departureDateTime == null) return;
    setState(() => _isLoading = true);
    try {
      final data = {
        'route': _selectedRouteId,
        'vehicle': _selectedVehicleId,
        'departure_datetime': _departureDateTime!.toIso8601String(),
        'arrival_estimate': _departureDateTime!.add(const Duration(hours: 3)).toIso8601String(),
        'fare': double.tryParse(_fareController.text) ?? 0,
        'status': 'SCHEDULED',
      };
      if (widget.initialData != null) {
        await _api.dio.put('/operator/schedules/${widget.initialData!['id']}/', data: data);
      } else {
        await _api.dio.post('/operator/schedules/', data: data);
      }
      widget.onSuccess();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save schedule.')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.initialData == null ? 'Add Schedule' : 'Edit Schedule',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedRouteId,
                decoration: const InputDecoration(labelText: 'Route', prefixIcon: Icon(Icons.route)),
                items: _routes.map((r) => DropdownMenuItem<String>(value: r['id'].toString(), child: Text('${r['origin']} → ${r['destination']}'))).toList(),
                onChanged: (v) => setState(() => _selectedRouteId = v),
                validator: (v) => v == null ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedVehicleId,
                decoration: const InputDecoration(labelText: 'Vehicle', prefixIcon: Icon(Icons.directions_bus)),
                items: _vehicles.map((v) => DropdownMenuItem<String>(value: v['id'].toString(), child: Text(v['plate_number']))).toList(),
                onChanged: (v) => setState(() => _selectedVehicleId = v),
                validator: (v) => v == null ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: Text(_departureDateTime == null
                    ? 'Select Departure Date & Time'
                    : DateFormat('dd MMM yyyy, hh:mm a').format(_departureDateTime!)),
                trailing: const Icon(Icons.chevron_right),
                onTap: _pickDateTime,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _fareController,
                decoration: const InputDecoration(labelText: 'Fare (KES)', prefixIcon: Icon(Icons.payments)),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(widget.initialData == null ? 'Add Schedule' : 'Save Changes'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
