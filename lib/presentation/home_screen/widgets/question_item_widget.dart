import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/app_export.dart';

class QuestionItemWidget extends StatelessWidget {
  final Map<String, dynamic> question;
  final bool isSeen;
  final VoidCallback onTap;

  const QuestionItemWidget({
    required this.question,
    required this.isSeen,
    required this.onTap,
    super.key,
  });

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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(16),
          border: Border(
            left: BorderSide(
              color: isSeen ? const Color(0xFF2A2A2A) : AppTheme.gold,
              width: isSeen ? 1 : 3,
            ),
            top: BorderSide(color: const Color(0xFF2A2A2A), width: 1),
            right: BorderSide(color: const Color(0xFF2A2A2A), width: 1),
            bottom: BorderSide(color: const Color(0xFF2A2A2A), width: 1),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: status badge + time
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
              const SizedBox(height: 10),

              // Title
              Text(
                question['title'] as String,
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: isSeen ? FontWeight.w500 : FontWeight.w700,
                  color: isSeen ? AppTheme.textSecondary : AppTheme.textPrimary,
                  height: 1.35,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),

              // Details preview
              Text(
                question['details'] as String,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: AppTheme.textMuted,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Bottom row: author + reply count
              Row(
                children: [
                  // Author avatar
                  ClipOval(
                    child: CustomImageWidget(
                      imageUrl: question['authorUrl'] as String,
                      width: 24,
                      height: 24,
                      fit: BoxFit.cover,
                      semanticLabel: question['authorSemanticLabel'] as String,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    question['author'] as String,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  // Photo indicator
                  if (question['hasPhoto'] == true) ...[
                    const Icon(
                      Icons.photo_outlined,
                      size: 13,
                      color: AppTheme.textMuted,
                    ),
                    const SizedBox(width: 8),
                  ],
                  // Reply count
                  const Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 13,
                    color: AppTheme.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${question['replyCount']}',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                      fontFeatures: [const FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}