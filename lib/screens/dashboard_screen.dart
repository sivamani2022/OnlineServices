import 'package:flutter/material.dart';
import '../models/department.dart';
import '../services/api_service.dart';
import 'services_screen.dart';
import 'login_screen.dart';
import 'admin_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<List<Department>> _future;
  List<Department> _all = [];
  List<Department> _filtered = [];
  Map<String, String>? _session; // {deptId, deptName}

  @override
  void initState() {
    super.initState();
    _load();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final s = await SessionStore.load();
    if (mounted) setState(() => _session = s);
  }

  void _load() {
    _future = ApiService.getDepartments().then((depts) {
      _all = depts;
      _filtered = depts;
      return depts;
    });
  }

  void _refresh() {
    setState(_load);
  }

  void _filter(String q) {
    setState(() {
      _filtered = _all
          .where((d) => d.name.toLowerCase().contains(q.toLowerCase()))
          .toList();
    });
  }

  Future<void> _onLoginTap() async {
    if (_session != null) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AdminScreen(
            deptId: _session!['deptId']!,
            deptName: _session!['deptName']!,
          ),
        ),
      );
      _restoreSession();
      _refresh();
      return;
    }
    final result = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
    if (result != null) {
      setState(() => _session = result);
      _onLoginTap();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('e-Services Directory'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: TextButton(
                onPressed: _onLoginTap,
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.15),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(_session == null
                    ? 'Dept Login'
                    : '${_session!['deptName']!.split(' ').first} ▾'),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: FutureBuilder<List<Department>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return ListView(
                children: [
                  const SizedBox(height: 80),
                  Center(
                    child: Text(
                      'Could not load departments.\n${snap.error}',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                ],
              );
            }
            if (_all.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 80),
                  Center(child: Text('No departments have been added yet.')),
                ],
              );
            }
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
                  child: TextField(
                    onChanged: _filter,
                    decoration: InputDecoration(
                      hintText: 'Search departments…',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(14, 6, 14, 20),
                    itemCount: _filtered.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.05,
                    ),
                    itemBuilder: (context, i) {
                      final d = _filtered[i];
                      return _DeptCard(
                        department: d,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ServicesScreen(
                              deptId: d.id,
                              deptName: d.name,
                              deptIcon: d.icon,
                              isOwner: _session?['deptId'] == d.id,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DeptCard extends StatelessWidget {
  final Department department;
  final VoidCallback onTap;
  const _DeptCard({required this.department, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(department.icon, style: const TextStyle(fontSize: 32)),
              const SizedBox(height: 8),
              Text(
                department.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
              ),
              const SizedBox(height: 4),
              Text(
                '${department.serviceCount} service${department.serviceCount == 1 ? '' : 's'}',
                style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
