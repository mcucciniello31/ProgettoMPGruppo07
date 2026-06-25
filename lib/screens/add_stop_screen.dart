import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/stop.dart';
import '../models/activity.dart';
import '../models/trip.dart';
import '../providers/travel_provider.dart';
import '../theme/app_theme.dart';

class AddStopScreen extends StatefulWidget {
  final int tripId;
  final Stop? parentStop; // If set, we add an activity to this stop instead of a new stop
  final Stop? stop; // If set, we edit this stop
  final Activity? activity; // If set, we edit this activity

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

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late TextEditingController _itineraryOrderController;
  late TextEditingController _notesController;
  late TextEditingController _costController;
  late TextEditingController _timeController;

  DateTime _stopDateTime = DateTime.now();
  String _selectedActivityType = 'Altro';
  String _selectedActivityStatus = 'Da svolgere';
  Trip? _trip;
  bool _validationTriggered = false;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<TravelProvider>(context, listen: false);
    _trip = provider.selectedTrip;

    // Determine roles
    final isActivity = widget.parentStop != null || widget.activity != null;
    final isEdit = widget.stop != null || widget.activity != null;

    _nameController = TextEditingController(
      text: isActivity ? widget.activity?.name ?? '' : widget.stop?.name ?? '',
    );
    _descriptionController = TextEditingController(
      text: isActivity ? widget.activity?.description ?? '' : widget.stop?.description ?? '',
    );
    _locationController = TextEditingController(
      text: isActivity ? widget.activity?.location ?? '' : widget.stop?.location ?? '',
    );

    int defaultOrder = provider.currentStops.length + 1;
    _itineraryOrderController = TextEditingController(
      text: !isActivity && isEdit ? widget.stop!.itineraryOrder.toString() : defaultOrder.toString(),
    );
    
    _notesController = TextEditingController(
      text: isActivity ? widget.activity?.notes ?? '' : widget.stop?.notes ?? '',
    );

    _costController = TextEditingController(
      text: isActivity
          ? (widget.activity != null ? widget.activity!.cost.toStringAsFixed(2).replaceAll('.', ',') : '0,00')
          : '',
    );

    _timeController = TextEditingController(
      text: isActivity ? widget.activity?.time ?? '' : '',
    );

    _selectedActivityType = isActivity ? widget.activity?.type ?? 'Altro' : 'Altro';
    _selectedActivityStatus = isActivity ? widget.activity?.status ?? 'Da svolgere' : 'Da svolgere';

    if (!isActivity) {
      if (isEdit) {
        _stopDateTime = widget.stop!.dateTime;
      } else {
        if (_trip != null) {
          final now = DateTime.now();
          if (now.isAfter(_trip!.startDate) && now.isBefore(_trip!.endDate)) {
            _stopDateTime = now;
          } else {
            _stopDateTime = _trip!.startDate;
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _itineraryOrderController.dispose();
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

  Future<void> _selectDateTime() async {
    final firstLimit = _trip?.startDate ?? DateTime(2020);
    final lastLimit = _trip?.endDate ?? DateTime(2030);

    final datePicked = await showDatePicker(
      context: context,
      initialDate: _stopDateTime.isBefore(firstLimit)
          ? firstLimit
          : (_stopDateTime.isAfter(lastLimit) ? lastLimit : _stopDateTime),
      firstDate: firstLimit,
      lastDate: lastLimit,
    );

    if (datePicked != null) {
      if (mounted) {
        final timePicked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(_stopDateTime),
        );

        if (timePicked != null) {
          setState(() {
            _stopDateTime = DateTime(
              datePicked.year,
              datePicked.month,
              datePicked.day,
              timePicked.hour,
              timePicked.minute,
            );
          });
        }
      }
    }
  }

  Future<void> _selectActivityTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 12, minute: 0),
    );
    if (picked != null) {
      final formatted = "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
      setState(() {
        _timeController.text = formatted;
      });
    }
  }

