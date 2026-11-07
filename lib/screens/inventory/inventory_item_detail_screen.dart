import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive_size.dart';
import '../../models/inventory_item_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../widgets/buttons/rdx_action_button.dart';
import '../../widgets/dialogs/rdx_delete_dialog.dart';
import '../../widgets/reusable_widgets/rdx_header.dart';
import '../../widgets/reusable_widgets/stat_card.dart';

class InventoryItemDetailScreen extends ConsumerStatefulWidget {
  final InventoryItemModel item;

  const InventoryItemDetailScreen({
    super.key,
    required this.item,
  });

  @override
  ConsumerState<InventoryItemDetailScreen> createState() =>
      _InventoryItemDetailScreenState();
}

class _InventoryItemDetailScreenState
    extends ConsumerState<InventoryItemDetailScreen> {
  final ScrollController _historyScrollController = ScrollController();
  final List<InventoryStockHistoryEntry> _stockHistory = [];
  String? _historyCursor;
  String? _historyError;
  String? _historyNotice;
  bool _historyLoading = true;
  bool _historyLoadingMore = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadStockHistory();
    });
  }

  @override
  void dispose() {
    _historyScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadStockHistory({bool loadMore = false}) async {
    if (loadMore && (_historyCursor == null || _historyLoadingMore)) return;
    setState(() {
      _historyError = null;
      if (loadMore) {
        _historyLoadingMore = true;
      } else {
        _historyLoading = true;
      }
    });
    try {
      final page = await ref.read(inventoryProvider).fetchStockHistory(
            widget.item.id,
            cursor: loadMore ? _historyCursor : null,
          );
      if (!mounted) return;
      setState(() {
        if (!loadMore) _stockHistory.clear();
        _stockHistory.addAll(page.entries);
        _historyCursor = page.nextCursor;
        _historyNotice = null;
        _historyLoading = false;
        _historyLoadingMore = false;
      });
    } catch (error) {
      if (!mounted) return;
      if (error is FirebaseFunctionsException &&
          error.code == 'invalid-argument' &&
          error.message?.contains('Unsupported inventory action') == true) {
        final item = _currentItem(ref.read(inventoryProvider).items);
        setState(() {
          _stockHistory
            ..clear()
            ..addAll(_legacyHistory(item));
          _historyCursor = null;
          _historyError = null;
          _historyNotice =
              'Showing available legacy history. Deploy the updated '
              'manageInventory Cloud Function to load all stock movements.';
          _historyLoading = false;
          _historyLoadingMore = false;
        });
        return;
      }
      setState(() {
        _historyError = error.toString();
        _historyLoading = false;
        _historyLoadingMore = false;
      });
    }
  }

  InventoryItemModel _currentItem(List<InventoryItemModel> items) {
    for (final item in items) {
      if (item.id == widget.item.id) return item;
    }
    return widget.item;
  }

  List<InventoryStockHistoryEntry> _legacyHistory(InventoryItemModel item) {
    final entries = <InventoryStockHistoryEntry>[];
    final initialAt = item.initialStockAt ?? item.createdAt;
    final initialQuantity = item.initialStockQty ??
        (initialAt != null &&
                item.lastAddedAt != null &&
                initialAt.isAtSameMomentAs(item.lastAddedAt!)
            ? item.lastAddedQty
            : null);

    if (initialAt != null && initialQuantity != null) {
      entries.add(
        InventoryStockHistoryEntry(
          id: 'legacy-initial',
          type: 'initial',
          quantity: initialQuantity,
          occurredAt: initialAt,
          stockBefore: 0,
          stockAfter: initialQuantity,
        ),
      );
    }

    if (item.lastAddedAt != null &&
        item.lastAddedQty != null &&
        (initialAt == null || !initialAt.isAtSameMomentAs(item.lastAddedAt!))) {
      entries.add(
        InventoryStockHistoryEntry(
          id: 'legacy-added',
          type: 'added',
          quantity: item.lastAddedQty!,
          occurredAt: item.lastAddedAt,
          stockBefore: item.lastAddedStockBefore ?? 0,
          stockAfter: (item.lastAddedStockBefore ?? 0) + item.lastAddedQty!,
          purchaseCost: item.lastAddedCost,
          unitCost: item.lastAddedCost == null
              ? null
              : item.lastAddedCost! / item.lastAddedQty!,
          totalCost: item.lastAddedCost,
        ),
      );
    }

    if (item.lastUsedAt != null && item.lastUsedQty != null) {
      final before = item.lastUsedStockBefore ?? item.lastUsedQty!;
      entries.add(
        InventoryStockHistoryEntry(
          id: 'legacy-used',
          type: 'used',
          quantity: item.lastUsedQty!,
          occurredAt: item.lastUsedAt,
          stockBefore: before,
          stockAfter:
              (before - item.lastUsedQty!).clamp(0, double.infinity).toDouble(),
        ),
      );
    }

    entries.sort((a, b) {
      final aTime = a.occurredAt;
      final bTime = b.occurredAt;
      if (aTime == null) return bTime == null ? 0 : 1;
      if (bTime == null) return -1;
      return bTime.compareTo(aTime);
    });
    return entries;
  }

  Future<void> _deleteItem(InventoryItemModel item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => RdxDeleteDialog(
        title: 'Delete Material',
        itemName: item.name,
        deleteButtonLabel: 'Delete Material',
        warningMessage: 'This permanently deletes this inventory material.',
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref.read(inventoryProvider).deleteItem(item.id);
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete material. $error')),
      );
    }
  }

  Widget _buildStockHistory(
    BuildContext context,
    InventoryItemModel item,
  ) {
    if (_historyLoading && _stockHistory.isEmpty) {
      return _stockHistorySection(
        context,
        const Center(child: CircularProgressIndicator()),
        expandChild: true,
      );
    }

    if (_historyError != null && _stockHistory.isEmpty) {
      return _stockHistorySection(
        context,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Could not load stock history: $_historyError'),
            TextButton(
              onPressed: () => _loadStockHistory(),
              child: const Text('Retry'),
            ),
          ],
        ),
        expandChild: true,
      );
    }

    if (_stockHistory.isEmpty) {
      return _stockHistorySection(
        context,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_historyNotice != null) ...[
              Text(
                _historyNotice!,
                style: AppTextStyles.bodySecondary(context).copyWith(
                  color: AppColors.of(context).textSecondary,
                ),
              ),
              SizedBox(height: context.h(8)),
            ],
            Text(
              'No stock history is available.',
              style: AppTextStyles.bodySecondary(context),
            ),
          ],
        ),
        expandChild: true,
      );
    }

    final sortedHistory = List<InventoryStockHistoryEntry>.of(_stockHistory)
      ..sort((a, b) {
        final aTime = a.occurredAt;
        final bTime = b.occurredAt;
        if (aTime == null) return bTime == null ? 0 : 1;
        if (bTime == null) return -1;
        final byTime = bTime.compareTo(aTime);
        return byTime != 0 ? byTime : b.id.compareTo(a.id);
      });
    final grouped = <String, List<InventoryStockHistoryEntry>>{};
    for (final entry in sortedHistory) {
      final date = entry.occurredAt;
      final key = date == null
          ? 'Date unavailable'
          : '${date.year}-${date.month.toString().padLeft(2, '0')}-'
              '${date.day.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(key, () => []).add(entry);
    }
    final sortedDateKeys = grouped.keys.toList()
      ..sort((a, b) {
        if (a == 'Date unavailable') return 1;
        if (b == 'Date unavailable') return -1;
        return b.compareTo(a);
      });

    return _stockHistorySection(
      context,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_historyNotice != null) ...[
            Text(
              _historyNotice!,
              style: AppTextStyles.bodySecondary(context).copyWith(
                color: AppColors.of(context).textSecondary,
              ),
            ),
            SizedBox(height: context.h(12)),
          ],
          Expanded(
            child: Scrollbar(
              controller: _historyScrollController,
              thumbVisibility: true,
              child: ListView(
                controller: _historyScrollController,
                primary: false,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: ClampingScrollPhysics(),
                ),
                padding: EdgeInsets.zero,
                children: [
                  for (final dateKey in sortedDateKeys) ...[
                    Text(
                      _historyDateLabel(grouped[dateKey]!.first.occurredAt),
                      style: AppTextStyles.label(context).copyWith(
                        color: AppColors.of(context).textMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: context.h(8)),
                    for (final entry in grouped[dateKey]!) ...[
                      _StockHistoryTile(item: item, entry: entry),
                      SizedBox(height: context.h(8)),
                    ],
                  ],
                  if (_historyError != null) ...[
                    SizedBox(height: context.h(4)),
                    Text(
                      'Could not load more history: $_historyError',
                      style: AppTextStyles.bodySecondary(context).copyWith(
                        color: AppColors.danger,
                      ),
                    ),
                  ],
                  if (_historyCursor != null)
                    Align(
                      alignment: Alignment.center,
                      child: TextButton(
                        onPressed: _historyLoadingMore
                            ? null
                            : () => _loadStockHistory(loadMore: true),
                        child: Text(
                          _historyLoadingMore
                              ? 'Loading...'
                              : 'Load more history',
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (_historyLoadingMore) const LinearProgressIndicator(),
          if (_stockHistory.isNotEmpty && _historyCursor == null)
            Padding(
              padding: EdgeInsets.only(top: context.h(8)),
              child: Text(
                'End of stock history',
                textAlign: TextAlign.center,
                style: AppTextStyles.label(context).copyWith(
                  color: AppColors.of(context).textMuted,
                ),
              ),
            ),
        ],
      ),
      expandChild: true,
    );
  }

  Widget _stockHistorySection(
    BuildContext context,
    Widget child, {
    bool expandChild = false,
  }) {
    return _SectionCard(
      title: 'Stock History',
      icon: Icons.receipt_long_outlined,
      expandChild: expandChild,
      child: child,
    );
  }

  static const _months = [
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

  static String _historyDateLabel(DateTime? value) {
    if (value == null) return 'Date unavailable';
    final date = value.toLocal();
    return '${date.day.toString().padLeft(2, '0')} '
        '${_months[date.month - 1]} ${date.year}';
  }

  static String _formatTime(DateTime? value) {
    if (value == null) return 'Time unavailable';
    final date = value.toLocal();
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final item = _currentItem(ref.watch(inventoryProvider).items);
    final canEdit = ref.watch(authProvider).permissions.canEditInventory;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            RdxHeader(
              title: item.name,
              showBackButton: true,
            ),
            Expanded(
              child: Padding(
                padding: Responsive.pagePadding(context, top: 12, bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _InventoryItemSummary(item: item),
                    SizedBox(height: context.h(10)),
                    Expanded(child: _buildStockHistory(context, item)),
                    if (canEdit) ...[
                      SizedBox(height: context.h(10)),
                      _ActionsSection(
                        enabled: true,
                        onDelete: () => _deleteItem(item),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatQuantity(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(1);

  static String _formatStockQuantity(InventoryItemModel item, double value) {
    if (item.portionSize <= 0 ||
        item.portionUnit == null ||
        item.portionUnit!.isEmpty) {
      return '${_formatQuantity(value)} ${item.unit}';
    }
    final whole = value.floorToDouble();
    final portions = double.parse(
      ((value - whole) * item.portionSize).toStringAsFixed(4),
    );
    if (portions >= item.portionSize) {
      return '${_formatQuantity(whole + 1)} ${item.unit} + '
          '0 ${item.portionUnit}';
    }
    return '${_formatQuantity(whole)} ${item.unit} + '
        '${_formatQuantity(portions)} ${item.portionUnit}';
  }
}

class _StockHistoryTile extends StatelessWidget {
  final InventoryItemModel item;
  final InventoryStockHistoryEntry entry;

  const _StockHistoryTile({
    required this.item,
    required this.entry,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isAdded = entry.type == 'added' || entry.type == 'initial';
    final title = switch (entry.type) {
      'initial' => 'Initial stock',
      'added' => 'Stock added',
      'used' => 'Stock used',
      _ => 'Stock updated',
    };
    final icon = switch (entry.type) {
      'initial' => Icons.inventory_2_outlined,
      'added' => Icons.add_circle_outline,
      'used' => Icons.remove_circle_outline,
      _ => Icons.history,
    };
    final color = isAdded ? AppColors.success : AppColors.danger;
    final amount = _InventoryItemDetailScreenState._formatStockQuantity(
      item,
      entry.quantity,
    );
    final timestamp = entry.occurredAt;
    final time = _InventoryItemDetailScreenState._formatTime(timestamp);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: context.w(10),
        vertical: context.h(7),
      ),
      decoration: BoxDecoration(
        color: colors.surfaceVariant.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(context.h(8)),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: context.h(16), color: color),
              SizedBox(width: context.w(6)),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.bodySecondary(context).copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                time,
                style: AppTextStyles.label(context).copyWith(
                  color: colors.textMuted,
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(5)),
          Wrap(
            spacing: context.w(14),
            runSpacing: context.h(4),
            children: [
              _detail(context, isAdded ? 'Quantity added' : 'Quantity used',
                  amount),
              _detail(
                context,
                'Stock before → after',
                '${_InventoryItemDetailScreenState._formatStockQuantity(item, entry.stockBefore)}'
                    ' → '
                    '${_InventoryItemDetailScreenState._formatStockQuantity(item, entry.stockAfter)}',
              ),
              if (entry.totalCost != null)
                _detail(
                  context,
                  entry.type == 'used' ? 'Value at use' : 'Purchase cost',
                  Formatters.currency(entry.totalCost!),
                ),
              if (entry.unitCost != null)
                _detail(
                  context,
                  'Rate at this time',
                  '${Formatters.currency(entry.unitCost!)} / ${item.unit}',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detail(BuildContext context, String label, String value) {
    final colors = AppColors.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: AppTextStyles.label(context).copyWith(
            color: colors.textMuted,
          ),
        ),
        SizedBox(width: context.w(6)),
        Text(
          value,
          style: AppTextStyles.bodySecondary(context).copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Shared section shell — same approach as Settings _SettingsCard
// (header + edge-to-edge divider + padded body)
// =============================================================================

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final bool expandChild;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.expandChild = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(context.h(8)),
        border: Border.all(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.w(16),
              context.h(14),
              context.w(16),
              context.h(14),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: context.h(18),
                  color: AppColors.primary,
                ),
                SizedBox(width: context.w(8)),
                Text(
                  title,
                  style: AppTextStyles.section(context).copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          // Full-bleed underline (touches card edges)
          Divider(height: 1, thickness: 1, color: colors.divider),
          if (expandChild)
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  context.w(16),
                  context.h(14),
                  context.w(16),
                  context.h(16),
                ),
                child: child,
              ),
            )
          else
            Padding(
              padding: EdgeInsets.fromLTRB(
                context.w(16),
                context.h(14),
                context.w(16),
                context.h(16),
              ),
              child: child,
            ),
        ],
      ),
    );
  }
}

// =============================================================================
// Stats — single row (same as Inventory overview)
// =============================================================================

class _InventoryItemSummary extends StatelessWidget {
  final InventoryItemModel item;

  const _InventoryItemSummary({required this.item});

  static String _format(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(1);

  static String _formatStock(InventoryItemModel item) {
    if (item.portionSize <= 0 ||
        item.portionUnit == null ||
        item.portionUnit!.isEmpty) {
      return _format(item.quantity);
    }
    final whole = item.quantity.floorToDouble();
    final portions = double.parse(
      ((item.quantity - whole) * item.portionSize).toStringAsFixed(4),
    );
    if (portions >= item.portionSize) {
      return '${_format(whole + 1)} + 0';
    }
    return '${_format(whole)} + ${_format(portions)}';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 600;
          final spacing = isNarrow ? context.w(6) : context.w(12);
          final minH = isNarrow ? 62.0 : 72.0;

          final cards = <Widget>[
            StatCard(
              label: item.portionSize > 0 && item.portionUnit != null
                  ? 'Current Stock (${item.unit} + ${item.portionUnit})'
                  : 'Current Stock (${item.unit})',
              value: _formatStock(item),
              icon: Icons.inventory_2_outlined,
              accentColor: AppColors.primary,
              minHeight: minH,
            ),
            StatCard(
              label: 'Total Expenditure (₹)',
              value: Formatters.currency(item.totalCost),
              icon: Icons.payments_outlined,
              accentColor: AppColors.primary,
              minHeight: minH,
            ),
            StatCard(
              label: 'Unit Cost (₹/${item.unit})',
              value: Formatters.currency(item.unitCost),
              icon: Icons.sell_outlined,
              accentColor: AppColors.warning,
              minHeight: minH,
            ),
          ];

          return Row(
            children: [
              for (int i = 0; i < cards.length; i++) ...[
                Expanded(child: cards[i]),
                if (i != cards.length - 1) SizedBox(width: spacing),
              ],
            ],
          );
        },
      ),
    );
  }
}

// =============================================================================
// Actions — LAST section.
// =============================================================================

class _ActionsSection extends StatelessWidget {
  final bool enabled;
  final VoidCallback onDelete;

  const _ActionsSection({
    required this.enabled,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return _SectionCard(
      title: 'Actions',
      icon: Icons.tune_rounded,
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Remove this item from inventory.',
              style: AppTextStyles.bodySecondary(context).copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
          SizedBox(width: context.w(12)),
          RdxActionButton.discard(
            label: 'Delete',
            onPressed: enabled ? onDelete : null,
          ),
        ],
      ),
    );
  }
}
