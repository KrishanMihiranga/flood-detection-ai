import 'package:flutter/material.dart';

import '../../core/auth/auth_session_repository.dart';
import '../../core/demo/demo_credentials.dart';
import '../../core/reports/flood_report_record.dart';
import '../../core/reports/flood_reports_repository.dart';
import '../../core/theme/app_colors.dart';
import 'admin_report_verification_screen.dart';

/// Moderator-facing queue — **blocked for non‑admin roles** ([AuthSessionRepository]).
class AdminPendingReportsScreen extends StatefulWidget {
  const AdminPendingReportsScreen({super.key});

  @override
  State<AdminPendingReportsScreen> createState() =>
      _AdminPendingReportsScreenState();
}

class _AdminPendingReportsScreenState extends State<AdminPendingReportsScreen> {
  late Future<(bool allowed, List<CitizenFloodReport> pending)> _load;

  @override
  void initState() {
    super.initState();
    _load = _bootstrap();
  }

  Future<(bool, List<CitizenFloodReport>)> _bootstrap() async {
    final gate = await AuthSessionRepository.isCurrentUserAdmin();
    if (!gate) return (false, const <CitizenFloodReport>[]);
    final rows = await FloodReportsRepository.loadPendingForModeration();
    return (true, rows);
  }

  Future<void> _reload() async {
    setState(() {
      _load = _bootstrap();
    });
    await _load;
  }

  Future<void> _openVerification(CitizenFloodReport row) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => AdminReportVerificationScreen(report: row),
      ),
    );
    if (mounted) await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.dashboardCanvas,
      appBar: AppBar(
        title: const Text('Report moderation'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: FutureBuilder<(bool, List<CitizenFloodReport>)>(
        future: _load,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final allowed = snapshot.data!.$1;
          if (!allowed) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline,
                        size: 48, color: AppColors.textSecondary),
                    const SizedBox(height: 16),
                    Text(
                      'Administrators only',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'This queue is gated by your signed‑in role. Citizen accounts '
                      'cannot open it.\n\n'
                      '(Demo moderator login: ${DemoCredentials.adminEmail})',
                      style: textTheme.bodyMedium?.copyWith(
                        height: 1.4,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Back'),
                    ),
                  ],
                ),
              ),
            );
          }

          final rows = snapshot.data!.$2;
          return RefreshIndicator(
            onRefresh: _reload,
            child: rows.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(32),
                    children: [
                      Text(
                        'No pending submissions — nice and quiet.',
                        style: textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    itemCount: rows.length,
                    separatorBuilder: (context, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) => _ModerationTile(
                      row: rows[index],
                      onTap: () => _openVerification(rows[index]),
                    ),
                  ),
          );
        },
      ),
    );
  }
}

class _ModerationTile extends StatelessWidget {
  const _ModerationTile({required this.row, required this.onTap});

  final CitizenFloodReport row;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final shortDesc = row.description.trim();
    final preview = shortDesc.length > 132
        ? '${shortDesc.substring(0, 129)}…'
        : shortDesc;

    return Material(
      color: AppColors.background,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF6E8),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Pending',
                      style: textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFB54708),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      row.reporterPhone,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                preview,
                style: textTheme.bodyMedium?.copyWith(height: 1.42),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.smart_toy_outlined,
                      size: 18, color: AppColors.ctaBackground),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      row.aiSuggestedRiskLabel,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.ctaBackground,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Tap for narrative, coordinates, attachments',
                style: textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}