  void _save() {
    final name = _nameController.text;
    final description = _descriptionController.text;
    final location = _locationController.text;
    final orderText = _itineraryOrderController.text;
    final notesText = _notesController.text;
    final costText = _costController.text;
    final timeText = _timeController.text;

    final isActivity = widget.parentStop != null || widget.activity != null;
    List<String> validationErrors = [];

    if (!isActivity) {
      // Validating Stop
      if (name.isEmpty) {
        validationErrors.add("Nome tappa: campo obbligatorio");
      } else if (name.startsWith(' ')) {
        validationErrors.add("Nome tappa: non può iniziare con uno spazio");
      } else if (!_isValidTitle(name)) {
        validationErrors.add("Nome tappa: può contenere solo lettere, numeri, spazi e i caratteri speciali ' - , . ! : ? (che devono essere preceduti e seguiti da lettere o numeri)");
      }

      if (location.isEmpty) {
        validationErrors.add("Luogo / Località: campo obbligatorio");
      } else if (location.startsWith(' ')) {
        validationErrors.add("Luogo / Località: non può iniziare con uno spazio");
      }

      if (description.isEmpty) {
        validationErrors.add("Descrizione: campo obbligatorio");
      } else if (description.startsWith(' ')) {
        validationErrors.add("Descrizione: non può iniziare con uno spazio");
      }

      if (orderText.isEmpty) {
        validationErrors.add("Ordine nell'itinerario: campo obbligatorio");
      } else if (orderText.startsWith(' ')) {
        validationErrors.add("Ordine nell'itinerario: non può iniziare con uno spazio");
      } else {
        final orderVal = int.tryParse(orderText);
        if (orderVal == null || orderVal <= 0) {
          validationErrors.add("Ordine nell'itinerario: deve essere un numero intero positivo maggiore di zero (es: 1, 2, 3)");
        } else {
          final provider = Provider.of<TravelProvider>(context, listen: false);
          final existingStops = provider.currentStops;
          if (widget.stop == null) {
            final maxAllowed = existingStops.length + 1;
            if (orderVal > maxAllowed) {
              validationErrors.add("Ordine nell'itinerario: non puoi saltare giorni. La prossima tappa deve avere un ordine al massimo di $maxAllowed (attualmente ci sono ${existingStops.length} tappe).");
            }
          } else {
            final maxAllowed = existingStops.length;
            if (orderVal > maxAllowed) {
              validationErrors.add("Ordine nell'itinerario: giorno non valido. Non può essere superiore al numero totale di tappe ($maxAllowed).");
            }
          }
        }
      }

      if (notesText.startsWith(' ')) {
        validationErrors.add("Note: non possono iniziare con uno spazio");
      }
    } else {
      // Validating Activity
      if (name.isEmpty) {
        validationErrors.add("Nome attività: campo obbligatorio");
      } else if (name.startsWith(' ')) {
        validationErrors.add("Nome attività: non può iniziare con uno spazio");
      }

      if (description.isEmpty) {
        validationErrors.add("Descrizione attività: campo obbligatorio");
      } else if (description.startsWith(' ')) {
        validationErrors.add("Descrizione attività: non può iniziare con uno spazio");
      }

      if (timeText.isEmpty) {
        validationErrors.add("Orario / Fascia oraria: campo obbligatorio");
      } else if (timeText.startsWith(' ')) {
        validationErrors.add("Orario / Fascia oraria: non può iniziare con uno spazio");
      }

      if (location.isEmpty) {
        validationErrors.add("Luogo attività: campo obbligatorio");
      } else if (location.startsWith(' ')) {
        validationErrors.add("Luogo attività: non può iniziare con uno spazio");
      }

      if (costText.isEmpty) {
        validationErrors.add("Costo previsto: campo obbligatorio");
      } else if (costText.startsWith(' ')) {
        validationErrors.add("Costo previsto: non può iniziare con uno spazio");
      } else if (!RegExp(r'^\d+,\d+$').hasMatch(costText)) {
        validationErrors.add("Costo previsto: deve includere i decimali separati da una virgola (es: 15,50 o 0,00)");
      } else {
        final parsed = double.tryParse(costText.replaceAll(',', '.'));
        if (parsed == null || parsed < 0) {
          validationErrors.add("Costo previsto: deve essere maggiore o uguale a zero");
        }
      }

      if (notesText.startsWith(' ')) {
        validationErrors.add("Note: non possono iniziare con uno spazio");
      }
    }

    if (validationErrors.isNotEmpty) {
      setState(() {
        _validationTriggered = true;
      });
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              SizedBox(width: 8),
              Expanded(
                child: Text("Controlli di Validazione"),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Per salvare, compila o correggi i seguenti campi:"),
                const SizedBox(height: 12),
                ...validationErrors.map((error) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 5.0),
                        child: Icon(Icons.circle, size: 6, color: Colors.redAccent),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          error,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                )),
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
      final orderVal = int.parse(orderText.trim());
      if (widget.stop == null) {
        // Adding a Stop
        final newStop = Stop(
          tripId: widget.tripId,
          name: name.trim(),
          description: description.trim(),
          dateTime: _stopDateTime,
          location: location.trim(),
          itineraryOrder: orderVal,
          notes: notesText.trim(),
        );
        provider.addStop(newStop);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Tappa '${name.trim()}' aggiunta con successo!")),
        );
      } else {
        // Editing a Stop
        final updatedStop = widget.stop!.copyWith(
          name: name.trim(),
          description: description.trim(),
          dateTime: _stopDateTime,
          location: location.trim(),
          itineraryOrder: orderVal,
          notes: notesText.trim(),
        );
        provider.updateStop(updatedStop);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Tappa '${name.trim()}' modificata con successo!")),
        );
      }
    } else {
      // Adding/Editing an Activity
      final cost = double.tryParse(costText.trim().replaceAll(',', '.')) ?? 0.0;
      final status = _selectedActivityStatus;

      if (widget.activity == null) {
        // Adding Activity
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
          SnackBar(content: Text("Attività '${name.trim()}' aggiunta con successo!")),
        );
      } else {
        // Editing Activity
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
          SnackBar(content: Text("Attività '${name.trim()}' modificata con successo!")),
        );
      }
    }
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

              // 1. Name input
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: isActivity ? "Nome Attività *" : "Nome Tappa / Giornata *",
                  hintText: isActivity ? "Es: Visita al Museo del Louvre" : "Es: Primo Giorno a Parigi",
                  prefixIcon: Icon(isActivity ? Icons.local_activity : Icons.place),
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

              // 2. Stop or Activity specific fields
              if (!isActivity) ...[
                // Stop location input
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

                // Order in itinerary input
                TextFormField(
                  controller: _itineraryOrderController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "Ordine nell'itinerario *",
                    hintText: "Es: 1 (giorno 1)",
                    prefixIcon: const Icon(Icons.format_list_numbered),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Inserisci l'ordine";
                    }
                    if (value.startsWith(' ')) {
                      return "Non può iniziare con uno spazio";
                    }
                    final orderVal = int.tryParse(value);
                    if (orderVal == null || orderVal <= 0) {
                      return "Inserisci un numero intero maggiore di 0";
                    }
                    final provider = Provider.of<TravelProvider>(context, listen: false);
                    final existingStops = provider.currentStops;
                    if (widget.stop == null) {
                      final maxAllowed = existingStops.length + 1;
                      if (orderVal > maxAllowed) {
                        return "Non puoi saltare giorni. Max consentito: $maxAllowed";
                      }
                    } else {
                      final maxAllowed = existingStops.length;
                      if (orderVal > maxAllowed) {
                        return "Giorno non valido. Max consentito: $maxAllowed";
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Stop DateTime Picker Card
                InkWell(
                  onTap: _selectDateTime,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.5)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Data e Ora *",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.calendar_month, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              "${_formatDate(_stopDateTime)} alle ${_stopDateTime.hour.toString().padLeft(2, '0')}:${_stopDateTime.minute.toString().padLeft(2, '0')}",
                              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                // Activity Type / Category Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedActivityType,
                  decoration: InputDecoration(
                    labelText: "Categoria Attività *",
                    prefixIcon: const Icon(Icons.category),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  items: AppTheme.activityIcons.keys.map((type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Row(
                        children: [
                          Icon(AppTheme.activityIcons[type], size: 20, color: Theme.of(context).colorScheme.primary),
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

                // Activity Status Dropdown (Completata, Annullata, Da svolgere)
                DropdownButtonFormField<String>(
                  value: _selectedActivityStatus,
                  decoration: InputDecoration(
                    labelText: "Stato dell'attività *",
                    prefixIcon: const Icon(Icons.task_alt),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Da svolgere', child: Text('Da svolgere')),
                    DropdownMenuItem(value: 'Completata', child: Text('Completata')),
                    DropdownMenuItem(value: 'Annullata', child: Text('Annullata')),
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

                // Location input for Activity
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

                // Activity Time / Fascia Oraria
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

                // Activity Cost input (Required)
                TextFormField(
                  controller: _costController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: "Costo previsto (€) *",
                    hintText: "Es: 15,50 o 0,00",
                    prefixIcon: const Icon(Icons.euro),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Inserisci il costo previsto (scrivi 0,00 se gratuita)";
                    }
                    if (value.startsWith(' ')) {
                      return "Non può iniziare con uno spazio";
                    }
                    final val = value.replaceAll(',', '.');
                    if (double.tryParse(val) == null || double.parse(val) < 0) {
                      return "Importo non valido";
                    }
                    if (!RegExp(r'^\d+,\d+$').hasMatch(value)) {
                      return "Deve includere i decimali separati da una virgola (es: 15,50)";
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 20),

              // 3. Description input
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: isActivity ? "Descrizione Attività *" : "Descrizione della giornata *",
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

              // 4. Notes input (Shared, optional)
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: "Note aggiuntive",
                  hintText: isActivity ? "Es: I biglietti sono sul telefono" : "Es: Ricordarsi la macchina fotografica",
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

              // 5. Save Button
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
                  isEdit ? "Salva Modifiche" : (isActivity ? "Aggiungi Attività" : "Aggiungi Tappa"),
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
