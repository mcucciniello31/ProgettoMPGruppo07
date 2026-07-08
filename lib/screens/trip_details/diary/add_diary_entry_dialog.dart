import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../../models/diary_entry.dart';
import '../../../models/activity.dart';
import 'package:say_my_travel/providers/travel_provider.dart';
import '../../../theme/app_theme.dart';
import 'diary_tab.dart';

class AddDiaryEntryDialog {
  static void show(BuildContext context, DiaryEntry? entry) {
    final provider = Provider.of<TravelProvider>(context, listen: false);
    final isEdit = entry != null;
    final titleController = TextEditingController(text: entry?.title ?? '');
    final contentController = TextEditingController(text: entry?.content ?? '');
    DateTime selectedDate = entry?.date ?? DateTime.now();
    String? selectedImagePath = entry?.imagePath;

    // Variabili di stato per l'associazione
    String associatedType = entry?.associatedType ?? 'Generale';
    int? selectedStopId;
    int? selectedActivityId;

    // Carica tappe e attività
    final stops = provider.currentStops;
    final List<Activity> activities = [];
    for (var stop in stops) {
      activities.addAll(provider.getActivitiesForStop(stop.id!));
    }

    // Se in modifica, ripristina gli ID selezionati
    if (isEdit && entry.associatedId != null) {
      if (entry.associatedType == 'Tappa') {
        selectedStopId = entry.associatedId;
      } else if (entry.associatedType == 'Attivita') {
        selectedActivityId = entry.associatedId;
      }
    }

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

          Widget buildAssociationChip(
            String label,
            String value,
            IconData icon,
          ) {
            final isSelected = associatedType == value;
            final theme = Theme.of(context);
            final primaryColor = theme.colorScheme.primary;
            final onSurface = theme.colorScheme.onSurface;

            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setDialogState(() {
                    associatedType = value;
                    if (value == 'Generale') {
                      selectedStopId = null;
                      selectedActivityId = null;
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? primaryColor.withOpacity(0.15)
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? primaryColor
                          : theme.dividerColor.withOpacity(0.2),
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icon,
                        size: 18,
                        color: isSelected
                            ? primaryColor
                            : onSurface.withOpacity(0.6),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: isSelected
                              ? primaryColor
                              : onSurface.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: Row(
              children: [
                Icon(
                  isEdit
                      ? Icons.edit_note_outlined
                      : Icons.add_photo_alternate_outlined,
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
                            color: Theme.of(
                              context,
                            ).dividerColor.withOpacity(0.3),
                          ),
                        ),
                        child: selectedImagePath == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_a_photo_outlined,
                                    size: 36,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary.withOpacity(0.7),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    "Seleziona Foto",
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Tocca per scegliere o scattare",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Theme.of(
                                        context,
                                      ).textTheme.bodySmall?.color,
                                    ),
                                  ),
                                ],
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    DiaryTab.buildDiaryImage(selectedImagePath),
                                    Positioned(
                                      right: 8,
                                      bottom: 8,
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.6),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.edit,
                                          color: Colors.white,
                                          size: 16,
                                        ),
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
                      label: Text(
                        "Data: ${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}",
                      ),
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
                    const SizedBox(height: 16),

                    // Sezione Associazione Ricordo
                    Text(
                      "Associa a",
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        buildAssociationChip(
                          'Generale',
                          'Generale',
                          Icons.photo_album_outlined,
                        ),
                        const SizedBox(width: 8),
                        buildAssociationChip(
                          'Tappa',
                          'Tappa',
                          Icons.map_outlined,
                        ),
                        const SizedBox(width: 8),
                        buildAssociationChip(
                          'Attività',
                          'Attivita',
                          Icons.local_activity_outlined,
                        ),
                      ],
                    ),
                    if (associatedType == 'Tappa') ...[
                      const SizedBox(height: 12),
                      stops.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                "Nessuna tappa presente in questo viaggio.",
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 12,
                                ),
                              ),
                            )
                          : DropdownButtonFormField<int>(
                              value: selectedStopId,
                              decoration: InputDecoration(
                                labelText: "Seleziona Tappa",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              items: stops.map((stop) {
                                return DropdownMenuItem<int>(
                                  value: stop.id,
                                  child: Text(
                                    "Giorno ${stop.itineraryOrder} • ${stop.name}",
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setDialogState(() {
                                  selectedStopId = val;
                                });
                              },
                            ),
                    ],
                    if (associatedType == 'Attivita') ...[
                      const SizedBox(height: 12),
                      activities.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                "Nessuna attività programmata in questo viaggio.",
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 12,
                                ),
                              ),
                            )
                          : DropdownButtonFormField<int>(
                              value: selectedActivityId,
                              decoration: InputDecoration(
                                labelText: "Seleziona Attività",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              items: activities.map((act) {
                                return DropdownMenuItem<int>(
                                  value: act.id,
                                  child: Row(
                                    children: [
                                      Icon(
                                        AppTheme.activityIcons[act.type] ??
                                            Icons.local_activity,
                                        size: 16,
                                        color:
                                            AppTheme.activityColors[act.type] ??
                                            Colors.grey,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          act.name,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setDialogState(() {
                                  selectedActivityId = val;
                                });
                              },
                            ),
                    ],
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
                      const SnackBar(
                        content: Text(
                          "Il titolo non può essere vuoto o iniziare con uno spazio.",
                        ),
                      ),
                    );
                    return;
                  }
                  if (content.isEmpty || content.startsWith(' ')) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "La descrizione non può essere vuota o iniziare con uno spazio.",
                        ),
                      ),
                    );
                    return;
                  }

                  // Risolvi l'associazione
                  String finalAssociatedType = associatedType;
                  int? finalAssociatedId;
                  String finalAssociatedName = 'Generale';

                  if (associatedType == 'Tappa' && selectedStopId != null) {
                    finalAssociatedId = selectedStopId;
                    final stop = stops.firstWhere(
                      (s) => s.id == selectedStopId,
                    );
                    finalAssociatedName = stop.name;
                  } else if (associatedType == 'Attivita' &&
                      selectedActivityId != null) {
                    finalAssociatedId = selectedActivityId;
                    final act = activities.firstWhere(
                      (a) => a.id == selectedActivityId,
                    );
                    finalAssociatedName = act.name;
                  } else {
                    finalAssociatedType = 'Generale';
                  }

                  String? finalPath = selectedImagePath;
                  if (selectedImagePath != null &&
                      (selectedImagePath!.startsWith('/') ||
                          selectedImagePath!.contains(':/')) &&
                      (entry == null || entry.imagePath != selectedImagePath)) {
                    try {
                      final appDocDir =
                          await getApplicationDocumentsDirectory();
                      final extension = path.extension(selectedImagePath!);
                      final fileName =
                          "diary_${DateTime.now().millisecondsSinceEpoch}$extension";
                      final savedFile = await File(
                        selectedImagePath!,
                      ).copy("${appDocDir.path}/$fileName");
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
                      associatedType: finalAssociatedType,
                      associatedId: finalAssociatedId,
                      associatedName: finalAssociatedName,
                    );
                    provider.updateDiaryEntry(updated);
                  } else {
                    final newEntry = DiaryEntry(
                      tripId: provider.selectedTrip!.id!,
                      title: title,
                      content: content,
                      date: selectedDate,
                      imagePath: finalPath,
                      associatedType: finalAssociatedType,
                      associatedId: finalAssociatedId,
                      associatedName: finalAssociatedName,
                    );
                    provider.addDiaryEntry(newEntry);
                  }

                  Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isEdit ? "Ricordo modificato!" : "Ricordo aggiunto!",
                        ),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(isEdit ? "Salva" : "Aggiungi"),
              ),
            ],
          );
        },
      ),
    );
  }
}
