import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/travel_provider.dart';
import '../models/trip.dart';
import 'add_trip_screen.dart';
import 'trip_details_screen.dart';
import 'analytics_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Trip search & filter states
  String _searchDestination = "";
  String _selectedStatusFilter = "Tutti"; // Tutti, futuro, in_corso, completato
  DateTimeRange? _selectedDateRange;
  bool _showFilterPanel = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Load trips on startup
    Future.microtask(() =>
      Provider.of<TravelProvider>(context, listen: false).loadTrips()
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime dt) {
    return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
  }

  @override
  Widget build(BuildContext context) {
    final travelProvider = Provider.of<TravelProvider>(context);
    final trips = travelProvider.trips;

    // Filter trips by destination/title, status, and date range
    final filteredTrips = trips.where((t) {
      if (_searchDestination.isNotEmpty &&
          !t.destination.toLowerCase().contains(_searchDestination.toLowerCase()) &&
          !t.title.toLowerCase().contains(_searchDestination.toLowerCase())) {
        return false;
      }
      if (_selectedStatusFilter != "Tutti" && t.status != _selectedStatusFilter) {
        return false;
      }
      if (_selectedDateRange != null) {
        final tripStart = DateTime(t.startDate.year, t.startDate.month, t.startDate.day);
        final tripEnd = DateTime(t.endDate.year, t.endDate.month, t.endDate.day);
        final rangeStart = DateTime(_selectedDateRange!.start.year, _selectedDateRange!.start.month, _selectedDateRange!.start.day);
        final rangeEnd = DateTime(_selectedDateRange!.end.year, _selectedDateRange!.end.month, _selectedDateRange!.end.day);
        if (tripStart.isAfter(rangeEnd) || tripEnd.isBefore(rangeStart)) {
          return false;
        }
      }
      return true;
    }).toList();

    final activeTrips = filteredTrips.where((t) => t.status != 'archiviato').toList();
    final archivedTrips = filteredTrips.where((t) => t.status == 'archiviato').toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Sleek Header with Title and Dashboard Info
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Zefiro",
                          style: GoogleFonts.outfit(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        Text(
                          "Organizza le tue prossime avventure!",
                          style: Theme.of(context).textTheme.bodyMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: Icon(
                      Icons.bar_chart_outlined,
                      color: Theme.of(context).colorScheme.primary,
                      size: 28,
                    ),
                    tooltip: "Statistiche e Analisi",
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AnalyticsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Search and Filter Bar for Trips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: "Destinazione o Titolo",
                            prefixIcon: const Icon(Icons.search, size: 20),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          onChanged: (val) {
                            setState(() {
                              _searchDestination = val;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: _selectedStatusFilter != "Tutti" || _selectedDateRange != null
                              ? Theme.of(context).colorScheme.primary.withOpacity(0.15)
                              : Theme.of(context).cardColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: _selectedStatusFilter != "Tutti" || _selectedDateRange != null
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).dividerColor.withOpacity(0.2),
                            ),
                          ),
                          padding: const EdgeInsets.all(12),
                        ),
                        icon: Icon(
                          Icons.filter_list,
                          color: _selectedStatusFilter != "Tutti" || _selectedDateRange != null
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).iconTheme.color,
                        ),
                        onPressed: () {
                          setState(() {
                            _showFilterPanel = !_showFilterPanel;
                          });
                        },
                      ),
                    ],
                  ),
                  if (_showFilterPanel) ...[
                    const SizedBox(height: 12),
                    Card(
                      elevation: 0,
                      color: Theme.of(context).colorScheme.surface.withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Stato del Viaggio",
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  'Tutti', 'futuro', 'in_corso', 'completato'
                                ].map((status) {
                                  final display = status == 'futuro'
                                      ? 'Futuro'
                                      : status == 'in_corso'
                                          ? 'In Corso'
                                          : status == 'completato'
                                              ? 'Completato'
                                              : 'Tutti';
                                  final isSelected = _selectedStatusFilter == status;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: ChoiceChip(
                                      label: Text(display),
                                      selected: isSelected,
                                      selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                                      labelStyle: TextStyle(
                                        fontSize: 12,
                                        color: isSelected
                                            ? Theme.of(context).colorScheme.primary
                                            : Theme.of(context).textTheme.bodyMedium?.color,
                                      ),
                                      onSelected: (selected) {
                                        if (selected) {
                                          setState(() {
                                            _selectedStatusFilter = status;
                                          });
                                        }
                                      },
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            const Divider(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Intervallo di Date",
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                if (_selectedDateRange != null)
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _selectedDateRange = null;
                                      });
                                    },
                                    child: const Text("Azzera", style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () async {
                                final picked = await showDateRangePicker(
                                  context: context,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030),
                                  initialDateRange: _selectedDateRange,
                                );
                                if (picked != null) {
                                  setState(() {
                                    _selectedDateRange = picked;
                                  });
                                }
                              },
                              icon: const Icon(Icons.date_range, size: 16),
                              label: Text(
                                _selectedDateRange == null
                                    ? "Seleziona Date"
                                    : "${_formatDate(_selectedDateRange!.start)} - ${_formatDate(_selectedDateRange!.end)}",
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // 2. Tab Bar for Active vs Archived
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                ),
                dividerColor: Colors.transparent,
                labelColor: Theme.of(context).colorScheme.primary,
                unselectedLabelColor: Colors.grey,
                labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.flight_takeoff, size: 18),
                        const SizedBox(width: 8),
                        Text("Viaggi Attivi (${activeTrips.length})"),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.archive_outlined, size: 18),
                        const SizedBox(width: 8),
                        Text("Archiviati (${archivedTrips.length})"),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 3. Tab Bar View for Trips
            Expanded(
              child: travelProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildTripsList(context, activeTrips, travelProvider, false),
                        _buildTripsList(context, archivedTrips, travelProvider, true),
                      ],
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddTripScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text("Aggiungi Viaggio"),
      ),
    );
  }

  Widget _buildTripsList(BuildContext context, List<Trip> list, TravelProvider provider, bool isArchivedList) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isArchivedList ? Icons.archive_outlined : Icons.explore_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              isArchivedList ? "Nessun viaggio archiviato" : "Ancora nessun viaggio creato",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              isArchivedList ? "Puoi archiviare i viaggi trascinandoli verso sinistra." : "Tocca il tasto + in basso per iniziare!",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 80),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final trip = list[index];

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Dismissible(
            key: Key("trip_${trip.id}"),
            background: Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 24),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(Icons.delete, color: Colors.white),
                  SizedBox(width: 8),
                  Text("Elimina", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            secondaryBackground: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 24),
              decoration: BoxDecoration(
                color: isArchivedList ? Colors.green : Colors.orangeAccent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    isArchivedList ? "Ripristina" : "Archivia",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Icon(isArchivedList ? Icons.unarchive : Icons.archive, color: Colors.white),
                ],
              ),
            ),
            confirmDismiss: (direction) async {
              if (direction == DismissDirection.startToEnd) {
                // Swipe Left-to-Right: Delete
                return await _confirmDelete(context, trip, provider);
              } else {
                // Swipe Right-to-Left: Archive/Restore
                if (isArchivedList) {
                  // Restore to appropriate computed status based on dates
                  String targetStatus = 'futuro';
                  final now = DateTime.now();
                  final today = DateTime(now.year, now.month, now.day);
                  final startDay = DateTime(trip.startDate.year, trip.startDate.month, trip.startDate.day);
                  final endDay = DateTime(trip.endDate.year, trip.endDate.month, trip.endDate.day);

                  if (today.isBefore(startDay)) {
                    targetStatus = 'futuro';
                  } else if (today.isAfter(endDay)) {
                    targetStatus = 'completato';
                  } else {
                    targetStatus = 'in_corso';
                  }

                  await provider.updateTrip(trip.copyWith(status: targetStatus));
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Viaggio '${trip.title}' ripristinato")),
                    );
                  }
                } else {
                  // Archive
                  await provider.updateTrip(trip.copyWith(status: 'archiviato'));
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Viaggio '${trip.title}' archiviato")),
                    );
                  }
                }
                return false; // Handled manually by state update, don't dismiss card natively
              }
            },
            child: _buildTripCard(context, trip, provider),
          ),
        );
      },
    );
  }

  Widget _buildTripCard(BuildContext context, Trip trip, TravelProvider provider) {
    // Generate cover gradient based on the trip's title
    final gradientColors = [
      Color((trip.title.hashCode & 0xFFFFFF) | 0xFF000000).withOpacity(0.85),
      Color((trip.destination.hashCode & 0xFFFFFF) | 0xFF000000).withOpacity(0.85),
    ];

    // Determine status badge details
    String statusText = 'Futuro';
    Color badgeColor = Colors.blueAccent;
    IconData statusIcon = Icons.calendar_today;

    if (trip.status == 'in_corso') {
      statusText = 'In Corso';
      badgeColor = Colors.green;
      statusIcon = Icons.directions_run;
    } else if (trip.status == 'completato') {
      statusText = 'Completato';
      badgeColor = Colors.blueGrey;
      statusIcon = Icons.done_all;
    } else if (trip.status == 'archiviato') {
      statusText = 'Archiviato';
      badgeColor = Colors.orange;
      statusIcon = Icons.archive_outlined;
    }

    return InkWell(
      onTap: () async {
        await provider.selectTrip(trip);
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const TripDetailsScreen(),
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Card(
        margin: EdgeInsets.zero,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Trip Cover Header
              Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      gradientColors[0],
                      gradientColors[1].withBlue(180),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    // Background graphics
                    Positioned(
                      right: -20,
                      bottom: -20,
                      child: Icon(
                        Icons.landscape,
                        size: 150,
                        color: Colors.white.withOpacity(0.12),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.location_on_outlined, color: Colors.white, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      trip.destination,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Status Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: badgeColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(statusIcon, color: Colors.white, size: 12),
                                    const SizedBox(width: 4),
                                    Text(
                                      statusText,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            trip.title,
                            style: GoogleFonts.outfit(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Action Buttons (Edit)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddTripScreen(trip: trip),
                            ),
                          );
                        },
                      ),
                    )
                  ],
                ),
              ),
              // Trip Dates & Info Footer
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "${_formatDate(trip.startDate)} - ${_formatDate(trip.endDate)}",
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      "Budget: €${trip.budget.toStringAsFixed(0)}",
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, Trip trip, TravelProvider provider) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Elimina Viaggio"),
        content: Text("Sei sicuro di voler eliminare definitivamente il viaggio '${trip.title}'? Questa azione non può essere annullata."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Annulla"),
          ),
          TextButton(
            onPressed: () {
              provider.deleteTrip(trip.id!);
              Navigator.pop(context, true);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Viaggio '${trip.title}' eliminato")),
              );
            },
            child: const Text("Elimina", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
