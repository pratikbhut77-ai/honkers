import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/loading_skeleton_widget.dart';
import '../../widgets/custom_image_widget.dart';
import '../../services/supabase_service.dart';
import '../../services/honkers_session.dart';
import './widgets/community_header_widget.dart';
import './widgets/feed_tab_toggle_widget.dart';
import './widgets/question_item_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showUnseen = true;
  bool _isLoading = true;
  Set<String> _seenIds = {};
  List<Map<String, dynamic>> _questions = [];
  int _memberCount = 0;
  RealtimeChannel? _subscription;

  @override
  void initState() {
    super.initState();
    _loadData();
    _subscribeToQuestions();
  }

  @override
  void dispose() {
    _subscription?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final userId = HonkersSession.instance.userId;
    final results = await Future.wait([
      SupabaseService.instance.getApprovedQuestions(),
      SupabaseService.instance.getMemberCount(),
      userId.isNotEmpty
          ? SupabaseService.instance.getSeenQuestionIds(userId)
          : Future.value(<String>{}),
    ]);
    if (!mounted) return;
    setState(() {
      _questions = results[0] as List<Map<String, dynamic>>;
      _memberCount = results[1] as int;
      _seenIds = results[2] as Set<String>;
      _isLoading = false;
    });
  }

  void _subscribeToQuestions() {
    _subscription = SupabaseService.instance.subscribeToQuestions((
      payload,
    ) async {
      if (!mounted) return;
      final eventType = payload['eventType'] as String;
      final newRecord = payload['newRecord'] as Map<String, dynamic>?;
      final oldRecord = payload['oldRecord'] as Map<String, dynamic>?;

      if (eventType == 'INSERT' &&
          newRecord != null &&
          newRecord['status'] == 'approved') {
        // Fetch full question with user data
        final questions = await SupabaseService.instance.getApprovedQuestions();
        if (mounted) setState(() => _questions = questions);
      } else if (eventType == 'UPDATE' && newRecord != null) {
        if (newRecord['status'] == 'approved') {
          final questions = await SupabaseService.instance
              .getApprovedQuestions();
          if (mounted) setState(() => _questions = questions);
        } else {
          // Remove from list if no longer approved
          if (mounted) {
            setState(() {
              _questions.removeWhere((q) => q['id'] == newRecord['id']);
            });
          }
        }
      } else if (eventType == 'DELETE' && oldRecord != null) {
        if (mounted) {
          setState(() {
            _questions.removeWhere((q) => q['id'] == oldRecord['id']);
          });
        }
      }
    });
  }

  List<Map<String, dynamic>> get _filteredQuestions {
    if (_showUnseen) {
      return _questions.where((q) => !_seenIds.contains(q['id'])).toList();
    } else {
      return _questions.where((q) => _seenIds.contains(q['id'])).toList();
    }
  }

  void _openQuestion(Map<String, dynamic> q) {
    final qId = q['id'] as String;
    final userId = HonkersSession.instance.userId;
    setState(() => _seenIds.add(qId));
    if (userId.isNotEmpty) {
      SupabaseService.instance.markQuestionSeen(
        userId: userId,
        questionId: qId,
      );
    }
    context.push(AppRoutes.questionDetailScreen, extra: q);
  }

  @override
  Widget build(BuildContext context) {
    final unseenCount = _questions
        .where((q) => !_seenIds.contains(q['id']))
        .length;

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildAppBar(context),
            CommunityHeaderWidget(memberCount: _memberCount),
            const SizedBox(height: 12),
            FeedTabToggleWidget(
              showUnseen: _showUnseen,
              unseenCount: unseenCount,
              onToggle: (v) => setState(() => _showUnseen = v),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: _isLoading
                  ? const QuestionFeedSkeletonWidget()
                  : _buildFeed(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Honkers',
                  style: GoogleFonts.dmSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.gold,
                    letterSpacing: -0.3,
                  ),
                ),
                TextSpan(
                  text: '.in',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          _AppBarIconButton(
            icon: Icons.local_fire_department_rounded,
            onTap: () => context.push(AppRoutes.trendingDiscussionsScreen),
          ),
          const SizedBox(width: 8),
          _AppBarIconButton(
            icon: Icons.share_rounded,
            onTap: () => _showShareSheet(context),
          ),
          const SizedBox(width: 8),
          _AppBarIconButton(
            icon: Icons.search_rounded,
            onTap: () => context.go(AppRoutes.searchScreen),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => context.go(AppRoutes.profileScreen),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.gold.withAlpha(153),
                  width: 1.5,
                ),
              ),
              child: ClipOval(
                child: HonkersSession.instance.avatarUrl != null
                    ? CustomImageWidget(
                        imageUrl: HonkersSession.instance.avatarUrl!,
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                        semanticLabel: 'Your profile photo',
                      )
                    : Container(
                        color: AppTheme.surfaceVariantDark,
                        child: const Icon(
                          Icons.person_rounded,
                          color: AppTheme.textMuted,
                          size: 20,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showShareSheet(BuildContext context) {
    const inviteLink = 'https://honkers3397.builtwithrocket.new';
    const inviteMessage =
        '🦆 Join me on Honkers.in — the community for Ahmedabad! Ask questions, share knowledge, and connect with locals.\n\n$inviteLink';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ShareBottomSheet(
        inviteLink: inviteLink,
        inviteMessage: inviteMessage,
      ),
    );
  }

  Widget _buildFeed() {
    final items = _filteredQuestions;
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _showUnseen
                  ? Icons.check_circle_outline_rounded
                  : Icons.history_rounded,
              size: 56,
              color: AppTheme.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              _showUnseen ? 'You\'re all caught up!' : 'No seen questions yet',
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _showUnseen
                  ? 'Come back later for new questions from Ahmedabad.'
                  : 'Questions you open will appear here.',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: AppTheme.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppTheme.gold,
      backgroundColor: AppTheme.surfaceDark,
      onRefresh: _loadData,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final q = items[index];
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 300 + index * 50),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) => Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: child,
              ),
            ),
            child: QuestionItemWidget(
              question: _mapToQuestionDisplay(q),
              isSeen: _seenIds.contains(q['id']),
              onTap: () => _openQuestion(q),
            ),
          );
        },
      ),
    );
  }

  Map<String, dynamic> _mapToQuestionDisplay(Map<String, dynamic> q) {
    final user = q['honkers_users'] as Map<String, dynamic>?;
    final createdAt = q['created_at'] != null
        ? DateTime.tryParse(q['created_at'] as String)
        : null;
    return {
      'id': q['id'],
      'title': q['title'] ?? '',
      'details': q['details'] ?? '',
      'status': q['status'] ?? 'approved',
      'author': user?['full_name'] ?? 'Honker',
      'authorUrl': user?['avatar_url'] ?? '',
      'authorSemanticLabel': 'Profile photo of ${user?['full_name'] ?? 'user'}',
      'replyCount': q['reply_count'] ?? 0,
      'timeAgo': createdAt != null ? _timeAgo(createdAt) : '',
      'hasPhoto': ((q['photo_urls'] as List?)?.isNotEmpty) ?? false,
    };
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _AppBarIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _AppBarIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariantDark,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF2A2A2A)),
        ),
        child: Icon(icon, size: 18, color: AppTheme.textSecondary),
      ),
    );
  }
}

class _ShareBottomSheet extends StatelessWidget {
  final String inviteLink;
  final String inviteMessage;

  const _ShareBottomSheet({
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
          // Link preview box
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
                child: _ShareOptionButton(
                  icon: Icons.chat_rounded,
                  label: 'WhatsApp',
                  color: const Color(0xFF25D366),
                  onTap: () {
                    Navigator.pop(context);
                    final encoded = Uri.encodeComponent(inviteMessage);
                    final uri = Uri.parse('https://wa.me/?text=$encoded');
                    SharePlus.instance.share(ShareParams(text: inviteMessage));
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ShareOptionButton(
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
                child: _ShareOptionButton(
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

class _ShareOptionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ShareOptionButton({
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
