part of 'travel_provider.dart';

extension ExpensesProvider on TravelProvider {
  // ==========================================
  // OPERAZIONI SULLE SPESE
  // ==========================================

  Future<void> addExpense(Expense expense) async {
    await _dbHelper.insertExpense(expense);
    if (_selectedTrip != null) {
      await loadTripDetails(_selectedTrip!.id!);
      notify();
    }
  }

  Future<void> updateExpense(Expense expense) async {
    await _dbHelper.updateExpense(expense);
    if (_selectedTrip != null) {
      await loadTripDetails(_selectedTrip!.id!);
      notify();
    }
  }

  Future<void> deleteExpense(int id) async {
    await _dbHelper.deleteExpense(id);
    if (_selectedTrip != null) {
      await loadTripDetails(_selectedTrip!.id!);
      notify();
    }
  }

  // Getter di supporto per le statistiche del viaggio selezionato
  double get totalBudget => _selectedTrip?.budget ?? 0.0;

  double get totalExpenses {
    return _currentExpenses
        .where((e) => e.status == 'Sostenuta')
        .fold(
          0.0,
          (sum, item) =>
              sum + CurrencyService.convert(item.amount, item.currency, 'EUR'),
        );
  }

  double get totalPlannedExpenses {
    return _currentExpenses
        .where((e) => e.status == 'Prevista')
        .fold(
          0.0,
          (sum, item) =>
              sum + CurrencyService.convert(item.amount, item.currency, 'EUR'),
        );
  }

  double get remainingBudget => totalBudget - totalExpenses;

  double get remainingBudgetPlanned => totalBudget - totalPlannedExpenses;
}
