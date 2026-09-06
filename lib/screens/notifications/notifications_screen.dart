import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

    Future.microtask(
      () => context.read<NotificationProvider>().load(),
    );
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
                      _buildPageHeader(
                        colors,
                        isMobile: isMobile,
                      ),
                      SizedBox(height: context.h(22)),
                      _buildStats(
                        provider,
                        colors,
                        isMobile: isMobile,
                      ),
                      SizedBox(height: context.h(22)),
                      _buildMainContent(
                        provider,
                        colors,
                        isMobile: isMobile,
                        isTablet: isTablet,
                      ),
                      SizedBox(height: context.h(20)),
                      _buildHistoryNavigation(
                        colors,
                        isMobile: isMobile,
                      ),
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

  Widget _buildPageHeader(
    AppColorScheme colors, {
    required bool isMobile,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.campaign_outlined,
                    size: 15,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    'COMMUNICATION HUB',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.9,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Broadcast System',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: isMobile ? 22 : 25,
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Send important updates and announcements to your customer app users.',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        if (!isMobile) ...[
          const SizedBox(width: 20),
          OutlinedButton.icon(
            onPressed: _openHistory,
            icon: const Icon(
              Icons.history_outlined,
              size: 16,
            ),
            label: const Text(
              'Notification History',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.textPrimary,
              side: BorderSide(
                color: colors.border,
              ),
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
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

    final scheduled = provider.history
        .where(
          (item) => item.scheduled,
        )
        .length;

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
            if (i > 0) const SizedBox(height: 12),
            _buildStatCard(
              cards[i],
              colors,
            ),
          ],
        ],
      );
    }

    return Row(
      children: [
        for (int i = 0; i < cards.length; i++) ...[
          if (i > 0) const SizedBox(width: 14),
          Expanded(
            child: _buildStatCard(
              cards[i],
              colors,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatCard(
    _NotificationStat stat,
    AppColorScheme colors,
  ) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 102,
      ),
      padding: const EdgeInsets.fromLTRB(
        18,
        16,
        16,
        15,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colors.border,
        ),
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
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.7,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  stat.value,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  stat.subtitle,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: stat.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(
              stat.icon,
              size: 20,
              color: stat.color,
            ),
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
        isMobile ? 18 : 24,
        isMobile ? 18 : 21,
        isMobile ? 18 : 24,
        isMobile ? 20 : 22,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Compose Notification',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 23),
          _fieldLabel(
            colors,
            'NOTIFICATION TITLE',
          ),
          const SizedBox(height: 8),
          RdxTextField(
            controller: _titleController,
            hint: 'e.g. System Update',
            maxLines: 1,
          ),
          const SizedBox(height: 19),
          Row(
            children: [
              Expanded(
                child: _fieldLabel(
                  colors,
                  'MESSAGE CONTENT',
                ),
              ),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _messageController,
                builder: (_, value, __) {
                  return Text(
                    '${value.text.length}/500',
                    style: TextStyle(
                      color: colors.textMuted,
                      fontSize: 10,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          RdxTextField(
            controller: _messageController,
            hint: 'Type your message here...',
            maxLines: isMobile ? 7 : 8,
            maxLength: 500,
          ),
          const SizedBox(height: 21),
          _buildActionButtons(
            provider,
            colors,
            vertical: isMobile,
          ),
          if (provider.errorMessage != null) ...[
            const SizedBox(height: 14),
            _buildError(
              provider.errorMessage!,
              colors,
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // ACTION BUTTONS
  // ============================================================

  Widget _buildActionButtons(
    NotificationProvider provider,
    AppColorScheme colors, {
    required bool vertical,
  }) {
    final scheduleButton = OutlinedButton.icon(
      onPressed: provider.isLoading
          ? null
          : () => _showScheduleDialog(
                provider,
                colors,
              ),
      icon: const Icon(
        Icons.calendar_month_outlined,
        size: 17,
      ),
      label: const Text('Schedule'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 46),
        foregroundColor: colors.textPrimary,
        side: BorderSide(
          color: colors.border,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );

    final sendButton = ElevatedButton.icon(
      onPressed: provider.isLoading ? null : () => _sendNow(provider),
      icon: provider.isLoading
          ? const SizedBox(
              width: 15,
              height: 15,
              child: CircularProgressIndicator(
                strokeWidth: 1.8,
                color: Colors.white,
              ),
            )
          : const Icon(
              Icons.send_outlined,
              size: 17,
            ),
      label: const Text('Send Now'),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 46),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );

    if (vertical) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          scheduleButton,
          const SizedBox(height: 10),
          sendButton,
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: scheduleButton,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: sendButton,
        ),
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
          builder: (
            context,
            setDialogState,
          ) {
            final isReady = selectedDate != null && selectedTime != null;

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 24,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 400,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: colors.border,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // HEADER
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          18,
                          15,
                          12,
                          15,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_month_outlined,
                              size: 18,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Schedule Notification',
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(
                                dialogContext,
                              ),
                              icon: Icon(
                                Icons.close,
                                size: 19,
                                color: colors.textSecondary,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 30,
                                minHeight: 30,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Divider(
                        height: 1,
                        color: colors.divider,
                      ),

                      // DATE / TIME
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          20,
                          18,
                          20,
                          20,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _scheduleFieldLabel(
                              'Date',
                              colors,
                            ),
                            const SizedBox(height: 7),
                            _scheduleInput(
                              colors: colors,
                              icon: Icons.calendar_today_outlined,
                              hint: 'MM/DD/YYYY',
                              value: selectedDate == null
                                  ? null
                                  : _formatScheduleDate(
                                      selectedDate!,
                                    ),
                              onTap: () async {
                                final now = DateTime.now();

                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: selectedDate ?? now,
                                  firstDate: DateTime(
                                    now.year,
                                    now.month,
                                    now.day,
                                  ),
                                  lastDate: DateTime(
                                    now.year + 5,
                                  ),
                                  builder: (
                                    context,
                                    child,
                                  ) {
                                    return Theme(
                                      data: Theme.of(
                                        context,
                                      ).copyWith(
                                        colorScheme: Theme.of(
                                          context,
                                        ).colorScheme.copyWith(
                                              primary: AppColors.primary,
                                            ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );

                                if (picked != null) {
                                  setDialogState(
                                    () {
                                      selectedDate = picked;
                                    },
                                  );
                                }
                              },
                            ),
                            const SizedBox(height: 18),
                            _scheduleFieldLabel(
                              'Time (Local)',
                              colors,
                            ),
                            const SizedBox(height: 7),
                            _scheduleInput(
                              colors: colors,
                              icon: Icons.access_time_outlined,
                              hint: '02:30 PM',
                              value: selectedTime == null
                                  ? null
                                  : selectedTime!.format(
                                      context,
                                    ),
                              onTap: () async {
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: selectedTime ?? TimeOfDay.now(),
                                  builder: (
                                    context,
                                    child,
                                  ) {
                                    return Theme(
                                      data: Theme.of(
                                        context,
                                      ).copyWith(
                                        colorScheme: Theme.of(
                                          context,
                                        ).colorScheme.copyWith(
                                              primary: AppColors.primary,
                                            ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );

                                if (picked != null) {
                                  setDialogState(
                                    () {
                                      selectedTime = picked;
                                    },
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),

                      // ACTIONS
                      Container(
                        padding: const EdgeInsets.fromLTRB(
                          20,
                          13,
                          20,
                          13,
                        ),
                        decoration: BoxDecoration(
                          color: colors.background.withOpacity(0.45),
                          border: Border(
                            top: BorderSide(
                              color: colors.divider,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: () => Navigator.pop(
                                dialogContext,
                              ),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(
                                  75,
                                  40,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                ),
                              ),
                              child: const Text(
                                'Cancel',
                              ),
                            ),
                            const SizedBox(width: 10),
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

                                      if (!context.mounted) {
                                        return;
                                      }

                                      if (success) {
                                        Navigator.pop(
                                          dialogContext,
                                        );

                                        _titleController.clear();
                                        _messageController.clear();

                                        ScaffoldMessenger.of(
                                          this.context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Notification scheduled successfully.',
                                            ),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      }
                                    },
                              icon: provider.isLoading
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 1.7,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.send_outlined,
                                      size: 15,
                                    ),
                              label: const Text(
                                'Schedule Now',
                              ),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(
                                  128,
                                  40,
                                ),
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    6,
                                  ),
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

  Widget _scheduleFieldLabel(
    String text,
    AppColorScheme colors,
  ) {
    return Text(
      text,
      style: TextStyle(
        color: colors.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
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
      borderRadius: BorderRadius.circular(7),
      child: Container(
        height: 44,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: const Color(0xFFD7D7D7),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: AppColors.primary,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                value ?? hint,
                style: TextStyle(
                  color: value == null
                      ? const Color(0xFFF1A6B0)
                      : const Color(0xFF333333),
                  fontSize: 12,
                  fontWeight: value == null ? FontWeight.w400 : FontWeight.w500,
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
      borderRadius: BorderRadius.circular(12),
      onTap: _openHistory,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colors.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(
                Icons.history_outlined,
                size: 19,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notification History',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'View sent and scheduled notifications',
                    style: TextStyle(
                      color: colors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 13,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  void _openHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const NotificationHistoryScreen(),
      ),
    );
  }

  // ============================================================
  // TEXT FIELD
  // ============================================================

  Widget _fieldLabel(
    AppColorScheme colors,
    String text,
  ) {
    return Text(
      text,
      style: TextStyle(
        color: colors.textMuted,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.55,
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildError(
    String message,
    AppColorScheme colors,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.danger.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.danger.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            size: 16,
            color: AppColors.danger,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.danger,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SEND NOW
  // ============================================================

  Future<void> _sendNow(
    NotificationProvider provider,
  ) async {
    final success = await provider.sendBroadcast(
      title: _titleController.text,
      message: _messageController.text,
    );

    if (!mounted || !success) {
      return;
    }

    _titleController.clear();
    _messageController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Notification sent successfully.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _formatScheduleDate(
    DateTime date,
  ) {
    return '${date.month.toString().padLeft(2, '0')}/'
        '${date.day.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _formatNumber(int value) {
    if (value < 1000) {
      return value.toString();
    }

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
