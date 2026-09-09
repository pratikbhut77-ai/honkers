import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/honkers_session.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _isLoading = true;
  bool _isSaving = false;

  bool _notifyReplies = true;
  bool _notifyMentions = true;
  bool _notifyBadges = true;
  bool _quietHoursEnabled = false;
  int _quietStartHour = 22;
  int _quietEndHour = 8;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final userId = HonkersSession.instance.userId;
    if (userId.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }
    final prefs = await SupabaseService.instance.getNotificationPreferences(
      userId,
    );
    if (!mounted) return;
    setState(() {
      _notifyReplies = prefs['notify_replies'] as bool? ?? true;
      _notifyMentions = prefs['notify_mentions'] as bool? ?? true;
      _notifyBadges = prefs['notify_badges'] as bool? ?? true;
      _quietHoursEnabled = prefs['quiet_hours_enabled'] as bool? ?? false;
      _quietStartHour = prefs['quiet_start_hour'] as int? ?? 22;
      _quietEndHour = prefs['quiet_end_hour'] as int? ?? 8;
      _isLoading = false;
    });
  }

  Future<void> _savePreferences() async {
    final userId = HonkersSession.instance.userId;
    if (userId.isEmpty) return;
    setState(() => _isSaving = true);
    final success = await SupabaseService.instance.saveNotificationPreferences(
      userId: userId,
      notifyReplies: _notifyReplies,
      notifyMentions: _notifyMentions,
      notifyBadges: _notifyBadges,
      quietHoursEnabled: _quietHoursEnabled,
      quietStartHour: _quietStartHour,
      quietEndHour: _quietEndHour,
    );
    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Preferences saved!' : 'Failed to save. Try again.',
          style: GoogleFonts.dmSans(
            color: success ? AppTheme.backgroundDark : Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: success ? AppTheme.gold : AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatHour(int hour) {
    final period = hour < 12 ? 'AM' : 'PM';
    final displayHour = hour == 0
        ? 12
        : hour > 12
        ? hour - 12
        : hour;
    return '$displayHour:00 $period';
  }

  Future<void> _pickHour({
    required String title,
    required int currentHour,
    required ValueChanged<int> onSelected,
  }) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _HourPickerSheet(
        title: title,
        currentHour: currentHour,
        onSelected: onSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppTheme.textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Notification Settings',
          style: GoogleFonts.dmSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.gold,
                  ),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _savePreferences,
              child: Text(
                'Save',
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.gold,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.gold))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                _SectionHeader(title: 'Notification Types'),
                const SizedBox(height: 8),
                _SettingsCard(
                  children: [
                    _ToggleRow(
                      icon: Icons.reply_rounded,
                      iconColor: const Color(0xFF5B9BD5),
                      title: 'Replies',
                      subtitle: 'When someone replies to your question',
                      value: _notifyReplies,
                      onChanged: (v) => setState(() => _notifyReplies = v),
                    ),
                    _Divider(),
                    _ToggleRow(
                      icon: Icons.alternate_email_rounded,
                      iconColor: const Color(0xFF7EC8A4),
                      title: 'Mentions',
                      subtitle: 'When someone mentions you in a reply',
                      value: _notifyMentions,
                      onChanged: (v) => setState(() => _notifyMentions = v),
                    ),
                    _Divider(),
                    _ToggleRow(
                      icon: Icons.military_tech_rounded,
                      iconColor: AppTheme.gold,
                      title: 'Badges',
                      subtitle: 'When you earn a new achievement badge',
                      value: _notifyBadges,
                      onChanged: (v) => setState(() => _notifyBadges = v),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _SectionHeader(title: 'Quiet Hours'),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    'Mute all notifications during a set time window to avoid interruptions.',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: AppTheme.textMuted,
                      height: 1.4,
                    ),
                  ),
                ),
                _SettingsCard(
                  children: [
                    _ToggleRow(
                      icon: Icons.bedtime_rounded,
                      iconColor: const Color(0xFF9B7FD4),
                      title: 'Enable Quiet Hours',
                      subtitle: 'No notifications during this window',
                      value: _quietHoursEnabled,
                      onChanged: (v) => setState(() => _quietHoursEnabled = v),
                    ),
                    if (_quietHoursEnabled) ...[
                      _Divider(),
                      _TimeRow(
                        icon: Icons.nights_stay_rounded,
                        iconColor: const Color(0xFF9B7FD4),
                        title: 'Start Time',
                        timeLabel: _formatHour(_quietStartHour),
                        onTap: () => _pickHour(
                          title: 'Quiet Hours Start',
                          currentHour: _quietStartHour,
                          onSelected: (h) =>
                              setState(() => _quietStartHour = h),
                        ),
                      ),
                      _Divider(),
                      _TimeRow(
                        icon: Icons.wb_sunny_rounded,
                        iconColor: const Color(0xFFE8A838),
                        title: 'End Time',
                        timeLabel: _formatHour(_quietEndHour),
                        onTap: () => _pickHour(
                          title: 'Quiet Hours End',
                          currentHour: _quietEndHour,
                          onSelected: (h) => setState(() => _quietEndHour = h),
                        ),
                      ),
                    ],
                  ],
                ),
                if (_quietHoursEnabled) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.goldSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppTheme.gold.withAlpha(80),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 16,
                          color: AppTheme.gold,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Notifications are silenced from ${_formatHour(_quietStartHour)} to ${_formatHour(_quietEndHour)}.',
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: AppTheme.gold,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _savePreferences,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.gold,
                      foregroundColor: AppTheme.backgroundDark,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                      disabledBackgroundColor: AppTheme.gold.withAlpha(100),
                    ),
                    child: Text(
                      'Save Preferences',
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.dmSans(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppTheme.textMuted,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      color: Color(0xFF242424),
      indent: 52,
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconColor.withAlpha(30),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppTheme.gold,
            activeTrackColor: AppTheme.gold.withAlpha(80),
            inactiveThumbColor: AppTheme.textMuted,
            inactiveTrackColor: const Color(0xFF2A2A2A),
          ),
        ],
      ),
    );
  }
}

class _TimeRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String timeLabel;
  final VoidCallback onTap;

  const _TimeRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.timeLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: iconColor.withAlpha(30),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.goldSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.gold.withAlpha(100)),
              ),
              child: Text(
                timeLabel,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.gold,
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppTheme.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _HourPickerSheet extends StatefulWidget {
  final String title;
  final int currentHour;
  final ValueChanged<int> onSelected;

  const _HourPickerSheet({
    required this.title,
    required this.currentHour,
    required this.onSelected,
  });

  @override
  State<_HourPickerSheet> createState() => _HourPickerSheetState();
}

class _HourPickerSheetState extends State<_HourPickerSheet> {
  late int _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.currentHour;
  }

  String _label(int h) {
    final period = h < 12 ? 'AM' : 'PM';
    final display = h == 0
        ? 12
        : h > 12
        ? h - 12
        : h;
    return '$display:00 $period';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.textMuted.withAlpha(80),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.title,
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 2.2,
              ),
              itemCount: 24,
              itemBuilder: (_, i) {
                final isSelected = i == _selected;
                return GestureDetector(
                  onTap: () => setState(() => _selected = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.gold
                          : AppTheme.surfaceVariantDark,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.gold
                            : const Color(0xFF3A3A3A),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _label(i),
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? AppTheme.backgroundDark
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onSelected(_selected);
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.gold,
                foregroundColor: AppTheme.backgroundDark,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: Text(
                'Confirm',
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
