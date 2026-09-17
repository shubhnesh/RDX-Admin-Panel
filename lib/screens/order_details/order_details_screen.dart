// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';

// import '../../core/theme/app_colors.dart';
// import '../../core/theme/text_styles.dart';
// import '../../core/utils/responsive_size.dart';
// import '../../models/order_model.dart';
// import '../../providers/order_providers.dart'; // or your order detail providers
// import '../../services/order_service.dart';
// import '../../widgets/buttons/rdx_action_button.dart';
// import '../../widgets/reusable_widgets/empty_state.dart';
// import '../../widgets/reusable_widgets/loading_indicator.dart';
// import '../../widgets/reusable_widgets/rdx_header.dart';

// /// Fetches a single order by ID (one-shot + optional stream).
// final orderDetailProvider =
//     FutureProvider.family<OrderModel?, String>((ref, orderId) async {
//   if (orderId.trim().isEmpty) return null;
//   return OrderService().fetchOrderById(orderId);
// });

// class OrderDetailsScreen extends ConsumerWidget {
//   final String orderId;

//   const OrderDetailsScreen({super.key, required this.orderId});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final colors = AppColors.of(context);
//     final asyncOrder = ref.watch(orderDetailProvider(orderId));

//     return Scaffold(
//       backgroundColor: colors.background,
//       body: Column(
//         children: [
//           RdxHeader(
//             title: asyncOrder.when(
//               data: (o) =>
//                   o == null ? 'Order Detail' : 'Order #${_shortId(o.id)}',
//               loading: () => 'Order Detail',
//               error: (_, __) => 'Order Detail',
//             ),
//             showBackButton: true,
//           ),
//           Expanded(
//             child: asyncOrder.when(
//               loading: () => const LoadingIndicator(),
//               error: (e, _) => EmptyState(message: 'Failed to load order.\n$e'),
//               data: (order) {
//                 if (order == null) {
//                   return const EmptyState(message: 'Order not found.');
//                 }
//                 return _OrderDetailBody(order: order);
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   String _shortId(String id) =>
//       id.length >= 4 ? id.substring(id.length - 4) : id;
// }

// class _OrderDetailBody extends ConsumerWidget {
//   final OrderModel order;
//   const _OrderDetailBody({required this.order});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final colors = AppColors.of(context);
//     final narrow = MediaQuery.sizeOf(context).width < 900;

//     // Simple tax calculation (adjust to your real business rules)
//     double subtotal = 0;
//     for (final i in order.items) {
//       subtotal += i.price * i.quantity;
//     }
//     final tax = (order.total - subtotal).clamp(0, double.infinity);
//     final taxPercent = subtotal > 0 ? (tax / subtotal * 100) : 0.0;

//     return Column(
//       children: [
//         Expanded(
//           child: SingleChildScrollView(
//             padding: EdgeInsets.fromLTRB(
//               context.w(20),
//               context.h(12),
//               context.w(20),
//               context.h(20),
//             ),
//             child: narrow
//                 ? Column(
//                     children: [
//                       _ServiceAndCustomer(order: order),
//                       SizedBox(height: context.h(14)),
//                       _OrderItemsSection(order: order),
//                       SizedBox(height: context.h(14)),
//                       _BillingSummary(
//                         subtotal: subtotal,
//                         tax: tax.toDouble(),
//                         taxPercent: taxPercent,
//                         total: order.total,
//                       ),
//                       SizedBox(height: context.h(14)),
//                       _ReceiptPreview(
//                           order: order,
//                           subtotal: subtotal,
//                           tax: tax.toDouble()),
//                     ],
//                   )
//                 : Row(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       // Left column – manage order
//                       Expanded(
//                         flex: 5,
//                         child: Column(
//                           children: [
//                             _ServiceAndCustomer(order: order),
//                             SizedBox(height: context.h(14)),
//                             _OrderItemsSection(order: order),
//                           ],
//                         ),
//                       ),
//                       SizedBox(width: context.w(16)),
//                       // Right column – bill + receipt
//                       Expanded(
//                         flex: 4,
//                         child: Column(
//                           children: [
//                             _BillingSummary(
//                               subtotal: subtotal,
//                               tax: tax.toDouble(),
//                               taxPercent: taxPercent,
//                               total: order.total,
//                             ),
//                             SizedBox(height: context.h(14)),
//                             _ReceiptPreview(
//                                 order: order,
//                                 subtotal: subtotal,
//                                 tax: tax.toDouble()),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//           ),
//         ),
//         // Bottom action bar
//         _BottomBar(order: order),
//       ],
//     );
//   }
// }

// /* ───────────────────────── Service + Customer ───────────────────────── */

// class _ServiceAndCustomer extends StatelessWidget {
//   final OrderModel order;
//   const _ServiceAndCustomer({required this.order});

//   @override
//   Widget build(BuildContext context) {
//     final colors = AppColors.of(context);

