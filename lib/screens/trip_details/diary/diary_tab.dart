import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../../models/diary_entry.dart';
import '../../../models/activity.dart';
import '../../../providers/travel_provider.dart';
import '../../../theme/app_theme.dart';

class DiaryTab extends StatefulWidget {
  final TravelProvider provider;

  const DiaryTab({super.key, required this.provider});

  @override
  State<DiaryTab> createState() => _DiaryTabState();

  // Permette alla parent screen (trip_details_screen) di richiamare questo dialog dal FAB
  static void showAddEditDiaryDialog(BuildContext context, DiaryEntry? entry) {
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
                                    buildDiaryImage(selectedImagePath),
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

  static Widget buildDiaryImage(String? imagePath) {
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
            child: const Icon(
              Icons.broken_image_outlined,
              color: Colors.redAccent,
            ),
          );
        },
      );
    }
    return Image.network(
      imagePath,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.red.shade50,
          child: const Icon(
            Icons.broken_image_outlined,
            color: Colors.redAccent,
          ),
        );
      },
    );
  }

  /// Costruisce un badge testuale per l'associazione del ricordo
  static Widget buildAssociationBadge(DiaryEntry entry) {
    if (entry.associatedType == 'Generale') {
      return const SizedBox.shrink();
    }

    final IconData icon;
    final Color color;

    if (entry.associatedType == 'Tappa') {
      icon = Icons.map_outlined;
      color = Colors.teal;
    } else {
      icon = Icons.local_activity_outlined;
      color = Colors.deepPurple;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              entry.associatedName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiaryTabState extends State<DiaryTab> {
  String _formatDate(DateTime dt) {
    return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
  }

  void _showFullScreenImage(
    BuildContext context,
    String? imagePath,
    int? entryId,
  ) {
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
                      onTap: () => _showFullScreenImage(
                        context,
                        entry.imagePath,
                        entry.id,
                      ),
                      child: Hero(
                        tag: 'diary_image_${entry.id}',
                        child: DiaryTab.buildDiaryImage(entry.imagePath),
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.1),
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
                                DiaryTab.showAddEditDiaryDialog(context, entry);
                              },
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.redAccent,
                                size: 20,
                              ),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (subCtx) => AlertDialog(
                                    title: const Text("Elimina Ricordo"),
                                    content: const Text(
                                      "Sei sicuro di voler eliminare questo ricordo permanentemente?",
                                    ),
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
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                "Ricordo eliminato con successo!",
                                              ),
                                            ),
                                          );
                                        },
                                        child: const Text(
                                          "Elimina",
                                          style: TextStyle(
                                            color: Colors.redAccent,
                                          ),
                                        ),
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
                    // Badge associazione sotto la data
                    if (entry.associatedType != 'Generale') ...[
                      const SizedBox(height: 8),
                      _buildDetailAssociationBadge(entry),
                    ],
                    const SizedBox(height: 12),
                    Text(
                      entry.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 180),
                      child: SingleChildScrollView(
                        child: Text(
                          entry.content,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                height: 1.5,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color
                                    ?.withOpacity(0.85),
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

  Widget _buildDetailAssociationBadge(DiaryEntry entry) {
    final IconData icon;
    final Color color;
    final String label;

    if (entry.associatedType == 'Tappa') {
      icon = Icons.map_outlined;
      color = Colors.teal;
      label = "Tappa: ${entry.associatedName}";
    } else {
      icon = Icons.local_activity_outlined;
      color = Colors.deepPurple;
      label = "Attività: ${entry.associatedName}";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
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
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 80),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.70,
      ),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return Card(
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
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
                        child: DiaryTab.buildDiaryImage(entry.imagePath),
                      ),
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _formatDate(entry.date),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
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
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entry.content,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(fontSize: 11),
                      ),
                      if (entry.associatedType != 'Generale') ...[
                        const SizedBox(height: 6),
                        DiaryTab.buildAssociationBadge(entry),
                      ],
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
}
