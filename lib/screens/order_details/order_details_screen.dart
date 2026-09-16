// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:rdx_admin/core/theme/text_styles.dart';
// import '../../core/utils/responsive_size.dart';
// import '../../core/theme/app_colors.dart';
// import '../../models/order_model.dart';
// import '../../providers/order_detail_provider.dart';
// import '../../services/order_service.dart';
// import '../../widgets/reusable_widgets/loading_indicator.dart';
// import '../../widgets/reusable_widgets/rdx_header.dart';

// class OrderDetailsScreen extends StatelessWidget {
//   final String orderId;

//   const OrderDetailsScreen({
//     super.key,
//     required this.orderId,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return ChangeNotifierProvider(
//       create: (_) => OrderDetailProvider(
//         OrderService(),
//         orderId,
//       )..load(),
//       child: const _OrderDetailBody(),
//     );
//   }
// }

// class _OrderDetailBody extends StatelessWidget {
//   const _OrderDetailBody();

//   @override
//   Widget build(BuildContext context) {
//     final provider = context.watch<OrderDetailProvider>();

//     final order = provider.order;

//     return Scaffold(
//       backgroundColor: AppColors.lightBackground,
//       body: Column(
//         children: [
//           RdxHeader(
//             title: order == null ? 'Order Detail' : 'Order #RDX-${order.id}',
//             showBackButton: true,
//           ),
//           Expanded(
//             child: provider.isLoading || order == null
//                 ? const LoadingIndicator()
//                 : _OrderDetailContent(
//                     order: order,
//                     provider: provider,
//                   ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _OrderDetailContent extends StatelessWidget {
//   final OrderModel order;
//   final OrderDetailProvider provider;

//   const _OrderDetailContent({
//     required this.order,
//     required this.provider,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return LayoutBuilder(
//       builder: (context, constraints) {
//         final compact = constraints.maxWidth < 900;

//         if (compact) {
//           return SingleChildScrollView(
//             padding: Responsive.pagePadding(context, top: 14, bottom: 80),
//             child: Column(
//               children: [
//                 _OrderHeader(order: order),
//                 const SizedBox(height: 12),
//                 _CustomerCard(order: order),
//                 const SizedBox(height: 12),
//                 _OrderItemsCard(order: order),
//                 const SizedBox(height: 12),
//                 _DeliveryCard(order: order),
//                 const SizedBox(height: 12),
//                 _TimelineCard(order: order),
//                 const SizedBox(height: 12),
//                 _StatusCard(
//                   order: order,
//                   provider: provider,
//                 ),
//                 const SizedBox(height: 80),
//               ],
//             ),
//           );
//         }

//         return Column(
//           children: [
//             Expanded(
//               child: SingleChildScrollView(
//                 padding: Responsive.pagePadding(
//                   context,
//                   top: 14,
//                   bottom: 12,
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     _OrderHeader(order: order),
//                     const SizedBox(height: 12),
//                     Row(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Expanded(
//                           flex: 4,
//                           child: Column(
//                             children: [
//                               _CustomerCard(order: order),
//                               const SizedBox(height: 12),
//                               _OrderItemsCard(order: order),
//                             ],
//                           ),
//                         ),
//                         const SizedBox(width: 12),
//                         Expanded(
//                           flex: 6,
//                           child: Column(
//                             children: [
//                               _DeliveryCard(order: order),
//                               const SizedBox(height: 12),
//                               _TimelineCard(order: order),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             _BottomActionBar(
//               order: order,
//               provider: provider,
//             ),
//           ],
//         );
//       },
//     );
//   }
// }

// /* -------------------------------------------------------------------------- */
// /* HEADER                                                                     */
// /* -------------------------------------------------------------------------- */

// class _OrderHeader extends StatelessWidget {
//   final OrderModel order;

//   const _OrderHeader({
//     required this.order,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final narrow = MediaQuery.sizeOf(context).width < 600;
//     final titleBlock = Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Wrap(
//           crossAxisAlignment: WrapCrossAlignment.center,
//           spacing: 7,
//           runSpacing: 4,
//           children: [
//             Text('Order #RDX-${order.id}',
//                 style: AppTextStyles.label(context)
//                     .copyWith(color: const Color(0xFFE8E8E8))),
//             _SmallStatusBadge(status: order.status),
//           ],
//         ),
//         const SizedBox(height: 4),
//         Text('Placed at ${_formatTime(order.createdAt)} • Delivery order',
//             style: AppTextStyles.caption(context)
//                 .copyWith(color: const Color(0xFF666666))),
//       ],
//     );
//     final actions = Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         _HeaderButton(
//           icon: Icons.print_outlined,
//           label: 'Print',
//           onTap: () {},
//         ),
//         const SizedBox(width: 7),
//         _HeaderButton(
//           icon: Icons.support_agent_outlined,
//           label: 'Support',
//           onTap: () {},
//         ),
//       ],
//     );
//     if (narrow) {
//       return Column(
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           titleBlock,
//           const SizedBox(height: 10),
//           Align(alignment: Alignment.centerLeft, child: actions),
//         ],
//       );
//     }
//     return Row(
//       children: [
//         Expanded(child: titleBlock),
//         actions,
//       ],
//     );
//   }

//   String _formatTime(DateTime value) {
//     final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
//     final minute = value.minute.toString().padLeft(2, '0');
//     final period = value.hour >= 12 ? 'PM' : 'AM';

