import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';
import '../../services/supabase_service.dart';

class TopContributorsScreen extends StatefulWidget {
  const TopContributorsScreen({super.key});

  @override
  State<TopContributorsScreen> createState() => _TopContributorsScreenState();
}

class _TopContributorsScreenState extends State<TopContributorsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  List<Map<String, dynamic>> _byReplies = [];
  List<Map<String, dynamic>> _byQuestions = [];
  List<Map<String, dynamic>> _byApprovalRate = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadContributors();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadContributors() async {
    setState(() => _isLoading = true);
    final data = await SupabaseService.instance.getTopContributors();
    if (!mounted) return;
    setState(() {
      _byReplies = List<Map<String, dynamic>>.from(data['byReplies'] ?? []);
      _byQuestions = List<Map<String, dynamic>>.from(data['byQuestions'] ?? []);
      _byApprovalRate = List<Map<String, dynamic>>.from(
        data['byApprovalRate'] ?? [],
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
        title: Text(
          'Top Contributors',
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
            onPressed: _loadContributors,
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
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              labelColor: AppTheme.gold,
              unselectedLabelColor: AppTheme.textMuted,
              tabs: const [
                Tab(text: 'Replies'),
                Tab(text: 'Questions'),
                Tab(text: 'Approval'),
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
              onRefresh: _loadContributors,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildLeaderboard(
                    contributors: _byReplies,
                    metricLabel: 'Replies',
                    metricKey: 'replyCount',
                    icon: Icons.chat_bubble_outline_rounded,
                    emptyMessage: 'No replies yet',
                  ),
                  _buildLeaderboard(
                    contributors: _byQuestions,
                    metricLabel: 'Questions',
                    metricKey: 'questionCount',
                    icon: Icons.help_outline_rounded,
                    emptyMessage: 'No questions yet',
                  ),
                  _buildLeaderboard(
                    contributors: _byApprovalRate,
                    metricLabel: 'Approval',
                    metricKey: 'approvalRate',
                    icon: Icons.verified_rounded,
                    emptyMessage: 'No approved questions yet',
                    isPercentage: true,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildLeaderboard({
    required List<Map<String, dynamic>> contributors,
    required String metricLabel,
    required String metricKey,
    required IconData icon,
    required String emptyMessage,
    bool isPercentage = false,
  }) {
    if (contributors.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppTheme.textMuted, size: 40),
            const SizedBox(height: 12),
            Text(
              emptyMessage,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    final top3 = contributors.take(3).toList();
    final rest = contributors.length > 3
        ? contributors.sublist(3)
        : <Map<String, dynamic>>[];

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPodium(top3, metricKey, isPercentage),
          if (rest.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                'OTHER CONTRIBUTORS',
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textMuted,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            ...rest.asMap().entries.map((entry) {
              return _buildContributorRow(
                rank: entry.key + 4,
                contributor: entry.value,
                metricKey: metricKey,
                metricLabel: metricLabel,
                icon: icon,
                isPercentage: isPercentage,
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildPodium(
    List<Map<String, dynamic>> top3,
    String metricKey,
    bool isPercentage,
  ) {
    final slots = List<Map<String, dynamic>>.from(top3);
    while (slots.length < 3) {
      slots.add({});
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.gold.withAlpha(22),
            AppTheme.goldDim.withAlpha(10),
            Colors.transparent,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.gold.withAlpha(40)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: _buildPodiumSlot(
              contributor: slots[1],
              rank: 2,
              barHeight: 80,
              metricKey: metricKey,
              isPercentage: isPercentage,
              accentColor: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildPodiumSlot(
              contributor: slots[0],
              rank: 1,
              barHeight: 110,
              metricKey: metricKey,
              isPercentage: isPercentage,
              accentColor: AppTheme.gold,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildPodiumSlot(
              contributor: slots[2],
              rank: 3,
              barHeight: 60,
              metricKey: metricKey,
              isPercentage: isPercentage,
              accentColor: const Color(0xFFCD7F32),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumSlot({
    required Map<String, dynamic> contributor,
    required int rank,
    required double barHeight,
    required String metricKey,
    required bool isPercentage,
    required Color accentColor,
  }) {
    final isEmpty = contributor.isEmpty;
    final name = isEmpty
        ? '—'
        : (contributor['fullName'] as String? ?? 'Unknown');
    final value = isEmpty ? 0 : (contributor[metricKey] as num? ?? 0).toInt();
    final initials = (!isEmpty && name != '—')
        ? name
              .trim()
              .split(' ')
              .map((w) => w.isNotEmpty ? w[0] : '')
              .take(2)
              .join()
              .toUpperCase()
        : '?';
    final avatarSize = rank == 1 ? 54.0 : 42.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: accentColor.withAlpha(30),
            shape: BoxShape.circle,
            border: Border.all(color: accentColor.withAlpha(120)),
          ),
          child: Center(
            child: Text(
              '$rank',
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: accentColor,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: avatarSize,
          height: avatarSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.surfaceVariantDark,
            border: Border.all(
              color: isEmpty
                  ? AppTheme.surfaceElevatedDark
                  : accentColor.withAlpha(160),
              width: rank == 1 ? 2.5 : 1.5,
            ),
          ),
          child: Center(
            child: Text(
              initials,
              style: GoogleFonts.dmSans(
                fontSize: rank == 1 ? 17 : 13,
                fontWeight: FontWeight.w700,
                color: isEmpty ? AppTheme.textMuted : AppTheme.textPrimary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          name.length > 9 ? '${name.substring(0, 8)}…' : name,
          style: GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isEmpty ? AppTheme.textMuted : AppTheme.textPrimary,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: isEmpty ? AppTheme.surfaceDark : accentColor.withAlpha(25),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isEmpty
                  ? AppTheme.surfaceElevatedDark
                  : accentColor.withAlpha(80),
            ),
          ),
          child: Text(
            isEmpty ? '—' : (isPercentage ? '$value%' : '$value'),
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isEmpty ? AppTheme.textMuted : accentColor,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: barHeight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isEmpty
                  ? [AppTheme.surfaceDark, AppTheme.surfaceDark]
                  : [accentColor.withAlpha(55), accentColor.withAlpha(18)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
            border: Border.all(
              color: isEmpty
                  ? AppTheme.surfaceElevatedDark
                  : accentColor.withAlpha(55),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContributorRow({
    required int rank,
    required Map<String, dynamic> contributor,
    required String metricKey,
    required String metricLabel,
    required IconData icon,
    required bool isPercentage,
  }) {
    final name = contributor['fullName'] as String? ?? 'Unknown';
    final value = (contributor[metricKey] as num? ?? 0).toInt();
    final initials = name
        .trim()
        .split(' ')
        .map((w) => w.isNotEmpty ? w[0] : '')
        .take(2)
        .join()
        .toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.gold.withAlpha(20)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '#$rank',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.textMuted,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.surfaceVariantDark,
              border: Border.all(color: AppTheme.gold.withAlpha(50)),
            ),
            child: Center(
              child: Text(
                initials,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: AppTheme.gold),
              const SizedBox(width: 5),
              Text(
                isPercentage ? '$value%' : '$value',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.gold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
