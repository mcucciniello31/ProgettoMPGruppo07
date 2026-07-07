import 'package:flutter/material.dart';
import '../../../models/stop.dart';
import '../../../models/activity.dart';
import '../../../models/trip.dart';
import '../../../providers/travel_provider.dart';
import '../../../theme/app_theme.dart';
import 'add_stop_screen.dart';

class ItineraryTab extends StatefulWidget {
  final TravelProvider provider;

  const ItineraryTab({super.key, required this.provider});

  @override
  State<ItineraryTab> createState() => _ItineraryTabState();
}

class _ItineraryTabState extends State<ItineraryTab> {
  String _searchStopLocation = "";
  DateTime? _selectedStopDate;
  String _selectedActivityCategoryFilter = "Tutti";
  bool _isCalendarView = false;

  String _formatDate(DateTime dt) {
    return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
  }

  List<DateTime> _getTripMonths(DateTime start, DateTime end) {
    List<DateTime> months = [];
    DateTime current = DateTime(start.year, start.month, 1);
    DateTime last = DateTime(end.year, end.month, 1);
    while (!current.isAfter(last)) {
      months.add(current);
      current = DateTime(current.year, current.month + 1, 1);
    }
    return months;
  }

  void _showDeleteActivityConfirmation(
    BuildContext context,
    TravelProvider provider,
    Activity activity,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Elimina Attività"),
          content: Text(
            "Sei sicuro di voler eliminare l'attività '${activity.name}'?",
          ),
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
              child: const Text(
                "Elimina",
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActivityRow(
    BuildContext context,
    Activity activity,
    TravelProvider provider,
  ) {
    final statusColor = activity.status == 'Completata'
        ? Colors.green
        : activity.status == 'Annullata'
        ? Colors.redAccent
        : Theme.of(context).colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.05),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            AppTheme.activityIcons[activity.type] ?? Icons.explore,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        activity.name,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        activity.status,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      activity.time,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    if (activity.location.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.location_on,
                        size: 12,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          activity.location,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (activity.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    activity.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.color?.withOpacity(0.8),
                    ),
                  ),
                ],
                if (activity.notes.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.bookmark_border,
                        size: 12,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          activity.notes,
                          style: const TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (activity.cost > 0)
                Text(
                  "€${activity.cost.toStringAsFixed(2).replaceAll('.', ',')}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                )
              else
                const Text(
                  "Gratis",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.green,
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.edit_outlined,
                      color: Colors.blue,
                      size: 16,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddStopScreen(
                            tripId: provider.selectedTrip!.id!,
                            parentStop: provider.currentStops.firstWhere(
                              (s) => s.id == activity.stopId,
                            ),
                            activity: activity,
                          ),
                        ),
                      );
                    },
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                      size: 16,
                    ),
                    onPressed: () => _showDeleteActivityConfirmation(
                      context,
                      provider,
                      activity,
                    ),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDayDetailsBottomSheet(
    DateTime date,
    List<Stop> dayStops,
    TravelProvider provider,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(context).dividerColor.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Dettagli del ${_formatDate(date)}",
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  if (dayStops.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 48,
                              color: Theme.of(
                                context,
                              ).hintColor.withOpacity(0.5),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "Nessuna tappa per questo giorno",
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 16,
                                color: Theme.of(context).hintColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: dayStops.length,
                        itemBuilder: (context, sIndex) {
                          final stop = dayStops[sIndex];
                          final stopActivities = provider.getActivitiesForStop(
                            stop.id!,
                          );
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            elevation: 0,
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.04),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.1),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          stop.name,
                                          style: const TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      if (stop.notes.isNotEmpty)
                                        Icon(
                                          Icons.notes,
                                          size: 18,
                                          color: Theme.of(context).hintColor,
                                        ),
                                    ],
                                  ),
                                  if (stop.location.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.location_on,
                                          size: 14,
                                          color: Theme.of(context).hintColor,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            stop.location,
                                            style: TextStyle(
                                              fontFamily: 'Outfit',
                                              fontSize: 13,
                                              color: Theme.of(
                                                context,
                                              ).hintColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  if (stop.notes.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      stop.notes,
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 13,
                                        fontStyle: FontStyle.italic,
                                        color: Theme.of(context).hintColor,
                                      ),
                                    ),
                                  ],
                                  const Divider(height: 20),
                                  if (stopActivities.isEmpty)
                                    Text(
                                      "Nessuna attività programmata",
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 13,
                                        fontStyle: FontStyle.italic,
                                        color: Theme.of(context).hintColor,
                                      ),
                                    )
                                  else ...[
                                    const Text(
                                      "Attività:",
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Column(
                                      children: stopActivities.map((act) {
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 6,
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Icon(
                                                Icons.check_circle_outline,
                                                size: 14,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  "${act.time} - ${act.name} (${act.type})",
                                                  style: const TextStyle(
                                                    fontFamily: 'Outfit',
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ),
                                              if (act.cost > 0)
                                                Text(
                                                  "${act.cost.toStringAsFixed(2)} €",
                                                  style: const TextStyle(
                                                    fontFamily: 'Outfit',
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMonthCalendar(
    DateTime monthDate,
    Trip trip,
    List<Stop> stops,
    TravelProvider provider,
  ) {
    final year = monthDate.year;
    final month = monthDate.month;
    final firstDayOfMonth = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final offset =
        firstDayOfMonth.weekday - 1; // 0 indica Lunedì, 6 indica Domenica

    final monthNames = [
      "",
      "Gennaio",
      "Febbraio",
      "Marzo",
      "Aprile",
      "Maggio",
      "Giugno",
      "Luglio",
      "Agosto",
      "Settembre",
      "Ottobre",
      "Novembre",
      "Dicembre",
    ];
    final monthName = monthNames[month];

    final weekDays = ["Lun", "Mar", "Mer", "Gio", "Ven", "Sab", "Dom"];

    final tripStart = DateTime(
      trip.startDate.year,
      trip.startDate.month,
      trip.startDate.day,
    );
    final tripEnd = DateTime(
      trip.endDate.year,
      trip.endDate.month,
      trip.endDate.day,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withOpacity(0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "$monthName $year",
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: weekDays.map((day) {
                return SizedBox(
                  width: 32,
                  child: Center(
                    child: Text(
                      day,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: offset + daysInMonth,
              itemBuilder: (context, index) {
                if (index < offset) {
                  return const SizedBox.shrink();
                }

                final dayNumber = index - offset + 1;
                final dayDate = DateTime(year, month, dayNumber);

                final isWithinTrip =
                    !dayDate.isBefore(tripStart) && !dayDate.isAfter(tripEnd);

                final dayStops = stops.where((stop) {
                  final sDate = stop.dateTime;
                  return sDate.year == year &&
                      sDate.month == month &&
                      sDate.day == dayNumber;
                }).toList();

                final hasStops = dayStops.isNotEmpty;

                return GestureDetector(
                  onTap: () {
                    _showDayDetailsBottomSheet(dayDate, dayStops, provider);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isWithinTrip
                          ? (hasStops
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(
                                    context,
                                  ).colorScheme.primary.withOpacity(0.15))
                          : Colors.transparent,
                      border:
                          isWithinTrip &&
                              DateTime.now().year == year &&
                              DateTime.now().month == month &&
                              DateTime.now().day == dayNumber
                          ? Border.all(
                              color: Theme.of(context).colorScheme.secondary,
                              width: 2,
                            )
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        "$dayNumber",
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13,
                          fontWeight: isWithinTrip
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isWithinTrip
                              ? (hasStops
                                    ? Colors.white
                                    : Theme.of(
                                        context,
                                      ).colorScheme.onBackground)
                              : Theme.of(context).hintColor.withOpacity(0.4),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItineraryCalendarView(TravelProvider provider) {
    final trip = provider.selectedTrip!;
    final stops = provider.currentStops;
    final months = _getTripMonths(trip.startDate, trip.endDate);

    return ListView.builder(
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: months.length,
      itemBuilder: (context, index) {
        final monthDate = months[index];
        return _buildMonthCalendar(monthDate, trip, stops, provider);
      },
    );
  }

  Widget _buildItineraryToggle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).dividerColor.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isCalendarView = false;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: !_isCalendarView
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.list_alt,
                          size: 18,
                          color: !_isCalendarView
                              ? Colors.white
                              : Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "Vista Elenco",
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w600,
                            color: !_isCalendarView
                                ? Colors.white
                                : Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isCalendarView = true;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: _isCalendarView
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_month,
                          size: 18,
                          color: _isCalendarView
                              ? Colors.white
                              : Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "Vista Calendario",
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w600,
                            color: _isCalendarView
                                ? Colors.white
                                : Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    final stops = provider.currentStops;

    // Filtra le tappe per posizione, nome, data e categoria delle attività contenute
    final filteredStops = stops.where((stop) {
      if (_searchStopLocation.isNotEmpty &&
          !stop.location.toLowerCase().contains(
            _searchStopLocation.toLowerCase(),
          ) &&
          !stop.name.toLowerCase().contains(
            _searchStopLocation.toLowerCase(),
          )) {
        return false;
      }
      if (_selectedStopDate != null) {
        final stopDay = DateTime(
          stop.dateTime.year,
          stop.dateTime.month,
          stop.dateTime.day,
        );
        final filterDay = DateTime(
          _selectedStopDate!.year,
          _selectedStopDate!.month,
          _selectedStopDate!.day,
        );
        if (stopDay != filterDay) {
          return false;
        }
      }
      if (_selectedActivityCategoryFilter != 'Tutti') {
        final activities = provider.getActivitiesForStop(stop.id!);
        final hasMatch = activities.any(
          (a) => a.type == _selectedActivityCategoryFilter,
        );
        if (!hasMatch) {
          return false;
        }
      }
      return true;
    }).toList();

    return Column(
      children: [
        // Selettore della vista: Vista Elenco vs Vista Calendario
        _buildItineraryToggle(),

        if (_isCalendarView)
          Expanded(child: _buildItineraryCalendarView(provider))
        else ...[
          // Filtri di ricerca per la vista ad elenco
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Cerca luogo o tappa...",
                      prefixIcon: const Icon(Icons.search, size: 20),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchStopLocation = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  initialValue: _selectedActivityCategoryFilter,
                  offset: const Offset(0, 30),
                  onSelected: (String value) {
                    setState(() {
                      _selectedActivityCategoryFilter = value;
                    });
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                          value: 'Tutti',
                          child: Text("Tutte le attività"),
                        ),
                        ...AppTheme.activityIcons.keys.map(
                          (type) => PopupMenuItem<String>(
                            value: type,
                            child: Row(
                              children: [
                                Icon(
                                  AppTheme.activityIcons[type],
                                  size: 16,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(type),
                              ],
                            ),
                          ),
                        ),
                      ],
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedActivityCategoryFilter == 'Tutti'
                            ? "Tutte le attività"
                            : _selectedActivityCategoryFilter,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.filter_list,
                        color: _selectedActivityCategoryFilter != 'Tutti'
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: filteredStops.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.map_outlined,
                          size: 64,
                          color: Theme.of(context).hintColor.withOpacity(0.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Nessuna tappa corrisponde ai filtri",
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 16,
                            color: Theme.of(context).hintColor,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                    itemCount: filteredStops.length,
                    itemBuilder: (context, index) {
                      final stop = filteredStops[index];
                      final activities = provider.getActivitiesForStop(
                        stop.id!,
                      );

                      // Filtra le attività all'interno della tappa in base al filtro selezionato
                      final displayActivities =
                          _selectedActivityCategoryFilter == 'Tutti'
                          ? activities
                          : activities
                                .where(
                                  (a) =>
                                      a.type == _selectedActivityCategoryFilter,
                                )
                                .toList();

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Theme(
                          data: Theme.of(
                            context,
                          ).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            tilePadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: Icon(
                              Icons.location_on_outlined,
                              color: Theme.of(context).colorScheme.primary,
                              size: 28,
                            ),
                            title: Text(
                              "Giorno ${stop.itineraryOrder} • ${stop.name}",
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.access_time,
                                      size: 12,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "${_formatDate(stop.dateTime)} - ${stop.dateTime.hour.toString().padLeft(2, '0')}:${stop.dateTime.minute.toString().padLeft(2, '0')}",
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                if (stop.location.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on_outlined,
                                        size: 12,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          stop.location,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    color: Colors.blue,
                                  ),
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
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.all(8),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.redAccent,
                                  ),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) {
                                        return AlertDialog(
                                          title: const Text("Elimina Tappa"),
                                          content: Text(
                                            "Sei sicuro di voler eliminare la tappa '${stop.name}' e tutte le sue attività?",
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx),
                                              child: const Text("Annulla"),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(ctx);
                                                provider.deleteStop(stop.id!);
                                              },
                                              child: const Text(
                                                "Elimina",
                                                style: TextStyle(
                                                  color: Colors.redAccent,
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.all(8),
                                ),
                              ],
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  16,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    if (stop.description.isNotEmpty) ...[
                                      Text(
                                        stop.description,
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 14,
                                          color: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.color
                                              ?.withOpacity(0.85),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                    if (stop.notes.isNotEmpty) ...[
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.withOpacity(
                                            0.05,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: Colors.orange.withOpacity(
                                              0.15,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Icon(
                                              Icons.sticky_note_2_outlined,
                                              color: Colors.orange,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                stop.notes,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontStyle: FontStyle.italic,
                                                  color: Colors.orange,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                    ],
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "Attività programmate (${displayActivities.length})",
                                          style: const TextStyle(
                                            fontFamily: 'Outfit',
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                        TextButton.icon(
                                          icon: const Icon(Icons.add, size: 16),
                                          label: const Text(
                                            "Nuova Attività",
                                            style: TextStyle(fontSize: 12),
                                          ),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    AddStopScreen(
                                                      tripId: provider
                                                          .selectedTrip!
                                                          .id!,
                                                      parentStop: stop,
                                                    ),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    if (displayActivities.isEmpty)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8,
                                        ),
                                        child: Text(
                                          "Nessuna attività registrata",
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontStyle: FontStyle.italic,
                                            color: Theme.of(context).hintColor,
                                          ),
                                        ),
                                      )
                                    else
                                      ...displayActivities.map(
                                        (act) => _buildActivityRow(
                                          context,
                                          act,
                                          provider,
                                        ),
                                      ),
                                  ],
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
      ],
    );
  }
}
