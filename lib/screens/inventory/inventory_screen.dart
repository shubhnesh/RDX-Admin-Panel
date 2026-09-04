import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/utils/responsive.dart';
import '../../models/inventory_item_model.dart';
import '../../providers/inventory_provider.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/rdx_header.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<InventoryProvider>().load());
  }

  Color _statusColor(StockStatus s) {
    switch (s) {
      case StockStatus.inStock:
        return AppColors.success;
      case StockStatus.lowStock:
        return AppColors.warning;
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
      case StockStatus.outOfStock:
        return 'Out of Stock';
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventoryProvider>();

    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      appBar: RdxHeader(
        title: 'Inventory Management',
        actions: [
          if (provider.lowStockCount + provider.outOfStockCount > 0)
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                  '${provider.lowStockCount + provider.outOfStockCount} items need attention',
                  style:
                      const TextStyle(color: AppColors.warning, fontSize: 12)),
            ),
        ],
      ),
      body: provider.isLoading
          ? const LoadingIndicator()
          : ListView.separated(
              padding: Responsive.pagePadding(context),
              itemCount: provider.items.length,
              separatorBuilder: (_, __) => const Divider(height: 24),
              itemBuilder: (context, index) {
                final item = provider.items[index];
                return Row(
                  children: [
                    Expanded(
                        flex: 2,
                        child: Text(item.name, style: AppTextStyles.body)),
                    Expanded(
                        child: Text(
                            '${item.quantity.toStringAsFixed(1)} ${item.unit}',
                            style: AppTextStyles.bodyMuted)),
                    Expanded(
                        child: Text(_timeAgo(item.lastUpdated),
                            style: AppTextStyles.label)),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _statusColor(item.status).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(_statusLabel(item.status),
                              style: TextStyle(
                                  color: _statusColor(item.status),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      color: AppColors.textSecondary,
                      onPressed: () =>
                          _showUpdateDialog(context, provider, item),
                    ),
                  ],
                );
              },
            ),
    );
  }

  String _timeAgo(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  void _showUpdateDialog(BuildContext context, InventoryProvider provider,
      InventoryItemModel item) {
    final controller = TextEditingController(text: item.quantity.toString());
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Update ${item.name}',
            style: const TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(suffixText: item.unit),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              if (value != null) provider.updateQuantity(item.id, value);
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}
