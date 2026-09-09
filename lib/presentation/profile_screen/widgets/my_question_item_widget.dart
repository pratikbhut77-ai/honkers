import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/status_badge_widget.dart';

class MyQuestionItemWidget extends StatelessWidget {
  final Map<String, dynamic> question;

  const MyQuestionItemWidget({required this.question, super.key});

  QuestionStatus get _status {
    switch (question['status'] as String) {
      case 'approved':
        return QuestionStatus.approved;
      case 'rejected':
        return QuestionStatus.rejected;
      default:
        return QuestionStatus.pending;
    }
  }

  @override
  Widget build(BuildContext context) {
    final replyCount = question['replyCount'] as int;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border(
          left: BorderSide(color: _statusColor, width: 3),
          top: BorderSide(color: const Color(0xFF2A2A2A), width: 1),
          right: BorderSide(color: const Color(0xFF2A2A2A), width: 1),
          bottom: BorderSide(color: const Color(0xFF2A2A2A), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusBadgeWidget(status: _status, compact: true),
              const Spacer(),
              Text(
                question['timeAgo'] as String,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            question['title'] as String,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
              height: 1.35,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (_status == QuestionStatus.rejected) ...[
            const SizedBox(height: 6),
            Text(
              'This question was not approved by the admin.',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: AppTheme.error.withAlpha(204),
              ),
            ),
          ],
          if (_status == QuestionStatus.pending) ...[
            const SizedBox(height: 6),
            Text(
              'Waiting for admin review...',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: AppTheme.gold.withAlpha(204),
              ),
            ),
          ],
          if (replyCount > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 13,
                  color: AppTheme.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  '$replyCount ${replyCount == 1 ? 'reply' : 'replies'}',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color get _statusColor {
    switch (_status) {
      case QuestionStatus.approved:
        return AppTheme.approved;
      case QuestionStatus.rejected:
        return AppTheme.rejected;
      case QuestionStatus.pending:
        return AppTheme.gold;
    }
  }
}
