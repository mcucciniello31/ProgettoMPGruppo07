import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/database_helper.dart';
import '../services/currency_service.dart';
import '../models/trip.dart';
import '../models/stop.dart';
import '../models/activity.dart';
import '../models/checklist_item.dart';
import '../models/expense.dart';
import '../theme/app_theme.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  bool _isLoading = true;
  List<Trip> _allTrips = [];
  List<Stop> _allStops = [];
  List<Activity> _allActivities = [];
  List<ChecklistItem> _allChecklistItems = [];
  List<Expense> _allExpenses = [];

  // Filter option: null means "All Trips" (Global)
  int? _selectedFilterTripId;

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final db = DatabaseHelper.instance;
      _allTrips = await db.getTrips();
      _allStops = await db.getAllStops();
      _allActivities = await db.getAllActivities();
      _allChecklistItems = await db.getAllChecklistItems();
      _allExpenses = await db.getAllExpenses();
    } catch (e) {
      debugPrint("Error loading analytics: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatCurrency(double amount) {
    return "€${amount.toStringAsFixed(2).replaceAll('.', ',')}";
  }

  @override
  Widget build(BuildContext context) {
    final selectedTrip = _selectedFilterTripId == null
        ? null
        : _allTrips.firstWhere((t) => t.id == _selectedFilterTripId, orElse: () => _allTrips.first);

    // Filter data based on selected trip
    final activeTrips = selectedTrip == null
        ? _allTrips
        : [selectedTrip];

    final activeStops = selectedTrip == null
        ? _allStops
        : _allStops.where((s) => s.tripId == selectedTrip.id).toList();

    final stopIds = activeStops.map((s) => s.id).toSet();

    final activeActivities = selectedTrip == null
        ? _allActivities
        : _allActivities.where((a) => stopIds.contains(a.stopId)).toList();

    final activeChecklistItems = selectedTrip == null
        ? _allChecklistItems
        : _allChecklistItems.where((c) => c.tripId == selectedTrip.id).toList();

    final activeExpenses = selectedTrip == null
        ? _allExpenses
        : _allExpenses.where((e) => e.tripId == selectedTrip.id).toList();

    // 1. Calculations - Trips (Relevant for Global view)
    final totalTrips = _allTrips.length;
    final futureTripsCount = _allTrips.where((t) => t.status == 'futuro').length;
    final ongoingTripsCount = _allTrips.where((t) => t.status == 'in_corso').length;
    final completedTripsCount = _allTrips.where((t) => t.status == 'completato').length;
    final archivedTripsCount = _allTrips.where((t) => t.status == 'archiviato').length;

    // 2. Calculations - Expenses (Converted to EUR)
    final totalBudget = activeTrips.fold(0.0, (sum, t) => sum + t.budget);
    final totalSpentActual = activeExpenses
        .where((e) => e.status == 'Sostenuta')
        .fold(0.0, (sum, e) => sum + CurrencyService.convert(e.amount, e.currency, 'EUR'));
    final totalSpentPlanned = activeExpenses
        .where((e) => e.status == 'Prevista')
        .fold(0.0, (sum, e) => sum + CurrencyService.convert(e.amount, e.currency, 'EUR'));

    // Category Distribution (Actual spent only)
    Map<String, double> categoryDistribution = {};
    for (var e in activeExpenses.where((e) => e.status == 'Sostenuta')) {
      final eurAmount = CurrencyService.convert(e.amount, e.currency, 'EUR');
      categoryDistribution[e.category] = (categoryDistribution[e.category] ?? 0.0) + eurAmount;
    }
    
    // Sort category distribution by spent amount descending
    final sortedCategories = categoryDistribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // 3. Calculations - Activities
    final totalActivities = activeActivities.length;
    final completedActivities = activeActivities.where((a) => a.status == 'Completata').length;
    final pendingActivities = activeActivities.where((a) => a.status == 'Da svolgere').length;
    final cancelledActivities = activeActivities.where((a) => a.status == 'Annullata').length;

    // 4. Calculations - Checklists
    final totalChecklistItems = activeChecklistItems.length;
    final completedChecklistItems = activeChecklistItems.where((i) => i.isChecked).length;
    final openChecklistItems = activeChecklistItems.where((i) => !i.isChecked).length;

    // 5. Calculations - Top Active Days (Stops with most activities)
    Map<int, int> stopActivityCounts = {};
    for (var a in activeActivities) {
      stopActivityCounts[a.stopId] = (stopActivityCounts[a.stopId] ?? 0) + 1;
    }

    final topStopsData = stopActivityCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    List<Map<String, dynamic>> topStopsList = [];
    for (var entry in topStopsData.take(5)) {
      final stopId = entry.key;
      final activityCount = entry.value;
      final stop = _allStops.firstWhere((s) => s.id == stopId, orElse: () => Stop(tripId: 0, name: 'Tappa Sconosciuta', description: '', dateTime: DateTime.now(), location: '', itineraryOrder: 1));
      final trip = _allTrips.firstWhere((t) => t.id == stop.tripId, orElse: () => Trip(title: 'Viaggio Sconosciuto', destination: '', startDate: DateTime.now(), endDate: DateTime.now(), budget: 0.0));
      topStopsList.add({
        'stopName': stop.name,
        'tripTitle': trip.title,
        'count': activityCount,
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Analisi e Statistiche",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Aggiorna dati",
            onPressed: _loadAnalyticsData,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _allTrips.isEmpty
              ? _buildEmptyState()
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Trip Selector Filter Dropdown
                      _buildTripFilterSelector(),
                      const SizedBox(height: 20),

                      // Global Trips Status (Only visible when filter is Global)
                      if (_selectedFilterTripId == null) ...[
                        _buildTripsStatusCard(
                          totalTrips,
                          futureTripsCount,
                          ongoingTripsCount,
                          completedTripsCount,
                          archivedTripsCount,
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Budget & Expenses Overview Panel
                      _buildBudgetExpensesCard(
                        totalBudget,
                        totalSpentActual,
                        totalSpentPlanned,
                      ),
                      const SizedBox(height: 16),

                      // Expense Category Distribution Card
                      _buildCategoryDistributionCard(
                        totalSpentActual,
                        sortedCategories,
                      ),
                      const SizedBox(height: 16),

                      // Activities & Checklists Performance
                      _buildActivitiesChecklistCard(
                        totalActivities,
                        completedActivities,
                        pendingActivities,
                        cancelledActivities,
                        totalChecklistItems,
                        completedChecklistItems,
                        openChecklistItems,
                      ),
                      const SizedBox(height: 16),

                      // Top Active Days (Tappe più attive)
                      _buildTopActiveDaysCard(topStopsList),
                    ],
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart_outlined,
              size: 100,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              "Nessun viaggio disponibile per l'analisi",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Crea almeno un viaggio e aggiungi tappe, attività, spese o checklist per visualizzare statistiche dettagliate ed elaborazioni grafiche.",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripFilterSelector() {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.primary.withOpacity(0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.filter_alt_outlined, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int?>(
                  value: _selectedFilterTripId,
                  isExpanded: true,
                  style: GoogleFonts.outfit(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                  hint: const Text("Seleziona Filtro"),
                  items: [
                    DropdownMenuItem<int?>(
                      value: null,
                      child: Text(
                        "Tutti i Viaggi (Panoramica Globale)",
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                      ),
                    ),
                    ..._allTrips.map((t) => DropdownMenuItem<int?>(
                          value: t.id,
                          child: Text(t.title),
                        )),
                  ],
                  onChanged: (tripId) {
                    setState(() {
                      _selectedFilterTripId = tripId;
                    });
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripsStatusCard(
    int total,
    int future,
    int ongoing,
    int completed,
    int archived,
  ) {
    final hasActiveTrips = total > 0;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Stato dei Viaggi",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              "Totale Viaggi Salvati: $total",
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const Divider(height: 24),
            
            // Visual Segmented Bar Chart
            if (hasActiveTrips) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 16,
                  width: double.infinity,
                  color: Colors.grey.withOpacity(0.1),
                  child: Row(
                    children: [
                      if (future > 0)
                        Expanded(
                          flex: future,
                          child: Container(color: Colors.blueAccent),
                        ),
                      if (ongoing > 0)
                        Expanded(
                          flex: ongoing,
                          child: Container(color: Colors.green),
                        ),
                      if (completed > 0)
                        Expanded(
                          flex: completed,
                          child: Container(color: Colors.blueGrey),
                        ),
                      if (archived > 0)
                        Expanded(
                          flex: archived,
                          child: Container(color: Colors.orange),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Legend Grid
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatusLegendItem("Futuro", future, Colors.blueAccent),
                _buildStatusLegendItem("In Corso", ongoing, Colors.green),
                _buildStatusLegendItem("Completato", completed, Colors.blueGrey),
                _buildStatusLegendItem("Archiviato", archived, Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusLegendItem(String label, int count, Color color) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          "$count",
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetExpensesCard(
    double totalBudget,
    double totalSpentActual,
    double totalSpentPlanned,
  ) {
    final spendRate = totalBudget > 0 ? (totalSpentActual / totalBudget).clamp(0.0, 1.0) : 0.0;
    final plannedSpendRate = totalBudget > 0 ? (totalSpentPlanned / totalBudget).clamp(0.0, 1.0) : 0.0;
    final isOverBudget = totalSpentActual > totalBudget;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Riepilogo Budget Globale",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Stats Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Spend Rate Ring
                SizedBox(
                  width: 90,
                  height: 90,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: spendRate,
                        strokeWidth: 8,
                        backgroundColor: Colors.grey.withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isOverBudget ? Colors.redAccent : Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      Text(
                        "${(spendRate * 100).toStringAsFixed(0)}%",
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isOverBudget ? Colors.redAccent : Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                // Detailed text stats
                Expanded(
                  child: Column(
                    children: [
                      _buildBudgetMiniRow("Budget Totale", totalBudget, Colors.grey),
                      const SizedBox(height: 6),
                      _buildBudgetMiniRow("Speso Effettivo", totalSpentActual, isOverBudget ? Colors.redAccent : Colors.green),
                      const SizedBox(height: 6),
                      _buildBudgetMiniRow("Speso Stimato", totalSpentPlanned, Colors.orange),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            
            // Linear indicator comparison
            const Text(
              "Andamento Spesa Stimata vs Speso Effettivo",
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: plannedSpendRate,
                minHeight: 6,
                backgroundColor: Colors.grey.withOpacity(0.1),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Speso Effettivo (Sotto)", style: TextStyle(fontSize: 9, color: Colors.grey)),
                Text(
                  isOverBudget 
                      ? "Fuori Budget di ${_formatCurrency(totalSpentActual - totalBudget)}"
                      : "Rimanente Effettivo: ${_formatCurrency(totalBudget - totalSpentActual)}",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isOverBudget ? Colors.redAccent : Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetMiniRow(String label, double amount, Color amountColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        Text(
          _formatCurrency(amount),
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: amountColor,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryDistributionCard(
    double totalSpentActual,
    List<MapEntry<String, double>> categories,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Distribuzione delle Spese",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Icon(
                  Icons.pie_chart_outline,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              "Spese effettive suddivise per categoria",
              style: TextStyle(color: Colors.grey, fontSize: 11),
            ),
            const Divider(height: 24),
            
            if (categories.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    "Nessuna spesa sostenuta registrata.",
                    style: TextStyle(color: Colors.grey, fontSize: 13, fontStyle: FontStyle.italic),
                  ),
                ),
              )
            else
              Column(
                children: categories.map((entry) {
                  final cat = entry.key;
                  final amount = entry.value;
                  final color = AppTheme.categoryColors[cat] ?? Colors.grey;
                  final rate = totalSpentActual > 0 ? (amount / totalSpentActual) : 0.0;
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  cat,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                                ),
                              ],
                            ),
                            Text(
                              "${_formatCurrency(amount)} (${(rate * 100).toStringAsFixed(1)}%)",
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: rate,
                            minHeight: 6,
                            backgroundColor: Colors.grey.withOpacity(0.1),
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivitiesChecklistCard(
    int totalActs,
    int completedActs,
    int pendingActs,
    int cancelledActs,
    int totalChecklist,
    int completedChecklist,
    int openChecklist,
  ) {
    final actCompletionRate = totalActs > 0 ? (completedActs / totalActs) : 0.0;
    final checklistCompletionRate = totalChecklist > 0 ? (completedChecklist / totalChecklist) : 0.0;

    return Row(
      children: [
        // Activities Widget
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Attività",
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: SizedBox(
                      width: 70,
                      height: 70,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: actCompletionRate,
                            strokeWidth: 6,
                            backgroundColor: Colors.grey.withOpacity(0.1),
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                          ),
                          Text(
                            "${(actCompletionRate * 100).toStringAsFixed(0)}%",
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildAnalysisMiniLabel("Totali", totalActs),
                  _buildAnalysisMiniLabel("Fatte", completedActs),
                  _buildAnalysisMiniLabel("Da fare", pendingActs),
                  _buildAnalysisMiniLabel("Annullate", cancelledActs),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Checklist Widget
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Checklist",
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: SizedBox(
                      width: 70,
                      height: 70,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: checklistCompletionRate,
                            strokeWidth: 6,
                            backgroundColor: Colors.grey.withOpacity(0.1),
                            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                          ),
                          Text(
                            "${(checklistCompletionRate * 100).toStringAsFixed(0)}%",
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildAnalysisMiniLabel("Totali", totalChecklist),
                  _buildAnalysisMiniLabel("Spuntate", completedChecklist),
                  _buildAnalysisMiniLabel("Aperte", openChecklist),
                  // Spacer to align heights
                  const SizedBox(height: 18),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalysisMiniLabel(String label, int val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          Text("$val", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildTopActiveDaysCard(List<Map<String, dynamic>> topStops) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Giornate Più Attive",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Icon(
                  Icons.flash_on_outlined,
                  color: Colors.amber[700],
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              "Tappe del viaggio con il maggior numero di attività",
              style: TextStyle(color: Colors.grey, fontSize: 11),
            ),
            const Divider(height: 24),
            
            if (topStops.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    "Nessuna attività pianificata.",
                    style: TextStyle(color: Colors.grey, fontSize: 13, fontStyle: FontStyle.italic),
                  ),
                ),
              )
            else
              Column(
                children: topStops.map((stopInfo) {
                  final stopName = stopInfo['stopName'];
                  final tripTitle = stopInfo['tripTitle'];
                  final count = stopInfo['count'];
                  
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: CircleAvatar(
                      backgroundColor: Colors.amber.withOpacity(0.15),
                      child: Text(
                        "$count",
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber[800],
                        ),
                      ),
                    ),
                    title: Text(
                      stopName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    subtitle: Text(
                      tripTitle,
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                    trailing: const Text(
                      "attività",
                      style: TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}
