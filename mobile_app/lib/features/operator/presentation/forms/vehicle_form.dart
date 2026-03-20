import 'package:flutter/material.dart';
import '../../../../core/network/dio_client.dart';

class VehicleForm extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  final VoidCallback onSuccess;
  const VehicleForm({super.key, this.initialData, required this.onSuccess});

  @override
  State<VehicleForm> createState() => _VehicleFormState();
}

class _VehicleFormState extends State<VehicleForm> {
  final _formKey = GlobalKey<FormState>();
  final _plateController = TextEditingController();
  final _typeController = TextEditingController();
  final _capacityController = TextEditingController();
  bool _isLoading = false;
  final _api = ApiClient();

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _plateController.text = widget.initialData!['plate_number'] ?? '';
      _typeController.text = widget.initialData!['vehicle_type'] ?? '';
      _capacityController.text = widget.initialData!['seat_capacity']?.toString() ?? '';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final data = {
        'plate_number': _plateController.text,
        'vehicle_type': _typeController.text,
        'seat_capacity': int.tryParse(_capacityController.text) ?? 0,
      };
      if (widget.initialData != null) {
        await _api.dio.put('/operator/vehicles/${widget.initialData!['id']}/', data: data);
      } else {
        await _api.dio.post('/operator/vehicles/', data: data);
      }
      widget.onSuccess();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save vehicle.')),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.initialData == null ? 'Add Vehicle' : 'Edit Vehicle',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _plateController,
              decoration: const InputDecoration(labelText: 'Plate Number', prefixIcon: Icon(Icons.directions_car)),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _typeController,
              decoration: const InputDecoration(labelText: 'Vehicle Type (e.g. 29-Seater)', prefixIcon: Icon(Icons.category)),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _capacityController,
              decoration: const InputDecoration(labelText: 'Seat Capacity', prefixIcon: Icon(Icons.event_seat)),
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
                    : Text(widget.initialData == null ? 'Add Vehicle' : 'Save Changes'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
