class Roles {
  static const String admin = 'Admin';
  static const String analyst = 'Analyst';
  static const String monitor = 'Monitor';
}

class RoleDescription {
  final String title;
  final String description;
  final List<String> capabilities;

  const RoleDescription({
    required this.title,
    required this.description,
    required this.capabilities,
  });
}

const Map<String, RoleDescription> roleDescriptions = {
  'Admin': RoleDescription(
    title: 'Administrator',
    description: 'Full system access including user management, settings, and all alerts',
    capabilities: [
      'View all users',
      'Create, update, delete users',
      'Access system settings',
      'View all alerts (including archived)',
      'Manage user roles',
      'View system logs',
    ],
  ),
  'Analyst': RoleDescription(
    title: 'Security Analyst',
    description: 'Can analyze traffic, create reports, and manage personal alert filters',
    capabilities: [
      'View dashboard and monitoring',
      'Analyze live traffic data',
      'Create and export reports',
      'Filter and manage alerts',
      'Access network graph',
      'View logs and history',
    ],
  ),
  'Monitor': RoleDescription(
    title: 'Traffic Monitor',
    description: 'Read-only access to live monitoring and alerts (cannot modify data)',
    capabilities: [
      'View live traffic monitoring',
      'View real-time alerts',
      'Access network graph (view-only)',
      'View dashboard statistics',
    ],
  ),
};

const Map<String, List<String>> pageAccessMap = {
  'users': ['Admin'],
  'settings': ['Admin'],
  'dashboard': ['Admin', 'Analyst', 'Monitor'],
  'monitoring': ['Admin', 'Analyst', 'Monitor'],
  'alerts': ['Admin', 'Analyst', 'Monitor'],
  'network': ['Admin', 'Analyst', 'Monitor'],
  'logs': ['Admin', 'Analyst'],
  'simulation': ['Admin'],
  'audit': ['Admin'],
};

bool canAccessPage(String role, String page) {
  return pageAccessMap[page]?.contains(role) ?? false;
}