//     return '$hour:$minute $period';
//   }
// }

// class _HeaderButton extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   final VoidCallback onTap;

//   const _HeaderButton({
//     required this.icon,
//     required this.label,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(4),
//       child: Container(
//         height: 26,
//         padding: const EdgeInsets.symmetric(horizontal: 9),
//         decoration: BoxDecoration(
//           color: const Color(0xFF0F0F0F),
//           borderRadius: BorderRadius.circular(4),
//           border: Border.all(
//             color: const Color(0xFF343434),
//           ),
//         ),
//         child: Row(
//           children: [
//             Icon(
//               icon,
//               size: 11,
//               color: const Color(0xFFB8B8B8),
//             ),
//             const SizedBox(width: 5),
//             Text(label,
//                 style: AppTextStyles.caption(context)
//                     .copyWith(color: const Color(0xFFB8B8B8))),
//           ],
//         ),
//       ),
//     );
//   }
// }

// /* -------------------------------------------------------------------------- */
// /* CUSTOMER                                                                  */
// /* -------------------------------------------------------------------------- */

// class _CustomerCard extends StatelessWidget {
//   final OrderModel order;

//   const _CustomerCard({
//     required this.order,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return _DarkCard(
//       title: 'CUSTOMER DETAILS',
//       child: Column(
//         children: [
//           Row(
//             children: [
//               Container(
//                 width: 31,
//                 height: 31,
//                 decoration: BoxDecoration(
//                   color: const Color(0xFF222222),
//                   shape: BoxShape.circle,
//                   border: Border.all(
//                     color: const Color(0xFF383838),
//                   ),
//                 ),
//                 child: const Icon(
//                   Icons.person_outline,
//                   color: Color(0xFF8E8E8E),
//                   size: 16,
//                 ),
//               ),
//               const SizedBox(width: 9),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(order.customerName,
//                         style: AppTextStyles.label(context)
//                             .copyWith(color: const Color(0xFFE2E2E2))),
//                     const SizedBox(height: 3),
//                     Text(order.customerPhone,
//                         style: AppTextStyles.caption(context)
//                             .copyWith(color: const Color(0xFF777777))),
//                   ],
//                 ),
//               ),
//               _CircleAction(
//                 icon: Icons.phone_outlined,
//                 onTap: () {},
//               ),
//             ],
//           ),
//           const SizedBox(height: 12),
//           _AddressRow(
//             address: order.deliveryAddress,
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _AddressRow extends StatelessWidget {
//   final String address;

//   const _AddressRow({
//     required this.address,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Icon(
//           Icons.location_on_outlined,
//           size: 13,
//           color: Color(0xFF777777),
//         ),
//         const SizedBox(width: 7),
//         Expanded(
//           child: Text(address,
//               style: AppTextStyles.caption(context)
//                   .copyWith(color: const Color(0xFF929292))),
//         ),
//       ],
//     );
//   }
// }

// class _CircleAction extends StatelessWidget {
//   final IconData icon;
//   final VoidCallback onTap;

//   const _CircleAction({
//     required this.icon,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(20),
//       child: Container(
//         width: 27,
//         height: 27,
//         decoration: BoxDecoration(
//           color: const Color(0xFF191919),
//           shape: BoxShape.circle,
//           border: Border.all(
//             color: const Color(0xFF343434),
//           ),
//         ),
//         child: Icon(
//           icon,
//           size: 12,
//           color: const Color(0xFFAAAAAA),
//         ),
//       ),
//     );
//   }
// }

// /* -------------------------------------------------------------------------- */
// /* ORDER ITEMS                                                                */
// /* -------------------------------------------------------------------------- */

// class _OrderItemsCard extends StatelessWidget {
//   final OrderModel order;

//   const _OrderItemsCard({
//     required this.order,
//   });

//   @override
//   Widget build(BuildContext context) {
//     double subtotal = 0;

//     for (final item in order.items) {
//       subtotal += item.price * item.quantity;
//     }

//     final tax =
//         order.total > subtotal ? order.total - subtotal : subtotal * .05;

//     return _DarkCard(
//       title: 'ORDER ITEMS',
//       trailing: '${order.items.length} ITEMS',
//       child: Column(
//         children: [
//           ...order.items.map(
//             (item) => Padding(
//               padding: const EdgeInsets.only(bottom: 11),
//               child: Row(
//                 children: [
//                   Container(
//                     width: 25,
//                     height: 25,
//                     alignment: Alignment.center,
//                     decoration: BoxDecoration(
//                       color: const Color(0xFF202020),
//                       borderRadius: BorderRadius.circular(4),
//                     ),
//                     child: Text('${item.quantity}x',
//                         style: AppTextStyles.caption(context)
//                             .copyWith(color: const Color(0xFFBBBBBB))),
//                   ),
//                   const SizedBox(width: 8),
//                   Expanded(
//                     child: Text(
//                       item.name,
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                       style: AppTextStyles.caption(context)
//                           .copyWith(color: const Color(0xFFD2D2D2)),
//                     ),
//                   ),
//                   Text('₹${(item.price * item.quantity).toStringAsFixed(2)}',
//                       style: AppTextStyles.caption(context)
//                           .copyWith(color: const Color(0xFFBDBDBD))),
//                 ],
//               ),
//             ),
//           ),
//           const Divider(
//             height: 1,
//             color: Color(0xFF292929),
//           ),
//           const SizedBox(height: 10),
//           _PriceRow(
//             label: 'Subtotal',
//             value: '₹${subtotal.toStringAsFixed(2)}',
//           ),
//           const SizedBox(height: 7),
//           _PriceRow(
//             label: 'Tax & Fees',
//             value: '₹${tax.toStringAsFixed(2)}',
//           ),
//           const SizedBox(height: 8),
//           _PriceRow(
//             label: 'Total',
//             value: '₹${order.total.toStringAsFixed(2)}',
//             strong: true,
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _PriceRow extends StatelessWidget {
//   final String label;
//   final String value;
//   final bool strong;

//   const _PriceRow({
//     required this.label,
//     required this.value,
//     this.strong = false,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         Expanded(
//           child: Text(label,
//               style: AppTextStyles.caption(context).copyWith(
//                 color:
//                     strong ? const Color(0xFFD7D7D7) : const Color(0xFF777777),
//               )),
//         ),
//         Text(
//           value,
//           style: AppTextStyles.caption(context).copyWith(
//             color: strong ? const Color(0xFFE5E5E5) : const Color(0xFF999999),
//           ),
//         ),
//       ],
//     );
//   }
// }

// /* -------------------------------------------------------------------------- */
// /* DELIVERY                                                                  */
// /* -------------------------------------------------------------------------- */

// class _DeliveryCard extends StatelessWidget {
//   final OrderModel order;

//   const _DeliveryCard({
//     required this.order,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: 250,
//       decoration: BoxDecoration(
//         color: const Color(0xFF111111),
//         borderRadius: BorderRadius.circular(7),
//         border: Border.all(
//           color: const Color(0xFF2A2A2A),
//         ),
//       ),
//       clipBehavior: Clip.antiAlias,
//       child: Stack(
//         children: [
//           Positioned.fill(
//             child: CustomPaint(
//               painter: _MapGridPainter(),
//             ),
//           ),
//           Positioned(
//             top: 9,
//             left: 10,
//             child: Container(
//               padding: const EdgeInsets.symmetric(
//                 horizontal: 7,
//                 vertical: 4,
//               ),
//               decoration: BoxDecoration(
//                 color: const Color(0xCC101010),
//                 borderRadius: BorderRadius.circular(3),
//                 border: Border.all(
//                   color: const Color(0xFF292929),
//                 ),
//               ),
//               child: Text('DELIVERY LOCATION',
//                   style: AppTextStyles.caption(context)
//                       .copyWith(color: const Color(0xFF777777))),
//             ),
//           ),
//           Positioned(
//             top: 82,
//             left: 0,
//             right: 0,
//             child: Column(
//               children: [
//                 const Icon(
//                   Icons.location_on,
//                   color: Color(0xFFB91936),
//                   size: 30,
//                 ),
//                 const SizedBox(height: 3),
//                 Container(
//                   width: 5,
//                   height: 5,
//                   decoration: const BoxDecoration(
//                     color: Color(0xFFB91936),
//                     shape: BoxShape.circle,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           Positioned(
//             left: 14,
//             right: 14,
//             bottom: 12,
//             child: Container(
//               padding: const EdgeInsets.all(10),
//               decoration: BoxDecoration(
//                 color: const Color(0xEE101010),
//                 borderRadius: BorderRadius.circular(6),
//                 border: Border.all(
//                   color: const Color(0xFF333333),
//                 ),
//               ),
//               child: Row(
//                 children: [
//                   Container(
//                     width: 28,
//                     height: 28,
//                     decoration: const BoxDecoration(
//                       color: Color(0xFF146BC2),
//                       shape: BoxShape.circle,
//                     ),
//                     child: const Icon(
//                       Icons.delivery_dining_outlined,
//                       color: Colors.white,
//                       size: 15,
//                     ),
//                   ),
//                   const SizedBox(width: 9),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text('RIDER ASSIGNED',
//                             style: AppTextStyles.caption(context)
//                                 .copyWith(color: const Color(0xFF6B6B6B))),
//                         SizedBox(height: 3),
//                         Text('Marcus T.  (3.2 mi away)',
//                             style: AppTextStyles.caption(context)
//                                 .copyWith(color: const Color(0xFFD7D7D7))),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _MapGridPainter extends CustomPainter {
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()
//       ..color = const Color(0xFF20282A)
//       ..strokeWidth = .6
//       ..style = PaintingStyle.stroke;

//     final secondaryPaint = Paint()
//       ..color = const Color(0xFF171D1E)
//       ..strokeWidth = .5;

//     for (double x = -size.height; x < size.width + size.height; x += 28) {
//       canvas.drawLine(
//         Offset(x, 0),
//         Offset(x + size.height, size.height),
//         paint,
//       );
//     }

//     for (double x = 0; x < size.width; x += 48) {
//       canvas.drawLine(
//         Offset(x, 0),
//         Offset(x, size.height),
//         secondaryPaint,
//       );
//     }

//     for (double y = 0; y < size.height; y += 34) {
//       canvas.drawLine(
//         Offset(0, y),
//         Offset(size.width, y),
//         secondaryPaint,
//       );
//     }
//   }

//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) {
//     return false;
//   }
// }

// /* -------------------------------------------------------------------------- */
// /* TIMELINE                                                                  */
// /* -------------------------------------------------------------------------- */

// class _TimelineCard extends StatelessWidget {
//   final OrderModel order;

//   const _TimelineCard({
//     required this.order,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return _DarkCard(
//       title: 'LOGISTICS TIMELINE',
//       child: Column(
//         children: [
//           _TimelineStep(
//             title: 'Order Confirmed',
//             subtitle: _formatTime(order.createdAt),
//             completed: true,
//             active: order.status != OrderStatus.pending,
//           ),
//           _TimelineStep(
//             title: 'Preparing Food',
//             subtitle: order.status == OrderStatus.preparing
//                 ? 'In kitchen · Est. 10m remaining'
//                 : 'Kitchen preparation',
//             completed: order.status == OrderStatus.ready ||
//                 order.status == OrderStatus.delivered,
//             active: order.status == OrderStatus.preparing,
//           ),
//           _TimelineStep(
//             title: 'Rider Pickup',
//             subtitle: order.status == OrderStatus.ready
//                 ? 'Ready for pickup'
//                 : 'Pending',
//             completed: order.status == OrderStatus.delivered,
//             active: order.status == OrderStatus.ready,
//             last: true,
//           ),
//         ],
//       ),
//     );
//   }

//   String _formatTime(DateTime value) {
//     final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
//     final minute = value.minute.toString().padLeft(2, '0');
//     final period = value.hour >= 12 ? 'PM' : 'AM';

//     return '$hour:$minute $period';
//   }
// }

// class _TimelineStep extends StatelessWidget {
//   final String title;
//   final String subtitle;
//   final bool completed;
//   final bool active;
//   final bool last;

//   const _TimelineStep({
//     required this.title,
//     required this.subtitle,
//     required this.completed,
//     required this.active,
//     this.last = false,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       height: 58,
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           SizedBox(
//             width: 20,
//             child: Column(
//               children: [
//                 Container(
//                   width: 7,
//                   height: 7,
//                   decoration: BoxDecoration(
//                     color: active || completed
//                         ? const Color(0xFFE31B3F)
//                         : const Color(0xFF343434),
//                     shape: BoxShape.circle,
//                   ),
//                 ),
//                 if (!last)
//                   Expanded(
//                     child: Container(
//                       width: 1,
//                       color: const Color(0xFF303030),
//                     ),
//                   ),
//               ],
//             ),
//           ),
//           const SizedBox(width: 5),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(title,
//                     style: AppTextStyles.caption(context).copyWith(
//                       color: active || completed
//                           ? const Color(0xFFDADADA)
//                           : const Color(0xFF707070),
//                     )),
//                 const SizedBox(height: 3),
//                 Text(subtitle,
//                     style: AppTextStyles.caption(context).copyWith(
//                       backgroundColor: active
//                           ? const Color(0xFFB8B8B8)
//                           : const Color(0xFF5E5E5E),
//                     )),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// /* -------------------------------------------------------------------------- */
// /* STATUS                                                                    */
// /* -------------------------------------------------------------------------- */

// class _StatusCard extends StatelessWidget {
//   final OrderModel order;
//   final OrderDetailProvider provider;

//   const _StatusCard({
//     required this.order,
//     required this.provider,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return _DarkCard(
//       title: 'ORDER STATUS',
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           _SmallStatusBadge(
//             status: order.status,
//           ),
//           const SizedBox(height: 12),
//           Wrap(
//             spacing: 6,
//             runSpacing: 6,
//             children: OrderStatus.values
//                 .where(
//                   (status) => status != OrderStatus.cancelled,
//                 )
//                 .map(
//                   (status) => _StatusButton(
//                     label: status.label,
//                     active: status == order.status,
//                     onTap: () {
//                       provider.updateStatus(status);
//                     },
//                   ),
//                 )
//                 .toList(),
//           ),
//           const SizedBox(height: 6),
//           TextButton(
//             onPressed: () {
//               provider.updateStatus(
//                 OrderStatus.cancelled,
//               );
//             },
//             style: TextButton.styleFrom(
//               padding: EdgeInsets.zero,
//               minimumSize: const Size(0, 25),
//             ),
//             child: Text('Cancel Order',
//                 style: AppTextStyles.caption(context)
//                     .copyWith(color: const Color(0xFFCE3048))),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _StatusButton extends StatelessWidget {
//   final String label;
//   final bool active;
//   final VoidCallback onTap;

//   const _StatusButton({
//     required this.label,
//     required this.active,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(3),
//       child: Container(
//         height: 25,
//         padding: const EdgeInsets.symmetric(
//           horizontal: 9,
//         ),
//         alignment: Alignment.center,
//         decoration: BoxDecoration(
//           color: active ? const Color(0xFF8F1028) : const Color(0xFF151515),
//           borderRadius: BorderRadius.circular(3),
//           border: Border.all(
//             color: active ? const Color(0xFFB51A35) : const Color(0xFF353535),
//           ),
//         ),
//         child: Text(label,
//             style: AppTextStyles.caption(context).copyWith(
//               color: active ? Colors.white : const Color(0xFF9A9A9A),
//             )),
//       ),
//     );
//   }
// }

// /* -------------------------------------------------------------------------- */
// /* BOTTOM ACTION BAR                                                         */
// /* -------------------------------------------------------------------------- */

// class _BottomActionBar extends StatelessWidget {
//   final OrderModel order;
//   final OrderDetailProvider provider;

//   const _BottomActionBar({
//     required this.order,
//     required this.provider,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final narrow = MediaQuery.sizeOf(context).width < 900;

//     final quickActions = Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Text('QUICK ACTIONS',
//             style: AppTextStyles.caption(context)
//                 .copyWith(color: const Color(0xFF656565))),
//         const SizedBox(width: 14),
//         _QuickAction(
//           icon: Icons.schedule_outlined,
//           title: 'Delay',
//           subtitle: '5m',
//           onTap: () {},
//         ),
//         const SizedBox(width: 7),
//         _QuickAction(
//           icon: Icons.notifications_none_outlined,
//           title: 'Notify',
//           subtitle: 'Rider',
//           onTap: () {},
//         ),
//       ],
//     );

//     final primaryActions = Wrap(
//       spacing: 7,
//       runSpacing: 7,
//       alignment: WrapAlignment.end,
//       children: [
//         _BottomButton(
//           label: 'Contact Customer',
//           icon: Icons.phone_outlined,
//           onTap: () {},
//         ),
//         _BottomButton(
//           label: 'Mark Ready',
//           icon: Icons.check_circle_outline,
//           onTap: () {
//             provider.updateStatus(
//               OrderStatus.ready,
//             );
//           },
//         ),
//         _BottomButton(
//           label: 'Dispatch Rider',
//           icon: Icons.delivery_dining_outlined,
//           primary: true,
//           onTap: () {
//             provider.updateStatus(
//               OrderStatus.delivered,
//             );
//           },
//         ),
//       ],
//     );

//     return Container(
//       padding: EdgeInsets.symmetric(
//         horizontal: narrow ? 12 : 18,
//         vertical: narrow ? 10 : 0,
//       ),
//       constraints: BoxConstraints(minHeight: narrow ? 0 : 57),
//       decoration: const BoxDecoration(
//         color: Color(0xFF0D0D0D),
//         border: Border(
//           top: BorderSide(
//             color: Color(0xFF292929),
//           ),
//         ),
//       ),
//       child: narrow
//           ? Column(
//               crossAxisAlignment: CrossAxisAlignment.stretch,
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 SingleChildScrollView(
//                   scrollDirection: Axis.horizontal,
//                   child: quickActions,
//                 ),
//                 const SizedBox(height: 8),
//                 primaryActions,
//               ],
//             )
//           : Row(
//               children: [
//                 quickActions,
//                 const Spacer(),
//                 primaryActions,
//               ],
//             ),
//     );
//   }
// }

// class _QuickAction extends StatelessWidget {
//   final IconData icon;
//   final String title;
//   final String subtitle;
//   final VoidCallback onTap;

//   const _QuickAction({
//     required this.icon,
//     required this.title,
//     required this.subtitle,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(3),
//       child: Container(
//         height: 30,
//         padding: const EdgeInsets.symmetric(
//           horizontal: 9,
//         ),
//         decoration: BoxDecoration(
//           color: const Color(0xFF151515),
//           borderRadius: BorderRadius.circular(3),
//           border: Border.all(
//             color: const Color(0xFF303030),
//           ),
//         ),
//         child: Row(
//           children: [
//             Icon(
//               icon,
//               size: 10,
//               color: const Color(0xFF888888),
//             ),
//             const SizedBox(width: 5),
//             Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(title,
//                     style: AppTextStyles.caption(context)
//                         .copyWith(color: const Color(0xFFB0B0B0))),
//                 Text(subtitle,
//                     style: AppTextStyles.caption(context)
//                         .copyWith(color: const Color(0xFF666666))),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _BottomButton extends StatelessWidget {
//   final String label;
//   final IconData icon;
//   final bool primary;
//   final VoidCallback onTap;

//   const _BottomButton({
//     required this.label,
//     required this.icon,
//     required this.onTap,
//     this.primary = false,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(3),
//       child: Container(
//         height: 32,
//         padding: const EdgeInsets.symmetric(
//           horizontal: 12,
//         ),
//         decoration: BoxDecoration(
//           color: primary ? const Color(0xFFBD1534) : const Color(0xFF161616),
//           borderRadius: BorderRadius.circular(3),
//           border: Border.all(
//             color: primary ? const Color(0xFFD22645) : const Color(0xFF353535),
//           ),
//         ),
//         child: Row(
//           children: [
//             Icon(
//               icon,
//               size: 11,
//               color: primary ? Colors.white : const Color(0xFFAAAAAA),
//             ),
//             const SizedBox(width: 6),
//             Text(label,
//                 style: AppTextStyles.caption(context).copyWith(
//                   color: primary ? Colors.white : const Color(0xFFBDBDBD),
//                 )),
//           ],
//         ),
//       ),
//     );
//   }
// }

// /* -------------------------------------------------------------------------- */
// /* COMMON CARD                                                               */
// /* -------------------------------------------------------------------------- */

// class _DarkCard extends StatelessWidget {
//   final String title;
//   final String? trailing;
//   final Widget child;

//   const _DarkCard({
//     required this.title,
//     required this.child,
//     this.trailing,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(11),
//       decoration: BoxDecoration(
//         color: const Color(0xFF111111),
//         borderRadius: BorderRadius.circular(7),
//         border: Border.all(
//           color: const Color(0xFF292929),
//         ),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Expanded(
//                 child: Text(title,
//                     style: AppTextStyles.caption(context)
//                         .copyWith(color: const Color(0xFF777777))),
//               ),
//               if (trailing != null)
//                 Text(trailing!,
//                     style: AppTextStyles.caption(context)
//                         .copyWith(color: const Color(0xFF666666))),
//             ],
//           ),
//           const SizedBox(height: 11),
//           child,
//         ],
//       ),
//     );
//   }
// }

// /* -------------------------------------------------------------------------- */
// /* STATUS BADGE                                                              */
// /* -------------------------------------------------------------------------- */

// class _SmallStatusBadge extends StatelessWidget {
//   final OrderStatus status;

//   const _SmallStatusBadge({
//     required this.status,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final Color color;

//     switch (status) {
//       case OrderStatus.pending:
//         color = const Color(0xFFE3A326);
//         break;
//       case OrderStatus.preparing:
//         color = const Color(0xFFE3A326);
//         break;
//       case OrderStatus.ready:
//         color = const Color(0xFF27B879);
//         break;
//       case OrderStatus.delivered:
//         color = const Color(0xFF3B8DFF);
//         break;
//       case OrderStatus.cancelled:
//         color = const Color(0xFFD8324E);
//         break;
//     }

//     return Container(
//       padding: const EdgeInsets.symmetric(
//         horizontal: 5,
//         vertical: 2,
//       ),
//       decoration: BoxDecoration(
//         color: color.withOpacity(.12),
//         borderRadius: BorderRadius.circular(3),
//         border: Border.all(
//           color: color.withOpacity(.28),
//         ),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Container(
//             width: 4,
//             height: 4,
//             decoration: BoxDecoration(
//               color: color,
//               shape: BoxShape.circle,
//             ),
//           ),
//           const SizedBox(width: 4),
//           Text(status.label.toUpperCase(),
//               style: AppTextStyles.caption(context)
//                   .copyWith(color: const Color(0xFF656565))),
//         ],
//       ),
//     );
//   }
// }

// order_details_screen.dart  (full replacement)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/utils/responsive_size.dart';
import '../../models/order_model.dart';
import '../../providers/order_providers.dart'; // or your order detail providers
import '../../services/order_service.dart';
import '../../widgets/buttons/rdx_action_button.dart';
import '../../widgets/reusable_widgets/empty_state.dart';
import '../../widgets/reusable_widgets/loading_indicator.dart';
import '../../widgets/reusable_widgets/rdx_header.dart';

/// Fetches a single order by ID (one-shot + optional stream).
final orderDetailProvider =
    FutureProvider.family<OrderModel?, String>((ref, orderId) async {
  if (orderId.trim().isEmpty) return null;
  return OrderService().fetchOrderById(orderId);
});

class OrderDetailsScreen extends ConsumerWidget {
  final String orderId;

  const OrderDetailsScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final asyncOrder = ref.watch(orderDetailProvider(orderId));

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          RdxHeader(
            title: asyncOrder.when(
              data: (o) =>
                  o == null ? 'Order Detail' : 'Order #${_shortId(o.id)}',
              loading: () => 'Order Detail',
              error: (_, __) => 'Order Detail',
            ),
            showBackButton: true,
          ),
          Expanded(
            child: asyncOrder.when(
              loading: () => const LoadingIndicator(),
              error: (e, _) => EmptyState(message: 'Failed to load order.\n$e'),
              data: (order) {
                if (order == null) {
                  return const EmptyState(message: 'Order not found.');
                }
                return _OrderDetailBody(order: order);
              },
            ),
          ),
        ],
      ),
    );
  }

  String _shortId(String id) =>
      id.length >= 4 ? id.substring(id.length - 4) : id;
}

class _OrderDetailBody extends ConsumerWidget {
  final OrderModel order;
  const _OrderDetailBody({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final narrow = MediaQuery.sizeOf(context).width < 900;

    // Simple tax calculation (adjust to your real business rules)
    double subtotal = 0;
    for (final i in order.items) {
      subtotal += i.price * i.quantity;
    }
    final tax = (order.total - subtotal).clamp(0, double.infinity);
    final taxPercent = subtotal > 0 ? (tax / subtotal * 100) : 0.0;

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
                      _ServiceAndCustomer(order: order),
                      SizedBox(height: context.h(14)),
                      _OrderItemsSection(order: order),
                      SizedBox(height: context.h(14)),
                      _BillingSummary(
                        subtotal: subtotal,
                        tax: tax.toDouble(),
                        taxPercent: taxPercent,
                        total: order.total,
                      ),
                      SizedBox(height: context.h(14)),
                      _ReceiptPreview(
                          order: order,
                          subtotal: subtotal,
                          tax: tax.toDouble()),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left column – manage order
                      Expanded(
                        flex: 5,
                        child: Column(
                          children: [
                            _ServiceAndCustomer(order: order),
                            SizedBox(height: context.h(14)),
                            _OrderItemsSection(order: order),
                          ],
                        ),
                      ),
                      SizedBox(width: context.w(16)),
                      // Right column – bill + receipt
                      Expanded(
                        flex: 4,
                        child: Column(
                          children: [
                            _BillingSummary(
                              subtotal: subtotal,
                              tax: tax.toDouble(),
                              taxPercent: taxPercent,
                              total: order.total,
                            ),
                            SizedBox(height: context.h(14)),
                            _ReceiptPreview(
                                order: order,
                                subtotal: subtotal,
                                tax: tax.toDouble()),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        // Bottom action bar
        _BottomBar(order: order),
      ],
    );
  }
}

/* ───────────────────────── Service + Customer ───────────────────────── */

class _ServiceAndCustomer extends StatelessWidget {
  final OrderModel order;
  const _ServiceAndCustomer({required this.order});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.h(14)),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(context.h(12)),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order type chips
          Text('SERVICE OPTION',
              style: AppTextStyles.caption(context)
                  .copyWith(color: colors.textMuted, letterSpacing: 0.6)),
          SizedBox(height: context.h(8)),
          Row(
            children: [
              _chip(context, colors, 'Eat In',
                  order.orderType == OrderType.dineIn),
              // SizedBox(width: context.w(8)),
              // _chip(context, colors, 'To Go',
              //     order.orderType == OrderType.takeaway),
              SizedBox(width: context.w(8)),
              _chip(context, colors, 'Delivery',
                  order.orderType == OrderType.delivery),
            ],
          ),
          SizedBox(height: context.h(14)),
          // Table
          if (order.orderType == OrderType.dineIn) ...[
            Text('TABLE ASSIGNMENT',
                style: AppTextStyles.caption(context)
                    .copyWith(color: colors.textMuted, letterSpacing: 0.6)),
            SizedBox(height: context.h(6)),
            Text(
              (order.tableNumber?.trim().isNotEmpty ?? false)
                  ? 'Table ${order.tableNumber}'
                  : 'No Table / Counter',
              style: AppTextStyles.body(context).copyWith(
                  color: colors.textPrimary, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: context.h(14)),
          ],
          // Customer
          Text('CUSTOMER & PAYMENT',
              style: AppTextStyles.caption(context)
                  .copyWith(color: colors.textMuted, letterSpacing: 0.6)),
          SizedBox(height: context.h(8)),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        order.customerName.isEmpty
                            ? 'Walk-in'
                            : order.customerName,
                        style: AppTextStyles.body(context).copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w600)),
                    if (order.customerPhone.isNotEmpty)
                      Text(order.customerPhone,
                          style: AppTextStyles.caption(context)
                              .copyWith(color: colors.textSecondary)),
                  ],
                ),
              ),
              if (order.paymentMethod != null)
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: context.w(10), vertical: context.h(4)),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(context.h(6)),
                  ),
                  child: Text(
                    order.paymentMethod!.label.toUpperCase(),
                    style: AppTextStyles.caption(context).copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          if (order.notes != null && order.notes!.isNotEmpty) ...[
            SizedBox(height: context.h(10)),
            Text('KITCHEN NOTES',
                style: AppTextStyles.caption(context)
                    .copyWith(color: colors.textMuted)),
            SizedBox(height: context.h(4)),
            Text(order.notes!,
                style: AppTextStyles.bodySecondary(context)
                    .copyWith(color: colors.textSecondary)),
          ],
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, AppColorScheme colors, String label,
      bool selected) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: context.w(12), vertical: context.h(6)),
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : colors.surfaceVariant,
        borderRadius: BorderRadius.circular(context.h(8)),
        border: Border.all(color: selected ? AppColors.primary : colors.border),
      ),
      child: Text(
        label,
        style: AppTextStyles.label(context).copyWith(
          color: selected ? Colors.white : colors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/* ───────────────────────── Order Items ───────────────────────── */

class _OrderItemsSection extends StatelessWidget {
  final OrderModel order;
  const _OrderItemsSection({required this.order});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.h(14)),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(context.h(12)),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('ORDER ITEMS',
                  style: AppTextStyles.caption(context)
                      .copyWith(color: colors.textMuted, letterSpacing: 0.6)),
              const Spacer(),
              Text('${order.items.length} items',
                  style: AppTextStyles.caption(context)
                      .copyWith(color: colors.textSecondary)),
            ],
          ),
          SizedBox(height: context.h(12)),
          for (final item in order.items) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: AppTextStyles.body(context).copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w600),
                      ),
                      if (item.spiceLevel != null || item.addOns.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(top: context.h(2)),
                          child: Text(
                            [
                              if (item.spiceLevel != null) item.spiceLevel!,
                              ...item.addOns,
                            ].join(' · '),
                            style: AppTextStyles.caption(context)
                                .copyWith(color: colors.textSecondary),
                          ),
                        ),
                      if (item.notes != null && item.notes!.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(top: context.h(2)),
                          child: Text(
                            'Note: ${item.notes}',
                            style: AppTextStyles.caption(context).copyWith(
                                color: colors.textMuted,
                                fontStyle: FontStyle.italic),
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  '${item.quantity} × ₹${item.price.toStringAsFixed(0)}',
                  style: AppTextStyles.body(context)
                      .copyWith(color: colors.textSecondary),
                ),
                SizedBox(width: context.w(12)),
                Text(
                  '₹${(item.price * item.quantity).toStringAsFixed(0)}',
                  style: AppTextStyles.body(context).copyWith(
                      color: colors.textPrimary, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            SizedBox(height: context.h(12)),
          ],
        ],
      ),
    );
  }
}

