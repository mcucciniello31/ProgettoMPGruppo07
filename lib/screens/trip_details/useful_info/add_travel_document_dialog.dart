import 'package:flutter/material.dart';
import '../../../models/travel_document.dart';
import 'package:say_my_travel/providers/travel_provider.dart';

class AddTravelDocumentDialog {
  static void show(
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
                      initialValue: selectedDocType,
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
                            ).dividerColor.withValues(alpha: 0.5),
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
}
