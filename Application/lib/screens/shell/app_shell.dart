import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/app_data_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/role_permissions.dart';
import '../dashboard/dashboard_screen.dart';
import '../monitoring/monitoring_screen.dart';
import '../alerts/alerts_screen.dart';
import '../network/network_graph_screen.dart';
import '../logs/logs_screen.dart';
import '../simulation/simulation_screen.dart';
import '../users/users_screen.dart';
import '../settings/settings_screen.dart';
import '../audit/audit_screen.dart';

class NavItem {
  final String label;
  final IconData icon;
  final String page;
  final Widget screen;

  const NavItem({
    required this.label,
    required this.icon,
    required this.page,
    required this.screen,
  });
}

const allNavItems = [
  NavItem(label: 'Dashboard', icon: Icons.dashboard, page: 'dashboard', screen: DashboardScreen()),
  NavItem(label: 'Monitoring', icon: Icons.sensors, page: 'monitoring', screen: MonitoringScreen()),
  NavItem(label: 'Alerts', icon: Icons.notification_important, page: 'alerts', screen: AlertsScreen()),
  NavItem(label: 'Network', icon: Icons.hub, page: 'network', screen: NetworkGraphScreen()),
  NavItem(label: 'Logs', icon: Icons.article, page: 'logs', screen: LogsScreen()),
  NavItem(label: 'Simulation', icon: Icons.bolt, page: 'simulation', screen: SimulationScreen()),
  NavItem(label: 'Users', icon: Icons.people, page: 'users', screen: UsersScreen()),
  NavItem(label: 'Settings', icon: Icons.settings, page: 'settings', screen: SettingsScreen()),
  NavItem(label: 'Audit', icon: Icons.fact_check, page: 'audit', screen: AuditScreen()),
];

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // Start auto-refresh when app shell is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dataProvider = context.read<AppDataProvider>();
      dataProvider.refreshData(silent: false);
      dataProvider.startAutoRefresh();
    });
  }



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
    final auth = context.watch<AuthProvider>();
    final data = context.watch<AppDataProvider>();
    final role = auth.role;
    final stats = data.stats;

    // Filter nav items based on user role
    final navItems = allNavItems.where((item) => canAccessPage(role, item.page)).toList();

    // Ensure selected index is valid
    if (_selectedIndex >= navItems.length) {
      _selectedIndex = 0;
    }

    // Bottom nav only shows first 4 items
    final bottomNavItems = navItems.take(4).toList();
    final currentScreen = navItems[_selectedIndex].screen;
    final currentTitle = navItems[_selectedIndex].label;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          icon: const Icon(Icons.menu, color: AppColors.textPrimary),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SECURE OPERATIONS',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            Text(
              currentTitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: [
          // System status chip
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _statusColor(stats['systemStatus'] as String).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _statusColor(stats['systemStatus'] as String).withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              stats['systemStatus'] as String,
              style: TextStyle(
                color: _statusColor(stats['systemStatus'] as String),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          // Logout button
          IconButton(
            onPressed: () {
              data.stopAutoRefresh();
              auth.logout();
            },
            icon: const Icon(Icons.logout, color: AppColors.red, size: 20),
          ),
        ],
      ),
      drawer: _buildDrawer(navItems, auth),
      body: Stack(
        children: [
          currentScreen,
          // Notification stack
          _buildNotificationStack(data),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex < bottomNavItems.length ? _selectedIndex : 0,
          onTap: (i) => setState(() => _selectedIndex = i),
          items: bottomNavItems.map((item) {
            return BottomNavigationBarItem(
              icon: Icon(item.icon),
              label: item.label,
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildDrawer(List<NavItem> navItems, AuthProvider auth) {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          children: [
            // Drawer header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: AppColors.heroGradient,
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SECURE MILITARY',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Comm Monitoring',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person, color: AppColors.accent, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                auth.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.only(top: 2),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  auth.role,
                                  style: const TextStyle(
                                    color: AppColors.accent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Nav items
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: navItems.length,
                itemBuilder: (context, index) {
                  final item = navItems[index];
                  final isActive = index == _selectedIndex;

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    child: Material(
                      color: isActive
                          ? AppColors.accent.withValues(alpha: 0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          setState(() => _selectedIndex = index);
                          Navigator.pop(context);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                item.icon,
                                size: 20,
                                color: isActive
                                    ? AppColors.accent
                                    : AppColors.textDim,
                              ),
                              const SizedBox(width: 14),
                              Text(
                                item.label,
                                style: TextStyle(
                                  color: isActive
                                      ? AppColors.accent
                                      : AppColors.textSecondary,
                                  fontWeight: isActive
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                              if (isActive) ...[
                                const Spacer(),
                                Container(
                                  width: 4,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: AppColors.accent,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Logout
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    context.read<AppDataProvider>().stopAutoRefresh();
                    auth.logout();
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.logout, color: AppColors.red, size: 18),
                  label: const Text('Logout', style: TextStyle(color: AppColors.red)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.red.withValues(alpha: 0.3)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationStack(AppDataProvider data) {
    if (data.notifications.isEmpty) return const SizedBox.shrink();

    return Positioned(
      top: 8,
      right: 8,
      left: 8,
      child: Column(
        children: data.notifications.map((item) {
          final severity = item['severity']?.toString() ?? 'Medium';
          Color color;
          switch (severity) {
            case 'High':
            case 'Critical':
              color = AppColors.red;
              break;
            case 'Medium':
              color = AppColors.orange;
              break;
            default:
              color = AppColors.green;
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.5)),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber, color: color, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$severity Alert',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        item['message']?.toString() ?? '',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
