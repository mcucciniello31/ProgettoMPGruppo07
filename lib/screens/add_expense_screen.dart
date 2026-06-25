import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/expense.dart';
import '../models/stop.dart';
import '../models/activity.dart';
import '../providers/travel_provider.dart';
import '../theme/app_theme.dart';
import '../services/currency_service.dart';

class AddExpenseScreen extends StatefulWidget {
  final int tripId;
  final Expense? expense; // Null if adding, not null if editing

  const AddExpenseScreen({super.key, required this.tripId, this.expense});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String _selectedCategory = 'Altro';
  DateTime _expenseDate = DateTime.now();
  String _selectedCurrency = 'EUR';
  String _selectedPaymentMethod = 'Contanti';
  String _selectedStatus = 'Sostenuta'; // 'Prevista', 'Sostenuta'

  // Association properties
  String _associatedType = 'Generale'; // 'Generale', 'Tappa', 'Attivita'
  int? _selectedStopId;
  int? _selectedActivityId;

  List<Stop> _stops = [];
  List<Activity> _activities = [];

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<TravelProvider>(context, listen: false);
    _stops = provider.currentStops;
    
    // Load all activities for this trip
    _activities = [];
    for (var stop in _stops) {
      _activities.addAll(provider.getActivitiesForStop(stop.id!));
    }

    final trip = provider.selectedTrip;
    if (trip != null) {
      if (DateTime.now().isAfter(trip.startDate) && DateTime.now().isBefore(trip.endDate)) {
        _expenseDate = DateTime.now();
      } else {
        _expenseDate = trip.startDate;
      }
    }

