import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../utils/role_permissions.dart';
import '../../widgets/panel_card.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List<Map<String, dynamic>> _users = [];
  bool _loading = false;
  bool _saving = false;
  bool _showForm = false;
  String _error = '';
  String _success = '';

  final _nameCtl = TextEditingController();
  final _emailCtl = TextEditingController();
  final _passwordCtl = TextEditingController();
  String _formRole = 'Monitor';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _emailCtl.dispose();
    _passwordCtl.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final rows = await ApiService.fetchUsers();
      setState(() {
        _users = rows.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      });
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _handleAddUser() async {
    setState(() {
      _saving = true;
      _error = '';
      _success = '';
    });
    try {
      await ApiService.createUserByAdmin({
        'name': _nameCtl.text.trim(),
        'email': _emailCtl.text.trim(),
        'password': _passwordCtl.text,
        'role': _formRole,
      });
      _nameCtl.clear();
      _emailCtl.clear();
      _passwordCtl.clear();
      setState(() {
        _showForm = false;
        _success = 'User created successfully';
      });
      await _loadUsers();
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _saving = false);
    }
  }

  Future<void> _handleDeleteUser(String userId) async {
    setState(() {
      _error = '';
      _success = '';
    });
    try {
      await ApiService.deleteUser(userId);
      setState(() => _success = 'User deleted successfully');
      await _loadUsers();
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _handleRoleUpdate(String userId, String role) async {
    setState(() {
      _error = '';
      _success = '';
    });
    try {
      await ApiService.updateUserRole(userId, role);
      setState(() => _success = 'Role updated successfully');
      await _loadUsers();
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
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
              Text('Only Admins can access User Management.', style: TextStyle(color: AppColors.textDim)),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Role access matrix
        PanelCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Role Access Matrix',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              ...roleDescriptions.entries.map((entry) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.key,
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entry.value.title,
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entry.value.description,
                        style: TextStyle(color: AppColors.textDim, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      ...entry.value.capabilities.map((c) => Padding(
                            padding: const EdgeInsets.only(bottom: 3),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle, color: AppColors.green, size: 14),
                                const SizedBox(width: 6),
                                Text(c, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                              ],
                            ),
                          )),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // User management
        PanelCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'User Management',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: _loading ? null : _loadUsers,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        child: const Text('Refresh', style: TextStyle(fontSize: 12)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => setState(() => _showForm = !_showForm),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        child: Text(_showForm ? 'Cancel' : '+ Add', style: const TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
              if (_error.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.red.withValues(alpha: 0.3)),
                  ),
                  child: Text(_error, style: const TextStyle(color: AppColors.red, fontSize: 12)),
                ),
              if (_success.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.green.withValues(alpha: 0.3)),
                  ),
                  child: Text(_success, style: const TextStyle(color: AppColors.green, fontSize: 12)),
                ),
              if (_showForm) ...[
                const SizedBox(height: 16),
                _buildAddUserForm(),
              ],
              const SizedBox(height: 16),
              _buildUserList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddUserForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          TextField(
            controller: _nameCtl,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'Officer Name',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _emailCtl,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'user@defence.gov',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordCtl,
            obscureText: true,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              labelText: 'Password',
              hintText: 'Minimum 6 characters',
            ),
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
                value: _formRole,
                isExpanded: true,
                dropdownColor: AppColors.surfaceLight,
                style: const TextStyle(color: AppColors.textPrimary),
                items: ['Admin', 'Analyst', 'Monitor'].map((r) {
                  return DropdownMenuItem(value: r, child: Text(r));
                }).toList(),
                onChanged: (v) => setState(() => _formRole = v!),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _handleAddUser,
              child: Text(_saving ? 'Creating...' : 'Create User'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList() {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
      );
    }

    if (_users.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Text('No users found.', style: TextStyle(color: AppColors.textDim)),
        ),
      );
    }

    return Column(
      children: _users.map((u) {
        final userId = u['_id']?.toString() ?? u['id']?.toString() ?? '';
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      u['name']?.toString() ?? '',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      u['email']?.toString() ?? '',
                      style: TextStyle(color: AppColors.textDim, fontSize: 12),
                    ),
                  ],
                ),
              ),
              // Role dropdown
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: u['role']?.toString() ?? 'Monitor',
                    dropdownColor: AppColors.surface,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
                    items: ['Admin', 'Analyst', 'Monitor'].map((r) {
                      return DropdownMenuItem(value: r, child: Text(r));
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) _handleRoleUpdate(userId, v);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _showDeleteDialog(userId, u['name']?.toString() ?? ''),
                icon: const Icon(Icons.delete_outline, color: AppColors.red, size: 20),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _showDeleteDialog(String userId, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete User', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to delete $name?', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _handleDeleteUser(userId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
