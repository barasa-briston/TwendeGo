import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../features/trips/presentation/providers/trip_provider.dart';

class HeroSearchBar extends ConsumerStatefulWidget {
  const HeroSearchBar({super.key});

  @override
  ConsumerState<HeroSearchBar> createState() => _HeroSearchBarState();
}

class _HeroSearchBarState extends ConsumerState<HeroSearchBar> {
  DateTime? _selectedDate;
  String _fromLocation = '';
  String _toLocation = '';
  int _passengers = 1;

  static const List<String> _kenyanCities = [
    'Nairobi', 'Mombasa', 'Kisumu', 'Nakuru', 'Eldoret', 
    'Malindi', 'Machakos', 'Thika', 'Nyeri', 'Kakamega', 
    'Naivasha', 'Kitale', 'Meru', 'Kilifi', 'Voi', 'Garissa'
  ];

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Book » Pay » Travel',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildAutocompleteField(
                  label: 'From',
                  icon: Icons.location_on,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAutocompleteField(
                  label: 'To',
                  icon: Icons.location_on,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 90)),
                    );
                    if (date != null) setState(() => _selectedDate = date);
                  },
                  child: _buildDisplayField(
                    label: 'Departure Date',
                    value: _selectedDate == null 
                        ? 'Select Date' 
                        : DateFormat('dd MMM yyyy').format(_selectedDate!),
                    icon: Icons.calendar_today,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        int tempPassengers = _passengers;
                        return StatefulBuilder(
                          builder: (context, setDialogState) {
                            return AlertDialog(
                              title: const Text('Select Passengers'),
                              content: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove),
                                    onPressed: () {
                                      if (tempPassengers > 1) {
                                        setDialogState(() => tempPassengers--);
                                      }
                                    },
                                  ),
                                  Text('$tempPassengers', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: () {
                                      if (tempPassengers < 10) {
                                        setDialogState(() => tempPassengers++);
                                      }
                                    },
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() => _passengers = tempPassengers);
                                    Navigator.pop(context);
                                  },
                                  child: const Text('Confirm'),
                                ),
                              ],
                            );
                          }
                        );
                      }
                    );
                  },
                  child: _buildDisplayField(
                    label: 'Passengers',
                    value: '$_passengers Passenger${_passengers > 1 ? 's' : ''}',
                    icon: Icons.person,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              if (_fromLocation.isEmpty || _toLocation.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter origin and destination')),
                );
                return;
              }
              
              final dateStr = _selectedDate == null ? null : DateFormat('yyyy-MM-dd').format(_selectedDate!);
              
              // Trigger search
              ref.read(tripProvider.notifier).searchSchedules(
                origin: _fromLocation,
                destination: _toLocation,
                date: dateStr,
              );
              
              context.push(
                Uri(
                  path: '/search',
                  queryParameters: {
                    'origin': _fromLocation,
                    'destination': _toLocation,
                    'date': dateStr,
                    'passengers': _passengers.toString(),
                  },
                ).toString(),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size(double.infinity, 56),
            ),
            child: const Text('SEARCH TRIPS', style: TextStyle(fontSize: 18, letterSpacing: 1.2)),
          ),
        ],
      ),
    ),
   ),
  );
}

  Widget _buildAutocompleteField({required String label, required IconData icon}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Autocomplete<String>(
        optionsBuilder: (TextEditingValue textEditingValue) {
          if (textEditingValue.text.isEmpty) {
            return const Iterable<String>.empty();
          }
          return _kenyanCities.where((String option) {
            return option.toLowerCase().startsWith(textEditingValue.text.toLowerCase());
          });
        },
        onSelected: (String selection) {
          if (label == 'From') _fromLocation = selection; else _toLocation = selection;
        },
        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
          return TextField(
            controller: controller,
            focusNode: focusNode,
            onChanged: (val) {
              if (label == 'From') _fromLocation = val; else _toLocation = val;
            },
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: AppColors.primary),
              hintText: label,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 15),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDisplayField({required String label, required String value, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
