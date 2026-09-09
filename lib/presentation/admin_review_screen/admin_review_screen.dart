import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../theme/app_theme.dart';
import '../../widgets/status_badge_widget.dart';
import '../../widgets/empty_state_widget.dart';
import '../../services/supabase_service.dart';
import '../../routes/app_routes.dart';

class AdminReviewScreen extends StatefulWidget {
  const AdminReviewScreen({super.key});

  @override
  State<AdminReviewScreen> createState() => _AdminReviewScreenState();
}

class _AdminReviewScreenState extends State<AdminReviewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _allQuestions = [];
  bool _isLoading = true;
  RealtimeChannel? _subscription;

  int get _pendingCount =>
      _allQuestions.where((q) => q['status'] == 'pending').length;
  int get _approvedCount =>
      _allQuestions.where((q) => q['status'] == 'approved').length;
  int get _rejectedCount =>
      _allQuestions.where((q) => q['status'] == 'rejected').length;

  List<Map<String, dynamic>> get _pendingQuestions =>
      _allQuestions.where((q) => q['status'] == 'pending').toList();
  List<Map<String, dynamic>> get _approvedQuestions =>
      _allQuestions.where((q) => q['status'] == 'approved').toList();
  List<Map<String, dynamic>> get _rejectedQuestions =>
      _allQuestions.where((q) => q['status'] == 'rejected').toList();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadQuestions();
    _subscribeToQuestions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _subscription?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    setState(() => _isLoading = true);
    final questions = await SupabaseService.instance.getAllQuestions();
    if (!mounted) return;
    setState(() {
      _allQuestions = questions;
      _isLoading = false;
    });
  }

  void _subscribeToQuestions() {
    _subscription = SupabaseService.instance.subscribeToQuestions((
      payload,
    ) async {
      if (!mounted) return;
      // Reload all questions on any change for simplicity
      final questions = await SupabaseService.instance.getAllQuestions();
      if (mounted) setState(() => _allQuestions = questions);
    });
  }

  Future<void> _approveQuestion(String id) async {
    final ok = await SupabaseService.instance.updateQuestionStatus(
      questionId: id,
      status: 'approved',
    );
    if (ok && mounted) {
      setState(() {
        final idx = _allQuestions.indexWhere((q) => q['id'] == id);
        if (idx != -1) _allQuestions[idx]['status'] = 'approved';
      });
      _showSnackBar('Question approved', AppTheme.approved);
    }
  }

  Future<void> _rejectQuestion(String id) async {
    final ok = await SupabaseService.instance.updateQuestionStatus(
      questionId: id,
      status: 'rejected',
    );
    if (ok && mounted) {
      setState(() {
        final idx = _allQuestions.indexWhere((q) => q['id'] == id);
        if (idx != -1) _allQuestions[idx]['status'] = 'rejected';
      });
      _showSnackBar('Question rejected', AppTheme.rejected);
    }
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
                color: AppTheme.goldSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.gold.withAlpha(60)),
              ),
              child: const Icon(
                Icons.admin_panel_settings_rounded,
                color: AppTheme.gold,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Admin Review',
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
              Icons.flag_rounded,
              color: AppTheme.error,
              size: 20,
            ),
            tooltip: 'Community Reports',
            onPressed: () => context.push(AppRoutes.contentModerationScreen),
          ),
          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppTheme.gold,
              size: 20,
            ),
            onPressed: _loadQuestions,
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
                _buildQuestionList(_pendingQuestions, showActions: true),
                _buildQuestionList(_approvedQuestions),
                _buildQuestionList(_rejectedQuestions),
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
            label: 'Queue',
            count: _pendingCount,
            color: AppTheme.gold,
          ),
          const SizedBox(width: 8),
          _buildStatChip(
            icon: Icons.check_circle_outline_rounded,
            label: 'Approved',
            count: _approvedCount,
            color: AppTheme.approved,
          ),
          const SizedBox(width: 8),
          _buildStatChip(
            icon: Icons.cancel_outlined,
            label: 'Rejected',
            count: _rejectedCount,
            color: AppTheme.rejected,
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
          borderRadius: BorderRadius.circular(12),
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
                fontSize: 15,
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
                  fontWeight: FontWeight.w500,
                  color: color.withAlpha(180),
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
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppTheme.goldSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.gold.withAlpha(80)),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: AppTheme.gold,
        unselectedLabelColor: AppTheme.textMuted,
        labelStyle: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.all(3),
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Pending'),
                if (_pendingCount > 0) ...[
                  const SizedBox(width: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.gold,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$_pendingCount',
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.backgroundDark,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Tab(text: 'Approved'),
          const Tab(text: 'Rejected'),
        ],
      ),
    );
  }

  Widget _buildQuestionList(
    List<Map<String, dynamic>> questions, {
    bool showActions = false,
  }) {
    if (questions.isEmpty) {
      return EmptyStateWidget(
        icon: showActions
            ? Icons.inbox_rounded
            : Icons.check_circle_outline_rounded,
        title: showActions ? 'Queue is empty' : 'Nothing here yet',
        subtitle: showActions
            ? 'All questions have been reviewed'
            : 'No questions in this category',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: questions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final q = questions[index];
        return _buildQuestionCard(q, showActions: showActions);
      },
    );
  }

  Widget _buildQuestionCard(
    Map<String, dynamic> q, {
    bool showActions = false,
  }) {
    final user = q['honkers_users'] as Map<String, dynamic>?;
    final authorName = user?['full_name'] as String? ?? 'Honker';
    final authorPhone = user?['phone'] as String? ?? '';
    final avatarUrl = user?['avatar_url'] as String? ?? '';
    final photoUrls = q['photo_urls'] as List? ?? [];
    final photoCount = photoUrls.length;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: Row(
              children: [
                ClipOval(
                  child: Image.network(
                    avatarUrl,
                    width: 36,
                    height: 36,
                    fit: BoxFit.cover,
                    semanticLabel: 'Avatar of $authorName',
                    errorBuilder: (_, __, ___) => Container(
                      width: 36,
                      height: 36,
                      color: AppTheme.surfaceVariantDark,
                      child: const Icon(
                        Icons.person_rounded,
                        color: AppTheme.textMuted,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authorName,
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        authorPhone.isNotEmpty ? '+91 $authorPhone' : '',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    StatusBadgeWidget(
                      status: _statusFromString(
                        q['status'] as String? ?? 'pending',
                      ),
                      compact: true,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 10,
                          color: AppTheme.textMuted,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          _timeAgo(q['created_at']),
                          style: GoogleFonts.dmSans(
                            fontSize: 10,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Text(
              q['title'] as String? ?? '',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if ((q['details'] as String? ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 5, 14, 0),
              child: Text(
                q['details'] as String,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          if (photoCount > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
              child: Row(
                children: [
                  const Icon(
                    Icons.photo_library_outlined,
                    size: 13,
                    color: AppTheme.gold,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$photoCount photo${photoCount > 1 ? 's' : ''} attached',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: AppTheme.gold,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          if (showActions) ...[
            const SizedBox(height: 12),
            Container(height: 1, color: const Color(0xFF2A2A2A)),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _rejectQuestion(q['id'] as String),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: AppTheme.rejected.withAlpha(20),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppTheme.rejected.withAlpha(80),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.close_rounded,
                              color: AppTheme.rejected,
                              size: 16,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Reject',
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.rejected,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _approveQuestion(q['id'] as String),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: AppTheme.approved.withAlpha(20),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppTheme.approved.withAlpha(80),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.check_rounded,
                              color: AppTheme.approved,
                              size: 16,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Approve',
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.approved,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else
            const SizedBox(height: 14),
        ],
      ),
    );
  }

  QuestionStatus _statusFromString(String s) {
    return switch (s) {
      'approved' => QuestionStatus.approved,
      'rejected' => QuestionStatus.rejected,
      _ => QuestionStatus.pending,
    };
  }
}
