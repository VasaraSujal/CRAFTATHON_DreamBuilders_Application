import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/app_data_provider.dart';
import '../../widgets/panel_card.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  final _searchController = TextEditingController();
  String _attackType = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppDataProvider>(
      builder: (context, data, _) {
        final query = _searchController.text.trim().toLowerCase();
        final logs = data.logs.where((item) {
          final src = (item['source']?.toString() ?? '').toLowerCase();
          final dst = (item['destination']?.toString() ?? '').toLowerCase();
          final hitQuery = query.isEmpty || src.contains(query) || dst.contains(query);
          final hitType = _attackType == 'All' || item['attackType'] == _attackType;
          return hitQuery && hitType;
        }).toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Filters
            PanelCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filter Logs',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      hintText: 'Search source or destination',
                      prefixIcon: Icon(Icons.search, color: AppColors.textDim, size: 20),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _attackType,
                        isExpanded: true,
                        dropdownColor: AppColors.surfaceLight,
                        style: const TextStyle(color: AppColors.textPrimary),
                        items: ['All', 'None', 'DDoS', 'Spoofing', 'Intrusion'].map((t) {
                          return DropdownMenuItem(value: t, child: Text(t));
                        }).toList(),
                        onChanged: (v) => setState(() => _attackType = v!),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Logs table
            PanelCard(
              padding: const EdgeInsets.all(0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Historical Logs',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${logs.length} records',
                          style: TextStyle(color: AppColors.textDim, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  if (logs.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child: Text(
                          'No logs match the current filter.',
                          style: TextStyle(color: AppColors.textDim),
                        ),
                      ),
                    )
                  else
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(AppColors.surfaceLight),
                        columns: const [
                          DataColumn(label: Text('Timestamp', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 12))),
                          DataColumn(label: Text('Source', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 12))),
                          DataColumn(label: Text('Destination', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 12))),
                          DataColumn(label: Text('Status', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 12))),
                          DataColumn(label: Text('Severity', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 12))),
                        ],
                        rows: logs.take(100).map((row) {
                          return DataRow(cells: [
                            DataCell(Text(_formatTimestamp(row['timestamp']), style: const TextStyle(fontSize: 11))),
                            DataCell(Text(row['source']?.toString() ?? '', style: const TextStyle(fontSize: 12))),
                            DataCell(Text(row['destination']?.toString() ?? '', style: const TextStyle(fontSize: 12))),
                            DataCell(Text(row['status']?.toString() ?? '', style: const TextStyle(fontSize: 12))),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _severityColor(row['severity']?.toString() ?? '').withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  row['severity']?.toString() ?? '',
                                  style: TextStyle(
                                    color: _severityColor(row['severity']?.toString() ?? ''),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ]);
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatTimestamp(dynamic ts) {
    if (ts == null) return '';
    try {
      final dt = DateTime.parse(ts.toString());
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return ts.toString();
    }
  }

  Color _severityColor(String s) {
    switch (s) {
      case 'Critical':
        return AppColors.severityCritical;
      case 'High':
        return AppColors.severityHigh;
      case 'Medium':
        return AppColors.severityMedium;
      default:
        return AppColors.severityLow;
    }
  }
}
