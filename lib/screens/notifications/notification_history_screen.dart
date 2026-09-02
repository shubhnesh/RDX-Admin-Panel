// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../../core/theme/app_colors.dart';
// import '../../models/notification_model.dart';
// import '../../providers/notification_provider.dart';
// import '../../widgets/loading_indicator.dart';

// class NotificationHistoryScreen extends StatefulWidget {
//   const NotificationHistoryScreen({
//     super.key,
//   });

//   @override
//   State<NotificationHistoryScreen> createState() =>
//       _NotificationHistoryScreenState();
// }

// class _NotificationHistoryScreenState extends State<NotificationHistoryScreen> {
//   String _statusFilter = 'All Statuses';

//   @override
//   void initState() {
//     super.initState();

//     Future.microtask(
//       () => context.read<NotificationProvider>().load(),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final provider = context.watch<NotificationProvider>();
//     final colors = AppColors.of(context);

//     final filteredNotifications = _filteredNotifications(
//       provider.history,
//     );

//     return Scaffold(
//       backgroundColor: colors.background,
//       body: provider.isLoading && provider.history.isEmpty
//           ? const LoadingIndicator()
//           : LayoutBuilder(
//               builder: (context, constraints) {
//                 final width = constraints.maxWidth;

//                 final isMobile = width < 600;
//                 final isTablet = width >= 600 && width < 1000;

//                 return SingleChildScrollView(
//                   padding: EdgeInsets.fromLTRB(
//                     isMobile
//                         ? 16
//                         : isTablet
//                             ? 20
//                             : 24,
//                     isMobile ? 18 : 24,
//                     isMobile
//                         ? 16
//                         : isTablet
//                             ? 20
//                             : 24,
//                     32,
//                   ),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       _buildHeader(
//                         colors,
//                         isMobile,
//                       ),
//                       SizedBox(
//                         height: isMobile ? 18 : 22,
//                       ),
//                       _buildFilters(
//                         colors,
//                         isMobile,
//                         isTablet,
//                         provider,
//                       ),
//                       SizedBox(
//                         height: isMobile ? 12 : 16,
//                       ),
//                       _buildTable(
//                         colors,
//                         filteredNotifications,
//                         isMobile,
//                         isTablet,
//                         width,
//                       ),
//                     ],
//                   ),
//                 );
//               },
//             ),
//     );
//   }

//   // ============================================================
//   // HEADER
//   // ============================================================

