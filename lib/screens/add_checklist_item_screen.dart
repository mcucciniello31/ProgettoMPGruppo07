import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/checklist_item.dart';
import '../providers/travel_provider.dart';

class AddChecklistItemScreen extends StatefulWidget {
  final int tripId;
  final ChecklistItem? checklistItem; // Se valorizzato, siamo in modifica

  const AddChecklistItemScreen({
    super.key,
    required this.tripId,
    this.checklistItem,
  });

  @override
  State<AddChecklistItemScreen> createState() => _AddChecklistItemScreenState();
}

class _AddChecklistItemScreenState extends State<AddChecklistItemScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _textController;

  String _selectedCategory = 'Bagaglio';
  String _selectedPriority = 'Media';

  final List<String> _categories = [
    'Bagaglio',
    'Documenti',
    'Pre-partenza',
    'Prenotazioni',
    'Acquisti',
    'Altro',
  ];

  final List<String> _priorities = ['Bassa', 'Media', 'Alta'];

  @override
  void initState() {
    super.initState();
    final isEditing = widget.checklistItem != null;
    _textController = TextEditingController(
      text: isEditing ? widget.checklistItem!.itemText : '',
    );
    if (isEditing) {
      _selectedCategory = widget.checklistItem!.category;
      _selectedPriority = widget.checklistItem!.priority;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
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

  void _showValidationErrorsDialog(List<String> errors) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(width: 8),
              const Expanded(child: Text("Campi non validi o mancanti")),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: errors
                .map(
                  (err) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "• ",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Expanded(child: Text(err)),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Ho capito"),
            ),
          ],
        );
      },
    );
  }

  void _save() {
    final text = _textController.text;
    final errors = <String>[];

    if (text.isEmpty) {
      errors.add("La descrizione dell'elemento è obbligatoria");
    } else if (text.startsWith(' ')) {
      errors.add("La descrizione non può iniziare con uno spazio");
    }

    if (errors.isNotEmpty) {
      _showValidationErrorsDialog(errors);
      return;
    }

    final provider = Provider.of<TravelProvider>(context, listen: false);
    final isEditing = widget.checklistItem != null;

    if (isEditing) {
      final updatedItem = widget.checklistItem!.copyWith(
        itemText: text.trim(),
        category: _selectedCategory,
        priority: _selectedPriority,
      );
      provider.updateChecklistItem(updatedItem);
    } else {
      final newItem = ChecklistItem(
        tripId: widget.tripId,
        itemText: text.trim(),
        category: _selectedCategory,
        priority: _selectedPriority,
        isChecked: false,
      );
      provider.addChecklistItem(newItem);
    }

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isEditing
              ? "Elemento modificato con successo!"
              : "Elemento aggiunto alla checklist con successo!",
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.checklistItem != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? "Modifica Elemento" : "Nuovo Elemento"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isEditing
                    ? "Modifica i dettagli dell'elemento della checklist."
                    : "Aggiungi un nuovo promemoria o elemento da preparare per il viaggio.",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),

              // 1. Campo di testo per l'elemento
              TextFormField(
                controller: _textController,
                decoration: InputDecoration(
                  labelText: "Cosa portare o fare *",
                  hintText:
                      "Es: Caricabatterie, passaporto, stampare biglietti...",
                  prefixIcon: const Icon(Icons.playlist_add_check),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Campo obbligatorio";
                  }
                  if (value.startsWith(' ')) {
                    return "Non può iniziare con uno spazio";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // 2. Selettore Categoria
              DropdownButtonFormField<String>(
                isExpanded: true,
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: "Categoria *",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                items: _categories.map((cat) {
                  return DropdownMenuItem<String>(
                    value: cat,
                    child: Row(
                      children: [
                        Icon(
                          _getChecklistCategoryIcon(cat),
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Text(cat),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedCategory = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 20),

              // 3. Selettore Priorità
              DropdownButtonFormField<String>(
                isExpanded: true,
                value: _selectedPriority,
                decoration: InputDecoration(
                  labelText: "Priorità *",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                items: _priorities.map((pri) {
                  return DropdownMenuItem<String>(
                    value: pri,
                    child: Row(
                      children: [
                        Icon(Icons.flag, color: _getPriorityColor(pri)),
                        const SizedBox(width: 12),
                        Text(pri),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedPriority = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 32),

              // 4. Pulsante di salvataggio
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  isEditing ? "Salva Modifiche" : "Aggiungi Elemento",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
