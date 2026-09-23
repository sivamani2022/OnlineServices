import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/service_item.dart';
import '../services/api_service.dart';

class ServicesScreen extends StatefulWidget {
  final String deptId;
  final String deptName;
  final String deptIcon;
  final bool isOwner;

  const ServicesScreen({
    super.key,
    required this.deptId,
    required this.deptName,
    required this.deptIcon,
    this.isOwner = false,
  });

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  late Future<List<ServiceItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiService.getServices(widget.deptId);
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Could not open link.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.deptIcon}  ${widget.deptName}'),
      ),
      body: FutureBuilder<List<ServiceItem>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Could not load services.\n${snap.error}'));
          }
          final services = snap.data ?? [];
          if (services.isEmpty) {
            return const Center(child: Text('No services listed for this department yet.'));
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
                            style: TextStyle(
                                color: Colors.grey.shade700, fontSize: 13, height: 1.4)),
                      ],
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: ElevatedButton.icon(
                          onPressed: () => _openUrl(s.url),
                          icon: const Icon(Icons.open_in_new, size: 16),
                          label: const Text('Open Service'),
                          style: ElevatedButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          ),
                        ),
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