//     return Container(
//       width: double.infinity,
//       padding: EdgeInsets.all(context.h(14)),
//       decoration: BoxDecoration(
//         color: colors.surface,
//         borderRadius: BorderRadius.circular(context.h(12)),
//         border: Border.all(color: colors.border),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Order type chips
//           Text('SERVICE OPTION',
//               style: AppTextStyles.caption(context)
//                   .copyWith(color: colors.textMuted, letterSpacing: 0.6)),
//           SizedBox(height: context.h(8)),
//           Row(
//             children: [
//               _chip(context, colors, 'Eat In',
//                   order.orderType == OrderType.dineIn),
//               // SizedBox(width: context.w(8)),
//               // _chip(context, colors, 'To Go',
//               //     order.orderType == OrderType.takeaway),
//               SizedBox(width: context.w(8)),
//               _chip(context, colors, 'Delivery',
//                   order.orderType == OrderType.delivery),
//             ],
//           ),
//           SizedBox(height: context.h(14)),
//           // Table
//           if (order.orderType == OrderType.dineIn) ...[
//             Text('TABLE ASSIGNMENT',
//                 style: AppTextStyles.caption(context)
//                     .copyWith(color: colors.textMuted, letterSpacing: 0.6)),
//             SizedBox(height: context.h(6)),
//             Text(
//               (order.tableNumber?.trim().isNotEmpty ?? false)
//                   ? 'Table ${order.tableNumber}'
//                   : 'No Table / Counter',
//               style: AppTextStyles.body(context).copyWith(
//                   color: colors.textPrimary, fontWeight: FontWeight.w600),
//             ),
//             SizedBox(height: context.h(14)),
//           ],
//           // Customer
//           Text('CUSTOMER & PAYMENT',
//               style: AppTextStyles.caption(context)
//                   .copyWith(color: colors.textMuted, letterSpacing: 0.6)),
//           SizedBox(height: context.h(8)),
//           Row(
//             children: [
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                         order.customerName.isEmpty
//                             ? 'Walk-in'
//                             : order.customerName,
//                         style: AppTextStyles.body(context).copyWith(
//                             color: colors.textPrimary,
//                             fontWeight: FontWeight.w600)),
//                     if (order.customerPhone.isNotEmpty)
//                       Text(order.customerPhone,
//                           style: AppTextStyles.caption(context)
//                               .copyWith(color: colors.textSecondary)),
//                   ],
//                 ),
//               ),
//               if (order.paymentMethod != null)
//                 Container(
//                   padding: EdgeInsets.symmetric(
//                       horizontal: context.w(10), vertical: context.h(4)),
//                   decoration: BoxDecoration(
//                     color: AppColors.primary.withValues(alpha: 0.12),
//                     borderRadius: BorderRadius.circular(context.h(6)),
//                   ),
//                   child: Text(
//                     order.paymentMethod!.label.toUpperCase(),
//                     style: AppTextStyles.caption(context).copyWith(
//                       color: AppColors.primary,
//                       fontWeight: FontWeight.w700,
//                     ),
//                   ),
//                 ),
//             ],
//           ),
//           if (order.notes != null && order.notes!.isNotEmpty) ...[
//             SizedBox(height: context.h(10)),
//             Text('KITCHEN NOTES',
//                 style: AppTextStyles.caption(context)
//                     .copyWith(color: colors.textMuted)),
//             SizedBox(height: context.h(4)),
//             Text(order.notes!,
//                 style: AppTextStyles.bodySecondary(context)
//                     .copyWith(color: colors.textSecondary)),
//           ],
//         ],
//       ),
//     );
//   }

//   Widget _chip(BuildContext context, AppColorScheme colors, String label,
//       bool selected) {
//     return Container(
//       padding: EdgeInsets.symmetric(
//           horizontal: context.w(12), vertical: context.h(6)),
//       decoration: BoxDecoration(
//         color: selected ? AppColors.primary : colors.surfaceVariant,
//         borderRadius: BorderRadius.circular(context.h(8)),
//         border: Border.all(color: selected ? AppColors.primary : colors.border),
//       ),
//       child: Text(
//         label,
//         style: AppTextStyles.label(context).copyWith(
//           color: selected ? Colors.white : colors.textPrimary,
//           fontWeight: FontWeight.w600,
//         ),
//       ),
//     );
//   }
// }

// /* ───────────────────────── Order Items ───────────────────────── */

// class _OrderItemsSection extends StatelessWidget {
//   final OrderModel order;
//   const _OrderItemsSection({required this.order});

//   @override
//   Widget build(BuildContext context) {
//     final colors = AppColors.of(context);

