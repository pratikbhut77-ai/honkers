import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

enum QuestionStatus { pending, approved, rejected }

class StatusBadgeWidget extends StatelessWidget {
  final QuestionStatus status;
  final bool compact;

  const StatusBadgeWidget({
    required this.status,
    this.compact = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final (label, color, bg) = switch (status) {
      QuestionStatus.pending => (
        'Pending',
        AppTheme.gold,
        AppTheme.gold.withAlpha(31),
      ),
      QuestionStatus.approved => (
        'Approved',
        AppTheme.approved,
        AppTheme.approved.withAlpha(31),
      ),
      QuestionStatus.rejected => (
        'Rejected',
        AppTheme.rejected,
        AppTheme.rejected.withAlpha(31),
      ),
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(102), width: 1),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: compact ? 10 : 11,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
