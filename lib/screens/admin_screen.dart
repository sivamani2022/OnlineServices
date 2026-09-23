import 'package:flutter/material.dart';
import '../models/service_item.dart';
import '../services/api_service.dart';

class AdminScreen extends StatefulWidget {
  final String deptId;
  final String deptName;
  const AdminScreen({super.key, required this.deptId, required this.deptName});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  late Future<List<ServiceItem>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = ApiService.getServices(widget.deptId);
  }

  void _refresh() => setState(_load);

  Future<void> _logout() async {
    await SessionStore.clear();
    if (mounted) Navigator.pop(context);
  }

  Future<void> _openForm({ServiceItem? existing}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => _ServiceFormSheet(deptId: widget.deptId, existing: existing),
    );
    if (saved == true) _refresh();
  }

  Future<void> _delete(ServiceItem s) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete service?'),
        content: Text('Remove "${s.name}" from your department\'s listings?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    final res = await ApiService.deleteService(widget.deptId, s.id);
    if (!mounted) return;
    if (res.success) {
      _refresh();
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(res.message ?? 'Could not delete.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.deptName),
        actions: [
          TextButton(
            onPressed: _logout,
            child: const Text('Log out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<ServiceItem>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final services = snap.data ?? [];
          if (services.isEmpty) {
            return const Center(
                child: Text('No services listed yet. Tap + to add one.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(14),
            itemCount: services.length,
            itemBuilder: (context, i) {
              final s = services[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15)),
                      if (s.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(s.description,
                            style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () => _openForm(existing: s),
                            child: const Text('Edit'),
                          ),
                          TextButton(
                            onPressed: () => _delete(s),
                            child: const Text('Delete',
                                style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ServiceFormSheet extends StatefulWidget {
  final String deptId;
  final ServiceItem? existing;
  const _ServiceFormSheet({required this.deptId, this.existing});

  @override
  State<_ServiceFormSheet> createState() => _ServiceFormSheetState();
}

class _ServiceFormSheetState extends State<_ServiceFormSheet> {
  late final TextEditingController _name;
  late final TextEditingController _desc;
  late final TextEditingController _url;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? '');
    _desc = TextEditingController(text: widget.existing?.description ?? '');
    _url = TextEditingController(text: widget.existing?.url ?? '');
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final url = _url.text.trim();
    if (name.isEmpty || url.isEmpty) {
      setState(() => _error = 'Service name and URL are required.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final res = widget.existing == null
        ? await ApiService.addService(widget.deptId, name, _desc.text.trim(), url)
        : await ApiService.updateService(
            widget.deptId, widget.existing!.id, name, _desc.text.trim(), url);
    if (!mounted) return;
    if (res.success) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _saving = false;
        _error = res.message ?? 'Something went wrong.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.existing == null ? 'Add Service' : 'Edit Service',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            decoration: const InputDecoration(
                labelText: 'Service Name', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _desc,
            maxLines: 3,
            decoration: const InputDecoration(
                labelText: 'Description', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _url,
            decoration: const InputDecoration(
                labelText: 'Service URL',
                hintText: 'https://...',
                border: OutlineInputBorder()),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child:
                        CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Save'),
          ),
        ],
      ),
    );
  }
}
