import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:setulink_app/models/job_model.dart';
import 'package:setulink_app/screens/job_detail_screen.dart';
import 'package:intl/intl.dart';

class AdminJobsListScreen extends StatelessWidget {
  const AdminJobsListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(tr('all_jobs')),
          bottom: TabBar(
            tabs: [
              Tab(text: tr('open')),
              Tab(text: tr('active')),
              Tab(text: tr('completed')),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _JobList(status: ['open']),
            _JobList(status: ['confirmed', 'in_progress', 'on_the_way', 'started']),
            _JobList(status: ['completed', 'cancelled']),
          ],
        ),
      ),
    );
  }
}

class _JobList extends StatelessWidget {
  final List<String> status;
  const _JobList({Key? key, required this.status}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('jobs')
          .where('jobStatus', whereIn: status)
          .orderBy('scheduledTime', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('${tr('error')}: ${snapshot.error}'));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final jobs = snapshot.data!.docs;
        if (jobs.isEmpty) return Center(child: Text(tr('no_jobs_found')));

        return ListView.builder(
          itemCount: jobs.length,
          itemBuilder: (context, index) {
            final job = JobModel.fromMap(jobs[index].data() as Map<String, dynamic>, jobs[index].id);
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                title: Text(job.title),
                subtitle: Text('${job.jobStatus.toUpperCase()} • ₹${job.budget}'),
                trailing: Text(DateFormat('dd MMM').format(job.scheduledTime)),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => JobDetailScreen(jobId: job.id)),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