/* ───────────────────────── Billing Summary ───────────────────────── */

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

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.h(14)),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(context.h(12)),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('BILL SUMMARY',
              style: AppTextStyles.caption(context)
                  .copyWith(color: colors.textMuted, letterSpacing: 0.6)),
          SizedBox(height: context.h(12)),
          _row(context, colors, 'Subtotal', '₹${subtotal.toStringAsFixed(2)}'),
          SizedBox(height: context.h(6)),
          _row(
              context,
              colors,
              'Tax & Surcharge (${taxPercent.toStringAsFixed(1)}%)',
              '₹${tax.toStringAsFixed(2)}'),
          SizedBox(height: context.h(10)),
          Divider(color: colors.divider, height: 1),
          SizedBox(height: context.h(10)),
          Row(
            children: [
              Text('Total Due',
                  style: AppTextStyles.section(context)
                      .copyWith(color: colors.textPrimary)),
              const Spacer(),
              Text('₹${total.toStringAsFixed(2)}',
                  style: AppTextStyles.section(context).copyWith(
                      color: AppColors.primary, fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(
      BuildContext context, AppColorScheme colors, String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(label,
              style: AppTextStyles.bodySecondary(context)
                  .copyWith(color: colors.textSecondary)),
        ),
        Text(value,
            style: AppTextStyles.body(context)
                .copyWith(color: colors.textPrimary)),
      ],
    );
  }
}

