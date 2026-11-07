import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rdx_admin/core/theme/app_colors.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import 'package:rdx_admin/core/utils/responsive_size.dart';
import 'package:rdx_admin/models/order_model.dart';

class LiveOrderCard extends StatefulWidget {
  final OrderModel order;
  final String? actionText;
  final ValueChanged<OrderModel>? onAdvance;
  final String? secondaryActionText;
  final ValueChanged<OrderModel>? onSecondaryAction;
  final VoidCallback? onTap;

  const LiveOrderCard({
    super.key,
    required this.order,
    this.actionText,
    this.onAdvance,
    this.secondaryActionText,
    this.onSecondaryAction,
    this.onTap,
  });

  @override
  State<LiveOrderCard> createState() => _LiveOrderCardState();
}

class _LiveOrderCardState extends State<LiveOrderCard> {
  bool _itemsExpanded = false;
  bool _itemsHovering = false;

  OrderModel get order => widget.order;
  String? get actionText => widget.actionText;
  ValueChanged<OrderModel>? get onAdvance => widget.onAdvance;
  String? get secondaryActionText => widget.secondaryActionText;
  ValueChanged<OrderModel>? get onSecondaryAction => widget.onSecondaryAction;
  VoidCallback? get onTap => widget.onTap;

  void _log(String message) {
    if (kDebugMode) debugPrint('[LiveOrderCard] $message');
  }

  void _tapAdvance() {
    _log(
      'Status action tapped (order: ${order.id}, action: $actionText, '
      'status: ${order.status.name}, callback: ${onAdvance != null}).',
    );
    onAdvance?.call(order);
  }

