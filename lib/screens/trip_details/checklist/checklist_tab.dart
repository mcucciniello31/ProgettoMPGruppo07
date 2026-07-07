import 'package:flutter/material.dart';
import '../../../models/checklist_item.dart';
import '../../../providers/travel_provider.dart';
import 'add_checklist_item_screen.dart';

class ChecklistTab extends StatefulWidget {
  final TravelProvider provider;

  const ChecklistTab({super.key, required this.provider});

  @override
  State<ChecklistTab> createState() => _ChecklistTabState();
}

class _ChecklistTabState extends State<ChecklistTab> {
  String _selectedChecklistCategory = 'Tutti';
  String _selectedChecklistStatusFilter =
      'Tutti'; // Opzioni: Tutti, Da completare, Completati
  String _selectedChecklistPriorityFilter =
      'Tutte'; // Opzioni: Tutte, Bassa, Media, Alta

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Alta':
        return Colors.redAccent;
      case 'Bassa':
        return Colors.green;
      case 'Media':
      default:
        return Colors.orange;
    }
  }

  IconData _getChecklistCategoryIcon(String category) {
    switch (category) {
      case 'Bagaglio':
        return Icons.backpack_outlined;
      case 'Documenti':
        return Icons.assignment_outlined;
      case 'Pre-partenza':
        return Icons.hourglass_top_outlined;
      case 'Prenotazioni':
        return Icons.book_online_outlined;
      case 'Acquisti':
        return Icons.shopping_bag_outlined;
      case 'Altro':
      default:
        return Icons.check_box_outlined;
    }
  }

  void _showDeleteChecklistItemConfirmation(
    TravelProvider provider,
    ChecklistItem item,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Elimina Elemento"),
          content: Text("Sei sicuro di voler eliminare '${item.itemText}'?"),
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
                provider.deleteChecklistItem(item.id!);
                Navigator.pop(context);
              },
              child: const Text("Elimina"),
            ),
          ],
        );
      },
    );
  }

  void _showEditChecklistItemDialog(
    TravelProvider provider,
    ChecklistItem item,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddChecklistItemScreen(
          tripId: provider.selectedTrip!.id!,
          checklistItem: item,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    final list = provider.currentChecklist;

    // Filtra la lista della checklist per categoria, stato e priorità
    final filteredList = list.where((item) {
      if (_selectedChecklistCategory != 'Tutti' &&
          item.category != _selectedChecklistCategory) {
        return false;
      }
      if (_selectedChecklistStatusFilter != 'Tutti') {
        final wantChecked = _selectedChecklistStatusFilter == 'Completati';
        if (item.isChecked != wantChecked) {
          return false;
        }
      }
      if (_selectedChecklistPriorityFilter != 'Tutte' &&
          item.priority != _selectedChecklistPriorityFilter) {
        return false;
      }
      return true;
    }).toList();

    // La percentuale di avanzamento della checklist si adatta ai filtri correnti
    final categoryOnlyList = _selectedChecklistCategory == 'Tutti'
        ? list
        : list
              .where((item) => item.category == _selectedChecklistCategory)
              .toList();

    final categoryCheckedCount = categoryOnlyList
        .where((i) => i.isChecked)
        .length;
    final categoryRate = categoryOnlyList.isEmpty
        ? 0.0
        : categoryCheckedCount / categoryOnlyList.length;

    final overallCheckedCount = list.where((i) => i.isChecked).length;
    final overallRate = list.isEmpty ? 0.0 : overallCheckedCount / list.length;

    return Column(
      children: [
        // Menu a discesa per filtrare gli elementi per categoria, stato e priorità
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedChecklistCategory,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: "Categoria",
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  selectedItemBuilder: (BuildContext context) {
                    return [
                      'Tutti',
                      'Bagaglio',
                      'Documenti',
                      'Pre-partenza',
                      'Prenotazioni',
                      'Acquisti',
                      'Altro',
                    ].map((cat) {
                      return Row(
                        children: [
                          if (cat != 'Tutti') ...[
                            Icon(
                              _getChecklistCategoryIcon(cat),
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
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
                            'Bagaglio',
                            'Documenti',
                            'Pre-partenza',
                            'Prenotazioni',
                            'Acquisti',
                            'Altro',
                          ]
                          .map(
                            (cat) => DropdownMenuItem<String>(
                              value: cat,
                              child: Row(
                                children: [
                                  if (cat != 'Tutti') ...[
                                    Icon(
                                      _getChecklistCategoryIcon(cat),
                                      size: 16,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
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
                        _selectedChecklistCategory = val;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedChecklistStatusFilter,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: "Stato",
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: ['Tutti', 'Da completare', 'Completati']
                      .map(
                        (status) => DropdownMenuItem<String>(
                          value: status,
                          child: Text(status),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedChecklistStatusFilter = val;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedChecklistPriorityFilter,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: "Priorità",
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  selectedItemBuilder: (BuildContext context) {
                    return ['Tutte', 'Bassa', 'Media', 'Alta'].map((prio) {
                      return Row(
                        children: [
                          if (prio != 'Tutte') ...[
                            Icon(
                              Icons.flag,
                              size: 14,
                              color: _getPriorityColor(prio),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Expanded(
                            child: Text(prio, overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      );
                    }).toList();
                  },
                  items: ['Tutte', 'Bassa', 'Media', 'Alta']
                      .map(
                        (prio) => DropdownMenuItem<String>(
                          value: prio,
                          child: Row(
                            children: [
                              if (prio != 'Tutte') ...[
                                Icon(
                                  Icons.flag,
                                  size: 14,
                                  color: _getPriorityColor(prio),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Expanded(
                                child: Text(
                                  prio,
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
                        _selectedChecklistPriorityFilter = val;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ),

        // Scheda visuale dello stato di avanzamento
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedChecklistCategory == 'Tutti'
                            ? "Progresso Checklist Totale"
                            : "Progresso $_selectedChecklistCategory",
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "${(categoryRate * 100).toStringAsFixed(0)}%",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: categoryRate,
                      minHeight: 10,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "$categoryCheckedCount di ${filteredList.length} elementi completati",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (_selectedChecklistCategory != 'Tutti')
                        Text(
                          "Totale: $overallCheckedCount su ${list.length} (${(overallRate * 100).toStringAsFixed(0)}%)",
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // Elementi visualizzati per la checklist
        Expanded(
          child: filteredList.isEmpty
              ? Center(
                  child: Text(
                    "Nessun elemento in questa categoria,\naggiungine uno qui sotto!",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredList.length + 1,
                  itemBuilder: (context, index) {
                    if (index == filteredList.length) {
                      return const SizedBox(height: 80);
                    }
                    final item = filteredList[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: Checkbox(
                          value: item.isChecked,
                          activeColor: Theme.of(context).colorScheme.primary,
                          onChanged: (_) => provider.toggleChecklistItem(item),
                        ),
                        title: Text(
                          item.itemText,
                          style: TextStyle(
                            decoration: item.isChecked
                                ? TextDecoration.lineThrough
                                : null,
                            color: item.isChecked ? Colors.grey : null,
                          ),
                        ),
                        subtitle: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              if (_selectedChecklistCategory == 'Tutti') ...[
                                Icon(
                                  _getChecklistCategoryIcon(item.category),
                                  size: 12,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  item.category,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ],
                              Icon(
                                Icons.flag,
                                size: 12,
                                color: _getPriorityColor(item.priority),
                              ),
                            ],
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
                                  _showEditChecklistItemDialog(provider, item),
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(8),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.redAccent,
                              ),
                              onPressed: () =>
                                  _showDeleteChecklistItemConfirmation(
                                    provider,
                                    item,
                                  ),
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(8),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
