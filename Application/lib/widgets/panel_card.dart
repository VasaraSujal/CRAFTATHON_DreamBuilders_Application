import 'package:flutter/material.dart';
import '../core/theme.dart';

class PanelCard extends StatelessWidget {
  final Widget child;
  final Gradient? gradient;
  final EdgeInsets? padding;

  const PanelCard({
    super.key,
    required this.child,
    this.gradient,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: gradient == null ? AppColors.surface : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}
