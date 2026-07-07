import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../models/useful_info.dart';
import '../../../models/travel_document.dart';
import '../../../providers/travel_provider.dart';
import '../../../widgets/offline_code_painters.dart';

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

  static void showAddEditUsefulInfoDialog(
    BuildContext context,
    TravelProvider provider, [
    UsefulInfo? info,
  ]) {
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
              title: Text(
                isEditing ? "Modifica Info Utile" : "Nuova Info Utile",
              ),
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
                      isExpanded: true,
                      value: selectedCategory,
                      decoration: InputDecoration(
                        labelText: "Categoria",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      selectedItemBuilder: (BuildContext context) {
                        return [
                          'Nota',
                          'Promemoria',
                          'Prenotazione',
                          'Indirizzo',
                          'Altro',
                        ].map((cat) {
                          return Row(
                            children: [
                              Icon(
                                getUsefulInfoCategoryIcon(cat),
                                size: 18,
                                color: getUsefulInfoCategoryColor(cat),
                              ),
                              const SizedBox(width: 8),
                              Text(cat),
                            ],
                          );
                        }).toList();
                      },
                      items:
                          [
                                'Nota',
                                'Promemoria',
                                'Prenotazione',
                                'Indirizzo',
                                'Altro',
                              ]
                              .map(
                                (cat) => DropdownMenuItem<String>(
                                  value: cat,
                                  child: Row(
                                    children: [
                                      Icon(
                                        getUsefulInfoCategoryIcon(cat),
                                        size: 18,
                                        color: getUsefulInfoCategoryColor(cat),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(cat),
                                    ],
                                  ),
                                ),
                              )
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

                    if (title.startsWith(' ') || content.startsWith(' ')) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Il testo non può iniziare con uno spazio",
                          ),
                        ),
                      );
                      return;
                    }

                    final trimmedTitle = title.trim();
                    final trimmedContent = content.trim();

                    if (trimmedTitle.isEmpty || trimmedContent.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Titolo e Contenuto sono obbligatori"),
                        ),
                      );
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

  static void showAddEditTravelDocumentDialog(
    BuildContext context,
    TravelProvider provider, [
    TravelDocument? doc,
  ]) {
    final isEditing = doc != null;
    final titleController = TextEditingController(text: doc?.title ?? '');
    final bookingCodeController = TextEditingController(
      text: doc?.bookingCode ?? '',
    );
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
              title: Text(
                isEditing ? "Modifica Biglietto" : "Aggiungi Biglietto",
              ),
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
                      items:
                          [
                                'Volo',
                                'Treno',
                                'Pullman',
                                'Hotel',
                                'Attrazione',
                                'Altro',
                              ]
                              .map(
                                (type) => DropdownMenuItem<String>(
                                  value: type,
                                  child: Text(type),
                                ),
                              )
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
                    if (selectedDocType == 'Hotel' ||
                        selectedDocType == 'Attrazione' ||
                        selectedDocType == 'Altro')
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
                        DateTime initDate =
                            selectedDateTime ??
                            provider.selectedTrip!.startDate;
                        if (initDate.isBefore(
                          provider.selectedTrip!.startDate,
                        )) {
                          initDate = provider.selectedTrip!.startDate;
                        } else if (initDate.isAfter(
                          provider.selectedTrip!.endDate,
                        )) {
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
                            initialTime: TimeOfDay.fromDateTime(
                              selectedDateTime ?? DateTime.now(),
                            ),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).dividerColor.withOpacity(0.5),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              selectedDateTime == null
                                  ? "Seleziona Data e Ora"
                                  : "${selectedDateTime!.day.toString().padLeft(2, '0')}/${selectedDateTime!.month.toString().padLeft(2, '0')}/${selectedDateTime!.year} alle ${selectedDateTime!.hour.toString().padLeft(2, '0')}:${selectedDateTime!.minute.toString().padLeft(2, '0')}",
                              style: TextStyle(
                                color: selectedDateTime == null
                                    ? Theme.of(context).hintColor
                                    : Theme.of(
                                        context,
                                      ).textTheme.bodyLarge?.color,
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

                    if (title.startsWith(' ') ||
                        bookingCode.startsWith(' ') ||
                        seat.startsWith(' ') ||
                        gate.startsWith(' ') ||
                        notes.startsWith(' ')) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Il testo non può iniziare con uno spazio",
                          ),
                        ),
                      );
                      return;
                    }

                    if (title.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Il titolo è obbligatorio"),
                        ),
                      );
                      return;
                    }

                    final isSingleField =
                        selectedDocType == 'Hotel' ||
                        selectedDocType == 'Attrazione' ||
                        selectedDocType == 'Altro';
                    final newDoc = TravelDocument(
                      id: doc?.id,
                      tripId: provider.selectedTrip!.id!,
                      title: title.trim(),
                      documentType: selectedDocType,
                      bookingCode: bookingCode.trim().isEmpty
                          ? null
                          : bookingCode.trim(),
                      seat: isSingleField
                          ? null
                          : (seat.trim().isEmpty ? null : seat.trim()),
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

  static void showExportTripDialog(
    BuildContext context,
    TravelProvider provider,
  ) {
    final trip = provider.selectedTrip!;
    final stops = provider.currentStops;
    final checklist = provider.currentChecklist;
    final expenses = provider.currentExpenses;

    String formatDateLocal(DateTime dt) {
      return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
    }

    final buffer = StringBuffer();
    buffer.writeln("# Viaggio a ${trip.destination}: ${trip.title}");
    buffer.writeln(
      "**Periodo:** ${formatDateLocal(trip.startDate)} - ${formatDateLocal(trip.endDate)}",
    );
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
        buffer.writeln(
          "**Data/Ora:** ${formatDateLocal(stop.dateTime)} alle ${stop.dateTime.hour.toString().padLeft(2, '0')}:${stop.dateTime.minute.toString().padLeft(2, '0')}",
        );
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
            final costStr = act.cost > 0
                ? " (Costo: ${act.cost.toStringAsFixed(2)}€)"
                : "";
            buffer.writeln(
              "- [${act.status}] ${act.time} - **${act.name}** [${act.type}]$costStr",
            );
            if (act.description.isNotEmpty) {
              buffer.writeln("  *${act.description}*");
            }
          }
        }
      }
    }

    buffer.writeln("\n## Checklist delle cose da fare");
    if (checklist.isEmpty) {
      buffer.writeln("*Nessun elemento presente nella checklist.*");
    } else {
      for (var item in checklist) {
        final checkSymbol = item.isChecked ? "[x]" : "[ ]";
        buffer.writeln(
          "- $checkSymbol **${item.itemText}** (${item.category} - Priorità: ${item.priority})",
        );
      }
    }

    buffer.writeln("\n## Bilancio e Spese Sostenute");
    buffer.writeln(
      "**Budget di Viaggio:** ${provider.totalBudget.toStringAsFixed(2)}€",
    );
    buffer.writeln(
      "**Spesa Totale Sostenuta:** ${provider.totalExpenses.toStringAsFixed(2)}€",
    );
    buffer.writeln(
      "**Spesa Totale Stimata:** ${provider.totalPlannedExpenses.toStringAsFixed(2)}€",
    );

    final remaining = provider.remainingBudget;
    if (remaining < 0) {
      buffer.writeln(
        "**Bilancio Effettivo:** Sotto budget di ${(-remaining).toStringAsFixed(2)}€ ⚠️",
      );
    } else {
      buffer.writeln(
        "**Bilancio Effettivo:** Avanzo di ${remaining.toStringAsFixed(2)}€",
      );
    }

    if (expenses.isNotEmpty) {
      buffer.writeln("\n**Dettaglio Transazioni:**");
      for (var ex in expenses) {
        buffer.writeln(
          "- **${ex.title}** (${ex.status}): ${ex.amount.toStringAsFixed(2)} ${ex.currency} (${ex.category} - ${ex.paymentMethod})",
        );
      }
    }

    final formattedText = buffer.toString();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Esporta Viaggio"),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Copia il riepilogo in formato Markdown o genera un documento PDF stampabile (inclusi i biglietti del Wallet).",
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              Container(
                height: 200,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).dividerColor.withOpacity(0.2),
                  ),
                ),
                child: Scrollbar(
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    child: SelectableText(
                      formattedText,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                      ),
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
                const SnackBar(
                  content: Text(
                    "Riepilogo copiato negli appunti con successo!",
                  ),
                ),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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

  static Future<void> _exportTripToPdf(
    BuildContext context,
    TravelProvider provider,
  ) async {
    final trip = provider.selectedTrip!;
    final stops = provider.currentStops;
    final checklist = provider.currentChecklist;
    final expenses = provider.currentExpenses;
    final documents = provider.currentTravelDocuments;

    String formatDateLocal(DateTime dt) {
      return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
    }

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
                        style: const pw.TextStyle(
                          fontSize: 14,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.Text(
                        "Periodo: ${formatDateLocal(trip.startDate)} - ${formatDateLocal(trip.endDate)}",
                        style: const pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        "SAY MY TRAVEL",
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue800,
                        ),
                      ),
                      pw.Text(
                        "Generato automaticamente",
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Informazioni Generali
            if (trip.generalInfo.isNotEmpty) ...[
              pw.Text(
                "Informazioni Generali",
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Paragraph(
                text: trip.generalInfo,
                style: const pw.TextStyle(fontSize: 11, color: PdfColors.black),
              ),
              pw.SizedBox(height: 20),
            ],

            // Itinerario
            pw.Text(
              "Programma di Viaggio (Itinerario)",
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue800,
              ),
            ),
            pw.SizedBox(height: 10),
            if (stops.isEmpty)
              pw.Text(
                "Nessuna tappa pianificata.",
                style: const pw.TextStyle(
                  fontSize: 11,
                  fontStyle: pw.FontStyle.italic,
                ),
              )
            else
              ...stops.map((stop) {
                final activities = provider.getActivitiesForStop(stop.id!);
                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 16),
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(8),
                    ),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            "Giorno ${stop.itineraryOrder}: ${stop.name}",
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          pw.Text(
                            "${formatDateLocal(stop.dateTime)} ${stop.dateTime.hour.toString().padLeft(2, '0')}:${stop.dateTime.minute.toString().padLeft(2, '0')}",
                            style: const pw.TextStyle(
                              color: PdfColors.grey700,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      if (stop.location.isNotEmpty) ...[
                        pw.SizedBox(height: 4),
                        pw.Text(
                          "Località: ${stop.location}",
                          style: const pw.TextStyle(fontSize: 11),
                        ),
                      ],
                      if (stop.description.isNotEmpty) ...[
                        pw.SizedBox(height: 6),
                        pw.Text(
                          stop.description,
                          style: const pw.TextStyle(fontSize: 11),
                        ),
                      ],
                      if (stop.notes.isNotEmpty) ...[
                        pw.SizedBox(height: 6),
                        pw.Text(
                          "Note: ${stop.notes}",
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontStyle: pw.FontStyle.italic,
                            color: PdfColors.orange700,
                          ),
                        ),
                      ],
                      if (activities.isNotEmpty) ...[
                        pw.SizedBox(height: 10),
                        pw.Text(
                          "Attività giornaliere:",
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Table(
                          border: pw.TableBorder.all(
                            color: PdfColors.grey200,
                            width: 0.5,
                          ),
                          columnWidths: {
                            0: const pw.FixedColumnWidth(60),
                            1: const pw.FlexColumnWidth(),
                            2: const pw.FixedColumnWidth(80),
                            3: const pw.FixedColumnWidth(60),
                          },
                          children: [
                            pw.TableRow(
                              children: [
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(4),
                                  child: pw.Text(
                                    "Orario",
                                    style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(4),
                                  child: pw.Text(
                                    "Nome / Categoria",
                                    style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(4),
                                  child: pw.Text(
                                    "Stato",
                                    style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(4),
                                  child: pw.Text(
                                    "Costo",
                                    style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            ...activities.map(
                              (act) => pw.TableRow(
                                children: [
                                  pw.Padding(
                                    padding: const pw.EdgeInsets.all(4),
                                    child: pw.Text(
                                      act.time,
                                      style: const pw.TextStyle(fontSize: 10),
                                    ),
                                  ),
                                  pw.Padding(
                                    padding: const pw.EdgeInsets.all(4),
                                    child: pw.Text(
                                      "${act.name} [${act.type}]",
                                      style: const pw.TextStyle(fontSize: 10),
                                    ),
                                  ),
                                  pw.Padding(
                                    padding: const pw.EdgeInsets.all(4),
                                    child: pw.Text(
                                      act.status,
                                      style: const pw.TextStyle(fontSize: 10),
                                    ),
                                  ),
                                  pw.Padding(
                                    padding: const pw.EdgeInsets.all(4),
                                    child: pw.Text(
                                      act.cost > 0
                                          ? "${act.cost.toStringAsFixed(2)} €"
                                          : "Gratis",
                                      style: const pw.TextStyle(fontSize: 10),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              }),
            pw.SizedBox(height: 20),

            // Checklist
            pw.Text(
              "Checklist delle cose da fare",
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue800,
              ),
            ),
            pw.SizedBox(height: 10),
            if (checklist.isEmpty)
              pw.Text(
                "Nessun elemento presente nella checklist.",
                style: const pw.TextStyle(
                  fontSize: 11,
                  fontStyle: pw.FontStyle.italic,
                ),
              )
            else
              pw.Column(
                children: checklist.map((item) {
                  return pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 2),
                    child: pw.Row(
                      children: [
                        pw.Container(
                          width: 10,
                          height: 10,
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: PdfColors.grey800),
                            color: item.isChecked ? PdfColors.blue800 : null,
                          ),
                        ),
                        pw.SizedBox(width: 8),
                        pw.Text(
                          "${item.itemText} (${item.category} - Priorità: ${item.priority})",
                          style: pw.TextStyle(
                            fontSize: 11,
                            decoration: item.isChecked
                                ? pw.TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            pw.SizedBox(height: 20),

            // Spese
            pw.Text(
              "Resoconto Finanziario (Budget e Spese)",
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue800,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  "Budget Totale: ${provider.totalBudget.toStringAsFixed(2)} €",
                  style: const pw.TextStyle(fontSize: 11),
                ),
                pw.Text(
                  "Speso Effettivo: ${provider.totalExpenses.toStringAsFixed(2)} €",
                  style: const pw.TextStyle(fontSize: 11),
                ),
                pw.Text(
                  "Rimanente Effettivo: ${provider.remainingBudget.toStringAsFixed(2)} €",
                  style: pw.TextStyle(
                    fontSize: 11,
                    color: provider.remainingBudget < 0
                        ? PdfColors.red800
                        : PdfColors.green800,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 10),
            if (expenses.isEmpty)
              pw.Text(
                "Nessuna spesa registrata.",
                style: const pw.TextStyle(
                  fontSize: 11,
                  fontStyle: pw.FontStyle.italic,
                ),
              )
            else
              pw.Table(
                border: pw.TableBorder.all(
                  color: PdfColors.grey200,
                  width: 0.5,
                ),
                children: [
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          "Spesa",
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          "Categoria",
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          "Stato",
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          "Importo (Valuta Originale)",
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  ...expenses.map(
                    (ex) => pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            ex.title,
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            ex.category,
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            ex.status,
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            "${ex.amount.toStringAsFixed(2)} ${ex.currency}",
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            pw.SizedBox(height: 20),

            // Biglietti Wallet
            pw.Text(
              "Biglietti e Documenti del Wallet",
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue800,
              ),
            ),
            pw.SizedBox(height: 10),
            if (documents.isEmpty)
              pw.Text(
                "Nessun biglietto caricato.",
                style: const pw.TextStyle(
                  fontSize: 11,
                  fontStyle: pw.FontStyle.italic,
                ),
              )
            else
              ...documents.map(
                (doc) => pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 12),
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(6),
                    ),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        "${doc.documentType.toUpperCase()}: ${doc.title}",
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          if (doc.dateTime != null)
                            pw.Text(
                              "Data: ${formatDateLocal(doc.dateTime!)} alle ${doc.dateTime!.hour.toString().padLeft(2, '0')}:${doc.dateTime!.minute.toString().padLeft(2, '0')}",
                              style: const pw.TextStyle(fontSize: 10),
                            ),
                          if (doc.bookingCode != null)
                            pw.Text(
                              "Codice (PNR): ${doc.bookingCode}",
                              style: pw.TextStyle(
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          if (doc.seat != null)
                            pw.Text(
                              "Posto: ${doc.seat}",
                              style: const pw.TextStyle(fontSize: 10),
                            ),
                          if (doc.gate != null)
                            pw.Text(
                              doc.documentType == 'Hotel'
                                  ? "Indirizzo: ${doc.gate}"
                                  : "Gate: ${doc.gate}",
                              style: const pw.TextStyle(fontSize: 10),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
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
                            ).dividerColor.withOpacity(0.3),
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
                                  UsefulInfoTab.showAddEditTravelDocumentDialog(
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
                                            color: Colors.white.withOpacity(
                                              0.7,
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
                                            color: Colors.white.withOpacity(
                                              0.7,
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
                                              color: Colors.white.withOpacity(
                                                0.7,
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
                                              color: Colors.white.withOpacity(
                                                0.7,
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
                                              color: Colors.white.withOpacity(
                                                0.7,
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
                                                color: Colors.white.withOpacity(
                                                  0.4,
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
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
                  color: Colors.black.withOpacity(0.02),
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
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _selectedUsefulInfoCategory,
                    decoration: InputDecoration(
                      labelText: "Filtra per Categoria",
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    selectedItemBuilder: (BuildContext context) {
                      return [
                        'Tutti',
                        'Nota',
                        'Promemoria',
                        'Prenotazione',
                        'Indirizzo',
                        'Altro',
                      ].map((cat) {
                        return Row(
                          children: [
                            if (cat != 'Tutti') ...[
                              Icon(
                                UsefulInfoTab.getUsefulInfoCategoryIcon(cat),
                                size: 16,
                                color: UsefulInfoTab.getUsefulInfoCategoryColor(
                                  cat,
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            Expanded(
                              child: Text(cat, overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        );
                      }).toList();
                    },
                    items:
                        [
                              'Tutti',
                              'Nota',
                              'Promemoria',
                              'Prenotazione',
                              'Indirizzo',
                              'Altro',
                            ]
                            .map(
                              (cat) => DropdownMenuItem<String>(
                                value: cat,
                                child: Row(
                                  children: [
                                    if (cat != 'Tutti') ...[
                                      Icon(
                                        UsefulInfoTab.getUsefulInfoCategoryIcon(
                                          cat,
                                        ),
                                        size: 16,
                                        color:
                                            UsefulInfoTab.getUsefulInfoCategoryColor(
                                              cat,
                                            ),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    Expanded(
                                      child: Text(
                                        cat,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
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

          Expanded(
            child: filteredInfo.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.note_alt_outlined,
                          size: 64,
                          color: Theme.of(context).hintColor.withOpacity(0.5),
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
                                color: catColor.withOpacity(0.1),
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
                                  onPressed: () =>
                                      UsefulInfoTab.showAddEditUsefulInfoDialog(
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
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary.withOpacity(0.02),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Theme.of(
                                        context,
                                      ).dividerColor.withOpacity(0.05),
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
                          color: Theme.of(context).hintColor.withOpacity(0.5),
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
                                color: Colors.black.withOpacity(0.05),
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
                                    color: Colors.white.withOpacity(0.2),
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
                                          color: Colors.white.withOpacity(0.7),
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
