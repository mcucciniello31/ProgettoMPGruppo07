import 'package:flutter/material.dart';
import '../../../models/expense.dart';
import '../../../providers/travel_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../services/currency_service.dart';
import 'add_expense_screen.dart';

class ExpensesTab extends StatefulWidget {
  final TravelProvider provider;

  const ExpensesTab({super.key, required this.provider});

  @override
  State<ExpensesTab> createState() => _ExpensesTabState();
}

class _ExpensesTabState extends State<ExpensesTab> {
  String _selectedExpenseFilter = 'Tutte';
  bool _showExpenseFilterPanel = false;
  String _selectedExpenseCategoryFilter = "Tutte";
  String _selectedExpenseAmountRangeFilter = "Tutti";
  String _selectedExpenseAssociationFilter = "Tutti";

  final TextEditingController _convAmountController = TextEditingController(
    text: '100',
  );
  String _convFrom = 'EUR';
  String _convTo = 'USD';

  @override
  void dispose() {
    _convAmountController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime dt) {
    return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
  }

  void _showDeleteExpenseConfirmation(TravelProvider provider, Expense ex) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Elimina Spesa"),
          content: Text(
            "Sei sicuro di voler eliminare la spesa '${ex.title}'?",
          ),
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
                provider.deleteExpense(ex.id!);
                Navigator.pop(context);
              },
              child: const Text("Elimina"),
            ),
          ],
        );
      },
    );
  }

  void _showCurrencyConverterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(
                    Icons.currency_exchange,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  const Text("Convertitore Valuta"),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _convAmountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: "Importo",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (val) {
                      setDialogState(() {});
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _convFrom,
                          decoration: InputDecoration(
                            labelText: "Da",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: CurrencyService.currencies
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c.code,
                                  child: Text(
                                    c.code,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() {
                                _convFrom = val;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _convTo,
                          decoration: InputDecoration(
                            labelText: "A",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: CurrencyService.currencies
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c.code,
                                  child: Text(
                                    c.code,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() {
                                _convTo = val;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Builder(
                    builder: (context) {
                      final parsed =
                          double.tryParse(
                            _convAmountController.text.replaceAll(',', '.'),
                          ) ??
                          0.0;
                      final converted = CurrencyService.convert(
                        parsed,
                        _convFrom,
                        _convTo,
                      );
                      final symbolFrom = CurrencyService.getSymbol(_convFrom);
                      final symbolTo = CurrencyService.getSymbol(_convTo);
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            "$symbolFrom${parsed.toStringAsFixed(2)} $_convFrom = $symbolTo${converted.toStringAsFixed(2)} $_convTo",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Chiudi"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showExpenseDetailsDialog(TravelProvider provider, Expense ex) {
    final localSymbol = CurrencyService.getSymbol(ex.currency);
    final amountInEur = CurrencyService.convert(ex.amount, ex.currency, 'EUR');
    final showEurConv = ex.currency != 'EUR';
    final accentColor = AppTheme.categoryColors[ex.category] ?? Colors.grey;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ex.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow(
                  "Importo:",
                  "$localSymbol${ex.amount.toStringAsFixed(2)} ${ex.currency}",
                ),
                if (showEurConv)
                  _buildDetailRow(
                    "Equivalente EUR:",
                    "€${amountInEur.toStringAsFixed(2)}",
                  ),
                _buildDetailRow("Categoria:", ex.category),
                _buildDetailRow("Data:", _formatDate(ex.date)),
                _buildDetailRow("Stato:", ex.status),
                _buildDetailRow("Metodo Pagamento:", ex.paymentMethod),
                _buildDetailRow(
                  "Associazione:",
                  "${ex.associatedType}: ${ex.associatedName}",
                ),
                if (ex.notes.isNotEmpty) _buildDetailRow("Note:", ex.notes),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Chiudi"),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.blue),
              tooltip: "Modifica",
              onPressed: () {
                Navigator.pop(
                  context,
                ); // Chiude la finestra di dialogo dei dettagli
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddExpenseScreen(
                      tripId: provider.selectedTrip!.id!,
                      expense: ex,
                    ),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              tooltip: "Elimina",
              onPressed: () {
                Navigator.pop(
                  context,
                ); // Chiude la finestra di dialogo dei dettagli
                _showDeleteExpenseConfirmation(provider, ex);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label ",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Colors.grey,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    final expenses = provider.currentExpenses;
    final budget = provider.totalBudget;

    // Valori monetari convertiti in EUR
    final totalSpentActual = provider.totalExpenses;
    final totalSpentPlanned = provider.totalPlannedExpenses;
    final remainingActual = provider.remainingBudget;
    final remainingPlanned = provider.remainingBudgetPlanned;

    final percentSpentActual = budget > 0
        ? (totalSpentActual / budget).clamp(0.0, 1.0)
        : 0.0;

    final isOverBudgetActual = remainingActual < 0;
    final isOverBudgetPlanned = remainingPlanned < 0;

    // Calcola la percentuale di spesa per ciascuna categoria (spese sostenute convertite in EUR)
    Map<String, double> catSpent = {};
    for (var ex in expenses) {
      if (ex.status == 'Sostenuta') {
        final amountInEur = CurrencyService.convert(
          ex.amount,
          ex.currency,
          'EUR',
        );
        catSpent[ex.category] = (catSpent[ex.category] ?? 0.0) + amountInEur;
      }
    }

    // Costruisce la lista di tappe e attività collegate a questo viaggio per i filtri
    final associations = <String>['Tutti', 'Generale'];
    for (var stop in provider.currentStops) {
      associations.add(stop.name);
      final activities = provider.getActivitiesForStop(stop.id!);
      for (var act in activities) {
        associations.add(act.name);
      }
    }

    // Elenco delle transazioni registrate storiche che corrispondono ai filtri selezionati
    final filteredExpenses = expenses.where((ex) {
      // 1. Filtro di stato del viaggio
      if (_selectedExpenseFilter == 'Sostenute' && ex.status != 'Sostenuta')
        return false;
      if (_selectedExpenseFilter == 'Previste' && ex.status != 'Prevista')
        return false;

      // 2. Filtro per categoria delle spese
      if (_selectedExpenseCategoryFilter != 'Tutte' &&
          ex.category != _selectedExpenseCategoryFilter) {
        return false;
      }

      // 3. Filtro per range di spesa (basato sul valore convertito in EUR)
      final amountInEur = CurrencyService.convert(
        ex.amount,
        ex.currency,
        'EUR',
      );
      if (_selectedExpenseAmountRangeFilter != 'Tutti') {
        if (_selectedExpenseAmountRangeFilter == 'Fino a €50' &&
            amountInEur > 50)
          return false;
        if (_selectedExpenseAmountRangeFilter == '€50 - €200' &&
            (amountInEur < 50 || amountInEur > 200)) {
          return false;
        }
        if (_selectedExpenseAmountRangeFilter == 'Oltre €200' &&
            amountInEur < 200)
          return false;
      }

      // 4. Filtro per collegare la spesa ad una tappa/attività
      if (_selectedExpenseAssociationFilter != 'Tutti') {
        if (_selectedExpenseAssociationFilter == 'Generale') {
          if (ex.associatedType != 'Generale') return false;
        } else {
          if (ex.associatedName != _selectedExpenseAssociationFilter) {
            return false;
          }
        }
      }

      return true;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Scheda di Riepilogo del Budget (Statistiche Spese Sostenute e Previste)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Budget di Viaggio",
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.currency_exchange, size: 20),
                        tooltip: "Convertitore",
                        onPressed: _showCurrencyConverterDialog,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 90,
                        height: 90,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: percentSpentActual,
                              strokeWidth: 8,
                              backgroundColor: Colors.grey.withOpacity(0.1),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isOverBudgetActual
                                    ? Colors.redAccent
                                    : Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            Text(
                              "${(percentSpentActual * 100).toStringAsFixed(0)}%",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isOverBudgetActual
                                    ? Colors.redAccent
                                    : Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Budget Totale",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  "€${budget.toStringAsFixed(2).replaceAll('.', ',')}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Sostenuto (Attuale)",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  "€${totalSpentActual.toStringAsFixed(2).replaceAll('.', ',')}",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isOverBudgetActual
                                        ? Colors.redAccent
                                        : Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Stimato (Pianificato)",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  "€${totalSpentPlanned.toStringAsFixed(2).replaceAll('.', ',')}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Budget Rimanente Effettivo:",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        isOverBudgetActual
                            ? "Sotto di €${(-remainingActual).toStringAsFixed(2).replaceAll('.', ',')}"
                            : "€${remainingActual.toStringAsFixed(2).replaceAll('.', ',')}",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isOverBudgetActual
                              ? Colors.redAccent
                              : Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Budget Rimanente Pianificato:",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        isOverBudgetPlanned
                            ? "Sotto di €${(-remainingPlanned).toStringAsFixed(2).replaceAll('.', ',')}"
                            : "€${remainingPlanned.toStringAsFixed(2).replaceAll('.', ',')}",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isOverBudgetPlanned
                              ? Colors.redAccent
                              : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Sezione di filtro delle spese
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Storico Spese (${filteredExpenses.length})",
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  PopupMenuButton<String>(
                    initialValue: _selectedExpenseFilter,
                    offset: const Offset(0, 30),
                    onSelected: (String value) {
                      setState(() {
                        _selectedExpenseFilter = value;
                      });
                    },
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<String>>[
                          const PopupMenuItem<String>(
                            value: 'Tutte',
                            child: Text('Tutte'),
                          ),
                          const PopupMenuItem<String>(
                            value: 'Sostenute',
                            child: Text('Sostenute'),
                          ),
                          const PopupMenuItem<String>(
                            value: 'Previste',
                            child: Text('Previste'),
                          ),
                        ],
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _selectedExpenseFilter,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Icon(
                          Icons.arrow_drop_down,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.filter_alt_outlined,
                      color: _showExpenseFilterPanel
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _showExpenseFilterPanel = !_showExpenseFilterPanel;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),

          if (_showExpenseFilterPanel) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withOpacity(0.1),
                ),
              ),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedExpenseCategoryFilter,
                    decoration: const InputDecoration(
                      labelText: "Categoria",
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: 'Tutte',
                        child: Text("Tutte"),
                      ),
                      ...AppTheme.categoryColors.keys.map(
                        (c) => DropdownMenuItem(value: c, child: Text(c)),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedExpenseCategoryFilter = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedExpenseAmountRangeFilter,
                    decoration: const InputDecoration(
                      labelText: "Fascia d'importo",
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Tutti', child: Text("Tutti")),
                      DropdownMenuItem(
                        value: 'Fino a €50',
                        child: Text("Fino a €50"),
                      ),
                      DropdownMenuItem(
                        value: '€50 - €200',
                        child: Text("€50 - €200"),
                      ),
                      DropdownMenuItem(
                        value: 'Oltre €200',
                        child: Text("Oltre €200"),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedExpenseAmountRangeFilter = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedExpenseAssociationFilter,
                    decoration: const InputDecoration(
                      labelText: "Associazione",
                      isDense: true,
                    ),
                    items: associations
                        .map(
                          (assoc) => DropdownMenuItem(
                            value: assoc,
                            child: Text(assoc),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedExpenseAssociationFilter = val;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),

          if (filteredExpenses.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.money_off_outlined,
                      size: 64,
                      color: Theme.of(context).hintColor.withOpacity(0.5),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Nessuna spesa corrisponde ai filtri",
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 16,
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredExpenses.length,
              itemBuilder: (context, index) {
                final ex = filteredExpenses[index];
                final localSymbol = CurrencyService.getSymbol(ex.currency);
                final categoryColor =
                    AppTheme.categoryColors[ex.category] ?? Colors.grey;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Container(
                      width: 8,
                      height: 40,
                      decoration: BoxDecoration(
                        color: categoryColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    title: Text(
                      ex.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Row(
                      children: [
                        Icon(
                          ex.status == 'Sostenuta'
                              ? Icons.check_circle_outline
                              : Icons.schedule,
                          size: 12,
                          color: ex.status == 'Sostenuta'
                              ? Colors.green
                              : Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "${ex.status} • ${_formatDate(ex.date)}",
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (ex.associatedType != 'Generale') ...[
                          const Icon(Icons.link, size: 12, color: Colors.grey),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              ex.associatedName,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    trailing: Text(
                      "$localSymbol${ex.amount.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    onTap: () => _showExpenseDetailsDialog(provider, ex),
                  ),
                );
              },
            ),

          if (catSpent.isNotEmpty && _selectedExpenseFilter != 'Previste') ...[
            const SizedBox(height: 24),
            Text(
              "Ripartizione Categoria Spese Sostenute",
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: AppTheme.categoryColors.keys.map((category) {
                    final spent = catSpent[category] ?? 0.0;
                    final fraction = totalSpentActual > 0
                        ? (spent / totalSpentActual)
                        : 0.0;
                    if (spent == 0.0) return const SizedBox.shrink();

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: AppTheme.categoryColors[category],
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    category,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                "€${spent.toStringAsFixed(2)} (${(fraction * 100).toStringAsFixed(0)}%)",
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: fraction,
                              minHeight: 6,
                              backgroundColor: Colors.grey.withOpacity(0.1),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.categoryColors[category]!,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],

          const SizedBox(height: 100),
        ],
      ),
    );
  }
}
