import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/app_data_provider.dart';
import '../../widgets/panel_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _saved = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppDataProvider>(
      builder: (context, data, _) {
        final settings = data.settings;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            PanelCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'System Settings',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Configure dashboard behavior and display preferences.',
                    style: TextStyle(color: AppColors.textDim, fontSize: 13),
                  ),
                  if (_saved)
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.green.withValues(alpha: 0.3)),
                      ),
                      child: const Text(
                        'Settings saved successfully!',
                        style: TextStyle(color: AppColors.green, fontSize: 13),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Dashboard settings
            _buildSettingPanel(
              icon: Icons.dashboard,
              title: 'Dashboard',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Refresh interval (seconds)',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: ((settings['refreshInterval'] as int?) ?? 5).toDouble(),
                          min: 1,
                          max: 60,
                          divisions: 59,
                          activeColor: AppColors.accent,
                          inactiveColor: AppColors.border,
                          label: '${settings['refreshInterval']}s',
                          onChanged: (v) {
                            data.updateSettings({
                              ...settings,
                              'refreshInterval': v.round(),
                            });
                            setState(() => _saved = false);
                          },
                        ),
                      ),
                      SizedBox(
                        width: 50,
                        child: Text(
                          '${settings['refreshInterval']}s',
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Alert settings
            _buildSettingPanel(
              icon: Icons.notifications_active,
              title: 'Alerts',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Alert threshold (%)',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: ((settings['alertThreshold'] as int?) ?? 50).toDouble(),
                          min: 0,
                          max: 100,
                          divisions: 100,
                          activeColor: AppColors.orange,
                          inactiveColor: AppColors.border,
                          label: '${settings['alertThreshold']}%',
                          onChanged: (v) {
                            data.updateSettings({
                              ...settings,
                              'alertThreshold': v.round(),
                            });
                            setState(() => _saved = false);
                          },
                        ),
                      ),
                      SizedBox(
                        width: 50,
                        child: Text(
                          '${settings['alertThreshold']}%',
                          style: const TextStyle(
                            color: AppColors.orange,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Theme settings
            _buildSettingPanel(
              icon: Icons.palette,
              title: 'Display',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Theme',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: (settings['theme'] as String?) ?? 'dark',
                        isExpanded: true,
                        dropdownColor: AppColors.surfaceLight,
                        style: const TextStyle(color: AppColors.textPrimary),
                        items: const [
                          DropdownMenuItem(value: 'dark', child: Text('Dark (Military)')),
                          DropdownMenuItem(value: 'light', child: Text('Light')),
                          DropdownMenuItem(value: 'blue', child: Text('Blue')),
                        ],
                        onChanged: (v) {
                          data.updateSettings({
                            ...settings,
                            'theme': v,
                          });
                          setState(() => _saved = false);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  data.updateSettings({...settings});
                  setState(() => _saved = true);
                  Future.delayed(const Duration(seconds: 3), () {
                    if (mounted) setState(() => _saved = false);
                  });
                },
                child: const Text(
                  'Save Settings',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSettingPanel({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.accent, size: 20),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