//     return Container(
//       width: double.infinity,
//       padding: EdgeInsets.all(context.h(14)),
//       decoration: BoxDecoration(
//         color: colors.surface,
//         borderRadius: BorderRadius.circular(context.h(12)),
//         border: Border.all(color: colors.border),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Text('ORDER ITEMS',
//                   style: AppTextStyles.caption(context)
//                       .copyWith(color: colors.textMuted, letterSpacing: 0.6)),
//               const Spacer(),
//               Text('${order.items.length} items',
//                   style: AppTextStyles.caption(context)
//                       .copyWith(color: colors.textSecondary)),
//             ],
//           ),
//           SizedBox(height: context.h(12)),
//           for (final item in order.items) ...[
//             Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         item.name,
//                         style: AppTextStyles.body(context).copyWith(
//                             color: colors.textPrimary,
//                             fontWeight: FontWeight.w600),
//                       ),
//                       if (item.spiceLevel != null || item.addOns.isNotEmpty)
//                         Padding(
//                           padding: EdgeInsets.only(top: context.h(2)),
//                           child: Text(
//                             [
//                               if (item.spiceLevel != null) item.spiceLevel!,
//                               ...item.addOns,
//                             ].join(' · '),
//                             style: AppTextStyles.caption(context)
//                                 .copyWith(color: colors.textSecondary),
//                           ),
//                         ),
//                       if (item.notes != null && item.notes!.isNotEmpty)
//                         Padding(
//                           padding: EdgeInsets.only(top: context.h(2)),
//                           child: Text(
//                             'Note: ${item.notes}',
//                             style: AppTextStyles.caption(context).copyWith(
//                                 color: colors.textMuted,
//                                 fontStyle: FontStyle.italic),
//                           ),
//                         ),
//                     ],
//                   ),
//                 ),
//                 Text(
//                   '${item.quantity} × ₹${item.price.toStringAsFixed(0)}',
//                   style: AppTextStyles.body(context)
//                       .copyWith(color: colors.textSecondary),
//                 ),
//                 SizedBox(width: context.w(12)),
//                 Text(
//                   '₹${(item.price * item.quantity).toStringAsFixed(0)}',
//                   style: AppTextStyles.body(context).copyWith(
//                       color: colors.textPrimary, fontWeight: FontWeight.w600),
//                 ),
//               ],
//             ),
//             SizedBox(height: context.h(12)),
//           ],
//         ],
//       ),
//     );
//   }
// }

// /* ───────────────────────── Billing Summary ───────────────────────── */

// class _BillingSummary extends StatelessWidget {
//   final double subtotal;
//   final double tax;
//   final double taxPercent;
//   final double total;

//   const _BillingSummary({
//     required this.subtotal,
//     required this.tax,
//     required this.taxPercent,
//     required this.total,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final colors = AppColors.of(context);

//     return Container(
//       width: double.infinity,
//       padding: EdgeInsets.all(context.h(14)),
//       decoration: BoxDecoration(
//         color: colors.surface,
//         borderRadius: BorderRadius.circular(context.h(12)),
//         border: Border.all(color: colors.border),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text('BILL SUMMARY',
//               style: AppTextStyles.caption(context)
//                   .copyWith(color: colors.textMuted, letterSpacing: 0.6)),
//           SizedBox(height: context.h(12)),
//           _row(context, colors, 'Subtotal', '₹${subtotal.toStringAsFixed(2)}'),
//           SizedBox(height: context.h(6)),
//           _row(
//               context,
//               colors,
//               'Tax & Surcharge (${taxPercent.toStringAsFixed(1)}%)',
//               '₹${tax.toStringAsFixed(2)}'),
//           SizedBox(height: context.h(10)),
//           Divider(color: colors.divider, height: 1),
//           SizedBox(height: context.h(10)),
//           Row(
//             children: [
//               Text('Total Due',
//                   style: AppTextStyles.section(context)
//                       .copyWith(color: colors.textPrimary)),
//               const Spacer(),
//               Text('₹${total.toStringAsFixed(2)}',
//                   style: AppTextStyles.section(context).copyWith(
//                       color: AppColors.primary, fontWeight: FontWeight.w700)),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _row(
//       BuildContext context, AppColorScheme colors, String label, String value) {
//     return Row(
//       children: [
//         Expanded(
//           child: Text(label,
//               style: AppTextStyles.bodySecondary(context)
//                   .copyWith(color: colors.textSecondary)),
//         ),
//         Text(value,
//             style: AppTextStyles.body(context)
//                 .copyWith(color: colors.textPrimary)),
//       ],
//     );
//   }
// }

// /* ───────────────────────── Receipt Preview ───────────────────────── */

// class _ReceiptPreview extends StatelessWidget {
//   final OrderModel order;
//   final double subtotal;
//   final double tax;

//   const _ReceiptPreview({
//     required this.order,
//     required this.subtotal,
//     required this.tax,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final colors = AppColors.of(context);

