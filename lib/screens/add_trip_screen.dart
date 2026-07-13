import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/trip.dart';
import 'package:say_my_travel/providers/travel_provider.dart';

class AddTripScreen extends StatefulWidget {
  final Trip? trip;

  const AddTripScreen({super.key, this.trip});

  @override
  State<AddTripScreen> createState() => _AddTripScreenState();
}

class _AddTripScreenState extends State<AddTripScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _destinationController;
  late TextEditingController _budgetController;
  late TextEditingController _participantsController;
  late TextEditingController _generalInfoController;

  DateTime? _startDate;
  DateTime? _endDate;
  double? _latitude;
  double? _longitude;
  String? _coverImagePath;
  bool _isNewImageSelected = false;

  bool _validationTriggered = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.trip?.title ?? '');
    _destinationController = TextEditingController(
      text: widget.trip?.destination ?? '',
    );
    _budgetController = TextEditingController(
      text: widget.trip != null
          ? widget.trip!.budget.toStringAsFixed(2).replaceAll('.', ',')
          : '',
    );
    _participantsController = TextEditingController(
      text: widget.trip?.participants ?? '',
    );
    _generalInfoController = TextEditingController(
      text: widget.trip?.generalInfo ?? '',
    );
    _startDate = widget.trip?.startDate;
    _endDate = widget.trip?.endDate;
    _latitude = widget.trip?.latitude;
    _longitude = widget.trip?.longitude;
    _coverImagePath = TravelProvider.resolveImagePath(
      widget.trip?.coverImagePath,
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _destinationController.dispose();
    _budgetController.dispose();
    _participantsController.dispose();
    _generalInfoController.dispose();
    super.dispose();
  }

  bool _isValidTitle(String text) {
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

  bool _isValidParticipantName(String text) {
    final alphaNum = RegExp(r'^[\p{L}\p{N}]$', unicode: true);
    final trimmed = text.trim();
    final words = trimmed
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return false;

    for (int i = 0; i < trimmed.length; i++) {
      final char = trimmed[i];
      if (alphaNum.hasMatch(char) || char == ' ') {
        continue;
      }
      if (const ['\'', '-', ','].contains(char)) {
        if (i > 0 && i < trimmed.length - 1) {
          final prev = trimmed[i - 1];
          final next = trimmed[i + 1];
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

  String _formatDate(DateTime? dt) {
    if (dt == null) return "Seleziona data";
    return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        // Sposta in avanti la data di fine se la data d'inizio viene selezionata dopo
        if (_endDate != null && _endDate!.isBefore(_startDate!)) {
          _endDate = _startDate;
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _pickCoverImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _coverImagePath = image.path;
          _isNewImageSelected = true;
        });
      }
    } catch (e) {
      debugPrint("Errore durante la selezione dell'immagine: $e");
    }
  }

  void _showCoverImageSourceSheet() {
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
                _pickCoverImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text("Scatta una foto"),
              onTap: () {
                Navigator.pop(sheetCtx);
                _pickCoverImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveTrip() async {
    final title = _titleController.text;
    final destination = _destinationController.text;
    final budgetText = _budgetController.text;
    final participantsText = _participantsController.text;
    final generalInfoText = _generalInfoController.text;

    List<String> validationErrors = [];

    // Validazione del titolo del viaggio
    if (title.isEmpty) {
      validationErrors.add("Titolo del viaggio: campo obbligatorio");
    } else if (title.startsWith(' ')) {
      validationErrors.add(
        "Titolo del viaggio: non può iniziare con uno spazio",
      );
    } else if (!_isValidTitle(title)) {
      validationErrors.add(
        "Titolo del viaggio: può contenere solo lettere, numeri, spazi e i caratteri speciali ' - , . ! : ? (che devono essere preceduti e seguiti da lettere o numeri)",
      );
    }

    // Validazione della destinazione principale
    if (destination.isEmpty) {
      validationErrors.add("Destinazione principale: campo obbligatorio");
    } else if (destination.startsWith(' ')) {
      validationErrors.add(
        "Destinazione principale: non può iniziare con uno spazio",
      );
    }

    // Validazione dell'importo del budget
    if (budgetText.isEmpty) {
      validationErrors.add("Budget stimato: campo obbligatorio");
    } else if (budgetText.startsWith(' ')) {
      validationErrors.add("Budget stimato: non può iniziare con uno spazio");
    } else if (!RegExp(r'^\d+,\d+$').hasMatch(budgetText)) {
      validationErrors.add(
        "Budget stimato: deve includere i decimali separati da una virgola (es: 1500,00)",
      );
    } else {
      final parsed = double.tryParse(budgetText.replaceAll(',', '.'));
      if (parsed == null || parsed <= 0) {
        validationErrors.add(
          "Budget stimato: deve essere maggiore di zero (es: 1500,00)",
        );
      }
    }

    // Validazione delle date selezionate
    if (_startDate == null) {
      validationErrors.add("Data di inizio: campo obbligatorio");
    }
    if (_endDate == null) {
      validationErrors.add("Data di fine: campo obbligatorio");
    }

    // Validazione dei partecipanti (facoltativi, ma devono avere formati validi)
    if (participantsText.startsWith(' ')) {
      validationErrors.add("Partecipanti: non può iniziare con uno spazio");
    } else if (participantsText.isNotEmpty) {
      final list = participantsText.split(',');
      bool allValid = true;
      for (final p in list) {
        if (!_isValidParticipantName(p)) {
          allValid = false;
          break;
        }
      }
      if (!allValid) {
        validationErrors.add(
          "Partecipanti: ogni nome deve contenere solo lettere, numeri, spazi e i simboli ' e - (che non possono essere all'inizio o adiacenti a spazi)",
        );
      }
    }

    // Validazione delle utilities generali (facoltative, ma devono contenere almeno una lettera)
    if (generalInfoText.startsWith(' ')) {
      validationErrors.add(
        "Utilities Generali: non possono iniziare con uno spazio",
      );
    } else if (generalInfoText.isNotEmpty) {
      final hasLetter = RegExp(
        r'\p{L}',
        unicode: true,
      ).hasMatch(generalInfoText);
      if (!hasLetter) {
        validationErrors.add(
          "Utilities Generali: non possono essere composte solo da numeri o caratteri speciali; inserisci almeno una lettera",
        );
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
              Expanded(child: Text("Controlli di Validazione")),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Per salvare il viaggio, compila o correggi i seguenti campi:",
                ),
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

      // Esegue la validazione del form per colorare i campi mancanti in rosso
      _formKey.currentState!.validate();
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<TravelProvider>(context, listen: false);
    final budget =
        double.tryParse(_budgetController.text.trim().replaceAll(',', '.')) ??
        0.0;
    final participants = _participantsController.text.trim();
    final generalInfo = _generalInfoController.text.trim();

    // Copia l'immagine selezionata nella memoria interna permanente dell'applicazione
    String? finalCoverPath;
    if (_isNewImageSelected) {
      if (_coverImagePath != null) {
        try {
          final appDocDir = await getApplicationDocumentsDirectory();
          final extension = path.extension(_coverImagePath!);
          final fileName =
              "trip_cover_${DateTime.now().millisecondsSinceEpoch}$extension";
          final savedFile = await File(
            _coverImagePath!,
          ).copy("${appDocDir.path}/$fileName");
          finalCoverPath = savedFile.path;
        } catch (e) {
          debugPrint("Error copying cover image to persistent folder: $e");
          finalCoverPath = _coverImagePath;
        }
      } else {
        finalCoverPath = null;
      }
    } else {
      // Nessuna modifica all'immagine di copertina
      finalCoverPath = widget.trip?.coverImagePath;
    }

    // Calcola lo stato del viaggio ('futuro', 'in_corso', 'completato') in base al calendario
    String status = widget.trip?.status ?? 'futuro';
    if (status != 'archiviato') {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final startDay = DateTime(
        _startDate!.year,
        _startDate!.month,
        _startDate!.day,
      );
      final endDay = DateTime(_endDate!.year, _endDate!.month, _endDate!.day);

      if (today.isBefore(startDay)) {
        status = 'futuro';
      } else if (today.isAfter(endDay)) {
        status = 'completato';
      } else {
        status = 'in_corso';
      }
    }

    if (widget.trip == null) {
      // Logica per creare un nuovo viaggio
      final newTrip = Trip(
        title: title.trim(),
        destination: destination.trim(),
        startDate: _startDate!,
        endDate: _endDate!,
        coverImagePath: finalCoverPath,
        budget: budget,
        status: status,
        participants: participants,
        generalInfo: generalInfo,
        latitude: _latitude,
        longitude: _longitude,
      );
      provider.addTrip(newTrip);
    } else {
      // Logica per aggiornare un viaggio esistente
      final updatedTrip = widget.trip!.copyWith(
        title: title.trim(),
        destination: destination.trim(),
        startDate: _startDate!,
        endDate: _endDate!,
        coverImagePath: finalCoverPath,
        budget: budget,
        status: status,
        participants: participants,
        generalInfo: generalInfo,
        latitude: _latitude,
        longitude: _longitude,
      );
      provider.updateTrip(updatedTrip);
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.trip == null
                ? "Viaggio creato con successo!"
                : "Viaggio modificato con successo!",
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.trip != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? "Modifica Viaggio" : "Nuovo Viaggio"),
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
                isEdit
                    ? "Aggiorna i dettagli del tuo viaggio"
                    : "Comincia ad organizzare il tuo prossimo viaggio!",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 28),

              // Input del nome del viaggio
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: "Nome Viaggio *",
                  hintText: "Es: Vacanze Estive a Tokyo",
                  prefixIcon: const Icon(Icons.title),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Inserisci un nome per il viaggio";
                  }
                  if (value.startsWith(' ')) {
                    return "Il nome non può iniziare con uno spazio";
                  }
                  if (!_isValidTitle(value)) {
                    return "Usa solo lettere, numeri, spazi e ' - , . ! : ? circondati da lettere/numeri";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Input della destinazione
              TextFormField(
                controller: _destinationController,
                decoration: InputDecoration(
                  labelText: "Destinazione Principale *",
                  hintText: "Es: Tokyo, Parigi, Colosseo...",
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Inserisci la destinazione";
                  }
                  if (value.startsWith(' ')) {
                    return "La destinazione non può iniziare con uno spazio";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Input per specificare il budget stimato
              TextFormField(
                controller: _budgetController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: "Budget Stimato (€) *",
                  hintText: "Es: 1500,00",
                  prefixIcon: const Icon(Icons.euro),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Inserisci il budget";
                  }
                  if (value.startsWith(' ')) {
                    return "Il budget non può iniziare con uno spazio";
                  }
                  if (!RegExp(r'^\d+,\d+$').hasMatch(value)) {
                    return "Deve includere i decimali separati da una virgola (es: 1500,00)";
                  }
                  final parsed = double.tryParse(value.replaceAll(',', '.'));
                  if (parsed == null || parsed <= 0) {
                    return "Deve essere maggiore di 0";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Area di inserimento partecipanti (nomi separati da virgole)
              TextFormField(
                controller: _participantsController,
                decoration: InputDecoration(
                  labelText: "Partecipanti",
                  hintText: "Es: Mario Rossi, Sofia Bianchi",
                  prefixIcon: const Icon(Icons.people_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                validator: (value) {
                  final text = value ?? '';
                  if (text.isEmpty) return null;
                  if (text.startsWith(' ')) {
                    return "Non può iniziare con uno spazio";
                  }
                  final list = text.split(',');
                  for (final p in list) {
                    if (!_isValidParticipantName(p)) {
                      return "Usa caratteri validi (lettere, spazi, ' e -)";
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Input multilinea per le note e informazioni generali
              TextFormField(
                controller: _generalInfoController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: "Utilities Generali",
                  hintText:
                      "Inserisci dettagli utili come hotel, numeri di emergenza, note sui voli...",
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 50.0),
                    child: Icon(Icons.info_outline),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                validator: (value) {
                  final text = value ?? '';
                  if (text.isEmpty) return null;
                  if (text.startsWith(' ')) {
                    return "Non può iniziare con uno spazio";
                  }
                  final hasLetter = RegExp(
                    r'\p{L}',
                    unicode: true,
                  ).hasMatch(text);
                  if (!hasLetter) {
                    return "Inserisci almeno una lettera (non solo numeri o simboli)";
                  }
                  return null;
                },
              ),

              // Selettore dell'immagine di sfondo/copertina
              const SizedBox(height: 20),
              Text(
                "Sfondo del Viaggio",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _showCoverImageSourceSheet,
                child: Container(
                  height: 160,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).dividerColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: _coverImagePath == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 40,
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.7),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "Seleziona Sfondo Viaggio",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Verrà mostrato come copertina nella Home",
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
                              Image.file(
                                File(_coverImagePath!),
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
                              ),
                              Positioned(
                                right: 12,
                                top: 12,
                                child: CircleAvatar(
                                  backgroundColor: Colors.black.withValues(
                                    alpha: 0.6,
                                  ),
                                  radius: 18,
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _coverImagePath = null;
                                        _isNewImageSelected = true;
                                      });
                                    },
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 12,
                                bottom: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.edit,
                                        color: Colors.white,
                                        size: 12,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        "Modifica sfondo",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // Pulsanti e indicatori per selezionare la data di inizio e fine
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: _selectStartDate,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color:
                                    _validationTriggered && _startDate == null
                                    ? Theme.of(context).colorScheme.error
                                    : Theme.of(context).colorScheme.outline
                                          .withValues(alpha: 0.5),
                                width:
                                    _validationTriggered && _startDate == null
                                    ? 2.0
                                    : 1.0,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Data Inizio *",
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color:
                                            _validationTriggered &&
                                                _startDate == null
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.error
                                            : Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                      ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_month,
                                      size: 16,
                                      color:
                                          _validationTriggered &&
                                              _startDate == null
                                          ? Theme.of(context).colorScheme.error
                                          : null,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _formatDate(_startDate),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color:
                                            _validationTriggered &&
                                                _startDate == null
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.error
                                            : null,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_validationTriggered && _startDate == null)
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 12.0,
                              top: 6.0,
                            ),
                            child: Text(
                              "Seleziona la data di inizio",
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: _selectEndDate,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _validationTriggered && _endDate == null
                                    ? Theme.of(context).colorScheme.error
                                    : Theme.of(context).colorScheme.outline
                                          .withValues(alpha: 0.5),
                                width: _validationTriggered && _endDate == null
                                    ? 2.0
                                    : 1.0,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Data Fine *",
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color:
                                            _validationTriggered &&
                                                _endDate == null
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.error
                                            : Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                      ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_month,
                                      size: 16,
                                      color:
                                          _validationTriggered &&
                                              _endDate == null
                                          ? Theme.of(context).colorScheme.error
                                          : null,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _formatDate(_endDate),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color:
                                            _validationTriggered &&
                                                _endDate == null
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.error
                                            : null,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_validationTriggered && _endDate == null)
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 12.0,
                              top: 6.0,
                            ),
                            child: Text(
                              "Seleziona la data di fine",
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // Pulsante per salvare o modificare il viaggio
              ElevatedButton(
                onPressed: _saveTrip,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  isEdit ? "Salva Modifiche" : "Crea Viaggio",
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
