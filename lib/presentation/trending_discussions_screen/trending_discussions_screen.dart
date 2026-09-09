import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_theme.dart';
import '../../services/supabase_service.dart';
import '../../routes/app_routes.dart';
import '../../widgets/custom_image_widget.dart';

class TrendingDiscussionsScreen extends StatefulWidget {
  const TrendingDiscussionsScreen({super.key});

  @override
  State<TrendingDiscussionsScreen> createState() =>
      _TrendingDiscussionsScreenState();
}

class _TrendingDiscussionsScreenState extends State<TrendingDiscussionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  List<Map<String, dynamic>> _byReplies = [];
  List<Map<String, dynamic>> _byEngagement = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final data = await SupabaseService.instance.getTrendingQuestions();
    if (!mounted) return;
    setState(() {
      _byReplies = List<Map<String, dynamic>>.from(data['byReplies'] ?? []);
      _byEngagement = List<Map<String, dynamic>>.from(
        data['byEngagement'] ?? [],
      );
      _isLoading = false;
    });
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
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.goldLight, AppTheme.gold],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: const Icon(
                Icons.local_fire_department_rounded,
                color: Color(0xFF0A0A0A),
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Trending',
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
            onPressed: _loadData,
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.gold.withAlpha(40)),
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
              labelStyle: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              labelColor: AppTheme.gold,
              unselectedLabelColor: AppTheme.textMuted,
              tabs: const [
                Tab(text: 'Most Replies'),
                Tab(text: 'Most Engaged'),
              ],
            ),
          ),
        ),
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
              onRefresh: _loadData,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildRankedList(
                    questions: _byReplies,
                    metricKey: 'replyCount',
                    metricLabel: 'replies',
                    metricIcon: Icons.chat_bubble_rounded,
                    emptyMessage: 'No discussions yet',
                  ),
                  _buildRankedList(
                    questions: _byEngagement,
                    metricKey: 'engagementScore',
                    metricLabel: 'score',
                    metricIcon: Icons.trending_up_rounded,
                    emptyMessage: 'No engaged discussions yet',
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildRankedList({
    required List<Map<String, dynamic>> questions,
    required String metricKey,
    required String metricLabel,
    required IconData metricIcon,
    required String emptyMessage,
  }) {
    if (questions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(metricIcon, color: AppTheme.textMuted, size: 44),
            const SizedBox(height: 12),
            Text(
              emptyMessage,
              style: GoogleFonts.dmSans(
                fontSize: 15,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top 3 highlight cards
          if (questions.isNotEmpty)
            _buildTopCard(
              rank: 1,
              question: questions[0],
              metricKey: metricKey,
              metricLabel: metricLabel,
              metricIcon: metricIcon,
            ),
          if (questions.length > 1) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildSecondaryCard(
                    rank: 2,
                    question: questions[1],
                    metricKey: metricKey,
                    metricLabel: metricLabel,
                  ),
                ),
                if (questions.length > 2) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildSecondaryCard(
                      rank: 3,
                      question: questions[2],
                      metricKey: metricKey,
                      metricLabel: metricLabel,
                    ),
                  ),
                ],
              ],
            ),
          ],
          if (questions.length > 3) ...[
            const SizedBox(height: 20),
            Text(
              'MORE DISCUSSIONS',
              style: GoogleFonts.dmSans(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppTheme.textMuted,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            ...questions.sublist(3).asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildRankRow(
                  rank: entry.key + 4,
                  question: entry.value,
                  metricKey: metricKey,
                  metricLabel: metricLabel,
                  metricIcon: metricIcon,
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildTopCard({
    required int rank,
    required Map<String, dynamic> question,
    required String metricKey,
    required String metricLabel,
    required IconData metricIcon,
  }) {
    final metricValue = question[metricKey] ?? 0;
    final author = question['honkers_users'] as Map<String, dynamic>?;
    final authorName = author?['full_name'] as String? ?? 'Anonymous';
    final avatarUrl = author?['avatar_url'] as String? ?? '';
    final title = question['title'] as String? ?? '';
    final replyCount = question['replyCount'] ?? 0;

    return GestureDetector(
      onTap: () =>
          context.push(AppRoutes.questionDetailScreen, extra: question),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.gold.withAlpha(30),
              AppTheme.goldDim.withAlpha(15),
              AppTheme.backgroundDark,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: AppTheme.gold.withAlpha(80), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Rank badge
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.goldLight, AppTheme.gold],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Center(
                    child: Text(
                      '#$rank',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0A0A0A),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(
                  Icons.local_fire_department_rounded,
                  color: AppTheme.gold,
                  size: 18,
                ),
                const SizedBox(width: 4),
                Text(
                  'Top Discussion',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.gold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.goldSurface,
                    borderRadius: BorderRadius.circular(20.0),
                    border: Border.all(color: AppTheme.gold.withAlpha(60)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(metricIcon, size: 12, color: AppTheme.gold),
                      const SizedBox(width: 4),
                      Text(
                        '$metricValue $metricLabel',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.gold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
                height: 1.35,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (avatarUrl.isNotEmpty)
                  ClipOval(
                    child: CustomImageWidget(
                      imageUrl: avatarUrl,
                      width: 22,
                      height: 22,
                      fit: BoxFit.cover,
                      semanticLabel: '$authorName profile photo',
                    ),
                  )
                else
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariantDark,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      size: 13,
                      color: AppTheme.textMuted,
                    ),
                  ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    authorName,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 13,
                  color: AppTheme.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  '$replyCount',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: AppTheme.gold,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecondaryCard({
    required int rank,
    required Map<String, dynamic> question,
    required String metricKey,
    required String metricLabel,
  }) {
    final metricValue = question[metricKey] ?? 0;
    final title = question['title'] as String? ?? '';
    final replyCount = question['replyCount'] ?? 0;

    return GestureDetector(
      onTap: () =>
          context.push(AppRoutes.questionDetailScreen, extra: question),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(14.0),
          border: Border.all(
            color: rank == 2
                ? AppTheme.gold.withAlpha(50)
                : const Color(0xFF2A2A2A),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: rank == 2
                        ? AppTheme.gold.withAlpha(30)
                        : AppTheme.surfaceVariantDark,
                    borderRadius: BorderRadius.circular(6.0),
                    border: Border.all(
                      color: rank == 2
                          ? AppTheme.gold.withAlpha(80)
                          : const Color(0xFF3A3A3A),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '#$rank',
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: rank == 2
                            ? AppTheme.gold
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '$metricValue',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.gold,
                  ),
                ),
                const SizedBox(width: 3),
                Text(
                  metricLabel,
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
                height: 1.3,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 12,
                  color: AppTheme.textMuted,
                ),
                const SizedBox(width: 3),
                Text(
                  '$replyCount',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRankRow({
    required int rank,
    required Map<String, dynamic> question,
    required String metricKey,
    required String metricLabel,
    required IconData metricIcon,
  }) {
    final metricValue = question[metricKey] ?? 0;
    final author = question['honkers_users'] as Map<String, dynamic>?;
    final authorName = author?['full_name'] as String? ?? 'Anonymous';
    final avatarUrl = author?['avatar_url'] as String? ?? '';
    final title = question['title'] as String? ?? '';
    final replyCount = question['replyCount'] ?? 0;

    return GestureDetector(
      onTap: () =>
          context.push(AppRoutes.questionDetailScreen, extra: question),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: const Color(0xFF2A2A2A)),
        ),
        child: Row(
          children: [
            // Rank number
            SizedBox(
              width: 28,
              child: Text(
                '$rank',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (avatarUrl.isNotEmpty)
                        ClipOval(
                          child: CustomImageWidget(
                            imageUrl: avatarUrl,
                            width: 18,
                            height: 18,
                            fit: BoxFit.cover,
                            semanticLabel: '$authorName profile photo',
                          ),
                        )
                      else
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceVariantDark,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            size: 10,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          authorName,
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 11,
                        color: AppTheme.textMuted,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '$replyCount',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Metric badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$metricValue',
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.gold,
                  ),
                ),
                Text(
                  metricLabel,
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
