import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mensa_scolastica/models/student.dart';
import 'package:mensa_scolastica/providers/student_provider.dart';
import 'package:mensa_scolastica/screens/admin/add_edit_student_screen.dart';

class ManageStudentsScreen extends ConsumerStatefulWidget {
  const ManageStudentsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ManageStudentsScreen> createState() => _ManageStudentsScreenState();
}

class _ManageStudentsScreenState extends ConsumerState<ManageStudentsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToAddStudent() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEditStudentScreen(),
      ),
    ).then((_) {
      // Aggiorna la lista quando torna indietro
      ref.refresh(studentListProvider);
    });
  }

  void _navigateToEditStudent(Student student) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditStudentScreen(student: student),
      ),
    ).then((_) {
      // Aggiorna la lista quando torna indietro
      ref.refresh(studentListProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(studentListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestione Studenti'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(studentListProvider),
            tooltip: 'Aggiorna',
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
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddStudent,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStudentItem(Student student) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue,
          child: Text(
            student.firstName.substring(0, 1) + student.lastName.substring(0, 1),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text('${student.firstName} ${student.lastName}'),
        subtitle: Text('${student.className} - ${student.school}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getCreditColor(student.credit),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Saldo: ${student.credit}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _navigateToEditStudent(student),
            ),
          ],
        ),
        onTap: () => _navigateToEditStudent(student),
      ),
    );
  }

  Color _getCreditColor(int credit) {
    if (credit <= 2) {
      return Colors.red;
    } else if (credit <= 5) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }
}