//     return Container(
//       width: double.infinity,
//       padding: EdgeInsets.all(context.h(16)),
//       decoration: BoxDecoration(
//         color: colors.surface,
//         borderRadius: BorderRadius.circular(context.h(12)),
//         border: Border.all(color: colors.border),
//       ),
//       child: Column(
//         children: [
//           Text('RDX CORE RESTAURANT & BAR',
//               style: AppTextStyles.label(context).copyWith(
//                   color: colors.textPrimary, fontWeight: FontWeight.w700)),
//           SizedBox(height: context.h(2)),
//           Text(
//               'Order #${order.id.length >= 6 ? order.id.substring(0, 6) : order.id}',
//               style: AppTextStyles.caption(context)
//                   .copyWith(color: colors.textMuted)),
//           SizedBox(height: context.h(12)),
//           Divider(color: colors.divider, height: 1),
//           SizedBox(height: context.h(10)),
//           for (final item in order.items)
//             Padding(
//               padding: EdgeInsets.only(bottom: context.h(4)),
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: Text('${item.quantity}x ${item.name}',
//                         style: AppTextStyles.caption(context)
//                             .copyWith(color: colors.textSecondary)),
//                   ),
//                   Text('₹${(item.price * item.quantity).toStringAsFixed(2)}',
//                       style: AppTextStyles.caption(context)
//                           .copyWith(color: colors.textPrimary)),
//                 ],
//               ),
//             ),
//           SizedBox(height: context.h(8)),
//           Divider(color: colors.divider, height: 1),
//           SizedBox(height: context.h(8)),
//           _receiptRow(context, colors, 'Subtotal', subtotal),
//           _receiptRow(context, colors, 'Tax', tax),
//           SizedBox(height: context.h(6)),
//           _receiptRow(context, colors, 'TOTAL', order.total, bold: true),
//           SizedBox(height: context.h(12)),
//           Text('Thank you for dining at RDX!',
//               style: AppTextStyles.caption(context)
//                   .copyWith(color: colors.textMuted)),
//         ],
//       ),
//     );
//   }

//   Widget _receiptRow(
//       BuildContext context, AppColorScheme colors, String label, double value,
//       {bool bold = false}) {
//     return Padding(
//       padding: EdgeInsets.only(bottom: context.h(3)),
//       child: Row(
//         children: [
//           Expanded(
//             child: Text(label,
//                 style: (bold
//                         ? AppTextStyles.label(context)
//                         : AppTextStyles.caption(context))
//                     .copyWith(
//                         color: bold ? colors.textPrimary : colors.textSecondary,
//                         fontWeight: bold ? FontWeight.w700 : FontWeight.w400)),
//           ),
//           Text('₹${value.toStringAsFixed(2)}',
//               style: (bold
//                       ? AppTextStyles.label(context)
//                       : AppTextStyles.caption(context))
//                   .copyWith(
//                       color: colors.textPrimary,
//                       fontWeight: bold ? FontWeight.w700 : FontWeight.w400)),
//         ],
//       ),
//     );
//   }
// }

// /* ───────────────────────── Bottom Action Bar ───────────────────────── */

// class _BottomBar extends ConsumerWidget {
//   final OrderModel order;
//   const _BottomBar({required this.order});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final colors = AppColors.of(context);
//     final actionLabel = order.status.advanceActionLabel;

//     return SafeArea(
//       top: false,
//       child: Container(
//         padding: EdgeInsets.fromLTRB(
//             context.w(20), context.h(12), context.w(20), context.h(14)),
//         decoration: BoxDecoration(
//           color: colors.surface,
//           border: Border(top: BorderSide(color: colors.border)),
//         ),
//         child: Row(
//           children: [
//             Expanded(
//               child: RdxActionButton(
//                 label: 'Print Bill & Receipt',
//                 leadingIcon: Icons.print_outlined,
//                 onPressed: () {
//                   // TODO: integrate real printer / share PDF
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(content: Text('Sending to printer…')),
//                   );
//                 },
//               ),
//             ),
//             SizedBox(width: context.w(10)),
//             if (actionLabel != null)
//               Expanded(
//                 child: RdxActionButton(
//                   label: actionLabel,
//                   isPrimary: true,
//                   onPressed: () async {
//                     final next = order.status.nextStatus;
//                     if (next == null) return;
//                     await OrderService().updateOrderStatus(order.id, next);
//                     // Refresh the detail screen
//                     ref.invalidate(orderDetailProvider(order.id));
//                     if (context.mounted) {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         SnackBar(content: Text('Status → ${next.label}')),
//                       );
//                     }
//                   },
//                 ),
//               ),
//             if (order.status == OrderStatus.ready ||
//                 order.status == OrderStatus.delivered) ...[
//               SizedBox(width: context.w(10)),
//               Expanded(
//                 child: RdxActionButton(
//                   label: 'Mark Paid & Complete',
//                   isPrimary: true,
//                   onPressed: () async {
//                     await OrderService()
//                         .updateOrderStatus(order.id, OrderStatus.delivered);
//                     ref.invalidate(orderDetailProvider(order.id));
//                     if (context.mounted) {
//                       Navigator.of(context).pop(true);
//                     }
//                   },
//                 ),
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/utils/responsive_size.dart';
import '../../models/order_model.dart';
import '../../providers/order_providers.dart';
import '../../services/order_service.dart';
import '../../widgets/buttons/rdx_action_button.dart';
import '../../widgets/reusable_widgets/empty_state.dart';
import '../../widgets/reusable_widgets/loading_indicator.dart';
import '../../widgets/reusable_widgets/rdx_header.dart';

final orderDetailProvider =
    FutureProvider.family<OrderModel?, String>((ref, orderId) async {
  if (orderId.trim().isEmpty) return null;

  return OrderService().fetchOrderById(orderId);
});

class OrderDetailsScreen extends ConsumerWidget {
  final String orderId;

  const OrderDetailsScreen({
    super.key,
    required this.orderId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncOrder = ref.watch(orderDetailProvider(orderId));

    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      body: Column(
        children: [
          RdxHeader(
            title: asyncOrder.when(
              data: (order) {
                if (order == null) return 'Order Detail';

                return 'Order #${_shortId(order.id)}';
              },
              loading: () => 'Order Detail',
              error: (_, __) => 'Order Detail',
            ),
            showBackButton: true,
          ),
          Expanded(
            child: asyncOrder.when(
              loading: () => const LoadingIndicator(),
              error: (error, _) => EmptyState(
                message: 'Failed to load order.\n$error',
              ),
              data: (order) {
                if (order == null) {
                  return const EmptyState(
                    message: 'Order not found.',
                  );
                }

                return _OrderDetailBody(order: order);
              },
            ),
          ),
        ],
      ),
    );
  }

  String _shortId(String id) {
    if (id.length <= 4) return id;
    return id.substring(id.length - 4);
  }
}

// =============================================================================
// ORDER DETAIL BODY
// =============================================================================

class _OrderDetailBody extends ConsumerWidget {
  final OrderModel order;

  const _OrderDetailBody({
    required this.order,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;

    final narrow = width < 900;

    double subtotal = 0;

    for (final item in order.items) {
      subtotal += item.price * item.quantity;
    }

    final tax = (order.total - subtotal).clamp(
      0,
      double.infinity,
    );

    final taxPercent = subtotal > 0 ? (tax / subtotal) * 100 : 0.0;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              context.w(20),
              context.h(12),
              context.w(20),
              context.h(20),
            ),
            child: narrow
                ? Column(
                    children: [
                      _ServiceAndCustomer(
                        order: order,
                      ),
                      SizedBox(height: context.h(14)),
                      _OrderItemsSection(
                        order: order,
                      ),
                      SizedBox(height: context.h(14)),
                      _KitchenNotes(
                        order: order,
                      ),
                      SizedBox(height: context.h(14)),
                      _PaymentSection(
                        order: order,
                      ),
                      SizedBox(height: context.h(14)),
                      _BillingSummary(
                        subtotal: subtotal,
                        tax: tax.toDouble(),
                        taxPercent: taxPercent,
                        total: order.total,
                      ),
                      SizedBox(height: context.h(14)),
                      _WorkflowSection(
                        order: order,
                      ),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: Column(
                          children: [
                            _ServiceAndCustomer(
                              order: order,
                            ),
                            SizedBox(height: context.h(14)),
                            _OrderItemsSection(
                              order: order,
                            ),
                            SizedBox(height: context.h(14)),
                            _KitchenNotes(
                              order: order,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: context.w(16)),
                      Expanded(
                        flex: 4,
                        child: Column(
                          children: [
                            _PaymentSection(
                              order: order,
                            ),
                            SizedBox(height: context.h(14)),
                            _BillingSummary(
                              subtotal: subtotal,
                              tax: tax.toDouble(),
                              taxPercent: taxPercent,
                              total: order.total,
                            ),
                            SizedBox(height: context.h(14)),
                            _WorkflowSection(
                              order: order,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        _BottomActionBar(
          order: order,
        ),
      ],
    );
  }
}

// =============================================================================
// SERVICE + CUSTOMER
// =============================================================================

class _ServiceAndCustomer extends StatelessWidget {
  final OrderModel order;

  const _ServiceAndCustomer({
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return _Panel(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            context: context,
            title: 'SERVICE & CUSTOMER',
            icon: Icons.receipt_long_outlined,
          ),
          SizedBox(height: context.h(14)),
          Text(
            'SERVICE OPTION',
            style: AppTextStyles.caption(context).copyWith(
              color: colors.textMuted,
              letterSpacing: 0.6,
            ),
          ),
          SizedBox(height: context.h(7)),
          Row(
            children: [
              Expanded(
                child: _OptionTile(
                  context: context,
                  label: 'Eat In',
                  selected: order.orderType == OrderType.dineIn,
                ),
              ),
              SizedBox(width: context.w(8)),
              Expanded(
                child: _OptionTile(
                  context: context,
                  label: 'To Go',
                  selected: false,
                ),
              ),
              SizedBox(width: context.w(8)),
              Expanded(
                child: _OptionTile(
                  context: context,
                  label: 'Delivery',
                  selected: order.orderType == OrderType.delivery,
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(14)),
          Row(
            children: [
              Expanded(
                child: _InfoBlock(
                  context: context,
                  label: 'TABLE',
                  value: order.orderType == OrderType.dineIn
                      ? ((order.tableNumber?.trim().isNotEmpty ?? false)
                          ? 'Table ${order.tableNumber}'
                          : 'No Table / Counter')
                      : '—',
                ),
              ),
              SizedBox(width: context.w(10)),
              Expanded(
                child: _InfoBlock(
                  context: context,
                  label: 'ORDER TYPE',
                  value: _orderTypeLabel(order.orderType),
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(14)),
          Divider(
            height: 1,
            color: colors.divider,
          ),
          SizedBox(height: context.h(14)),
          Row(
            children: [
              Container(
                width: context.h(30),
                height: context.h(30),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(
                    alpha: 0.10,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_outline,
                  size: context.h(16),
                  color: AppColors.primary,
                ),
              ),
              SizedBox(width: context.w(10)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.customerName.trim().isEmpty
                          ? 'Walk-in Customer'
                          : order.customerName,
                      style: AppTextStyles.body(context).copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (order.customerPhone.trim().isNotEmpty)
                      SizedBox(height: context.h(2)),
                    if (order.customerPhone.trim().isNotEmpty)
                      Text(
                        order.customerPhone,
                        style: AppTextStyles.caption(context).copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (order.orderType == OrderType.delivery &&
              order.deliveryAddress.trim().isNotEmpty) ...[
            SizedBox(height: context.h(12)),
            _InfoBlock(
              context: context,
              label: 'DELIVERY ADDRESS',
              value: order.deliveryAddress,
            ),
          ],
        ],
      ),
    );
  }

  String _orderTypeLabel(OrderType type) {
    switch (type) {
      case OrderType.dineIn:
        return 'Eat In';
      case OrderType.delivery:
        return 'Delivery';
      case OrderType.takeaway:
        return 'To Go';
    }
  }
}

// =============================================================================
// ORDER ITEMS
// =============================================================================

class _OrderItemsSection extends StatelessWidget {
  final OrderModel order;

  const _OrderItemsSection({
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return _Panel(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SectionTitle(
                context: context,
                title: 'ORDER ITEMS',
                icon: Icons.restaurant_menu_outlined,
              ),
              const Spacer(),
              Text(
                '${order.items.length} Lines',
                style: AppTextStyles.caption(context).copyWith(
                  color: colors.textMuted,
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(12)),
          for (int index = 0; index < order.items.length; index++) ...[
            _OrderItemRow(
              item: order.items[index],
            ),
            if (index != order.items.length - 1)
              Padding(
                padding: EdgeInsets.symmetric(
                  vertical: context.h(10),
                ),
                child: Divider(
                  height: 1,
                  color: colors.divider,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _OrderItemRow extends StatelessWidget {
  final OrderItemModel item;

  const _OrderItemRow({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    final amount = item.price * item.quantity;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: context.h(25),
          height: context.h(25),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.surfaceVariant,
            borderRadius: BorderRadius.circular(
              context.h(5),
            ),
            border: Border.all(
              color: colors.border,
            ),
          ),
          child: Text(
            '${item.quantity}',
            style: AppTextStyles.caption(context).copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        SizedBox(width: context.w(10)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body(context).copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: context.h(2)),
              if (item.spiceLevel != null || item.addOns.isNotEmpty)
                Text(
                  [
                    if (item.spiceLevel != null &&
                        item.spiceLevel!.trim().isNotEmpty)
                      item.spiceLevel!,
                    ...item.addOns,
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption(context).copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              if (item.notes != null && item.notes!.trim().isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(
                    top: context.h(2),
                  ),
                  child: Text(
                    'Note: ${item.notes}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption(context).copyWith(
                      color: colors.textMuted,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(width: context.w(10)),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '₹${amount.toStringAsFixed(2)}',
              style: AppTextStyles.body(context).copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: context.h(2)),
            Text(
              '₹${item.price.toStringAsFixed(2)} each',
              style: AppTextStyles.caption(context).copyWith(
                color: colors.textMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// =============================================================================
// KITCHEN NOTES
// =============================================================================

class _KitchenNotes extends StatelessWidget {
  final OrderModel order;

  const _KitchenNotes({
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    if (order.notes == null || order.notes!.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return _Panel(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.notes_outlined,
                size: context.h(14),
                color: colors.textMuted,
              ),
              SizedBox(width: context.w(5)),
              Text(
                'KITCHEN NOTES',
                style: AppTextStyles.caption(context).copyWith(
                  color: colors.textMuted,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(8)),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(
              context.h(10),
            ),
            decoration: BoxDecoration(
              color: colors.surfaceVariant,
              borderRadius: BorderRadius.circular(
                context.h(7),
              ),
            ),
            child: Text(
              order.notes!,
              style: AppTextStyles.bodySecondary(context).copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// PAYMENT
// =============================================================================

class _PaymentSection extends ConsumerWidget {
  final OrderModel order;

  const _PaymentSection({
    required this.order,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);

    final isPaid = order.paymentMethod != null;

    return _Panel(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SectionTitle(
                context: context,
                title: 'PAYMENT',
                icon: Icons.payments_outlined,
              ),
              const Spacer(),
              _PaymentStatusBadge(
                context: context,
                paid: isPaid,
              ),
            ],
          ),
          SizedBox(height: context.h(14)),
          if (isPaid)
            _PaidPayment(
              order: order,
            )
          else
            _UnpaidPayment(
              order: order,
            ),
        ],
      ),
    );
  }
}

class _PaidPayment extends StatelessWidget {
  final OrderModel order;

  const _PaidPayment({
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        context.h(11),
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(
          alpha: 0.07,
        ),
        borderRadius: BorderRadius.circular(
          context.h(8),
        ),
        border: Border.all(
          color: AppColors.primary.withValues(
            alpha: 0.20,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: context.h(32),
            height: context.h(32),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(
                alpha: 0.12,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check,
              size: context.h(17),
              color: AppColors.primary,
            ),
          ),
          SizedBox(width: context.w(10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payment Completed',
                  style: AppTextStyles.body(context).copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: context.h(2)),
                Text(
                  order.paymentMethod!.label,
                  style: AppTextStyles.caption(context).copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '₹${order.total.toStringAsFixed(2)}',
            style: AppTextStyles.body(context).copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _UnpaidPayment extends ConsumerWidget {
  final OrderModel order;

  const _UnpaidPayment({
    required this.order,
  });

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final colors = AppColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(
            context.h(11),
          ),
          decoration: BoxDecoration(
            color: colors.surfaceVariant,
            borderRadius: BorderRadius.circular(
              context.h(8),
            ),
            border: Border.all(
              color: colors.border,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.pending_outlined,
                size: context.h(17),
                color: colors.textMuted,
              ),
              SizedBox(width: context.w(8)),
              Expanded(
                child: Text(
                  'Payment is pending',
                  style: AppTextStyles.bodySecondary(context).copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
              Text(
                '₹${order.total.toStringAsFixed(2)}',
                style: AppTextStyles.body(context).copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: context.h(10)),
        SizedBox(
          width: double.infinity,
          child: RdxActionButton(
            label: 'Make Payment',
            leadingIcon: Icons.payments_outlined,
            isPrimary: true,
            onPressed: () {
              _showPaymentDialog(
                context,
                ref,
                order,
              );
            },
          ),
        ),
      ],
    );
  }

  // Future<void> _showPaymentDialog(
  //   BuildContext context,
  //   OrderModel order,
  // ) async {
  //   final method = await showDialog<PaymentMethod>(
  //     context: context,
  //     builder: (dialogContext) {
  //       final colors = AppColors.of(dialogContext);

  //       return AlertDialog(
  //         backgroundColor: colors.surface,
  //         title: Text(
  //           'Make Payment',
  //           style: AppTextStyles.section(dialogContext).copyWith(
  //             color: colors.textPrimary,
  //           ),
  //         ),
  //         content: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             Text(
  //               'Select payment method for ₹${order.total.toStringAsFixed(2)}',
  //               style: AppTextStyles.bodySecondary(dialogContext).copyWith(
  //                 color: colors.textSecondary,
  //               ),
  //             ),
  //             SizedBox(height: context.h(14)),
  //             for (final method in PaymentMethod.values)
  //               Padding(
  //                 padding: EdgeInsets.only(
  //                   bottom: context.h(8),
  //                 ),
  //                 child: SizedBox(
  //                   width: double.infinity,
  //                   child: RdxActionButton(
  //                     label: method.label,
  //                     leadingIcon: _paymentIcon(method),
  //                     onPressed: () {
  //                       Navigator.of(dialogContext).pop(method);
  //                     },
  //                   ),
  //                 ),
  //               ),
  //           ],
  //         ),
  //       );
  //     },
  //   );

  //   if (method == null) return;

  //   try {
  //     await OrderService().updatePaymentStatus(
  //       order.id,
  //       method,
  //     );

  //     if (!context.mounted) return;

  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text(
  //           'Payment completed via ${method.label}.',
  //         ),
  //       ),
  //     );
  //   } catch (e) {
  //     if (!context.mounted) return;

  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text(
  //           'Payment failed. $e',
  //         ),
  //       ),
  //     );
  //   }
  // }

  Future<void> _showPaymentDialog(
    BuildContext context,
    WidgetRef ref,
    OrderModel order,
  ) async {
    // Prevent making the same payment again.
    if (order.paymentStatus == PaymentStatus.paid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This order has already been paid.'),
        ),
      );
      return;
    }

    final method = await showDialog<PaymentMethod>(
      context: context,
      builder: (dialogContext) {
        final colors = AppColors.of(dialogContext);

        return AlertDialog(
          backgroundColor: colors.surface,
          title: Text(
            'Make Payment',
            style: AppTextStyles.section(dialogContext).copyWith(
              color: colors.textPrimary,
            ),
          ),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(dialogContext).height * 0.6,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Select payment method for '
                    '₹${order.total.toStringAsFixed(2)}',
                    style: AppTextStyles.bodySecondary(
                      dialogContext,
                    ).copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  SizedBox(
                    height: dialogContext.h(14),
                  ),
                  for (final method in PaymentMethod.values)
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: dialogContext.h(8),
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: RdxActionButton(
                          label: method.label,
                          leadingIcon: _paymentIcon(method),
                          onPressed: () {
                            Navigator.of(dialogContext).pop(method);
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (method == null) {
      return;
    }

    try {
      await OrderService().updatePaymentStatus(
        orderId: order.id,
        paymentMethod: method,
      );

      if (!context.mounted) {
        return;
      }

      // Refresh the order details from Firestore.
      ref.invalidate(
        orderDetailProvider(order.id),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Payment completed via ${method.label}.',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Payment failed. ${e.toString()}',
          ),
        ),
      );
    }
  }

  IconData _paymentIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return Icons.payments_outlined;
      case PaymentMethod.card:
        return Icons.credit_card_outlined;
      case PaymentMethod.upi:
        return Icons.qr_code_2_outlined;
      case PaymentMethod.online:
        return Icons.language_outlined;
      case PaymentMethod.split:
        return Icons.call_split_outlined;
    }
  }
}

class _PaymentStatusBadge extends StatelessWidget {
  final BuildContext context;
  final bool paid;

  const _PaymentStatusBadge({
    required this.context,
    required this.paid,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(8),
        vertical: context.h(4),
      ),
      decoration: BoxDecoration(
        color: paid
            ? AppColors.primary.withValues(alpha: 0.10)
            : colors.surfaceVariant,
        borderRadius: BorderRadius.circular(
          context.h(6),
        ),
      ),
      child: Text(
        paid ? 'PAID' : 'UNPAID',
        style: AppTextStyles.caption(context).copyWith(
          fontSize: context.h(8),
          color: paid ? AppColors.primary : colors.textMuted,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// =============================================================================
// BILL SUMMARY
// =============================================================================

class _BillingSummary extends StatelessWidget {
  final double subtotal;
  final double tax;
  final double taxPercent;
  final double total;

  const _BillingSummary({
    required this.subtotal,
    required this.tax,
    required this.taxPercent,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return _Panel(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            context: context,
            title: 'BILL SUMMARY',
            icon: Icons.receipt_outlined,
          ),
          SizedBox(height: context.h(12)),
          _BillRow(
            context: context,
            label: 'Subtotal',
            value: '₹${subtotal.toStringAsFixed(2)}',
          ),
          SizedBox(height: context.h(7)),
          _BillRow(
            context: context,
            label: 'Tax & Surcharge (${taxPercent.toStringAsFixed(2)}%)',
            value: '₹${tax.toStringAsFixed(2)}',
          ),
          SizedBox(height: context.h(11)),
          Divider(
            height: 1,
            color: colors.divider,
          ),
          SizedBox(height: context.h(11)),
          Row(
            children: [
              Text(
                'Total Due',
                style: AppTextStyles.section(context).copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '₹${total.toStringAsFixed(2)}',
                style: AppTextStyles.heading(context).copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BillRow extends StatelessWidget {
  final BuildContext context;
  final String label;
  final String value;

  const _BillRow({
    required this.context,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodySecondary(context).copyWith(
              color: colors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: AppTextStyles.body(context).copyWith(
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// WORKFLOW
// =============================================================================

class _WorkflowSection extends ConsumerWidget {
  final OrderModel order;

  const _WorkflowSection({
    required this.order,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);

    final nextStatus = order.status.nextStatus;

    return _Panel(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            context: context,
            title: 'WORKFLOW',
            icon: Icons.sync_alt_outlined,
          ),
          SizedBox(height: context.h(12)),
          Row(
            children: [
              Expanded(
                child: _WorkflowButton(
                  context: context,
                  label: order.status == OrderStatus.pending
                      ? 'Move to Preparing'
                      : order.status == OrderStatus.preparing
                          ? 'Mark Ready'
                          : 'Current Stage',
                  icon: Icons.arrow_forward_outlined,
                  enabled: nextStatus != null,
                  onPressed: nextStatus == null
                      ? null
                      : () async {
                          try {
                            await OrderService().updateOrderStatus(
                              order.id,
                              nextStatus,
                            );

                            ref.invalidate(
                              orderDetailProvider(order.id),
                            );
                          } catch (e) {
                            if (!context.mounted) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Failed to update status. $e',
                                ),
                              ),
                            );
                          }
                        },
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(8)),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: context.w(10),
              vertical: context.h(8),
            ),
            decoration: BoxDecoration(
              color: colors.surfaceVariant,
              borderRadius: BorderRadius.circular(
                context.h(7),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'CURRENT STAGE',
                  style: AppTextStyles.caption(context).copyWith(
                    fontSize: context.h(8),
                    color: colors.textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                Text(
                  order.status.label,
                  style: AppTextStyles.caption(context).copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkflowButton extends StatelessWidget {
  final BuildContext context;
  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback? onPressed;

  const _WorkflowButton({
    required this.context,
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return RdxActionButton(
      label: label,
      leadingIcon: icon,
      isPrimary: enabled,
      onPressed: onPressed,
    );
  }
}

// =============================================================================
// BOTTOM ACTION BAR
// =============================================================================

class _BottomActionBar extends StatelessWidget {
  final OrderModel order;

  const _BottomActionBar({
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          context.w(20),
          context.h(10),
          context.w(20),
          context.h(14),
        ),
        decoration: BoxDecoration(
          color: AppColors.of(context).surface,
          border: Border(
            top: BorderSide(
              color: AppColors.of(context).border,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: RdxActionButton(
                label: 'Print Bill & Receipt',
                leadingIcon: Icons.print_outlined,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Sending bill to printer…',
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(width: context.w(10)),
            Expanded(
              child: RdxActionButton(
                label: 'Close',
                leadingIcon: Icons.close,
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// COMMON UI
// =============================================================================

class _Panel extends StatelessWidget {
  final BuildContext context;
  final Widget child;

  const _Panel({
    required this.context,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        context.h(14),
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(
          context.h(10),
        ),
        border: Border.all(
          color: colors.border,
        ),
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final BuildContext context;
  final String title;
  final IconData icon;

  const _SectionTitle({
    required this.context,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Row(
      children: [
        Icon(
          icon,
          size: context.h(14),
          color: colors.textMuted,
        ),
        SizedBox(width: context.w(5)),
        Text(
          title,
          style: AppTextStyles.caption(context).copyWith(
            color: colors.textMuted,
            letterSpacing: 0.6,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  final BuildContext context;
  final String label;
  final bool selected;

  const _OptionTile({
    required this.context,
    required this.label,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Container(
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(
        vertical: context.h(8),
        horizontal: context.w(8),
      ),
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : colors.surfaceVariant,
        borderRadius: BorderRadius.circular(
          context.h(7),
        ),
        border: Border.all(
          color: selected ? AppColors.primary : colors.border,
        ),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption(context).copyWith(
          color: selected ? Colors.white : colors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  final BuildContext context;
  final String label;
  final String value;

  const _InfoBlock({
    required this.context,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption(context).copyWith(
            fontSize: context.h(8),
            color: colors.textMuted,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: context.h(3)),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bodySecondary(context).copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
