import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../services/api_service.dart';
import '../../widgets/panel_card.dart';

class NetworkGraphScreen extends StatefulWidget {
  const NetworkGraphScreen({super.key});

  @override
  State<NetworkGraphScreen> createState() => _NetworkGraphScreenState();
}

class _NetworkGraphScreenState extends State<NetworkGraphScreen> {
  List<dynamic> _traffic = [];
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadTraffic();
  }

  Future<void> _loadTraffic() async {
    try {
      setState(() => _loading = true);
      final data = await ApiService.fetchTraffic();
      setState(() {
        _traffic = data;
        _error = '';
      });
    } catch (e) {
      setState(() => _error = 'Unable to load network traffic');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
              ElevatedButton(
                onPressed: _loadTraffic,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_traffic.isEmpty) {
      return Center(
        child: PanelCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.hub, color: AppColors.textDim, size: 40),
              const SizedBox(height: 12),
              Text(
                'No traffic logs available yet.',
                style: TextStyle(color: AppColors.textDim),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          PanelCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Communication Network Graph',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  onPressed: _loadTraffic,
                  icon: const Icon(Icons.refresh, color: AppColors.accent, size: 20),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: PanelCard(
              padding: const EdgeInsets.all(8),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return _buildNetworkVisualization(
                    constraints.maxWidth,
                    constraints.maxHeight,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkVisualization(double width, double height) {
    final latest = _traffic.take(30).toList();

    final nodeMap = <String, _NodeData>{};
    final edges = <_EdgeData>[];

    final uniqueIps = <String>{};
    for (int i = 0; i < latest.length; i++) {
      final item = latest[i] as Map<String, dynamic>;
      final src = item['source']?.toString() ?? '';
      final dst = item['destination']?.toString() ?? '';
      if (src.isNotEmpty) uniqueIps.add(src);
      if (dst.isNotEmpty) uniqueIps.add(dst);
    }

    final ipsList = uniqueIps.toList();
    if (ipsList.isEmpty) return const SizedBox.shrink();

    final centerX = width / 2;
    final centerY = height / 2;
    final radius = max(10.0, min(width, height) / 2 - 50); 

    for (int i = 0; i < ipsList.length; i++) {
      final ip = ipsList[i];
      final angle = i * 2 * pi / ipsList.length;
      nodeMap[ip] = _NodeData(
        ip: ip,
        x: centerX + radius * cos(angle),
        y: centerY + radius * sin(angle),
        isSource: false,
      );
    }

    for (int i = 0; i < latest.length; i++) {
      final item = latest[i] as Map<String, dynamic>;
      final src = item['source']?.toString() ?? '';
      final dst = item['destination']?.toString() ?? '';
      final status = item['status']?.toString() ?? 'Normal';

      if (src.isNotEmpty && dst.isNotEmpty) {
        if (nodeMap.containsKey(src)) {
          final old = nodeMap[src]!;
          nodeMap[src] = _NodeData(ip: old.ip, x: old.x, y: old.y, isSource: true);
        }
        edges.add(_EdgeData(
          from: src,
          to: dst,
          isAnomaly: status == 'Anomaly',
        ));
      }
    }

    return CustomPaint(
      size: Size(width, height),
      painter: _NetworkPainter(
        nodes: nodeMap,
        edges: edges,
      ),
    );
  }
}

class _NodeData {
  final String ip;
  final double x;
  final double y;
  final bool isSource;

  _NodeData({
    required this.ip,
    required this.x,
    required this.y,
    required this.isSource,
  });
}

class _EdgeData {
  final String from;
  final String to;
  final bool isAnomaly;

  _EdgeData({required this.from, required this.to, required this.isAnomaly});
}

class _NetworkPainter extends CustomPainter {
  final Map<String, _NodeData> nodes;
  final List<_EdgeData> edges;

  _NetworkPainter({required this.nodes, required this.edges});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Draw circular hub guidelines
    final centerPaint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final maxRadius = min(size.width, size.height) / 2;
    canvas.drawCircle(Offset(centerX, centerY), maxRadius * 0.3, centerPaint);
    canvas.drawCircle(Offset(centerX, centerY), maxRadius * 0.6, centerPaint);
    canvas.drawCircle(Offset(centerX, centerY), maxRadius - 50, centerPaint);

    // Draw edges
    for (final edge in edges) {
      final fromNode = nodes[edge.from];
      final toNode = nodes[edge.to];
      if (fromNode == null || toNode == null) continue;

      final paint = Paint()
        ..color = edge.isAnomaly ? AppColors.red.withValues(alpha: 0.7) : AppColors.green.withValues(alpha: 0.3)
        ..strokeWidth = edge.isAnomaly ? 2.5 : 1.0
        ..style = PaintingStyle.stroke;

      // Draw curved line via center
      final path = Path();
      path.moveTo(fromNode.x, fromNode.y);
      path.quadraticBezierTo(centerX, centerY, toNode.x, toNode.y);
      canvas.drawPath(path, paint);
      
      // Draw a small dot moving along the path to simulate traffic (approximate center)
      final midX = (fromNode.x + toNode.x) / 2;
      final midY = (fromNode.y + toNode.y) / 2;
      final qX = (midX + centerX) / 2;
      final qY = (midY + centerY) / 2;
      final dotPaint = Paint()..color = edge.isAnomaly ? AppColors.red : AppColors.green;
      canvas.drawCircle(Offset(qX, qY), edge.isAnomaly ? 3 : 2, dotPaint);
    }

    // Draw nodes
    for (final node in nodes.values) {
      final isAnomalyTarget = edges.any((e) => e.to == node.ip && e.isAnomaly);
      final isAnomalySource = edges.any((e) => e.from == node.ip && e.isAnomaly);
      final hasAnomaly = isAnomalyTarget || isAnomalySource;
      
      if (hasAnomaly) {
        canvas.drawCircle(
          Offset(node.x, node.y), 
          20, 
          Paint()..color = AppColors.red.withValues(alpha: 0.2)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
        );
      }

      // Background
      final bgPaint = Paint()
        ..color = node.isSource
            ? const Color(0xFF1E293B)  // Using surfaceLight equivalent
            : const Color(0xFF111827); // Using surface equivalent
      canvas.drawCircle(Offset(node.x, node.y), 12, bgPaint);

      // Inner icon 
      canvas.drawCircle(Offset(node.x, node.y), 3, Paint()..color = AppColors.textPrimary.withValues(alpha: 0.5));

      // Border
      final borderPaint = Paint()
        ..color = node.isSource ? AppColors.green : (hasAnomaly ? AppColors.red : AppColors.orange)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(Offset(node.x, node.y), 12, borderPaint);

      // Outer ring for sources
      if (node.isSource) {
         canvas.drawCircle(Offset(node.x, node.y), 16, borderPaint..strokeWidth = 0.5..color = AppColors.accent.withValues(alpha: 0.5));
      }

      // Label Positioning
      final angleFromCenter = atan2(node.y - centerY, node.x - centerX);
      final labelDist = 24.0; 
      final labelX = node.x + cos(angleFromCenter) * labelDist;
      final labelY = node.y + sin(angleFromCenter) * labelDist;

      final textSpan = TextSpan(
        text: node.ip.length > 15 ? node.ip.substring(node.ip.length - 8) : node.ip,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      textPainter.layout();
      
      // Determine if text should be drawn left or right of the labelX
      final isLeftMost = cos(angleFromCenter) < 0;
      final finalX = isLeftMost ? labelX - textPainter.width : labelX;
      final finalY = labelY - textPainter.height / 2;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(finalX - 4, finalY - 2, textPainter.width + 8, textPainter.height + 4),
        const Radius.circular(4),
      );
      canvas.drawRRect(rect, Paint()..color = AppColors.surface.withValues(alpha: 0.9));
      canvas.drawRRect(rect, Paint()..color = AppColors.border..style = PaintingStyle.stroke..strokeWidth = 1);

      textPainter.paint(canvas, Offset(finalX, finalY));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
