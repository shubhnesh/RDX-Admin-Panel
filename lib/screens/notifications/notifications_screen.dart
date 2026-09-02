// // import 'package:flutter/material.dart';
// // import 'package:provider/provider.dart';
// // import '../../core/theme/app_colors.dart';
// // import '../../models/notification_model.dart';
// // import '../../providers/notification_provider.dart';
// // import '../../widgets/loading_indicator.dart';

// // class NotificationsScreen extends StatefulWidget {
// //   const NotificationsScreen({super.key});

// //   @override
// //   State<NotificationsScreen> createState() => _NotificationsScreenState();
// // }

// // class _NotificationsScreenState extends State<NotificationsScreen> {
// //   final TextEditingController _titleController = TextEditingController();

// //   final TextEditingController _messageController = TextEditingController();

// //   @override
// //   void initState() {
// //     super.initState();

// //     Future.microtask(
// //       () => context.read<NotificationProvider>().load(),
// //     );
// //   }

// //   @override
// //   void dispose() {
// //     _titleController.dispose();
// //     _messageController.dispose();
// //     super.dispose();
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     final provider = context.watch<NotificationProvider>();

// //     final colors = AppColors.of(context);

// //     return Scaffold(
// //       backgroundColor: colors.background,
// //       body: provider.isLoading && provider.history.isEmpty
// //           ? const LoadingIndicator()
// //           : RefreshIndicator(
// //               color: AppColors.primary,
// //               backgroundColor: colors.surface,
// //               onRefresh: provider.load,
// //               child: LayoutBuilder(
// //                 builder: (context, constraints) {
// //                   final width = constraints.maxWidth;

// //                   final bool isMobile = width < 700;
// //                   final bool isTablet = width >= 700 && width < 1050;

// //                   return ListView(
// //                     physics: const AlwaysScrollableScrollPhysics(),
// //                     padding: EdgeInsets.fromLTRB(
// //                       isMobile ? 16 : 24,
// //                       16,
// //                       isMobile ? 16 : 24,
// //                       32,
// //                     ),
// //                     children: [
// //                       _buildPageHeader(
// //                         colors,
// //                         isMobile: isMobile,
// //                       ),
// //                       const SizedBox(height: 20),
// //                       _buildStats(
// //                         provider,
// //                         colors,
// //                         isMobile: isMobile,
// //                       ),
// //                       const SizedBox(height: 20),
// //                       if (isMobile || isTablet)
// //                         Column(
// //                           children: [
// //                             _buildComposeCard(
// //                               provider,
// //                               colors,
// //                               isMobile: isMobile,
// //                             ),
// //                             const SizedBox(height: 20),
// //                             _buildHistoryCard(
// //                               provider,
// //                               colors,
// //                               isMobile: isMobile,
// //                             ),
// //                           ],
// //                         )
// //                       else
// //                         Row(
// //                           crossAxisAlignment: CrossAxisAlignment.start,
// //                           children: [
// //                             // Increased Compose width.
// //                             Expanded(
// //                               flex: 40,
// //                               child: _buildComposeCard(
// //                                 provider,
// //                                 colors,
// //                                 isMobile: false,
// //                               ),
// //                             ),

// //                             const SizedBox(width: 20),

// //                             // History gets the remaining space.
// //                             Expanded(
// //                               flex: 60,
// //                               child: _buildHistoryCard(
// //                                 provider,
// //                                 colors,
// //                                 isMobile: false,
// //                               ),
// //                             ),
// //                           ],
// //                         ),
// //                       const SizedBox(height: 20),
// //                       _buildSystemStatus(colors),
// //                     ],
// //                   );
// //                 },
// //               ),
// //             ),
// //     );
// //   }

// //   // ═══════════════════════════════════════════════════════════════════
// //   // PAGE HEADER
// //   // ═══════════════════════════════════════════════════════════════════

// //   Widget _buildPageHeader(
// //     AppColorScheme colors, {
// //     required bool isMobile,
// //   }) {
// //     return Column(
// //       crossAxisAlignment: CrossAxisAlignment.start,
// //       children: [
// //         Row(
// //           crossAxisAlignment: CrossAxisAlignment.end,
// //           children: [
// //             Expanded(
// //               child: Column(
// //                 crossAxisAlignment: CrossAxisAlignment.start,
// //                 children: [
// //                   Row(
// //                     children: [
// //                       const Icon(
// //                         Icons.campaign_outlined,
// //                         size: 14,
// //                         color: AppColors.primary,
// //                       ),
// //                       const SizedBox(width: 7),
// //                       Text(
// //                         'COMMUNICATION HUB',
// //                         style: TextStyle(
// //                           color: AppColors.primary,
// //                           fontSize: 10,
// //                           fontWeight: FontWeight.w700,
// //                           letterSpacing: 0.9,
// //                         ),
// //                       ),
// //                     ],
// //                   ),
// //                   const SizedBox(height: 5),
// //                   Text(
// //                     'Broadcast System',
// //                     style: TextStyle(
// //                       color: colors.textPrimary,
// //                       fontSize: 24,
// //                       fontWeight: FontWeight.bold,
// //                       height: 1.1,
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //             ),
// //           ],
// //         ),
// //         const SizedBox(height: 5),
// //         Text(
// //           'Send important updates and announcements to your customer app users.',
// //           style: TextStyle(
// //             color: colors.textSecondary,
// //             fontSize: 12,
// //             height: 1.4,
// //           ),
// //         ),
// //       ],
// //     );
// //   }

// //   // ═══════════════════════════════════════════════════════════════════
// //   // STAT CARDS
// //   // ═══════════════════════════════════════════════════════════════════

// //   Widget _buildStats(
// //     NotificationProvider provider,
// //     AppColorScheme colors, {
// //     required bool isMobile,
// //   }) {
// //     final totalRecipients = provider.history.fold<int>(
// //       0,
// //       (sum, notification) => sum + notification.recipientCount,
// //     );

// //     final totalBroadcasts = provider.history.length;

// //     final scheduledCount = provider.history
// //         .where(
// //           (notification) => notification.scheduled,
// //         )
// //         .length;

// //     final cards = [
// //       _NotificationStat(
// //         label: 'TOTAL RECIPIENTS',
// //         value: _formatNumber(totalRecipients),
// //         subtitle: 'Across all broadcasts',
// //         icon: Icons.people_alt_outlined,
// //         iconColor: AppColors.primary,
// //         iconBackground: AppColors.primary.withOpacity(0.15),
// //       ),
// //       _NotificationStat(
// //         label: 'TOTAL BROADCASTS',
// //         value: _formatNumber(totalBroadcasts),
// //         subtitle: 'Notifications created',
// //         icon: Icons.campaign_outlined,
// //         iconColor: AppColors.info,
// //         iconBackground: AppColors.info.withOpacity(0.15),
// //       ),
// //       _NotificationStat(
// //         label: 'SCHEDULED',
// //         value: _formatNumber(scheduledCount),
// //         subtitle: scheduledCount == 0
// //             ? 'No scheduled broadcasts'
// //             : 'Awaiting delivery',
// //         icon: Icons.schedule_outlined,
// //         iconColor: AppColors.warning,
// //         iconBackground: AppColors.warning.withOpacity(0.15),
// //       ),
// //     ];

// //     if (isMobile) {
// //       return Column(
// //         children: [
// //           for (int i = 0; i < cards.length; i++) ...[
// //             if (i > 0) const SizedBox(height: 12),
// //             _buildStatCard(
// //               cards[i],
// //               colors,
// //             ),
// //           ],
// //         ],
// //       );
// //     }

// //     return Row(
// //       children: [
// //         for (int i = 0; i < cards.length; i++) ...[
// //           if (i > 0) const SizedBox(width: 12),
// //           Expanded(
// //             child: _buildStatCard(
// //               cards[i],
// //               colors,
// //             ),
// //           ),
// //         ],
// //       ],
// //     );
// //   }

