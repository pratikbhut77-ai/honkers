import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state_widget.dart';
import '../../services/supabase_service.dart';
import '../home_screen/widgets/question_item_widget.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  List<Map<String, dynamic>> _results = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _isSearching = false;
      });
      return;
    }
    setState(() => _isSearching = true);
    final results = await SupabaseService.instance.searchApprovedQuestions(
      query.trim(),
    );
    if (!mounted) return;
    setState(() {
      _results = results;
      _isSearching = false;
    });
  }

  Map<String, dynamic> _mapToDisplay(Map<String, dynamic> q) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  Text(
                    'Search',
                    style: GoogleFonts.dmSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
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
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceVariantDark,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _query.isNotEmpty
                        ? AppTheme.gold.withAlpha(128)
                        : const Color(0xFF2A2A2A),
                    width: _query.isNotEmpty ? 1.5 : 1,
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  autofocus: false,
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    color: AppTheme.textPrimary,
                  ),
                  onChanged: (v) {
                    setState(() => _query = v);
                    _performSearch(v);
                  },
                  decoration: InputDecoration(
                    hintText: 'Search questions in AhmedabadHonkers...',
                    hintStyle: GoogleFonts.dmSans(
                      fontSize: 14,
                      color: AppTheme.textMuted,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppTheme.gold,
                      size: 20,
                    ),
                    suffixIcon: _query.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              setState(() {
                                _query = '';
                                _results = [];
                              });
                            },
                            child: const Icon(
                              Icons.close_rounded,
                              color: AppTheme.textMuted,
                              size: 18,
                            ),
                          )
                        : null,
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(child: _buildResults()),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_query.trim().isEmpty) {
      return _buildSearchPrompt();
    }

    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.gold, strokeWidth: 2),
      );
    }

    final displayResults = _results.map(_mapToDisplay).toList();

    if (displayResults.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.search_off_rounded,
        title: 'No results found',
        subtitle:
            'No approved questions match "$_query". Try different keywords or ask the community.',
        ctaLabel: 'Ask this Question',
        onCta: () => context.push(AppRoutes.askAQuestionScreen),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
      itemCount: displayResults.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final q = displayResults[index];
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 250 + index * 40),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 12 * (1 - value)),
              child: child,
            ),
          ),
          child: QuestionItemWidget(
            question: q,
            isSeen: false,
            onTap: () => context.push(
              AppRoutes.questionDetailScreen,
              extra: _results[index],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchPrompt() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Popular Topics',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.textSecondary,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                [
                  'Food & Restaurants',
                  'Healthcare',
                  'Education',
                  'Transport',
                  'Home Services',
                  'Shopping',
                  'Events',
                  'Local Tips',
                ].map((topic) {
                  return GestureDetector(
                    onTap: () {
                      _searchController.text = topic;
                      setState(() => _query = topic);
                      _performSearch(topic);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceVariantDark,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: const Color(0xFF2A2A2A),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        topic,
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
          const SizedBox(height: 28),
          Text(
            'Recent Searches',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.textSecondary,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 12),
          ...[
            'misal pav Navrangpura',
            'dentist Bopal',
            'GST CA SG Highway',
          ].map((recent) {
            return GestureDetector(
              onTap: () {
                _searchController.text = recent;
                setState(() => _query = recent);
                _performSearch(recent);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    const Icon(
                      Icons.history_rounded,
                      size: 16,
                      color: AppTheme.textMuted,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      recent,
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.north_west_rounded,
                      size: 14,
                      color: AppTheme.textMuted,
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
