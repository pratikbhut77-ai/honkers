import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../theme/app_theme.dart';
import '../../widgets/status_badge_widget.dart';
import '../../services/supabase_service.dart';
import '../../services/honkers_session.dart';
import './widgets/question_photo_strip_widget.dart';
import './widgets/reply_input_bar_widget.dart';
import './widgets/reply_item_widget.dart';

class QuestionDetailScreen extends StatefulWidget {
  final Map<String, dynamic>? question;

  const QuestionDetailScreen({this.question, super.key});

  @override
  State<QuestionDetailScreen> createState() => _QuestionDetailScreenState();
}

class _QuestionDetailScreenState extends State<QuestionDetailScreen> {
  List<Map<String, dynamic>> _replies = [];
  bool _isLoading = true;
  RealtimeChannel? _replySubscription;

  String get _questionId => widget.question?['id'] as String? ?? '';

  @override
  void initState() {
    super.initState();
    _loadReplies();
    if (_questionId.isNotEmpty) {
      _subscribeToReplies();
    }
  }

  @override
  void dispose() {
    _replySubscription?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadReplies() async {
    if (_questionId.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }
    final replies = await SupabaseService.instance.getRepliesForQuestion(
      _questionId,
    );
    if (!mounted) return;
    setState(() {
      _replies = replies;
      _isLoading = false;
    });
  }

  void _subscribeToReplies() {
    _replySubscription = SupabaseService.instance.subscribeToReplies(
      questionId: _questionId,
      onEvent: (payload) async {
        if (!mounted) return;
        final eventType = payload['eventType'] as String;
        final newRecord = payload['newRecord'] as Map<String, dynamic>?;
        final oldRecord = payload['oldRecord'] as Map<String, dynamic>?;

        if (eventType == 'INSERT' && newRecord != null) {
          // Fetch full reply with user data
          final replies = await SupabaseService.instance.getRepliesForQuestion(
            _questionId,
          );
          if (mounted) setState(() => _replies = replies);
        } else if (eventType == 'UPDATE' && newRecord != null) {
          if (mounted) {
            setState(() {
              final idx = _replies.indexWhere(
                (r) => r['id'] == newRecord['id'],
              );
              if (idx != -1) {
                _replies[idx] = {..._replies[idx], 'text': newRecord['text']};
              }
            });
          }
        } else if (eventType == 'DELETE' && oldRecord != null) {
          if (mounted) {
            setState(() {
              _replies.removeWhere((r) => r['id'] == oldRecord['id']);
            });
          }
        }
      },
    );
  }

  Future<void> _addReply(String text) async {
    final userId = HonkersSession.instance.userId;
    if (userId.isEmpty || _questionId.isEmpty) return;
    final reply = await SupabaseService.instance.addReply(
      questionId: _questionId,
      userId: userId,
      text: text,
    );
    if (reply != null && mounted) {
      // Real-time will update, but also add optimistically
      final replies = await SupabaseService.instance.getRepliesForQuestion(
        _questionId,
      );
      if (mounted) setState(() => _replies = replies);
    }
  }

  Future<void> _editReply(String id, String newText) async {
    await SupabaseService.instance.updateReply(replyId: id, text: newText);
    if (mounted) {
      setState(() {
        final idx = _replies.indexWhere((r) => r['id'] == id);
        if (idx != -1) _replies[idx] = {..._replies[idx], 'text': newText};
      });
    }
  }

  Future<void> _deleteReply(String id) async {
    await SupabaseService.instance.deleteReply(id);
    if (mounted) {
      setState(() => _replies.removeWhere((r) => r['id'] == id));
    }
  }

  Map<String, dynamic> _replyToDisplay(Map<String, dynamic> r) {
    final user = r['honkers_users'] as Map<String, dynamic>?;
    final createdAt = r['created_at'] != null
        ? DateTime.tryParse(r['created_at'] as String)
        : null;
    final currentUserId = HonkersSession.instance.userId;
    return {
      'id': r['id'],
      'author': user?['full_name'] ?? 'Honker',
      'authorUrl': user?['avatar_url'] ?? '',
      'authorSemanticLabel': 'Profile photo of ${user?['full_name'] ?? 'user'}',
      'isOwnReply': user?['id'] == currentUserId,
      'text': r['text'] ?? '',
      'timeAgo': createdAt != null ? _timeAgo(createdAt) : '',
    };
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    final status = q != null
        ? (q['status'] == 'approved'
              ? QuestionStatus.approved
              : q['status'] == 'rejected'
              ? QuestionStatus.rejected
              : QuestionStatus.pending)
        : QuestionStatus.approved;

    final displayReplies = _replies.map(_replyToDisplay).toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundDark,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariantDark,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF2A2A2A)),
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              size: 18,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        title: Text(
          'Question',
          style: GoogleFonts.dmSans(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.goldSurface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppTheme.gold.withAlpha(77)),
            ),
            child: Text(
              'AhmedabadHonkers',
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.gold,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildQuestionCard(q, status)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                    child: Row(
                      children: [
                        Text(
                          'Replies',
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
                            '${displayReplies.length}',
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
                else if (displayReplies.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 40,
                            color: AppTheme.textMuted,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No replies yet',
                            style: GoogleFonts.dmSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Be the first to help the community!',
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final r = displayReplies[index];
                      return ReplyItemWidget(
                        reply: r,
                        onEdit: (newText) =>
                            _editReply(r['id'] as String, newText),
                        onDelete: () => _deleteReply(r['id'] as String),
                      );
                    }, childCount: displayReplies.length),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
          ReplyInputBarWidget(onSubmit: _addReply),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic>? q, QuestionStatus status) {
    final createdAt = q?['created_at'] != null
        ? DateTime.tryParse(q!['created_at'] as String)
        : null;
    final timeAgo = createdAt != null
        ? _timeAgo(createdAt)
        : (q?['timeAgo'] as String? ?? '');

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.gold.withAlpha(51)),
        gradient: LinearGradient(
          colors: [AppTheme.surfaceDark, AppTheme.gold.withAlpha(10)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusBadgeWidget(status: status),
              const Spacer(),
              Text(
                timeAgo,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            q?['title'] as String? ?? 'Question Title',
            style: GoogleFonts.dmSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            q?['details'] as String? ?? 'No additional details provided.',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
          if ((q?['photo_urls'] as List?)?.isNotEmpty == true ||
              q?['hasPhoto'] == true) ...[
            const SizedBox(height: 14),
            const QuestionPhotoStripWidget(),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              ClipOval(
                child: Image.network(
                  (q?['honkers_users'] as Map?)?['avatar_url'] as String? ??
                      q?['authorUrl'] as String? ??
                      '',
                  width: 28,
                  height: 28,
                  fit: BoxFit.cover,
                  semanticLabel: 'Question author avatar',
                  errorBuilder: (_, __, ___) => Container(
                    width: 28,
                    height: 28,
                    color: AppTheme.surfaceVariantDark,
                    child: const Icon(
                      Icons.person_rounded,
                      size: 16,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                (q?['honkers_users'] as Map?)?['full_name'] as String? ??
                    q?['author'] as String? ??
                    'Community Member',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _showReportQuestionDialog(q),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.flag_outlined,
                      size: 13,
                      color: AppTheme.textMuted,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      'Report',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showReportQuestionDialog(Map<String, dynamic>? q) {
    if (q == null) return;
    final questionId = q['id'] as String?;
    if (questionId == null || questionId.isEmpty) return;

    final reasons = [
      'Spam or misleading',
      'Offensive or abusive language',
      'Harassment or bullying',
      'Misinformation',
      'Other',
    ];
    String? selectedReason;
    final otherController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.surfaceDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(Icons.flag_rounded, color: AppTheme.error, size: 18),
              const SizedBox(width: 8),
              Text(
                'Report Question',
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Why are you reporting this question?',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              ...reasons.map(
                (r) => RadioListTile<String>(
                  value: r,
                  groupValue: selectedReason,
                  onChanged: (v) => setDialogState(() => selectedReason = v),
                  title: Text(
                    r,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  activeColor: AppTheme.gold,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
              if (selectedReason == 'Other') ...[
                const SizedBox(height: 8),
                TextField(
                  controller: otherController,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: AppTheme.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Describe the issue...',
                    hintStyle: GoogleFonts.dmSans(color: AppTheme.textMuted),
                    filled: true,
                    fillColor: AppTheme.surfaceVariantDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: AppTheme.gold,
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  maxLines: 2,
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: GoogleFonts.dmSans(color: AppTheme.textMuted),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              onPressed: selectedReason == null
                  ? null
                  : () async {
                      final reason = selectedReason == 'Other'
                          ? (otherController.text.trim().isNotEmpty
                                ? otherController.text.trim()
                                : 'Other')
                          : selectedReason!;
                      Navigator.pop(ctx);
                      final reporterId = HonkersSession.instance.userId;
                      if (reporterId.isEmpty) return;
                      final ok = await SupabaseService.instance.submitReport(
                        reporterId: reporterId,
                        contentType: 'question',
                        contentId: questionId,
                        reason: reason,
                      );
                      if (ok && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Question reported. Our team will review it.',
                              style: GoogleFonts.dmSans(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            backgroundColor: AppTheme.approved,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    },
              child: Text(
                'Submit',
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