/* ───────────────────────── Receipt Preview ───────────────────────── */

class _ReceiptPreview extends StatelessWidget {
  final OrderModel order;
  final double subtotal;
  final double tax;

  const _ReceiptPreview({
    required this.order,
    required this.subtotal,
    required this.tax,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.h(16)),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(context.h(12)),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Text('RDX CORE RESTAURANT & BAR',
              style: AppTextStyles.label(context).copyWith(
                  color: colors.textPrimary, fontWeight: FontWeight.w700)),
          SizedBox(height: context.h(2)),
          Text(
              'Order #${order.id.length >= 6 ? order.id.substring(0, 6) : order.id}',
              style: AppTextStyles.caption(context)
                  .copyWith(color: colors.textMuted)),
          SizedBox(height: context.h(12)),
          Divider(color: colors.divider, height: 1),
          SizedBox(height: context.h(10)),
          for (final item in order.items)
            Padding(
              padding: EdgeInsets.only(bottom: context.h(4)),
              child: Row(
                children: [
                  Expanded(
                    child: Text('${item.quantity}x ${item.name}',
                        style: AppTextStyles.caption(context)
                            .copyWith(color: colors.textSecondary)),
                  ),
                  Text('₹${(item.price * item.quantity).toStringAsFixed(2)}',
                      style: AppTextStyles.caption(context)
                          .copyWith(color: colors.textPrimary)),
                ],
              ),
            ),
          SizedBox(height: context.h(8)),
          Divider(color: colors.divider, height: 1),
          SizedBox(height: context.h(8)),
          _receiptRow(context, colors, 'Subtotal', subtotal),
          _receiptRow(context, colors, 'Tax', tax),
          SizedBox(height: context.h(6)),
          _receiptRow(context, colors, 'TOTAL', order.total, bold: true),
          SizedBox(height: context.h(12)),
          Text('Thank you for dining at RDX!',
              style: AppTextStyles.caption(context)
                  .copyWith(color: colors.textMuted)),
        ],
      ),
    );
  }

  Widget _receiptRow(
      BuildContext context, AppColorScheme colors, String label, double value,
      {bool bold = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.h(3)),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: (bold
                        ? AppTextStyles.label(context)
                        : AppTextStyles.caption(context))
                    .copyWith(
                        color: bold ? colors.textPrimary : colors.textSecondary,
                        fontWeight: bold ? FontWeight.w700 : FontWeight.w400)),
          ),
          Text('₹${value.toStringAsFixed(2)}',
              style: (bold
                      ? AppTextStyles.label(context)
                      : AppTextStyles.caption(context))
                  .copyWith(
                      color: colors.textPrimary,
                      fontWeight: bold ? FontWeight.w700 : FontWeight.w400)),
        ],
      ),
    );
  }
}

