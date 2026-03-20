import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/trip_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/global_top_nav_bar.dart';
import 'package:intl/intl.dart';

class SearchResultsPage extends ConsumerStatefulWidget {
  final String? origin;
  final String? destination;
  final String? date;
  final int passengers;

  const SearchResultsPage({super.key, this.origin, this.destination, this.date, this.passengers = 1});

  @override
  ConsumerState<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends ConsumerState<SearchResultsPage> {
  RangeValues _priceRange = const RangeValues(500, 5000);
  String _departureTime = 'All'; // All, Morning, Afternoon, Evening, Night
  String _vehicleType = 'All'; // All, Bus, Shuttle
  final List<String> _amenities = []; // WiFi, AC, Power Outlets, Water
  String _searchQuery = '';
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _performSearch();
    });
  }

  @override
  void didUpdateWidget(SearchResultsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.origin != widget.origin || 
        oldWidget.destination != widget.destination || 
        oldWidget.date != widget.date) {
      _performSearch();
    }
  }

  void _performSearch() {
    if (widget.origin != null || widget.destination != null) {
      ref.read(tripProvider.notifier).searchSchedules(
        origin: widget.origin,
        destination: widget.destination,
        date: widget.date,
      );
      setState(() => _hasSearched = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tripState = ref.watch(tripProvider);
    final displayDate = widget.date != null ? DateFormat('E, d MMM yyyy').format(DateTime.parse(widget.date!)) : 'Any Date';

    // Apply Live Filters
    final filteredTrips = tripState.schedules.where((schedule) {
      if (_searchQuery.isNotEmpty) {
        final opName = (schedule.vehicle?['operator_name'] ?? '').toLowerCase();
        if (!opName.contains(_searchQuery.toLowerCase())) return false;
      }
      if (schedule.fare < _priceRange.start || schedule.fare > _priceRange.end) return false;

      final vType = schedule.vehicle?['vehicle_type']?.toLowerCase() ?? '';
      if (_vehicleType != 'All') {
        if (_vehicleType == 'Bus' && !vType.contains('bus')) return false;
        if (_vehicleType == 'Shuttle' && !vType.contains('shuttle')) return false;
      }

      final hour = schedule.departureDatetime.hour;
      if (_departureTime == 'Morning' && (hour < 5 || hour >= 12)) return false;
      if (_departureTime == 'Afternoon' && (hour < 12 || hour >= 17)) return false;
      if (_departureTime == 'Evening' && (hour < 17 || hour >= 21)) return false;
      if (_departureTime == 'Night' && (hour >= 5 && hour < 21)) return false;

      return true;
    }).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;
        
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: const GlobalTopNavBar(),
          body: tripState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : tripState.error != null
                  ? Center(child: Text(tripState.error!))
                  : SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 16 : 40, 
                        vertical: 24
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Search results', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                          const SizedBox(height: 8),
                          // Responsive Header
                          if (isMobile)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${widget.origin ?? "Any"} to ${widget.destination ?? "Any"}',
                                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$displayDate | ${widget.passengers} Passenger(s)',
                                  style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 12),
                                OutlinedButton(
                                  onPressed: () => context.pop(),
                                  style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 40)),
                                  child: const Text('Edit Search', style: TextStyle(color: AppColors.primary)),
                                ),
                              ],
                            )
                          else
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '${widget.origin ?? "Any"} to ${widget.destination ?? "Any"} | $displayDate | ${widget.passengers} Passenger(s)',
                                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                OutlinedButton(
                                  onPressed: () => context.pop(),
                                  child: const Text('Edit Search', style: TextStyle(color: AppColors.primary)),
                                ),
                              ],
                            ),
                          const SizedBox(height: 32),
                          // Main content
                          if (isMobile)
                            Column(
                              children: [
                                // Simple Search Toggle or just show simple filter
                                _buildMobileFilterToggle(),
                                const SizedBox(height: 24),
                                if (filteredTrips.isEmpty)
                                  const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('No trips match your filters.')))
                                else
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: filteredTrips.length,
                                    itemBuilder: (context, index) => _TripCard(schedule: filteredTrips[index], passengers: widget.passengers),
                                  ),
                              ],
                            )
                          else
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(width: 250, child: _buildFiltersSidebar()),
                                const SizedBox(width: 32),
                                Expanded(
                                  child: filteredTrips.isEmpty
                                      ? const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('No trips match your exact filters.')))
                                      : ListView.builder(
                                          shrinkWrap: true,
                                          physics: const NeverScrollableScrollPhysics(),
                                          itemCount: filteredTrips.length,
                                          itemBuilder: (context, index) => _TripCard(schedule: filteredTrips[index], passengers: widget.passengers),
                                        ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
        );
      },
    );
  }

  Widget _buildMobileFilterToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.filter_list, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('Filters (${_amenities.length + (_departureTime != 'All' ? 1 : 0)})', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          TextButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => Container(
                  height: MediaQuery.of(context).size.height * 0.8,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 40, height: 4,
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                      ),
                      Expanded(child: SingleChildScrollView(child: _buildFiltersSidebar())),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: AppColors.primary),
                          child: const Text('Apply Filters', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            child: const Text('Adjust'),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSidebar() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Search', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(hintText: 'Operator Name...', isDense: true, border: OutlineInputBorder()),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
          const SizedBox(height: 24),
          const Text('Price Range', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('KES ${_priceRange.start.toInt()}', style: const TextStyle(fontSize: 12)), 
              Text('KES ${_priceRange.end.toInt()}', style: const TextStyle(fontSize: 12))
            ],
          ),
          RangeSlider(
            values: _priceRange,
            min: 500,
            max: 5000,
            divisions: 45,
            activeColor: AppColors.primary,
            onChanged: (v) => setState(() => _priceRange = v),
          ),
          const SizedBox(height: 24),
          const Text('Departure Time', style: TextStyle(fontWeight: FontWeight.bold)),
          _filterRadio('All', _departureTime, (v) => setState(() => _departureTime = v)),
          _filterRadio('Morning', _departureTime, (v) => setState(() => _departureTime = v)),
          _filterRadio('Afternoon', _departureTime, (v) => setState(() => _departureTime = v)),
          _filterRadio('Evening', _departureTime, (v) => setState(() => _departureTime = v)),
          _filterRadio('Night', _departureTime, (v) => setState(() => _departureTime = v)),
          const SizedBox(height: 24),
          const Text('Vehicle Type', style: TextStyle(fontWeight: FontWeight.bold)),
          _filterRadio('All', _vehicleType, (v) => setState(() => _vehicleType = v)),
          _filterRadio('Bus', _vehicleType, (v) => setState(() => _vehicleType = v)),
          _filterRadio('Shuttle', _vehicleType, (v) => setState(() => _vehicleType = v)),
          const SizedBox(height: 24),
          const Text('Amenities', style: TextStyle(fontWeight: FontWeight.bold)),
          _filterCheckbox(Icons.wifi, 'WiFi'),
          _filterCheckbox(Icons.ac_unit, 'AC'),
          _filterCheckbox(Icons.electrical_services, 'Power Outlets'),
          _filterCheckbox(Icons.water_drop, 'Water'),
        ],
      ),
    );
  }

  Widget _filterRadio(String title, String groupValue, Function(String) onChanged) {
    final selected = title == groupValue;
    return InkWell(
      onTap: () => onChanged(title),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(selected ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: selected ? AppColors.primary : AppColors.divider, size: 20),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }

  Widget _filterCheckbox(IconData icon, String title) {
    final selected = _amenities.contains(title);
    return InkWell(
      onTap: () {
        setState(() {
          if (selected) {
            _amenities.remove(title);
          } else {
            _amenities.add(title);
          }
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(
              selected ? Icons.check_box : Icons.check_box_outline_blank,
              color: selected ? AppColors.primary : AppColors.divider,
              size: 20,
            ),
            const SizedBox(width: 8),
            Icon(icon, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(fontSize: 14, fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  final dynamic schedule;
  final int passengers;

  const _TripCard({required this.schedule, required this.passengers});

  @override
  Widget build(BuildContext context) {
    final operatorName = schedule.vehicle?['operator_name'] ?? 'Premium Shuttle';
    final isBus = schedule.vehicle?['vehicle_type']?.toLowerCase().contains('bus') ?? true;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 24.0),
            child: Column(
              children: [
                // Top Row: Operator and Fare
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppColors.background,
                            radius: isMobile ? 16 : 20,
                            child: Icon(isBus ? Icons.directions_bus : Icons.airport_shuttle, color: AppColors.accent, size: isMobile ? 16 : 20),
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Operator', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                                Text(operatorName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 14 : 16, color: AppColors.primary), overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                          if (!isMobile) ...[
                            const SizedBox(width: 32),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Vehicle Class', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                Text(isBus ? 'VIP Coach' : 'Executive', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Fare', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                        Text('KES ${NumberFormat('#,##0').format(schedule.fare)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 18 : 22, color: AppColors.textPrimary)),
                      ],
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(),
                ),
                // Middle Section: Timing and Route
                if (isMobile)
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildTimeColumn(DateFormat('HH:mm').format(schedule.departureDatetime), schedule.route.origin),
                          const Icon(Icons.arrow_forward_rounded, color: AppColors.textSecondary, size: 16),
                          _buildTimeColumn(DateFormat('HH:mm').format(schedule.arrivalEstimate), schedule.route.destination),
                          _buildInfoColumn('Duration', '8h 30m'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildInfoColumn('Boarding', '${schedule.route.origin} CBD'),
                          _buildInfoColumn('Seats', '${schedule.availableSeatsCount} Left', align: CrossAxisAlignment.end),
                        ],
                      ),
                    ],
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Departure & Arrival', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(DateFormat('HH:mm').format(schedule.departureDatetime), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Icon(Icons.arrow_forward_rounded, color: AppColors.textSecondary, size: 20),
                              ),
                              Text(DateFormat('HH:mm').format(schedule.arrivalEstimate), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Text('${schedule.route.origin} to ${schedule.route.destination}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                      _buildInfoColumn('Duration', '8h 30m'),
                      _buildInfoColumn('Boarding Terminal', '${schedule.route.origin} CBD'),
                      _buildInfoColumn('Available Seats', '${schedule.availableSeatsCount} Seats', align: CrossAxisAlignment.end),
                    ],
                  ),
                const SizedBox(height: 20),
                // Bottom Row: Amenities & Action
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (!isMobile)
                      Row(
                        children: [
                          const Text('Amenities', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          const SizedBox(width: 12),
                          _amenityBadge(Icons.wifi),
                          const SizedBox(width: 8),
                          _amenityBadge(Icons.ac_unit),
                          const SizedBox(width: 8),
                          _amenityBadge(Icons.power),
                        ],
                      )
                    else
                      const Row(
                        children: [
                          Icon(Icons.wifi, size: 14, color: AppColors.textSecondary),
                          SizedBox(width: 8),
                          Icon(Icons.ac_unit, size: 14, color: AppColors.textSecondary),
                          SizedBox(width: 8),
                          Icon(Icons.power, size: 14, color: AppColors.textSecondary),
                        ],
                      ),
                    ElevatedButton(
                      onPressed: () => GoRouter.of(context).push('/seat-selection/${schedule.id}?passengers=$passengers'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 32, vertical: isMobile ? 12 : 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text('Book Now', style: TextStyle(fontSize: isMobile ? 14 : 16, fontWeight: FontWeight.w900)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimeColumn(String time, String city) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(time, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(city, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildInfoColumn(String label, String value, {CrossAxisAlignment align = CrossAxisAlignment.start}) {
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _amenityBadge(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.divider),
      ),
      child: Icon(icon, size: 16, color: AppColors.textSecondary),
    );
  }
}

