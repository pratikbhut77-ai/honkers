import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/app_export.dart';
import '../../services/honkers_session.dart';
import '../../services/supabase_service.dart';
import './widgets/edit_profile_bottom_sheet_widget.dart';
import './widgets/my_question_item_widget.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name = HonkersSession.instance.fullName;
  String _bio = HonkersSession.instance.bio;
  final String _phone = HonkersSession.instance.phone;
  final String? _avatarUrl = HonkersSession.instance.avatarUrl;

  List<Map<String, dynamic>> _myQuestions = [];
  bool _isLoading = true;

  // Streaks & badges state
  int _streak = 0;
  int _replyCount = 0;
  List<Map<String, dynamic>> _badges = [];

  @override
  void initState() {
    super.initState();
    _loadMyQuestions();
    _loadStreaksAndBadges();
  }

  Future<void> _loadMyQuestions() async {
    final userId = HonkersSession.instance.userId;
    if (userId.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }
    final questions = await SupabaseService.instance.getQuestionsByUser(userId);
    if (!mounted) return;
    setState(() {
      _myQuestions = questions;
      _isLoading = false;
    });
  }

  Future<void> _loadStreaksAndBadges() async {
    final userId = HonkersSession.instance.userId;
    if (userId.isEmpty) return;

    // Record today's activity and auto-award badges
    await SupabaseService.instance.recordActivity(userId);

    final results = await Future.wait([
      SupabaseService.instance.getUserStreak(userId),
      SupabaseService.instance.getUserReplyCount(userId),
      SupabaseService.instance.getUserBadges(userId),
    ]);

    if (!mounted) return;
    setState(() {
      _streak = results[0] as int;
      _replyCount = results[1] as int;
      _badges = results[2] as List<Map<String, dynamic>>;
    });
  }

  List<Map<String, dynamic>> get _myQuestionMaps {
    return _myQuestions.map((q) {
      final createdAt = q['created_at'] != null
          ? DateTime.tryParse(q['created_at'] as String)
          : null;
      return {
        'id': q['id'],
        'title': q['title'] ?? '',
        'status': q['status'] ?? 'pending',
        'replyCount': q['reply_count'] ?? 0,
        'timeAgo': createdAt != null ? _timeAgo(createdAt) : '',
      };
    }).toList();
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  void _showShareSheet() {
    const inviteLink = 'https://honkers3397.builtwithrocket.new';
    const inviteMessage =
        '🦆 Join me on Honkers.in — the community for Ahmedabad! Ask questions, share knowledge, and connect with locals.\n\n$inviteLink';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProfileShareBottomSheet(
        inviteLink: inviteLink,
        inviteMessage: inviteMessage,
      ),
    );
  }

  void _openEditSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditProfileBottomSheetWidget(
        initialName: _name,
        initialBio: _bio,
        onSave: (name, bio) async {
          final userId = HonkersSession.instance.userId;
          if (userId.isNotEmpty) {
            await SupabaseService.instance.updateUserProfile(
              userId: userId,
              fullName: name,
              bio: bio,
            );
          }
          HonkersSession.instance.updateProfile(fullName: name, bio: bio);
          if (mounted) {
            setState(() {
              _name = name;
              _bio = bio;
            });
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayQuestions = _myQuestionMaps;
    final approvedCount = displayQuestions
        .where((q) => q['status'] == 'approved')
        .length;
    final pendingCount = displayQuestions
        .where((q) => q['status'] == 'pending')
        .length;
    final totalReplies = displayQuestions.fold<int>(
      0,
      (sum, q) => sum + (q['replyCount'] as int),
    );

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  children: [
                    Text(
                      'Profile',
                      style: GoogleFonts.dmSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () => context.push(AppRoutes.dashboardScreen),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.goldSurface,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: AppTheme.gold.withAlpha(120),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.bar_chart_rounded,
                                  size: 13,
                                  color: AppTheme.gold,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'Dashboard',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.gold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () =>
                              context.push(AppRoutes.topContributorsScreen),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.goldSurface,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: AppTheme.gold.withAlpha(120),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.emoji_events_rounded,
                                  size: 13,
                                  color: AppTheme.gold,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'Leaders',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.gold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => context.push(AppRoutes.helpCenterScreen),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.goldSurface,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: AppTheme.gold.withAlpha(120),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.help_outline_rounded,
                                  size: 13,
                                  color: AppTheme.gold,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'Help',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.gold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () =>
                              context.push(AppRoutes.adminReviewScreen),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.goldSurface,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: AppTheme.gold.withAlpha(120),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.admin_panel_settings_rounded,
                                  size: 13,
                                  color: AppTheme.gold,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'Admin',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.gold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _showShareSheet,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.goldSurface,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: AppTheme.gold.withAlpha(120),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.share_rounded,
                                  size: 13,
                                  color: AppTheme.gold,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'Invite',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.gold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => context.push(
                            AppRoutes.notificationSettingsScreen,
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.goldSurface,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: AppTheme.gold.withAlpha(120),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.notifications_outlined,
                                  size: 13,
                                  color: AppTheme.gold,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'Notifs',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.gold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _openEditSheet,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceVariantDark,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: AppTheme.gold.withAlpha(102),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.edit_rounded,
                                  size: 13,
                                  color: AppTheme.gold,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'Edit Profile',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.gold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(child: _buildProfileHeader()),
            SliverToBoxAdapter(
              child: _buildStatsRow(approvedCount, pendingCount, totalReplies),
            ),

            // ── Streak & Social Proof Section ──
            SliverToBoxAdapter(child: _buildStreakAndBadgesSection()),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 10),
                child: Row(
                  children: [
                    Text(
                      'My Questions',
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.goldSurface,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${displayQuestions.length}',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.gold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (_isLoading)
              const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(
                      color: AppTheme.gold,
                      strokeWidth: 2,
                    ),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final q = displayQuestions[index];
                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: Duration(milliseconds: 250 + index * 60),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) => Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 16 * (1 - value)),
                        child: child,
                      ),
                    ),
                    child: MyQuestionItemWidget(question: q),
                  );
                }, childCount: displayQuestions.length),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakAndBadgesSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Streak Card ──
          _StreakCard(streak: _streak, replyCount: _replyCount),
          const SizedBox(height: 12),
          // ── Badges ──
          if (_badges.isNotEmpty) ...[
            Row(
              children: [
                Text(
                  'Badges',
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.goldSurface,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${_badges.length}',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.gold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _badges.map((b) => _BadgeChip(badge: b)).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.gold.withAlpha(51)),
        gradient: LinearGradient(
          colors: [AppTheme.surfaceDark, AppTheme.gold.withAlpha(13)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.gold, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.gold.withAlpha(64),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: _avatarUrl != null && _avatarUrl.isNotEmpty
                      ? CustomImageWidget(
                          imageUrl: _avatarUrl,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          semanticLabel:
                              'Profile photo of $_name, Ahmedabad community member',
                        )
                      : Container(
                          color: AppTheme.surfaceVariantDark,
                          child: const Icon(
                            Icons.person_rounded,
                            color: AppTheme.textMuted,
                            size: 40,
                          ),
                        ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppTheme.gold,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.surfaceDark, width: 2),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 12,
                    color: Color(0xFF0A0A0A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _name,
            style: GoogleFonts.dmSans(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '+91 $_phone',
            style: GoogleFonts.dmSans(fontSize: 13, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 10),
          if (_bio.isNotEmpty)
            Text(
              _bio,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.45,
              ),
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.goldSurface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppTheme.gold.withAlpha(102), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.location_city_rounded,
                  size: 14,
                  color: AppTheme.gold,
                ),
                const SizedBox(width: 6),
                Text(
                  'AhmedabadHonkers Member',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.gold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(int approved, int pending, int totalReplies) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          _StatCard(
            value: '$approved',
            label: 'Approved',
            color: AppTheme.approved,
          ),
          const SizedBox(width: 8),
          _StatCard(value: '$pending', label: 'Pending', color: AppTheme.gold),
          const SizedBox(width: 8),
          _StatCard(
            value: '$totalReplies',
            label: 'Replies\nReceived',
            color: AppTheme.textSecondary,
          ),
        ],
      ),
    );
  }
}

// ── Streak Card ──────────────────────────────────────────────────────────────

class _StreakCard extends StatelessWidget {
  final int streak;
  final int replyCount;

  const _StreakCard({required this.streak, required this.replyCount});

  String get _replyMilestoneLabel {
    if (replyCount >= 50) return '50+ Replies';
    if (replyCount >= 10) return '10+ Replies';
    if (replyCount >= 1) return 'First Reply';
    return 'No replies yet';
  }

  Color get _replyMilestoneColor {
    if (replyCount >= 50) return const Color(0xFFFFD700);
    if (replyCount >= 10) return const Color(0xFFFFC107);
    if (replyCount >= 1) return const Color(0xFFB8860B);
    return AppTheme.textMuted;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.gold.withAlpha(51)),
        gradient: LinearGradient(
          colors: [AppTheme.surfaceDark, AppTheme.gold.withAlpha(18)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          // Streak
          Expanded(
            child: _SocialProofTile(
              icon: Icons.local_fire_department_rounded,
              iconColor: streak > 0
                  ? const Color(0xFFFF6B35)
                  : AppTheme.textMuted,
              value: '$streak',
              label: streak == 1 ? 'Day Streak' : 'Day Streak',
              sublabel: streak == 0
                  ? 'Start today!'
                  : streak >= 7
                  ? '🔥 On fire!'
                  : 'Keep going!',
            ),
          ),
          Container(width: 1, height: 48, color: AppTheme.gold.withAlpha(40)),
          // Reply milestone
          Expanded(
            child: _SocialProofTile(
              icon: Icons.chat_bubble_rounded,
              iconColor: replyCount > 0
                  ? _replyMilestoneColor
                  : AppTheme.textMuted,
              value: '$replyCount',
              label: 'Replies Given',
              sublabel: _replyMilestoneLabel,
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialProofTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final String sublabel;

  const _SocialProofTile({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.sublabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 6),
            Text(
              value,
              style: GoogleFonts.dmSans(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
                fontFeatures: [const FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppTheme.textMuted,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          sublabel,
          style: GoogleFonts.dmSans(
            fontSize: 10,
            color: iconColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ── Badge Chip ───────────────────────────────────────────────────────────────

class _BadgeChip extends StatelessWidget {
  final Map<String, dynamic> badge;

  const _BadgeChip({required this.badge});

  IconData _iconForKey(String key) {
    if (key.startsWith('streak_')) return Icons.local_fire_department_rounded;
    if (key.startsWith('reply_')) return Icons.chat_bubble_rounded;
    if (key.startsWith('approved_')) return Icons.verified_rounded;
    return Icons.star_rounded;
  }

  Color _colorForKey(String key) {
    if (key.startsWith('streak_')) return const Color(0xFFFF6B35);
    if (key.startsWith('reply_')) return const Color(0xFF4FC3F7);
    if (key.startsWith('approved_')) return AppTheme.gold;
    return AppTheme.gold;
  }

  @override
  Widget build(BuildContext context) {
    final key = badge['badge_key'] as String? ?? '';
    final label = badge['badge_label'] as String? ?? '';
    final iconColor = _colorForKey(key);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: iconColor.withAlpha(20),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: iconColor.withAlpha(80)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_iconForKey(key), size: 13, color: iconColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: iconColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileShareBottomSheet extends StatelessWidget {
  final String inviteLink;
  final String inviteMessage;

  const _ProfileShareBottomSheet({
    required this.inviteLink,
    required this.inviteMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: Color(0xFFD4AF37), width: 1)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFF3A3A3A),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(
                Icons.people_alt_rounded,
                color: Color(0xFFD4AF37),
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                'Invite Friends to Honkers',
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Grow the Ahmedabad community — share your invite link!',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: const Color(0xFF888888),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF2A2A2A)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    inviteLink,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: const Color(0xFFD4AF37),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _ProfileShareOption(
                  icon: Icons.chat_rounded,
                  label: 'WhatsApp',
                  color: const Color(0xFF25D366),
                  onTap: () {
                    Navigator.pop(context);
                    SharePlus.instance.share(ShareParams(text: inviteMessage));
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ProfileShareOption(
                  icon: Icons.sms_rounded,
                  label: 'SMS',
                  color: const Color(0xFF4A90E2),
                  onTap: () {
                    Navigator.pop(context);
                    SharePlus.instance.share(ShareParams(text: inviteMessage));
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ProfileShareOption(
                  icon: Icons.copy_rounded,
                  label: 'Copy Link',
                  color: const Color(0xFFD4AF37),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: inviteLink));
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Invite link copied!',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        backgroundColor: const Color(0xFFD4AF37),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context);
                SharePlus.instance.share(ShareParams(text: inviteMessage));
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFD4AF37), Color(0xFFB8960C)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.share_rounded,
                      color: Colors.black,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Share via Other Apps',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileShareOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ProfileShareOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(80)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stat Card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF2A2A2A)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.dmSans(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: color,
                fontFeatures: [const FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppTheme.textMuted,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