/* ───────────────────────── Bottom Action Bar ───────────────────────── */

class _BottomBar extends ConsumerWidget {
  final OrderModel order;
  const _BottomBar({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final actionLabel = order.status.advanceActionLabel;

    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(
            context.w(20), context.h(12), context.w(20), context.h(14)),
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border(top: BorderSide(color: colors.border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: RdxActionButton(
                label: 'Print Bill & Receipt',
                leadingIcon: Icons.print_outlined,
                onPressed: () {
                  // TODO: integrate real printer / share PDF
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sending to printer…')),
                  );
                },
              ),
            ),
            SizedBox(width: context.w(10)),
            if (actionLabel != null)
              Expanded(
                child: RdxActionButton(
                  label: actionLabel,
                  isPrimary: true,
                  onPressed: () async {
                    final next = order.status.nextStatus;
                    if (next == null) return;
                    await OrderService().updateOrderStatus(order.id, next);
                    // Refresh the detail screen
                    ref.invalidate(orderDetailProvider(order.id));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Status → ${next.label}')),
                      );
                    }
                  },
                ),
              ),
            if (order.status == OrderStatus.ready ||
                order.status == OrderStatus.delivered) ...[
              SizedBox(width: context.w(10)),
              Expanded(
                child: RdxActionButton(
                  label: 'Mark Paid & Complete',
                  isPrimary: true,
                  onPressed: () async {
                    await OrderService()
                        .updateOrderStatus(order.id, OrderStatus.delivered);
                    ref.invalidate(orderDetailProvider(order.id));
                    if (context.mounted) {
                      Navigator.of(context).pop(true);
                    }
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
