import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/panel_card.dart';
import '../../widgets/stat_card.dart';

class AuditScreen extends StatefulWidget {
  const AuditScreen({super.key});

  @override
  State<AuditScreen> createState() => _AuditScreenState();
}

class _AuditScreenState extends State<AuditScreen> {
  Map<String, dynamic>? _audit;
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetchAudit();
  }

  Future<void> _fetchAudit() async {
    try {
      setState(() => _loading = true);
      final data = await ApiService.fetchAuditSummary();
      setState(() {
        _audit = data;
        _error = '';
      });
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.role != 'Admin') {
      return Center(
        child: PanelCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.lock, color: AppColors.red, size: 40),
              SizedBox(height: 12),
              Text('Access Denied', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
              SizedBox(height: 6),
              Text('Only Admins can access Audit logs.', style: TextStyle(color: AppColors.textDim)),
            ],
          ),
        ),
      );
    }

    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accent));
    }

    if (_error.isNotEmpty) {
      return Center(
        child: PanelCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.red, size: 40),
              const SizedBox(height: 12),
              Text(_error, style: const TextStyle(color: AppColors.red)),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _fetchAudit, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    if (_audit == null) return const SizedBox.shrink();
    final audit = _audit!;

    return RefreshIndicator(
      color: AppColors.accent,
      backgroundColor: AppColors.surface,
      onRefresh: _fetchAudit,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          PanelCard(
            gradient: AppColors.heroGradient,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AUDIT SUMMARY',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'System Audit Report',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                ),
                if (audit['generatedAt'] != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Generated: ${_formatDate(audit['generatedAt'])}',
                    style: TextStyle(color: AppColors.textDim, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Stats
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'Total Logs',
                  value: '${audit['totalLogs'] ?? 0}',
                  icon: Icons.article,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatCard(
                  label: 'Total Alerts',
                  value: '${audit['totalAlerts'] ?? 0}',
                  icon: Icons.warning,
                  color: AppColors.orange,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatCard(
                  label: 'Unresolved',
                  value: '${audit['unresolvedAlerts'] ?? 0}',
                  icon: Icons.error,
                  color: AppColors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Attacks by type
          _buildTable(
            title: 'Attacks by Type',
            icon: Icons.bolt,
            headers: ['Attack Type', 'Count'],
            data: (audit['attacksByType'] as List?)?.map((item) {
                  return [item['_id']?.toString() ?? '', '${item['count'] ?? 0}'];
                }).toList() ??
                [],
          ),
          const SizedBox(height: 12),

          // Traffic by protocol
          _buildTable(
            title: 'Traffic by Protocol',
            icon: Icons.router,
            headers: ['Protocol', 'Count'],
            data: (audit['trafficByProtocol'] as List?)?.map((item) {
                  return [item['_id']?.toString() ?? '', '${item['count'] ?? 0}'];
                }).toList() ??
                [],
          ),
          const SizedBox(height: 12),

          // Top talkers
          _buildTable(
            title: 'Top Talkers (Source IPs)',
            icon: Icons.trending_up,
            headers: ['Source IP', 'Packets'],
            data: (audit['topTalkers'] as List?)?.map((item) {
                  return [item['_id']?.toString() ?? '', '${item['count'] ?? 0}'];
                }).toList() ??
                [],
          ),
        ],
      ),
    );
  }

  Widget _buildTable({
    required String title,
    required IconData icon,
    required List<String> headers,
    required List<List<String>> data,
  }) {
    return PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.accent, size: 18),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          if (data.isEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text('No data', style: TextStyle(color: AppColors.textDim, fontSize: 13)),
            )
          else
            ...data.map((row) {
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.3))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(row[0], style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        row[1],
                        style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  String _formatDate(dynamic ts) {
    if (ts == null) return '';
    try {
      final dt = DateTime.parse(ts.toString());
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return ts.toString();
    }
  }
}
