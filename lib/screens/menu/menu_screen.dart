import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/menu_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/rdx_header.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<MenuProvider>().load());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MenuProvider>();

    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      appBar: RdxHeader(
        title: 'Menu Management',
        actions: [
          ElevatedButton.icon(
            onPressed: () async {
              await Navigator.of(context).pushNamed(AppRoutes.editMenuItem);
              if (context.mounted) context.read<MenuProvider>().load();
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Item'),
          ),
        ],
      ),
      body: provider.isLoading
          ? const LoadingIndicator()
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: provider.setSearchQuery,
                          decoration: const InputDecoration(
                            hintText: 'Search menu items...',
                            prefixIcon: Icon(Icons.search, size: 18),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      DropdownButton<String>(
                        value: provider.selectedCategory,
                        dropdownColor: AppColors.surface,
                        underline: const SizedBox(),
                        items: provider.categories
                            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) provider.setCategory(value);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: provider.filteredItems.isEmpty
                        ? const EmptyState(message: 'No menu items found')
                        : GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: 0.85,
                            ),
                            itemCount: provider.filteredItems.length,
                            itemBuilder: (context, index) {
                              final item = provider.filteredItems[index];
                              return Container(
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          color: AppColors.surfaceVariant,
                                          borderRadius:
                                              BorderRadius.vertical(top: Radius.circular(12)),
                                        ),
                                        child: const Center(
                                          child: Icon(Icons.fastfood_outlined,
                                              color: AppColors.textMuted, size: 32),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(item.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                  color: AppColors.textPrimary,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13)),
                                          const SizedBox(height: 4),
                                          Text('₹${item.price.toStringAsFixed(0)}',
                                              style: const TextStyle(
                                                  color: AppColors.primary,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600)),
                                          const SizedBox(height: 6),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Switch(
                                                value: item.available,
                                                onChanged: (_) => provider.toggleAvailability(item),
                                                activeColor: AppColors.primary,
                                              ),
                                              Row(
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(Icons.edit_outlined, size: 16),
                                                    color: AppColors.textSecondary,
                                                    onPressed: () async {
                                                      await Navigator.of(context).pushNamed(
                                                        AppRoutes.editMenuItem,
                                                        arguments: item.id,
                                                      );
                                                      if (context.mounted) {
                                                        context.read<MenuProvider>().load();
                                                      }
                                                    },
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(Icons.delete_outline, size: 16),
                                                    color: AppColors.danger,
                                                    onPressed: () => provider.deleteItem(item.id),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
