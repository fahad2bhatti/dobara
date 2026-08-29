import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';

const _kSupportEmail = 'support@dobara.app';

class AboutHelpScreen extends StatelessWidget {
  const AboutHelpScreen({super.key});

  static const _faqs = <(String, String)>[
    (
    'How do I track my order?',
    'Go to Profile → My Orders. Each order shows its current delivery status and updates as it moves.',
    ),
    (
    'Can I return an item?',
    'Reach out to support within 3 days of delivery with your order number and we\'ll sort it out.',
    ),
    (
    'How do reviews work?',
    'Once you\'re signed in, you can leave one review per item you\'ve bought — you can edit it any time from the same listing.',
    ),
    (
    'How do I delete my account?',
    'Go to Settings → Delete Account. This is permanent and can\'t be undone.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('About & Help')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _sectionLabel('FREQUENTLY ASKED'),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: _faqs
                    .map((f) => ExpansionTile(
                  title: Text(f.$1,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  childrenPadding:
                  const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  expandedCrossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(f.$2,
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textBody,
                            height: 1.5)),
                  ],
                ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 20),
            _sectionLabel('SUPPORT'),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                leading: const Text('✉️', style: TextStyle(fontSize: 16)),
                title: const Text(_kSupportEmail,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                subtitle: const Text('Tap to copy',
                    style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                onTap: () {
                  Clipboard.setData(const ClipboardData(text: _kSupportEmail));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Email copied.')),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            _sectionLabel('LEGAL'),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  ListTile(
                    title: const Text('Terms of Service',
                        style: TextStyle(fontSize: 13)),
                    trailing: const Icon(Icons.chevron_right,
                        size: 18, color: AppColors.neutral200),
                    onTap: () => _showLegalSheet(
                      context,
                      'Terms of Service',
                      'Placeholder — replace with the real Terms of Service before this app is published.',
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.divider),
                  ListTile(
                    title: const Text('Privacy Policy',
                        style: TextStyle(fontSize: 13)),
                    trailing: const Icon(Icons.chevron_right,
                        size: 18, color: AppColors.neutral200),
                    onTap: () => _showLegalSheet(
                      context,
                      'Privacy Policy',
                      'Placeholder — replace with the real Privacy Policy before this app is published.',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text('Dobara v1.0.0',
                  style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textTertiary.withValues(alpha: 0.8))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(left: 4),
    child: Text(
      text,
      style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4,
          color: AppColors.textTertiary),
    ),
  );

  void _showLegalSheet(BuildContext context, String title, String body) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Text(body,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textBody, height: 1.5)),
          ],
        ),
      ),
    );
  }
}
