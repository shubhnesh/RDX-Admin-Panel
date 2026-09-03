import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../widgets/rdx_header.dart';
import '../../widgets/custom_text_field.dart';

/// Contact Technical Support — matches the provided design.
class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedCategory = 'Order Issues';
  bool _sending = false;

  static const _categories = [
    ('Order Issues', Icons.receipt_long_outlined),
    ('Payment Failure', Icons.payment_outlined),
    ('App Errors', Icons.bug_report_outlined),
    ('Store Closure', Icons.storefront_outlined),
  ];

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_subjectController.text.trim().isEmpty ||
        _messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill subject and message')),
      );
      return;
    }
    setState(() => _sending = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => _sending = false);
    _subjectController.clear();
    _messageController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ticket submitted successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isNarrow = !Responsive.isDesktop(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: const RdxHeader(title: 'Contact Technical Support'),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final content = isNarrow
              ? ListView(
                  padding: Responsive.pagePadding(context, top: 20),
                  children: [
                    _buildIntro(colors),
                    const SizedBox(height: 20),
                    _buildCategorySection(colors),
                    const SizedBox(height: 20),
                    _buildFormSection(colors),
                    const SizedBox(height: 24),
                    _buildDirectChannels(colors),
                  ],
                )
              : Padding(
                  padding: Responsive.pagePadding(context),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildIntro(colors),
                              const SizedBox(height: 20),
                              _buildCategorySection(colors),
                              const SizedBox(height: 20),
                              _buildFormSection(colors),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      SizedBox(
                        width: 300,
                        child: _buildDirectChannels(colors),
                      ),
                    ],
                  ),
                );

          return content;
        },
      ),
    );
  }

  Widget _buildIntro(AppColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Questions? Our Support team is here. Create tickets or reply to existing problems.',
          style:
              TextStyle(color: colors.textSecondary, fontSize: 14, height: 1.4),
        ),
      ],
    );
  }

  Widget _buildCategorySection(AppColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Issue Category',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _categories.map((c) {
            final selected = _selectedCategory == c.$1;
            return Material(
              color: selected
                  ? AppColors.primary.withOpacity(0.15)
                  : colors.surface,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: () => setState(() => _selectedCategory = c.$1),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected ? AppColors.primary : colors.border,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        c.$2,
                        size: 18,
                        color:
                            selected ? AppColors.primary : colors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        c.$1,
                        style: TextStyle(
                          color: selected
                              ? colors.textPrimary
                              : colors.textSecondary,
                          fontSize: 13,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFormSection(AppColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomTextField(
            controller: _subjectController,
            label: 'Subject',
            hint: 'Brief summary of the issue',
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _messageController,
            label: 'Describe the issue',
            hint: 'Provide as much detail as possible…',
            maxLines: 6,
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: BoxDecoration(
              color: colors.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: colors.border,
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              children: [
                Icon(Icons.cloud_upload_outlined,
                    size: 32, color: colors.textMuted),
                const SizedBox(height: 8),
                Text(
                  'Drag & drop screenshots or logs',
                  style: TextStyle(color: colors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  'PNG, JPG, PDF up to 10 MB',
                  style: TextStyle(color: colors.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _sending ? null : _submit,
              icon: _sending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded, size: 18),
              label: Text(_sending ? 'Submitting…' : 'Submit Ticket'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectChannels(AppColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Direct Channels',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _channelRow(
            colors,
            icon: Icons.email_outlined,
            title: 'Email Support',
            subtitle: 'support@rdxadmin.com',
          ),
          const SizedBox(height: 14),
          _channelRow(
            colors,
            icon: Icons.phone_outlined,
            title: 'Phone Hotline',
            subtitle: '+91 1800-123-4567',
          ),
          const SizedBox(height: 14),
          _channelRow(
            colors,
            icon: Icons.chat_bubble_outline,
            title: 'Live Chat',
            subtitle: 'Available 9 AM – 9 PM IST',
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.schedule, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Average Response',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Under 2 hours on business days',
                  style: TextStyle(color: colors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _channelRow(
    AppColorScheme colors, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colors.surfaceVariant,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(color: colors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
