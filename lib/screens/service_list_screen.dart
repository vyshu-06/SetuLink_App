import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';

class ServiceListScreen extends StatefulWidget {
  final String categoryKey;
  final String role;

  const ServiceListScreen({
    required this.categoryKey,
    required this.role,
    Key? key,
  }) : super(key: key);

  @override
  State<ServiceListScreen> createState() => _ServiceListScreenState();
}

class _ServiceListScreenState extends State<ServiceListScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr(widget.categoryKey)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db
            .collection('services')
            .where('category', isEqualTo: widget.categoryKey)
            .snapshots(),
        builder: (context, snapshot) {
          // 🔹 Loading State
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 🔹 Error State
          if (snapshot.hasError) {
            return Center(child: Text(tr('error_loading_data')));
          }

          // 🔹 Empty Data
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(child: Text(tr('no_jobs_available')));
          }

          // 🔹 List Display
          return ListView.separated(
            padding: const EdgeInsets.all(8.0),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final service = docs[index].data() as Map<String, dynamic>;

              final name = service['name'] ?? tr('unknown_service');
              final description = service['description'] ?? '';

              return ListTile(
                title: Text(name),
                subtitle: Text(description),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // TODO: Navigate to detail page
                  // Example: Navigator.push(...);
                },
              );
            },
          );
        },
      ),
    );
  }
}
