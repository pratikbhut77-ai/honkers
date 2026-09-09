import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Set<int> _expandedFaq = {};
  final Set<int> _expandedTrouble = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildGuidelinesTab(),
                  _buildTroubleshootingTab(),
                  _buildFaqTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2A2A2A)),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Help Center',
                style: GoogleFonts.dmSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                'Guidelines, tips & answers',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.goldSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.gold.withAlpha(80)),
            ),
            child: const Icon(
              Icons.help_outline_rounded,
              size: 18,
              color: AppTheme.gold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2A2A2A)),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: AppTheme.gold,
            borderRadius: BorderRadius.circular(10),
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
          labelColor: const Color(0xFF0A0A0A),
          unselectedLabelColor: AppTheme.textMuted,
          padding: const EdgeInsets.all(3),
          tabs: const [
            Tab(text: 'Guidelines'),
            Tab(text: 'Troubleshoot'),
            Tab(text: 'FAQ'),
          ],
        ),
      ),
    );
  }

  // ─── GUIDELINES TAB ───────────────────────────────────────────

  Widget _buildGuidelinesTab() {
    final guidelines = [
      _GuidelineItem(
        icon: Icons.handshake_rounded,
        color: AppTheme.gold,
        title: 'Be Respectful',
        body:
            'Treat every member with courtesy. Disagreements are fine — personal attacks, insults, or harassment are not. Assume good intent before responding.',
      ),
      _GuidelineItem(
        icon: Icons.lightbulb_outline_rounded,
        color: const Color(0xFF4FC3F7),
        title: 'Ask Clear Questions',
        body:
            'Include enough context so others can help effectively. Describe what you\'ve already tried, share relevant details, and use a descriptive title.',
      ),
      _GuidelineItem(
        icon: Icons.verified_rounded,
        color: const Color(0xFF66BB6A),
        title: 'Share Accurate Information',
        body:
            'Only post answers you\'re confident about. If you\'re unsure, say so. Misinformation harms the community — quality matters more than speed.',
      ),
      _GuidelineItem(
        icon: Icons.search_rounded,
        color: const Color(0xFFBA68C8),
        title: 'Search Before Posting',
        body:
            'Use the search bar to check if your question has already been answered. Duplicate questions dilute the knowledge base and slow down responses.',
      ),
      _GuidelineItem(
        icon: Icons.flag_outlined,
        color: const Color(0xFFEF5350),
        title: 'Report, Don\'t Retaliate',
        body:
            'If you see content that violates these guidelines, use the report button. Do not engage in arguments — let the moderation team handle it.',
      ),
      _GuidelineItem(
        icon: Icons.workspace_premium_rounded,
        color: AppTheme.goldLight,
        title: 'Earn Your Reputation',
        body:
            'Approvals, streaks, and badges reflect genuine contribution. Gaming the system undermines trust for everyone. Authentic participation is always rewarded.',
      ),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        _sectionLabel('Community Standards'),
        const SizedBox(height: 12),
        ...guidelines.map((g) => _buildGuidelineCard(g)),
        const SizedBox(height: 16),
        _buildInfoBanner(
          icon: Icons.gavel_rounded,
          text:
              'Repeated violations may result in content removal or account suspension. Our moderation team reviews all reports.',
        ),
      ],
    );
  }

  Widget _buildGuidelineCard(_GuidelineItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: item.color.withAlpha(25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, size: 20, color: item.color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.body,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── TROUBLESHOOTING TAB ──────────────────────────────────────

  Widget _buildTroubleshootingTab() {
    final items = [
      _TroubleItem(
        title: 'My question isn\'t getting replies',
        steps: [
          'Make sure your title clearly describes the problem.',
          'Add more context in the body — include what you\'ve tried.',
          'Check if a similar question already has answers you can use.',
          'Try re-posting during peak hours (evenings and weekends).',
          'Use relevant tags so experts in that area can find your question.',
        ],
      ),
      _TroubleItem(
        title: 'My reply was removed',
        steps: [
          'Review the community guidelines — your reply may have violated them.',
          'Replies flagged by multiple members are reviewed by moderators.',
          'Ensure your answer is accurate and adds value to the discussion.',
          'Avoid posting duplicate or off-topic responses.',
          'If you believe it was removed in error, contact a moderator.',
        ],
      ),
      _TroubleItem(
        title: 'I can\'t upload a photo',
        steps: [
          'Check that the image is under 5 MB in size.',
          'Supported formats: JPG, PNG, and WEBP.',
          'Ensure you\'ve granted the app camera/storage permissions.',
          'Try a different image or restart the app and try again.',
          'If the issue persists, try on a different network connection.',
        ],
      ),
      _TroubleItem(
        title: 'My streak reset unexpectedly',
        steps: [
          'Streaks require at least one activity per calendar day.',
          'Activity includes posting a question, reply, or approving an answer.',
          'Timezone differences may affect the day boundary — use local time.',
          'Streaks are calculated at midnight — ensure you\'re active before then.',
        ],
      ),
      _TroubleItem(
        title: 'I\'m not receiving notifications',
        steps: [
          'Check that notifications are enabled in your device settings.',
          'Ensure the app has notification permissions granted.',
          'Notifications appear when someone replies to your question.',
          'Self-replies do not trigger notifications.',
          'Try logging out and back in to refresh the notification subscription.',
        ],
      ),
      _TroubleItem(
        title: 'My badge isn\'t showing',
        steps: [
          'Badges are awarded automatically — visit your profile to trigger a refresh.',
          'Streak badges require 3, 7, or 30 consecutive active days.',
          'Reply badges unlock at 1, 10, and 50 total replies given.',
          'Approval badges unlock when your replies are approved 1, 5, or 10 times.',
          'Pull down to refresh the profile screen if a badge seems missing.',
        ],
      ),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        _sectionLabel('Common Issues'),
        const SizedBox(height: 12),
        ...items.asMap().entries.map((e) => _buildTroubleCard(e.key, e.value)),
      ],
    );
  }

  Widget _buildTroubleCard(int index, _TroubleItem item) {
    final isExpanded = _expandedTrouble.contains(index);
    return GestureDetector(
      onTap: () => setState(() {
        if (isExpanded) {
          _expandedTrouble.remove(index);
        } else {
          _expandedTrouble.add(index);
        }
      }),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isExpanded
                ? AppTheme.gold.withAlpha(80)
                : const Color(0xFF2A2A2A),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isExpanded
                          ? AppTheme.goldSurface
                          : const Color(0xFF242424),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.build_circle_outlined,
                      size: 16,
                      color: isExpanded ? AppTheme.gold : AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.title,
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isExpanded
                            ? AppTheme.textPrimary
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: isExpanded ? AppTheme.gold : AppTheme.textMuted,
                  ),
                ],
              ),
            ),
            if (isExpanded) ...[
              const Divider(height: 1, color: Color(0xFF2A2A2A)),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: item.steps.asMap().entries.map((e) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            margin: const EdgeInsets.only(top: 1),
                            decoration: BoxDecoration(
                              color: AppTheme.goldSurface,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${e.key + 1}',
                                style: GoogleFonts.dmSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.gold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              e.value,
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: AppTheme.textSecondary,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── FAQ TAB ──────────────────────────────────────────────────

  Widget _buildFaqTab() {
    final faqs = [
      _FaqItem(
        q: 'How do I get my question approved?',
        a: 'Questions are reviewed by community moderators. Ensure your question is clear, on-topic, and not a duplicate. Most questions are reviewed within 24 hours.',
      ),
      _FaqItem(
        q: 'What does "approval rate" mean?',
        a: 'Your approval rate is the percentage of your replies that have been marked as helpful or approved by the question author or moderators. A higher rate signals trusted expertise.',
      ),
      _FaqItem(
        q: 'Can I edit or delete my question after posting?',
        a: 'Currently, questions cannot be edited after submission. If you need a correction, you can add a follow-up reply to your own question with the updated information.',
      ),
      _FaqItem(
        q: 'How are top contributors ranked?',
        a: 'The leaderboard ranks members by reply count, question count, and approval rate across three separate tabs. Rankings update in real time as activity occurs.',
      ),
      _FaqItem(
        q: 'What happens when I report content?',
        a: 'Reports are sent to the moderation team for review. You\'ll see a confirmation that your report was submitted. The reported content remains visible until a moderator takes action.',
      ),
      _FaqItem(
        q: 'How do I earn the "30-day streak" badge?',
        a: 'Be active every single day for 30 consecutive days. Any activity counts — posting a question, giving a reply, or approving an answer. Missing one day resets the streak.',
      ),
      _FaqItem(
        q: 'Is my phone number visible to other members?',
        a: 'No. Your phone number is used only for account identification and is never displayed publicly. Only your name, bio, and avatar are visible to other community members.',
      ),
      _FaqItem(
        q: 'How do I change my profile photo?',
        a: 'Tap the edit icon on your Profile screen. You can upload a new photo from your camera or gallery. Photos are stored securely and only used for your community profile.',
      ),
      _FaqItem(
        q: 'Why can\'t I see the Admin Review screen?',
        a: 'The Admin Review and Content Moderation screens are only accessible to users with admin privileges. If you believe you should have access, contact a community administrator.',
      ),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        _sectionLabel('Frequently Asked Questions'),
        const SizedBox(height: 12),
        ...faqs.asMap().entries.map((e) => _buildFaqCard(e.key, e.value)),
        const SizedBox(height: 16),
        _buildInfoBanner(
          icon: Icons.forum_outlined,
          text:
              'Still have questions? Post them in the community — our members and moderators are happy to help.',
        ),
      ],
    );
  }

  Widget _buildFaqCard(int index, _FaqItem item) {
    final isExpanded = _expandedFaq.contains(index);
    return GestureDetector(
      onTap: () => setState(() {
        if (isExpanded) {
          _expandedFaq.remove(index);
        } else {
          _expandedFaq.add(index);
        }
      }),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isExpanded
                ? AppTheme.gold.withAlpha(80)
                : const Color(0xFF2A2A2A),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Q',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.gold,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.q,
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: isExpanded ? AppTheme.gold : AppTheme.textMuted,
                  ),
                ],
              ),
            ),
            if (isExpanded) ...[
              const Divider(height: 1, color: Color(0xFF2A2A2A)),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'A',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF66BB6A),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.a,
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: AppTheme.textSecondary,
                          height: 1.55,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── SHARED HELPERS ───────────────────────────────────────────

  Widget _sectionLabel(String label) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: AppTheme.gold,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.textMuted,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoBanner({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.goldSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.gold.withAlpha(60)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppTheme.gold),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── DATA MODELS ──────────────────────────────────────────────────────────────

class _GuidelineItem {
  final IconData icon;
  final Color color;
  final String title;
  final String body;

  const _GuidelineItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });
}

class _TroubleItem {
  final String title;
  final List<String> steps;

  const _TroubleItem({required this.title, required this.steps});
}

class _FaqItem {
  final String q;
  final String a;

  const _FaqItem({required this.q, required this.a});
}