// //   Widget _buildStatCard(
// //     _NotificationStat stat,
// //     AppColorScheme colors,
// //   ) {
// //     return Container(
// //       constraints: const BoxConstraints(
// //         minHeight: 94,
// //       ),
// //       padding: const EdgeInsets.fromLTRB(
// //         18,
// //         15,
// //         15,
// //         14,
// //       ),
// //       decoration: BoxDecoration(
// //         color: colors.surface,
// //         borderRadius: BorderRadius.circular(14),
// //         border: Border.all(
// //           color: colors.border,
// //         ),
// //       ),
// //       child: Row(
// //         children: [
// //           Expanded(
// //             child: Column(
// //               crossAxisAlignment: CrossAxisAlignment.start,
// //               children: [
// //                 Text(
// //                   stat.label,
// //                   style: TextStyle(
// //                     color: colors.textMuted,
// //                     fontSize: 10,
// //                     fontWeight: FontWeight.w700,
// //                     letterSpacing: 0.65,
// //                   ),
// //                 ),
// //                 const SizedBox(height: 6),
// //                 Text(
// //                   stat.value,
// //                   style: TextStyle(
// //                     color: colors.textPrimary,
// //                     fontSize: 22,
// //                     fontWeight: FontWeight.bold,
// //                     height: 1,
// //                   ),
// //                 ),
// //                 const SizedBox(height: 6),
// //                 Text(
// //                   stat.subtitle,
// //                   style: TextStyle(
// //                     color: colors.textSecondary,
// //                     fontSize: 10,
// //                     height: 1.2,
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ),
// //           const SizedBox(width: 10),
// //           Container(
// //             width: 38,
// //             height: 38,
// //             alignment: Alignment.center,
// //             decoration: BoxDecoration(
// //               color: stat.iconBackground,
// //               borderRadius: BorderRadius.circular(9),
// //             ),
// //             child: Icon(
// //               stat.icon,
// //               size: 19,
// //               color: stat.iconColor,
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   // ═══════════════════════════════════════════════════════════════════
// //   // COMPOSE CARD
// //   // ═══════════════════════════════════════════════════════════════════

// //   Widget _buildComposeCard(
// //     NotificationProvider provider,
// //     AppColorScheme colors, {
// //     required bool isMobile,
// //   }) {
// //     return Container(
// //       width: double.infinity,
// //       padding: const EdgeInsets.fromLTRB(
// //         20,
// //         18,
// //         20,
// //         18,
// //       ),
// //       decoration: BoxDecoration(
// //         color: colors.surface,
// //         borderRadius: BorderRadius.circular(14),
// //         border: Border.all(
// //           color: colors.border,
// //         ),
// //       ),
// //       child: Column(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           _sectionHeader(
// //             colors,
// //             icon: Icons.edit_outlined,
// //             title: 'Compose',
// //           ),

// //           const SizedBox(height: 20),

// //           _fieldLabel(
// //             colors,
// //             'NOTIFICATION TITLE',
// //           ),

// //           const SizedBox(height: 7),

// //           _buildTextField(
// //             controller: _titleController,
// //             colors: colors,
// //             hint: 'e.g. System Update',
// //             maxLines: 1,
// //           ),

// //           const SizedBox(height: 18),

// //           Row(
// //             children: [
// //               Expanded(
// //                 child: _fieldLabel(
// //                   colors,
// //                   'MESSAGE CONTENT',
// //                 ),
// //               ),
// //               ValueListenableBuilder<TextEditingValue>(
// //                 valueListenable: _messageController,
// //                 builder: (
// //                   _,
// //                   value,
// //                   __,
// //                 ) {
// //                   return Text(
// //                     '${value.text.length}/500',
// //                     style: TextStyle(
// //                       color: colors.textMuted,
// //                       fontSize: 10,
// //                       fontWeight: FontWeight.w500,
// //                     ),
// //                   );
// //                 },
// //               ),
// //             ],
// //           ),

// //           const SizedBox(height: 7),

// //           _buildTextField(
// //             controller: _messageController,
// //             colors: colors,
// //             hint: 'Type your message here...',
// //             maxLines: isMobile ? 6 : 7,
// //             maxLength: 500,
// //             minHeight: 150,
// //           ),

// //           const SizedBox(height: 18),

// //           // Send mode + button.
// //           if (isMobile)
// //             Column(
// //               crossAxisAlignment: CrossAxisAlignment.stretch,
// //               children: [
// //                 _buildSendMode(
// //                   provider,
// //                   colors,
// //                 ),
// //                 const SizedBox(height: 12),
// //                 _buildSendButton(
// //                   provider,
// //                   colors,
// //                 ),
// //               ],
// //             )
// //           else
// //             Row(
// //               children: [
// //                 _buildSendMode(
// //                   provider,
// //                   colors,
// //                 ),
// //                 const Spacer(),
// //                 _buildSendButton(
// //                   provider,
// //                   colors,
// //                 ),
// //               ],
// //             ),

// //           if (provider.errorMessage != null) ...[
// //             const SizedBox(height: 14),
// //             Container(
// //               width: double.infinity,
// //               padding: const EdgeInsets.symmetric(
// //                 horizontal: 12,
// //                 vertical: 10,
// //               ),
// //               decoration: BoxDecoration(
// //                 color: AppColors.danger.withOpacity(0.08),
// //                 borderRadius: BorderRadius.circular(8),
// //                 border: Border.all(
// //                   color: AppColors.danger.withOpacity(0.22),
// //                 ),
// //               ),
// //               child: Row(
// //                 crossAxisAlignment: CrossAxisAlignment.start,
// //                 children: [
// //                   const Icon(
// //                     Icons.error_outline,
// //                     size: 16,
// //                     color: AppColors.danger,
// //                   ),
// //                   const SizedBox(width: 8),
// //                   Expanded(
// //                     child: Text(
// //                       provider.errorMessage!,
// //                       style: const TextStyle(
// //                         color: AppColors.danger,
// //                         fontSize: 11,
// //                         height: 1.3,
// //                       ),
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //             ),
// //           ],
// //         ],
// //       ),
// //     );
// //   }

// //   // ═══════════════════════════════════════════════════════════════════
// //   // SECTION HEADER
// //   // ═══════════════════════════════════════════════════════════════════

// //   Widget _sectionHeader(
// //     AppColorScheme colors, {
// //     required IconData icon,
// //     required String title,
// //   }) {
// //     return Row(
// //       children: [
// //         Container(
// //           width: 28,
// //           height: 28,
// //           alignment: Alignment.center,
// //           decoration: BoxDecoration(
// //             color: AppColors.primary.withOpacity(0.10),
// //             borderRadius: BorderRadius.circular(7),
// //           ),
// //           child: Icon(
// //             icon,
// //             size: 16,
// //             color: AppColors.primary,
// //           ),
// //         ),
// //         const SizedBox(width: 9),
// //         Text(
// //           title,
// //           style: TextStyle(
// //             color: colors.textPrimary,
// //             fontSize: 15,
// //             fontWeight: FontWeight.w600,
// //           ),
// //         ),
// //       ],
// //     );
// //   }

// //   // ═══════════════════════════════════════════════════════════════════
// //   // FIELD LABEL
// //   // ═══════════════════════════════════════════════════════════════════

// //   Widget _fieldLabel(
// //     AppColorScheme colors,
// //     String text,
// //   ) {
// //     return Text(
// //       text,
// //       style: TextStyle(
// //         color: colors.textMuted,
// //         fontSize: 11,
// //         fontWeight: FontWeight.w600,
// //         letterSpacing: 0.55,
// //       ),
// //     );
// //   }

// //   // ═══════════════════════════════════════════════════════════════════
// //   // TEXT FIELD
// //   // ═══════════════════════════════════════════════════════════════════

