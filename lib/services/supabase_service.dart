import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._();

  SupabaseService._();

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static Future<void> initialize() async {
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw Exception(
        'SUPABASE_URL and SUPABASE_ANON_KEY must be defined using --dart-define.',
      );
    }
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }

  SupabaseClient get client => Supabase.instance.client;

  // ─── USER METHODS ─────────────────────────────────────────────────────────

  /// Get or create a user by phone number. Returns the user map.
  Future<Map<String, dynamic>?> getOrCreateUser({
    required String phone,
    String fullName = '',
  }) async {
    try {
      final existing = await client
          .from('honkers_users')
          .select()
          .eq('phone', phone)
          .maybeSingle();
      if (existing != null) return existing;

      final created = await client
          .from('honkers_users')
          .insert({
            'phone': phone,
            'full_name': fullName.isNotEmpty ? fullName : 'Honker',
          })
          .select()
          .single();
      return created;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getUserByPhone(String phone) async {
    try {
      return await client
          .from('honkers_users')
          .select()
          .eq('phone', phone)
          .maybeSingle();
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getUserById(String userId) async {
    try {
      return await client
          .from('honkers_users')
          .select()
          .eq('id', userId)
          .maybeSingle();
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateUserProfile({
    required String userId,
    required String fullName,
    required String bio,
    String? avatarUrl,
  }) async {
    try {
      final data = <String, dynamic>{'full_name': fullName, 'bio': bio};
      if (avatarUrl != null) data['avatar_url'] = avatarUrl;
      await client.from('honkers_users').update(data).eq('id', userId);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<int> getMemberCount() async {
    try {
      final response = await client
          .from('honkers_users')
          .select('id')
          .count(CountOption.exact);
      return response.count;
    } catch (e) {
      return 0;
    }
  }

  // ─── QUESTION METHODS ─────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getApprovedQuestions() async {
    try {
      final response = await client
          .from('honkers_questions')
          .select('*, honkers_users(id, full_name, avatar_url, phone)')
          .eq('status', 'approved')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAllQuestions() async {
    try {
      final response = await client
          .from('honkers_questions')
          .select('*, honkers_users(id, full_name, avatar_url, phone)')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getQuestionsByUser(String userId) async {
    try {
      final response = await client
          .from('honkers_questions')
          .select('*, honkers_users(id, full_name, avatar_url, phone)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> submitQuestion({
    required String userId,
    required String title,
    required String details,
    List<String> photoUrls = const [],
  }) async {
    try {
      final response = await client
          .from('honkers_questions')
          .insert({
            'user_id': userId,
            'title': title,
            'details': details,
            'photo_urls': photoUrls,
            'status': 'pending',
          })
          .select()
          .single();
      return response;
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateQuestionStatus({
    required String questionId,
    required String status,
  }) async {
    try {
      await client
          .from('honkers_questions')
          .update({'status': status})
          .eq('id', questionId);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> searchApprovedQuestions(
    String query,
  ) async {
    try {
      final q = query.toLowerCase();
      final response = await client
          .from('honkers_questions')
          .select('*, honkers_users(id, full_name, avatar_url, phone)')
          .eq('status', 'approved')
          .or('title.ilike.%$q%,details.ilike.%$q%')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  // ─── REPLY METHODS ────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getRepliesForQuestion(
    String questionId,
  ) async {
    try {
      final response = await client
          .from('honkers_replies')
          .select('*, honkers_users(id, full_name, avatar_url, phone)')
          .eq('question_id', questionId)
          .order('created_at', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> addReply({
    required String questionId,
    required String userId,
    required String text,
  }) async {
    try {
      final response = await client
          .from('honkers_replies')
          .insert({'question_id': questionId, 'user_id': userId, 'text': text})
          .select('*, honkers_users(id, full_name, avatar_url, phone)')
          .single();
      return response;
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateReply({
    required String replyId,
    required String text,
  }) async {
    try {
      await client
          .from('honkers_replies')
          .update({'text': text})
          .eq('id', replyId);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteReply(String replyId) async {
    try {
      await client.from('honkers_replies').delete().eq('id', replyId);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteQuestion(String questionId) async {
    try {
      await client.from('honkers_questions').delete().eq('id', questionId);
      return true;
    } catch (e) {
      return false;
    }
  }

  // ─── REPORTS ──────────────────────────────────────────────────────────────

  Future<bool> submitReport({
    required String reporterId,
    required String contentType,
    required String contentId,
    required String reason,
  }) async {
    try {
      await client.from('honkers_reports').insert({
        'reporter_id': reporterId,
        'content_type': contentType,
        'content_id': contentId,
        'reason': reason,
        'status': 'pending',
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getReports() async {
    try {
      // Fetch reports with reporter info
      final response = await client
          .from('honkers_reports')
          .select('*, honkers_users(id, full_name)')
          .order('created_at', ascending: false);
      final reports = List<Map<String, dynamic>>.from(response);

      // Enrich each report with a content preview
      for (final report in reports) {
        final contentType = report['content_type'] as String;
        final contentId = report['content_id'] as String;
        try {
          if (contentType == 'question') {
            final q = await client
                .from('honkers_questions')
                .select('title')
                .eq('id', contentId)
                .maybeSingle();
            report['content_preview'] = q?['title'] as String? ?? '';
          } else {
            final r = await client
                .from('honkers_replies')
                .select('text')
                .eq('id', contentId)
                .maybeSingle();
            report['content_preview'] = r?['text'] as String? ?? '';
          }
        } catch (_) {
          report['content_preview'] = '[Content no longer available]';
        }
      }
      return reports;
    } catch (e) {
      return [];
    }
  }

  Future<bool> updateReportStatus({
    required String reportId,
    required String status,
    String? adminNote,
  }) async {
    try {
      final data = <String, dynamic>{
        'status': status,
        'reviewed_at': DateTime.now().toIso8601String(),
      };
      if (adminNote != null) data['admin_note'] = adminNote;
      await client.from('honkers_reports').update(data).eq('id', reportId);
      return true;
    } catch (e) {
      return false;
    }
  }

  // ─── SEEN QUESTIONS ───────────────────────────────────────────────────────

  Future<Set<String>> getSeenQuestionIds(String userId) async {
    try {
      final response = await client
          .from('honkers_seen_questions')
          .select('question_id')
          .eq('user_id', userId);
      return Set<String>.from(
        (response as List).map((r) => r['question_id'] as String),
      );
    } catch (e) {
      return {};
    }
  }

  Future<void> markQuestionSeen({
    required String userId,
    required String questionId,
  }) async {
    try {
      await client.from('honkers_seen_questions').upsert({
        'user_id': userId,
        'question_id': questionId,
      }, onConflict: 'user_id,question_id');
    } catch (e) {
      // Silently ignore
    }
  }

  // ─── DASHBOARD STATS ──────────────────────────────────────────────────────

  Future<Map<String, int>> getDashboardStats() async {
    try {
      final questionsResp = await client
          .from('honkers_questions')
          .select('status');
      final questions = List<Map<String, dynamic>>.from(questionsResp);
      final total = questions.length;
      final approved = questions.where((q) => q['status'] == 'approved').length;
      final pending = questions.where((q) => q['status'] == 'pending').length;
      final rejected = questions.where((q) => q['status'] == 'rejected').length;

      final repliesResp = await client
          .from('honkers_replies')
          .select('id')
          .count(CountOption.exact);
      final replyCount = repliesResp.count;

      final memberCount = await getMemberCount();

      // Active today: users who submitted questions today
      final today = DateTime.now();
      final todayStart = DateTime(
        today.year,
        today.month,
        today.day,
      ).toIso8601String();
      final activeTodayResp = await client
          .from('honkers_questions')
          .select('user_id')
          .gte('created_at', todayStart);
      final activeUserIds = Set<String>.from(
        (activeTodayResp as List).map((r) => r['user_id']),
      );

      // This week
      final weekStart = today
          .subtract(Duration(days: today.weekday - 1))
          .copyWith(hour: 0, minute: 0, second: 0)
          .toIso8601String();

      final questionsWeekResp = await client
          .from('honkers_questions')
          .select('id')
          .gte('created_at', weekStart);
      final questionsThisWeek = (questionsWeekResp as List).length;

      final repliesWeekResp = await client
          .from('honkers_replies')
          .select('id')
          .gte('created_at', weekStart);
      final repliesThisWeek = (repliesWeekResp as List).length;

      final membersWeekResp = await client
          .from('honkers_users')
          .select('id')
          .gte('created_at', weekStart);
      final newMembersThisWeek = (membersWeekResp as List).length;

      return {
        'totalQuestions': total,
        'approvedQuestions': approved,
        'pendingQuestions': pending,
        'rejectedQuestions': rejected,
        'replyCount': replyCount,
        'totalMembers': memberCount,
        'activeMembersToday': activeUserIds.length,
        'approvalRate': total > 0 ? ((approved / total) * 100).round() : 0,
        'questionsThisWeek': questionsThisWeek,
        'repliesThisWeek': repliesThisWeek,
        'newMembersThisWeek': newMembersThisWeek,
      };
    } catch (e) {
      return {
        'totalQuestions': 0,
        'approvedQuestions': 0,
        'pendingQuestions': 0,
        'rejectedQuestions': 0,
        'replyCount': 0,
        'totalMembers': 0,
        'activeMembersToday': 0,
        'approvalRate': 0,
        'questionsThisWeek': 0,
        'repliesThisWeek': 0,
        'newMembersThisWeek': 0,
      };
    }
  }

  // ─── TOP CONTRIBUTORS ─────────────────────────────────────────────────────

  Future<Map<String, List<Map<String, dynamic>>>> getTopContributors() async {
    try {
      // Fetch all users
      final usersResp = await client
          .from('honkers_users')
          .select('id, full_name, avatar_url');
      final users = List<Map<String, dynamic>>.from(usersResp);

      // Fetch all replies grouped by user
      final repliesResp = await client
          .from('honkers_replies')
          .select('user_id');
      final replies = List<Map<String, dynamic>>.from(repliesResp);

      // Fetch all questions grouped by user
      final questionsResp = await client
          .from('honkers_questions')
          .select('user_id, status');
      final questions = List<Map<String, dynamic>>.from(questionsResp);

      // Build per-user maps
      final replyCountMap = <String, int>{};
      for (final r in replies) {
        final uid = r['user_id'] as String? ?? '';
        if (uid.isNotEmpty) replyCountMap[uid] = (replyCountMap[uid] ?? 0) + 1;
      }

      final questionCountMap = <String, int>{};
      final approvedCountMap = <String, int>{};
      for (final q in questions) {
        final uid = q['user_id'] as String? ?? '';
        if (uid.isNotEmpty) {
          questionCountMap[uid] = (questionCountMap[uid] ?? 0) + 1;
          if (q['status'] == 'approved') {
            approvedCountMap[uid] = (approvedCountMap[uid] ?? 0) + 1;
          }
        }
      }

      // Build contributor list
      final contributors = users.map((u) {
        final uid = u['id'] as String? ?? '';
        final qCount = questionCountMap[uid] ?? 0;
        final approvedCount = approvedCountMap[uid] ?? 0;
        final approvalRate = qCount > 0
            ? ((approvedCount / qCount) * 100).round()
            : 0;
        return {
          'userId': uid,
          'fullName': u['full_name'] as String? ?? 'Unknown',
          'avatarUrl': u['avatar_url'],
          'replyCount': replyCountMap[uid] ?? 0,
          'questionCount': qCount,
          'approvalRate': approvalRate,
        };
      }).toList();

      // Sort by each metric
      final byReplies = List<Map<String, dynamic>>.from(contributors)
        ..sort(
          (a, b) => (b['replyCount'] as int).compareTo(a['replyCount'] as int),
        );

      final byQuestions = List<Map<String, dynamic>>.from(contributors)
        ..sort(
          (a, b) =>
              (b['questionCount'] as int).compareTo(a['questionCount'] as int),
        );

      // For approval rate, only include users with at least 1 question
      final byApprovalRate =
          contributors.where((c) => (c['questionCount'] as int) > 0).toList()
            ..sort(
              (a, b) => (b['approvalRate'] as int).compareTo(
                a['approvalRate'] as int,
              ),
            );

      return {
        'byReplies': byReplies,
        'byQuestions': byQuestions,
        'byApprovalRate': byApprovalRate,
      };
    } catch (e) {
      return {'byReplies': [], 'byQuestions': [], 'byApprovalRate': []};
    }
  }

  // ─── STREAKS & BADGES ─────────────────────────────────────────────────────

  /// Record today's activity for a user and auto-award any earned badges.
  Future<void> recordActivity(String userId) async {
    try {
      await client.rpc(
        'honkers_record_activity',
        params: {'p_user_id': userId},
      );
    } catch (e) {
      // Silently ignore
    }
  }

  /// Compute the current consecutive-day streak for a user.
  Future<int> getUserStreak(String userId) async {
    try {
      final response = await client
          .from('honkers_activity_log')
          .select('activity_date')
          .eq('user_id', userId)
          .order('activity_date', ascending: false)
          .limit(365);
      final dates = (response as List)
          .map((r) => DateTime.parse(r['activity_date'] as String))
          .toList();
      if (dates.isEmpty) return 0;

      int streak = 0;
      DateTime cursor = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      );

      for (final d in dates) {
        final day = DateTime(d.year, d.month, d.day);
        if (day == cursor || day == cursor.subtract(const Duration(days: 1))) {
          streak++;
          cursor = day.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }
      return streak;
    } catch (e) {
      return 0;
    }
  }

  /// Fetch all badges earned by a user.
  Future<List<Map<String, dynamic>>> getUserBadges(String userId) async {
    try {
      final response = await client
          .from('honkers_user_badges')
          .select()
          .eq('user_id', userId)
          .order('earned_at', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  /// Fetch reply count for a user (for milestone display).
  Future<int> getUserReplyCount(String userId) async {
    try {
      final response = await client
          .from('honkers_replies')
          .select('id')
          .eq('user_id', userId)
          .count(CountOption.exact);
      return response.count;
    } catch (e) {
      return 0;
    }
  }

  // ─── TRENDING DISCUSSIONS ─────────────────────────────────────────────────

  Future<Map<String, List<Map<String, dynamic>>>> getTrendingQuestions() async {
    try {
      // Fetch approved questions with user info
      final questionsResp = await client
          .from('honkers_questions')
          .select('*, honkers_users(id, full_name, avatar_url)')
          .eq('status', 'approved');
      final questions = List<Map<String, dynamic>>.from(questionsResp);

      // Fetch all replies to count per question
      final repliesResp = await client
          .from('honkers_replies')
          .select('question_id, created_at');
      final replies = List<Map<String, dynamic>>.from(repliesResp);

      // Build reply count map
      final replyCountMap = <String, int>{};
      final recentReplyCountMap = <String, int>{};
      final cutoff = DateTime.now().subtract(const Duration(days: 7));
      for (final r in replies) {
        final qid = r['question_id'] as String? ?? '';
        if (qid.isNotEmpty) {
          replyCountMap[qid] = (replyCountMap[qid] ?? 0) + 1;
          final createdAt = DateTime.tryParse(r['created_at'] as String? ?? '');
          if (createdAt != null && createdAt.isAfter(cutoff)) {
            recentReplyCountMap[qid] = (recentReplyCountMap[qid] ?? 0) + 1;
          }
        }
      }

      // Enrich questions with reply counts and engagement score
      final enriched = questions.map((q) {
        final qid = q['id'] as String? ?? '';
        final replyCount = replyCountMap[qid] ?? 0;
        final recentReplies = recentReplyCountMap[qid] ?? 0;
        // Engagement score: total replies * 1 + recent replies * 2
        final engagementScore = replyCount + (recentReplies * 2);
        return {
          ...q,
          'replyCount': replyCount,
          'engagementScore': engagementScore,
        };
      }).toList();

      // Sort by reply count
      final byReplies = List<Map<String, dynamic>>.from(enriched)
        ..sort(
          (a, b) => (b['replyCount'] as int).compareTo(a['replyCount'] as int),
        );

      // Sort by engagement score
      final byEngagement = List<Map<String, dynamic>>.from(enriched)
        ..sort(
          (a, b) => (b['engagementScore'] as int).compareTo(
            a['engagementScore'] as int,
          ),
        );

      return {
        'byReplies': byReplies.take(20).toList(),
        'byEngagement': byEngagement.take(20).toList(),
      };
    } catch (e) {
      return {'byReplies': [], 'byEngagement': []};
    }
  }

  // ─── REAL-TIME SUBSCRIPTIONS ──────────────────────────────────────────────

  RealtimeChannel subscribeToQuestions(
    void Function(Map<String, dynamic> payload) onEvent,
  ) {
    return client
        .channel('honkers_questions_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'honkers_questions',
          callback: (payload) => onEvent({
            'eventType': payload.eventType.name,
            'newRecord': payload.newRecord,
            'oldRecord': payload.oldRecord,
          }),
        )
        .subscribe();
  }

  RealtimeChannel subscribeToReplies({
    required String questionId,
    required void Function(Map<String, dynamic> payload) onEvent,
  }) {
    return client
        .channel('honkers_replies_$questionId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'honkers_replies',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'question_id',
            value: questionId,
          ),
          callback: (payload) => onEvent({
            'eventType': payload.eventType.name,
            'newRecord': payload.newRecord,
            'oldRecord': payload.oldRecord,
          }),
        )
        .subscribe();
  }

  // ─── NOTIFICATION PREFERENCES ─────────────────────────────────────────────

  Future<Map<String, dynamic>> getNotificationPreferences(String userId) async {
    try {
      final result = await client
          .from('honkers_notification_preferences')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      if (result != null) return result;
      // Return defaults if no record yet
      return {
        'notify_replies': true,
        'notify_mentions': true,
        'notify_badges': true,
        'quiet_hours_enabled': false,
        'quiet_start_hour': 22,
        'quiet_end_hour': 8,
      };
    } catch (e) {
      return {
        'notify_replies': true,
        'notify_mentions': true,
        'notify_badges': true,
        'quiet_hours_enabled': false,
        'quiet_start_hour': 22,
        'quiet_end_hour': 8,
      };
    }
  }

  Future<bool> saveNotificationPreferences({
    required String userId,
    required bool notifyReplies,
    required bool notifyMentions,
    required bool notifyBadges,
    required bool quietHoursEnabled,
    required int quietStartHour,
    required int quietEndHour,
  }) async {
    try {
      await client.from('honkers_notification_preferences').upsert({
        'user_id': userId,
        'notify_replies': notifyReplies,
        'notify_mentions': notifyMentions,
        'notify_badges': notifyBadges,
        'quiet_hours_enabled': quietHoursEnabled,
        'quiet_start_hour': quietStartHour,
        'quiet_end_hour': quietEndHour,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id');
      return true;
    } catch (e) {
      return false;
    }
  }
}
