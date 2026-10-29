import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../../../core/config/api_config.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../auth/data/auth_client.dart';
import '../../models/verification_status.dart';

class VerificationStatusScreen extends StatefulWidget {
  const VerificationStatusScreen({super.key});

  @override
  State<VerificationStatusScreen> createState() => _VerificationStatusScreenState();
}

class _VerificationStatusScreenState extends State<VerificationStatusScreen> {
  late Future<List<VerificationStatus>> _future = _load();

  Future<List<VerificationStatus>> _load() async {
    final token = await AuthSession.token();
    if (token == null) throw Exception('Your session has expired.');
    final response = await http.get(
      Uri.parse(ApiConfig.mySubmissions),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) throw Exception('Unable to load verification status.');
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (data['items'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(VerificationStatus.fromJson)
        .toList();
  }

  void _retry() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EcoTraceColors.canvas,
      appBar: AppBar(
        title: const Text('Verification status'),
        backgroundColor: EcoTraceColors.canvas,
        foregroundColor: EcoTraceColors.forestDeep,
      ),
      body: RefreshIndicator(
        onRefresh: () async => _retry(),
        child: FutureBuilder<List<VerificationStatus>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 120),
                  const Icon(Icons.cloud_off_outlined, size: 48, color: EcoTraceColors.muted),
                  const SizedBox(height: 16),
                  Text(snapshot.error.toString().replaceFirst('Exception: ', ''), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton(onPressed: _retry, child: const Text('Try again')),
                ],
              );
            }
            final items = snapshot.data ?? const <VerificationStatus>[];
            if (items.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(24),
                children: const [
                  SizedBox(height: 120),
                  Icon(Icons.fact_check_outlined, size: 52, color: EcoTraceColors.forest),
                  SizedBox(height: 16),
                  Text('No verification records yet', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                  SizedBox(height: 8),
                  Text('Your submitted tree verifications will appear here with their review status.', textAlign: TextAlign.center, style: TextStyle(color: EcoTraceColors.muted)),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, index) => _StatusCard(item: items[index]),
            );
          },
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.item});
  final VerificationStatus item;

  @override
  Widget build(BuildContext context) {
    final status = item.status.toUpperCase();
    final color = switch (item.status) {
      'approved' => const Color(0xFF15803D),
      'declined' => const Color(0xFFB91C1C),
      'resubmit' => const Color(0xFFD97706),
      _ => const Color(0xFF0284C7),
    };
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: EcoTraceColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(item.treeName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: EcoTraceColors.forestDeep))),
          Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: color.withValues(alpha: .12), borderRadius: BorderRadius.circular(99)), child: Text(status, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900))),
        ]),
        if (item.treeCode != null) ...[const SizedBox(height: 6), Text(item.treeCode!, style: const TextStyle(color: EcoTraceColors.muted, fontSize: 12))],
        const SizedBox(height: 10),
        Text(item.type == 'incident' ? 'Incident report' : 'Tree verification', style: const TextStyle(color: EcoTraceColors.muted, fontSize: 13, fontWeight: FontWeight.w700)),
        if (item.eventTitle != null) Text(item.eventTitle!, style: const TextStyle(color: EcoTraceColors.muted, fontSize: 12)),
        if (item.reason?.isNotEmpty == true) ...[const SizedBox(height: 10), Text('Reason: ${item.reason}', style: const TextStyle(color: Color(0xFF7F1D1D), fontSize: 13))],
        if (item.note?.isNotEmpty == true) ...[const SizedBox(height: 6), Text('Reviewer note: ${item.note}', style: const TextStyle(color: EcoTraceColors.muted, fontSize: 13))],
      ]),
    );
  }
}