// //   Widget _buildTextField({
// //     required TextEditingController controller,
// //     required AppColorScheme colors,
// //     required String hint,
// //     required int maxLines,
// //     int? maxLength,
// //     double? minHeight,
// //   }) {
// //     return ConstrainedBox(
// //       constraints: BoxConstraints(
// //         minHeight: minHeight ?? 44,
// //       ),
// //       child: TextField(
// //         controller: controller,
// //         maxLines: maxLines,
// //         maxLength: maxLength,
// //         style: TextStyle(
// //           color: colors.textPrimary,
// //           fontSize: 14,
// //           height: 1.35,
// //         ),
// //         cursorColor: AppColors.primary,
// //         textAlignVertical: TextAlignVertical.top,
// //         decoration: InputDecoration(
// //           hintText: hint,
// //           hintStyle: TextStyle(
// //             color: colors.textMuted,
// //             fontSize: 13,
// //           ),
// //           counterText: '',
// //           filled: true,
// //           fillColor: colors.surfaceVariant,
// //           contentPadding: const EdgeInsets.symmetric(
// //             horizontal: 13,
// //             vertical: 12,
// //           ),
// //           border: OutlineInputBorder(
// //             borderRadius: BorderRadius.circular(8),
// //             borderSide: BorderSide(
// //               color: colors.border,
// //             ),
// //           ),
// //           enabledBorder: OutlineInputBorder(
// //             borderRadius: BorderRadius.circular(8),
// //             borderSide: BorderSide(
// //               color: colors.border,
// //             ),
// //           ),
// //           focusedBorder: OutlineInputBorder(
// //             borderRadius: BorderRadius.circular(8),
// //             borderSide: const BorderSide(
// //               color: AppColors.primary,
// //               width: 1.2,
// //             ),
// //           ),
// //         ),
// //       ),
// //     );
// //   }

// //   // ═══════════════════════════════════════════════════════════════════
// //   // SEND MODE
// //   // ═══════════════════════════════════════════════════════════════════

// //   Widget _buildSendMode(
// //     NotificationProvider provider,
// //     AppColorScheme colors,
// //   ) {
// //     return InkWell(
// //       onTap: () {
// //         provider.setSendImmediately(
// //           !provider.sendImmediately,
// //         );
// //       },
// //       borderRadius: BorderRadius.circular(8),
// //       child: Row(
// //         mainAxisSize: MainAxisSize.min,
// //         children: [
// //           Container(
// //             width: 38,
// //             height: 38,
// //             alignment: Alignment.center,
// //             decoration: BoxDecoration(
// //               color: colors.surfaceVariant,
// //               borderRadius: BorderRadius.circular(8),
// //               border: Border.all(
// //                 color: colors.border,
// //               ),
// //             ),
// //             child: Icon(
// //               provider.sendImmediately
// //                   ? Icons.schedule_send_outlined
// //                   : Icons.schedule_outlined,
// //               size: 18,
// //               color: colors.textSecondary,
// //             ),
// //           ),
// //           const SizedBox(width: 9),
// //           Text(
// //             provider.sendImmediately ? 'Send Now' : 'Schedule',
// //             style: TextStyle(
// //               color: colors.textSecondary,
// //               fontSize: 13,
// //               fontWeight: FontWeight.w500,
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   // ═══════════════════════════════════════════════════════════════════
// //   // SEND BUTTON
// //   // ═══════════════════════════════════════════════════════════════════

// //   Widget _buildSendButton(
// //     NotificationProvider provider,
// //     AppColorScheme colors,
// //   ) {
// //     return SizedBox(
// //       height: 40,
// //       child: ElevatedButton.icon(
// //         onPressed: provider.isLoading
// //             ? null
// //             : () => _sendBroadcast(
// //                   provider,
// //                 ),
// //         icon: provider.isLoading
// //             ? const SizedBox(
// //                 width: 15,
// //                 height: 15,
// //                 child: CircularProgressIndicator(
// //                   strokeWidth: 1.8,
// //                   color: Colors.white,
// //                 ),
// //               )
// //             : const Icon(
// //                 Icons.send_outlined,
// //                 size: 16,
// //               ),
// //         label: Text(
// //           provider.sendImmediately ? 'Send Now' : 'Schedule',
// //         ),
// //         style: ElevatedButton.styleFrom(
// //           padding: const EdgeInsets.symmetric(
// //             horizontal: 18,
// //           ),
// //           textStyle: const TextStyle(
// //             fontSize: 12,
// //             fontWeight: FontWeight.w600,
// //           ),
// //           shape: RoundedRectangleBorder(
// //             borderRadius: BorderRadius.circular(7),
// //           ),
// //         ),
// //       ),
// //     );
// //   }

// //   // ═══════════════════════════════════════════════════════════════════
// //   // SEND
// //   // ═══════════════════════════════════════════════════════════════════

// //   Future<void> _sendBroadcast(
// //     NotificationProvider provider,
// //   ) async {
// //     final success = await provider.sendBroadcast(
// //       title: _titleController.text,
// //       message: _messageController.text,
// //     );

// //     if (!mounted || !success) {
// //       return;
// //     }

// //     _titleController.clear();
// //     _messageController.clear();

// //     ScaffoldMessenger.of(context).showSnackBar(
// //       SnackBar(
// //         content: Text(
// //           provider.sendImmediately
// //               ? 'Broadcast sent successfully.'
// //               : 'Broadcast scheduled successfully.',
// //         ),
// //         behavior: SnackBarBehavior.floating,
// //       ),
// //     );
// //   }

// //   // ═══════════════════════════════════════════════════════════════════
// //   // NOTIFICATION HISTORY
// //   // ═══════════════════════════════════════════════════════════════════

// //   Widget _buildHistoryCard(
// //     NotificationProvider provider,
// //     AppColorScheme colors, {
// //     required bool isMobile,
// //   }) {
// //     return Container(
// //       width: double.infinity,
// //       padding: const EdgeInsets.fromLTRB(
// //         20,
// //         18,
// //         20,
// //         8,
// //       ),
// //       decoration: BoxDecoration(
// //         color: colors.surface,
// //         borderRadius: BorderRadius.circular(14),
// //         border: Border.all(
// //           color: colors.border,
// //         ),
// //       ),
// //       child: Column(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           Row(
// //             children: [
// //               Text(
// //                 'Notification History',
// //                 style: TextStyle(
// //                   color: colors.textPrimary,
// //                   fontSize: 15,
// //                   fontWeight: FontWeight.w600,
// //                 ),
// //               ),
// //               const Spacer(),
// //               TextButton(
// //                 onPressed: () {},
// //                 style: TextButton.styleFrom(
// //                   foregroundColor: AppColors.primary,
// //                   padding: const EdgeInsets.symmetric(
// //                     horizontal: 8,
// //                   ),
// //                   minimumSize: Size.zero,
// //                   tapTargetSize: MaterialTapTargetSize.shrinkWrap,
// //                 ),
// //                 child: const Text(
// //                   'VIEW ALL',
// //                   style: TextStyle(
// //                     fontSize: 12,
// //                     fontWeight: FontWeight.w600,
// //                     letterSpacing: 0.5,
// //                   ),
// //                 ),
// //               ),
// //             ],
// //           ),
// //           const SizedBox(height: 8),
// //           if (provider.history.isEmpty)
// //             _buildEmptyHistory(colors)
// //           else
// //             _buildHistoryTable(
// //               provider.history,
// //               colors,
// //               isMobile: isMobile,
// //             ),
// //         ],
// //       ),
// //     );
// //   }

// //   // ═══════════════════════════════════════════════════════════════════
// //   // HISTORY TABLE
// //   // ═══════════════════════════════════════════════════════════════════

// //   Widget _buildHistoryTable(
// //     List<NotificationModel> history,
// //     AppColorScheme colors, {
// //     required bool isMobile,
// //   }) {
// //     if (isMobile) {
// //       return Column(
// //         children: history
// //             .map(
// //               (notification) => _buildMobileHistoryItem(
// //                 notification,
// //                 colors,
// //               ),
// //             )
// //             .toList(),
// //       );
// //     }

// //     return Column(
// //       children: [
// //         Padding(
// //           padding: const EdgeInsets.symmetric(
// //             vertical: 8,
// //           ),
// //           child: Row(
// //             children: [
// //               _colHeader(
// //                 colors,
// //                 'NOTIFICATION',
// //                 flex: 5,
// //               ),
// //               _colHeader(
// //                 colors,
// //                 'DATE',
// //                 flex: 2,
// //               ),
// //               _colHeader(
// //                 colors,
// //                 'STATUS',
// //                 flex: 2,
// //               ),
// //             ],
// //           ),
// //         ),
// //         Divider(
// //           height: 1,
// //           color: colors.divider,
// //         ),
// //         for (final notification in history)
// //           _buildHistoryRow(
// //             notification,
// //             colors,
// //           ),
// //       ],
// //     );
// //   }

