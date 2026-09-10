import 'package:flutter/material.dart';
import 'package:rdx_admin/core/utils/responsive_size.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../models/inventory_item_model.dart';
import '../../../core/utils/formatters.dart';

class InventoryTable extends StatelessWidget {
  final List<InventoryItemModel> items;
  final ValueChanged<InventoryItemModel> onEdit;
  final ValueChanged<InventoryItemModel> onDelete;

  const InventoryTable({
    super.key,
    required this.items,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    if (items.isEmpty) {
      return Center(
        child: Text('No materials match the current filters.',
            style: AppTextStyles.bodySecondary(context)),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(context.h(12)),
        border: Border.all(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header
          Container(
            color: colors.surfaceVariant,
            padding: EdgeInsets.symmetric(
              horizontal: context.w(16),
              vertical: context.h(12),
            ),
            child: Row(
              children: [
                _HeaderCell('MATERIAL', flex: 3),
                _HeaderCell('CATEGORY', flex: 2),
                _HeaderCell('MIN. REQUIRED', flex: 2),
                _HeaderCell('STOCK LEVEL', flex: 3),
                _HeaderCell('STATUS', flex: 2),
                _HeaderCell('UNIT COST', flex: 2),
                _HeaderCell('ACTIONS', flex: 1, align: TextAlign.center),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: colors.divider),
              itemBuilder: (context, index) {
                final item = items[index];
                return _InventoryRow(
                  item: item,
                  onEdit: () => onEdit(item),
                  onDelete: () => onDelete(item),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String label;
  final int flex;
  final TextAlign align;
  const _HeaderCell(this.label, {this.flex = 1, this.align = TextAlign.left});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        textAlign: align,
        style: AppTextStyles.caption(context).copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
          color: AppColors.of(context).textMuted,
        ),
      ),
    );
  }
}

class _InventoryRow extends StatelessWidget {
  final InventoryItemModel item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _InventoryRow({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  Color _statusColor(StockStatus s) {
    switch (s) {
      case StockStatus.inStock:
        return AppColors.success;
      case StockStatus.lowStock:
        return AppColors.warning;
      case StockStatus.critical:
        return AppColors.danger;
      case StockStatus.outOfStock:
        return AppColors.danger;
    }
  }

  String _statusLabel(StockStatus s) {
    switch (s) {
      case StockStatus.inStock:
        return 'In Stock';
      case StockStatus.lowStock:
        return 'Low Stock';
      case StockStatus.critical:
        return 'Critical';
      case StockStatus.outOfStock:
        return 'Out of Stock';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final status = item.status;
    final color = _statusColor(status);
    final pct = item.stockPercent.clamp(0, 100);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(16),
        vertical: context.h(12),
      ),
      child: Row(
        children: [
          // Material name
          Expanded(
            flex: 3,
            child: Text(item.name,
                style: AppTextStyles.body(context).copyWith(fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
          // Category chip
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: context.w(8), vertical: context.h(3)),
                decoration: BoxDecoration(
                  color: colors.surfaceVariant,
                  borderRadius: BorderRadius.circular(context.h(6)),
                  border: Border.all(color: colors.border),
                ),
                child: Text(item.category,
                    style: AppTextStyles.caption(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
            ),
          ),
          // Min required
          Expanded(
            flex: 2,
            child: Text(
              '${_fmt(item.minRequired)} ${item.unit} min',
              style: AppTextStyles.body(context),
            ),
          ),
          // Stock level bar
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_fmt(item.quantity)} / ${_fmt(item.maxCapacity)} ${item.unit} (${pct.toStringAsFixed(0)}%)',
                  style: AppTextStyles.caption(context),
                ),
                SizedBox(height: context.h(4)),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct / 100,
                    minHeight: 6,
                    backgroundColor: colors.border,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
              ],
            ),
          ),
          // Status badge
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: context.w(10), vertical: context.h(4)),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                    SizedBox(width: context.w(6)),
                    Text(_statusLabel(status),
                        style: TextStyle(
                          color: color,
                          fontSize: context.h(11),
                          fontWeight: FontWeight.w600,
                        )),
                  ],
                ),
              ),
            ),
          ),
          // Unit cost
          Expanded(
            flex: 2,
            child: Text(
              '${Formatters.currency(item.unitCost)}/${item.unit}',
              style: AppTextStyles.body(context),
            ),
          ),
          // Actions
          Expanded(
            flex: 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.edit_outlined, size: 18, color: colors.textSecondary),
                  onPressed: onEdit,
                  tooltip: 'Edit',
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                  onPressed: onDelete,
                  tooltip: 'Delete',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(1);
  }
}
