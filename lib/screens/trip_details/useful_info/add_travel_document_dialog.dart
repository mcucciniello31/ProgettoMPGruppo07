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

    // Gestione Carrozza e Fila per Treno
    String initialCarrozza = '';
    String initialFila = '';
    if (isEditing && doc.documentType == 'Treno' && doc.gate != null) {
      if (doc.gate!.contains('|')) {
        final parts = doc.gate!.split('|');
        initialCarrozza = parts[0];
        initialFila = parts[1];
      } else {
        initialCarrozza = doc.gate!;
      }
    } else {
      initialCarrozza = doc?.gate ?? '';
    }

    final gateController = TextEditingController(text: initialCarrozza);
    final trainRowController = TextEditingController(text: initialFila);
    final notesController = TextEditingController(text: doc?.notes ?? '');

    String selectedDocType = doc?.documentType ?? 'Volo';
    DateTime? selectedDateTime = doc?.dateTime;

    bool isAssigned = true;
    if (isEditing &&
        (doc.documentType == 'Treno' || doc.documentType == 'Pullman')) {
      if (doc.seat == 'Posto unico') {
        isAssigned = false;
      }
    }

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
                    if (selectedDocType == 'Treno' ||
                        selectedDocType == 'Pullman') ...[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Tipologia Posto *",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3B6A8A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setDialogState(() {
                                      isAssigned = false;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: !isAssigned
                                          ? Colors.blue.shade50
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: !isAssigned
                                            ? Colors.blue
                                            : const Color(0xFFADCDE2),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.confirmation_number_outlined,
                                          color: !isAssigned
                                              ? Colors.blue
                                              : Colors.grey,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          "Posto Unico",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setDialogState(() {
                                      isAssigned = true;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isAssigned
                                          ? Colors.blue.shade50
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isAssigned
                                            ? Colors.blue
                                            : const Color(0xFFADCDE2),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons
                                              .airline_seat_recline_normal_outlined,
                                          color: isAssigned
                                              ? Colors.blue
                                              : Colors.grey,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          "Assegnato",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
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
                    else if (selectedDocType == 'Volo' || isAssigned)
                      if (selectedDocType == 'Treno')
                        Column(
                          children: [
                            TextField(
                              controller: seatController,
                              decoration: InputDecoration(
                                labelText: "Posto",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: gateController,
                                    decoration: InputDecoration(
                                      labelText: "Carrozza",
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: trainRowController,
                                    maxLength: 1,
                                    textCapitalization:
                                        TextCapitalization.characters,
                                    decoration: InputDecoration(
                                      labelText: "Fila",
                                      counterText: "",
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
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
                                  labelText: selectedDocType == 'Pullman'
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

                    final isSingleField =
                        selectedDocType == 'Hotel' ||
                        selectedDocType == 'Attrazione' ||
                        selectedDocType == 'Altro';
                    final bool isTrainOrBus =
                        selectedDocType == 'Treno' ||
                        selectedDocType == 'Pullman';

                    final trainRow = trainRowController.text
                        .trim()
                        .toUpperCase();

                    if (title.startsWith(' ') ||
                        bookingCode.startsWith(' ') ||
                        notes.startsWith(' ') ||
                        (selectedDocType == 'Volo' &&
                            (seat.startsWith(' ') || gate.startsWith(' '))) ||
                        (selectedDocType == 'Pullman' &&
                            isAssigned &&
                            (seat.startsWith(' ') || gate.startsWith(' '))) ||
                        (selectedDocType == 'Treno' &&
                            isAssigned &&
                            (seat.startsWith(' ') ||
                                gate.startsWith(' ') ||
                                trainRowController.text.startsWith(' '))) ||
                        (isSingleField && gate.startsWith(' '))) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Il testo non può iniziare con uno spazio",
                          ),
                        ),
                      );
                      return;
                    }

                    if (selectedDocType == 'Treno' &&
                        isAssigned &&
                        trainRow.isNotEmpty) {
                      final regExp = RegExp(r'^[A-Z]$');
                      if (!regExp.hasMatch(trainRow)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "La fila deve essere una singola lettera da A a Z",
                            ),
                          ),
                        );
                        return;
                      }
                    }

                    if (title.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Il titolo è obbligatorio"),
                        ),
                      );
                      return;
                    }

                    final String? finalSeat = isTrainOrBus && !isAssigned
                        ? "Posto unico"
                        : (isSingleField
                              ? null
                              : (seat.trim().isEmpty ? null : seat.trim()));

                    String? finalGate;
                    if (isTrainOrBus && !isAssigned) {
                      finalGate = null;
                    } else if (selectedDocType == 'Treno') {
                      final carr = gate.trim();
                      if (carr.isEmpty && trainRow.isEmpty) {
                        finalGate = null;
                      } else {
                        finalGate = "$carr|$trainRow";
                      }
                    } else {
                      finalGate = gate.trim().isEmpty ? null : gate.trim();
                    }

                    final newDoc = TravelDocument(
                      id: doc?.id,
                      tripId: provider.selectedTrip!.id!,
                      title: title.trim(),
                      documentType: selectedDocType,
                      bookingCode: bookingCode.trim().isEmpty
                          ? null
                          : bookingCode.trim(),
                      seat: finalSeat,
                      gate: finalGate,
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
