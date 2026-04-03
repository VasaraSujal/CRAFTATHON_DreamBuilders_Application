import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/app_data_provider.dart';
import '../../widgets/panel_card.dart';

class MonitoringScreen extends StatelessWidget {
  const MonitoringScreen({super.key});

  Color _rowColor(String status) {
    if (status == 'Anomaly') return AppColors.red;
    return AppColors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppDataProvider>(
      builder: (context, data, _) {
        final traffic = data.liveTraffic;
        final graphData = traffic.take(12).toList().reversed.toList();

        return RefreshIndicator(
          color: AppColors.accent,
          backgroundColor: AppColors.surface,
          onRefresh: () => data.refreshData(silent: false),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (data.error.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.red.withValues(alpha: 0.3)),
                  ),
                  child: Text(data.error, style: const TextStyle(color: AppColors.red, fontSize: 13)),
                ),

              // Tracking control
              PanelCard(
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Live Monitoring',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: data.isTrackingLive ? AppColors.green : AppColors.red,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              data.isTrackingLive ? 'ACTIVE' : 'PAUSED',
                              style: TextStyle(
                                color: AppColors.textDim,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () => data.toggleTracking(),
                      icon: Icon(
                        data.isTrackingLive ? Icons.stop : Icons.play_arrow,
                        size: 16,
                      ),
                      label: Text(
                        data.isTrackingLive ? 'STOP' : 'START',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: data.isTrackingLive ? AppColors.red : AppColors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Packet size chart
              PanelCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Live Packet Size Stream',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Auto-refresh enabled',
                      style: TextStyle(color: AppColors.textDim, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: graphData.isEmpty
                          ? Center(
                              child: Text(
                                'Waiting for data...',
                                style: TextStyle(color: AppColors.textDim),
                              ),
                            )
                          : LineChart(
                              LineChartData(
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  horizontalInterval: 200,
                                  getDrawingHorizontalLine: (v) => FlLine(
                                    color: AppColors.border.withValues(alpha: 0.3),
                                    strokeWidth: 1,
                                  ),
                                ),
                                titlesData: FlTitlesData(
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 40,
                                      getTitlesWidget: (v, _) => Text(
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
                                      getTitlesWidget: (v, _) {
                                        final idx = v.toInt();
                                        if (idx < 0 || idx >= graphData.length) return const SizedBox.shrink();
                                        return Text(
                                          graphData[idx]['time']?.toString() ?? '',
                                          style: TextStyle(color: AppColors.textDim, fontSize: 8),
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
                                    spots: List.generate(graphData.length, (i) {
                                      final ps = graphData[i]['packetSize'];
                                      return FlSpot(i.toDouble(), (ps is int ? ps : 0).toDouble());
                                    }),
                                    isCurved: true,
                                    color: AppColors.accent,
                                    barWidth: 2.5,
                                    dotData: const FlDotData(show: false),
                                    belowBarData: BarAreaData(
                                      show: true,
                                      color: AppColors.accent.withValues(alpha: 0.1),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Traffic table
              PanelCard(
                padding: const EdgeInsets.all(0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                      child: Text(
                        'Live Traffic Table',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (data.loading && traffic.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Center(
                          child: Text(
                            'Loading real-time data...',
                            style: TextStyle(color: AppColors.textDim),
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: traffic.length > 50 ? 50 : traffic.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = traffic[index];
                          final status = item['status']?.toString() ?? 'Normal';
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${item['protocol']} • ${_formatTime(item['timestamp'])}',
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: _rowColor(status).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        status,
                                        style: TextStyle(
                                          color: _rowColor(status),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
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
                                          Text(item['source']?.toString() ?? '', style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
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
                                          Text(item['destination']?.toString() ?? '', style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        const Text('Size', style: TextStyle(color: AppColors.textDim, fontSize: 10)),
                                        Text('${item['packetSize']} B', style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
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
          ),
        );
      },
    );
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return '';
    try {
      final dt = DateTime.parse(timestamp.toString());
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
    } catch (_) {
      return timestamp.toString();
    }
  }
}
