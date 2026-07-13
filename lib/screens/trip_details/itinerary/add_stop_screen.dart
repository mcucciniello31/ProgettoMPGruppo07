import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/stop.dart';
import '../../../models/activity.dart';
import '../../../models/trip.dart';
import 'package:say_my_travel/providers/travel_provider.dart';
import '../../../theme/app_theme.dart';

class AddStopScreen extends StatefulWidget {
  final int tripId;
  final Stop?
  parentStop; // Se impostato, aggiungiamo un'attività a questa tappa invece di creare una nuova tappa
  final Stop? stop; // Se impostato, stiamo modificando questa tappa
  final Activity? activity; // Se impostato, stiamo modificando questa attività

  const AddStopScreen({
    super.key,
    required this.tripId,
    this.parentStop,
    this.stop,
    this.activity,
  });

  @override
  State<AddStopScreen> createState() => _AddStopScreenState();
}

class _AddStopScreenState extends State<AddStopScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controller per la gestione dei campi di testo
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late TextEditingController _notesController;
  late TextEditingController _costController;
  late TextEditingController _timeController;

  int _selectedDayIndex = 0;
  TimeOfDay _stopTime = TimeOfDay.now();
  String _selectedActivityType = 'Altro';
  String _selectedActivityStatus = 'Da svolgere';
  Trip? _trip;
  bool _isPaid = false;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<TravelProvider>(context, listen: false);
    _trip = provider.selectedTrip;

    // Determina il tipo di operazione (Tappa o Attività, Aggiunta o Modifica)
    final isActivity = widget.parentStop != null || widget.activity != null;
    final isEdit = widget.stop != null || widget.activity != null;

    _nameController = TextEditingController(
      text: isActivity ? widget.activity?.name ?? '' : widget.stop?.name ?? '',
    );
    _descriptionController = TextEditingController(
      text: isActivity
          ? widget.activity?.description ?? ''
          : widget.stop?.description ?? '',
    );
    _locationController = TextEditingController(
      text: isActivity
          ? widget.activity?.location ?? ''
          : widget.stop?.location ?? '',
    );

    _notesController = TextEditingController(
      text: isActivity
          ? widget.activity?.notes ?? ''
          : widget.stop?.notes ?? '',
    );

    _costController = TextEditingController(
      text: isActivity
          ? (widget.activity != null
                ? widget.activity!.cost.toStringAsFixed(2).replaceAll('.', ',')
                : '0,00')
          : '',
    );

    _timeController = TextEditingController(
      text: isActivity ? widget.activity?.time ?? '' : '',
    );

    _isPaid = isActivity
        ? (widget.activity != null ? widget.activity!.cost > 0 : false)
        : false;

    _selectedActivityType = isActivity
        ? widget.activity?.type ?? 'Altro'
        : 'Altro';
    _selectedActivityStatus = isActivity
        ? widget.activity?.status ?? 'Da svolgere'
        : 'Da svolgere';

    if (!isActivity) {
      if (isEdit) {
        final stopDateTime = widget.stop!.dateTime;
        final tripStartDay = DateTime(
          _trip!.startDate.year,
          _trip!.startDate.month,
          _trip!.startDate.day,
        );
        final stopDay = DateTime(
          stopDateTime.year,
          stopDateTime.month,
          stopDateTime.day,
        );
        _selectedDayIndex = stopDay.difference(tripStartDay).inDays;
        _selectedDayIndex = _selectedDayIndex.clamp(0, _tripTotalDays() - 1);
        _stopTime = TimeOfDay.fromDateTime(stopDateTime);
      } else if (_trip != null) {
        final now = DateTime.now();
        final tripStartDay = DateTime(
          _trip!.startDate.year,
          _trip!.startDate.month,
          _trip!.startDate.day,
        );
        final tripEndDay = DateTime(
          _trip!.endDate.year,
          _trip!.endDate.month,
          _trip!.endDate.day,
        );
        final today = DateTime(now.year, now.month, now.day);
        if (!today.isBefore(tripStartDay) && !today.isAfter(tripEndDay)) {
          _selectedDayIndex = today.difference(tripStartDay).inDays;
          _stopTime = TimeOfDay.fromDateTime(now);
        } else {
          _selectedDayIndex = 0;
          _stopTime = TimeOfDay.now();
        }
        _selectedDayIndex = _selectedDayIndex.clamp(0, _tripTotalDays() - 1);
      }
    }
  }

  /// Numero totale di giorni nel viaggio, garantito per essere almeno 1
  /// anche se la data di fine del viaggio è antecedente alla data di inizio.
  int _tripTotalDays() {
    final tripStartDay = DateTime(
      _trip!.startDate.year,
      _trip!.startDate.month,
      _trip!.startDate.day,
    );
    final tripEndDay = DateTime(
      _trip!.endDate.year,
      _trip!.endDate.month,
      _trip!.endDate.day,
    );
    final totalDays = tripEndDay.difference(tripStartDay).inDays + 1;
    return totalDays < 1 ? 1 : totalDays;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    _costController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime dt) {
    return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
  }

  bool _isValidTitle(String text) {
    if (text.startsWith(' ')) return false;
    final alphaNum = RegExp(r'^[\p{L}\p{N}]$', unicode: true);
    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      if (alphaNum.hasMatch(char) || char == ' ') {
        continue;
      }
      if (const ['\'', '-', ',', '.', '!', ':', '?'].contains(char)) {
        if (i > 0 && i < text.length - 1) {
          final prev = text[i - 1];
          final next = text[i + 1];
          if (alphaNum.hasMatch(prev) && alphaNum.hasMatch(next)) {
            continue;
          }
        }
        return false;
      }
      return false;
    }
    return true;
  }

  Future<void> _selectStopTime() async {
    final timePicked = await showTimePicker(
      context: context,
      initialTime: _stopTime,
    );
    if (timePicked != null) {
      setState(() {
        _stopTime = timePicked;
      });
    }
  }

  DateTime get _combinedStopDateTime {
    final dayDate = _trip!.startDate.add(Duration(days: _selectedDayIndex));
    return DateTime(
      dayDate.year,
      dayDate.month,
      dayDate.day,
      _stopTime.hour,
      _stopTime.minute,
    );
  }

  Future<void> _selectActivityTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 12, minute: 0),
    );
    if (picked != null) {
      final formatted =
          "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
      setState(() {
        _timeController.text = formatted;
      });
    }
  }

  void _save() {
    final name = _nameController.text;
    final description = _descriptionController.text;
    final location = _locationController.text;
    final notesText = _notesController.text;
    final costText = _costController.text;
    final timeText = _timeController.text;

    final isActivity = widget.parentStop != null || widget.activity != null;
    List<String> validationErrors = [];

    if (!isActivity) {
      // Validazione della Tappa
      if (name.isEmpty) {
        validationErrors.add("Nome tappa: campo obbligatorio");
      } else if (name.startsWith(' ')) {
        validationErrors.add("Nome tappa: non può iniziare con uno spazio");
      } else if (!_isValidTitle(name)) {
        validationErrors.add(
          "Nome tappa: può contenere solo lettere, numeri, spazi e i caratteri speciali ' - , . ! : ? (che devono essere preceduti e seguiti da lettere o numeri)",
        );
      }

      if (location.isEmpty) {
        validationErrors.add("Luogo / Località: campo obbligatorio");
      } else if (location.startsWith(' ')) {
        validationErrors.add(
          "Luogo / Località: non può iniziare con uno spazio",
        );
      }

      if (description.isEmpty) {
        validationErrors.add("Descrizione: campo obbligatorio");
      } else if (description.startsWith(' ')) {
        validationErrors.add("Descrizione: non può iniziare con uno spazio");
      }

      if (notesText.startsWith(' ')) {
        validationErrors.add("Note: non possono iniziare con uno spazio");
      }
    } else {
      // Validazione dell'Attività
      if (name.isEmpty) {
        validationErrors.add("Nome attività: campo obbligatorio");
      } else if (name.startsWith(' ')) {
        validationErrors.add("Nome attività: non può iniziare con uno spazio");
      }

      if (description.isEmpty) {
        validationErrors.add("Descrizione attività: campo obbligatorio");
      } else if (description.startsWith(' ')) {
        validationErrors.add(
          "Descrizione attività: non può iniziare con uno spazio",
        );
      }

      if (timeText.isEmpty) {
        validationErrors.add("Orario / Fascia oraria: campo obbligatorio");
      } else if (timeText.startsWith(' ')) {
        validationErrors.add(
          "Orario / Fascia oraria: non può iniziare con uno spazio",
        );
      }

      if (location.isEmpty) {
        validationErrors.add("Luogo attività: campo obbligatorio");
      } else if (location.startsWith(' ')) {
        validationErrors.add("Luogo attività: non può iniziare con uno spazio");
      }

      if (notesText.startsWith(' ')) {
        validationErrors.add("Note: non possono iniziare con uno spazio");
      }
    }

    if (validationErrors.isNotEmpty) {
      setState(() {});
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              SizedBox(width: 8),
              Expanded(child: Text("Controlli di Validazione")),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Per salvare, compila o correggi i seguenti campi:"),
                const SizedBox(height: 12),
                ...validationErrors.map(
                  (error) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 5.0),
                          child: Icon(
                            Icons.circle,
                            size: 6,
                            color: Colors.redAccent,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            error,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );

      _formKey.currentState!.validate();
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<TravelProvider>(context, listen: false);

    if (!isActivity) {
      if (widget.stop == null) {
        // Aggiunta di una Tappa
        final newStop = Stop(
          tripId: widget.tripId,
          name: name.trim(),
          description: description.trim(),
          dateTime: _combinedStopDateTime,
          location: location.trim(),
          itineraryOrder:
              1, // Sovrascritto da TravelProvider.addStop in base alla data della tappa
          notes: notesText.trim(),
        );
        provider.addStop(newStop);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Tappa '${name.trim()}' aggiunta con successo!"),
          ),
        );
      } else {
        // Modifica di una Tappa
        final updatedStop = widget.stop!.copyWith(
          name: name.trim(),
          description: description.trim(),
          dateTime: _combinedStopDateTime,
          location: location.trim(),
          notes: notesText.trim(),
        );
        provider.updateStop(updatedStop);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Tappa '${name.trim()}' modificata con successo!"),
          ),
        );
      }
    } else {
      // Interfaccia di Aggiunta/Modifica di un'Attività
      final cost = _isPaid ? 1.0 : 0.0;
      final status = _selectedActivityStatus;

      if (widget.activity == null) {
        // Aggiunta dell'Attività
        final newActivity = Activity(
          stopId: widget.parentStop!.id!,
          name: name.trim(),
          type: _selectedActivityType,
          description: description.trim(),
          time: timeText.trim(),
          cost: cost,
          location: location.trim(),
          status: status,
          notes: notesText.trim(),
        );
        provider.addActivity(newActivity);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Attività '${name.trim()}' aggiunta con successo!"),
          ),
        );
      } else {
        // Modifica dell'Attività
        final updatedActivity = widget.activity!.copyWith(
          name: name.trim(),
          type: _selectedActivityType,
          description: description.trim(),
          time: timeText.trim(),
          cost: cost,
          location: location.trim(),
          status: status,
          notes: notesText.trim(),
        );
        provider.updateActivity(updatedActivity);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Attività '${name.trim()}' modificata con successo!"),
          ),
        );
      }
    }
  }

  Widget _buildFormDropdownField<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    Widget? prefixIcon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFADCDE2), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3B6A8A),
            ),
          ),
          const SizedBox(height: 2),
          DropdownButtonHideUnderline(
            child: DropdownButtonFormField<T>(
              initialValue: value,
              isExpanded: true,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.zero,
                prefixIcon: prefixIcon,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isActivity = widget.parentStop != null || widget.activity != null;
    final isEdit = widget.stop != null || widget.activity != null;

    String pageTitle = "Nuova Tappa";
    if (isActivity) {
      pageTitle = isEdit ? "Modifica Attività" : "Aggiungi Attività";
    } else if (isEdit) {
      pageTitle = "Modifica Tappa / Giornata";
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(pageTitle),
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
              if (isActivity && widget.parentStop != null) ...[
                Text(
                  "Aggiungi un'attività per la tappa: ${widget.parentStop!.name}",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // 1. Input del nome (obbligatorio)
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: isActivity
                      ? "Nome Attività *"
                      : "Nome Tappa / Giornata *",
                  hintText: isActivity
                      ? "Es: Visita al Museo del Louvre"
                      : "Es: Primo Giorno a Parigi",
                  prefixIcon: Icon(
                    isActivity ? Icons.local_activity : Icons.place,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Inserisci un nome";
                  }
                  if (value.startsWith(' ')) {
                    return "Non può iniziare con uno spazio";
                  }
                  if (!isActivity && !_isValidTitle(value)) {
                    return "Usa solo lettere, numeri, spazi e ' - , . ! : ? circondati da lettere/numeri";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // 2. Campi specifici a seconda che sia Tappa o Attività
              if (!isActivity) ...[
                // Input della località della tappa
                TextFormField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    labelText: "Luogo / Località *",
                    hintText: "Es: Gare du Nord, Parigi",
                    prefixIcon: const Icon(Icons.map_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Inserisci la località";
                    }
                    if (value.startsWith(' ')) {
                      return "Non può iniziare con uno spazio";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Selezione del giorno di itinerario (limitato ai giorni effettivi del viaggio)
                Builder(
                  builder: (context) {
                    final tripStartDay = DateTime(
                      _trip!.startDate.year,
                      _trip!.startDate.month,
                      _trip!.startDate.day,
                    );
                    final totalDays = _tripTotalDays();
                    final dropdownValue = _selectedDayIndex.clamp(
                      0,
                      totalDays - 1,
                    );
                    return _buildFormDropdownField<int>(
                      label: "Giorno del viaggio *",
                      value: dropdownValue,
                      prefixIcon: const Icon(Icons.calendar_month),
                      items: List.generate(totalDays, (i) {
                        final dayDate = tripStartDay.add(Duration(days: i));
                        return DropdownMenuItem<int>(
                          value: i,
                          child: Text(
                            "Giorno ${i + 1} - ${_formatDate(dayDate)}",
                          ),
                        );
                      }),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedDayIndex = val;
                          });
                        }
                      },
                    );
                  },
                ),
                const SizedBox(height: 20),

                // Selettore dell'orario della tappa
                InkWell(
                  onTap: _selectStopTime,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withValues(alpha: 0.5),
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Ora *",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              "${_stopTime.hour.toString().padLeft(2, '0')}:${_stopTime.minute.toString().padLeft(2, '0')}",
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                // Selezione della categoria o tipo di attività
                _buildFormDropdownField<String>(
                  label: "Categoria Attività *",
                  value: _selectedActivityType,
                  prefixIcon: const Icon(Icons.category),
                  items: AppTheme.activityIcons.keys.map((type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Row(
                        children: [
                          Icon(
                            AppTheme.activityIcons[type],
                            size: 20,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 10),
                          Text(type),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedActivityType = val;
                      });
                    }
                  },
                ),
                const SizedBox(height: 20),

                // Selezione dello stato dell'attività (Da svolgere, Completata, Annullata)
                _buildFormDropdownField<String>(
                  label: "Stato dell'attività *",
                  value: _selectedActivityStatus,
                  prefixIcon: const Icon(Icons.task_alt),
                  items: const [
                    DropdownMenuItem(
                      value: 'Da svolgere',
                      child: Text('Da svolgere'),
                    ),
                    DropdownMenuItem(
                      value: 'Completata',
                      child: Text('Completata'),
                    ),
                    DropdownMenuItem(
                      value: 'Annullata',
                      child: Text('Annullata'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedActivityStatus = val;
                      });
                    }
                  },
                ),
                const SizedBox(height: 20),

                // Input della località dell'attività
                TextFormField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    labelText: "Luogo dell'attività *",
                    hintText: "Es: Museo del Louvre, Parigi",
                    prefixIcon: const Icon(Icons.location_on_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Inserisci il luogo dell'attività";
                    }
                    if (value.startsWith(' ')) {
                      return "Non può iniziare con uno spazio";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Orario o fascia oraria dell'attività
                TextFormField(
                  controller: _timeController,
                  decoration: InputDecoration(
                    labelText: "Orario / Fascia Oraria *",
                    hintText: "Es: 10:00 - 12:00, Pomeriggio, Mattina",
                    prefixIcon: const Icon(Icons.access_time),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.more_time),
                      tooltip: "Seleziona ora esatta",
                      onPressed: _selectActivityTime,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Inserisci l'orario o fascia oraria";
                    }
                    if (value.startsWith(' ')) {
                      return "Non può iniziare con uno spazio";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Selettore del costo dell'attività (Gratuita o A pagamento)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Costo previsto *",
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
                              setState(() {
                                _isPaid = false;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: !_isPaid
                                    ? Colors.green.shade50
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: !_isPaid
                                      ? Colors.green
                                      : const Color(0xFFADCDE2),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.money_off_rounded,
                                    color: !_isPaid
                                        ? Colors.green
                                        : Colors.grey,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Gratuita",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: !_isPaid
                                          ? Colors.green.shade700
                                          : Colors.grey,
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
                              setState(() {
                                _isPaid = true;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _isPaid
                                    ? Colors.orange.shade50
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _isPaid
                                      ? Colors.orange
                                      : const Color(0xFFADCDE2),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.monetization_on_rounded,
                                    color: _isPaid
                                        ? Colors.orange
                                        : Colors.grey,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "A pagamento",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _isPaid
                                          ? Colors.orange.shade700
                                          : Colors.grey,
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
              ],
              const SizedBox(height: 20),

              // 3. Input per la descrizione
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: isActivity
                      ? "Descrizione Attività *"
                      : "Descrizione della giornata *",
                  hintText: isActivity
                      ? "Es: Visitare l'ala Denon per vedere la Gioconda."
                      : "Es: Arrivo in hotel, check-in e prima passeggiata serale.",
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 40),
                    child: Icon(Icons.notes),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Inserisci la descrizione";
                  }
                  if (value.startsWith(' ')) {
                    return "Non può iniziare con uno spazio";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // 4. Input per note aggiuntive (condiviso, facoltativo)
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: "Note aggiuntive",
                  hintText: isActivity
                      ? "Es: I biglietti sono sul telefono"
                      : "Es: Ricordarsi la macchina fotografica",
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 15),
                    child: Icon(Icons.sticky_note_2_outlined),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                validator: (value) {
                  if (value != null && value.startsWith(' ')) {
                    return "Non può iniziare con uno spazio";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 40),

              // 5. Pulsante di salvataggio del modulo
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
                  isEdit
                      ? "Salva Modifiche"
                      : (isActivity ? "Aggiungi Attività" : "Aggiungi Tappa"),
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
