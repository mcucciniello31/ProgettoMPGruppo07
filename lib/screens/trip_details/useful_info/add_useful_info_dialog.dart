import 'package:flutter/material.dart';
import '../../../models/useful_info.dart';
import 'package:say_my_travel/providers/travel_provider.dart';
import 'useful_info_tab.dart';

class AddUsefulInfoDialog {
  static void show(
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
                isEditing ? "Modifica Utility" : "Nuova Utility",
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFADCDE2),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "Categoria",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3B6A8A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          DropdownButtonHideUnderline(
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              value: selectedCategory,
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
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
                                        UsefulInfoTab.getUsefulInfoCategoryIcon(
                                          cat,
                                        ),
                                        size: 18,
                                        color:
                                            UsefulInfoTab.getUsefulInfoCategoryColor(
                                              cat,
                                            ),
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
                                                UsefulInfoTab.getUsefulInfoCategoryIcon(
                                                  cat,
                                                ),
                                                size: 18,
                                                color:
                                                    UsefulInfoTab.getUsefulInfoCategoryColor(
                                                      cat,
                                                    ),
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
                          ),
                        ],
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
}