// //   // ═══════════════════════════════════════════════════════════════════
// //   // DASHBOARD-STYLE COLUMN HEADER
// //   // ═══════════════════════════════════════════════════════════════════

// //   Widget _colHeader(
// //     AppColorScheme colors,
// //     String text, {
// //     required int flex,
// //   }) {
// //     return Expanded(
// //       flex: flex,
// //       child: Text(
// //         text,
// //         style: TextStyle(
// //           color: colors.textMuted,
// //           fontSize: 11,
// //           fontWeight: FontWeight.w600,
// //           letterSpacing: 0.5,
// //         ),
// //       ),
// //     );
// //   }

// //   // ═══════════════════════════════════════════════════════════════════
// //   // HISTORY ROW
// //   // ═══════════════════════════════════════════════════════════════════

// //   Widget _buildHistoryRow(
// //     NotificationModel notification,
// //     AppColorScheme colors,
// //   ) {
// //     final statusColor =
// //         notification.scheduled ? AppColors.info : AppColors.success;

// //     return Container(
// //       width: double.infinity,
// //       padding: const EdgeInsets.symmetric(
// //         vertical: 12,
// //       ),
// //       decoration: BoxDecoration(
// //         border: Border(
// //           bottom: BorderSide(
// //             color: colors.divider.withOpacity(0.6),
// //           ),
// //         ),
// //       ),
// //       child: Row(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           // Notification.
// //           Expanded(
// //             flex: 5,
// //             child: Row(
// //               crossAxisAlignment: CrossAxisAlignment.start,
// //               children: [
// //                 Padding(
// //                   padding: const EdgeInsets.only(
// //                     top: 1,
// //                   ),
// //                   child: _notificationDot(
// //                     notification,
// //                     colors,
// //                   ),
// //                 ),
// //                 const SizedBox(width: 10),
// //                 Expanded(
// //                   child: Text(
// //                     notification.title,
// //                     style: TextStyle(
// //                       color: colors.textPrimary,
// //                       fontSize: 13,
// //                       fontWeight: FontWeight.w600,
// //                       height: 1.35,
// //                     ),
// //                     softWrap: true,
// //                     maxLines: null,
// //                     overflow: TextOverflow.visible,
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ),

// //           // Date.
// //           Expanded(
// //             flex: 2,
// //             child: Padding(
// //               padding: const EdgeInsets.only(
// //                 top: 2,
// //               ),
// //               child: Text(
// //                 _formatDate(
// //                   notification.sentAt,
// //                 ),
// //                 style: TextStyle(
// //                   color: colors.textSecondary,
// //                   fontSize: 12,
// //                   height: 1.35,
// //                 ),
// //               ),
// //             ),
// //           ),

// //           // Status.
// //           Expanded(
// //             flex: 2,
// //             child: Padding(
// //               padding: const EdgeInsets.only(
// //                 top: 1,
// //               ),
// //               child: Align(
// //                 alignment: Alignment.topLeft,
// //                 child: _statusBadge(
// //                   notification.scheduled ? 'SCHEDULED' : 'SENT',
// //                   statusColor,
// //                 ),
// //               ),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   // ═══════════════════════════════════════════════════════════════════
// //   // MOBILE HISTORY
// //   // ═══════════════════════════════════════════════════════════════════

// //   Widget _buildMobileHistoryItem(
// //     NotificationModel notification,
// //     AppColorScheme colors,
// //   ) {
// //     final statusColor =
// //         notification.scheduled ? AppColors.info : AppColors.success;

// //     return Container(
// //       width: double.infinity,
// //       padding: const EdgeInsets.symmetric(
// //         vertical: 13,
// //       ),
// //       decoration: BoxDecoration(
// //         border: Border(
// //           bottom: BorderSide(
// //             color: colors.divider.withOpacity(0.6),
// //           ),
// //         ),
// //       ),
// //       child: Row(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           _notificationDot(
// //             notification,
// //             colors,
// //           ),
// //           const SizedBox(width: 10),
// //           Expanded(
// //             child: Column(
// //               crossAxisAlignment: CrossAxisAlignment.start,
// //               children: [
// //                 Text(
// //                   notification.title,
// //                   style: TextStyle(
// //                     color: colors.textPrimary,
// //                     fontSize: 13,
// //                     fontWeight: FontWeight.w600,
// //                     height: 1.35,
// //                   ),
// //                   softWrap: true,
// //                   maxLines: null,
// //                   overflow: TextOverflow.visible,
// //                 ),
// //                 const SizedBox(height: 6),
// //                 Text(
// //                   _formatDate(
// //                     notification.sentAt,
// //                   ),
// //                   style: TextStyle(
// //                     color: colors.textMuted,
// //                     fontSize: 11,
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ),
// //           const SizedBox(width: 10),
// //           _statusBadge(
// //             notification.scheduled ? 'SCHEDULED' : 'SENT',
// //             statusColor,
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   // ═══════════════════════════════════════════════════════════════════
// //   // NOTIFICATION ICON
// //   // ═══════════════════════════════════════════════════════════════════

// //   Widget _notificationDot(
// //     NotificationModel notification,
// //     AppColorScheme colors,
// //   ) {
// //     final iconColor =
// //         notification.scheduled ? AppColors.info : AppColors.primary;

// //     return Container(
// //       width: 28,
// //       height: 28,
// //       alignment: Alignment.center,
// //       decoration: BoxDecoration(
// //         color: iconColor.withOpacity(0.12),
// //         borderRadius: BorderRadius.circular(8),
// //       ),
// //       child: Icon(
// //         notification.scheduled
// //             ? Icons.schedule_outlined
// //             : Icons.notifications_none_outlined,
// //         size: 15,
// //         color: iconColor,
// //       ),
// //     );
// //   }

// //   // ═══════════════════════════════════════════════════════════════════
// //   // STATUS BADGE
// //   // ═══════════════════════════════════════════════════════════════════

// //   Widget _statusBadge(
// //     String text,
// //     Color color,
// //   ) {
// //     return Container(
// //       padding: const EdgeInsets.symmetric(
// //         horizontal: 8,
// //         vertical: 4,
// //       ),
// //       decoration: BoxDecoration(
// //         color: color.withOpacity(0.15),
// //         borderRadius: BorderRadius.circular(6),
// //       ),
// //       child: Text(
// //         text,
// //         style: TextStyle(
// //           color: color,
// //           fontSize: 10,
// //           fontWeight: FontWeight.w700,
// //           letterSpacing: 0.3,
// //         ),
// //       ),
// //     );
// //   }

// //   // ═══════════════════════════════════════════════════════════════════
// //   // EMPTY HISTORY
// //   // ═══════════════════════════════════════════════════════════════════

// //   Widget _buildEmptyHistory(
// //     AppColorScheme colors,
// //   ) {
// //     return Padding(
// //       padding: const EdgeInsets.symmetric(
// //         vertical: 60,
// //       ),
// //       child: Center(
// //         child: Column(
// //           children: [
// //             Container(
// //               width: 46,
// //               height: 46,
// //               alignment: Alignment.center,
// //               decoration: BoxDecoration(
// //                 color: colors.surfaceVariant,
// //                 borderRadius: BorderRadius.circular(
// //                   12,
// //                 ),
// //               ),
// //               child: Icon(
// //                 Icons.notifications_none_outlined,
// //                 size: 23,
// //                 color: colors.textMuted,
// //               ),
// //             ),
// //             const SizedBox(height: 12),
// //             Text(
// //               'No notifications sent yet',
// //               style: TextStyle(
// //                 color: colors.textSecondary,
// //                 fontSize: 13,
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }

// //   // ═══════════════════════════════════════════════════════════════════
// //   // SYSTEM STATUS
// //   // ═══════════════════════════════════════════════════════════════════

