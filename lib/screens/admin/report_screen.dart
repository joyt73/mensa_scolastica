import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mensa_scolastica/models/transaction.dart';
import 'package:mensa_scolastica/providers/student_provider.dart';
import 'package:mensa_scolastica/providers/transaction_provider.dart';
import 'package:mensa_scolastica/repositories/transaction_repository.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// Provider per tutte le transazioni
final allTransactionsProvider = FutureProvider<List<MealTransaction>>((ref) async {
  final repository = ref.watch(transactionRepositoryProvider);
  // Utilizza un metodo pubblico per ottenere tutte le transazioni
  return repository.getAllTransactions();
});

class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  String _selectedReport = 'all';
  String _selectedView = 'list'; // 'list', 'charts', 'summary'
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(allTransactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report e Statistiche'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () => _showExportDialog(context, transactionsAsync),
            tooltip: 'Esporta',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filtri
            _buildDateFilters(),
            const SizedBox(height: 16),
            _buildReportTypeSelector(),
            const SizedBox(height: 16),
            _buildViewSelector(),
            const SizedBox(height: 24),

            // Contenuto del report
            Expanded(
              child: transactionsAsync.when(
                data: (transactions) {
                  // Filtra le transazioni per data
                  final filteredTransactions = transactions.where((t) {
                    return t.timestamp.isAfter(_startDate) &&
                        t.timestamp.isBefore(_endDate.add(const Duration(days: 1)));
                  }).toList();

                  // Filtra per tipo di report
                  if (_selectedReport == 'meals') {
                    filteredTransactions.removeWhere((t) => t.type != 'pasto');
                  } else if (_selectedReport == 'recharges') {
                    filteredTransactions.removeWhere((t) => t.type != 'ricarica');
                  }

                  if (filteredTransactions.isEmpty) {
                    return const Center(
                      child: Text('Nessuna transazione nel periodo selezionato'),
                    );
                  }

                  // Mostra in base alla vista selezionata
                  switch (_selectedView) {
                    case 'charts':
                      return _buildChartsView(filteredTransactions);
                    case 'summary':
                      return _buildSummaryView(filteredTransactions);
                    case 'list':
                    default:
                      return _buildListView(filteredTransactions);
                  }
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Text('Errore nel caricamento dei dati: $error'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateFilters() {
    final dateFormatter = DateFormat('dd/MM/yyyy');
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => _selectDate(true),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Da',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              child: Text(dateFormatter.format(_startDate)),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: InkWell(
            onTap: () => _selectDate(false),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'A',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              child: Text(dateFormatter.format(_endDate)),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate(bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          // Assicurati che la data di inizio non sia successiva alla data di fine
          if (_startDate.isAfter(_endDate)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
          // Assicurati che la data di fine non sia precedente alla data di inizio
          if (_endDate.isBefore(_startDate)) {
            _startDate = _endDate;
          }
        }
      });
    }
  }

  Widget _buildReportTypeSelector() {
    return Row(
      children: [
        Expanded(
          child: RadioListTile<String>(
            title: const Text('Tutti'),
            value: 'all',
            groupValue: _selectedReport,
            onChanged: (value) {
              setState(() {
                _selectedReport = value!;
              });
            },
          ),
        ),
        Expanded(
          child: RadioListTile<String>(
            title: const Text('Pasti'),
            value: 'meals',
            groupValue: _selectedReport,
            onChanged: (value) {
              setState(() {
                _selectedReport = value!;
              });
            },
          ),
        ),
        Expanded(
          child: RadioListTile<String>(
            title: const Text('Ricariche'),
            value: 'recharges',
            groupValue: _selectedReport,
            onChanged: (value) {
              setState(() {
                _selectedReport = value!;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildViewSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildViewButton('Lista', 'list', Icons.list),
        const SizedBox(width: 8),
        _buildViewButton('Grafici', 'charts', Icons.bar_chart),
        const SizedBox(width: 8),
        _buildViewButton('Riepilogo', 'summary', Icons.summarize),
      ],
    );
  }

  Widget _buildViewButton(String label, String view, IconData icon) {
    final isSelected = _selectedView == view;

    return ElevatedButton.icon(
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Theme.of(context).primaryColor : Colors.grey[300],
        foregroundColor: isSelected ? Colors.white : Colors.black,
      ),
      onPressed: () {
        setState(() {
          _selectedView = view;
        });
      },
    );
  }

  Widget _buildListView(List<MealTransaction> transactions) {
    final dateFormatter = DateFormat('dd/MM/yyyy HH:mm');

    return Column(
      children: [
        _buildSummaryCards(transactions),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 8),
        const Text(
          'Dettaglio Transazioni',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final transaction = transactions[index];
              final formattedDate = dateFormatter.format(transaction.timestamp);

              final isMeal = transaction.type == 'pasto';
              final icon = isMeal ? Icons.restaurant : Icons.account_balance_wallet;
              final color = isMeal ? Colors.red : Colors.green;
              final sign = isMeal ? '-' : '+';
              final amount = transaction.amount.abs();

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color.withOpacity(0.2),
                    child: Icon(icon, color: color),
                  ),
                  title: Text(isMeal ? 'Pasto consumato' : 'Ricarica buoni'),
                  subtitle: FutureBuilder(
                    future: ref.read(studentByIdProvider(transaction.studentId).future),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data != null) {
                        final student = snapshot.data!;
                        return Text(
                          '${student.firstName} ${student.lastName} - $formattedDate',
                        );
                      }
                      return Text(formattedDate);
                    },
                  ),
                  trailing: Text(
                    '$sign$amount',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChartsView(List<MealTransaction> transactions) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCards(transactions),
          const SizedBox(height: 24),
          const Text(
            'Transazioni per giorno',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: _buildDailyTransactionChart(transactions),
          ),
          const SizedBox(height: 24),
          const Text(
            'Distribuzione per tipo',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: Row(
              children: [
                Expanded(
                  child: _buildTransactionPieChart(transactions),
                ),
                Expanded(
                  child: _buildPieChartLegend(transactions),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryView(List<MealTransaction> transactions) {
    // Raggruppa per data
    final Map<String, List<MealTransaction>> dailyTransactions = {};
    final dateFormatter = DateFormat('yyyy-MM-dd');

    for (final transaction in transactions) {
      final dateStr = dateFormatter.format(transaction.timestamp);
      if (!dailyTransactions.containsKey(dateStr)) {
        dailyTransactions[dateStr] = [];
      }
      dailyTransactions[dateStr]!.add(transaction);
    }

    // Ordina le date
    final sortedDates = dailyTransactions.keys.toList()..sort();

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildSummaryCards(transactions),
          const SizedBox(height: 24),
          const Text(
            'Riepilogo giornaliero',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...sortedDates.map((dateStr) {
            final transactionsForDay = dailyTransactions[dateStr]!;
            final mealsCount = transactionsForDay.where((t) => t.type == 'pasto').length;
            final rechargesCount = transactionsForDay.where((t) => t.type == 'ricarica').length;
            final totalMealAmount = transactionsForDay
                .where((t) => t.type == 'pasto')
                .fold(0, (sum, t) => sum + t.amount.abs());
            final totalRechargeAmount = transactionsForDay
                .where((t) => t.type == 'ricarica')
                .fold(0, (sum, t) => sum + t.amount.abs());

            final parsedDate = DateTime.parse(dateStr);
            final formattedDate = DateFormat('dd/MM/yyyy').format(parsedDate);

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formattedDate,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              const Text('Pasti'),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.restaurant, color: Colors.red, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$mealsCount ($totalMealAmount buoni)',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const VerticalDivider(),
                        Expanded(
                          child: Column(
                            children: [
                              const Text('Ricariche'),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.account_balance_wallet, color: Colors.green, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$rechargesCount ($totalRechargeAmount buoni)',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(List<MealTransaction> transactions) {
    final mealTransactions = transactions.where((t) => t.type == 'pasto').toList();
    final rechargeTransactions = transactions.where((t) => t.type == 'ricarica').toList();

    final totalMeals = mealTransactions.length;
    final totalRecharges = rechargeTransactions.length;

    final totalMealAmount = mealTransactions.fold<int>(
        0, (sum, t) => sum + t.amount.abs());
    final totalRechargeAmount = rechargeTransactions.fold<int>(
        0, (sum, t) => sum + t.amount.abs());

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Pasti',
            totalMeals.toString(),
            'Valore: $totalMealAmount',
            Icons.restaurant,
            Colors.red,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            'Ricariche',
            totalRecharges.toString(),
            'Valore: $totalRechargeAmount',
            Icons.account_balance_wallet,
            Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
      String title,
      String value,
      String subtitle,
      IconData icon,
      Color color,
      ) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyTransactionChart(List<MealTransaction> transactions) {
    // Raggruppa per data
    final Map<String, int> mealsByDay = {};
    final Map<String, int> rechargesByDay = {};
    final dateFormatter = DateFormat('yyyy-MM-dd');
    final displayFormatter = DateFormat('dd/MM');

    // Inizializza con tutte le date nel range
    DateTime currentDate = _startDate;
    while (currentDate.isBefore(_endDate.add(const Duration(days: 1)))) {
      final dateStr = dateFormatter.format(currentDate);
      mealsByDay[dateStr] = 0;
      rechargesByDay[dateStr] = 0;
      currentDate = currentDate.add(const Duration(days: 1));
    }

    // Popola con i dati effettivi
    for (final transaction in transactions) {
      final dateStr = dateFormatter.format(transaction.timestamp);

      if (transaction.type == 'pasto') {
        mealsByDay[dateStr] = (mealsByDay[dateStr] ?? 0) + 1;
      } else {
        rechargesByDay[dateStr] = (rechargesByDay[dateStr] ?? 0) + 1;
      }
    }

    // Converti in dati per il grafico
    final List<FlSpot> mealSpots = [];
    final List<FlSpot> rechargeSpots = [];

    // Ordina le date
    final sortedDates = mealsByDay.keys.toList()..sort();

    for (int i = 0; i < sortedDates.length; i++) {
      final dateStr = sortedDates[i];
      mealSpots.add(FlSpot(i.toDouble(), mealsByDay[dateStr]!.toDouble()));
      rechargeSpots.add(FlSpot(i.toDouble(), rechargesByDay[dateStr]!.toDouble()));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 1,
          verticalInterval: 1,
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < 0 || value.toInt() >= sortedDates.length) {
                  return const Text('');
                }
                final dateStr = sortedDates[value.toInt()];
                final parsedDate = DateTime.parse(dateStr);
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    displayFormatter.format(parsedDate),
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 2,
              reservedSize: 40,
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: const Color(0xff37434d)),
        ),
        minX: 0,
        maxX: sortedDates.length - 1.toDouble(),
        minY: 0,
        lineBarsData: [
          LineChartBarData(
            spots: mealSpots,
            isCurved: true,
            color: Colors.red,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(
              show: false,
            ),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.red.withOpacity(0.2),
            ),
          ),
          LineChartBarData(
            spots: rechargeSpots,
            isCurved: true,
            color: Colors.green,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(
              show: false,
            ),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.green.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionPieChart(List<MealTransaction> transactions) {
    final meals = transactions.where((t) => t.type == 'pasto').length;
    final recharges = transactions.where((t) => t.type == 'ricarica').length;
    final total = meals + recharges;

    if (total == 0) {
      return const Center(child: Text('Nessun dato disponibile'));
    }

    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: [
          PieChartSectionData(
            color: Colors.red,
            value: meals.toDouble(),
            title: '${((meals / total) * 100).toStringAsFixed(1)}%',
            radius: 100,
            titleStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          PieChartSectionData(
            color: Colors.green,
            value: recharges.toDouble(),
            title: '${((recharges / total) * 100).toStringAsFixed(1)}%',
            radius: 100,
            titleStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChartLegend(List<MealTransaction> transactions) {
    final meals = transactions.where((t) => t.type == 'pasto').length;
    final recharges = transactions.where((t) => t.type == 'ricarica').length;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem('Pasti', meals.toString(), Colors.red),
        const SizedBox(height: 16),
        _buildLegendItem('Ricariche', recharges.toString(), Colors.green),
      ],
    );
  }

  Widget _buildLegendItem(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: $value',
          style: const TextStyle(
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  void _showExportDialog(BuildContext context, AsyncValue<List<MealTransaction>> transactionsAsync) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Esporta Report'),
        content: const Text('Scegli il formato di esportazione:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('PDF'),
            onPressed: () {
              Navigator.pop(context);
              //_exportToPdf(transactionsAsync);
            },
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.print),
            label: const Text('Stampa'),
            onPressed: () {
              Navigator.pop(context);
              //_printReport(transactionsAsync);
            },
          ),
        ],
      ),
    );
  }

/*
  Future<void> _exportToPdf(AsyncValue<List<MealTransaction>> transactionsAsync) async {
    if (transactionsAsync is! AsyncData) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dati non ancora caricati. Riprova.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isExporting = true;
    });

    try {
      // Filtra le transazioni
      final allTransactions = transactionsAsync.value;
      final filteredTransactions = allTransactions.where((t) {
        if (!t.timestamp.isAfter(_startDate) ||
            !t.timestamp.isBefore(_endDate.add(const Duration(days: 1)))) {
          return false;
        }

        if (_selectedReport == 'meals' && t.type != 'pasto') {
          return false;
        }

        if (_selectedReport == 'recharges' && t.type != 'ricarica') {
          return false;
        }

        return true;
      }).toList();

      // Prepara i dati per il PDF
      final mealTransactions = filteredTransactions.where((t) => t.type == 'pasto').toList();
      final rechargeTransactions = filteredTransactions.where((t) => t.type == 'ricarica').toList();

      final totalMeals = mealTransactions.length;
      final totalRecharges = rechargeTransactions.length;

      final totalMealAmount = mealTransactions.fold<int>(
          0, (sum, t) => sum + t.amount.abs());
      final totalRechargeAmount = rechargeTransactions.fold<int>(
          0, (sum, t) => sum + t.amount.abs());

      // Crea il PDF
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(
                  level: 0,
                  child: pw.Text('Report Mensa Scolastica', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
                pw.Paragraph(text: 'Periodo: ${DateFormat('dd/MM/yyyy').format(_startDate)} - ${DateFormat('dd/MM/yyyy').format(_endDate)}'),

                pw.SizedBox(height: 20),

                pw.Header(level: 1, child: pw.Text('Riepilogo', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),

                pw.SizedBox(height: 10),

                pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(10),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(),
                          borderRadius: pw.BorderRadius.circular(5),
                        ),
                        child: pw.Column(
                          children: [
                            pw.Text('Pasti', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                            pw.Text('$totalMeals'),
                            pw.Text('Valore: $totalMealAmount'),
                          ],
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 10),
                    pw.Expanded(
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(10),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(),
                          borderRadius: pw.BorderRadius.circular(5),
                        ),
                        child: pw.Column(
                          children: [
                            pw.Text('Ricariche', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                            pw.Text('$totalRecharges'),
                            pw.Text('Valore: $totalRechargeAmount'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                pw.SizedBox(height: 20),

                pw.Header(level: 1, child: pw.Text('Transazioni', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),

                pw.SizedBox(height: 10),

                pw.Table(
                  border: pw.TableBorder.all(),
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text('Data', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text('Tipo', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text('Studente', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text('Importo', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                      ],
                    ),
                    ...filteredTransactions.map((transaction) {
                      final dateFormatter = DateFormat('dd/MM/yyyy HH:mm');
                      final formattedDate = dateFormatter.format(transaction.timestamp);
                      final isMeal = transaction.type == 'pasto';
                      final sign = isMeal ? '-' : '+';
                      final amount = transaction.amount.abs();

                      return pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text(formattedDate),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text(isMeal ? 'Pasto' : 'Ricarica'),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text(transaction.studentId),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text('$sign$amount'),
                          ),
                        ],
                      );
                    }).toList(),
                  ],
                ),

                pw.SizedBox(height: 20),

                pw.Footer(
                  trailing: pw.Text('Generato il ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}'),
                ),
              ],
            );
          },
        ),
      );

      // Stampa il PDF
      final pdfData = await pdf.save();
      await Printing.sharePdf(
        bytes: pdfData,
        filename: 'report_mensa_${DateFormat('yyyyMMdd').format(_startDate)}_${DateFormat('yyyyMMdd').format(_endDate)}.pdf',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore durante l\'esportazione: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }
*/

/*
  Future<void> _printReport(AsyncValue<List<MealTransaction>> transactionsAsync) async {
    if (transactionsAsync is! AsyncData) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dati non ancora caricati. Riprova.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isExporting = true;
    });

    try {
      // Filtra le transazioni
      final allTransactions = transactionsAsync.value;
      final filteredTransactions = allTransactions.where((t) {
        if (!t.timestamp.isAfter(_startDate) ||
            !t.timestamp.isBefore(_endDate.add(const Duration(days: 1)))) {
          return false;
        }

        if (_selectedReport == 'meals' && t.type != 'pasto') {
          return false;
        }

        if (_selectedReport == 'recharges' && t.type != 'ricarica') {
          return false;
        }

        return true;
      }).toList();

      // Prepara i dati per il PDF
      final mealTransactions = filteredTransactions.where((t) => t.type == 'pasto').toList();
      final rechargeTransactions = filteredTransactions.where((t) => t.type == 'ricarica').toList();

      final totalMeals = mealTransactions.length;
      final totalRecharges = rechargeTransactions.length;

      final totalMealAmount = mealTransactions.fold<int>(
          0, (sum, t) => sum + t.amount.abs());
      final totalRechargeAmount = rechargeTransactions.fold<int>(
          0, (sum, t) => sum + t.amount.abs());

      // Crea il PDF
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(
                  level: 0,
                  child: pw.Text('Report Mensa Scolastica', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
                pw.Paragraph(text: 'Periodo: ${DateFormat('dd/MM/yyyy').format(_startDate)} - ${DateFormat('dd/MM/yyyy').format(_endDate)}'),

                pw.SizedBox(height: 20),

                pw.Header(level: 1, child: pw.Text('Riepilogo', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),

                pw.SizedBox(height: 10),

                pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(10),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(),
                          borderRadius: pw.BorderRadius.circular(5),
                        ),
                        child: pw.Column(
                          children: [
                            pw.Text('Pasti', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                            pw.Text('$totalMeals'),
                            pw.Text('Valore: $totalMealAmount'),
                          ],
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 10),
                    pw.Expanded(
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(10),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(),
                          borderRadius: pw.BorderRadius.circular(5),
                        ),
                        child: pw.Column(
                          children: [
                            pw.Text('Ricariche', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                            pw.Text('$totalRecharges'),
                            pw.Text('Valore: $totalRechargeAmount'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                pw.SizedBox(height: 20),

                pw.Header(level: 1, child: pw.Text('Transazioni', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),

                pw.SizedBox(height: 10),

                pw.Table(
                  border: pw.TableBorder.all(),
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text('Data', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text('Tipo', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text('Studente', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text('Importo', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                      ],
                    ),
                    ...filteredTransactions.map((transaction) {
                      final dateFormatter = DateFormat('dd/MM/yyyy HH:mm');
                      final formattedDate = dateFormatter.format(transaction.timestamp);
                      final isMeal = transaction.type == 'pasto';
                      final sign = isMeal ? '-' : '+';
                      final amount = transaction.amount.abs();

                      return pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text(formattedDate),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text(isMeal ? 'Pasto' : 'Ricarica'),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text(transaction.studentId),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text('$sign$amount'),
                          ),
                        ],
                      );
                    }).toList(),
                  ],
                ),

                pw.SizedBox(height: 20),

                pw.Footer(
                  trailing: pw.Text('Generato il ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}'),
                ),
              ],
            );
          },
        ),
      );

      // Stampa il PDF
      final pdfData = await pdf.save();
      await Printing.layoutPdf(
        onLayout: (format) => pdfData,
        name: 'report_mensa_${DateFormat('yyyyMMdd').format(_startDate)}_${DateFormat('yyyyMMdd').format(_endDate)}',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore durante la stampa: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }
*/
}