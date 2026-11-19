import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rdx_admin/core/theme/app_colors.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import 'package:rdx_admin/core/utils/responsive_size.dart';
import 'package:rdx_admin/models/managed_user_model.dart';
import 'package:rdx_admin/providers/auth_provider.dart';
import 'package:rdx_admin/providers/user_management_provider.dart';
import 'package:rdx_admin/widgets/buttons/rdx_action_button.dart';
import 'package:rdx_admin/widgets/buttons/rdx_header_action_button.dart';
import 'package:rdx_admin/widgets/reusable_widgets/empty_state.dart';
import 'package:rdx_admin/widgets/reusable_widgets/loading_indicator.dart';
import 'package:rdx_admin/widgets/dialogs/rdx_delete_dialog.dart';
import 'package:rdx_admin/widgets/reusable_widgets/rdx_header.dart';
import 'package:rdx_admin/widgets/reusable_widgets/rdx_search_bar.dart';
import 'package:rdx_admin/widgets/reusable_widgets/rdx_table.dart';

import 'add_user_screen.dart';

/// Admin-only account directory.
/// All role writes go through Cloud Functions; local UI checks are not trusted.
class UserManagementScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;

  const UserManagementScreen({super.key, this.onBack});

  @override
  ConsumerState<UserManagementScreen> createState() =>
      _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = ref.read(authProvider);
      if (!auth.permissions.canManageUsers) return;
      ref.read(userManagementProvider).load();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openAdd({ManagedUserModel? existing}) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AddUserScreen(existing: existing)
      )
    );
    if (mounted) await ref.read(userManagementProvider).load();
  }

  Future<void> _disableUser(ManagedUserModel user) async {
    final auth = ref.read(authProvider);
    if (auth.user?.uid == user.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot disable your own account.'))
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => RdxDeleteDialog(
        title: 'Disable user',
        itemName: user.email,
        deleteButtonLabel: 'Disable',
        warningMessage:
            'This disables sign-in for this account. Role history is kept.'
      )
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref.read(userManagementProvider).disableUser(uid: user.uid);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User disabled.'))
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to disable user. $e'))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final auth = ref.watch(authProvider);
    final provider = ref.watch(userManagementProvider);
    final isNarrow = Responsive.isNarrow(context);
    final horizontal = Responsive.pageHorizontal(context);

    if (!auth.permissions.canManageUsers) {
      return Scaffold(
        backgroundColor: colors.background,
        body: Column(
          children: [
            RdxHeader(
              title: 'User Management',
              showBackButton: true,
              onBack: widget.onBack
            ),
            const Expanded(
              child: EmptyState(
                message: 'Admin access required to manage users.'
              )
            ),
          ]
        )
      );
    }

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          RdxHeader(
            title: 'User Management',
            showBackButton: true,
            onBack: widget.onBack
          ),
          SizedBox(height: context.h(isNarrow ? 10 : 14)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontal),
            child: isNarrow
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      RdxSearchBar(
                        controller: _searchController,
                        hintText: 'Search email or role',
                        height: RdxSearchBar.standardHeight(context),
                        onChanged: provider.setSearch
                      ),
                      SizedBox(height: context.h(10)),
                      Align(
                        alignment: Alignment.centerRight,
                        child: RdxHeaderActionButton(
                          label: 'Add user',
                          onPressed: () => _openAdd()
                        )
                      ),
                    ]
                  )
                : Row(
                    children: [
                      Expanded(
                        child: RdxSearchBar(
                          controller: _searchController,
                          hintText: 'Search email or role',
                          height: RdxSearchBar.standardHeight(context),
                          onChanged: provider.setSearch
                        )
                      ),
                      SizedBox(width: context.w(12)),
                      RdxHeaderActionButton(
                        label: 'Add user',
                        onPressed: () => _openAdd()
                      ),
                    ]
                  )
          ),
          SizedBox(height: context.h(12)),
          Expanded(
            child: provider.isLoading
                ? const LoadingIndicator()
                : provider.errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              provider.errorMessage!,
                              style: AppTextStyles.body(context),
                              textAlign: TextAlign.center
                            ),
                            SizedBox(height: context.h(12)),
                            RdxActionButton(
                              label: 'Retry',
                              isPrimary: true,
                              onPressed: () => provider.load()
                            ),
                          ]
                        )
                      )
                    : Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontal,
                          context.h(0),
                          horizontal,
                          context.h(20)
                        ),
                        child: _buildBody(
                          context,
                          colors,
                          provider.filteredUsers
                        )
                      )
          ),
        ]
      )
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppColorScheme colors,
    List<ManagedUserModel> users
  ) {
    if (users.isEmpty) {
      return EmptyState(
        message: ref.read(userManagementProvider).search.trim().isEmpty
            ? 'No users yet.'
            : 'No users match your search.'
      );
    }

    return RdxTable(
      showFooter: false,
      columns: [
        RdxTableColumn(title: 'EMAIL', minWidth: context.w(220), flex: 2.2),
        RdxTableColumn(title: 'ROLE', minWidth: context.w(100), flex: 1),
        RdxTableColumn(title: 'STATUS', minWidth: context.w(100), flex: 1),
        RdxTableColumn(
          title: 'ACTIONS',
          minWidth: context.w(110),
          alignment: Alignment.centerRight
        ),
      ],
      rows: [
        for (final u in users)
          [
            Text(
              u.email,
              style: AppTextStyles.body(context).copyWith(
                fontWeight: FontWeight.w600
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis
            ),
            Text(u.roleLabel, style: AppTextStyles.body(context)),
            Text(
              u.disabled ? 'Disabled' : 'Active',
              style: AppTextStyles.body(context).copyWith(
                color: u.disabled ? colors.textMuted : AppColors.success,
                fontWeight: FontWeight.w600
              )
            ),
            _actions(u),
          ],
      ],
      onRowTap: (index) => _openAdd(existing: users[index])
    );
  }

  Widget _actions(ManagedUserModel user) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        RdxTableActionButton(
          icon: Icons.edit_outlined,
          tooltip: 'Edit role',
          onPressed: user.disabled ? null : () => _openAdd(existing: user)
        ),
        RdxTableActionButton(
          icon: Icons.person_off_outlined,
          tooltip: 'Disable',
          onPressed: user.disabled ? null : () => _disableUser(user)
        ),
      ]
    );
  }
}
