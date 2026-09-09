import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './supabase_service.dart';
import './honkers_session.dart';

/// Model for a single in-app reply notification.
class ReplyNotification {
  final String id;
  final String questionTitle;
  final String replierName;
  final String questionId;
  final DateTime receivedAt;

  ReplyNotification({
    required this.id,
    required this.questionTitle,
    required this.replierName,
    required this.questionId,
    required this.receivedAt,
  });
}

/// Singleton service that listens for new replies on questions owned by the
/// current user and exposes a stream of [ReplyNotification] events.
class ReplyNotificationService {
  static ReplyNotificationService? _instance;
  static ReplyNotificationService get instance =>
      _instance ??= ReplyNotificationService._();

  ReplyNotificationService._();

  RealtimeChannel? _channel;

  /// Stream controller that emits whenever a new reply notification arrives.
  final _controller = ValueNotifier<ReplyNotification?>(null);

  ValueNotifier<ReplyNotification?> get notificationNotifier => _controller;

  /// Start listening for new replies on the current user's questions.
  /// Call this after the user logs in.
  Future<void> start() async {
    await stop(); // Cancel any previous subscription first.

    final userId = HonkersSession.instance.userId;
    if (userId.isEmpty) return;

    // Subscribe to ALL new inserts on honkers_replies.
    // We filter client-side to only show notifications for the current user's
    // questions (avoids needing a DB-level filter on a joined column).
    _channel = SupabaseService.instance.client
        .channel('reply_notifications_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'honkers_replies',
          callback: (payload) async {
            final newRecord = payload.newRecord;
            if (newRecord.isEmpty) return;

            final replyUserId = newRecord['user_id'] as String? ?? '';
            final questionId = newRecord['question_id'] as String? ?? '';

            // Don't notify the user about their own replies.
            if (replyUserId == userId) return;
            if (questionId.isEmpty) return;

            // Check if this question belongs to the current user.
            await _handleNewReply(
              replyId: newRecord['id'] as String? ?? '',
              questionId: questionId,
              replyUserId: replyUserId,
            );
          },
        )
        .subscribe();
  }

  Future<void> _handleNewReply({
    required String replyId,
    required String questionId,
    required String replyUserId,
  }) async {
    final userId = HonkersSession.instance.userId;
    if (userId.isEmpty) return;

    try {
      // Fetch the question to check ownership.
      final question = await SupabaseService.instance.client
          .from('honkers_questions')
          .select('id, title, user_id')
          .eq('id', questionId)
          .maybeSingle();

      if (question == null) return;
      if ((question['user_id'] as String? ?? '') != userId) return;

      // Fetch the replier's name.
      final replier = await SupabaseService.instance.client
          .from('honkers_users')
          .select('full_name')
          .eq('id', replyUserId)
          .maybeSingle();

      final replierName = (replier?['full_name'] as String?)?.isNotEmpty == true
          ? replier!['full_name'] as String
          : 'Someone';

      final notification = ReplyNotification(
        id: replyId,
        questionTitle: question['title'] as String? ?? 'your question',
        replierName: replierName,
        questionId: questionId,
        receivedAt: DateTime.now(),
      );

      _controller.value = notification;
    } catch (_) {
      // Silently ignore errors to avoid disrupting the app.
    }
  }

  /// Stop the real-time subscription.
  Future<void> stop() async {
    await _channel?.unsubscribe();
    _channel = null;
  }

  void dispose() {
    stop();
    _controller.dispose();
  }
}
