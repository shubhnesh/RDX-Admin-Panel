import 'package:flutter/material.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import 'package:rdx_admin/core/utils/responsive_size.dart';
import 'package:rdx_admin/models/order_model.dart';

class LiveOrderCard extends StatelessWidget {
  final OrderModel order;
  final String? actionText;
  final ValueChanged<OrderModel>? onAdvance;
  final VoidCallback? onTap;

  const LiveOrderCard({
    super.key,
    required this.order,
    this.actionText,
    this.onAdvance,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(context.h(10)),
        border: Border.all(
          color: const Color(0xFF302B2B),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(context.h(10)),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              context.w(14),
              context.h(13),
              context.w(14),
              context.h(13),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---------------------------------------------------------
                // ORDER ID + TIME
                // ---------------------------------------------------------
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        '#RDX-${order.id}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption(context).copyWith(
                          color: const Color(0xFFE0DCDC),
                        ),
                      ),
                    ),
                    Icon(
                      Icons.schedule_outlined,
                      size: context.h(12),
                      color: const Color(0xFF777070),
                    ),
                    SizedBox(width: context.w(5)),
                    Text(
                      _formatOrderTime(order.createdAt),
                      style: AppTextStyles.caption(context).copyWith(
                        color: const Color(0xFF888080),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: context.h(10)),

                // ---------------------------------------------------------
                // ITEMS
                // ---------------------------------------------------------
                Text(
                  order.items.isEmpty
                      ? 'Order'
                      : order.items
                          .map(
                            (item) => '${item.quantity}x ${item.name}',
                          )
                          .join(', '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption(context).copyWith(
                    color: const Color(0xFFD7D1D1),
                  ),
                ),

                SizedBox(height: context.h(6)),

                // ---------------------------------------------------------
                // CUSTOMER
                // ---------------------------------------------------------
                Text(
                  'Customer: ${order.customerName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption(context).copyWith(
                    color: const Color(0xFF858080),
                  ),
                ),

                SizedBox(height: context.h(12)),

                // ---------------------------------------------------------
                // DIVIDER
                // ---------------------------------------------------------
                Container(
                  height: 1,
                  color: const Color(0xFF292525),
                ),

                SizedBox(height: context.h(11)),

                // ---------------------------------------------------------
                // ITEMS COUNT + ACTION
                // ---------------------------------------------------------
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.w(7),
                        vertical: context.h(5),
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF252020),
                        borderRadius: BorderRadius.circular(
                          context.h(5),
                        ),
                        border: Border.all(
                          color: const Color(0xFF302A2A),
                        ),
                      ),
                      child: Text(
                        '${order.items.length} '
                        '${order.items.length == 1 ? 'Item' : 'Items'}',
                        style: AppTextStyles.caption(context).copyWith(
                          color: const Color(0xFFA69D9D),
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (actionText != null && onAdvance != null)
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(
                            context.h(5),
                          ),
                          onTap: () => onAdvance!(order),
                          child: Container(
                            height: context.h(28),
                            padding: EdgeInsets.symmetric(
                              horizontal: context.w(11),
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF214D9B),
                              borderRadius: BorderRadius.circular(
                                context.h(5),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              actionText!,
                              style: AppTextStyles.caption(context).copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatOrderTime(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'now';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours}h';
    }

    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }
}
