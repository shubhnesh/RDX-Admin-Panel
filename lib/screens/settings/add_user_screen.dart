import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rdx_admin/core/theme/app_colors.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import 'package:rdx_admin/core/utils/responsive_size.dart';
import 'package:rdx_admin/models/managed_user_model.dart';
import 'package:rdx_admin/providers/auth_provider.dart';
import 'package:rdx_admin/providers/user_management_provider.dart';
import 'package:rdx_admin/widgets/buttons/rdx_action_button.dart';
import 'package:rdx_admin/widgets/dialogs/rdx_delete_dialog.dart';
import 'package:rdx_admin/widgets/dialogs/rdx_notice_dialog.dart';
import 'package:rdx_admin/widgets/reusable_widgets/rdx_dropdown.dart';
import 'package:rdx_admin/widgets/reusable_widgets/rdx_header.dart';
import 'package:rdx_admin/widgets/reusable_widgets/rdx_text_field.dart';

/// Create a user or change their Auth role claim.
///
/// Role is applied only by Cloud Functions (`createManagedUser` / `setUserRole`).
/// This screen never talks to the Admin SDK and never writes custom claims.
class AddUserScreen extends ConsumerStatefulWidget {
  final ManagedUserModel? existing;

  const AddUserScreen({super.key, this.existing});

  @override
  ConsumerState<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends ConsumerState<AddUserScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  /// Claim value only: "admin" | "staff" (staff = worker role, not a group name).
  String? _role;
  bool _saving = false;
  bool _obscurePassword = true;

  bool get isEdit => widget.existing != null && widget.existing!.uid.isNotEmpty;

