import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class ManifestWidget extends StatelessWidget {
  const ManifestWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Ref')),
          DataColumn(label: Text('Passenger')),
          DataColumn(label: Text('Seat')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Actions')),
        ],
        rows: [
          _buildRow('TG-872', 'John Doe', 'A1', 'PAID'),
          _buildRow('TG-873', 'Jane Smith', 'A2', 'PAID'),
          _buildRow('TG-874', 'Peter Kamau', 'B1', 'PENDING'),
        ],
      ),
    );
  }

  DataRow _buildRow(String ref, String name, String seat, String status) {
    return DataRow(cells: [
      DataCell(Text(ref)),
      DataCell(Text(name)),
      DataCell(Text(seat)),
      DataCell(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: status == 'PAID' ? AppColors.success.withOpacity(0.1) : AppColors.warning.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(status, style: TextStyle(color: status == 'PAID' ? AppColors.success : AppColors.warning, fontSize: 10, fontWeight: FontWeight.bold)),
        ),
      ),
      DataCell(Row(
        children: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.edit, size: 18)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.print, size: 18)),
        ],
      )),
    ]);
  }
}