    // Populate data if editing
    final isEditing = widget.expense != null;
    if (isEditing) {
      final ex = widget.expense!;
      // Replace dot with comma for display
      _amountController.text = ex.amount.toString().replaceAll('.', ',');
      _titleController.text = ex.title;
      _notesController.text = ex.notes;
      _selectedCategory = ex.category;
      _expenseDate = ex.date;
      _selectedCurrency = ex.currency;
      _selectedPaymentMethod = ex.paymentMethod;
      _selectedStatus = ex.status;
      _associatedType = ex.associatedType;
      if (ex.associatedType == 'Tappa') {
        _selectedStopId = ex.associatedId;
      } else if (ex.associatedType == 'Attivita') {
        _selectedActivityId = ex.associatedId;
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime dt) {
    return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
  }

  Future<void> _selectDate() async {
    final provider = Provider.of<TravelProvider>(context, listen: false);
    final trip = provider.selectedTrip;
    
    // Constraint date picker to trip date range
    final firstDate = trip?.startDate ?? DateTime(2020);
    final lastDate = trip?.endDate ?? DateTime(2030);

    final picked = await showDatePicker(
      context: context,
      initialDate: _expenseDate.isAfter(firstDate) && _expenseDate.isBefore(lastDate)
          ? _expenseDate
          : firstDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked != null) {
      setState(() {
        _expenseDate = picked;
      });
    }
  }

  void _showValidationErrorsDialog(List<String> errors) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Theme.of(context).colorScheme.error),
              const SizedBox(width: 8),
              const Expanded(
                child: Text("Campi non validi o mancanti"),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: errors
                .map((err) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("• ", style: TextStyle(fontWeight: FontWeight.bold)),
                          Expanded(child: Text(err)),
                        ],
                      ),
                    ))
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

  void _saveExpense() {
    final errors = <String>[];

    final title = _titleController.text;
    final amountText = _amountController.text;
    final notes = _notesController.text;

    // 1. Check title leading space and emptiness
    if (title.isEmpty) {
      errors.add("Il titolo della spesa è obbligatorio");
    } else if (title.startsWith(' ')) {
      errors.add("Il titolo della spesa non può iniziare con uno spazio");
    }

    // 2. Check notes leading space
    if (notes.startsWith(' ')) {
      errors.add("Le note della spesa non possono iniziare con uno spazio");
    }

    // 3. Check amount leading space and parse
    if (amountText.isEmpty) {
      errors.add("L'importo è obbligatorio");
    } else if (amountText.startsWith(' ')) {
      errors.add("L'importo non può iniziare con uno spazio");
    }

    // Parse amount supporting commas
    final normalizedAmount = amountText.replaceAll(',', '.');
    final amount = double.tryParse(normalizedAmount);
    if (amountText.isNotEmpty && (amount == null || amount <= 0)) {
      errors.add("Inserisci un importo numerico valido e maggiore di zero");
    }

    // 4. Check association validity
    int? finalAssociatedId;
    String finalAssociatedName = 'Generale';

    if (_associatedType == 'Tappa') {
      if (_selectedStopId == null) {
        errors.add("Seleziona la tappa da associare");
      } else {
        finalAssociatedId = _selectedStopId;
        finalAssociatedName = _stops.firstWhere((s) => s.id == _selectedStopId).name;
      }
    } else if (_associatedType == 'Attivita') {
      if (_selectedActivityId == null) {
        errors.add("Seleziona l'attività da associare");
      } else {
        finalAssociatedId = _selectedActivityId;
        finalAssociatedName = _activities.firstWhere((a) => a.id == _selectedActivityId).name;
      }
    }

    // If validation fails, show error dialog
    if (errors.isNotEmpty) {
      _showValidationErrorsDialog(errors);
      return;
    }

    final provider = Provider.of<TravelProvider>(context, listen: false);

    final expense = Expense(
      id: widget.expense?.id,
      tripId: widget.tripId,
      title: title.trim(),
      amount: amount!,
      category: _selectedCategory,
      date: _expenseDate,
      associatedType: _associatedType,
      associatedId: finalAssociatedId,
      associatedName: finalAssociatedName,
      paymentMethod: _selectedPaymentMethod,
      status: _selectedStatus,
      notes: notes.trim(),
      currency: _selectedCurrency,
    );

    final isEditing = widget.expense != null;
    if (isEditing) {
      provider.updateExpense(expense);
    } else {
      provider.addExpense(expense);
    }

    Navigator.pop(context);

    final symbol = CurrencyService.getSymbol(_selectedCurrency);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isEditing
            ? "Spesa di $symbol${amount.toStringAsFixed(2)} modificata con successo!"
            : "Spesa di $symbol${amount.toStringAsFixed(2)} registrata con successo!"),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildAssociationChip(String label, String value, IconData icon) {
    final isSelected = _associatedType == value;
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _associatedType = value;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
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
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
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

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.expense != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? "Modifica Spesa" : "Registra Spesa"),
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
                    ? "Modifica i dati relativi alla spesa selezionata."
                    : "Inserisci i dati relativi alla spesa sostenuta o prevista.",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),

              // 1. Title input
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: "Titolo Spesa *",
                  hintText: "Es: Biglietto Museo, Cena...",
                  prefixIcon: const Icon(Icons.title),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 2. Amount and Currency row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        labelText: "Importo *",
                        hintText: "0,00",
                        prefixIcon: const Icon(Icons.monetization_on_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: _selectedCurrency,
                      decoration: InputDecoration(
                        labelText: "Valuta *",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      ),
                      items: CurrencyService.currencies.map((curr) {
                        return DropdownMenuItem<String>(
                          value: curr.code,
                          child: Text(
                            "${curr.code} (${curr.symbol})",
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedCurrency = val;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 3. Category & Status row
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: _selectedCategory,
                      decoration: InputDecoration(
                        labelText: "Categoria *",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      items: AppTheme.categoryColors.keys.map((cat) {
                        final color = AppTheme.categoryColors[cat] ?? Colors.grey;
                        return DropdownMenuItem<String>(
                          value: cat,
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 8),
                              Text(cat, style: const TextStyle(fontSize: 13)),
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
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: _selectedStatus,
                      decoration: InputDecoration(
                        labelText: "Stato *",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Prevista', child: Text("Prevista", style: TextStyle(fontSize: 13))),
                        DropdownMenuItem(value: 'Sostenuta', child: Text("Sostenuta", style: TextStyle(fontSize: 13))),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedStatus = val;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 4. Payment Method & Date row
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: _selectedPaymentMethod,
                      decoration: InputDecoration(
                        labelText: "Metodo *",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      items: const [
                        'Contanti',
                        'Carta di Credito',
                        'Carta di Debito',
                        'Apple Pay',
                        'Google Pay',
                        'Altro'
                      ].map((method) => DropdownMenuItem(
                            value: method,
                            child: Text(method, style: const TextStyle(fontSize: 13)),
                          ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedPaymentMethod = val;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: _selectDate,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
                        decoration: BoxDecoration(
                          border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.5)),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 16),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _formatDate(_expenseDate),
                                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 5. Association configuration
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.15)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Associazione Spesa *",
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildAssociationChip('Generale', 'Generale', Icons.receipt_long_outlined),
                          const SizedBox(width: 8),
                          _buildAssociationChip('Tappa', 'Tappa', Icons.map_outlined),
                          const SizedBox(width: 8),
                          _buildAssociationChip('Attività', 'Attivita', Icons.local_activity_outlined),
                        ],
                      ),
                      if (_associatedType == 'Tappa') ...[
                        const SizedBox(height: 12),
                        DropdownButtonFormField<int>(
                          value: _selectedStopId,
                          decoration: InputDecoration(
                            labelText: "Seleziona Tappa *",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: _stops.map((stop) {
                            return DropdownMenuItem<int>(
                              value: stop.id,
                              child: Text(stop.name, style: const TextStyle(fontSize: 13)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedStopId = val;
                            });
                          },
                        ),
                      ],
                      if (_associatedType == 'Attivita') ...[
                        const SizedBox(height: 12),
                        _activities.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  "Nessuna attività programmata in questo viaggio da poter associare.",
                                  style: TextStyle(color: Colors.orange, fontSize: 12),
                                ),
                              )
                            : DropdownButtonFormField<int>(
                                value: _selectedActivityId,
                                decoration: InputDecoration(
                                  labelText: "Seleziona Attività *",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                items: _activities.map((act) {
                                  return DropdownMenuItem<int>(
                                    value: act.id,
                                    child: Text(act.name, style: const TextStyle(fontSize: 13)),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setState(() {
                                    _selectedActivityId = val;
                                  });
                                },
                              ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 6. Notes input
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: "Note Aggiuntive",
                  hintText: "Es: Ricevuta salvata, Pagamento diviso...",
                  prefixIcon: const Icon(Icons.note_alt_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // 7. Save Button
              ElevatedButton(
                onPressed: _saveExpense,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  isEditing ? "Aggiorna Spesa" : "Salva Spesa",
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