  static const _roleValues = ['admin', 'staff'];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _emailCtrl.text = e.email;
      _nameCtrl.text = e.displayName ?? '';
      _role = e.role == 'admin' || e.role == 'staff' ? e.role : 'staff';
    } else {
      _role = 'staff';
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  String _roleLabel(String value) {
    switch (value) {
      case 'admin':
        return 'Admin';
      case 'staff':
        return 'Staff';
      default:
        return value;
    }
  }

  Future<void> _showNotice(String message) async {
    if (!mounted) return;
    await RdxNoticeDialog.show(context, message: message);
  }

  Future<void> _save() async {
    final auth = ref.read(authProvider);
    if (!auth.permissions.canManageUsers) {
      await _showNotice('Admin access required.');
      return;
    }

    final email = _emailCtrl.text.trim().toLowerCase();
    final password = _passwordCtrl.text;
    final role = (_role ?? '').trim().toLowerCase();
    final displayName = _nameCtrl.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      await _showNotice('Enter a valid email address.');
      return;
    }
    if (!isEdit) {
      if (password.length < 6) {
        await _showNotice('Password must be at least 6 characters.');
        return;
      }
    }
    if (role != 'admin' && role != 'staff') {
      await _showNotice('Select a role.');
      return;
    }

    if (isEdit && auth.user?.uid == widget.existing!.uid && role != 'admin') {
      await _showNotice('You cannot remove your own admin role.');
      return;
    }

    setState(() => _saving = true);
    try {
      final provider = ref.read(userManagementProvider);
      if (isEdit) {
        await provider.updateUser(
          uid: widget.existing!.uid,
          email: email,
          displayName: displayName,
          role: role,
        );
      } else {
        await provider.createUser(
          email: email,
          password: password,
          role: role,
          displayName: displayName.isEmpty ? null : displayName,
        );
      }
      if (!mounted) return;
      if (isEdit) {
        await _showNotice('User details saved.');
      } else {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) return;
      await _showNotice(
        isEdit ? 'Failed to update user details.' : 'Failed to create user. $e',
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteUser() async {
    final existing = widget.existing;
    if (existing == null) return;

    final auth = ref.read(authProvider);
    if (auth.user?.uid == existing.uid) {
      await _showNotice('You cannot disable your own account.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => RdxDeleteDialog(
        title: 'Delete User',
        itemName: existing.email,
        deleteButtonLabel: 'Disable user',
        warningTitle: 'SIGN-IN WILL BE DISABLED',
        warningMessage:
            'This disables the account. Existing account data and history are retained.',
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _saving = true);
    try {
      await ref.read(userManagementProvider).disableUser(uid: existing.uid);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      await _showNotice('Unable to disable this user. $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final auth = ref.watch(authProvider);

    if (!auth.permissions.canManageUsers) {
      return Scaffold(
        backgroundColor: colors.background,
        body: Column(
          children: [
            RdxHeader(
              title: isEdit ? 'User Details' : 'Add User',
              showBackButton: true,
            ),
            const Expanded(
              child: Center(child: Text('Admin access required.')),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RdxHeader(
            title: isEdit ? 'Edit User' : 'Add User',
            subtitle: isEdit
                ? 'Update this account’s details and access role.'
                : 'Create an Admin or Staff account. Staff is the worker role.',
            showBackButton: true,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: Responsive.pagePadding(
                context,
                top: context.h(16),
                bottom: context.h(32),
              ),
              child: Column(
                children: [
                  _SectionCard(
                    title: 'Account',
                    icon: Icons.person_outline_rounded,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        RdxTextField(
                          controller: _emailCtrl,
                          maxLength: 50,
                          label: 'Login ID (email) *',
                          hint: 'staff@restaurant.com',
                          keyboardType: TextInputType.emailAddress,
                        ),
                        SizedBox(height: context.h(16)),
                        RdxTextField(
                          controller: _nameCtrl,
                          maxLength: 40,
                          label: 'Display name',
                          hint: 'Optional',
                        ),
                        if (!isEdit) ...[
                          SizedBox(height: context.h(16)),
                          RdxTextField(
                            controller: _passwordCtrl,
                            maxLength: 50,
                            label: 'Initial Firebase password *',
                            hint: 'Min 6 characters',
                            obscureText: _obscurePassword,
                            suffixIcon: IconButton(
                              tooltip: _obscurePassword
                                  ? 'Show password'
                                  : 'Hide password',
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: context.w(18),
                              ),
                            ),
                          ),
                          SizedBox(height: context.h(6)),
                          Text(
                            'This creates the Firebase Authentication login. '
                            'Share the email and password securely; the user '
                            'can reset the password from the login screen.',
                            style: AppTextStyles.bodyTertiary(context)
                                .copyWith(color: colors.textMuted),
                          ),
                        ],
                        SizedBox(height: context.h(16)),
                        RdxDropdown<String>(
                          label: 'Role *',
                          value: _role,
                          items: _roleValues,
                          labelBuilder: _roleLabel,
                          hint: 'Select role',
                          onChanged: (v) {
                            if (v != null) setState(() => _role = v);
                          },
                        ),
                        SizedBox(height: context.h(6)),
                        Text(
                          'Admin: full access, including user management.\n'
                          'Staff: dashboard and orders, with read-only inventory and settings.',
                          style: AppTextStyles.bodyTertiary(context)
                              .copyWith(color: colors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  if (isEdit) ...[
                    SizedBox(height: context.h(16)),
                    _UserActionsSection(
                      enabled: !_saving,
                      saving: _saving,
                      onSave: _save,
                      onDelete: _deleteUser,
                    ),
                  ] else ...[
                    SizedBox(height: context.h(16)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        RdxActionButton.discard(
                          label: 'Discard',
                          minWidth: context.w(140),
                          onPressed: _saving
                              ? null
                              : () => Navigator.of(context).pop(),
                        ),
                        SizedBox(width: context.w(10)),
                        RdxActionButton.save(
                          label: 'Create user',
                          minWidth: context.w(140),
                          onPressed: _save,
                          isLoading: _saving,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserActionsSection extends StatelessWidget {
  final bool enabled;
  final bool saving;
  final VoidCallback onSave;
  final VoidCallback onDelete;

  const _UserActionsSection({
    required this.enabled,
    required this.saving,
    required this.onSave,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return _SectionCard(
      title: 'Actions',
      icon: Icons.tune_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Save account changes or disable sign-in access. Account history is retained.',
            style: AppTextStyles.bodySecondary(context)
                .copyWith(color: colors.textSecondary),
          ),
          SizedBox(height: context.h(14)),
          Wrap(
            spacing: context.w(10),
            runSpacing: context.h(10),
            children: [
              RdxActionButton.save(
                label: 'Save',
                minWidth: context.w(140),
                onPressed: enabled ? onSave : null,
                isLoading: saving,
              ),
              RdxActionButton.discard(
                label: 'Delete',
                minWidth: context.w(140),
                onPressed: enabled ? onDelete : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      padding: EdgeInsets.all(context.h(20)),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(context.h(12)),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: context.h(18), color: AppColors.primary),
              SizedBox(width: context.w(8)),
              Text(title, style: AppTextStyles.section(context)),
            ],
          ),
          SizedBox(height: context.h(16)),
          child,
        ],
      ),
    );
  }
}
