import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:say_my_travel/providers/travel_provider.dart';

class ExportTripDialog {
  static void show(BuildContext context, TravelProvider provider) {
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
            final costStr = act.cost > 0 ? " (A pagamento)" : " (Gratuito)";
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
                    color: Theme.of(
                      context,
                    ).dividerColor.withValues(alpha: 0.2),
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
                                      act.cost > 0 ? "A pagamento" : "Gratis",
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
                          if (doc.gate != null && doc.gate!.isNotEmpty)
                            pw.Text(
                              doc.documentType == 'Hotel'
                                  ? "Indirizzo: ${doc.gate}"
                                  : doc.documentType == 'Treno'
                                  ? "Carrozza: ${doc.gate}"
                                  : doc.documentType == 'Pullman'
                                  ? "Fila: ${doc.gate}"
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
}