// //   Widget _buildSystemStatus(
// //     AppColorScheme colors,
// //   ) {
// //     return Container(
// //       constraints: const BoxConstraints(
// //         minHeight: 36,
// //       ),
// //       padding: const EdgeInsets.symmetric(
// //         horizontal: 12,
// //         vertical: 8,
// //       ),
// //       decoration: BoxDecoration(
// //         color: colors.surface,
// //         borderRadius: BorderRadius.circular(8),
// //         border: Border.all(
// //           color: colors.border,
// //         ),
// //       ),
// //       child: Row(
// //         children: [
// //           Container(
// //             width: 7,
// //             height: 7,
// //             decoration: const BoxDecoration(
// //               color: AppColors.success,
// //               shape: BoxShape.circle,
// //             ),
// //           ),
// //           const SizedBox(width: 8),
// //           Expanded(
// //             child: Text(
// //               'System is monitoring live data streams for notification events.',
// //               style: TextStyle(
// //                 color: colors.textSecondary,
// //                 fontSize: 10,
// //               ),
// //               overflow: TextOverflow.ellipsis,
// //             ),
// //           ),
// //           const SizedBox(width: 12),
// //           Text(
// //             'Core Ops • Online',
// //             style: TextStyle(
// //               color: colors.textMuted,
// //               fontSize: 9,
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   // ═══════════════════════════════════════════════════════════════════
// //   // HELPERS
// //   // ═══════════════════════════════════════════════════════════════════

// //   String _formatNumber(int value) {
// //     if (value < 1000) {
// //       return value.toString();
// //     }

// //     final formatted = value.toString();

// //     final buffer = StringBuffer();

// //     for (int i = 0; i < formatted.length; i++) {
// //       if (i > 0 && (formatted.length - i) % 3 == 0) {
// //         buffer.write(',');
// //       }

// //       buffer.write(formatted[i]);
// //     }

// //     return buffer.toString();
// //   }

// //   String _formatDate(DateTime date) {
// //     const months = [
// //       'Jan',
// //       'Feb',
// //       'Mar',
// //       'Apr',
// //       'May',
// //       'Jun',
// //       'Jul',
// //       'Aug',
// //       'Sep',
// //       'Oct',
// //       'Nov',
// //       'Dec',
// //     ];

// //     final hour = date.hour > 12
// //         ? date.hour - 12
// //         : date.hour == 0
// //             ? 12
// //             : date.hour;

// //     final minute = date.minute.toString().padLeft(
// //           2,
// //           '0',
// //         );

// //     final period = date.hour >= 12 ? 'PM' : 'AM';

// //     return '${months[date.month - 1]} '
// //         '${date.day}, '
// //         '$hour:$minute $period';
// //   }
// // }

// // // ═══════════════════════════════════════════════════════════════════
// // // STAT MODEL
// // // ═══════════════════════════════════════════════════════════════════

// // class _NotificationStat {
// //   final String label;
// //   final String value;
// //   final String subtitle;
// //   final IconData icon;
// //   final Color iconColor;
// //   final Color iconBackground;

// //   const _NotificationStat({
// //     required this.label,
// //     required this.value,
// //     required this.subtitle,
// //     required this.icon,
// //     required this.iconColor,
// //     required this.iconBackground,
// //   });
// // }

// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';

// import '../../core/theme/app_colors.dart';
// import '../../models/notification_model.dart';
// import '../../providers/notification_provider.dart';
// import '../../widgets/loading_indicator.dart';
// import 'notification_history_screen.dart';

// class NotificationsScreen extends StatefulWidget {
//   const NotificationsScreen({super.key});

//   @override
//   State<NotificationsScreen> createState() => _NotificationsScreenState();
// }

// class _NotificationsScreenState extends State<NotificationsScreen> {
//   final TextEditingController _titleController = TextEditingController();

//   final TextEditingController _messageController = TextEditingController();

//   @override
//   void initState() {
//     super.initState();

//     Future.microtask(
//       () => context.read<NotificationProvider>().load(),
//     );
//   }

//   @override
//   void dispose() {
//     _titleController.dispose();
//     _messageController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final provider = context.watch<NotificationProvider>();
//     final colors = AppColors.of(context);

//     return Scaffold(
//       backgroundColor: colors.background,
//       body: provider.isLoading && provider.history.isEmpty
//           ? const LoadingIndicator()
//           : LayoutBuilder(
//               builder: (context, constraints) {
//                 final width = constraints.maxWidth;

//                 final bool isMobile = width < 700;
//                 final bool isTablet = width >= 700 && width < 1050;

//                 return RefreshIndicator(
//                   color: AppColors.primary,
//                   backgroundColor: colors.surface,
//                   onRefresh: provider.load,
//                   child: ListView(
//                     physics: const AlwaysScrollableScrollPhysics(),
//                     padding: EdgeInsets.fromLTRB(
//                       isMobile ? 16 : 24,
//                       16,
//                       isMobile ? 16 : 24,
//                       32,
//                     ),
//                     children: [
//                       _buildPageHeader(
//                         colors,
//                         isMobile: isMobile,
//                       ),
//                       const SizedBox(height: 20),
//                       _buildStats(
//                         provider,
//                         colors,
//                         isMobile: isMobile,
//                       ),
//                       const SizedBox(height: 20),
//                       if (isMobile || isTablet)
//                         _buildComposeCard(
//                           provider,
//                           colors,
//                           isMobile: isMobile,
//                         )
//                       else
//                         Center(
//                           child: ConstrainedBox(
//                             constraints: const BoxConstraints(
//                               maxWidth: 820,
//                             ),
//                             child: _buildComposeCard(
//                               provider,
//                               colors,
//                               isMobile: false,
//                             ),
//                           ),
//                         ),
//                       const SizedBox(height: 20),
//                       _buildHistoryNavigation(
//                         colors,
//                         isMobile: isMobile,
//                       ),
//                       const SizedBox(height: 20),
//                       _buildSystemStatus(colors),
//                     ],
//                   ),
//                 );
//               },
//             ),
//     );
//   }

//   // ═══════════════════════════════════════════════════════════════
//   // HEADER
//   // ═══════════════════════════════════════════════════════════════

//   Widget _buildPageHeader(
//     AppColorScheme colors, {
//     required bool isMobile,
//   }) {
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.end,
//       children: [
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 children: [
//                   const Icon(
//                     Icons.campaign_outlined,
//                     size: 14,
//                     color: AppColors.primary,
//                   ),
//                   const SizedBox(width: 7),
//                   Text(
//                     'COMMUNICATION HUB',
//                     style: TextStyle(
//                       color: AppColors.primary,
//                       fontSize: 10,
//                       fontWeight: FontWeight.w700,
//                       letterSpacing: 0.9,
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 5),
//               Text(
//                 'Broadcast System',
//                 style: TextStyle(
//                   color: colors.textPrimary,
//                   fontSize: 24,
//                   fontWeight: FontWeight.bold,
//                   height: 1.1,
//                 ),
//               ),
//               const SizedBox(height: 5),
//               Text(
//                 'Send important updates and announcements to your customer app users.',
//                 style: TextStyle(
//                   color: colors.textSecondary,
//                   fontSize: 12,
//                   height: 1.4,
//                 ),
//               ),
//             ],
//           ),
//         ),
//         if (!isMobile) ...[
//           const SizedBox(width: 20),
//           OutlinedButton.icon(
//             onPressed: () {
//               Navigator.of(context).push(
//                 MaterialPageRoute(
//                   builder: (_) => const NotificationHistoryScreen(),
//                 ),
//               );
//             },
//             icon: const Icon(
//               Icons.history_outlined,
//               size: 16,
//             ),
//             label: const Text('Notification History'),
//           ),
//         ],
//       ],
//     );
//   }

//   // ═══════════════════════════════════════════════════════════════
//   // STATS
//   // ═══════════════════════════════════════════════════════════════

//   Widget _buildStats(
//     NotificationProvider provider,
//     AppColorScheme colors, {
//     required bool isMobile,
//   }) {
//     final totalRecipients = provider.history.fold<int>(
//       0,
//       (sum, item) => sum + item.recipientCount,
//     );

//     final totalBroadcasts = provider.history.length;

//     final scheduled = provider.history
//         .where(
//           (item) => item.scheduled,
//         )
//         .length;

