import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';
import '../../services/supabase_service.dart';
import '../../widgets/empty_state_widget.dart';

class ContentModerationScreen extends StatefulWidget {
  const ContentModerationScreen({super.key});

  @override
  State<ContentModerationScreen> createState() =>
      _ContentModerationScreenState();
}

class _ContentModerationScreenState extends State<ContentModerationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _reports = [];
  bool _isLoading = true;

  List<Map<String, dynamic>> get _pendingReports =>
      _reports.where((r) => r['status'] == 'pending').toList();
  List<Map<String, dynamic>> get _reviewedReports =>
      _reports.where((r) => r['status'] == 'reviewed').toList();
  List<Map<String, dynamic>> get _dismissedReports =>
      _reports.where((r) => r['status'] == 'dismissed').toList();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadReports();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);
    final reports = await SupabaseService.instance.getReports();
    if (!mounted) return;
    setState(() {
      _reports = reports;
      _isLoading = false;
    });
  }

  Future<void> _removeContent(Map<String, dynamic> report) async {
    final confirmed = await _showConfirmDialog(
      title: 'Remove Content',
      message:
          'This will permanently delete the reported ${report['content_type']}. This action cannot be undone.',
      confirmLabel: 'Remove',
      confirmColor: AppTheme.error,
    );
    if (!confirmed) return;

    final contentType = report['content_type'] as String;
    final contentId = report['content_id'] as String;
    bool deleted = false;

    if (contentType == 'question') {
      deleted = await SupabaseService.instance.deleteQuestion(contentId);
    } else {
      deleted = await SupabaseService.instance.deleteReply(contentId);
    }

    if (deleted) {
      await SupabaseService.instance.updateReportStatus(
        reportId: report['id'] as String,
        status: 'reviewed',
        adminNote: 'Content removed by admin.',
      );
      _showSnackBar('Content removed successfully', AppTheme.approved);
      _loadReports();
    } else {
      _showSnackBar('Failed to remove content', AppTheme.error);
    }
  }

  Future<void> _dismissReport(Map<String, dynamic> report) async {
    final confirmed = await _showConfirmDialog(
      title: 'Dismiss Report',
      message:
          'Mark this report as dismissed? The content will remain visible.',
      confirmLabel: 'Dismiss',
      confirmColor: AppTheme.gold,
    );
    if (!confirmed) return;

    final ok = await SupabaseService.instance.updateReportStatus(
      reportId: report['id'] as String,
      status: 'dismissed',
      adminNote: 'Report dismissed by admin.',
    );
    if (ok && mounted) {
      setState(() {
        final idx = _reports.indexWhere((r) => r['id'] == report['id']);
        if (idx != -1) _reports[idx]['status'] = 'dismissed';
      });
      _showSnackBar('Report dismissed', AppTheme.textMuted);
    }
  }

  Future<bool> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: GoogleFonts.dmSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        content: Text(
          message,
          style: GoogleFonts.dmSans(
            fontSize: 14,
            color: AppTheme.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.dmSans(color: AppTheme.textMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              confirmLabel,
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.dmSans(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _timeAgo(dynamic value) {
    if (value == null) return '';
    DateTime? dt;
    if (value is DateTime) {
      dt = value;
    } else if (value is String) {
      dt = DateTime.tryParse(value);
    }
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppTheme.textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.error.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.error.withAlpha(60)),
              ),
              child: const Icon(
                Icons.flag_rounded,
                color: AppTheme.error,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Content Moderation',
              style: GoogleFonts.dmSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppTheme.gold,
              size: 20,
            ),
            onPressed: _loadReports,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(children: [_buildStatsRow(), _buildTabBar()]),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppTheme.gold,
                strokeWidth: 2,
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildReportList(_pendingReports, showActions: true),
                _buildReportList(_reviewedReports),
                _buildReportList(_dismissedReports),
              ],
            ),
    );
  }

  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        children: [
          _buildStatChip(
            icon: Icons.hourglass_top_rounded,
            label: 'Pending',
            count: _pendingReports.length,
            color: AppTheme.error,
          ),
          const SizedBox(width: 8),
          _buildStatChip(
            icon: Icons.check_circle_outline_rounded,
            label: 'Reviewed',
            count: _reviewedReports.length,
            color: AppTheme.approved,
          ),
          const SizedBox(width: 8),
          _buildStatChip(
            icon: Icons.do_not_disturb_on_outlined,
            label: 'Dismissed',
            count: _dismissedReports.length,
            color: AppTheme.textMuted,
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required int count,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 5),
            Text(
              '$count',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: AppTheme.textMuted,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppTheme.gold,
          borderRadius: BorderRadius.circular(8),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: AppTheme.backgroundDark,
        unselectedLabelColor: AppTheme.textMuted,
        labelStyle: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(text: 'Pending'),
          Tab(text: 'Reviewed'),
          Tab(text: 'Dismissed'),
        ],
      ),
    );
  }

  Widget _buildReportList(
    List<Map<String, dynamic>> reports, {
    bool showActions = false,
  }) {
    if (reports.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.flag_outlined,
        title: showActions ? 'No pending reports' : 'Nothing here',
        subtitle: showActions
            ? 'Community reports will appear here for review'
            : 'No reports in this category yet',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: reports.length,
      itemBuilder: (context, index) {
        return _buildReportCard(reports[index], showActions: showActions);
      },
    );
  }

  Widget _buildReportCard(
    Map<String, dynamic> report, {
    bool showActions = false,
  }) {
    final contentType = report['content_type'] as String? ?? 'content';
    final reason = report['reason'] as String? ?? '';
    final reporterName =
        (report['honkers_users'] as Map<String, dynamic>?)?['full_name']
            as String? ??
        'Unknown';
    final contentPreview = report['content_preview'] as String? ?? '';
    final adminNote = report['admin_note'] as String?;
    final isQuestion = contentType == 'question';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: showActions
              ? AppTheme.error.withAlpha(60)
              : const Color(0xFF2A2A2A),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: isQuestion
                        ? AppTheme.gold.withAlpha(25)
                        : AppTheme.surfaceVariantDark,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isQuestion
                          ? AppTheme.gold.withAlpha(60)
                          : const Color(0xFF3A3A3A),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isQuestion
                            ? Icons.help_outline_rounded
                            : Icons.chat_bubble_outline_rounded,
                        size: 11,
                        color: isQuestion
                            ? AppTheme.gold
                            : AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isQuestion ? 'Question' : 'Reply',
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isQuestion
                              ? AppTheme.gold
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withAlpha(20),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Reported',
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.error,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  _timeAgo(report['created_at']),
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),

          // Content preview
          if (contentPreview.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariantDark,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF3A3A3A)),
              ),
              child: Text(
                contentPreview,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          // Reason
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.report_problem_outlined,
                  size: 14,
                  color: AppTheme.error,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reason',
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textMuted,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        reason,
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Reporter
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Row(
              children: [
                const Icon(
                  Icons.person_outline_rounded,
                  size: 13,
                  color: AppTheme.textMuted,
                ),
                const SizedBox(width: 5),
                Text(
                  'Reported by ',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                  ),
                ),
                Text(
                  reporterName,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Admin note (if reviewed/dismissed)
          if (adminNote != null && adminNote.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.admin_panel_settings_outlined,
                    size: 13,
                    color: AppTheme.gold,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      adminNote,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: AppTheme.gold,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Action buttons
          if (showActions)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _dismissReport(report),
                      icon: const Icon(
                        Icons.do_not_disturb_on_outlined,
                        size: 15,
                      ),
                      label: Text(
                        'Dismiss',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textMuted,
                        side: const BorderSide(color: Color(0xFF3A3A3A)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _removeContent(report),
                      icon: const Icon(Icons.delete_outline_rounded, size: 15),
                      label: Text(
                        'Remove',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.error,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
