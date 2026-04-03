import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/app_data_provider.dart';
import '../../widgets/panel_card.dart';
import '../../widgets/stat_card.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  String _selectedSeverity = 'All';

  Color _severityColor(String severity) {
    switch (severity) {
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

  @override
  Widget build(BuildContext context) {
    return Consumer<AppDataProvider>(
      builder: (context, data, _) {
        final recentAlerts = data.recentAlerts;
        final filtered = _selectedSeverity == 'All'
            ? recentAlerts
            : recentAlerts.where((a) => a['severity'] == _selectedSeverity).toList();

        final criticalCount = recentAlerts.where((a) => a['severity'] == 'Critical').length;
        final highCount = recentAlerts.where((a) => a['severity'] == 'High').length;
        final mediumCount = recentAlerts.where((a) => a['severity'] == 'Medium').length;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Hero
            PanelCard(
              gradient: AppColors.heroGradient,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'THREAT CONTROL CENTER',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Real-Time Alert Feed',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Focused stream of active security events detected by the monitoring engine.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['All', 'Critical', 'High', 'Medium'].map((level) {
                      final isActive = _selectedSeverity == level;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedSeverity = level),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.accent.withValues(alpha: 0.2)
                                : AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isActive ? AppColors.accent : AppColors.border,
                            ),
                          ),
                          child: Text(
                            level,
                            style: TextStyle(
                              color: isActive ? AppColors.accent : AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Severity summary
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    label: 'Critical',
                    value: '$criticalCount',
                    icon: Icons.error,
                    color: AppColors.severityCritical,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatCard(
                    label: 'High',
                    value: '$highCount',
                    icon: Icons.warning,
                    color: AppColors.severityHigh,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatCard(
                    label: 'Medium',
                    value: '$mediumCount',
                    icon: Icons.info,
                    color: AppColors.severityMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Alert feed
            PanelCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Active Threat Timeline',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${filtered.length} alerts',
                        style: TextStyle(color: AppColors.textDim, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (filtered.isEmpty)
                    _buildEmptyState()
                  else
                    ...filtered.map((alert) => _buildAlertItem(alert)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.green.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle, color: AppColors.green, size: 40),
          ),
          const SizedBox(height: 16),
          const Text(
            'All Systems Normal',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'No anomaly or threat detected for the selected filter.',
            style: TextStyle(color: AppColors.textDim, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAlertItem(Map<String, dynamic> alert) {
    final severity = alert['severity']?.toString() ?? 'Medium';
    final color = _severityColor(severity);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '[$severity] ${alert['message']}',
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                _formatTime(alert['timestamp']),
                style: TextStyle(color: AppColors.textDim, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                'Source: ${alert['source'] ?? 'N/A'}',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
              const SizedBox(width: 16),
              Text(
                'Dest: ${alert['destination'] ?? 'N/A'}',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return '';
    try {
      final dt = DateTime.parse(timestamp.toString());
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
}
