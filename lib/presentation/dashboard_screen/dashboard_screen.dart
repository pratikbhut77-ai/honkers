import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';
import '../../services/supabase_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late List<Animation<double>> _fadeAnims;
  bool _isLoading = true;

  Map<String, int> _metrics = {
    'totalQuestions': 0,
    'approvalRate': 0,
    'activeMembersToday': 0,
    'replyCount': 0,
    'totalMembers': 0,
    'pendingQuestions': 0,
    'approvedQuestions': 0,
    'rejectedQuestions': 0,
    'questionsThisWeek': 0,
    'repliesThisWeek': 0,
    'newMembersThisWeek': 0,
  };

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnims = List.generate(
      6,
      (i) => CurvedAnimation(
        parent: _animController,
        curve: Interval(i * 0.1, 0.4 + i * 0.1, curve: Curves.easeOutCubic),
      ),
    );
    _loadMetrics();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadMetrics() async {
    setState(() => _isLoading = true);
    final stats = await SupabaseService.instance.getDashboardStats();
    if (!mounted) return;
    setState(() {
      _metrics = stats;
      _isLoading = false;
    });
    _animController.forward(from: 0);
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
        title: Text(
          'Dashboard',
          style: GoogleFonts.dmSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppTheme.gold,
              size: 20,
            ),
            onPressed: _loadMetrics,
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.goldSurface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppTheme.gold.withAlpha(60)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.circle, color: AppTheme.gold, size: 7),
                const SizedBox(width: 5),
                Text(
                  'Live',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.gold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppTheme.gold,
                strokeWidth: 2,
              ),
            )
          : RefreshIndicator(
              color: AppTheme.gold,
              backgroundColor: AppTheme.surfaceDark,
              onRefresh: _loadMetrics,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FadeTransition(
                      opacity: _fadeAnims[0],
                      child: _buildHeaderBanner(),
                    ),
                    const SizedBox(height: 24),
                    FadeTransition(
                      opacity: _fadeAnims[1],
                      child: _buildSectionLabel('MVP VALIDATION METRICS'),
                    ),
                    const SizedBox(height: 12),
                    FadeTransition(
                      opacity: _fadeAnims[1],
                      child: _buildPrimaryMetricsGrid(),
                    ),
                    const SizedBox(height: 24),
                    FadeTransition(
                      opacity: _fadeAnims[2],
                      child: _buildSectionLabel('QUESTION FUNNEL'),
                    ),
                    const SizedBox(height: 12),
                    FadeTransition(
                      opacity: _fadeAnims[2],
                      child: _buildQuestionFunnelCard(),
                    ),
                    const SizedBox(height: 24),
                    FadeTransition(
                      opacity: _fadeAnims[3],
                      child: _buildSectionLabel('THIS WEEK'),
                    ),
                    const SizedBox(height: 12),
                    FadeTransition(
                      opacity: _fadeAnims[3],
                      child: _buildWeeklyStatsRow(),
                    ),
                    const SizedBox(height: 24),
                    FadeTransition(
                      opacity: _fadeAnims[4],
                      child: _buildSectionLabel('ENGAGEMENT HEALTH'),
                    ),
                    const SizedBox(height: 12),
                    FadeTransition(
                      opacity: _fadeAnims[4],
                      child: _buildEngagementCard(),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeaderBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.gold.withAlpha(30),
            AppTheme.goldDim.withAlpha(15),
            Colors.transparent,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.gold.withAlpha(50), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.goldSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.gold.withAlpha(80)),
            ),
            child: const Icon(
              Icons.bar_chart_rounded,
              color: AppTheme.gold,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AhmedabadHonkers',
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.gold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'MVP validation overview · Live data',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.dmSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppTheme.textMuted,
        letterSpacing: 0.6,
      ),
    );
  }

  Widget _buildPrimaryMetricsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                icon: Icons.help_outline_rounded,
                label: 'Total Questions',
                value: '${_metrics['totalQuestions']}',
                subLabel: 'all time',
                accent: AppTheme.gold,
                isLarge: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                icon: Icons.check_circle_outline_rounded,
                label: 'Approval Rate',
                value: '${_metrics['approvalRate']}%',
                subLabel: 'of submitted',
                accent: AppTheme.approved,
                isLarge: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                icon: Icons.people_outline_rounded,
                label: 'Active Today',
                value: '${_metrics['activeMembersToday']}',
                subLabel: 'members',
                accent: const Color(0xFF4A9EFF),
                isLarge: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Total Replies',
                value: '${_metrics['replyCount']}',
                subLabel: 'community replies',
                accent: const Color(0xFFB06EFF),
                isLarge: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
    required String subLabel,
    required Color accent,
    bool isLarge = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withAlpha(40), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accent.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accent, size: 18),
              ),
              Icon(
                Icons.trending_up_rounded,
                color: accent.withAlpha(120),
                size: 16,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize: isLarge ? 26 : 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subLabel,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: AppTheme.textMuted,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionFunnelCard() {
    final total = _metrics['totalQuestions'] ?? 0;
    final approved = _metrics['approvedQuestions'] ?? 0;
    final pending = _metrics['pendingQuestions'] ?? 0;
    final rejected = _metrics['rejectedQuestions'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A2A), width: 1),
      ),
      child: Column(
        children: [
          _buildFunnelRow(
            label: 'Approved',
            count: approved,
            total: total,
            color: AppTheme.approved,
            icon: Icons.check_circle_rounded,
          ),
          const SizedBox(height: 14),
          _buildFunnelRow(
            label: 'Pending',
            count: pending,
            total: total,
            color: AppTheme.gold,
            icon: Icons.hourglass_empty_rounded,
          ),
          const SizedBox(height: 14),
          _buildFunnelRow(
            label: 'Rejected',
            count: rejected,
            total: total,
            color: AppTheme.rejected,
            icon: Icons.cancel_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildFunnelRow({
    required String label,
    required int count,
    required int total,
    required Color color,
    required IconData icon,
  }) {
    final ratio = total > 0 ? count / total : 0.0;
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
            const Spacer(),
            Text(
              '$count',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '(${(ratio * 100).toStringAsFixed(0)}%)',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            backgroundColor: color.withAlpha(25),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildSmallStatCard(
            icon: Icons.help_rounded,
            label: 'Questions',
            value: '${_metrics['questionsThisWeek']}',
            color: AppTheme.gold,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildSmallStatCard(
            icon: Icons.chat_bubble_rounded,
            label: 'Replies',
            value: '${_metrics['repliesThisWeek']}',
            color: const Color(0xFFB06EFF),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildSmallStatCard(
            icon: Icons.person_add_rounded,
            label: 'New Members',
            value: '${_metrics['newMembersThisWeek']}',
            color: const Color(0xFF4A9EFF),
          ),
        ),
      ],
    );
  }

  Widget _buildSmallStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(35), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppTheme.textMuted,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementCard() {
    final totalQ = _metrics['totalQuestions'] ?? 0;
    final totalR = _metrics['replyCount'] ?? 0;
    final totalM = _metrics['totalMembers'] ?? 0;
    final activeToday = _metrics['activeMembersToday'] ?? 0;

    final repliesPerQuestion = totalQ > 0
        ? (totalR / totalQ).toStringAsFixed(1)
        : '0';
    final memberEngagement = totalM > 0
        ? ((activeToday / totalM) * 100).toStringAsFixed(1)
        : '0';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A2A), width: 1),
      ),
      child: Column(
        children: [
          _buildEngagementRow(
            label: 'Avg. Replies per Question',
            value: repliesPerQuestion,
            icon: Icons.forum_rounded,
            color: AppTheme.gold,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Color(0xFF2A2A2A), height: 1),
          ),
          _buildEngagementRow(
            label: 'Daily Member Engagement',
            value: '$memberEngagement%',
            icon: Icons.people_rounded,
            color: const Color(0xFF4A9EFF),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Color(0xFF2A2A2A), height: 1),
          ),
          _buildEngagementRow(
            label: 'Total Community Members',
            value: '$totalM',
            icon: Icons.groups_rounded,
            color: const Color(0xFFB06EFF),
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementRow({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.dmSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}
