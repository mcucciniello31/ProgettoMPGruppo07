import 'package:flutter/material.dart';
import '../../../models/useful_info.dart';
import '../../../models/travel_document.dart';
import 'package:say_my_travel/providers/travel_provider.dart';
import '../../../widgets/offline_code_painters.dart';
import 'add_useful_info_dialog.dart';
import 'add_travel_document_dialog.dart';

class UsefulInfoTab extends StatefulWidget {
  final TravelProvider provider;
  final String infoSubTab;
  final ValueChanged<String> onInfoSubTabChanged;

  const UsefulInfoTab({
    super.key,
    required this.provider,
    required this.infoSubTab,
    required this.onInfoSubTabChanged,
  });

  @override
  State<UsefulInfoTab> createState() => _UsefulInfoTabState();

  static Color getUsefulInfoCategoryColor(String category) {
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

  static IconData getUsefulInfoCategoryIcon(String category) {
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
}

class _UsefulInfoTabState extends State<UsefulInfoTab> {
  String _selectedUsefulInfoCategory = 'Tutti';

  String _formatDate(DateTime dt) {
    return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
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

  void _showDeleteUsefulInfoConfirmation(
    TravelProvider provider,
    UsefulInfo info,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Elimina Utility"),
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

  void _showTravelDocumentDetailBottomSheet(
    BuildContext context,
    TravelDocument doc,
    TravelProvider provider,
  ) {
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
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 24,
                    ),
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).dividerColor.withValues(alpha: 0.3),
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
                                  AddTravelDocumentDialog.show(
                                    context,
                                    provider,
                                    doc,
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.redAccent,
                                ),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text("Elimina Biglietto"),
                                      content: const Text(
                                        "Sei sicuro di voler eliminare questo biglietto dal tuo Wallet?",
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text("Annulla"),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.redAccent,
                                          ),
                                          onPressed: () =>
                                              Navigator.pop(context, true),
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
                              color: Colors.black.withValues(alpha: 0.15),
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
                                      color: Colors.white.withValues(
                                        alpha: 0.2,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      typeIcon,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          doc.documentType.toUpperCase(),
                                          style: TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white.withValues(
                                              alpha: 0.7,
                                            ),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  if (doc.dateTime != null)
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "DATA & ORA",
                                          style: TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: 10,
                                            color: Colors.white.withValues(
                                              alpha: 0.7,
                                            ),
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
                                  if (doc.documentType == 'Hotel' ||
                                      doc.documentType == 'Attrazione' ||
                                      doc.documentType == 'Altro') ...[
                                    if (doc.gate != null &&
                                        doc.gate!.isNotEmpty)
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            "LUOGO",
                                            style: TextStyle(
                                              fontFamily: 'Outfit',
                                              fontSize: 10,
                                              color: Colors.white.withValues(
                                                alpha: 0.7,
                                              ),
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
                                    if (doc.seat != null &&
                                        doc.seat!.isNotEmpty)
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            "POSTO",
                                            style: TextStyle(
                                              fontFamily: 'Outfit',
                                              fontSize: 10,
                                              color: Colors.white.withValues(
                                                alpha: 0.7,
                                              ),
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
                                    if (doc.gate != null &&
                                        doc.gate!.isNotEmpty)
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
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
                                              color: Colors.white.withValues(
                                                alpha: 0.7,
                                              ),
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
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  12,
                                  20,
                                  16,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.1),
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
                                      final boxWidth = constraints
                                          .constrainWidth();
                                      const dashWidth = 6.0;
                                      const dashHeight = 1.5;
                                      final dashCount =
                                          (boxWidth / (2 * dashWidth)).floor();
                                      return Flex(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        direction: Axis.horizontal,
                                        children: List.generate(dashCount, (_) {
                                          return SizedBox(
                                            width: dashWidth,
                                            height: dashHeight,
                                            child: DecoratedBox(
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(
                                                  alpha: 0.4,
                                                ),
                                              ),
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
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                16,
                                20,
                                24,
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
                                            color: activeCodeType == 'QR'
                                                ? Colors.black
                                                : Colors.grey,
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
                                            color: activeCodeType == 'BAR'
                                                ? Colors.black
                                                : Colors.grey,
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
                                          code:
                                              doc.bookingCode ??
                                              "SAY-MY-TRAVEL-PASS",
                                          qrColor: Colors.black,
                                        ),
                                        size: const Size(140, 140),
                                      )
                                    else
                                      CustomPaint(
                                        painter: BarcodePainter(
                                          code:
                                              doc.bookingCode ??
                                              "SAY-MY-TRAVEL-PASS",
                                          barColor: Colors.black,
                                        ),
                                        size: const Size(220, 60),
                                      ),
                                    const SizedBox(height: 16),
                                    Text(
                                      doc.bookingCode != null
                                          ? "PNR: ${doc.bookingCode!.toUpperCase()}"
                                          : "BIGLIETTO DIGITALE",
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

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    final infoList = provider.currentUsefulInfo;
    final docList = provider.currentTravelDocuments;

    // Filtra la lista di informazioni utili
    final filteredInfo = infoList.where((info) {
      if (_selectedUsefulInfoCategory != 'Tutti' &&
          info.category != _selectedUsefulInfoCategory) {
        return false;
      }
      return true;
    }).toList();

    return Column(
      children: [
        // Selettore secondario Note / Biglietti in stile pillola premium
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => widget.onInfoSubTabChanged('Note'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: widget.infoSubTab == 'Note'
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.description_outlined,
                              size: 16,
                              color: widget.infoSubTab == 'Note'
                                  ? Colors.white
                                  : Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.color,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "Note & Info",
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: widget.infoSubTab == 'Note'
                                    ? Colors.white
                                    : Theme.of(
                                        context,
                                      ).textTheme.bodyMedium?.color,
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
                    onTap: () => widget.onInfoSubTabChanged('Biglietti'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: widget.infoSubTab == 'Biglietti'
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.wallet_travel_outlined,
                              size: 16,
                              color: widget.infoSubTab == 'Biglietti'
                                  ? Colors.white
                                  : Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.color,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "Biglietti & Pass",
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: widget.infoSubTab == 'Biglietti'
                                    ? Colors.white
                                    : Theme.of(
                                        context,
                                      ).textTheme.bodyMedium?.color,
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
        ),

        // Contenuto in base al tab selezionato
        if (widget.infoSubTab == 'Note') ...[
          // Filtri di categoria per le note
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: PopupMenuButton<String>(
                    offset: const Offset(0, 48),
                    onSelected: (val) {
                      setState(() {
                        _selectedUsefulInfoCategory = val;
                      });
                    },
                    itemBuilder: (BuildContext context) =>
                        [
                          'Tutti',
                          'Nota',
                          'Promemoria',
                          'Prenotazione',
                          'Indirizzo',
                          'Altro',
                        ].map((cat) {
                          return PopupMenuItem<String>(
                            value: cat,
                            child: Row(
                              children: [
                                Icon(
                                  cat == 'Tutti'
                                      ? Icons.category_outlined
                                      : UsefulInfoTab.getUsefulInfoCategoryIcon(
                                          cat,
                                        ),
                                  size: 16,
                                  color: cat == 'Tutti'
                                      ? const Color(0xFF3B6A8A)
                                      : UsefulInfoTab.getUsefulInfoCategoryColor(
                                          cat,
                                        ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  cat,
                                  style: TextStyle(
                                    color: cat == 'Tutti'
                                        ? const Color(0xFF0D2137)
                                        : UsefulInfoTab.getUsefulInfoCategoryColor(
                                            cat,
                                          ),
                                    fontWeight: cat == 'Tutti'
                                        ? FontWeight.normal
                                        : FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFADCDE2),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFFADCDE2,
                            ).withValues(alpha: 0.15),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Filtra per Categoria",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3B6A8A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Icon(
                                      _selectedUsefulInfoCategory == 'Tutti'
                                          ? Icons.category_outlined
                                          : UsefulInfoTab.getUsefulInfoCategoryIcon(
                                              _selectedUsefulInfoCategory,
                                            ),
                                      size: 14,
                                      color:
                                          _selectedUsefulInfoCategory == 'Tutti'
                                          ? const Color(0xFF3B6A8A)
                                          : UsefulInfoTab.getUsefulInfoCategoryColor(
                                              _selectedUsefulInfoCategory,
                                            ),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        _selectedUsefulInfoCategory,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color:
                                              _selectedUsefulInfoCategory ==
                                                  'Tutti'
                                              ? const Color(0xFF0D2137)
                                              : UsefulInfoTab.getUsefulInfoCategoryColor(
                                                  _selectedUsefulInfoCategory,
                                                ),
                                          fontWeight:
                                              _selectedUsefulInfoCategory ==
                                                  'Tutti'
                                              ? FontWeight.normal
                                              : FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.arrow_drop_down,
                                color: Color(0xFF3B6A8A),
                                size: 18,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: filteredInfo.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.note_alt_outlined,
                          size: 64,
                          color: Theme.of(
                            context,
                          ).hintColor.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Nessuna informazione registrata",
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
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                    itemCount: filteredInfo.length,
                    itemBuilder: (context, index) {
                      final info = filteredInfo[index];
                      final catColor = UsefulInfoTab.getUsefulInfoCategoryColor(
                        info.category,
                      );
                      final catIcon = UsefulInfoTab.getUsefulInfoCategoryIcon(
                        info.category,
                      );

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Theme(
                          data: Theme.of(
                            context,
                          ).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: catColor.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(catIcon, color: catColor, size: 20),
                            ),
                            title: Text(
                              info.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              info.category,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () => AddUsefulInfoDialog.show(
                                    context,
                                    provider,
                                    info,
                                  ),
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.all(8),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.redAccent,
                                  ),
                                  onPressed: () =>
                                      _showDeleteUsefulInfoConfirmation(
                                        provider,
                                        info,
                                      ),
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
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary
                                        .withValues(alpha: 0.02),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Theme.of(
                                        context,
                                      ).dividerColor.withValues(alpha: 0.05),
                                    ),
                                  ),
                                  child: SelectableText(
                                    info.content,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      height: 1.4,
                                    ),
                                  ),
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
          // Lista dei Biglietti / Documenti di viaggio
          Expanded(
            child: docList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.wallet_travel_outlined,
                          size: 64,
                          color: Theme.of(
                            context,
                          ).hintColor.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Il tuo Wallet Biglietti è vuoto",
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
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                    itemCount: docList.length,
                    itemBuilder: (context, index) {
                      final doc = docList[index];
                      final gradient = _getTravelDocumentGradient(
                        doc.documentType,
                      );
                      final docIcon = _getTravelDocumentIcon(doc.documentType);

                      return GestureDetector(
                        onTap: () => _showTravelDocumentDetailBottomSheet(
                          context,
                          doc,
                          provider,
                        ),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            gradient: gradient,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    docIcon,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        doc.documentType.toUpperCase(),
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white.withValues(
                                            alpha: 0.7,
                                          ),
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        doc.title,
                                        style: const TextStyle(
                                          fontFamily: 'Outfit',
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                      if (doc.dateTime != null) ...[
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.access_time,
                                              size: 10,
                                              color: Colors.white70,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              "${_formatDate(doc.dateTime!)} alle ${doc.dateTime!.hour.toString().padLeft(2, '0')}:${doc.dateTime!.minute.toString().padLeft(2, '0')}",
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.white70,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 14,
                                  color: Colors.white70,
                                ),
                              ],
                            ),
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
