import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/trip.dart';
import '../../providers/travel_provider.dart';
import 'checklist/checklist_tab.dart';
import 'checklist/add_checklist_item_screen.dart';
import 'itinerary/itinerary_tab.dart';
import 'itinerary/add_stop_screen.dart';
import 'expenses/expenses_tab.dart';
import 'expenses/add_expense_screen.dart';
import 'diary/diary_tab.dart';
import 'useful_info/useful_info_tab.dart';

class TripDetailsScreen extends StatefulWidget {
  const TripDetailsScreen({super.key});

  @override
  State<TripDetailsScreen> createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends State<TripDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isInfoExpanded = false;
  String _infoSubTab = 'Note'; // 'Note' oppure 'Biglietti'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      setState(
        () {},
      ); // Ricostruisce per aggiornare il FAB in base al tab attivo
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime dt) {
    return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
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
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "Informazioni di Viaggio",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
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
                        const Icon(
                          Icons.people_outline,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Partecipanti:",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                trip.participants,
                                style: const TextStyle(fontSize: 14),
                              ),
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
                              const Text(
                                "Info Utili Generali:",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                trip.generalInfo,
                                style: const TextStyle(fontSize: 14),
                              ),
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
                        const Icon(
                          Icons.map_outlined,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Posizione: ${trip.latitude!.toStringAsFixed(3)}°, ${trip.longitude!.toStringAsFixed(3)}°",
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            final url = Uri.parse(
                              'https://www.google.com/maps/search/?api=1&query=${trip.latitude},${trip.longitude}',
                            );
                            if (await canLaunchUrl(url)) {
                              await launchUrl(
                                url,
                                mode: LaunchMode.externalApplication,
                              );
                            } else {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Impossibile aprire la mappa",
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.map, size: 16),
                          label: const Text(
                            "Vedi Mappa",
                            style: TextStyle(fontSize: 12),
                          ),
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

  Widget? _buildFAB(TravelProvider provider) {
    if (MediaQuery.of(context).viewInsets.bottom > 0) {
      return null;
    }
    if (_tabController.index == 0) {
      return FloatingActionButton.extended(
        key: const ValueKey('fab_itinerary'),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  AddStopScreen(tripId: provider.selectedTrip!.id!),
            ),
          );
        },
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text("Aggiungi Tappa"),
      );
    } else if (_tabController.index == 1) {
      return FloatingActionButton.extended(
        key: const ValueKey('fab_checklist'),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  AddChecklistItemScreen(tripId: provider.selectedTrip!.id!),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text("Nuovo Elemento"),
      );
    } else if (_tabController.index == 2) {
      return FloatingActionButton.extended(
        key: const ValueKey('fab_expenses'),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  AddExpenseScreen(tripId: provider.selectedTrip!.id!),
            ),
          );
        },
        icon: const Icon(Icons.add_card_outlined),
        label: const Text("Aggiungi Spesa"),
      );
    } else if (_tabController.index == 3) {
      return FloatingActionButton.extended(
        key: const ValueKey('fab_diary'),
        onPressed: () {
          DiaryTab.showAddEditDiaryDialog(context, null);
        },
        icon: const Icon(Icons.add_photo_alternate_outlined),
        label: const Text("Nuovo Ricordo"),
      );
    } else if (_tabController.index == 4) {
      if (_infoSubTab == 'Biglietti') {
        return FloatingActionButton.extended(
          key: const ValueKey('fab_travel_tickets'),
          onPressed: () {
            UsefulInfoTab.showAddEditTravelDocumentDialog(
              context,
              provider,
              null,
            );
          },
          icon: const Icon(Icons.add_card_outlined),
          label: const Text("Aggiungi Biglietto"),
        );
      } else {
        return FloatingActionButton.extended(
          key: const ValueKey('fab_useful_info'),
          onPressed: () {
            UsefulInfoTab.showAddEditUsefulInfoDialog(context, provider, null);
          },
          icon: const Icon(Icons.add_comment_outlined),
          label: const Text("Nuova Info"),
        );
      }
    }
    return null;
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
      Color(
        (trip.destination.hashCode & 0xFFFFFF) | 0xFF000000,
      ).withOpacity(0.85),
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
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: Container(
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
                            image:
                                trip.coverImagePath != null &&
                                    trip.coverImagePath!.isNotEmpty &&
                                    File(trip.coverImagePath!).existsSync()
                                ? DecorationImage(
                                    image: FileImage(
                                      File(trip.coverImagePath!),
                                    ),
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.arrow_back_ios,
                                        color: Colors.white,
                                      ),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                    Expanded(
                                      child: Center(
                                        child: Text(
                                          trip.destination,
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(
                                              0.9,
                                            ),
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.ios_share,
                                        color: Colors.white,
                                      ),
                                      tooltip: "Esporta Viaggio",
                                      onPressed: () =>
                                          UsefulInfoTab.showExportTripDialog(
                                            context,
                                            provider,
                                          ),
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
                                    const Icon(
                                      Icons.calendar_month,
                                      color: Colors.white70,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      "${_formatDate(trip.startDate)} - ${_formatDate(trip.endDate)}",
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      _buildTripInfoSection(context, trip),
                    ] else ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                        child: Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.arrow_back_ios,
                                color: Theme.of(context).colorScheme.primary,
                                size: 20,
                              ),
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
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onBackground,
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
                    unselectedLabelColor: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color,
                    labelPadding: EdgeInsets.zero,
                    labelStyle: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    unselectedLabelStyle: const TextStyle(fontSize: 10),
                    tabs: const [
                      Tab(
                        icon: Icon(Icons.map_outlined, size: 20),
                        text: "Itinerario",
                      ),
                      Tab(
                        icon: Icon(Icons.checklist_outlined, size: 20),
                        text: "Checklist",
                      ),
                      Tab(
                        icon: Icon(Icons.euro_outlined, size: 20),
                        text: "Spese",
                      ),
                      Tab(
                        icon: Icon(Icons.photo_library_outlined, size: 20),
                        text: "Diario",
                      ),
                      Tab(
                        icon: Icon(Icons.info_outline, size: 20),
                        text: "Info Utili",
                      ),
                    ],
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              ItineraryTab(provider: provider),
              ChecklistTab(provider: provider),
              ExpensesTab(provider: provider),
              DiaryTab(provider: provider),
              UsefulInfoTab(
                provider: provider,
                infoSubTab: _infoSubTab,
                onInfoSubTabChanged: (val) {
                  setState(() {
                    _infoSubTab = val;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFAB(provider),
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
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overridesParent,
  ) {
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
