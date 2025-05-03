import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mensa_scolastica/models/student.dart';
import 'package:mensa_scolastica/providers/student_provider.dart';
import 'package:mensa_scolastica/repositories/student_repository.dart';
import 'package:mensa_scolastica/utils/qr_utils.dart';

class AddEditStudentScreen extends ConsumerStatefulWidget {
  final Student? student;

  const AddEditStudentScreen({
    Key? key,
    this.student,
  }) : super(key: key);

  @override
  ConsumerState<AddEditStudentScreen> createState() => _AddEditStudentScreenState();
}

class _AddEditStudentScreenState extends ConsumerState<AddEditStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _classController = TextEditingController();
  final _schoolController = TextEditingController();
  final _creditController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _dietController = TextEditingController();

  bool _isProcessing = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.student != null;

    if (_isEditing) {
      _firstNameController.text = widget.student!.firstName;
      _lastNameController.text = widget.student!.lastName;
      _classController.text = widget.student!.className;
      _schoolController.text = widget.student!.school;
      _creditController.text = widget.student!.credit.toString();
      _allergiesController.text = widget.student!.allergies.join(', ');
      _dietController.text = widget.student!.diet;
    } else {
      _creditController.text = '0';
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _classController.dispose();
    _schoolController.dispose();
    _creditController.dispose();
    _allergiesController.dispose();
    _dietController.dispose();
    super.dispose();
  }

  Future<void> _saveStudent() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isProcessing = true;
      });

      try {
        final studentRepository = ref.read(studentRepositoryProvider);

        // Preparare i dati dello studente
        final allergiesList = _allergiesController.text.isEmpty
            ? <String>[]
            : _allergiesController.text.split(',').map((e) => e.trim()).toList();

        if (_isEditing) {
          // Aggiornare studente esistente
          final updatedStudent = widget.student!.copyWith(
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            className: _classController.text.trim(),
            school: _schoolController.text.trim(),
            credit: int.parse(_creditController.text.trim()),
            allergies: allergiesList,
            diet: _dietController.text.trim(),
            updatedAt: DateTime.now(),
          );

          await studentRepository.updateStudent(
            widget.student!.id,
            updatedStudent.toFirestore(),
          );

          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Studente aggiornato con successo'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        } else {
          // Creare nuovo studente
          final salt = QrUtils.generateRandomSalt();

          final newStudent = Student(
            id: '', // Sarà generato da Firestore
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            className: _classController.text.trim(),
            school: _schoolController.text.trim(),
            qrCodeId: '', // Temporaneo, sarà aggiornato dopo la creazione
            credit: int.parse(_creditController.text.trim()),
            allergies: allergiesList,
            diet: _dietController.text.trim(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          // Creare prima il documento studente
          final studentId = await studentRepository.createStudent(newStudent);

          // Generare un QR code basato sull'ID studente
          final qrCodeId = QrUtils.generateSecureQrId(studentId, salt);

          // Aggiornare il documento con il QR code ID
          await studentRepository.updateStudent(studentId, {'qrCodeId': qrCodeId});

          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Studente creato con successo'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifica Studente' : 'Aggiungi Studente'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Campi del form
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'Nome',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Inserisci il nome';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Cognome',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Inserisci il cognome';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _classController,
                decoration: const InputDecoration(
                  labelText: 'Classe',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Inserisci la classe';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _schoolController,
                decoration: const InputDecoration(
                  labelText: 'Scuola',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Inserisci la scuola';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _creditController,
                decoration: const InputDecoration(
                  labelText: 'Saldo buoni',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Inserisci il saldo';
                  }
                  try {
                    int.parse(value);
                  } catch (e) {
                    return 'Inserisci un numero valido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _allergiesController,
                decoration: const InputDecoration(
                  labelText: 'Allergie (separate da virgola)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dietController,
                decoration: const InputDecoration(
                  labelText: 'Dieta speciale',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _saveStudent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: _isProcessing
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                    _isEditing ? 'Aggiorna Studente' : 'Crea Studente',
                    style: const TextStyle(fontSize: 16),
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