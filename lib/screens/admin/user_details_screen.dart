import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mensa_scolastica/models/student.dart';
import 'package:mensa_scolastica/models/user.dart';
import 'package:mensa_scolastica/providers/student_provider.dart';
import 'package:mensa_scolastica/repositories/user_repository.dart';

class UserDetailsScreen extends ConsumerStatefulWidget {
  final AppUser user;

  const UserDetailsScreen({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  ConsumerState<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends ConsumerState<UserDetailsScreen> {
  bool _isEditing = false;
  bool _isProcessing = false;
  late TextEditingController _displayNameController;
  late TextEditingController _emailController;
  late TextEditingController _schoolController;
  String _selectedRole = 'genitore';
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController(text: widget.user.displayName);
    _emailController = TextEditingController(text: widget.user.email);
    _schoolController = TextEditingController(text: widget.user.school ?? '');
    _selectedRole = widget.user.role;
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _schoolController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isProcessing = true;
      });

      try {
        final userRepository = ref.read(userRepositoryProvider);

        final updatedData = {
          'displayName': _displayNameController.text.trim(),
          'email': _emailController.text.trim(),
          'role': _selectedRole,
        };

        if (_selectedRole == 'operatore') {
          updatedData['school'] = _schoolController.text.trim();
        } else {
          // Se l'utente non è un operatore, rimuovi il campo school
          // (Firestore non supporta l'impostazione diretta a null, quindi useremo un'operazione di eliminazione campo)
          // userRepository.updateUserRemoveField(widget.user.id, 'school');
          // Per semplicità in questa implementazione, impostiamo school a stringa vuota
          updatedData['school'] = '';
        }

        await userRepository.updateUser(widget.user.id, updatedData);

        if (!mounted) return;

        setState(() {
          _isEditing = false;
          _isProcessing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Utente aggiornato con successo'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) return;

        setState(() {
          _isProcessing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dettagli Utente'),
        actions: [
          _isEditing
              ? IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              setState(() {
                _isEditing = false;
                // Ripristina i valori originali
                _displayNameController.text = widget.user.displayName;
                _emailController.text = widget.user.email;
                _schoolController.text = widget.user.school ?? '';
                _selectedRole = widget.user.role;
              });
            },
            tooltip: 'Annulla',
          )
              : IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              setState(() {
                _isEditing = true;
              });
            },
            tooltip: 'Modifica',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUserCard(),
            const SizedBox(height: 24),
            _isEditing ? _buildEditForm() : _buildUserDetails(),
            if (widget.user.role == 'genitore')
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  const Text(
                    'Figli associati',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildLinkedStudentsList(),
                ],
              ),
          ],
        ),
      ),
      bottomNavigationBar: _isEditing
          ? BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ElevatedButton(
            onPressed: _isProcessing ? null : _saveChanges,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(50),
            ),
            child: _isProcessing
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Salva modifiche', style: TextStyle(fontSize: 16)),
          ),
        ),
      )
          : null,
    );
  }

  Widget _buildUserCard() {
    final Color roleColor = _getRoleColor(widget.user.role);
    final IconData roleIcon = _getRoleIcon(widget.user.role);

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: roleColor.withOpacity(0.2),
              child: Icon(roleIcon, color: roleColor, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.user.displayName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.user.email,
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    _getRoleInItalian(widget.user.role),
                    style: TextStyle(
                      fontSize: 14,
                      color: roleColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Informazioni utente',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildDetailItem('Nome e cognome', widget.user.displayName),
        _buildDetailItem('Email', widget.user.email),
        _buildDetailItem('Ruolo', _getRoleInItalian(widget.user.role)),
        if (widget.user.school != null && widget.user.school!.isNotEmpty)
          _buildDetailItem('Scuola', widget.user.school!),
        _buildDetailItem('Data creazione', _formatDate(widget.user.createdAt)),
        if (widget.user.linkedStudents != null && widget.user.linkedStudents!.isNotEmpty)
          _buildDetailItem('Figli associati', widget.user.linkedStudents!.length.toString()),
      ],
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Modifica informazioni',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _displayNameController,
            decoration: const InputDecoration(
              labelText: 'Nome e cognome',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Inserisci il nome e cognome';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Inserisci l\'email';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Inserisci un indirizzo email valido';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedRole,
            decoration: const InputDecoration(
              labelText: 'Ruolo',
              border: OutlineInputBorder(),
            ),
            items: [
              DropdownMenuItem(
                value: 'genitore',
                child: Text(_getRoleInItalian('genitore')),
              ),
              DropdownMenuItem(
                value: 'operatore',
                child: Text(_getRoleInItalian('operatore')),
              ),
              DropdownMenuItem(
                value: 'admin',
                child: Text(_getRoleInItalian('admin')),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _selectedRole = value ?? 'genitore';
              });
            },
          ),
          const SizedBox(height: 16),
          if (_selectedRole == 'operatore')
            TextFormField(
              controller: _schoolController,
              decoration: const InputDecoration(
                labelText: 'Scuola',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (_selectedRole == 'operatore' && (value == null || value.isEmpty)) {
                  return 'Inserisci la scuola per l\'operatore';
                }
                return null;
              },
            ),
        ],
      ),
    );
  }

  Widget _buildLinkedStudentsList() {
    if (widget.user.linkedStudents == null || widget.user.linkedStudents!.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Nessun figlio associato a questo genitore'),
        ),
      );
    }

    return Column(
      children: widget.user.linkedStudents!.map((studentId) {
        return _buildLinkedStudentItem(studentId);
      }).toList(),
    );
  }

  Widget _buildLinkedStudentItem(String studentId) {
    return FutureBuilder<Student?>(
      future: ref.read(studentRepositoryProvider).getStudentById(studentId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (snapshot.hasError) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Errore: ${snapshot.error}'),
            ),
          );
        }

        final student = snapshot.data;
        if (student == null) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Studente non trovato: $studentId'),
            ),
          );
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue,
              child: Text(
                student.firstName.substring(0, 1) + student.lastName.substring(0, 1),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text('${student.firstName} ${student.lastName}'),
            subtitle: Text('Classe ${student.className} - ${student.school}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _showRemoveStudentDialog(student),
            ),
          ),
        );
      },
    );
  }

  void _showRemoveStudentDialog(Student student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rimuovi associazione'),
        content: Text(
          'Sei sicuro di voler rimuovere l\'associazione tra ${widget.user.displayName} e ${student.firstName} ${student.lastName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              setState(() {
                _isProcessing = true;
              });

              try {
                final userRepository = ref.read(userRepositoryProvider);
                await userRepository.unlinkStudentFromParent(widget.user.id, student.id);

                if (!mounted) return;

                // Aggiornare l'utente in locale
                setState(() {
                  widget.user.linkedStudents?.remove(student.id);
                  _isProcessing = false;
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Associazione rimossa con successo'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!mounted) return;

                setState(() {
                  _isProcessing = false;
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Errore: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Rimuovi'),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'genitore':
        return Colors.blue;
      case 'operatore':
        return Colors.green;
      case 'admin':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'genitore':
        return Icons.family_restroom;
      case 'operatore':
        return Icons.assignment_ind;
      case 'admin':
        return Icons.admin_panel_settings;
      default:
        return Icons.person;
    }
  }

  String _getRoleInItalian(String role) {
    switch (role) {
      case 'genitore':
        return 'Genitore';
      case 'operatore':
        return 'Operatore mensa';
      case 'admin':
        return 'Amministratore';
      default:
        return role;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}