  void _tapSecondaryAction() {
    _log(
      'Secondary action tapped (order: ${order.id}, '
      'action: $secondaryActionText, '
      'callback: ${onSecondaryAction != null}).',
    );
    onSecondaryAction?.call(order);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final primaryTitle = _getPrimaryTitle();
    final primaryIcon = _getPrimaryIcon();
    final isPaid = order.paymentStatus == PaymentStatus.paid;
    final hasMultipleItems = order.items.length > 1;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(context.h(10)),
        border: Border.all(
          color: colors.border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── UPPER HALF (larger) — tappable → opens order details ──────
          // Everything above the divider is one big hit target.
          // Lower half is completely non-interactive except the two buttons.
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(context.h(10)),
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  context.w(14),
                  context.h(14),
                  context.w(14),
                  context.h(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // PRIMARY ORDER INFORMATION
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: context.w(28),
                          height: context.w(28),
                          decoration: BoxDecoration(
                            color: colors.surfaceVariant,
                            borderRadius: BorderRadius.circular(context.w(7)),
                            border: Border.all(color: colors.border),
                          ),
                          child: Icon(
                            primaryIcon,
                            size: context.w(15),
                            color: colors.textPrimary,
                          ),
                        ),
                        SizedBox(width: context.w(9)),
                        Expanded(
                          child: Text(
                            primaryTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                AppTextStyles.bodySecondary(context).copyWith(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(width: context.w(6)),
                        _orderTypeBadge(context, colors),
                      ],
                    ),

                    SizedBox(height: context.h(15)),

                    // ORDER DATE + TIME
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: context.h(15),
                          color: colors.textMuted,
                        ),
                        SizedBox(width: context.w(5)),
                        Expanded(
                          child: Text(
                            _formatOrderDateTime(order.createdAt),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodyTertiary(context).copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // PHONE NUMBER
                    if (_hasCustomerPhone) ...[
                      SizedBox(height: context.h(6)),
                      Row(
                        children: [
                          Icon(
                            Icons.call_outlined,
                            size: context.h(15),
                            color: colors.textMuted,
                          ),
                          SizedBox(width: context.w(5)),
                          Expanded(
                            child: Text(
                              order.customerPhone.trim(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  AppTextStyles.bodyTertiary(context).copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    SizedBox(height: context.h(9)),

                    // ITEMS
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: AnimatedSize(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            alignment: Alignment.topLeft,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (order.items.isEmpty)
                                  Text(
                                    'Order',
                                    style: AppTextStyles.bodySecondary(context)
                                        .copyWith(
                                      color: colors.textSecondary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  )
                                else if (!_itemsExpanded && hasMultipleItems)
                                  Text(
                                    '${order.items.first.quantity}x '
                                    '${order.items.first.name} and more...',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.bodySecondary(context)
                                        .copyWith(
                                      color: colors.textSecondary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  )
                                else
                                  for (final item in order.items)
                                    Padding(
                                      padding: EdgeInsets.only(
                                        bottom: context.h(3),
                                      ),
                                      child: Text(
                                        '${item.quantity}x ${item.name}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style:
                                            AppTextStyles.bodySecondary(context)
                                                .copyWith(
                                          color: colors.textSecondary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                              ],
                            ),
                          ),
                        ),
                        if (hasMultipleItems) ...[
                          SizedBox(width: context.w(6)),
                          MouseRegion(
                            onEnter: (_) =>
                                setState(() => _itemsHovering = true),
                            onExit: (_) =>
                                setState(() => _itemsHovering = false),
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                setState(() {
                                  _itemsExpanded = !_itemsExpanded;
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 160),
                                curve: Curves.easeOut,
                                width: context.h(28).clamp(24.0, 28.0),
                                height: context.h(28).clamp(24.0, 28.0),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _itemsHovering
                                      ? AppColors.primary
                                      : colors.surface,
                                  border: Border.all(
                                    color: _itemsHovering
                                        ? AppColors.primary
                                        : colors.border,
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                                    _itemsExpanded
                                        ? Icons.keyboard_arrow_up_rounded
                                        : Icons.keyboard_arrow_down_rounded,
                                    size: context.h(18).clamp(14.0, 18.0),
                                    color: _itemsHovering
                                        ? AppColors.surface
                                        : AppColors.lightTextPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),

                    SizedBox(height: context.h(10)),

                    // TOTAL + PAYMENT STATUS
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          '₹${_orderTotal.toStringAsFixed(0)}',
                          style: AppTextStyles.section(context).copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        _paymentStatusBadge(context, isPaid: isPaid),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── LOWER HALF (smaller) — NOT tappable as a whole ─────────────
          // Only the Pay Now / action chips receive taps.
          // No InkWell / GestureDetector here on the container itself.
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.w(14),
              context.h(6),
              context.w(14),
              context.h(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 1,
                  color: colors.divider,
                ),
                SizedBox(height: context.h(10)),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.w(7),
                        vertical: context.h(5),
                      ),
                      decoration: BoxDecoration(
                        color: colors.surfaceVariant,
                        borderRadius: BorderRadius.circular(context.h(5)),
                        border: Border.all(color: colors.border),
                      ),
                      child: Text(
                        '${order.items.length} '
                        '${order.items.length == 1 ? 'Item' : 'Items'}',
                        style: AppTextStyles.caption(context).copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (secondaryActionText != null &&
                        onSecondaryAction != null) ...[
                      _actionChip(
                        context,
                        label: secondaryActionText!,
                        primary: false,
                        onTap: _tapSecondaryAction,
                      ),
                      SizedBox(width: context.w(6)),
                    ],
                    if (actionText != null && onAdvance != null)
                      _actionChip(
                        context,
                        label: actionText!,
                        primary: true,
                        onTap: _tapAdvance,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionChip(
    BuildContext context, {
    required String label,
    required bool primary,
    required VoidCallback onTap,
  }) {
    final colors = AppColors.of(context);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(context.h(5)),
      child: InkWell(
        borderRadius: BorderRadius.circular(context.h(5)),
        onTap: onTap,
        child: Container(
          height: context.h(28).clamp(24.0, 28.0),
          padding: EdgeInsets.symmetric(
            horizontal: context.w(11).clamp(7.0, 11.0),
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: primary ? AppColors.primary : colors.surface,
            borderRadius: BorderRadius.circular(context.h(5)),
            border: primary
                ? null
                : Border.all(
                    color: AppColors.primary.withValues(alpha: 0.45),
                  ),
          ),
          child: Text(
            label,
            style: AppTextStyles.caption(context).copyWith(
              color: primary ? Colors.white : AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // ORDER TOTAL
  // -------------------------------------------------------------------------

  double get _orderTotal => order.items.fold<double>(
        0,
        (sum, item) => sum + (item.price * item.quantity),
      );

  // -------------------------------------------------------------------------
  // ORDER TYPE BADGE
  // -------------------------------------------------------------------------

  /// Badge priority:
  /// - App-sourced orders → always "App" (never show Delivery/Dine-in as source).
  /// - Walk-in (staff POS) → order type label (Dine In / Takeaway / Delivery).
  Widget _orderTypeBadge(BuildContext context, AppColorScheme colors) {
    final isApp = order.orderSource == OrderSource.app;
    final label = isApp ? 'App' : _formatEnumLabel(order.orderType.name);
    final accent = isApp ? const Color(0xFF7C5CFC) : AppColors.primary;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(7),
        vertical: context.h(4),
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(context.h(20)),
        border: Border.all(
          color: accent.withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.caption(context).copyWith(
          color: accent,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // PAYMENT STATUS BADGE
  // -------------------------------------------------------------------------

  Widget _paymentStatusBadge(BuildContext context, {required bool isPaid}) {
    final color = isPaid ? const Color(0xFF20B47A) : const Color(0xFFE9A719);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(7),
        vertical: context.h(4),
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(context.h(20)),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        isPaid ? 'Paid' : 'Unpaid',
        style: AppTextStyles.caption(context).copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // PRIMARY INFORMATION
  // -------------------------------------------------------------------------

  bool get _hasTableNumber {
    final tableNumber = order.tableNumber;
    return tableNumber != null && tableNumber.trim().isNotEmpty;
  }

  bool get _hasCustomerName {
    final customerName = order.customerName;
    return customerName.trim().isNotEmpty;
  }

  bool get _hasCustomerPhone {
    final phone = order.customerPhone;
    return phone.trim().isNotEmpty;
  }

  String _getPrimaryTitle() {
    if (_hasTableNumber) {
      return 'Table ${order.tableNumber!.trim()}';
    }

    if (_hasCustomerName) {
      return order.customerName.trim();
    }

    return order.id;
  }

  IconData _getPrimaryIcon() {
    if (_hasTableNumber) {
      return Icons.table_restaurant_outlined;
    }

    if (_hasCustomerName) {
      return Icons.person_outline;
    }

    return Icons.receipt_long_outlined;
  }

  // -------------------------------------------------------------------------
  // DATE + TIME
  // -------------------------------------------------------------------------

  String _formatOrderDateTime(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = _monthName(dateTime.month);
    final year = dateTime.year;

    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';

    return '$day $month $year • $hour:$minute $period';
  }

  String _monthName(int month) {
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

  // -------------------------------------------------------------------------
  // ENUM LABEL FORMATTING (e.g. dineIn -> "Dine In")
  // -------------------------------------------------------------------------

  String _formatEnumLabel(String raw) {
    if (raw.isEmpty) return raw;

    final buffer = StringBuffer();

    for (var i = 0; i < raw.length; i++) {
      final char = raw[i];
      final isUpper = char == char.toUpperCase() && char != char.toLowerCase();

      if (i > 0 && isUpper) {
        buffer.write(' ');
      }

      buffer.write(i == 0 ? char.toUpperCase() : char);
    }

    return buffer.toString();
  }
}
