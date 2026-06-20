import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/travel_provider.dart';
import '../models/trip.dart';
import '../models/activity.dart';
import '../models/checklist_item.dart';
import '../models/useful_info.dart';
import '../models/expense.dart';
import '../theme/app_theme.dart';
import '../services/currency_service.dart';
import 'add_stop_screen.dart';
import 'add_expense_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class TripDetailsScreen extends StatefulWidget {
  const TripDetailsScreen({super.key});

  @override
  State<TripDetailsScreen> createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends State<TripDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _checklistController = TextEditingController();
  bool _isInfoExpanded = false;

  // Checklist categorization states
  String _selectedChecklistCategory = 'Tutti';
  String _addChecklistCategory = 'Bagaglio';
  String _addChecklistPriority = 'Media';
  String _selectedChecklistStatusFilter = "Tutti"; // Tutti, Da completare, Completati
  String _selectedChecklistPriorityFilter = "Tutte"; // Tutte, Bassa, Media, Alta

  // Useful Info categorization states
  String _selectedUsefulInfoCategory = 'Tutti';

  // Expense states
  String _selectedExpenseFilter = 'Tutte';
  bool _showExpenseFilterPanel = false;
  String _selectedExpenseCategoryFilter = "Tutte";
  String _selectedExpenseAmountRangeFilter = "Tutti";
  String _selectedExpenseAssociationFilter = "Tutti";
  final TextEditingController _convAmountController = TextEditingController(text: '100');
  String _convFrom = 'EUR';
  String _convTo = 'USD';

  // Itinerary states
  String _searchStopLocation = "";
  DateTime? _selectedStopDate;
  String _selectedActivityCategoryFilter = "Tutti";

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Alta':
        return Colors.redAccent;
      case 'Bassa':
        return Colors.green;
      case 'Media':
      default:
        return Colors.orange;
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Rebuild to change FAB based on active tab
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _checklistController.dispose();
    _convAmountController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime dt) {
    return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
  }

  String _formatTime(String time) {
    // Just return the HH:mm format
    return time;
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TravelProvider>(context);
    final trip = provider.selectedTrip;

    if (trip == null) {
      return const Scaffold(
        body: Center(child: Text("Nessun viaggio selezionato")),
      );
    }

    final gradientColors = [
      Color((trip.title.hashCode & 0xFFFFFF) | 0xFF000000).withOpacity(0.85),
      Color((trip.destination.hashCode & 0xFFFFFF) | 0xFF000000).withOpacity(0.85),
    ];

    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!isKeyboardOpen) ...[
                      // 1. Premium Trip Header Card
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [gradientColors[0], gradientColors[1].withBlue(180)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: gradientColors[0].withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                    Text(
                                      trip.destination,
                                      style: GoogleFonts.outfit(
                                        color: Colors.white.withOpacity(0.9),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 48), // Spacer to balance back button
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  trip.title,
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_month, color: Colors.white70, size: 16),
                                    const SizedBox(width: 6),
                                    Text(
                                      "${_formatDate(trip.startDate)} - ${_formatDate(trip.endDate)}",
                                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Collapsible Trip Info Drawer
                      _buildTripInfoSection(context, trip),
                    ] else ...[
                      // Compact Header for Keyboard Mode
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                        child: Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.arrow_back_ios, color: Theme.of(context).colorScheme.primary, size: 20),
                              onPressed: () => Navigator.pop(context),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                "${trip.destination} • ${trip.title}",
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Theme.of(context).colorScheme.onBackground,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    controller: _tabController,
                    indicatorColor: Theme.of(context).colorScheme.primary,
                    labelColor: Theme.of(context).colorScheme.onBackground,
                    unselectedLabelColor: Theme.of(context).textTheme.bodyMedium?.color,
                    tabs: const [
                      Tab(icon: Icon(Icons.map_outlined), text: "Itinerario"),
                      Tab(icon: Icon(Icons.checklist_outlined), text: "Checklist"),
                      Tab(icon: Icon(Icons.euro_outlined), text: "Spese"),
                      Tab(icon: Icon(Icons.info_outline), text: "Info Utili"),
                    ],
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildItineraryTab(provider),
              _buildChecklistTab(provider),
              _buildExpensesTab(provider),
              _buildUsefulInfoTab(provider),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFAB(provider),
    );
  }

  // ==========================================
  // FLOATING ACTION BUTTON BUILDER
  // ==========================================

  Widget? _buildFAB(TravelProvider provider) {
    if (MediaQuery.of(context).viewInsets.bottom > 0) {
      return null;
    }
    if (_tabController.index == 0) {
      // Itinerary Tab FAB -> Add Stop
      return FloatingActionButton.extended(
        key: const ValueKey('fab_itinerary'),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddStopScreen(tripId: provider.selectedTrip!.id!),
            ),
          );
        },
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text("Aggiungi Tappa"),
      );
    } else if (_tabController.index == 2) {
      // Expenses Tab FAB -> Add Expense
      return FloatingActionButton.extended(
        key: const ValueKey('fab_expenses'),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddExpenseScreen(tripId: provider.selectedTrip!.id!),
            ),
          );
        },
        icon: const Icon(Icons.add_card_outlined),
        label: const Text("Aggiungi Spesa"),
      );
    } else if (_tabController.index == 3) {
      // Useful Info Tab FAB -> Add Useful Info
      return FloatingActionButton.extended(
        key: const ValueKey('fab_useful_info'),
        onPressed: () {
          _showAddEditUsefulInfoDialog(provider);
        },
        icon: const Icon(Icons.add_comment_outlined),
        label: const Text("Nuova Info"),
      );
    }
    // Checklist uses text input at bottom, no FAB needed
    return null;
  }

  // ==========================================
  // TAB 1: ITINERARY (TIMELINE VIEW)
  // ==========================================

  Widget _buildItineraryTab(TravelProvider provider) {
    final stops = provider.currentStops;

    if (stops.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_road,
              size: 70,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              "Nessuna tappa definita per questo viaggio",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              "Tocca 'Aggiungi Tappa' per pianificare la prima tappa!",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    // Filter stops by location/name, date, and activity category
    final filteredStops = stops.where((stop) {
      if (_searchStopLocation.isNotEmpty &&
          !stop.location.toLowerCase().contains(_searchStopLocation.toLowerCase()) &&
          !stop.name.toLowerCase().contains(_searchStopLocation.toLowerCase())) {
        return false;
      }
      if (_selectedStopDate != null) {
        final stopDate = DateTime(stop.dateTime.year, stop.dateTime.month, stop.dateTime.day);
        final selectedDate = DateTime(_selectedStopDate!.year, _selectedStopDate!.month, _selectedStopDate!.day);
        if (stopDate != selectedDate) {
          return false;
        }
      }
      if (_selectedActivityCategoryFilter != 'Tutti') {
        final hasMatchingActivity = provider.getActivitiesForStop(stop.id!).any((act) => act.type == _selectedActivityCategoryFilter);
        if (!hasMatchingActivity) {
          return false;
        }
      }
      return true;
    }).toList();

    return Column(
      children: [
        // Search & Filter Panel
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: "Cerca per località...",
                        prefixIcon: const Icon(Icons.search, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _searchStopLocation = val;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: _selectedStopDate != null
                          ? Theme.of(context).colorScheme.primary.withOpacity(0.15)
                          : Theme.of(context).cardColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: _selectedStopDate != null
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).dividerColor.withOpacity(0.2),
                        ),
                      ),
                    ),
                    icon: Icon(
                      Icons.calendar_month,
                      color: _selectedStopDate != null
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).iconTheme.color,
                    ),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: provider.selectedTrip!.startDate,
                        firstDate: provider.selectedTrip!.startDate,
                        lastDate: provider.selectedTrip!.endDate,
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedStopDate = picked;
                        });
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedActivityCategoryFilter,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: "Filtra Attività per Categoria",
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: [
                        'Tutti', 'Visita', 'Escursione', 'Prenotazione', 'Pasto', 'Spostamento', 'Evento', 'Momento Libero', 'Altro'
                      ].map((cat) => DropdownMenuItem<String>(
                            value: cat,
                            child: Text(cat == 'Tutti' ? 'Tutte le Attività' : cat),
                          )).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedActivityCategoryFilter = val;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (_selectedStopDate != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: InputChip(
                label: Text("Data: ${_formatDate(_selectedStopDate!)}"),
                onDeleted: () {
                  setState(() {
                    _selectedStopDate = null;
                  });
                },
              ),
            ),
          ),
        
        Expanded(
          child: filteredStops.isEmpty
              ? Center(
                  child: Text(
                    "Nessuna tappa trovata per i filtri selezionati.",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: filteredStops.length + 1,
                  itemBuilder: (context, index) {
                    if (index == filteredStops.length) {
                      return const SizedBox(height: 80);
                    }
                    final stop = filteredStops[index];
                    final activities = provider.getActivitiesForStop(stop.id!).where((act) {
                      if (_selectedActivityCategoryFilter != 'Tutti' && act.type != _selectedActivityCategoryFilter) {
                        return false;
                      }
                      return true;
                    }).toList();

                    return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline graphics (bullets and vertical lines)
            Column(
              children: [
                // Bullet point
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                // Vertical Line (except for the last item)
                if (index < stops.length - 1)
                  Container(
                    width: 3,
                    height: 110.0 + (activities.length * 40.0), // dynamic height based on activities
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            // Stop Card
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  "Giorno ${stop.itineraryOrder} • ${stop.name}",
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 20),
                                    tooltip: "Modifica tappa",
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => AddStopScreen(
                                            tripId: provider.selectedTrip!.id!,
                                            stop: stop,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                                    tooltip: "Rimuovi tappa",
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text("Elimina Tappa"),
                                          content: Text("Sei sicuro di voler eliminare la tappa '${stop.name}' e tutte le sue attività associate?"),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(ctx),
                                              child: const Text("Annulla"),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(ctx);
                                                provider.deleteStop(stop.id!);
                                              },
                                              child: const Text("Elimina", style: TextStyle(color: Colors.redAccent)),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(Icons.access_time, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                "${_formatDate(stop.dateTime)} alle ${_formatTime(stop.dateTime.hour.toString().padLeft(2, '0'))}:${stop.dateTime.minute.toString().padLeft(2, '0')}",
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
                              ),
                              if (stop.location.isNotEmpty) ...[
                                const SizedBox(width: 12),
                                const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    stop.location,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (stop.description.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              stop.description,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8),
                              ),
                            ),
                          ],
                          if (stop.notes.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.sticky_note_2_outlined,
                                  size: 14,
                                  color: Theme.of(context).colorScheme.secondary.withOpacity(0.8),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    stop.notes,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontStyle: FontStyle.italic,
                                      fontSize: 13,
                                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AddStopScreen(
                                      tripId: provider.selectedTrip!.id!,
                                      parentStop: stop,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.add_task, size: 16),
                              label: const Text(
                                "Aggiungi attività per questa tappa",
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Activities inside this stop
                  if (activities.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 12, bottom: 16),
                      child: Column(
                        children: activities.map((act) => _buildActivityRow(context, act, provider)).toList(),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    ),
  ),
],
);
}

  Widget _buildActivityRow(BuildContext context, Activity activity, TravelProvider provider) {
    final categoryIcon = AppTheme.activityIcons[activity.type] ?? Icons.local_activity;

    // Determine status colors and icons
    IconData statusIcon;
    Color statusColor;
    TextStyle? textStyle;

    switch (activity.status) {
      case 'Completata':
        statusIcon = Icons.check_circle;
        statusColor = Colors.green;
        textStyle = const TextStyle(
          decoration: TextDecoration.lineThrough,
          color: Colors.grey,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        );
        break;
      case 'Annullata':
        statusIcon = Icons.cancel;
        statusColor = Colors.redAccent;
        textStyle = const TextStyle(
          decoration: TextDecoration.lineThrough,
          color: Colors.grey,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        );
        break;
      case 'Da svolgere':
      default:
        statusIcon = Icons.radio_button_off;
        statusColor = Theme.of(context).colorScheme.primary;
        textStyle = const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        );
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 0,
      color: Theme.of(context).colorScheme.surface.withOpacity(0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // 1. Status Dropdown Trigger Icon
                PopupMenuButton<String>(
                  icon: Icon(statusIcon, color: statusColor, size: 20),
                  tooltip: "Cambia stato attività",
                  onSelected: (newStatus) {
                    final updatedActivity = activity.copyWith(status: newStatus);
                    provider.updateActivity(updatedActivity);
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'Da svolgere', child: Text('Da svolgere')),
                    const PopupMenuItem(value: 'Completata', child: Text('Completata')),
                    const PopupMenuItem(value: 'Annullata', child: Text('Annullata')),
                  ],
                ),
                const SizedBox(width: 4),
                // 2. Category Icon
                Icon(categoryIcon, size: 16, color: Theme.of(context).colorScheme.secondary),
                const SizedBox(width: 8),
                // 3. Time - Title
                Expanded(
                  child: Text(
                    "${activity.time} • ${activity.name}",
                    style: textStyle,
                  ),
                ),
                // 4. Cost
                if (activity.cost > 0) ...[
                  Text(
                    "€${activity.cost.toStringAsFixed(2).replaceAll('.', ',')}",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(width: 4),
                ],
                // 5. Actions (Edit / Delete)
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 16, color: Colors.grey),
                  tooltip: "Modifica attività",
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddStopScreen(
                          tripId: provider.selectedTrip!.id!,
                          activity: activity,
                        ),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 16, color: Colors.redAccent),
                  tooltip: "Elimina attività",
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text("Elimina Attività"),
                        content: Text("Sei sicuro di voler eliminare l'attività '${activity.name}'?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text("Annulla"),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              provider.deleteActivity(activity.id!);
                            },
                            child: const Text("Elimina", style: TextStyle(color: Colors.redAccent)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
            
            // Sub-details inside card
            Padding(
              padding: const EdgeInsets.only(left: 36.0, top: 2.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Location
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          activity.location,
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                  // Description
                  if (activity.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      activity.description,
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8),
                      ),
                    ),
                  ],
                  // Notes
                  if (activity.notes.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.sticky_note_2_outlined, size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            activity.notes,
                            style: const TextStyle(
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TAB 2: CHECKLIST
  // ==========================================

  IconData _getChecklistCategoryIcon(String category) {
    switch (category) {
      case 'Bagaglio':
        return Icons.backpack_outlined;
      case 'Documenti':
        return Icons.assignment_outlined;
      case 'Pre-partenza':
        return Icons.hourglass_top_outlined;
      case 'Prenotazioni':
        return Icons.book_online_outlined;
      case 'Acquisti':
        return Icons.shopping_bag_outlined;
      case 'Altro':
      default:
        return Icons.check_box_outlined;
    }
  }

  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showEditChecklistItemDialog(TravelProvider provider, ChecklistItem item) {
    final textController = TextEditingController(text: item.itemText);
    String selectedCategory = item.category;
    String selectedPriority = item.priority;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Modifica Elemento"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: textController,
                    decoration: InputDecoration(
                      labelText: "Nome Elemento *",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: InputDecoration(
                      labelText: "Categoria",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: ['Bagaglio', 'Documenti', 'Pre-partenza', 'Prenotazioni', 'Acquisti', 'Altro']
                        .map((cat) => DropdownMenuItem<String>(
                              value: cat,
                              child: Row(
                                children: [
                                  Icon(_getChecklistCategoryIcon(cat), size: 18),
                                  const SizedBox(width: 8),
                                  Text(cat),
                                ],
                              ),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          selectedCategory = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedPriority,
                    decoration: InputDecoration(
                      labelText: "Priorità",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: ['Bassa', 'Media', 'Alta']
                        .map((pri) => DropdownMenuItem<String>(
                              value: pri,
                              child: Row(
                                children: [
                                  Icon(Icons.flag, size: 18, color: _getPriorityColor(pri)),
                                  const SizedBox(width: 8),
                                  Text(pri),
                                ],
                              ),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          selectedPriority = val;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Annulla"),
                ),
                ElevatedButton(
                  onPressed: () {
                    final text = textController.text.trim();
                    if (text.isEmpty) {
                      _showValidationError("Il nome non può essere vuoto");
                      return;
                    }
                    if (textController.text.startsWith(' ')) {
                      _showValidationError("Il testo non può iniziare con uno spazio");
                      return;
                    }
                    provider.updateChecklistItem(
                      item.copyWith(
                        itemText: text,
                        category: selectedCategory,
                        priority: selectedPriority,
                      ),
                    );
                    Navigator.pop(context);
                  },
                  child: const Text("Salva"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteChecklistItemConfirmation(TravelProvider provider, ChecklistItem item) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Elimina Elemento"),
          content: Text("Sei sicuro di voler eliminare '${item.itemText}'?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annulla"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              onPressed: () {
                provider.deleteChecklistItem(item.id!);
                Navigator.pop(context);
              },
              child: const Text("Elimina"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildChecklistTab(TravelProvider provider) {
    final list = provider.currentChecklist;
    
    // Filter list by selected category, status, and priority
    final filteredList = list.where((item) {
      if (_selectedChecklistCategory != 'Tutti' && item.category != _selectedChecklistCategory) {
        return false;
      }
      if (_selectedChecklistStatusFilter != 'Tutti') {
        final wantChecked = _selectedChecklistStatusFilter == 'Completati';
        if (item.isChecked != wantChecked) {
          return false;
        }
      }
      if (_selectedChecklistPriorityFilter != 'Tutte' && item.priority != _selectedChecklistPriorityFilter) {
        return false;
      }
      return true;
    }).toList();

    // Progress is calculated on the category-only filtered list
    final categoryOnlyList = _selectedChecklistCategory == 'Tutti'
        ? list
        : list.where((item) => item.category == _selectedChecklistCategory).toList();

    final categoryCheckedCount = categoryOnlyList.where((i) => i.isChecked).length;
    final categoryRate = categoryOnlyList.isEmpty ? 0.0 : categoryCheckedCount / categoryOnlyList.length;

    final overallCheckedCount = list.where((i) => i.isChecked).length;
    final overallRate = list.isEmpty ? 0.0 : overallCheckedCount / list.length;

    return Column(
      children: [
        // Category, Status, and Priority Filter Dropdowns
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedChecklistCategory,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: "Categoria",
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: [
                    'Tutti', 'Bagaglio', 'Documenti', 'Pre-partenza', 'Prenotazioni', 'Acquisti', 'Altro'
                  ].map((cat) => DropdownMenuItem<String>(
                        value: cat,
                        child: Text(cat),
                      )).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedChecklistCategory = val;
                        // Automatically update default adding category if not "Tutti"
                        if (val != 'Tutti') {
                          _addChecklistCategory = val;
                        }
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedChecklistStatusFilter,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: "Stato",
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: ['Tutti', 'Da completare', 'Completati'].map((status) => DropdownMenuItem<String>(
                        value: status,
                        child: Text(status),
                      )).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedChecklistStatusFilter = val;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedChecklistPriorityFilter,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: "Priorità",
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: ['Tutte', 'Bassa', 'Media', 'Alta'].map((prio) => DropdownMenuItem<String>(
                        value: prio,
                        child: Row(
                          children: [
                            if (prio != 'Tutte') ...[
                              Icon(Icons.flag, size: 14, color: _getPriorityColor(prio)),
                              const SizedBox(width: 4),
                            ],
                            Text(prio),
                          ],
                        ),
                      )).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedChecklistPriorityFilter = val;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ),

        // Progress Card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedChecklistCategory == 'Tutti'
                            ? "Progresso Checklist Totale"
                            : "Progresso $_selectedChecklistCategory",
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "${(categoryRate * 100).toStringAsFixed(0)}%",
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: categoryRate,
                      minHeight: 10,
                      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "$categoryCheckedCount di ${filteredList.length} elementi completati",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (_selectedChecklistCategory != 'Tutti')
                        Text(
                          "Totale: $overallCheckedCount su ${list.length} (${(overallRate * 100).toStringAsFixed(0)}%)",
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // Checklist items
        Expanded(
          child: filteredList.isEmpty
              ? Center(
                  child: Text(
                    "Nessun elemento in questa categoria. Aggiungine uno qui sotto!",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredList.length + 1,
                  itemBuilder: (context, index) {
                    if (index == filteredList.length) {
                      return const SizedBox(height: 80);
                    }
                    final item = filteredList[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: Checkbox(
                          value: item.isChecked,
                          activeColor: Theme.of(context).colorScheme.primary,
                          onChanged: (_) => provider.toggleChecklistItem(item),
                        ),
                        title: Text(
                          item.itemText,
                          style: TextStyle(
                            decoration: item.isChecked ? TextDecoration.lineThrough : null,
                            color: item.isChecked ? Colors.grey : null,
                          ),
                        ),
                        subtitle: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              if (_selectedChecklistCategory == 'Tutti') ...[
                                Icon(_getChecklistCategoryIcon(item.category), size: 12, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  item.category,
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                                const SizedBox(width: 12),
                              ],
                              Icon(Icons.flag, size: 12, color: _getPriorityColor(item.priority)),
                            ],
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                              onPressed: () => _showEditChecklistItemDialog(provider, item),
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(8),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              onPressed: () => _showDeleteChecklistItemConfirmation(provider, item),
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(8),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),

        // Quick Add input box at bottom
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border(
              top: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1)),
            ),
          ),
          child: Row(
            children: [
              // Category icon selection menu
              PopupMenuButton<String>(
                initialValue: _addChecklistCategory,
                icon: Icon(
                  _getChecklistCategoryIcon(_addChecklistCategory),
                  color: Theme.of(context).colorScheme.primary,
                ),
                tooltip: "Seleziona Categoria",
                onSelected: (String cat) {
                  setState(() {
                    _addChecklistCategory = cat;
                  });
                },
                itemBuilder: (context) => [
                  'Bagaglio', 'Documenti', 'Pre-partenza', 'Prenotazioni', 'Acquisti', 'Altro'
                ].map((cat) => PopupMenuItem<String>(
                  value: cat,
                  child: Row(
                    children: [
                      Icon(_getChecklistCategoryIcon(cat), size: 18),
                      const SizedBox(width: 8),
                      Text(cat),
                    ],
                  ),
                )).toList(),
              ),
              const SizedBox(width: 4),
              // Priority flag selection menu
              PopupMenuButton<String>(
                initialValue: _addChecklistPriority,
                icon: Icon(
                  Icons.flag,
                  color: _getPriorityColor(_addChecklistPriority),
                ),
                tooltip: "Seleziona Priorità",
                onSelected: (String prio) {
                  setState(() {
                    _addChecklistPriority = prio;
                  });
                },
                itemBuilder: (context) => [
                  'Bassa', 'Media', 'Alta'
                ].map((prio) => PopupMenuItem<String>(
                  value: prio,
                  child: Row(
                    children: [
                      Icon(Icons.flag, color: _getPriorityColor(prio), size: 18),
                      const SizedBox(width: 8),
                      Text(prio),
                    ],
                  ),
                )).toList(),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: TextField(
                  controller: _checklistController,
                  decoration: InputDecoration(
                    hintText: "Aggiungi a $_addChecklistCategory...",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onSubmitted: (val) {
                    if (val.startsWith(' ')) {
                      _showValidationError("Il testo non può iniziare con uno spazio");
                      return;
                    }
                    if (val.trim().isNotEmpty) {
                      provider.addChecklistItem(
                        ChecklistItem(
                          tripId: provider.selectedTrip!.id!,
                          itemText: val.trim(),
                          category: _addChecklistCategory,
                          priority: _addChecklistPriority,
                        ),
                      );
                      _checklistController.clear();
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.all(12),
                ),
                icon: const Icon(Icons.send),
                onPressed: () {
                  final text = _checklistController.text;
                  if (text.startsWith(' ')) {
                    _showValidationError("Il testo non può iniziare con uno spazio");
                    return;
                  }
                  final trimmed = text.trim();
                  if (trimmed.isNotEmpty) {
                    provider.addChecklistItem(
                      ChecklistItem(
                        tripId: provider.selectedTrip!.id!,
                        itemText: trimmed,
                        category: _addChecklistCategory,
                        priority: _addChecklistPriority,
                      ),
                    );
                    _checklistController.clear();
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // TAB 3: EXPENSES (BUDGET & CHARTS)
  // ==========================================

  void _showDeleteExpenseConfirmation(TravelProvider provider, Expense ex) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Elimina Spesa"),
          content: Text("Sei sicuro di voler eliminare la spesa '${ex.title}'?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annulla"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              onPressed: () {
                provider.deleteExpense(ex.id!);
                Navigator.pop(context);
              },
              child: const Text("Elimina"),
            ),
          ],
        );
      },
    );
  }

  void _showCurrencyConverterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.currency_exchange, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  const Text("Convertitore Valuta"),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _convAmountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: "Importo",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (val) {
                      setDialogState(() {});
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _convFrom,
                          decoration: InputDecoration(
                            labelText: "Da",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: CurrencyService.currencies.map((c) => DropdownMenuItem(
                            value: c.code,
                            child: Text(c.code, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          )).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() {
                                _convFrom = val;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _convTo,
                          decoration: InputDecoration(
                            labelText: "A",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: CurrencyService.currencies.map((c) => DropdownMenuItem(
                            value: c.code,
                            child: Text(c.code, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          )).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() {
                                _convTo = val;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Builder(
                    builder: (context) {
                      final parsed = double.tryParse(_convAmountController.text.replaceAll(',', '.')) ?? 0.0;
                      final converted = CurrencyService.convert(parsed, _convFrom, _convTo);
                      final symbolFrom = CurrencyService.getSymbol(_convFrom);
                      final symbolTo = CurrencyService.getSymbol(_convTo);
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            "$symbolFrom${parsed.toStringAsFixed(2)} $_convFrom = $symbolTo${converted.toStringAsFixed(2)} $_convTo",
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      );
                    }
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Chiudi"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showExpenseDetailsDialog(TravelProvider provider, Expense ex) {
    final localSymbol = CurrencyService.getSymbol(ex.currency);
    final amountInEur = CurrencyService.convert(ex.amount, ex.currency, 'EUR');
    final showEurConv = ex.currency != 'EUR';
    final accentColor = AppTheme.categoryColors[ex.category] ?? Colors.grey;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ex.title,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow("Importo:", "$localSymbol${ex.amount.toStringAsFixed(2)} ${ex.currency}"),
                if (showEurConv)
                  _buildDetailRow("Equivalente EUR:", "€${amountInEur.toStringAsFixed(2)}"),
                _buildDetailRow("Categoria:", ex.category),
                _buildDetailRow("Data:", _formatDate(ex.date)),
                _buildDetailRow("Stato:", ex.status),
                _buildDetailRow("Metodo Pagamento:", ex.paymentMethod),
                _buildDetailRow("Associazione:", "${ex.associatedType}: ${ex.associatedName}"),
                if (ex.notes.isNotEmpty)
                  _buildDetailRow("Note:", ex.notes),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Chiudi"),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.blue),
              tooltip: "Modifica",
              onPressed: () {
                Navigator.pop(context); // Close details dialog
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddExpenseScreen(tripId: provider.selectedTrip!.id!, expense: ex),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              tooltip: "Elimina",
              onPressed: () {
                Navigator.pop(context); // Close details dialog
                _showDeleteExpenseConfirmation(provider, ex);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label ",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpensesTab(TravelProvider provider) {
    final expenses = provider.currentExpenses;
    final budget = provider.totalBudget;

    // Converted EUR values
    final totalSpentActual = provider.totalExpenses;
    final totalSpentPlanned = provider.totalPlannedExpenses;
    final remainingActual = provider.remainingBudget;
    final remainingPlanned = provider.remainingBudgetPlanned;

    final percentSpentActual = budget > 0 ? (totalSpentActual / budget).clamp(0.0, 1.0) : 0.0;
    final percentSpentPlanned = budget > 0 ? (totalSpentPlanned / budget).clamp(0.0, 1.0) : 0.0;

    final isOverBudgetActual = remainingActual < 0;
    final isOverBudgetPlanned = remainingPlanned < 0;

    // Calculate category distribution for actual/sostenute expenses (converted to EUR)
    Map<String, double> catSpent = {};
    for (var ex in expenses) {
      if (ex.status == 'Sostenuta') {
        final amountInEur = CurrencyService.convert(ex.amount, ex.currency, 'EUR');
        catSpent[ex.category] = (catSpent[ex.category] ?? 0.0) + amountInEur;
      }
    }

    // Build list of unique associations for this trip
    final associations = <String>['Tutti', 'Generale'];
    for (var stop in provider.currentStops) {
      associations.add(stop.name);
      final activities = provider.getActivitiesForStop(stop.id!);
      for (var act in activities) {
        associations.add(act.name);
      }
    }

    // Filtered historical expenses
    final filteredExpenses = expenses.where((ex) {
      // 1. Status Filter
      if (_selectedExpenseFilter == 'Sostenute' && ex.status != 'Sostenuta') return false;
      if (_selectedExpenseFilter == 'Previste' && ex.status != 'Prevista') return false;

      // 2. Category Filter
      if (_selectedExpenseCategoryFilter != 'Tutte' && ex.category != _selectedExpenseCategoryFilter) {
        return false;
      }

      // 3. Amount range filter (using EUR amount)
      final amountInEur = CurrencyService.convert(ex.amount, ex.currency, 'EUR');
      if (_selectedExpenseAmountRangeFilter != 'Tutti') {
        if (_selectedExpenseAmountRangeFilter == 'Fino a €50' && amountInEur > 50) return false;
        if (_selectedExpenseAmountRangeFilter == '€50 - €200' && (amountInEur < 50 || amountInEur > 200)) return false;
        if (_selectedExpenseAmountRangeFilter == 'Oltre €200' && amountInEur < 200) return false;
      }

      // 4. Association filter
      if (_selectedExpenseAssociationFilter != 'Tutti') {
        if (_selectedExpenseAssociationFilter == 'Generale') {
          if (ex.associatedType != 'Generale') return false;
        } else {
          if (ex.associatedName != _selectedExpenseAssociationFilter) {
            return false;
          }
        }
      }

      return true;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Riepilogo Budget Card (Actual & Planned Stats)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Riepilogo Budget (Base Euro)",
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.currency_exchange, size: 20),
                        tooltip: "Convertitore Valuta",
                        onPressed: () => _showCurrencyConverterDialog(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Budget Totale Viaggio: €${budget.toStringAsFixed(0)}",
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const Divider(height: 24),

                  // Actual (Sostenute) Stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Speso Effettivo (Sostenuto)", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      Text("€${totalSpentActual.toStringAsFixed(2)}", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentSpentActual,
                      minHeight: 8,
                      backgroundColor: Colors.grey.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isOverBudgetActual ? Colors.redAccent : Colors.green,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isOverBudgetActual ? "Fuori Budget di:" : "Rimanente Effettivo:",
                        style: TextStyle(fontSize: 11, color: isOverBudgetActual ? Colors.redAccent : Colors.grey),
                      ),
                      Text(
                        "€${remainingActual.abs().toStringAsFixed(2)}",
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isOverBudgetActual ? Colors.redAccent : Colors.green),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Planned (Previste) Stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Speso Stimato (Previsto)", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      Text("€${totalSpentPlanned.toStringAsFixed(2)}", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentSpentPlanned,
                      minHeight: 8,
                      backgroundColor: Colors.grey.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isOverBudgetPlanned ? Colors.redAccent : Colors.orange,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isOverBudgetPlanned ? "Fuori Stima Budget di:" : "Rimanente Stimato:",
                        style: TextStyle(fontSize: 11, color: isOverBudgetPlanned ? Colors.redAccent : Colors.grey),
                      ),
                      Text(
                        "€${remainingPlanned.abs().toStringAsFixed(2)}",
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isOverBudgetPlanned ? Colors.redAccent : Colors.orange),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 2. Storico Spese Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Storico Spese",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: Icon(
                  Icons.filter_alt_outlined,
                  color: _selectedExpenseFilter != "Tutte" ||
                          _selectedExpenseCategoryFilter != "Tutte" ||
                          _selectedExpenseAmountRangeFilter != "Tutti" ||
                          _selectedExpenseAssociationFilter != "Tutti"
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).iconTheme.color,
                ),
                tooltip: "Filtri Avanzati",
                onPressed: () {
                  setState(() {
                    _showExpenseFilterPanel = !_showExpenseFilterPanel;
                  });
                },
              ),
            ],
          ),
          if (_showExpenseFilterPanel) ...[
            const SizedBox(height: 8),
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
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedExpenseFilter,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: "Filtra per Stato Spesa",
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: ['Tutte', 'Sostenute', 'Previste'].map((status) => DropdownMenuItem<String>(
                            value: status,
                            child: Text(status),
                          )).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedExpenseFilter = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: _selectedExpenseCategoryFilter,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: "Filtra per Categoria",
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: ['Tutte', 'Trasporto', 'Alloggio', 'Cibo', 'Attività', 'Shopping', 'Spese Mediche', 'Altro'].map((cat) => DropdownMenuItem<String>(
                            value: cat,
                            child: Text(cat),
                          )).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedExpenseCategoryFilter = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: _selectedExpenseAmountRangeFilter,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: "Filtra per Fascia di Importo",
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: ['Tutti', 'Fino a €50', '€50 - €200', 'Oltre €200'].map((range) => DropdownMenuItem<String>(
                            value: range,
                            child: Text(range),
                          )).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedExpenseAmountRangeFilter = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: _selectedExpenseAssociationFilter,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: "Filtra per Elemento Associato",
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: associations.map((assoc) => DropdownMenuItem<String>(
                            value: assoc,
                            child: Text(assoc),
                          )).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedExpenseAssociationFilter = val;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),

          filteredExpenses.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 30),
                    child: Text("Nessuna spesa registrata con questo filtro."),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredExpenses.length,
                  itemBuilder: (context, index) {
                    final ex = filteredExpenses[index];
                    final color = AppTheme.categoryColors[ex.category] ?? Colors.grey;
                    final localSymbol = CurrencyService.getSymbol(ex.currency);
                    final amountInEur = CurrencyService.convert(ex.amount, ex.currency, 'EUR');
                    final showEurConv = ex.currency != 'EUR';

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        onTap: () => _showExpenseDetailsDialog(provider, ex),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            localSymbol,
                            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        title: Text(ex.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${ex.category} • ${_formatDate(ex.date)}",
                              style: const TextStyle(fontSize: 11),
                            ),
                            if (ex.notes.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                "Note: ${ex.notes}",
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "- $localSymbol${ex.amount.toStringAsFixed(2)}",
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                color: ex.status == 'Sostenuta' ? Colors.redAccent : Colors.orange,
                                fontSize: 14,
                              ),
                            ),
                            if (showEurConv)
                              Text(
                                "(- €${amountInEur.toStringAsFixed(2)})",
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: ex.status == 'Sostenuta'
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                ex.status,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: ex.status == 'Sostenuta' ? Colors.green : Colors.orange,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

          const SizedBox(height: 24),

          // 3. Ripartizione Spese Effettive Section
          if (expenses.any((e) => e.status == 'Sostenuta')) ...[
            Text(
              "Ripartizione Spese Effettive",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: AppTheme.categoryColors.keys.map((category) {
                    final spent = catSpent[category] ?? 0.0;
                    final fraction = totalSpentActual > 0 ? (spent / totalSpentActual) : 0.0;
                    if (spent == 0.0) return const SizedBox.shrink();

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: AppTheme.categoryColors[category],
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(category, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                                ],
                              ),
                              Text("€${spent.toStringAsFixed(2)} (${(fraction * 100).toStringAsFixed(0)}%)", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: fraction,
                              minHeight: 6,
                              backgroundColor: Colors.grey.withOpacity(0.1),
                              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.categoryColors[category]!),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],

          // Prevent FAB overlapping with bottom elements
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Color _getUsefulInfoCategoryColor(String category) {
    switch (category) {
      case 'Nota':
        return Colors.amber;
      case 'Promemoria':
        return Colors.deepOrange;
      case 'Prenotazione':
        return Colors.blue;
      case 'Indirizzo':
        return Colors.green;
      case 'Altro':
      default:
        return Colors.teal;
    }
  }

  IconData _getUsefulInfoCategoryIcon(String category) {
    switch (category) {
      case 'Nota':
        return Icons.note_alt_outlined;
      case 'Promemoria':
        return Icons.notification_important_outlined;
      case 'Prenotazione':
        return Icons.confirmation_number_outlined;
      case 'Indirizzo':
        return Icons.map_outlined;
      case 'Altro':
      default:
        return Icons.info_outline;
    }
  }

  Widget _buildUsefulInfoTab(TravelProvider provider) {
    final list = provider.currentUsefulInfo;

    // Filter list by selected category
    final filteredList = _selectedUsefulInfoCategory == 'Tutti'
        ? list
        : list.where((item) => item.category == _selectedUsefulInfoCategory).toList();

    return Column(
      children: [
        // Category Filter Dropdown
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedUsefulInfoCategory,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: "Categoria",
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: [
                    'Tutti', 'Nota', 'Promemoria', 'Prenotazione', 'Indirizzo', 'Altro'
                  ].map((cat) => DropdownMenuItem<String>(
                        value: cat,
                        child: Text(cat),
                      )).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedUsefulInfoCategory = val;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ),

        // Info List
        Expanded(
          child: filteredList.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 64,
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Nessuna info utile in questa categoria.",
                          style: Theme.of(context).textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Aggiungi note, promemoria, prenotazioni o indirizzi con il pulsante in basso.",
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: filteredList.length + 1,
                  itemBuilder: (context, index) {
                    if (index == filteredList.length) {
                      return const SizedBox(height: 80);
                    }
                    final info = filteredList[index];
                    final accentColor = _getUsefulInfoCategoryColor(info.category);
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: Theme.of(context).dividerColor.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(
                              color: accentColor,
                              width: 6,
                            ),
                          ),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Category Badge
                                Row(
                                  children: [
                                    Icon(
                                      _getUsefulInfoCategoryIcon(info.category),
                                      color: accentColor,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: accentColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        info.category,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: accentColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                // Edit & Delete Actions
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.blue),
                                      onPressed: () => _showAddEditUsefulInfoDialog(provider, info),
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.all(6),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                                      onPressed: () => _showDeleteUsefulInfoConfirmation(provider, info),
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.all(6),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              info.title,
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              info.content,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                height: 1.4,
                              ),
                            ),
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

  void _showAddEditUsefulInfoDialog(TravelProvider provider, [UsefulInfo? info]) {
    final isEditing = info != null;
    final titleController = TextEditingController(text: info?.title ?? '');
    final contentController = TextEditingController(text: info?.content ?? '');
    String selectedCategory = info?.category ?? 'Nota';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEditing ? "Modifica Info Utile" : "Nuova Info Utile"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: "Titolo *",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: contentController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: "Contenuto / Dettagli *",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: InputDecoration(
                        labelText: "Categoria",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: ['Nota', 'Promemoria', 'Prenotazione', 'Indirizzo', 'Altro']
                          .map((cat) => DropdownMenuItem<String>(
                                value: cat,
                                child: Row(
                                  children: [
                                    Icon(_getUsefulInfoCategoryIcon(cat), size: 18, color: _getUsefulInfoCategoryColor(cat)),
                                    const SizedBox(width: 8),
                                    Text(cat),
                                  ],
                                ),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            selectedCategory = val;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Annulla"),
                ),
                ElevatedButton(
                  onPressed: () {
                    final title = titleController.text;
                    final content = contentController.text;

                    // Leading space validation
                    if (title.startsWith(' ') || content.startsWith(' ')) {
                      _showValidationError("Il testo non può iniziare con uno spazio");
                      return;
                    }

                    final trimmedTitle = title.trim();
                    final trimmedContent = content.trim();

                    if (trimmedTitle.isEmpty || trimmedContent.isEmpty) {
                      _showValidationError("Titolo e Contenuto sono obbligatori");
                      return;
                    }

                    if (isEditing) {
                      provider.updateUsefulInfo(
                        info.copyWith(
                          title: trimmedTitle,
                          content: trimmedContent,
                          category: selectedCategory,
                        ),
                      );
                    } else {
                      provider.addUsefulInfo(
                        UsefulInfo(
                          tripId: provider.selectedTrip!.id!,
                          title: trimmedTitle,
                          content: trimmedContent,
                          category: selectedCategory,
                        ),
                      );
                    }
                    Navigator.pop(context);
                  },
                  child: const Text("Salva"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteUsefulInfoConfirmation(TravelProvider provider, UsefulInfo info) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Elimina Info Utile"),
          content: Text("Sei sicuro di voler eliminare '${info.title}'?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annulla"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              onPressed: () {
                provider.deleteUsefulInfo(info.id!);
                Navigator.pop(context);
              },
              child: const Text("Elimina"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTripInfoSection(BuildContext context, Trip trip) {
    final hasParticipants = trip.participants.isNotEmpty;
    final hasGeneralInfo = trip.generalInfo.isNotEmpty;
    final hasCoords = trip.latitude != null && trip.longitude != null;

    if (!hasParticipants && !hasGeneralInfo && !hasCoords) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        color: Theme.of(context).cardColor,
        child: InkWell(
          onTap: () {
            setState(() {
              _isInfoExpanded = !_isInfoExpanded;
            });
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          "Informazioni di Viaggio",
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ],
                    ),
                    Icon(
                      _isInfoExpanded ? Icons.expand_less : Icons.expand_more,
                      color: Colors.grey,
                    ),
                  ],
                ),
                if (!_isInfoExpanded && hasParticipants) ...[
                  const SizedBox(height: 6),
                  Text(
                    "Partecipanti: ${trip.participants}",
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (_isInfoExpanded) ...[
                  const SizedBox(height: 12),
                  if (hasParticipants) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.people_outline, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Partecipanti:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                              const SizedBox(height: 2),
                              Text(trip.participants, style: const TextStyle(fontSize: 14)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (hasGeneralInfo) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.notes, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Info Utili Generali:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                              const SizedBox(height: 2),
                              Text(trip.generalInfo, style: const TextStyle(fontSize: 14)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (hasCoords) ...[
                    Row(
                      children: [
                        const Icon(Icons.map_outlined, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Posizione: ${trip.latitude!.toStringAsFixed(3)}°, ${trip.longitude!.toStringAsFixed(3)}°",
                            style: const TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            final url = Uri.parse(
                              'https://www.google.com/maps/search/?api=1&query=${trip.latitude},${trip.longitude}',
                            );
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url, mode: LaunchMode.externalApplication);
                            } else {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Impossibile aprire la mappa")),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.map, size: 16),
                          label: const Text("Vedi Mappa", style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverAppBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overridesParent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar;
  }
}