//     final cards = [
//       _NotificationStat(
//         label: 'TOTAL RECIPIENTS',
//         value: _formatNumber(totalRecipients),
//         subtitle: 'Across all broadcasts',
//         icon: Icons.people_alt_outlined,
//         color: AppColors.primary,
//       ),
//       _NotificationStat(
//         label: 'TOTAL BROADCASTS',
//         value: _formatNumber(totalBroadcasts),
//         subtitle: 'Notifications created',
//         icon: Icons.campaign_outlined,
//         color: AppColors.info,
//       ),
//       _NotificationStat(
//         label: 'SCHEDULED',
//         value: _formatNumber(scheduled),
//         subtitle: 'Upcoming notifications',
//         icon: Icons.schedule_outlined,
//         color: AppColors.warning,
//       ),
//     ];

//     if (isMobile) {
//       return Column(
//         children: [
//           for (final card in cards) ...[
//             if (card != cards.first) const SizedBox(height: 12),
//             _buildStatCard(card, colors),
//           ],
//         ],
//       );
//     }

//     return Row(
//       children: [
//         for (int i = 0; i < cards.length; i++) ...[
//           if (i > 0) const SizedBox(width: 12),
//           Expanded(
//             child: _buildStatCard(
//               cards[i],
//               colors,
//             ),
//           ),
//         ],
//       ],
//     );
//   }

