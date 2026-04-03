import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/app_data_provider.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/panel_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  Color _statusColor(String status) {
    switch (status) {
      case 'Critical':
        return AppColors.statusCritical;
      case 'Warning':
        return AppColors.statusWarning;
      default:
        return AppColors.statusNormal;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppDataProvider>(
      builder: (context, data, _) {
        final stats = data.stats;
        final series = data.trafficSeries;

        if (data.loading && series.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.accent),
          );
        }

        final detectionRate = (stats['totalTraffic'] as int) > 0
            ? ((stats['anomalies'] as int) * 100 / (stats['totalTraffic'] as int)).round()
            : 0;

        return RefreshIndicator(
          color: AppColors.accent,
          backgroundColor: AppColors.surface,
          onRefresh: () => data.refreshData(silent: false),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (data.error.isNotEmpty) _buildErrorBox(data.error),
              // Hero panel
              _buildHeroPanel(stats, detectionRate),
              const SizedBox(height: 16),
              // Metrics row
              _buildMetricsGrid(stats, detectionRate),
              const SizedBox(height: 16),
              // Line chart
              _buildTrafficChart(series),
              const SizedBox(height: 16),
              // Pie chart
              _buildPieChart(stats),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorBox(String error) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.red.withValues(alpha: 0.3)),
      ),
      child: Text(error, style: const TextStyle(color: AppColors.red, fontSize: 13)),
    );
  }

  Widget _buildHeroPanel(Map<String, dynamic> stats, int detectionRate) {
    final status = stats['systemStatus'] as String;
    return PanelCard(
      gradient: AppColors.heroGradient,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'OPERATIONAL OVERVIEW',
            style: TextStyle(
              color: AppColors.accent,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Command Intelligence Dashboard',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Live posture of network traffic, anomaly pressure, and protocol behavior.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildHeroBadge('Detection: $detectionRate%', AppColors.accent),
              _buildHeroBadge('Threat: ${stats['attackPercent']}%', AppColors.orange),
              _buildHeroBadge(status, _statusColor(status)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildMetricsGrid(Map<String, dynamic> stats, int detectionRate) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.6,
      children: [
        StatCard(
          label: 'Total Traffic',
          value: '${stats['totalTraffic']}',
          subtitle: 'packets analyzed',
          icon: Icons.router,
          color: AppColors.accent,
        ),
        StatCard(
          label: 'Anomalies',
          value: '${stats['anomalies']}',
          subtitle: 'threats identified',
          icon: Icons.warning_amber,
          color: AppColors.red,
        ),
        StatCard(
          label: 'Active Nodes',
          value: '${stats['activeNodes']}',
          subtitle: 'unique endpoints',
          icon: Icons.device_hub,
          color: AppColors.green,
        ),
        StatCard(
          label: 'System Status',
          value: stats['systemStatus'] as String,
          subtitle: '${stats['attackPercent']}% threat level',
          icon: Icons.shield,
          color: _statusColor(stats['systemStatus'] as String),
        ),
      ],
    );
  }

  Widget _buildTrafficChart(List<Map<String, dynamic>> series) {
    if (series.isEmpty) {
      return PanelCard(
        child: SizedBox(
          height: 200,
          child: Center(
            child: Text(
              'Waiting for traffic data...',
              style: TextStyle(color: AppColors.textDim),
            ),
          ),
        ),
      );
    }

    return PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Traffic Over Time',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Normal vs Anomaly',
                style: TextStyle(color: AppColors.textDim, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawHorizontalLine: true,
                  drawVerticalLine: false,
                  horizontalInterval: 5,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: AppColors.border.withValues(alpha: 0.3),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (v, meta) => Text(
                        v.toInt().toString(),
                        style: TextStyle(color: AppColors.textDim, fontSize: 10),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      interval: 1,
                      getTitlesWidget: (v, meta) {
                        final idx = v.toInt();
                        if (idx < 0 || idx >= series.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            series[idx]['time'] as String? ?? '',
                            style: TextStyle(color: AppColors.textDim, fontSize: 9),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(series.length, (i) {
                      return FlSpot(i.toDouble(), (series[i]['normal'] as int).toDouble());
                    }),
                    isCurved: true,
                    color: AppColors.green,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.green.withValues(alpha: 0.08),
                    ),
                  ),
                  LineChartBarData(
                    spots: List.generate(series.length, (i) {
                      return FlSpot(i.toDouble(), (series[i]['attack'] as int).toDouble());
                    }),
                    isCurved: true,
                    color: AppColors.red,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.red.withValues(alpha: 0.08),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendDot(AppColors.green, 'Normal'),
              const SizedBox(width: 20),
              _buildLegendDot(AppColors.red, 'Anomaly'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      ],
    );
  }

  Widget _buildPieChart(Map<String, dynamic> stats) {
    final normal = (stats['normalTraffic'] as int?) ?? 0;
    final attack = (stats['attackTraffic'] as int?) ?? 0;

    return PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Traffic Distribution',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Attack Ratio',
                style: TextStyle(color: AppColors.textDim, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 45,
                sections: [
                  PieChartSectionData(
                    value: normal.toDouble(),
                    color: AppColors.green,
                    title: 'Normal\n$normal',
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    radius: 50,
                  ),
                  PieChartSectionData(
                    value: attack.toDouble(),
                    color: AppColors.red,
                    title: 'Attack\n$attack',
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    radius: 50,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildFootnote(AppColors.green, 'Normal: $normal'),
              const SizedBox(width: 24),
              _buildFootnote(AppColors.red, 'Attack: $attack'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFootnote(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      ],
    );
  }
}