//   Widget _buildHeader(
//     AppColorScheme colors,
//     bool isMobile,
//   ) {
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         IconButton(
//           onPressed: () => Navigator.pop(context),
//           tooltip: 'Back',
//           padding: EdgeInsets.zero,
//           visualDensity: VisualDensity.compact,
//           icon: Icon(
//             Icons.arrow_back,
//             size: 20,
//             color: colors.textSecondary,
//           ),
//         ),
//         const SizedBox(width: 10),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 'Notification History',
//                 style: TextStyle(
//                   color: colors.textPrimary,
//                   fontSize: isMobile ? 21 : 25,
//                   fontWeight: FontWeight.w700,
//                   height: 1.2,
//                 ),
//               ),
//               const SizedBox(height: 6),
//               Text(
//                 'View all sent and scheduled notifications.',
//                 style: TextStyle(
//                   color: colors.textSecondary,
//                   fontSize: 12,
//                   fontWeight: FontWeight.w400,
//                   height: 1.4,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   // ============================================================
//   // FILTERS
//   // ============================================================

//   Widget _buildFilters(
//     AppColorScheme colors,
//     bool isMobile,
//     bool isTablet,
//     NotificationProvider provider,
//   ) {
//     if (isMobile) {
//       return Column(
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           Row(
//             children: [
//               Expanded(
//                 child: _filterButton(
//                   colors,
//                   'Last 7 Days',
//                   Icons.calendar_today_outlined,
//                 ),
//               ),
//               const SizedBox(width: 8),
//               Expanded(
//                 child: _statusDropdown(
//                   colors,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 10),
//           SizedBox(
//             height: 40,
//             width: double.infinity,
//             child: _refreshButton(
//               colors,
//               provider,
//             ),
//           ),
//         ],
//       );
//     }

//     if (isTablet) {
//       return Wrap(
//         spacing: 8,
//         runSpacing: 8,
//         crossAxisAlignment: WrapCrossAlignment.center,
//         children: [
//           _filterButton(
//             colors,
//             'Last 7 Days',
//             Icons.calendar_today_outlined,
//           ),
//           _statusDropdown(colors),
//           _refreshButton(
//             colors,
//             provider,
//           ),
//         ],
//       );
//     }

//     return Row(
//       children: [
//         _filterButton(
//           colors,
//           'Last 7 Days',
//           Icons.calendar_today_outlined,
//         ),
//         const SizedBox(width: 8),
//         _statusDropdown(colors),
//         const Spacer(),
//         _refreshButton(
//           colors,
//           provider,
//         ),
//       ],
//     );
//   }

//   // ============================================================
//   // DATE FILTER BUTTON
//   // ============================================================

//   Widget _filterButton(
//     AppColorScheme colors,
//     String text,
//     IconData icon,
//   ) {
//     return SizedBox(
//       height: 40,
//       child: OutlinedButton.icon(
//         onPressed: () {},
//         icon: Icon(
//           icon,
//           size: 15,
//           color: colors.textSecondary,
//         ),
//         label: Text(
//           text,
//           style: TextStyle(
//             fontSize: 11,
//             fontWeight: FontWeight.w500,
//             color: colors.textSecondary,
//           ),
//         ),
//         style: OutlinedButton.styleFrom(
//           foregroundColor: colors.textSecondary,
//           backgroundColor: colors.surface,
//           side: BorderSide(
//             color: colors.border,
//           ),
//           padding: const EdgeInsets.symmetric(
//             horizontal: 12,
//           ),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(7),
//           ),
//           minimumSize: const Size(0, 40),
//           tapTargetSize: MaterialTapTargetSize.shrinkWrap,
//         ),
//       ),
//     );
//   }

//   // ============================================================
//   // STATUS DROPDOWN
//   // ============================================================

//   Widget _statusDropdown(
//     AppColorScheme colors,
//   ) {
//     return Container(
//       height: 40,
//       padding: const EdgeInsets.symmetric(
//         horizontal: 11,
//       ),
//       decoration: BoxDecoration(
//         color: colors.surface,
//         borderRadius: BorderRadius.circular(7),
//         border: Border.all(
//           color: colors.border,
//         ),
//       ),
//       child: DropdownButtonHideUnderline(
//         child: DropdownButton<String>(
//           value: _statusFilter,
//           isDense: true,
//           dropdownColor: colors.surface,
//           icon: Icon(
//             Icons.keyboard_arrow_down,
//             size: 17,
//             color: colors.textSecondary,
//           ),
//           style: TextStyle(
//             color: colors.textSecondary,
//             fontSize: 11,
//             fontWeight: FontWeight.w500,
//           ),
//           items: const [
//             'All Statuses',
//             'Sent',
//             'Scheduled',
//           ].map(
//             (value) {
//               return DropdownMenuItem<String>(
//                 value: value,
//                 child: Text(value),
//               );
//             },
//           ).toList(),
//           onChanged: (value) {
//             if (value == null) {
//               return;
//             }

//             setState(() {
//               _statusFilter = value;
//             });
//           },
//         ),
//       ),
//     );
//   }

//   // ============================================================
//   // REFRESH BUTTON
//   // ============================================================

//   Widget _refreshButton(
//     AppColorScheme colors,
//     NotificationProvider provider,
//   ) {
//     return SizedBox(
//       height: 40,
//       child: OutlinedButton.icon(
//         onPressed: provider.isLoading
//             ? null
//             : () async {
//                 await context.read<NotificationProvider>().load();
//               },
//         icon: provider.isLoading
//             ? SizedBox(
//                 width: 14,
//                 height: 14,
//                 child: CircularProgressIndicator(
//                   strokeWidth: 1.7,
//                   color: colors.textSecondary,
//                 ),
//               )
//             : const Icon(
//                 Icons.refresh,
//                 size: 16,
//               ),
//         label: const Text(
//           'Refresh',
//           style: TextStyle(
//             fontSize: 11,
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//         style: OutlinedButton.styleFrom(
//           foregroundColor: colors.textSecondary,
//           backgroundColor: colors.surface,
//           disabledForegroundColor: colors.textMuted,
//           side: BorderSide(
//             color: colors.border,
//           ),
//           padding: const EdgeInsets.symmetric(
//             horizontal: 13,
//           ),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(7),
//           ),
//           minimumSize: const Size(0, 40),
//           tapTargetSize: MaterialTapTargetSize.shrinkWrap,
//         ),
//       ),
//     );
//   }

//   // ============================================================
//   // TABLE
//   // ============================================================

//   Widget _buildTable(
//     AppColorScheme colors,
//     List<NotificationModel> notifications,
//     bool isMobile,
//     bool isTablet,
//     double availableWidth,
//   ) {
//     if (notifications.isEmpty) {
//       return _buildEmptyState(colors);
//     }

//     /*
//      * Minimum table width.
//      *
//      * Mobile:
//      *   Table intentionally becomes horizontally scrollable.
//      *
//      * Tablet:
//      *   Table gets a little more room but still has a safe
//      *   minimum width so columns do not become unusably small.
//      *
//      * Desktop:
//      *   Table expands to the available width.
//      */
//     final double minimumTableWidth = isMobile
//         ? 760
//         : isTablet
//             ? 790
//             : 0;

//     final double tableWidth =
//         isMobile || isTablet ? minimumTableWidth : availableWidth;

//     return Container(
//       width: double.infinity,
//       decoration: BoxDecoration(
//         color: colors.surface,
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(
//           color: colors.border,
//         ),
//       ),
//       clipBehavior: Clip.antiAlias,
//       child: LayoutBuilder(
//         builder: (context, tableConstraints) {
//           final contentWidth = tableConstraints.maxWidth;

//           final effectiveWidth =
//               contentWidth < tableWidth ? tableWidth : contentWidth;

//           return SingleChildScrollView(
//             scrollDirection: Axis.horizontal,
//             physics: const ClampingScrollPhysics(),
//             child: SizedBox(
//               width: effectiveWidth,
//               child: Column(
//                 children: [
//                   _tableHeader(
//                     colors,
//                     effectiveWidth,
//                   ),
//                   Divider(
//                     height: 1,
//                     thickness: 1,
//                     color: colors.divider,
//                   ),
//                   for (int i = 0; i < notifications.length; i++) ...[
//                     _tableRow(
//                       colors,
//                       notifications[i],
//                       effectiveWidth,
//                     ),
//                     if (i != notifications.length - 1)
//                       Divider(
//                         height: 1,
//                         thickness: 1,
//                         color: colors.divider,
//                       ),
//                   ],
//                   Divider(
//                     height: 1,
//                     thickness: 1,
//                     color: colors.divider,
//                   ),
//                   _tableFooter(
//                     colors,
//                     notifications.length,
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }

//   // ============================================================
//   // EMPTY STATE
//   // ============================================================

//   Widget _buildEmptyState(
//     AppColorScheme colors,
//   ) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.symmetric(
//         horizontal: 24,
//         vertical: 52,
//       ),
//       decoration: BoxDecoration(
//         color: colors.surface,
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(
//           color: colors.border,
//         ),
//       ),
//       child: Column(
//         children: [
//           Container(
//             width: 52,
//             height: 52,
//             alignment: Alignment.center,
//             decoration: BoxDecoration(
//               color: colors.surfaceVariant,
//               shape: BoxShape.circle,
//             ),
//             child: Icon(
//               Icons.notifications_none_outlined,
//               size: 25,
//               color: colors.textMuted,
//             ),
//           ),
//           const SizedBox(height: 14),
//           Text(
//             'No notifications found',
//             style: TextStyle(
//               color: colors.textPrimary,
//               fontSize: 14,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//           const SizedBox(height: 5),
//           Text(
//             'Sent and scheduled notifications will appear here.',
//             textAlign: TextAlign.center,
//             style: TextStyle(
//               color: colors.textMuted,
//               fontSize: 11,
//               height: 1.4,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ============================================================
//   // TABLE HEADER
//   // ============================================================

//   Widget _tableHeader(
//     AppColorScheme colors,
//     double tableWidth,
//   ) {
//     final widths = _columnWidths(tableWidth);

//     return Container(
//       height: 46,
//       padding: const EdgeInsets.symmetric(
//         horizontal: 18,
//       ),
//       color: colors.surfaceVariant.withOpacity(0.35),
//       child: Row(
//         children: [
//           _colHeader(
//             'STATUS',
//             width: widths.status,
//             colors: colors,
//           ),
//           _colHeader(
//             'NOTIFICATION TITLE',
//             width: widths.title,
//             colors: colors,
//           ),
//           _colHeader(
//             'DATE / TIME',
//             width: widths.date,
//             colors: colors,
//           ),
//           _colHeader(
//             'ACTIONS',
//             width: widths.actions,
//             colors: colors,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _colHeader(
//     String text, {
//     required double width,
//     required AppColorScheme colors,
//   }) {
//     return SizedBox(
//       width: width,
//       child: Text(
//         text,
//         maxLines: 1,
//         overflow: TextOverflow.ellipsis,
//         style: TextStyle(
//           color: colors.textMuted,
//           fontSize: 11,
//           fontWeight: FontWeight.w600,
//           letterSpacing: 0.5,
//         ),
//       ),
//     );
//   }

//   // ============================================================
//   // TABLE ROW
//   // ============================================================

//   Widget _tableRow(
//     AppColorScheme colors,
//     NotificationModel item,
//     double tableWidth,
//   ) {
//     final status = item.scheduled ? 'Scheduled' : 'Sent';

//     final statusColor = item.scheduled ? AppColors.warning : AppColors.success;

//     final date = item.scheduledAt ?? item.sentAt ?? item.createdAt;

//     final widths = _columnWidths(tableWidth);

//     return Container(
//       constraints: const BoxConstraints(
//         minHeight: 72,
//       ),
//       padding: const EdgeInsets.symmetric(
//         horizontal: 18,
//         vertical: 11,
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: [
//           // ------------------------------------------------------
//           // STATUS
//           // ------------------------------------------------------

//           SizedBox(
//             width: widths.status,
//             child: Row(
//               children: [
//                 Container(
//                   width: 7,
//                   height: 7,
//                   decoration: BoxDecoration(
//                     color: statusColor,
//                     shape: BoxShape.circle,
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 Flexible(
//                   child: Text(
//                     status,
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                     style: TextStyle(
//                       color: colors.textSecondary,
//                       fontSize: 13,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           // ------------------------------------------------------
//           // NOTIFICATION TITLE
//           // ------------------------------------------------------

//           SizedBox(
//             width: widths.title,
//             child: Padding(
//               padding: const EdgeInsets.only(
//                 right: 14,
//               ),
//               child: Text(
//                 item.title,
//                 maxLines: 2,
//                 overflow: TextOverflow.ellipsis,
//                 style: TextStyle(
//                   color: colors.textPrimary,
//                   fontSize: 13,
//                   fontWeight: FontWeight.w500,
//                   height: 1.35,
//                 ),
//               ),
//             ),
//           ),

//           // ------------------------------------------------------
//           // DATE / TIME
//           // ------------------------------------------------------

//           SizedBox(
//             width: widths.date,
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   _formatDate(date),
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                   style: TextStyle(
//                     color: colors.textSecondary,
//                     fontSize: 12,
//                     fontWeight: FontWeight.w400,
//                   ),
//                 ),
//                 const SizedBox(height: 3),
//                 Text(
//                   _formatTime(date),
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                   style: TextStyle(
//                     color: colors.textMuted,
//                     fontSize: 11,
//                     fontWeight: FontWeight.w400,
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           // ------------------------------------------------------
//           // ACTIONS
//           // ------------------------------------------------------

//           SizedBox(
//             width: widths.actions,
//             child: Row(
//               children: [
//                 _tableActionButton(
//                   colors: colors,
//                   icon: Icons.visibility_outlined,
//                   tooltip: 'View',
//                   onPressed: () {},
//                 ),
//                 if (item.scheduled) ...[
//                   const SizedBox(width: 4),
//                   _tableActionButton(
//                     colors: colors,
//                     icon: Icons.edit_outlined,
//                     tooltip: 'Edit',
//                     onPressed: () {},
//                   ),
//                 ],
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ============================================================
//   // RESPONSIVE COLUMN WIDTHS
//   // ============================================================

//   _NotificationColumnWidths _columnWidths(
//     double tableWidth,
//   ) {
//     /*
//      * Horizontal padding = 18 left + 18 right.
//      */
//     const horizontalPadding = 36.0;

//     final available = tableWidth - horizontalPadding;

//     /*
//      * Minimum usable widths.
//      */
//     const minStatus = 105.0;
//     const minTitle = 300.0;
//     const minDate = 150.0;
//     const minActions = 85.0;

//     const minimumTotal = minStatus + minTitle + minDate + minActions;

//     /*
//      * For normal desktop widths, distribute the extra
//      * space primarily to the notification title.
//      */
//     if (available >= minimumTotal) {
//       final extra = available - minimumTotal;

//       return _NotificationColumnWidths(
//         status: minStatus + extra * 0.10,
//         title: minTitle + extra * 0.65,
//         date: minDate + extra * 0.15,
//         actions: minActions + extra * 0.10,
//       );
//     }

//     /*
//      * This should normally only happen when the table is
//      * horizontally constrained.
//      */
//     return const _NotificationColumnWidths(
//       status: minStatus,
//       title: minTitle,
//       date: minDate,
//       actions: minActions,
//     );
//   }

//   // ============================================================
//   // TABLE ACTION BUTTON
//   // ============================================================

//   Widget _tableActionButton({
//     required AppColorScheme colors,
//     required IconData icon,
//     required String tooltip,
//     required VoidCallback onPressed,
//   }) {
//     return Tooltip(
//       message: tooltip,
//       child: InkWell(
//         onTap: onPressed,
//         borderRadius: BorderRadius.circular(6),
//         child: SizedBox(
//           width: 32,
//           height: 32,
//           child: Center(
//             child: Icon(
//               icon,
//               size: 16,
//               color: colors.textMuted,
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   // ============================================================
//   // FOOTER
//   // ============================================================

//   Widget _tableFooter(
//     AppColorScheme colors,
//     int count,
//   ) {
//     return Container(
//       height: 48,
//       padding: const EdgeInsets.symmetric(
//         horizontal: 18,
//       ),
//       child: Row(
//         children: [
//           Flexible(
//             child: Text(
//               'Showing 1-$count of $count notifications',
//               maxLines: 1,
//               overflow: TextOverflow.ellipsis,
//               style: TextStyle(
//                 color: colors.textMuted,
//                 fontSize: 10,
//                 fontWeight: FontWeight.w400,
//               ),
//             ),
//           ),
//           const SizedBox(width: 12),
//           _paginationButton(
//             colors,
//             'Prev',
//             enabled: false,
//           ),
//           const SizedBox(width: 6),
//           _paginationButton(
//             colors,
//             'Next',
//             enabled: false,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _paginationButton(
//     AppColorScheme colors,
//     String text, {
//     required bool enabled,
//   }) {
//     return Container(
//       height: 28,
//       padding: const EdgeInsets.symmetric(
//         horizontal: 10,
//       ),
//       alignment: Alignment.center,
//       decoration: BoxDecoration(
//         color: colors.surfaceVariant,
//         borderRadius: BorderRadius.circular(6),
//         border: Border.all(
//           color: colors.border,
//         ),
//       ),
//       child: Text(
//         text,
//         style: TextStyle(
//           color: enabled ? colors.textSecondary : colors.textMuted,
//           fontSize: 10,
//           fontWeight: FontWeight.w500,
//         ),
//       ),
//     );
//   }

//   // ============================================================
//   // FILTERING
//   // ============================================================

//   List<NotificationModel> _filteredNotifications(
//     List<NotificationModel> notifications,
//   ) {
//     switch (_statusFilter) {
//       case 'Sent':
//         return notifications
//             .where(
//               (item) => !item.scheduled,
//             )
//             .toList();

//       case 'Scheduled':
//         return notifications
//             .where(
//               (item) => item.scheduled,
//             )
//             .toList();

//       default:
//         return notifications;
//     }
//   }

//   // ============================================================
//   // DATE / TIME
//   // ============================================================

//   String _formatDate(DateTime date) {
//     return '${_month(date.month)} '
//         '${date.day}, '
//         '${date.year}';
//   }

//   String _formatTime(DateTime date) {
//     final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;

//     final minute = date.minute.toString().padLeft(2, '0');

//     final period = date.hour >= 12 ? 'PM' : 'AM';

//     return '$hour:$minute $period';
//   }

//   String _month(int month) {
//     const months = [
//       'Jan',
//       'Feb',
//       'Mar',
//       'Apr',
//       'May',
//       'Jun',
//       'Jul',
//       'Aug',
//       'Sep',
//       'Oct',
//       'Nov',
//       'Dec',
//     ];

//     return months[month - 1];
//   }
// }

// // ============================================================
// // RESPONSIVE TABLE COLUMN MODEL
// // ============================================================

// class _NotificationColumnWidths {
//   final double status;
//   final double title;
//   final double date;
//   final double actions;

//   const _NotificationColumnWidths({
//     required this.status,
//     required this.title,
//     required this.date,
//     required this.actions,
//   });
// }

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../models/notification_model.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/loading_indicator.dart';

class NotificationHistoryScreen extends StatefulWidget {
  const NotificationHistoryScreen({
    super.key,
  });

  @override
  State<NotificationHistoryScreen> createState() =>
      _NotificationHistoryScreenState();
}

class _NotificationHistoryScreenState extends State<NotificationHistoryScreen> {
  String _statusFilter = 'All Statuses';

  @override
  void initState() {
    super.initState();

    Future.microtask(
      () => context.read<NotificationProvider>().load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final colors = AppColors.of(context);

    final filteredNotifications = _filteredNotifications(
      provider.history,
    );

    return Scaffold(
      backgroundColor: colors.background,
      body: provider.isLoading && provider.history.isEmpty
          ? const LoadingIndicator()
          : LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;

                final isMobile = width < 600;
                final isTablet = width >= 600 && width < 1000;

                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    isMobile
                        ? 16
                        : isTablet
                            ? 20
                            : 24,
                    isMobile ? 18 : 24,
                    isMobile
                        ? 16
                        : isTablet
                            ? 20
                            : 24,
                    32,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(
                        colors,
                        isMobile,
                      ),
                      SizedBox(
                        height: isMobile ? 20 : 24,
                      ),
                      _buildFilters(
                        colors,
                        isMobile,
                        isTablet,
                        provider,
                      ),
                      SizedBox(
                        height: isMobile ? 14 : 18,
                      ),
                      _buildTable(
                        colors,
                        filteredNotifications,
                        isMobile,
                        isTablet,
                        width,
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(
    AppColorScheme colors,
    bool isMobile,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _backButton(colors),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Notification History',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: isMobile ? 21 : 25,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'View and manage all sent and scheduled notifications.',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _backButton(
    AppColorScheme colors,
  ) {
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(7),
      child: InkWell(
        onTap: () => Navigator.pop(context),
        borderRadius: BorderRadius.circular(7),
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: colors.border,
            ),
          ),
          child: Icon(
            Icons.arrow_back,
            size: 18,
            color: colors.textSecondary,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // FILTERS
  // ============================================================

  Widget _buildFilters(
    AppColorScheme colors,
    bool isMobile,
    bool isTablet,
    NotificationProvider provider,
  ) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _filterButton(
                  colors,
                  'Last 7 Days',
                  Icons.calendar_today_outlined,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _statusDropdown(colors),
              ),
            ],
          ),
          const SizedBox(height: 9),
          SizedBox(
            height: 40,
            width: double.infinity,
            child: _refreshButton(
              colors,
              provider,
            ),
          ),
        ],
      );
    }

    if (isTablet) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _filterButton(
            colors,
            'Last 7 Days',
            Icons.calendar_today_outlined,
          ),
          _statusDropdown(colors),
          _refreshButton(
            colors,
            provider,
          ),
        ],
      );
    }

    return Row(
      children: [
        _filterButton(
          colors,
          'Last 7 Days',
          Icons.calendar_today_outlined,
        ),
        const SizedBox(width: 8),
        _statusDropdown(colors),
        const Spacer(),
        _refreshButton(
          colors,
          provider,
        ),
      ],
    );
  }

  // ============================================================
  // DATE FILTER
  // ============================================================

  Widget _filterButton(
    AppColorScheme colors,
    String text,
    IconData icon,
  ) {
    return SizedBox(
      height: 40,
      child: OutlinedButton.icon(
        onPressed: () {},
        icon: Icon(
          icon,
          size: 15,
          color: colors.textSecondary,
        ),
        label: Text(
          text,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.textSecondary,
          backgroundColor: colors.surface,
          side: BorderSide(
            color: colors.border,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(7),
          ),
          minimumSize: const Size(0, 40),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }

  // ============================================================
  // STATUS DROPDOWN
  // ============================================================

  Widget _statusDropdown(
    AppColorScheme colors,
  ) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: colors.border,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _statusFilter,
          isDense: true,
          dropdownColor: colors.surface,
          icon: Icon(
            Icons.keyboard_arrow_down,
            size: 17,
            color: colors.textSecondary,
          ),
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
          items: const [
            'All Statuses',
            'Sent',
            'Scheduled',
          ].map(
            (value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            },
          ).toList(),
          onChanged: (value) {
            if (value == null) {
              return;
            }

            setState(() {
              _statusFilter = value;
            });
          },
        ),
      ),
    );
  }

  // ============================================================
  // REFRESH BUTTON
  // ============================================================

  Widget _refreshButton(
    AppColorScheme colors,
    NotificationProvider provider,
  ) {
    final isLoading = provider.isLoading;

    return SizedBox(
      height: 40,
      child: ElevatedButton.icon(
        onPressed: isLoading
            ? null
            : () async {
                await context.read<NotificationProvider>().load();
              },
        icon: isLoading
            ? SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 1.7,
                  color: Colors.white.withOpacity(0.9),
                ),
              )
            : const Icon(
                Icons.refresh,
                size: 16,
              ),
        label: const Text(
          'Refresh',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary.withOpacity(0.55),
          disabledForegroundColor: Colors.white70,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(7),
          ),
          minimumSize: const Size(0, 40),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }

  // ============================================================
  // TABLE
  // ============================================================

  Widget _buildTable(
    AppColorScheme colors,
    List<NotificationModel> notifications,
    bool isMobile,
    bool isTablet,
    double availableWidth,
  ) {
    if (notifications.isEmpty) {
      return _buildEmptyState(colors);
    }

    final minimumTableWidth = isMobile
        ? 760.0
        : isTablet
            ? 790.0
            : 0.0;

    final tableWidth =
        isMobile || isTablet ? minimumTableWidth : availableWidth;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colors.border,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final effectiveWidth = constraints.maxWidth < tableWidth
              ? tableWidth
              : constraints.maxWidth;

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            child: SizedBox(
              width: effectiveWidth,
              child: Column(
                children: [
                  _tableHeader(
                    colors,
                    effectiveWidth,
                  ),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: colors.divider,
                  ),
                  for (int i = 0; i < notifications.length; i++) ...[
                    _tableRow(
                      colors,
                      notifications[i],
                      effectiveWidth,
                    ),
                    if (i != notifications.length - 1)
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: colors.divider,
                      ),
                  ],
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: colors.divider,
                  ),
                  _tableFooter(
                    colors,
                    notifications.length,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState(
    AppColorScheme colors,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 52,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colors.border,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none_outlined,
              size: 26,
              color: AppColors.primary.withOpacity(0.75),
            ),
          ),
          const SizedBox(height: 15),
          Text(
            'No notifications found',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Sent and scheduled notifications will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TABLE HEADER
  // ============================================================

  Widget _tableHeader(
    AppColorScheme colors,
    double tableWidth,
  ) {
    final widths = _columnWidths(tableWidth);

    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
      ),
      color: colors.surfaceVariant.withOpacity(0.35),
      child: Row(
        children: [
          _colHeader(
            'STATUS',
            width: widths.status,
            colors: colors,
          ),
          _colHeader(
            'NOTIFICATION TITLE',
            width: widths.title,
            colors: colors,
          ),
          _colHeader(
            'DATE / TIME',
            width: widths.date,
            colors: colors,
          ),
          _colHeader(
            'ACTIONS',
            width: widths.actions,
            colors: colors,
          ),
        ],
      ),
    );
  }

  Widget _colHeader(
    String text, {
    required double width,
    required AppColorScheme colors,
  }) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: colors.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ============================================================
  // TABLE ROW
  // ============================================================

  Widget _tableRow(
    AppColorScheme colors,
    NotificationModel item,
    double tableWidth,
  ) {
    final status = item.scheduled ? 'Scheduled' : 'Sent';

    final statusColor = item.scheduled ? AppColors.warning : AppColors.success;

    final date = item.scheduledAt ?? item.sentAt ?? item.createdAt;

    final widths = _columnWidths(tableWidth);

    return Container(
      constraints: const BoxConstraints(
        minHeight: 72,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 11,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // STATUS
          SizedBox(
            width: widths.status,
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    status,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // TITLE
          SizedBox(
            width: widths.title,
            child: Padding(
              padding: const EdgeInsets.only(
                right: 18,
              ),
              child: Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                ),
              ),
            ),
          ),

          // DATE / TIME
          SizedBox(
            width: widths.date,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(date),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _formatTime(date),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // ACTIONS
          SizedBox(
            width: widths.actions,
            child: Row(
              children: [
                _tableActionButton(
                  colors: colors,
                  icon: Icons.visibility_outlined,
                  tooltip: 'View notification',
                  onPressed: () {},
                ),
                if (item.scheduled) ...[
                  const SizedBox(width: 4),
                  _tableActionButton(
                    colors: colors,
                    icon: Icons.edit_outlined,
                    tooltip: 'Edit notification',
                    onPressed: () {},
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RESPONSIVE COLUMN WIDTHS
  // ============================================================

  _NotificationColumnWidths _columnWidths(
    double tableWidth,
  ) {
    const horizontalPadding = 36.0;

    final available = tableWidth - horizontalPadding;

    const minStatus = 105.0;
    const minTitle = 300.0;
    const minDate = 150.0;
    const minActions = 85.0;

    const minimumTotal = minStatus + minTitle + minDate + minActions;

    if (available >= minimumTotal) {
      final extra = available - minimumTotal;

      return _NotificationColumnWidths(
        status: minStatus + extra * 0.10,
        title: minTitle + extra * 0.65,
        date: minDate + extra * 0.15,
        actions: minActions + extra * 0.10,
      );
    }

    return const _NotificationColumnWidths(
      status: minStatus,
      title: minTitle,
      date: minDate,
      actions: minActions,
    );
  }

  // ============================================================
  // TABLE ACTION BUTTON
  // ============================================================

  Widget _tableActionButton({
    required AppColorScheme colors,
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              size: 16,
              color: colors.textMuted,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // FOOTER
  // ============================================================

  Widget _tableFooter(
    AppColorScheme colors,
    int count,
  ) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
      ),
      child: Row(
        children: [
          // LEFT SIDE
          Flexible(
            child: Text(
              'Showing 1-$count of $count notifications',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),

          // IMPORTANT:
          // This Spacer forces pagination to the
          // absolute right side of the table.
          const Spacer(),

          // RIGHT SIDE PAGINATION
          _paginationButton(
            colors,
            'Prev',
            enabled: false,
          ),

          const SizedBox(width: 6),

          _paginationButton(
            colors,
            'Next',
            enabled: false,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PAGINATION BUTTON
  // ============================================================

  Widget _paginationButton(
    AppColorScheme colors,
    String text, {
    required bool enabled,
  }) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
      ),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: enabled ? colors.surface : colors.surfaceVariant,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: colors.border,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: enabled ? colors.textSecondary : colors.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ============================================================
  // FILTERING
  // ============================================================

  List<NotificationModel> _filteredNotifications(
    List<NotificationModel> notifications,
  ) {
    switch (_statusFilter) {
      case 'Sent':
        return notifications
            .where(
              (item) => !item.scheduled,
            )
            .toList();

      case 'Scheduled':
        return notifications
            .where(
              (item) => item.scheduled,
            )
            .toList();

      default:
        return notifications;
    }
  }

  // ============================================================
  // DATE / TIME
  // ============================================================

  String _formatDate(DateTime date) {
    return '${_month(date.month)} '
        '${date.day}, '
        '${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;

    final minute = date.minute.toString().padLeft(2, '0');

    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }

  String _month(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return months[month - 1];
  }
}

// ============================================================
// RESPONSIVE TABLE COLUMN MODEL
// ============================================================

class _NotificationColumnWidths {
  final double status;
  final double title;
  final double date;
  final double actions;

  const _NotificationColumnWidths({
    required this.status,
    required this.title,
    required this.date,
    required this.actions,
  });
}
