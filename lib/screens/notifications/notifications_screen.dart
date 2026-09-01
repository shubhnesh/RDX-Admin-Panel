import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/text_styles.dart';
import '../../models/notification_model.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/rdx_header.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<NotificationProvider>().load());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();

    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      appBar: RdxHeader(
        title: 'Notifications',
        actions: [
          ElevatedButton.icon(
            onPressed: () => _showBroadcastSheet(context),
            icon: const Icon(Icons.campaign_outlined, size: 18),
            label: const Text('New Broadcast'),
          ),
        ],
      ),
      body: provider.isLoading
          ? const LoadingIndicator()
          : provider.history.isEmpty
              ? const EmptyState(message: 'No notifications sent yet')
              : ListView.separated(
                  padding: const EdgeInsets.all(24),
                  itemCount: provider.history.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final n = provider.history[index];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: (n.scheduled ? AppColors.info : AppColors.success).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              n.scheduled ? Icons.schedule : Icons.check_circle_outline,
                              color: n.scheduled ? AppColors.info : AppColors.success,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(n.title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 2),
                                Text(n.message, style: AppTextStyles.bodyMuted),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(n.scheduled ? 'Scheduled' : 'Sent', style: AppTextStyles.caption),
                              const SizedBox(height: 4),
                              Text('${n.recipientCount} recipients', style: AppTextStyles.caption),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  void _showBroadcastSheet(BuildContext context) {
    final titleController = TextEditingController();
    final messageController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
          ),
          child: Consumer<NotificationProvider>(
            builder: (context, provider, _) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('New Broadcast', style: AppTextStyles.h1),
                  const SizedBox(height: 16),
                  const Text('Audience', style: AppTextStyles.label),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: NotificationAudience.values.map((a) {
                      return ChoiceChip(
                        label: Text(_audienceLabel(a)),
                        selected: provider.audience == a,
                        onSelected: (_) => provider.setAudience(a),
                        backgroundColor: AppColors.surfaceVariant,
                        selectedColor: AppColors.primary.withOpacity(0.2),
                        labelStyle: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text('Subject', style: AppTextStyles.label),
                  const SizedBox(height: 6),
                  TextField(controller: titleController),
                  const SizedBox(height: 16),
                  const Text('Message', style: AppTextStyles.label),
                  const SizedBox(height: 6),
                  TextField(controller: messageController, maxLines: 3),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Switch(
                        value: provider.sendImmediately,
                        activeColor: AppColors.primary,
                        onChanged: provider.setSendImmediately,
                      ),
                      const Text('Send immediately', style: AppTextStyles.bodyMuted),
                    ],
                  ),
                  if (provider.errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(provider.errorMessage!, style: const TextStyle(color: AppColors.danger)),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: provider.isLoading
                          ? null
                          : () async {
                              final ok = await provider.sendBroadcast(
                                title: titleController.text,
                                message: messageController.text,
                              );
                              if (ok && context.mounted) Navigator.of(context).pop();
                            },
                      child: const Text('Send Broadcast'),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  String _audienceLabel(NotificationAudience a) {
    switch (a) {
      case NotificationAudience.allApp:
        return 'All App Users';
      case NotificationAudience.restaurantSpecific:
        return 'Restaurant Followers';
      case NotificationAudience.newCustomers:
        return 'New Customers';
    }
  }
}
