import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/travel_provider.dart';
import '../models/trip.dart';
import '../models/stop.dart';
import '../models/activity.dart';
import '../models/checklist_item.dart';
import '../models/useful_info.dart';
import '../models/expense.dart';
import '../theme/app_theme.dart';
import '../services/currency_service.dart';
import 'add_stop_screen.dart';
import 'add_expense_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/diary_entry.dart';
import '../models/travel_document.dart';
import '../widgets/offline_code_painters.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class TripDetailsScreen extends StatefulWidget {
  const TripDetailsScreen({super.key});

  @override
  State<TripDetailsScreen> createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends State<TripDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _checklistController = TextEditingController();
  bool _isInfoExpanded = false;

  // Variabili per il filtraggio e la ricerca della checklist
  String _selectedChecklistCategory = 'Tutti';
  String _addChecklistCategory = 'Bagaglio';
  String _addChecklistPriority = 'Media';
  String _selectedChecklistStatusFilter = "Tutti"; // Opzioni: Tutti, Da completare, Completati
  String _selectedChecklistPriorityFilter = "Tutte"; // Opzioni: Tutte, Bassa, Media, Alta

  // Variabili per il filtraggio e la ricerca delle info utili
  String _selectedUsefulInfoCategory = 'Tutti';

  // Variabili per il filtraggio e la ricerca delle spese
  String _selectedExpenseFilter = 'Tutte';
  bool _showExpenseFilterPanel = false;
  String _selectedExpenseCategoryFilter = "Tutte";
  String _selectedExpenseAmountRangeFilter = "Tutti";
  String _selectedExpenseAssociationFilter = "Tutti";
  final TextEditingController _convAmountController = TextEditingController(text: '100');
  String _convFrom = 'EUR';
  String _convTo = 'USD';

  // Variabili per il filtraggio e la ricerca dell'itinerario
  String _searchStopLocation = "";
  DateTime? _selectedStopDate;
  String _selectedActivityCategoryFilter = "Tutti";
  bool _isCalendarView = false;
  String _infoSubTab = 'Note'; // 'Note' oppure 'Biglietti'

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
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Ricostruisce l'interfaccia per cambiare l'azione del FAB in base alla scheda attiva
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
    // Restituisce direttamente il formato dell'orario HH:mm
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
                      // 1. Intestazione premium con titolo, budget e copertina del viaggio
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
                            image: trip.coverImagePath != null &&
                                    trip.coverImagePath!.isNotEmpty &&
                                    File(trip.coverImagePath!).existsSync()
                                ? DecorationImage(
                                    image: FileImage(File(trip.coverImagePath!)),
                                    fit: BoxFit.cover,
                                    colorFilter: ColorFilter.mode(
                                      Colors.black.withOpacity(0.45),
                                      BlendMode.darken,
                                    ),
                                  )
                                : null,
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
                                    Expanded(
                                      child: Center(
                                        child: Text(
                                          trip.destination,
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.9),
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.ios_share, color: Colors.white),
                                      tooltip: "Esporta Viaggio",
                                      onPressed: () => _showExportTripDialog(context, provider),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  trip.title,
                                  style: const TextStyle(
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

                      // Pannello a comparsa contenente i dettagli riassuntivi del viaggio
                      _buildTripInfoSection(context, trip),
                    ] else ...[
                      // Intestazione compatta per risparmiare spazio quando la tastiera è aperta
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
                                style: TextStyle(
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
                    isScrollable: false,
                    indicatorColor: Theme.of(context).colorScheme.primary,
                    labelColor: Theme.of(context).colorScheme.onBackground,
                    unselectedLabelColor: Theme.of(context).textTheme.bodyMedium?.color,
                    labelPadding: EdgeInsets.zero,
                    labelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    unselectedLabelStyle: const TextStyle(fontSize: 10),
                    tabs: const [
                      Tab(icon: Icon(Icons.map_outlined, size: 20), text: "Itinerario"),
                      Tab(icon: Icon(Icons.checklist_outlined, size: 20), text: "Checklist"),
                      Tab(icon: Icon(Icons.euro_outlined, size: 20), text: "Spese"),
                      Tab(icon: Icon(Icons.photo_library_outlined, size: 20), text: "Diario"),
                      Tab(icon: Icon(Icons.info_outline, size: 20), text: "Info Utili"),
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
              _buildDiaryTab(provider),
              _buildUsefulInfoTab(provider),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFAB(provider),
    );
  }

  // ==========================================
  // COSTRUTTORE DINAMICO DEL PULSANTE FAB
  // ==========================================

  Widget? _buildFAB(TravelProvider provider) {
    if (MediaQuery.of(context).viewInsets.bottom > 0) {
      return null;
    }
    if (_tabController.index == 0) {
      // Pulsante FAB per la scheda Itinerario: permette di aggiungere una Tappa
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
      // Pulsante FAB per la scheda Spese: permette di registrare un'uscita
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
      // Pulsante FAB per la scheda Diario: permette di scrivere un Ricordo
      return FloatingActionButton.extended(
        key: const ValueKey('fab_diary'),
        onPressed: () {
          _showAddEditDiaryDialog(context, null);
        },
        icon: const Icon(Icons.add_photo_alternate_outlined),
        label: const Text("Nuovo Ricordo"),
      );
    } else if (_tabController.index == 4) {
      // Pulsante FAB per la scheda Info Utili: permette di aggiungere Note o Biglietti
      if (_infoSubTab == 'Biglietti') {
        return FloatingActionButton.extended(
          key: const ValueKey('fab_travel_tickets'),
          onPressed: () {
            _showAddEditTravelDocumentDialog(context, provider, null);
          },
          icon: const Icon(Icons.add_card_outlined),
          label: const Text("Aggiungi Biglietto"),
        );
      } else {
        return FloatingActionButton.extended(
          key: const ValueKey('fab_useful_info'),
          onPressed: () {
            _showAddEditUsefulInfoDialog(provider);
          },
          icon: const Icon(Icons.add_comment_outlined),
          label: const Text("Nuova Info"),
        );
      }
    }
    // La checklist usa la barra di inserimento in basso, non ha bisogno del pulsante FAB
    return null;
  }

  // ==========================================
  // SCHEDA 1: ITINERARIO (VISTA LINEARE DELLE TAPPE)
  // ==========================================

  Widget _buildItineraryTab(TravelProvider provider) {
    final stops = provider.currentStops;

    // Filtra le tappe per posizione, nome, data e categoria delle attività contenute
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
        _buildItineraryToggle(),
        if (_isCalendarView)
          Expanded(child: _buildItineraryCalendarView(provider))
        else if (stops.isEmpty)
          Expanded(
            child: Center(
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
            ),
          )
        else ...[
        // Pannello a scomparsa per cercare e filtrare le spese
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: "Cerca per località",
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

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Scheda contenente la singola tappa dell'itinerario
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

                        // Lista delle singole attività programmate per questa tappa
                        if (activities.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 12, bottom: 16),
                            child: Column(
                              children: activities.map((act) => _buildActivityRow(context, act, provider)).toList(),
                            ),
                          ),
                      ],
                    );
      },
    ),
  ),
]
],
);
}

  Widget _buildActivityRow(BuildContext context, Activity activity, TravelProvider provider) {
    final categoryIcon = AppTheme.activityIcons[activity.type] ?? Icons.local_activity;

    // Determina il colore e l'icona in base allo stato
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
                // 1. Icona che mostra lo stato corrente ed apre il menu a discesa
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
                // 2. Icona della categoria associata
                Icon(categoryIcon, size: 16, color: Theme.of(context).colorScheme.secondary),
                const SizedBox(width: 8),
                // 3. Orario e Titolo dell'attività
                Expanded(
                  child: Text(
                    "${activity.time} • ${activity.name}",
                    style: textStyle,
                  ),
                ),
                // 4. Costo dell'attività
                if (activity.cost > 0) ...[
                  Text(
                    "€${activity.cost.toStringAsFixed(2).replaceAll('.', ',')}",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(width: 4),
                ],
                // 5. Azioni (Modifica / Elimina)
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
            
            // Dettagli secondari visualizzati dentro la scheda
            Padding(
              padding: const EdgeInsets.only(left: 36.0, top: 2.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Località
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
                  // Descrizione
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
                  // Note
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
  // SCHEDA 2: CHECKLIST E BAGAGLI
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

  // ==========================================
  // FUNZIONI DI SUPPORTO PER IL CALENDARIO DELL'ITINERARIO
  // ==========================================

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

  Widget _buildMonthCalendar(DateTime monthDate, Trip trip, List<Stop> stops, TravelProvider provider) {
    final year = monthDate.year;
    final month = monthDate.month;
    final firstDayOfMonth = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final offset = firstDayOfMonth.weekday - 1; // 0 indica Lunedì, 6 indica Domenica

    final monthNames = [
      "", "Gennaio", "Febbraio", "Marzo", "Aprile", "Maggio", "Giugno",
      "Luglio", "Agosto", "Settembre", "Ottobre", "Novembre", "Dicembre"
    ];
    final monthName = monthNames[month];

    final weekDays = ["Lun", "Mar", "Mer", "Gio", "Ven", "Sab", "Dom"];

    final tripStart = DateTime(trip.startDate.year, trip.startDate.month, trip.startDate.day);
    final tripEnd = DateTime(trip.endDate.year, trip.endDate.month, trip.endDate.day);

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1)),
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

                final isWithinTrip = !dayDate.isBefore(tripStart) && !dayDate.isAfter(tripEnd);

                final dayStops = stops.where((stop) {
                  final sDate = stop.dateTime;
                  return sDate.year == year && sDate.month == month && sDate.day == dayNumber;
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
                          ? Theme.of(context).colorScheme.primary.withOpacity(0.12)
                          : Colors.transparent,
                      border: Border.all(
                        color: hasStops
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "$dayNumber",
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 14,
                              fontWeight: isWithinTrip || hasStops ? FontWeight.bold : FontWeight.normal,
                              color: isWithinTrip
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                          if (hasStops)
                            Container(
                              width: 4,
                              height: 4,
                              margin: const EdgeInsets.only(top: 2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                        ],
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

  void _showDayDetailsBottomSheet(DateTime date, List<Stop> dayStops, TravelProvider provider) {
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
                              color: Theme.of(context).hintColor.withOpacity(0.5),
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
                          final stopActivities = provider.getActivitiesForStop(stop.id!);
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            elevation: 0,
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.04),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.1)),
                            ),
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
                                          stop.name,
                                          style: const TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      if (stop.notes.isNotEmpty)
                                        Icon(Icons.notes, size: 18, color: Theme.of(context).hintColor),
                                    ],
                                  ),
                                  if (stop.location.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.location_on, size: 14, color: Theme.of(context).hintColor),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            stop.location,
                                            style: TextStyle(
                                              fontFamily: 'Outfit',
                                              fontSize: 13,
                                              color: Theme.of(context).hintColor,
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
                                          padding: const EdgeInsets.only(bottom: 6),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Icon(
                                                Icons.check_circle_outline,
                                                size: 14,
                                                color: Theme.of(context).colorScheme.primary,
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
                          color: !_isCalendarView ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "Vista Elenco",
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w600,
                            color: !_isCalendarView ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
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
                          color: _isCalendarView ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "Vista Calendario",
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w600,
                            color: _isCalendarView ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
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

  Widget _buildChecklistTab(TravelProvider provider) {
    final list = provider.currentChecklist;
    
    // Filtra la lista della checklist per categoria, stato e priorità
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

    // La percentuale di avanzamento della checklist si adatta ai filtri correnti
    final categoryOnlyList = _selectedChecklistCategory == 'Tutti'
        ? list
        : list.where((item) => item.category == _selectedChecklistCategory).toList();

    final categoryCheckedCount = categoryOnlyList.where((i) => i.isChecked).length;
    final categoryRate = categoryOnlyList.isEmpty ? 0.0 : categoryCheckedCount / categoryOnlyList.length;

    final overallCheckedCount = list.where((i) => i.isChecked).length;
    final overallRate = list.isEmpty ? 0.0 : overallCheckedCount / list.length;

    return Column(
      children: [
        // Menu a discesa per filtrare gli elementi per categoria, stato e priorità
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
                        // Aggiorna la categoria predefinita all'aggiunta se è selezionato un filtro specifico
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

        // Scheda visuale dello stato di avanzamento
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
                        style: TextStyle(
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

        // Elementi visualizzati per la checklist
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

        // Casella di inserimento rapido per la checklist posta in basso
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
              // Menu a discesa per selezionare l'icona per le nuove categorie
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
              // Menu per selezionare la priorità del bagaglio/promemoria
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
                    hintText: _addChecklistCategory,
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
  // SCHEDA 3: SPESE (ANALISI BUDGET E GRAFICI)
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
                            style: TextStyle(
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
                  style: const TextStyle(fontWeight: FontWeight.bold),
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
                Navigator.pop(context); // Chiude la finestra di dialogo dei dettagli
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
                Navigator.pop(context); // Chiude la finestra di dialogo dei dettagli
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

    // Valori monetari convertiti in EUR
    final totalSpentActual = provider.totalExpenses;
    final totalSpentPlanned = provider.totalPlannedExpenses;
    final remainingActual = provider.remainingBudget;
    final remainingPlanned = provider.remainingBudgetPlanned;

    final percentSpentActual = budget > 0 ? (totalSpentActual / budget).clamp(0.0, 1.0) : 0.0;
    final percentSpentPlanned = budget > 0 ? (totalSpentPlanned / budget).clamp(0.0, 1.0) : 0.0;

    final isOverBudgetActual = remainingActual < 0;
    final isOverBudgetPlanned = remainingPlanned < 0;

    // Calcola la percentuale di spesa per ciascuna categoria (spese sostenute convertite in EUR)
    Map<String, double> catSpent = {};
    for (var ex in expenses) {
      if (ex.status == 'Sostenuta') {
        final amountInEur = CurrencyService.convert(ex.amount, ex.currency, 'EUR');
        catSpent[ex.category] = (catSpent[ex.category] ?? 0.0) + amountInEur;
      }
    }

    // Costruisce la lista di tappe e attività collegate a questo viaggio per i filtri
    final associations = <String>['Tutti', 'Generale'];
    for (var stop in provider.currentStops) {
      associations.add(stop.name);
      final activities = provider.getActivitiesForStop(stop.id!);
      for (var act in activities) {
        associations.add(act.name);
      }
    }

    // Elenco delle transazioni registrate storiche che corrispondono ai filtri selezionati
    final filteredExpenses = expenses.where((ex) {
      // 1. Filtro di stato del viaggio
      if (_selectedExpenseFilter == 'Sostenute' && ex.status != 'Sostenuta') return false;
      if (_selectedExpenseFilter == 'Previste' && ex.status != 'Prevista') return false;

      // 2. Filtro per categoria delle spese
      if (_selectedExpenseCategoryFilter != 'Tutte' && ex.category != _selectedExpenseCategoryFilter) {
        return false;
      }

      // 3. Filtro per range di spesa (basato sul valore convertito in EUR)
      final amountInEur = CurrencyService.convert(ex.amount, ex.currency, 'EUR');
      if (_selectedExpenseAmountRangeFilter != 'Tutti') {
        if (_selectedExpenseAmountRangeFilter == 'Fino a €50' && amountInEur > 50) return false;
        if (_selectedExpenseAmountRangeFilter == '€50 - €200' && (amountInEur < 50 || amountInEur > 200)) return false;
        if (_selectedExpenseAmountRangeFilter == 'Oltre €200' && amountInEur < 200) return false;
      }

      // 4. Filtro per collegare la spesa ad una tappa/attività
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
          // 1. Scheda di Riepilogo del Budget (Statistiche Spese Sostenute e Previste)
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

                  // Statistiche delle Spese Sostenute
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Speso Effettivo (Sostenuto)", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      Text("€${totalSpentActual.toStringAsFixed(2)}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
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

                  // Statistiche delle Spese Previste
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Speso Stimato (Previsto)", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      Text("€${totalSpentPlanned.toStringAsFixed(2)}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange)),
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

          // 2. Sezione Storico e Registro di tutte le spese
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
                              style: TextStyle(
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

          // 3. Sezione Grafica della Ripartizione delle Spese Sostenute
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

          // Spaziatore per evitare che il FAB copra il contenuto del fondo
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

    // Filtra gli elementi in base alla categoria selezionata
    final filteredList = _selectedUsefulInfoCategory == 'Tutti'
        ? list
        : list.where((item) => item.category == _selectedUsefulInfoCategory).toList();

    return Column(
      children: [
        _buildUsefulInfoToggle(),
        if (_infoSubTab == 'Note') ...[
          // Menu a discesa per filtrare gli elementi per categoria
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

          // Elenco delle note informative
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
                                  // Badge colorato della categoria
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
                                  // Pulsanti per modificare o eliminare l'elemento
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
                                style: const TextStyle(
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
        ] else ...[
          Expanded(child: _buildTravelDocumentsList(provider)),
        ]
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

                    // Validazione per prevenire gli spazi iniziali vuoti
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

  // ==========================================
  // FUNZIONI DI SUPPORTO PER IL RENDERING DEI BIGLIETTI DEL WALLET
  // ==========================================

  Widget _buildUsefulInfoToggle() {
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
                    _infoSubTab = 'Note';
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: _infoSubTab == 'Note'
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.note_alt_outlined,
                          size: 18,
                          color: _infoSubTab == 'Note' ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "Note di Viaggio",
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w600,
                            color: _infoSubTab == 'Note' ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
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
                    _infoSubTab = 'Biglietti';
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: _infoSubTab == 'Biglietti'
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.confirmation_number_outlined,
                          size: 18,
                          color: _infoSubTab == 'Biglietti' ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "Biglietti & Wallet",
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w600,
                            color: _infoSubTab == 'Biglietti' ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
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

  Widget _buildTravelDocumentsList(TravelProvider provider) {
    final docs = provider.currentTravelDocuments;

    if (docs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.wallet_membership_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              const Text(
                "Il tuo Wallet è vuoto",
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                "Aggiungi carte d'imbarco, biglietti del treno o dell'hotel tramite il pulsante '+'.",
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14,
                  color: Theme.of(context).hintColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      itemCount: docs.length + 1,
      itemBuilder: (context, index) {
        if (index == docs.length) {
          return const SizedBox(height: 80);
        }
        final doc = docs[index];
        final gradient = _getTravelDocumentGradient(doc.documentType);
        final icon = _getTravelDocumentIcon(doc.documentType);

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              title: Text(
                doc.title,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              subtitle: Text(
                "${doc.documentType}${doc.bookingCode != null ? ' - PNR: ' + doc.bookingCode! : ''}",
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
              onTap: () {
                _showTravelDocumentDetailBottomSheet(context, doc, provider);
              },
            ),
          ),
        );
      },
    );
  }

  void _showAddEditTravelDocumentDialog(BuildContext context, TravelProvider provider, [TravelDocument? doc]) {
    final isEditing = doc != null;
    final titleController = TextEditingController(text: doc?.title ?? '');
    final bookingCodeController = TextEditingController(text: doc?.bookingCode ?? '');
    final seatController = TextEditingController(text: doc?.seat ?? '');
    final gateController = TextEditingController(text: doc?.gate ?? '');
    final notesController = TextEditingController(text: doc?.notes ?? '');
    
    String selectedDocType = doc?.documentType ?? 'Volo';
    DateTime? selectedDateTime = doc?.dateTime;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEditing ? "Modifica Biglietto" : "Aggiungi Biglietto"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedDocType,
                      decoration: InputDecoration(
                        labelText: "Tipo di Biglietto",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: ['Volo', 'Treno', 'Pullman', 'Hotel', 'Attrazione', 'Altro']
                          .map((type) => DropdownMenuItem<String>(
                                value: type,
                                child: Text(type),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            selectedDocType = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: "Titolo (es. Volo Roma-Londra) *",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: bookingCodeController,
                      decoration: InputDecoration(
                        labelText: "Codice Prenotazione (PNR)",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (selectedDocType == 'Hotel' || selectedDocType == 'Attrazione' || selectedDocType == 'Altro')
                      TextField(
                        controller: gateController,
                        decoration: InputDecoration(
                          labelText: "Luogo",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: seatController,
                              decoration: InputDecoration(
                                labelText: "Posto",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: gateController,
                              decoration: InputDecoration(
                                labelText: selectedDocType == 'Treno'
                                    ? "Carrozza"
                                    : selectedDocType == 'Pullman'
                                        ? "Fila"
                                        : "Gate",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        DateTime initDate = selectedDateTime ?? provider.selectedTrip!.startDate;
                        if (initDate.isBefore(provider.selectedTrip!.startDate)) {
                          initDate = provider.selectedTrip!.startDate;
                        } else if (initDate.isAfter(provider.selectedTrip!.endDate)) {
                          initDate = provider.selectedTrip!.endDate;
                        }
                        final datePicked = await showDatePicker(
                          context: context,
                          initialDate: initDate,
                          firstDate: provider.selectedTrip!.startDate,
                          lastDate: provider.selectedTrip!.endDate,
                        );
                        if (datePicked != null) {
                          final timePicked = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(selectedDateTime ?? DateTime.now()),
                          );
                          if (timePicked != null) {
                            setDialogState(() {
                              selectedDateTime = DateTime(
                                datePicked.year,
                                datePicked.month,
                                datePicked.day,
                                timePicked.hour,
                                timePicked.minute,
                              );
                            });
                          }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.5)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              selectedDateTime == null
                                  ? "Seleziona Data e Ora"
                                  : "${_formatDate(selectedDateTime!)} alle ${selectedDateTime!.hour.toString().padLeft(2, '0')}:${selectedDateTime!.minute.toString().padLeft(2, '0')}",
                              style: TextStyle(
                                color: selectedDateTime == null ? Theme.of(context).hintColor : Theme.of(context).textTheme.bodyLarge?.color,
                              ),
                            ),
                            const Icon(Icons.calendar_today, size: 18),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: "Note aggiuntive",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
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
                    final bookingCode = bookingCodeController.text;
                    final seat = seatController.text;
                    final gate = gateController.text;
                    final notes = notesController.text;

                    // Validazione per prevenire gli spazi iniziali vuoti
                    if (title.startsWith(' ') ||
                        bookingCode.startsWith(' ') ||
                        seat.startsWith(' ') ||
                        gate.startsWith(' ') ||
                        notes.startsWith(' ')) {
                      _showValidationError("Il testo non può iniziare con uno spazio");
                      return;
                    }

                    if (title.trim().isEmpty) {
                      _showValidationError("Il titolo è obbligatorio");
                      return;
                    }

                    final isSingleField = selectedDocType == 'Hotel' || selectedDocType == 'Attrazione' || selectedDocType == 'Altro';
                    final newDoc = TravelDocument(
                      id: doc?.id,
                      tripId: provider.selectedTrip!.id!,
                      title: title.trim(),
                      documentType: selectedDocType,
                      bookingCode: bookingCode.trim().isEmpty ? null : bookingCode.trim(),
                      seat: isSingleField ? null : (seat.trim().isEmpty ? null : seat.trim()),
                      gate: gate.trim().isEmpty ? null : gate.trim(),
                      dateTime: selectedDateTime,
                      notes: notes.trim(),
                    );

                    if (isEditing) {
                      provider.updateTravelDocument(newDoc);
                    } else {
                      provider.addTravelDocument(newDoc);
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

  void _showTravelDocumentDetailBottomSheet(BuildContext context, TravelDocument doc, TravelProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        String activeCodeType = 'QR';
        return StatefulBuilder(
          builder: (context, setModalState) {
            final gradient = _getTravelDocumentGradient(doc.documentType);
            final typeIcon = _getTravelDocumentIcon(doc.documentType);

            return DraggableScrollableSheet(
              initialChildSize: 0.85,
              minChildSize: 0.6,
              maxChildSize: 0.95,
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).canvasColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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
                          const Text(
                            "Dettagli Biglietto",
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () {
                                  Navigator.pop(context);
                                  _showAddEditTravelDocumentDialog(context, provider, doc);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text("Elimina Biglietto"),
                                      content: const Text("Sei sicuro di voler eliminare questo biglietto dal tuo Wallet?"),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: const Text("Annulla"),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                                          onPressed: () => Navigator.pop(context, true),
                                          child: const Text("Elimina"),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    provider.deleteTravelDocument(doc.id!);
                                    Navigator.pop(context);
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Divider(),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          gradient: gradient,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(typeIcon, color: Colors.white, size: 24),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          doc.documentType.toUpperCase(),
                                          style: TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white.withOpacity(0.7),
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                        Text(
                                          doc.title,
                                          style: const TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  if (doc.dateTime != null)
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "DATA & ORA",
                                          style: TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: 10,
                                            color: Colors.white.withOpacity(0.7),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "${_formatDate(doc.dateTime!)} ${doc.dateTime!.hour.toString().padLeft(2, '0')}:${doc.dateTime!.minute.toString().padLeft(2, '0')}",
                                          style: const TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  if (doc.documentType == 'Hotel' || doc.documentType == 'Attrazione' || doc.documentType == 'Altro') ...[
                                    if (doc.gate != null && doc.gate!.isNotEmpty)
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            "LUOGO",
                                            style: TextStyle(
                                              fontFamily: 'Outfit',
                                              fontSize: 10,
                                              color: Colors.white.withOpacity(0.7),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            doc.gate!,
                                            style: const TextStyle(
                                              fontFamily: 'Outfit',
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                  ] else ...[
                                    if (doc.seat != null && doc.seat!.isNotEmpty)
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            "POSTO",
                                            style: TextStyle(
                                              fontFamily: 'Outfit',
                                              fontSize: 10,
                                              color: Colors.white.withOpacity(0.7),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            doc.seat!,
                                            style: const TextStyle(
                                              fontFamily: 'Outfit',
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    if (doc.gate != null && doc.gate!.isNotEmpty)
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            doc.documentType == 'Treno'
                                                ? "CARROZZA"
                                                : doc.documentType == 'Pullman'
                                                    ? "FILA"
                                                    : "GATE",
                                            style: TextStyle(
                                              fontFamily: 'Outfit',
                                              fontSize: 10,
                                              color: Colors.white.withOpacity(0.7),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            doc.gate!,
                                            style: const TextStyle(
                                              fontFamily: 'Outfit',
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ],
                              ),
                            ),
                            if (doc.notes != null && doc.notes!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    doc.notes!,
                                    style: const TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 13,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              )
                            else
                              const SizedBox(height: 16),
                            Row(
                              children: [
                                Container(
                                  width: 16,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).canvasColor,
                                    borderRadius: const BorderRadius.only(
                                      topRight: Radius.circular(16),
                                      bottomRight: Radius.circular(16),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      final boxWidth = constraints.constrainWidth();
                                      const dashWidth = 6.0;
                                      const dashHeight = 1.5;
                                      final dashCount = (boxWidth / (2 * dashWidth)).floor();
                                      return Flex(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        direction: Axis.horizontal,
                                        children: List.generate(dashCount, (_) {
                                          return SizedBox(
                                            width: dashWidth,
                                            height: dashHeight,
                                            child: DecoratedBox(
                                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.4)),
                                            ),
                                          );
                                        }),
                                      );
                                    },
                                  ),
                                ),
                                Container(
                                  width: 16,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).canvasColor,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(16),
                                      bottomLeft: Radius.circular(16),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        ChoiceChip(
                                          label: const Text("Codice QR"),
                                          selected: activeCodeType == 'QR',
                                          selectedColor: Colors.grey.shade200,
                                          backgroundColor: Colors.transparent,
                                          labelStyle: TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: activeCodeType == 'QR' ? Colors.black : Colors.grey,
                                          ),
                                          onSelected: (selected) {
                                            if (selected) {
                                              setModalState(() {
                                                activeCodeType = 'QR';
                                              });
                                            }
                                          },
                                        ),
                                        const SizedBox(width: 12),
                                        ChoiceChip(
                                          label: const Text("Codice a Barre"),
                                          selected: activeCodeType == 'BAR',
                                          selectedColor: Colors.grey.shade200,
                                          backgroundColor: Colors.transparent,
                                          labelStyle: TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: activeCodeType == 'BAR' ? Colors.black : Colors.grey,
                                          ),
                                          onSelected: (selected) {
                                            if (selected) {
                                              setModalState(() {
                                                activeCodeType = 'BAR';
                                              });
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    if (activeCodeType == 'QR')
                                      CustomPaint(
                                        painter: QrCodePainter(
                                          code: doc.bookingCode ?? "SAY-MY-TRAVEL-PASS",
                                          qrColor: Colors.black,
                                        ),
                                        size: const Size(140, 140),
                                      )
                                    else
                                      CustomPaint(
                                        painter: BarcodePainter(
                                          code: doc.bookingCode ?? "SAY-MY-TRAVEL-PASS",
                                          barColor: Colors.black,
                                        ),
                                        size: const Size(220, 60),
                                      ),
                                    const SizedBox(height: 16),
                                    Text(
                                      doc.bookingCode != null ? "PNR: ${doc.bookingCode!.toUpperCase()}" : "BIGLIETTO DIGITALE",
                                      style: const TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.5,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  IconData _getTravelDocumentIcon(String docType) {
    switch (docType) {
      case 'Volo':
        return Icons.flight_takeoff;
      case 'Treno':
        return Icons.directions_railway;
      case 'Pullman':
        return Icons.directions_bus;
      case 'Hotel':
        return Icons.hotel;
      case 'Attrazione':
        return Icons.local_activity;
      case 'Altro':
      default:
        return Icons.confirmation_number_outlined;
    }
  }

  Gradient _getTravelDocumentGradient(String docType) {
    switch (docType) {
      case 'Volo':
        return const LinearGradient(
          colors: [Color(0xFF0F4C81), Color(0xFF1E88E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'Treno':
        return const LinearGradient(
          colors: [Color(0xFFD45D00), Color(0xFFFFB300)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'Pullman':
        return const LinearGradient(
          colors: [Color(0xFFC2185B), Color(0xFFE91E63)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'Hotel':
        return const LinearGradient(
          colors: [Color(0xFF007A78), Color(0xFF00BFA5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'Attrazione':
        return const LinearGradient(
          colors: [Color(0xFF6B4C9A), Color(0xFFAB47BC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'Altro':
      default:
        return const LinearGradient(
          colors: [Color(0xFF2C3E50), Color(0xFF4F5D73)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
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
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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

  Widget _buildDiaryTab(TravelProvider provider) {
    final entries = provider.currentDiaryEntries;

    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 70,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              "Il tuo Diario di Bordo è vuoto",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              "Tocca 'Nuovo Ricordo' per aggiungere foto e note!",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return Card(
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: InkWell(
            onTap: () => _showDiaryEntryDetailsDialog(provider, entry),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Hero(
                        tag: 'diary_image_${entry.id}',
                        child: _buildDiaryImage(entry.imagePath),
                      ),
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _formatDate(entry.date),
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entry.content,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDiaryImage(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return Container(
        color: Colors.grey.shade200,
        child: const Icon(Icons.photo_outlined, color: Colors.grey, size: 40),
      );
    }
    if (imagePath.startsWith('/') || imagePath.contains(':/')) {
      return Image.file(
        File(imagePath),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.red.shade50,
            child: const Icon(Icons.broken_image_outlined, color: Colors.redAccent),
          );
        },
      );
    }
    return Image.network(
      imagePath,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: Colors.grey.shade100,
          child: const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey.shade200,
          child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
        );
      },
    );
  }

  void _showDiaryEntryDetailsDialog(TravelProvider provider, DiaryEntry entry) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: EdgeInsets.zero,
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 1.33,
                    child: GestureDetector(
                      onTap: () => _showFullScreenImage(context, entry.imagePath, entry.id),
                      child: Hero(
                        tag: 'diary_image_${entry.id}',
                        child: _buildDiaryImage(entry.imagePath),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: CircleAvatar(
                      backgroundColor: Colors.black.withOpacity(0.5),
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _formatDate(entry.date),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 20),
                              onPressed: () {
                                Navigator.pop(ctx);
                                _showAddEditDiaryDialog(context, entry);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (subCtx) => AlertDialog(
                                    title: const Text("Elimina Ricordo"),
                                    content: const Text("Sei sicuro di voler eliminare questo ricordo permanentemente?"),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(subCtx),
                                        child: const Text("Annulla"),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          provider.deleteDiaryEntry(entry.id!);
                                          Navigator.pop(subCtx);
                                          Navigator.pop(ctx);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text("Ricordo eliminato con successo!")),
                                          );
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
                    const SizedBox(height: 12),
                    Text(
                      entry.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Theme.of(context).colorScheme.onBackground,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 180),
                      child: SingleChildScrollView(
                        child: Text(
                          entry.content,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            height: 1.5,
                            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.85),
                          ),
                        ),
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

  void _showAddEditDiaryDialog(BuildContext context, DiaryEntry? entry) {
    final provider = Provider.of<TravelProvider>(context, listen: false);
    final isEdit = entry != null;
    final titleController = TextEditingController(text: entry?.title ?? '');
    final contentController = TextEditingController(text: entry?.content ?? '');
    DateTime selectedDate = entry?.date ?? DateTime.now();
    String? selectedImagePath = entry?.imagePath;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          
          Future<void> pickImage(ImageSource source) async {
            try {
              final picker = ImagePicker();
              final image = await picker.pickImage(
                source: source,
                maxWidth: 1200,
                maxHeight: 1200,
                imageQuality: 85,
              );
              if (image != null) {
                setDialogState(() {
                  selectedImagePath = image.path;
                });
              }
            } catch (e) {
              debugPrint("Error picking image: $e");
            }
          }

          void showImageSourceSheet() {
            showModalBottomSheet(
              context: context,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (sheetCtx) => SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.photo_library_outlined),
                      title: const Text("Scegli dalla galleria"),
                      onTap: () {
                        Navigator.pop(sheetCtx);
                        pickImage(ImageSource.gallery);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.camera_alt_outlined),
                      title: const Text("Scatta una foto"),
                      onTap: () {
                        Navigator.pop(sheetCtx);
                        pickImage(ImageSource.camera);
                      },
                    ),
                  ],
                ),
              ),
            );
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Row(
              children: [
                Icon(
                  isEdit ? Icons.edit_note_outlined : Icons.add_photo_alternate_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(isEdit ? "Modifica Ricordo" : "Aggiungi Ricordo"),
              ],
            ),
            content: SingleChildScrollView(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.85,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GestureDetector(
                      onTap: showImageSourceSheet,
                      child: Container(
                        height: 150,
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(context).dividerColor.withOpacity(0.3),
                          ),
                        ),
                        child: selectedImagePath == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_a_photo_outlined,
                                    size: 36,
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    "Seleziona Foto",
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Tocca per scegliere o scattare",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Theme.of(context).textTheme.bodySmall?.color,
                                    ),
                                  ),
                                ],
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    _buildDiaryImage(selectedImagePath),
                                    Positioned(
                                      right: 8,
                                      bottom: 8,
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.6),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.edit, color: Colors.white, size: 16),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: "Titolo Ricordo *",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: provider.selectedTrip!.startDate,
                          lastDate: provider.selectedTrip!.endDate,
                        );
                        if (picked != null) {
                          setDialogState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text("Data: ${_formatDate(selectedDate)}"),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: contentController,
                      minLines: 3,
                      maxLines: 5,
                      decoration: InputDecoration(
                        labelText: "Racconta questo momento... *",
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Annulla"),
              ),
              ElevatedButton(
                onPressed: () async {
                  final title = titleController.text.trim();
                  final content = contentController.text.trim();

                  if (title.isEmpty || title.startsWith(' ')) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Il titolo non può essere vuoto o iniziare con uno spazio.")),
                    );
                    return;
                  }
                  if (content.isEmpty || content.startsWith(' ')) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("La descrizione non può essere vuota o iniziare con uno spazio.")),
                    );
                    return;
                  }

                  String? finalPath = selectedImagePath;
                  if (selectedImagePath != null &&
                      (selectedImagePath!.startsWith('/') || selectedImagePath!.contains(':/')) &&
                      (entry == null || entry.imagePath != selectedImagePath)) {
                    
                    try {
                      final appDocDir = await getApplicationDocumentsDirectory();
                      final extension = path.extension(selectedImagePath!);
                      final fileName = "diary_${DateTime.now().millisecondsSinceEpoch}$extension";
                      final savedFile = await File(selectedImagePath!).copy("${appDocDir.path}/$fileName");
                      finalPath = savedFile.path;
                    } catch (e) {
                      debugPrint("Error copying file to persistent folder: $e");
                    }
                  }

                  if (isEdit) {
                    final updated = entry.copyWith(
                      title: title,
                      content: content,
                      date: selectedDate,
                      imagePath: finalPath,
                    );
                    provider.updateDiaryEntry(updated);
                  } else {
                    final newEntry = DiaryEntry(
                      tripId: provider.selectedTrip!.id!,
                      title: title,
                      content: content,
                      date: selectedDate,
                      imagePath: finalPath,
                    );
                    provider.addDiaryEntry(newEntry);
                  }

                  Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(isEdit ? "Ricordo modificato!" : "Ricordo aggiunto!")),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(isEdit ? "Salva" : "Aggiungi"),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showExportTripDialog(BuildContext context, TravelProvider provider) {
    final trip = provider.selectedTrip!;
    final stops = provider.currentStops;
    final checklist = provider.currentChecklist;
    final expenses = provider.currentExpenses;

    final buffer = StringBuffer();
    buffer.writeln("# Viaggio a ${trip.destination}: ${trip.title}");
    buffer.writeln("**Periodo:** ${_formatDate(trip.startDate)} - ${_formatDate(trip.endDate)}");
    if (trip.participants.isNotEmpty) {
      buffer.writeln("**Partecipanti:** ${trip.participants}");
    }
    if (trip.generalInfo.isNotEmpty) {
      buffer.writeln("\n## Informazioni Generali\n${trip.generalInfo}");
    }

    buffer.writeln("\n## Itinerario delle Tappe");
    if (stops.isEmpty) {
      buffer.writeln("*Nessuna tappa programmata.*");
    } else {
      for (var stop in stops) {
        buffer.writeln("\n### Giorno ${stop.itineraryOrder}: ${stop.name}");
        buffer.writeln("**Data/Ora:** ${_formatDate(stop.dateTime)} alle ${_formatTime(stop.dateTime.hour.toString().padLeft(2, '0'))}:${stop.dateTime.minute.toString().padLeft(2, '0')}");
        if (stop.location.isNotEmpty) {
          buffer.writeln("**Località:** ${stop.location}");
        }
        if (stop.description.isNotEmpty) {
          buffer.writeln("**Descrizione:** ${stop.description}");
        }
        if (stop.notes.isNotEmpty) {
          buffer.writeln("**Note:** ${stop.notes}");
        }
        
        final activities = provider.getActivitiesForStop(stop.id!);
        if (activities.isNotEmpty) {
          buffer.writeln("\n**Attività pianificate:**");
          for (var act in activities) {
            final costStr = act.cost > 0 ? " (Costo: ${act.cost.toStringAsFixed(2)}€)" : "";
            buffer.writeln("- [${act.status}] ${act.time} - **${act.name}** [${act.type}]$costStr");
            if (act.description.isNotEmpty) {
              buffer.writeln("  *${act.description}*");
            }
          }
        }
      }
    }

    buffer.writeln("\n## Checklist");
    if (checklist.isEmpty) {
      buffer.writeln("*Nessun elemento in checklist.*");
    } else {
      final completedCount = checklist.where((item) => item.isChecked).length;
      buffer.writeln("**Progresso:** $completedCount/${checklist.length} completate\n");
      for (var item in checklist) {
        final checkSymbol = item.isChecked ? "[x]" : "[ ]";
        buffer.writeln("- $checkSymbol ${item.itemText} (${item.category} - Priorità: ${item.priority})");
      }
    }

    buffer.writeln("\n## Riepilogo Spese");
    final double totalBudget = trip.budget;
    double actualExpenses = 0.0;
    double plannedExpenses = 0.0;
    
    for (var exp in expenses) {
      if (exp.status == 'Sostenuta') {
        actualExpenses += exp.amount;
      } else if (exp.status == 'Prevista') {
        plannedExpenses += exp.amount;
      }
    }
    
    buffer.writeln("- **Budget Totale:** ${totalBudget.toStringAsFixed(2)}€");
    buffer.writeln("- **Spese Sostenute:** ${actualExpenses.toStringAsFixed(2)}€");
    buffer.writeln("- **Spese Previste:** ${plannedExpenses.toStringAsFixed(2)}€");
    final double remaining = totalBudget - actualExpenses;
    buffer.writeln("- **Budget Rimanente:** ${remaining.toStringAsFixed(2)}€");

    if (expenses.isNotEmpty) {
      buffer.writeln("\n**Storico Spese:**");
      for (var exp in expenses) {
        buffer.writeln("- ${exp.date} - **${exp.title}**: ${exp.amount.toStringAsFixed(2)}€ [${exp.category}] (${exp.status})");
      }
    }

    final formattedText = buffer.toString();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(Icons.ios_share, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            const Text("Esporta Viaggio"),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Copia il riepilogo in formato Markdown o genera un documento PDF stampabile (inclusi i biglietti del Wallet).",
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              Container(
                constraints: const BoxConstraints(maxHeight: 250),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.2)),
                ),
                child: Scrollbar(
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    child: SelectableText(
                      formattedText,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        actions: [
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: formattedText));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Riepilogo copiato negli appunti con successo!")),
              );
            },
            icon: const Icon(Icons.copy),
            label: const Text("Copia negli appunti"),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              await _exportTripToPdf(context, provider);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text("Genera PDF"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Annulla"),
          ),
        ],
      ),
    );
  }

  Future<void> _exportTripToPdf(BuildContext context, TravelProvider provider) async {
    final trip = provider.selectedTrip!;
    final stops = provider.currentStops;
    final checklist = provider.currentChecklist;
    final expenses = provider.currentExpenses;
    final documents = provider.currentTravelDocuments;

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Intestazione
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        trip.title,
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue800,
                        ),
                      ),
                      pw.Text(
                        "Destinazione: ${trip.destination}",
                        style: pw.TextStyle(
                          fontSize: 14,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        "Periodo: ${_formatDate(trip.startDate)} - ${_formatDate(trip.endDate)}",
                        style: const pw.TextStyle(fontSize: 11),
                      ),
                      if (trip.participants.isNotEmpty)
                        pw.Text(
                          "Partecipanti: ${trip.participants}",
                          style: const pw.TextStyle(fontSize: 11),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 10),

            // Scheda delle Informazioni Generali
            if (trip.generalInfo.isNotEmpty) ...[
              pw.Text(
                "Informazioni Generali",
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800),
              ),
              pw.SizedBox(height: 4),
              pw.Paragraph(
                text: trip.generalInfo,
                style: const pw.TextStyle(fontSize: 11),
              ),
              pw.SizedBox(height: 16),
            ],

            // Scheda dell'Itinerario
            pw.Text(
              "Itinerario delle Tappe",
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800),
            ),
            pw.Divider(thickness: 1, color: PdfColors.blue200),
            pw.SizedBox(height: 8),

            if (stops.isEmpty)
              pw.Paragraph(text: "Nessuna tappa programmata.", style: const pw.TextStyle(fontSize: 11, fontStyle: pw.FontStyle.italic))
            else
              ...stops.map((stop) {
                final activities = provider.getActivitiesForStop(stop.id!);
                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 12),
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            "Giorno ${stop.itineraryOrder}: ${stop.name}",
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
                          ),
                          pw.Text(
                            "${_formatDate(stop.dateTime)} alle ${stop.dateTime.hour.toString().padLeft(2, '0')}:${stop.dateTime.minute.toString().padLeft(2, '0')}",
                            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                          ),
                        ],
                      ),
                      if (stop.location.isNotEmpty)
                        pw.Text("Località: ${stop.location}", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                      if (stop.description.isNotEmpty)
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(top: 4),
                          child: pw.Text(stop.description, style: const pw.TextStyle(fontSize: 10)),
                        ),
                      if (stop.notes.isNotEmpty)
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(top: 4),
                          child: pw.Text("Note: ${stop.notes}", style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                        ),
                      if (activities.isNotEmpty) ...[
                        pw.SizedBox(height: 6),
                        pw.Text("Attività:", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                        ...activities.map((act) {
                          final costStr = act.cost > 0 ? " (${act.cost.toStringAsFixed(2)} EUR)" : "";
                          return pw.Bullet(
                            text: "[${act.status}] ${act.time} - ${act.name} [${act.type}]$costStr",
                            style: const pw.TextStyle(fontSize: 9),
                          );
                        }),
                      ],
                    ],
                  ),
                );
              }),

            pw.SizedBox(height: 16),

            // Tabella degli elementi della checklist
            pw.Text(
              "Checklist",
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800),
            ),
            pw.Divider(thickness: 1, color: PdfColors.blue200),
            pw.SizedBox(height: 8),

            if (checklist.isEmpty)
              pw.Paragraph(text: "Nessun elemento in checklist.", style: const pw.TextStyle(fontSize: 11, fontStyle: pw.FontStyle.italic))
            else ...[
              pw.Text(
                "Progresso: ${checklist.where((item) => item.isChecked).length}/${checklist.length} completate",
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
              ),
              pw.SizedBox(height: 6),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text("Stato", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text("Elemento", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text("Categoria", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text("Priorità", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                    ],
                  ),
                  ...checklist.map((item) {
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(item.isChecked ? "SI" : "NO", style: pw.TextStyle(fontSize: 9, color: item.isChecked ? PdfColors.green : PdfColors.red)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(item.itemText, style: const pw.TextStyle(fontSize: 9)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(item.category, style: const pw.TextStyle(fontSize: 9)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(item.priority, style: const pw.TextStyle(fontSize: 9)),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ],

            pw.SizedBox(height: 16),

            // Elenco delle transazioni registrate
            pw.Text(
              "Riepilogo Spese",
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800),
            ),
            pw.Divider(thickness: 1, color: PdfColors.blue200),
            pw.SizedBox(height: 8),

            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              color: PdfColors.grey100,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text("Budget Totale:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      pw.Text("${trip.budget.toStringAsFixed(2)} EUR", style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text("Spese Sostenute:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      pw.Text(
                        "${expenses.where((e) => e.status == 'Sostenuta').fold(0.0, (sum, e) => sum + e.amount).toStringAsFixed(2)} EUR",
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text("Spese Previste:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      pw.Text(
                        "${expenses.where((e) => e.status == 'Prevista').fold(0.0, (sum, e) => sum + e.amount).toStringAsFixed(2)} EUR",
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                  pw.Divider(height: 8, thickness: 0.5),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text("Budget Rimanente:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      pw.Text(
                        "${(trip.budget - expenses.where((e) => e.status == 'Sostenuta').fold(0.0, (sum, e) => sum + e.amount)).toStringAsFixed(2)} EUR",
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 10,
                          color: (trip.budget - expenses.where((e) => e.status == 'Sostenuta').fold(0.0, (sum, e) => sum + e.amount)) >= 0 ? PdfColors.green800 : PdfColors.red800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 10),
            if (expenses.isNotEmpty) ...[
              pw.Text("Storico Spese:", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text("Data", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text("Titolo", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text("Categoria", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text("Tipo", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text("Importo", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8))),
                    ],
                  ),
                  ...expenses.map((exp) {
                    return pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(_formatDate(exp.date), style: const pw.TextStyle(fontSize: 8))),
                        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(exp.title, style: const pw.TextStyle(fontSize: 8))),
                        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(exp.category, style: const pw.TextStyle(fontSize: 8))),
                        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(exp.status, style: const pw.TextStyle(fontSize: 8))),
                        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text("${exp.amount.toStringAsFixed(2)} EUR", style: const pw.TextStyle(fontSize: 8))),
                      ],
                    );
                  }),
                ],
              ),
            ],

            pw.SizedBox(height: 20),

            // Sezione Biglietti e Documenti (Wallet)
            pw.Text(
              "Wallet Biglietti e Documenti",
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800),
            ),
            pw.Divider(thickness: 1, color: PdfColors.blue200),
            pw.SizedBox(height: 8),

            if (documents.isEmpty)
              pw.Paragraph(text: "Nessun biglietto o documento salvato nel Wallet.", style: const pw.TextStyle(fontSize: 11, fontStyle: pw.FontStyle.italic))
            else
              ...documents.map((doc) {
                // Determina il testo dell'etichetta in base al tipo di documento
                String labelGate = "Gate";
                if (doc.documentType == 'Treno') {
                  labelGate = "Carrozza";
                } else if (doc.documentType == 'Pullman') {
                  labelGate = "Fila";
                } else if (doc.documentType == 'Hotel' || doc.documentType == 'Attrazione' || doc.documentType == 'Altro') {
                  labelGate = "Luogo";
                }

                // Nasconde o mostra il posto a sedere in base al mezzo di trasporto
                final bool showSeat = !(doc.documentType == 'Hotel' || doc.documentType == 'Attrazione' || doc.documentType == 'Altro');

                // Intestazione colorata del biglietto in base alla categoria
                PdfColor headerColor = PdfColors.blue700;
                if (doc.documentType == 'Volo') headerColor = PdfColors.teal700;
                if (doc.documentType == 'Treno') headerColor = PdfColors.indigo700;
                if (doc.documentType == 'Pullman') headerColor = PdfColors.deepOrange700;
                if (doc.documentType == 'Hotel') headerColor = PdfColors.purple700;
                if (doc.documentType == 'Attrazione') headerColor = PdfColors.green700;

                // Codice a barre e data del documento
                final String codeStr = doc.bookingCode ?? "SAY-MY-TRAVEL-PASS";
                final bool isQrCode = codeStr.length <= 8;
                final String docDateStr = doc.dateTime != null ? _formatDate(doc.dateTime!) : "N/D";
                final String docTimeStr = doc.dateTime != null ? "${doc.dateTime!.hour.toString().padLeft(2, '0')}:${doc.dateTime!.minute.toString().padLeft(2, '0')}" : "N/D";

                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 16),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400, width: 1),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Scheda intestazione
                      pw.Container(
                        width: double.infinity,
                        padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: pw.BoxDecoration(
                          color: headerColor,
                          borderRadius: const pw.BorderRadius.only(
                            topLeft: pw.Radius.circular(7),
                            topRight: pw.Radius.circular(7),
                          ),
                        ),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              doc.documentType.toUpperCase(),
                              style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 11),
                            ),
                            pw.Text(
                              doc.title,
                              style: pw.TextStyle(color: PdfColors.white, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      
                      // Scheda principale del contenuto
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(12),
                        child: pw.Row(
                          children: [
                            // Colonna Sinistra: Informazioni principali del biglietto
                            pw.Expanded(
                              flex: 2,
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    "Codice (PNR): $codeStr",
                                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                                  ),
                                  pw.SizedBox(height: 4),
                                  pw.Text(
                                    "Data e Ora: $docDateStr alle $docTimeStr",
                                    style: const pw.TextStyle(fontSize: 9),
                                  ),
                                  pw.SizedBox(height: 4),
                                  if (showSeat) ...[
                                    pw.Text("Posto/Sedile: ${doc.seat ?? 'N/D'}", style: const pw.TextStyle(fontSize: 9)),
                                    pw.Text("$labelGate: ${doc.gate ?? 'N/D'}", style: const pw.TextStyle(fontSize: 9)),
                                  ] else ...[
                                    pw.Text("$labelGate: ${doc.gate ?? 'N/D'}", style: const pw.TextStyle(fontSize: 9)),
                                  ],
                                  if (doc.notes != null && doc.notes!.isNotEmpty) ...[
                                    pw.SizedBox(height: 4),
                                    pw.Text("Note: ${doc.notes}", style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                                  ],
                                ],
                              ),
                            ),
                            
                            // Linea tratteggiata decorativa per simulare uno strappo del biglietto
                            pw.Container(
                              height: 60,
                              width: 1,
                              color: PdfColors.grey300,
                              margin: const pw.EdgeInsets.symmetric(horizontal: 12),
                            ),

                            // Colonna Destra: Generazione del Codice a Barre / QR Code
                            pw.Expanded(
                              flex: 1,
                              child: pw.Center(
                                child: pw.Column(
                                  mainAxisAlignment: pw.MainAxisAlignment.center,
                                  children: [
                                    if (isQrCode)
                                      pw.BarcodeWidget(
                                        barcode: pw.Barcode.qrCode(),
                                        data: codeStr,
                                        width: 60,
                                        height: 60,
                                      )
                                    else
                                      pw.BarcodeWidget(
                                        barcode: pw.Barcode.code39(),
                                        data: codeStr,
                                        width: 100,
                                        height: 35,
                                      ),
                                    pw.SizedBox(height: 3),
                                    pw.Text(
                                      codeStr,
                                      style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ];
        },
      ),
    );

    try {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: "Say_My_Travel_Viaggio_${trip.title.replaceAll(' ', '_')}.pdf",
      );
    } catch (e) {
      debugPrint("Error exporting PDF: $e");
    }
  }

  void _showFullScreenImage(BuildContext context, String? imagePath, int? entryId) {
    showDialog(
      context: context,
      barrierColor: Colors.black,
      builder: (ctx) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(ctx),
          ),
        ),
        body: Center(
          child: InteractiveViewer(
            panEnabled: true,
            minScale: 0.5,
            maxScale: 4.0,
            child: Hero(
              tag: 'diary_image_$entryId',
              child: imagePath == null || imagePath.isEmpty
                  ? const Icon(Icons.photo, color: Colors.white, size: 100)
                  : (imagePath.startsWith('/') || imagePath.contains(':/')
                      ? Image.file(File(imagePath))
                      : Image.network(imagePath)),
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

