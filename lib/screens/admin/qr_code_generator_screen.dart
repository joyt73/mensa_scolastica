import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mensa_scolastica/models/student.dart';
import 'package:mensa_scolastica/providers/student_provider.dart';
import 'package:mensa_scolastica/utils/qr_generator.dart';

class QrCodeGeneratorScreen extends ConsumerStatefulWidget {
  const QrCodeGeneratorScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<QrCodeGeneratorScreen> createState() => _QrCodeGeneratorScreenState();
}

class _QrCodeGeneratorScreenState extends ConsumerState<QrCodeGeneratorScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<String> _selectedStudentIds = [];
  bool _isGeneratingPdf = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(studentListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Generatore QR Code'),
        actions: [
          if (_selectedStudentIds.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.print),
              onPressed: _showPrintOptions,
              tooltip: 'Stampa selezionati',
            ),
        ],
      ),
      body: Column(
        children: [
          // Barra di ricerca
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Cerca studente',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
                    : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),

          // Indicatore di selezione
          if (_selectedStudentIds.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Text(
                    'Selezionati: ${_selectedStudentIds.length} studenti',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedStudentIds.clear();
                      });
                    },
                    child: const Text('Deseleziona tutti'),
                  ),
                ],
              ),
            ),

          // Lista studenti
          Expanded(
            child: studentsAsync.when(
              data: (students) {
                // Filtra gli studenti in base alla ricerca
                final filteredStudents = students.where((student) {
                  if (_searchQuery.isEmpty) {
                    return true;
                  }

                  final fullName = '${student.firstName} ${student.lastName}'.toLowerCase();
                  final className = student.className.toLowerCase();
                  final school = student.school.toLowerCase();

                  return fullName.contains(_searchQuery) ||
                      className.contains(_searchQuery) ||
                      school.contains(_searchQuery);
                }).toList();

                if (filteredStudents.isEmpty) {
                  return Center(
                    child: _searchQuery.isEmpty
                        ? const Text('Nessuno studente registrato')
                        : const Text('Nessun risultato trovato'),
                  );
                }

                return ListView.builder(
                  itemCount: filteredStudents.length,
                  itemBuilder: (context, index) {
                    final student = filteredStudents[index];
                    return _buildStudentItem(student);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('Errore: $error'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentItem(Student student) {
    final isSelected = _selectedStudentIds.contains(student.id);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: CheckboxListTile(
        value: isSelected,
        onChanged: (value) {
          setState(() {
            if (value == true) {
              _selectedStudentIds.add(student.id);
            } else {
              _selectedStudentIds.remove(student.id);
            }
          });
        },
        title: Text('${student.firstName} ${student.lastName}'),
        subtitle: Text('Classe ${student.className} - ${student.school}'),
        secondary: CircleAvatar(
          backgroundColor: Colors.blue,
          child: Text(
            student.firstName.substring(0, 1) + student.lastName.substring(0, 1),
            style: const TextStyle(color: Colors.white),
          ),
        ),

        // onTap: () {
        //   // Visualizza singolo QR code
        //   _showQrCodeDialog(student);
        // },
      ),
    );
  }

  void _showQrCodeDialog(Student student) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              QrGenerator.buildQrCardWidget(student, size: 200),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.print),
                    label: const Text('Stampa'),
                    onPressed: () async {
                      Navigator.pop(context);
                      setState(() {
                        _isGeneratingPdf = true;
                      });

                      try {
                        final pdfData = await QrGenerator.generateStudentQrPdf(student);
                        if (!mounted) return;

                        await QrGenerator.printPdf(
                          pdfData,
                          'QR_${student.firstName}_${student.lastName}',
                        );
                      } finally {
                        if (mounted) {
                          setState(() {
                            _isGeneratingPdf = false;
                          });
                        }
                      }
                    },
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.share),
                    label: const Text('Condividi'),
                    onPressed: () async {
                      Navigator.pop(context);
                      setState(() {
                        _isGeneratingPdf = true;
                      });

                      try {
                        final pdfData = await QrGenerator.generateStudentQrPdf(student);
                        if (!mounted) return;

                        await QrGenerator.sharePdf(
                          pdfData,
                          'qr_${student.firstName.toLowerCase()}_${student.lastName.toLowerCase()}.pdf',
                        );
                      } finally {
                        if (mounted) {
                          setState(() {
                            _isGeneratingPdf = false;
                          });
                        }
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPrintOptions() {
    if (_selectedStudentIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nessuno studente selezionato'),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stampa QR Code'),
        content: const Text('Cosa vuoi fare con i QR code selezionati?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Annulla'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.print),
            label: const Text('Stampa'),
            onPressed: () async {
              Navigator.pop(context);
              await _printSelectedStudents();
            },
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.share),
            label: const Text('Condividi PDF'),
            onPressed: () async {
              Navigator.pop(context);
              await _shareSelectedStudents();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _printSelectedStudents() async {
    setState(() {
      _isGeneratingPdf = true;
    });

    try {
      final students = await _getSelectedStudents();
      if (students.isEmpty) return;

      final pdfData = await QrGenerator.generateMultipleStudentQrPdf(students);
      if (!mounted) return;

      await QrGenerator.printPdf(
        pdfData,
        'QR_Codes_${students.length}_studenti',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingPdf = false;
        });
      }
    }
  }

  Future<void> _shareSelectedStudents() async {
    setState(() {
      _isGeneratingPdf = true;
    });

    try {
      final students = await _getSelectedStudents();
      if (students.isEmpty) return;

      final pdfData = await QrGenerator.generateMultipleStudentQrPdf(students);
      if (!mounted) return;

      await QrGenerator.sharePdf(
        pdfData,
        'qr_codes_${students.length}_studenti.pdf',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingPdf = false;
        });
      }
    }
  }

  Future<List<Student>> _getSelectedStudents() async {
    final List<Student> selectedStudents = [];
    final studentRepository = ref.read(studentRepositoryProvider);

    for (final id in _selectedStudentIds) {
      final student = await studentRepository.getStudentById(id);
      if (student != null) {
        selectedStudents.add(student);
      }
    }

    return selectedStudents;
  }
}