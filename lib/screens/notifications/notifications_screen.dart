import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive_size.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/rdx_text_field.dart';
import 'notification_history_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<NotificationProvider>().load());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      body: provider.isLoading && provider.history.isEmpty
          ? const LoadingIndicator()
          : LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final isMobile = width < 700;
                final isTablet = width >= 700 && width < 1050;

                return RefreshIndicator(
                  color: AppColors.primary,
                  backgroundColor: colors.surface,
                  onRefresh: provider.load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      isMobile ? context.w(16) : context.w(24),
                      isMobile ? context.h(18) : context.h(20),
                      isMobile ? context.w(16) : context.w(24),
                      context.h(32),
                    ),
                    children: [
                      _buildPageHeader(colors, isMobile: isMobile),
                      SizedBox(height: context.h(22)),
                      _buildStats(provider, colors, isMobile: isMobile),
                      SizedBox(height: context.h(22)),
                      _buildMainContent(
                        provider,
                        colors,
                        isMobile: isMobile,
                        isTablet: isTablet,
                      ),
                      SizedBox(height: context.h(20)),
                      _buildHistoryNavigation(colors, isMobile: isMobile),
                    ],
                  ),
                );
              },
            ),
    );
  }

  // ============================================================
  // PAGE HEADER
  // ============================================================

  Widget _buildPageHeader(AppColorScheme colors, {required bool isMobile}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.campaign_outlined,
                    size: context.h(15),
                    color: AppColors.primary,
                  ),
                  SizedBox(width: context.w(7)),
                  Text(
                    'COMMUNICATION HUB',
                    style: AppTextStyles.section(context)
                        .copyWith(color: AppColors.primary),
                  ),
                ],
              ),
              SizedBox(height: context.h(6)),
              Text(
                'Broadcast System',
                style: AppTextStyles.heading(context),
              ),
              SizedBox(height: context.h(6)),
              Text(
                'Send important updates and announcements to your customer app users.',
                style: AppTextStyles.bodySecondary(context),
              ),
            ],
          ),
        ),
        if (!isMobile) ...[
          SizedBox(width: context.w(20)),
          OutlinedButton.icon(
            onPressed: _openHistory,
            icon: Icon(Icons.history_outlined, size: context.h(16)),
            label: Text(
              'Notification History',
              style: AppTextStyles.bodySecondary(context)
                  .copyWith(color: colors.textPrimary),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.textPrimary,
              side: BorderSide(color: colors.border),
              minimumSize: Size(0, context.h(40)),
              padding: EdgeInsets.symmetric(horizontal: context.w(14)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(context.h(8)),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ============================================================
  // STATS
  // ============================================================

  Widget _buildStats(
    NotificationProvider provider,
    AppColorScheme colors, {
    required bool isMobile,
  }) {
    final totalRecipients = provider.history.fold<int>(
      0,
      (sum, item) => sum + item.recipientCount,
    );
    final totalBroadcasts = provider.history.length;
    final scheduled =
        provider.history.where((item) => item.scheduled).length;

    final cards = [
      _NotificationStat(
        label: 'TOTAL RECIPIENTS',
        value: _formatNumber(totalRecipients),
        subtitle: 'Across all broadcasts',
        icon: Icons.people_alt_outlined,
        color: AppColors.primary,
      ),
      _NotificationStat(
        label: 'TOTAL BROADCASTS',
        value: _formatNumber(totalBroadcasts),
        subtitle: 'Notifications created',
        icon: Icons.campaign_outlined,
        color: AppColors.info,
      ),
      _NotificationStat(
        label: 'SCHEDULED',
        value: _formatNumber(scheduled),
        subtitle: 'Upcoming notifications',
        icon: Icons.schedule_outlined,
        color: AppColors.warning,
      ),
    ];

    if (isMobile) {
      return Column(
        children: [
          for (int i = 0; i < cards.length; i++) ...[
            if (i > 0) SizedBox(height: context.h(12)),
            _buildStatCard(cards[i], colors),
          ],
        ],
      );
    }

    return Row(
      children: [
        for (int i = 0; i < cards.length; i++) ...[
          if (i > 0) SizedBox(width: context.w(14)),
          Expanded(child: _buildStatCard(cards[i], colors)),
        ],
      ],
    );
  }

  Widget _buildStatCard(_NotificationStat stat, AppColorScheme colors) {
    return Container(
      constraints: BoxConstraints(minHeight: context.h(102)),
      padding: EdgeInsets.fromLTRB(
        context.w(18),
        context.h(16),
        context.w(16),
        context.h(15),
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(context.h(14)),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  stat.label,
                  style: AppTextStyles.section(context)
                      .copyWith(color: colors.textMuted),
                ),
                SizedBox(height: context.h(6)),
                Text(stat.value, style: AppTextStyles.heading(context)),
                SizedBox(height: context.h(6)),
                Text(stat.subtitle, style: AppTextStyles.bodySecondary(context)),
              ],
            ),
          ),
          SizedBox(width: context.w(12)),
          Container(
            width: context.w(42),
            height: context.h(42),
            decoration: BoxDecoration(
              color: stat.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(context.h(10)),
            ),
            alignment: Alignment.center,
            child: Icon(stat.icon, size: context.h(20), color: stat.color),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MAIN CONTENT
  // ============================================================

  Widget _buildMainContent(
    NotificationProvider provider,
    AppColorScheme colors, {
    required bool isMobile,
    required bool isTablet,
  }) {
    return _buildComposeCard(
      provider,
      colors,
      isMobile: isMobile,
      isTablet: isTablet,
    );
  }

  // ============================================================
  // COMPOSE
  // ============================================================

  Widget _buildComposeCard(
    NotificationProvider provider,
    AppColorScheme colors, {
    required bool isMobile,
    required bool isTablet,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        isMobile ? context.w(18) : context.w(24),
        isMobile ? context.h(18) : context.h(21),
        isMobile ? context.w(18) : context.w(24),
        isMobile ? context.h(20) : context.h(22),
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(context.h(14)),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: context.w(34),
                height: context.h(34),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(context.h(9)),
                ),
                child: Icon(
                  Icons.edit_outlined,
                  size: context.h(18),
                  color: AppColors.primary,
                ),
              ),
              SizedBox(width: context.w(10)),
              Text('Compose Notification', style: AppTextStyles.section(context)),
            ],
          ),
          SizedBox(height: context.h(23)),
          RdxTextField(
            controller: _titleController,
            label: 'NOTIFICATION TITLE',
            hint: 'e.g. System Update',
            maxLines: 1,
          ),
          SizedBox(height: context.h(19)),
          Row(
            children: [
              Expanded(child: _fieldLabel(colors, 'MESSAGE CONTENT')),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _messageController,
                builder: (_, value, __) {
                  return Text(
                    '${value.text.length}/500',
                    style: AppTextStyles.body(context),
                  );
                },
              ),
            ],
          ),
          SizedBox(height: context.h(8)),
          RdxTextField(
            controller: _messageController,
            hint: 'Type your message here...',
            maxLines: isMobile ? 7 : 8,
            maxLength: 500,
          ),
          SizedBox(height: context.h(21)),
          _buildActionButtons(provider, colors, vertical: isMobile),
          if (provider.errorMessage != null) ...[
            SizedBox(height: context.h(14)),
            _buildError(provider.errorMessage!, colors),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // ACTION BUTTONS (right-aligned, not expanded)
  // ============================================================

  Widget _buildActionButtons(
    NotificationProvider provider,
    AppColorScheme colors, {
    required bool vertical,
  }) {
    final scheduleButton = OutlinedButton.icon(
      onPressed: provider.isLoading
          ? null
          : () => _showScheduleDialog(provider, colors),
      icon: Icon(Icons.calendar_month_outlined, size: context.h(17)),
      label: Text(
        'Schedule',
        style: AppTextStyles.label(context).copyWith(color: colors.textPrimary),
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: Size(0, context.h(46)),
        padding: EdgeInsets.symmetric(horizontal: context.w(20)),
        foregroundColor: colors.textPrimary,
        side: BorderSide(color: colors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.h(8)),
        ),
      ),
    );

    final sendButton = ElevatedButton.icon(
      onPressed: provider.isLoading ? null : () => _sendNow(provider),
      icon: provider.isLoading
          ? SizedBox(
              width: context.w(15),
              height: context.h(15),
              child: const CircularProgressIndicator(
                strokeWidth: 1.8,
                color: Colors.white,
              ),
            )
          : Icon(Icons.send_outlined, size: context.h(17)),
      label: Text(
        'Send Now',
        style: AppTextStyles.label(context).copyWith(color: Colors.white),
      ),
      style: ElevatedButton.styleFrom(
        minimumSize: Size(0, context.h(46)),
        padding: EdgeInsets.symmetric(horizontal: context.w(22)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.h(8)),
        ),
      ),
    );

    if (vertical) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          scheduleButton,
          SizedBox(height: context.h(10)),
          sendButton,
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        scheduleButton,
        SizedBox(width: context.w(12)),
        sendButton,
      ],
    );
  }

  // ============================================================
  // SCHEDULE DIALOG
  // ============================================================

  Future<void> _showScheduleDialog(
    NotificationProvider provider,
    AppColorScheme colors,
  ) async {
    if (_titleController.text.trim().isEmpty ||
        _messageController.text.trim().isEmpty) {
      provider.setError(
        'Please fill in both notification title and message.',
      );
      return;
    }

    DateTime? selectedDate;
    TimeOfDay? selectedTime;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isReady = selectedDate != null && selectedTime != null;

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: EdgeInsets.symmetric(
                horizontal: context.w(20),
                vertical: context.h(24),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: context.w(400)),
                child: Container(
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(context.h(10)),
                    border: Border.all(color: colors.border),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // HEADER
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          context.w(18),
                          context.h(15),
                          context.w(12),
                          context.h(15),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_month_outlined,
                              size: context.h(18),
                              color: AppColors.primary,
                            ),
                            SizedBox(width: context.w(10)),
                            Expanded(
                              child: Text(
                                'Schedule Notification',
                                style: AppTextStyles.section(context),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              icon: Icon(
                                Icons.close,
                                size: context.h(19),
                                color: colors.textSecondary,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(
                                minWidth: context.w(30),
                                minHeight: context.h(30),
                              ),
                            ),
                          ],
                        ),
                      ),

                      Divider(height: context.h(1), color: colors.divider),

                      // DATE / TIME
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          context.w(20),
                          context.h(18),
                          context.w(20),
                          context.h(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _scheduleFieldLabel('Date', colors),
                            SizedBox(height: context.h(7)),
                            _scheduleInput(
                              colors: colors,
                              icon: Icons.calendar_today_outlined,
                              hint: 'MM/DD/YYYY',
                              value: selectedDate == null
                                  ? null
                                  : _formatScheduleDate(selectedDate!),
                              onTap: () async {
                                final now = DateTime.now();
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: selectedDate ?? now,
                                  firstDate: DateTime(now.year, now.month, now.day),
                                  lastDate: DateTime(now.year + 5),
                                  builder: (context, child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: Theme.of(context)
                                            .colorScheme
                                            .copyWith(primary: AppColors.primary),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (picked != null) {
                                  setDialogState(() => selectedDate = picked);
                                }
                              },
                            ),
                            SizedBox(height: context.h(18)),
                            _scheduleFieldLabel('Time (Local)', colors),
                            SizedBox(height: context.h(7)),
                            _scheduleInput(
                              colors: colors,
                              icon: Icons.access_time_outlined,
                              hint: '02:30 PM',
                              value: selectedTime == null
                                  ? null
                                  : selectedTime!.format(context),
                              onTap: () async {
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: selectedTime ?? TimeOfDay.now(),
                                  builder: (context, child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: Theme.of(context)
                                            .colorScheme
                                            .copyWith(primary: AppColors.primary),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (picked != null) {
                                  setDialogState(() => selectedTime = picked);
                                }
                              },
                            ),
                          ],
                        ),
                      ),

                      // ACTIONS
                      Container(
                        padding: EdgeInsets.fromLTRB(
                          context.w(20),
                          context.h(13),
                          context.w(20),
                          context.h(13),
                        ),
                        decoration: BoxDecoration(
                          color: colors.background.withOpacity(0.45),
                          border: Border(
                            top: BorderSide(color: colors.divider),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              style: OutlinedButton.styleFrom(
                                minimumSize: Size(context.w(75), context.h(40)),
                                padding: EdgeInsets.symmetric(
                                  horizontal: context.w(18),
                                ),
                              ),
                              child: Text(
                                'Cancel',
                                style: AppTextStyles.label(context)
                                    .copyWith(color: colors.textPrimary),
                              ),
                            ),
                            SizedBox(width: context.w(10)),
                            ElevatedButton.icon(
                              onPressed: !isReady || provider.isLoading
                                  ? null
                                  : () async {
                                      final scheduledAt = DateTime(
                                        selectedDate!.year,
                                        selectedDate!.month,
                                        selectedDate!.day,
                                        selectedTime!.hour,
                                        selectedTime!.minute,
                                      );

                                      final success =
                                          await provider.scheduleBroadcast(
                                        title: _titleController.text,
                                        message: _messageController.text,
                                        scheduledAt: scheduledAt,
                                      );

                                      if (!context.mounted) return;

                                      if (success) {
                                        Navigator.pop(dialogContext);
                                        _titleController.clear();
                                        _messageController.clear();

                                        ScaffoldMessenger.of(this.context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Notification scheduled successfully.',
                                              style: AppTextStyles.body(context)
                                                  .copyWith(color: Colors.white),
                                            ),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      }
                                    },
                              icon: provider.isLoading
                                  ? SizedBox(
                                      width: context.w(14),
                                      height: context.h(14),
                                      child: const CircularProgressIndicator(
                                        strokeWidth: 1.7,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Icon(Icons.send_outlined, size: context.h(15)),
                              label: Text(
                                'Schedule Now',
                                style: AppTextStyles.body(context).copyWith(
                                  color: selectedDate == null ||
                                          selectedTime == null
                                      ? colors.textMuted
                                      : Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                minimumSize: Size(context.w(128), context.h(40)),
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(context.h(6)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // SCHEDULE FIELD
  // ============================================================

  Widget _scheduleFieldLabel(String text, AppColorScheme colors) {
    return Text(
      text,
      style: AppTextStyles.bodySecondary(context)
          .copyWith(color: colors.textMuted),
    );
  }

  Widget _scheduleInput({
    required AppColorScheme colors,
    required IconData icon,
    required String hint,
    required VoidCallback onTap,
    String? value,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(context.h(7)),
      child: Container(
        height: context.h(44),
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: context.w(10)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(context.h(7)),
          border: Border.all(color: const Color(0xFFD7D7D7)),
        ),
        child: Row(
          children: [
            Icon(icon, size: context.h(16), color: AppColors.primary),
            SizedBox(width: context.w(9)),
            Expanded(
              child: Text(
                value ?? hint,
                style: AppTextStyles.body(context).copyWith(
                  color: value == null
                      ? const Color(0xFFF1A6B0)
                      : const Color(0xFF333333),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HISTORY NAVIGATION
  // ============================================================

  Widget _buildHistoryNavigation(
    AppColorScheme colors, {
    required bool isMobile,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(context.h(12)),
      onTap: _openHistory,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.w(16),
          vertical: context.h(15),
        ),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(context.h(12)),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            Container(
              width: context.w(36),
              height: context.h(36),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(context.h(9)),
              ),
              child: Icon(
                Icons.history_outlined,
                size: context.h(19),
                color: AppColors.primary,
              ),
            ),
            SizedBox(width: context.w(12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notification History',
                    style: AppTextStyles.section(context)
                        .copyWith(color: colors.textPrimary),
                  ),
                  SizedBox(height: context.h(3)),
                  Text(
                    'View sent and scheduled notifications',
                    style: AppTextStyles.bodySecondary(context),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: context.h(13),
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  void _openHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NotificationHistoryScreen()),
    );
  }

  // ============================================================
  // TEXT FIELD
  // ============================================================

  Widget _fieldLabel(AppColorScheme colors, String text) {
    return Text(
      text,
      style: AppTextStyles.bodySecondary(context)
          .copyWith(color: colors.textMuted),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildError(String message, AppColorScheme colors) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: context.w(12),
        vertical: context.h(10),
      ),
      decoration: BoxDecoration(
        color: AppColors.danger.withOpacity(0.08),
        borderRadius: BorderRadius.circular(context.h(8)),
        border: Border.all(color: AppColors.danger.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: context.h(16), color: AppColors.danger),
          SizedBox(width: context.w(8)),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.body(context).copyWith(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SEND NOW
  // ============================================================

  Future<void> _sendNow(NotificationProvider provider) async {
    final success = await provider.sendBroadcast(
      title: _titleController.text,
      message: _messageController.text,
    );

    if (!mounted || !success) return;

    _titleController.clear();
    _messageController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Notification sent successfully.',
          style: AppTextStyles.body(context).copyWith(color: Colors.white),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _formatScheduleDate(DateTime date) {
    return '${date.month.toString().padLeft(2, '0')}/'
        '${date.day.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _formatNumber(int value) {
    if (value < 1000) return value.toString();

    final text = value.toString();
    final result = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      if (i > 0 && (text.length - i) % 3 == 0) {
        result.write(',');
      }
      result.write(text[i]);
    }

    return result.toString();
  }
}

class _NotificationStat {
  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _NotificationStat({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}