//   Widget _buildStatCard(
//     _NotificationStat stat,
//     AppColorScheme colors,
//   ) {
//     return Container(
//       constraints: const BoxConstraints(
//         minHeight: 96,
//       ),
//       padding: const EdgeInsets.fromLTRB(
//         18,
//         15,
//         15,
//         14,
//       ),
//       decoration: BoxDecoration(
//         color: colors.surface,
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(
//           color: colors.border,
//         ),
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   stat.label,
//                   style: TextStyle(
//                     color: colors.textMuted,
//                     fontSize: 10,
//                     fontWeight: FontWeight.w700,
//                     letterSpacing: 0.65,
//                   ),
//                 ),
//                 const SizedBox(height: 6),
//                 Text(
//                   stat.value,
//                   style: TextStyle(
//                     color: colors.textPrimary,
//                     fontSize: 22,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 5),
//                 Text(
//                   stat.subtitle,
//                   style: TextStyle(
//                     color: colors.textSecondary,
//                     fontSize: 10,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           Container(
//             width: 40,
//             height: 40,
//             decoration: BoxDecoration(
//               color: stat.color.withOpacity(0.12),
//               borderRadius: BorderRadius.circular(9),
//             ),
//             alignment: Alignment.center,
//             child: Icon(
//               stat.icon,
//               size: 19,
//               color: stat.color,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ═══════════════════════════════════════════════════════════════
//   // COMPOSE
//   // ═══════════════════════════════════════════════════════════════

//   Widget _buildComposeCard(
//     NotificationProvider provider,
//     AppColorScheme colors, {
//     required bool isMobile,
//   }) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.fromLTRB(
//         22,
//         20,
//         22,
//         22,
//       ),
//       decoration: BoxDecoration(
//         color: colors.surface,
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(
//           color: colors.border,
//         ),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Container(
//                 width: 30,
//                 height: 30,
//                 alignment: Alignment.center,
//                 decoration: BoxDecoration(
//                   color: AppColors.primary.withOpacity(0.10),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: const Icon(
//                   Icons.edit_outlined,
//                   size: 17,
//                   color: AppColors.primary,
//                 ),
//               ),
//               const SizedBox(width: 9),
//               Text(
//                 'Compose',
//                 style: TextStyle(
//                   color: colors.textPrimary,
//                   fontSize: 16,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ],
//           ),

//           const SizedBox(height: 22),

//           _fieldLabel(
//             colors,
//             'NOTIFICATION TITLE',
//           ),

//           const SizedBox(height: 7),

//           _buildTextField(
//             controller: _titleController,
//             colors: colors,
//             hint: 'e.g. System Update',
//             maxLines: 1,
//           ),

//           const SizedBox(height: 18),

//           Row(
//             children: [
//               Expanded(
//                 child: _fieldLabel(
//                   colors,
//                   'MESSAGE CONTENT',
//                 ),
//               ),
//               ValueListenableBuilder<TextEditingValue>(
//                 valueListenable: _messageController,
//                 builder: (_, value, __) {
//                   return Text(
//                     '${value.text.length}/500',
//                     style: TextStyle(
//                       color: colors.textMuted,
//                       fontSize: 10,
//                     ),
//                   );
//                 },
//               ),
//             ],
//           ),

//           const SizedBox(height: 7),

//           _buildTextField(
//             controller: _messageController,
//             colors: colors,
//             hint: 'Type your message here...',
//             maxLines: isMobile ? 6 : 7,
//             maxLength: 500,
//             minHeight: 150,
//           ),

//           const SizedBox(height: 20),

//           // TWO CLEAR ACTIONS.
//           if (isMobile)
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.stretch,
//               children: [
//                 _buildActionButtons(
//                   provider,
//                   colors,
//                   vertical: true,
//                 ),
//               ],
//             )
//           else
//             _buildActionButtons(
//               provider,
//               colors,
//               vertical: false,
//             ),

//           if (provider.errorMessage != null) ...[
//             const SizedBox(height: 14),
//             _buildError(
//               provider.errorMessage!,
//               colors,
//             ),
//           ],
//         ],
//       ),
//     );
//   }

//   Widget _buildActionButtons(
//     NotificationProvider provider,
//     AppColorScheme colors, {
//     required bool vertical,
//   }) {
//     final buttons = [
//       Expanded(
//         child: OutlinedButton.icon(
//           onPressed: provider.isLoading
//               ? null
//               : () => _showScheduleDialog(
//                     provider,
//                     colors,
//                   ),
//           icon: const Icon(
//             Icons.calendar_month_outlined,
//             size: 17,
//           ),
//           label: const Text('Schedule'),
//           style: OutlinedButton.styleFrom(
//             minimumSize: const Size(double.infinity, 44),
//             foregroundColor: colors.textPrimary,
//             side: BorderSide(
//               color: colors.border,
//             ),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(8),
//             ),
//           ),
//         ),
//       ),
//       const SizedBox(width: 12),
//       Expanded(
//         child: ElevatedButton.icon(
//           onPressed: provider.isLoading ? null : () => _sendNow(provider),
//           icon: provider.isLoading
//               ? const SizedBox(
//                   width: 15,
//                   height: 15,
//                   child: CircularProgressIndicator(
//                     strokeWidth: 1.8,
//                     color: Colors.white,
//                   ),
//                 )
//               : const Icon(
//                   Icons.send_outlined,
//                   size: 17,
//                 ),
//           label: const Text('Send Now'),
//           style: ElevatedButton.styleFrom(
//             minimumSize: const Size(double.infinity, 44),
//             backgroundColor: AppColors.primary,
//             foregroundColor: Colors.white,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(8),
//             ),
//           ),
//         ),
//       ),
//     ];

//     if (vertical) {
//       return Column(
//         children: [
//           buttons[0],
//           const SizedBox(height: 10),
//           buttons[2],
//         ],
//       );
//     }

//     return Row(
//       children: buttons,
//     );
//   }

//   // ═══════════════════════════════════════════════════════════════
//   // SCHEDULE DIALOG
//   // ═══════════════════════════════════════════════════════════════

//   Future<void> _showScheduleDialog(
//     NotificationProvider provider,
//     AppColorScheme colors,
//   ) async {
//     if (_titleController.text.trim().isEmpty ||
//         _messageController.text.trim().isEmpty) {
//       provider.clearError();

//       provider.setError(
//         'Please fill in both notification title and message.',
//       );

//       return;
//     }

//     DateTime? selectedDate;
//     TimeOfDay? selectedTime;

//     await showDialog(
//       context: context,
//       barrierDismissible: true,
//       builder: (dialogContext) {
//         return StatefulBuilder(
//           builder: (
//             context,
//             setDialogState,
//           ) {
//             return Dialog(
//               backgroundColor: Colors.transparent,
//               insetPadding: const EdgeInsets.symmetric(
//                 horizontal: 20,
//                 vertical: 24,
//               ),
//               child: ConstrainedBox(
//                 constraints: const BoxConstraints(
//                   maxWidth: 400,
//                 ),
//                 child: Container(
//                   decoration: BoxDecoration(
//                     color: colors.surface,
//                     borderRadius: BorderRadius.circular(10),
//                     border: Border.all(
//                       color: colors.border,
//                     ),
//                   ),
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       // ─────────────────────────────
//                       // DIALOG HEADER
//                       // ─────────────────────────────

//                       Padding(
//                         padding: const EdgeInsets.fromLTRB(
//                           18,
//                           15,
//                           12,
//                           15,
//                         ),
//                         child: Row(
//                           children: [
//                             const Icon(
//                               Icons.calendar_month_outlined,
//                               size: 18,
//                               color: AppColors.primary,
//                             ),
//                             const SizedBox(width: 10),
//                             Expanded(
//                               child: Text(
//                                 'Schedule Notification',
//                                 style: TextStyle(
//                                   color: colors.textPrimary,
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.w600,
//                                 ),
//                               ),
//                             ),
//                             IconButton(
//                               onPressed: () => Navigator.pop(
//                                 dialogContext,
//                               ),
//                               icon: Icon(
//                                 Icons.close,
//                                 size: 19,
//                                 color: colors.textSecondary,
//                               ),
//                               padding: EdgeInsets.zero,
//                               constraints: const BoxConstraints(
//                                 minWidth: 30,
//                                 minHeight: 30,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),

//                       Divider(
//                         height: 1,
//                         color: colors.divider,
//                       ),

//                       // ─────────────────────────────
//                       // DATE / TIME
//                       // ─────────────────────────────

//                       Padding(
//                         padding: const EdgeInsets.fromLTRB(
//                           20,
//                           18,
//                           20,
//                           20,
//                         ),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             _scheduleFieldLabel(
//                               'Date',
//                               colors,
//                             ),
//                             const SizedBox(height: 7),
//                             _scheduleInput(
//                               colors: colors,
//                               icon: Icons.calendar_today_outlined,
//                               hint: 'MM/DD/YYYY',
//                               value: selectedDate == null
//                                   ? null
//                                   : _formatScheduleDate(
//                                       selectedDate!,
//                                     ),
//                               onTap: () async {
//                                 final now = DateTime.now();

//                                 final picked = await showDatePicker(
//                                   context: context,
//                                   initialDate: selectedDate ?? now,
//                                   firstDate: now,
//                                   lastDate: DateTime(
//                                     now.year + 5,
//                                   ),
//                                   builder: (context, child) {
//                                     return Theme(
//                                       data: Theme.of(
//                                         context,
//                                       ).copyWith(
//                                         colorScheme: Theme.of(
//                                           context,
//                                         ).colorScheme.copyWith(
//                                               primary: AppColors.primary,
//                                             ),
//                                       ),
//                                       child: child!,
//                                     );
//                                   },
//                                 );

//                                 if (picked != null) {
//                                   setDialogState(() {
//                                     selectedDate = picked;
//                                   });
//                                 }
//                               },
//                             ),
//                             const SizedBox(height: 18),
//                             _scheduleFieldLabel(
//                               'Time (Local)',
//                               colors,
//                             ),
//                             const SizedBox(height: 7),
//                             _scheduleInput(
//                               colors: colors,
//                               icon: Icons.access_time_outlined,
//                               hint: '02:30 PM',
//                               value: selectedTime == null
//                                   ? null
//                                   : selectedTime!.format(
//                                       context,
//                                     ),
//                               onTap: () async {
//                                 final picked = await showTimePicker(
//                                   context: context,
//                                   initialTime: selectedTime ?? TimeOfDay.now(),
//                                   builder: (context, child) {
//                                     return Theme(
//                                       data: Theme.of(
//                                         context,
//                                       ).copyWith(
//                                         colorScheme: Theme.of(
//                                           context,
//                                         ).colorScheme.copyWith(
//                                               primary: AppColors.primary,
//                                             ),
//                                       ),
//                                       child: child!,
//                                     );
//                                   },
//                                 );

//                                 if (picked != null) {
//                                   setDialogState(() {
//                                     selectedTime = picked;
//                                   });
//                                 }
//                               },
//                             ),
//                           ],
//                         ),
//                       ),

//                       // ─────────────────────────────
//                       // ACTIONS
//                       // ─────────────────────────────

//                       Container(
//                         padding: const EdgeInsets.fromLTRB(
//                           20,
//                           13,
//                           20,
//                           13,
//                         ),
//                         decoration: BoxDecoration(
//                           color: colors.background.withOpacity(0.45),
//                           border: Border(
//                             top: BorderSide(
//                               color: colors.divider,
//                             ),
//                           ),
//                         ),
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.end,
//                           children: [
//                             OutlinedButton(
//                               onPressed: () => Navigator.pop(
//                                 dialogContext,
//                               ),
//                               style: OutlinedButton.styleFrom(
//                                 minimumSize: const Size(
//                                   75,
//                                   40,
//                                 ),
//                                 padding: const EdgeInsets.symmetric(
//                                   horizontal: 18,
//                                 ),
//                               ),
//                               child: const Text('Cancel'),
//                             ),
//                             const SizedBox(width: 10),
//                             ElevatedButton.icon(
//                               onPressed: selectedDate == null ||
//                                       selectedTime == null
//                                   ? null
//                                   : () async {
//                                       final scheduledAt = DateTime(
//                                         selectedDate!.year,
//                                         selectedDate!.month,
//                                         selectedDate!.day,
//                                         selectedTime!.hour,
//                                         selectedTime!.minute,
//                                       );

//                                       if (!scheduledAt.isAfter(
//                                         DateTime.now(),
//                                       )) {
//                                         provider.setError(
//                                           'Please select a future date and time.',
//                                         );
//                                         return;
//                                       }

//                                       final success =
//                                           await provider.scheduleBroadcast(
//                                         title: _titleController.text,
//                                         message: _messageController.text,
//                                         scheduledAt: scheduledAt,
//                                       );

//                                       if (success && dialogContext.mounted) {
//                                         Navigator.pop(
//                                           dialogContext,
//                                         );

//                                         _titleController.clear();
//                                         _messageController.clear();

//                                         if (mounted) {
//                                           ScaffoldMessenger.of(
//                                             this.context,
//                                           ).showSnackBar(
//                                             const SnackBar(
//                                               content: Text(
//                                                 'Notification scheduled successfully.',
//                                               ),
//                                               behavior:
//                                                   SnackBarBehavior.floating,
//                                             ),
//                                           );
//                                         }
//                                       }
//                                     },
//                               icon: const Icon(
//                                 Icons.send_outlined,
//                                 size: 15,
//                               ),
//                               label: const Text(
//                                 'Schedule Now',
//                               ),
//                               style: ElevatedButton.styleFrom(
//                                 minimumSize: const Size(
//                                   128,
//                                   40,
//                                 ),
//                                 backgroundColor: AppColors.primary,
//                                 foregroundColor: Colors.white,
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(
//                                     6,
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             );
//           },
//         );
//       },
//     );
//   }

//   Widget _scheduleFieldLabel(
//     String text,
//     AppColorScheme colors,
//   ) {
//     return Text(
//       text,
//       style: TextStyle(
//         color: colors.textSecondary,
//         fontSize: 11,
//         fontWeight: FontWeight.w500,
//       ),
//     );
//   }

//   Widget _scheduleInput({
//     required AppColorScheme colors,
//     required IconData icon,
//     required String hint,
//     required VoidCallback onTap,
//     String? value,
//   }) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(7),
//       child: Container(
//         height: 44,
//         width: double.infinity,
//         padding: const EdgeInsets.symmetric(
//           horizontal: 10,
//         ),
//         decoration: BoxDecoration(
//           // Matches your supplied schedule-dialog
//           // reference where these fields are light.
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(7),
//           border: Border.all(
//             color: const Color(0xFFD7D7D7),
//           ),
//         ),
//         child: Row(
//           children: [
//             Icon(
//               icon,
//               size: 16,
//               color: AppColors.primary,
//             ),
//             const SizedBox(width: 9),
//             Text(
//               value ?? hint,
//               style: TextStyle(
//                 color: value == null
//                     ? const Color(0xFFF1A6B0)
//                     : const Color(0xFF333333),
//                 fontSize: 12,
//                 fontWeight: value == null ? FontWeight.w400 : FontWeight.w500,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // ═══════════════════════════════════════════════════════════════
//   // HISTORY NAVIGATION
//   // ═══════════════════════════════════════════════════════════════

//   Widget _buildHistoryNavigation(
//     AppColorScheme colors, {
//     required bool isMobile,
//   }) {
//     return InkWell(
//       borderRadius: BorderRadius.circular(12),
//       onTap: () {
//         Navigator.of(context).push(
//           MaterialPageRoute(
//             builder: (_) => const NotificationHistoryScreen(),
//           ),
//         );
//       },
//       child: Container(
//         padding: const EdgeInsets.symmetric(
//           horizontal: 16,
//           vertical: 14,
//         ),
//         decoration: BoxDecoration(
//           color: colors.surface,
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(
//             color: colors.border,
//           ),
//         ),
//         child: Row(
//           children: [
//             Container(
//               width: 34,
//               height: 34,
//               alignment: Alignment.center,
//               decoration: BoxDecoration(
//                 color: AppColors.primary.withOpacity(
//                   0.10,
//                 ),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: const Icon(
//                 Icons.history_outlined,
//                 size: 18,
//                 color: AppColors.primary,
//               ),
//             ),
//             const SizedBox(width: 11),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'Notification History',
//                     style: TextStyle(
//                       color: colors.textPrimary,
//                       fontSize: 13,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                   const SizedBox(height: 3),
//                   Text(
//                     'View sent and scheduled notifications',
//                     style: TextStyle(
//                       color: colors.textMuted,
//                       fontSize: 11,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             const Icon(
//               Icons.arrow_forward_ios,
//               size: 13,
//               color: AppColors.primary,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // ═══════════════════════════════════════════════════════════════
//   // HELPERS
//   // ═══════════════════════════════════════════════════════════════

//   Widget _fieldLabel(
//     AppColorScheme colors,
//     String text,
//   ) {
//     return Text(
//       text,
//       style: TextStyle(
//         color: colors.textMuted,
//         fontSize: 11,
//         fontWeight: FontWeight.w600,
//         letterSpacing: 0.55,
//       ),
//     );
//   }

//   Widget _buildTextField({
//     required TextEditingController controller,
//     required AppColorScheme colors,
//     required String hint,
//     required int maxLines,
//     int? maxLength,
//     double? minHeight,
//   }) {
//     return ConstrainedBox(
//       constraints: BoxConstraints(
//         minHeight: minHeight ?? 44,
//       ),
//       child: TextField(
//         controller: controller,
//         maxLines: maxLines,
//         maxLength: maxLength,
//         style: TextStyle(
//           color: colors.textPrimary,
//           fontSize: 14,
//           height: 1.35,
//         ),
//         cursorColor: AppColors.primary,
//         textAlignVertical: TextAlignVertical.top,
//         decoration: InputDecoration(
//           hintText: hint,
//           hintStyle: TextStyle(
//             color: colors.textMuted,
//             fontSize: 13,
//           ),
//           counterText: '',
//           filled: true,
//           fillColor: colors.surfaceVariant,
//           contentPadding: const EdgeInsets.symmetric(
//             horizontal: 13,
//             vertical: 12,
//           ),
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(8),
//             borderSide: BorderSide(
//               color: colors.border,
//             ),
//           ),
//           enabledBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(8),
//             borderSide: BorderSide(
//               color: colors.border,
//             ),
//           ),
//           focusedBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(8),
//             borderSide: const BorderSide(
//               color: AppColors.primary,
//               width: 1.2,
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildError(
//     String message,
//     AppColorScheme colors,
//   ) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.symmetric(
//         horizontal: 12,
//         vertical: 10,
//       ),
//       decoration: BoxDecoration(
//         color: AppColors.danger.withOpacity(0.08),
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(
//           color: AppColors.danger.withOpacity(0.2),
//         ),
//       ),
//       child: Row(
//         children: [
//           const Icon(
//             Icons.error_outline,
//             size: 16,
//             color: AppColors.danger,
//           ),
//           const SizedBox(width: 8),
//           Expanded(
//             child: Text(
//               message,
//               style: const TextStyle(
//                 color: AppColors.danger,
//                 fontSize: 11,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _sendNow(
//     NotificationProvider provider,
//   ) async {
//     final success = await provider.sendBroadcast(
//       title: _titleController.text,
//       message: _messageController.text,
//     );

//     if (!mounted || !success) return;

//     _titleController.clear();
//     _messageController.clear();

//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text('Notification sent successfully.'),
//         behavior: SnackBarBehavior.floating,
//       ),
//     );
//   }

//   String _formatScheduleDate(
//     DateTime date,
//   ) {
//     return '${date.month.toString().padLeft(2, '0')}/'
//         '${date.day.toString().padLeft(2, '0')}/'
//         '${date.year}';
//   }

//   String _formatNumber(int value) {
//     if (value < 1000) {
//       return value.toString();
//     }

//     final text = value.toString();
//     final result = StringBuffer();

//     for (int i = 0; i < text.length; i++) {
//       if (i > 0 && (text.length - i) % 3 == 0) {
//         result.write(',');
//       }
//       result.write(text[i]);
//     }

//     return result.toString();
//   }

//   Widget _buildSystemStatus(
//     AppColorScheme colors,
//   ) {
//     return Container(
//       padding: const EdgeInsets.symmetric(
//         horizontal: 12,
//         vertical: 9,
//       ),
//       decoration: BoxDecoration(
//         color: colors.surface,
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(
//           color: colors.border,
//         ),
//       ),
//       child: Row(
//         children: [
//           Container(
//             width: 7,
//             height: 7,
//             decoration: const BoxDecoration(
//               color: AppColors.success,
//               shape: BoxShape.circle,
//             ),
//           ),
//           const SizedBox(width: 8),
//           Expanded(
//             child: Text(
//               'System is monitoring live data streams for notification events.',
//               style: TextStyle(
//                 color: colors.textSecondary,
//                 fontSize: 10,
//               ),
//               overflow: TextOverflow.ellipsis,
//             ),
//           ),
//           Text(
//             'Core Ops • Online',
//             style: TextStyle(
//               color: colors.textMuted,
//               fontSize: 9,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _NotificationStat {
//   final String label;
//   final String value;
//   final String subtitle;
//   final IconData icon;
//   final Color color;

//   const _NotificationStat({
//     required this.label,
//     required this.value,
//     required this.subtitle,
//     required this.icon,
//     required this.color,
//   });
// }

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/loading_indicator.dart';
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
                      isMobile ? 16 : 24,
                      isMobile ? 18 : 20,
                      isMobile ? 16 : 24,
                      32,
                    ),
                    children: [
                      _buildPageHeader(
                        colors,
                        isMobile: isMobile,
                      ),
                      const SizedBox(height: 22),
                      _buildStats(
                        provider,
                        colors,
                        isMobile: isMobile,
                      ),
                      const SizedBox(height: 22),
                      _buildMainContent(
                        provider,
                        colors,
                        isMobile: isMobile,
                        isTablet: isTablet,
                      ),
                      const SizedBox(height: 20),
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
          _buildTextField(
            controller: _titleController,
            colors: colors,
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
          _buildTextField(
            controller: _messageController,
            colors: colors,
            hint: 'Type your message here...',
            maxLines: isMobile ? 7 : 8,
            maxLength: 500,
            minHeight: isMobile ? 155 : 170,
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

  Widget _buildTextField({
    required TextEditingController controller,
    required AppColorScheme colors,
    required String hint,
    required int maxLines,
    int? maxLength,
    double? minHeight,
  }) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: minHeight ?? 46,
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        maxLength: maxLength,
        style: TextStyle(
          color: colors.textPrimary,
          fontSize: 14,
          height: 1.35,
        ),
        cursorColor: AppColors.primary,
        textAlignVertical: TextAlignVertical.top,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: colors.textMuted,
            fontSize: 13,
          ),
          counterText: '',
          filled: true,
          fillColor: colors.surfaceVariant,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: colors.border,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: colors.border,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
              color: AppColors.primary,
              width: 1.2,
            ),
          ),
        ),
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
