import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
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

  // PDF generation states
  final _recipientNameCtrl = TextEditingController();
  final _recipientEmailCtrl = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    _recipientNameCtrl.dispose();
    _recipientEmailCtrl.dispose();
    super.dispose();
  }

  void _showShareDialog(BuildContext context, List<dynamic> logs) {
    DateTime? startDate;
    DateTime? endDate;
    String status = '';

    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pickDate(bool isStart) async {
              final initial = isStart ? (startDate ?? DateTime.now()) : (endDate ?? DateTime.now());
              final pickedStr = await showDatePicker(
                context: context,
                initialDate: initial,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
                builder: (context, child) => Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.dark(
                      primary: AppColors.accent,
                      surface: AppColors.surface,
                    ),
                  ),
                  child: child!,
                ),
              );
              if (pickedStr != null) {
                final pickedTime = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(initial),
                );
                if (pickedTime != null) {
                  setDialogState(() {
                    final dt = DateTime(pickedStr.year, pickedStr.month, pickedStr.day, pickedTime.hour, pickedTime.minute);
                    if (isStart) {
                      startDate = dt;
                    } else {
                      endDate = dt;
                    }
                  });
                }
              }
            }

            Future<void> generate(bool share) async {
              List<dynamic> targetLogs = logs;
              if (startDate != null) {
                targetLogs = targetLogs.where((l) {
                  final d = DateTime.tryParse(l['timestamp'].toString());
                  if (d == null) return false;
                  return (d.isAfter(startDate!) || d.isAtSameMomentAs(startDate!));
                }).toList();
              }
              if (endDate != null) {
                targetLogs = targetLogs.where((l) {
                  final d = DateTime.tryParse(l['timestamp'].toString());
                  if (d == null) return false;
                  return (d.isBefore(endDate!) || d.isAtSameMomentAs(endDate!));
                }).toList();
              }

              if (targetLogs.isEmpty) {
                setDialogState(() => status = 'No logs available for export in range.');
                return;
              }

              setDialogState(() => status = 'Generating PDF...');

              // Calculate Top 5 Communicators
              final Map<String, int> ipCounts = {};
              for (var log in targetLogs) {
                final src = log['source']?.toString();
                final dst = log['destination']?.toString();
                if (src != null && src.isNotEmpty) ipCounts[src] = (ipCounts[src] ?? 0) + 1;
                if (dst != null && dst.isNotEmpty) ipCounts[dst] = (ipCounts[dst] ?? 0) + 1;
              }
              final sortedIps = ipCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
              final top5 = sortedIps.take(5).toList();

              final pdfLogs = targetLogs.take(50).toList();
              final pdf = pw.Document();

              pdf.addPage(
                pw.MultiPage(
                  pageFormat: PdfPageFormat.a4,
                  build: (pw.Context context) {
                    return [
                      pw.Header(level: 0, child: pw.Text('Historical Logs Report')),
                      if (_recipientNameCtrl.text.isNotEmpty || _recipientEmailCtrl.text.isNotEmpty)
                        pw.Paragraph(
                          text: 'Generated for ${_recipientNameCtrl.text} (${_recipientEmailCtrl.text})',
                        ),
                      pw.SizedBox(height: 10),
                      if (top5.isNotEmpty) ...[
                        pw.Text('Top 5 Communicating IPs:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                        pw.SizedBox(height: 5),
                        pw.TableHelper.fromTextArray(
                          context: context,
                          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
                          data: <List<String>>[
                            <String>['Rank', 'IP Address', 'Total Connections'],
                            ...top5.asMap().entries.map((e) => [
                                  '#${e.key + 1}',
                                  e.value.key,
                                  '${e.value.value}',
                                ])
                          ],
                        ),
                        pw.SizedBox(height: 20),
                      ],
                      pw.Text('Log Extract (Latest ${pdfLogs.length})', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                      pw.SizedBox(height: 5),
                      pw.TableHelper.fromTextArray(
                        context: context,
                        headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
                        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        data: <List<String>>[
                          <String>['Timestamp', 'Source', 'Destination', 'Type', 'Severity'],
                          ...pdfLogs.map((l) => [
                                _formatTimestamp(l['timestamp']),
                                l['source']?.toString() ?? '',
                                l['destination']?.toString() ?? '',
                                l['attackType']?.toString() ?? '',
                                l['severity']?.toString() ?? '-',
                              ])
                        ],
                      ),
                    ];
                  },
                ),
              );

              final bytes = await pdf.save();
              if (mounted) {
                setDialogState(() => status = 'PDF created successfully.');
              }

              if (share) {
                await Printing.sharePdf(bytes: bytes, filename: 'logs_report.pdf');
              } else {
                await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => bytes);
              }
            }

            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Generate a PDF report', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('By default exports the latest logs and includes a ranked top 5 communicator list. Choose a start and end date to filter.', style: TextStyle(color: AppColors.textDim, fontSize: 12)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _recipientNameCtrl,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'Recipient name (Optional)',
                        labelStyle: const TextStyle(color: AppColors.textDim),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _recipientEmailCtrl,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'Recipient email (Optional)',
                        labelStyle: const TextStyle(color: AppColors.textDim),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => pickDate(true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                              decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(8)),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(startDate == null ? 'Start date & time' : _formatTimestamp(startDate!.toIso8601String()), style: TextStyle(color: startDate == null ? AppColors.textDim : Colors.white, fontSize: 12), overflow: TextOverflow.ellipsis),
                                  ),
                                  const Icon(Icons.calendar_today, size: 14, color: AppColors.textDim),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            onTap: () => pickDate(false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                              decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(8)),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(endDate == null ? 'End date & time' : _formatTimestamp(endDate!.toIso8601String()), style: TextStyle(color: endDate == null ? AppColors.textDim : Colors.white, fontSize: 12), overflow: TextOverflow.ellipsis),
                                  ),
                                  const Icon(Icons.calendar_today, size: 14, color: AppColors.textDim),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (status.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(status, style: TextStyle(color: status.contains('No logs') ? AppColors.red : AppColors.green, fontSize: 12)),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textDim)),
                ),
                ElevatedButton(
                  onPressed: () => generate(false),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.green, foregroundColor: Colors.white, elevation: 0),
                  child: const Text('Download'),
                ),
                ElevatedButton(
                  onPressed: () => generate(true),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.red, foregroundColor: Colors.white, elevation: 0),
                  child: const Text('Share'),
                ),
              ],
            );
          },
        );
      },
    );
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                                style: const TextStyle(color: AppColors.textDim, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _showShareDialog(context, logs),
                          icon: const Icon(Icons.share, size: 14),
                          label: const Text('Share Logs', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent.withValues(alpha: 0.2),
                            foregroundColor: AppColors.accent,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            minimumSize: const Size(0, 32),
                          ),
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
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: logs.length > 100 ? 100 : logs.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final row = logs[index];
                        final status = row['status']?.toString() ?? '';
                        final severity = row['severity']?.toString() ?? '';
                        
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatTimestamp(row['timestamp']),
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      if (status.isNotEmpty)
                                        Container(
                                          margin: const EdgeInsets.only(right: 6),
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: AppColors.surfaceLight,
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: AppColors.border),
                                          ),
                                          child: Text(
                                            status,
                                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      if (severity.isNotEmpty && severity != 'null')
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: _severityColor(severity).withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            severity,
                                            style: TextStyle(
                                              color: _severityColor(severity),
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Source', style: TextStyle(color: AppColors.textDim, fontSize: 10)),
                                        Text(row['source']?.toString() ?? '', style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
                                      ],
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 8),
                                    child: Icon(Icons.arrow_forward_outlined, color: AppColors.borderLight, size: 16),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Destination', style: TextStyle(color: AppColors.textDim, fontSize: 10)),
                                        Text(row['destination']?.toString() ?? '', style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text('Attack Type', style: TextStyle(color: AppColors.textDim, fontSize: 10)),
                                      Text(row['attackType']?.toString() ?? '-', style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
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
