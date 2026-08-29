import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sections = <_SettingsGroup>[
      _SettingsGroup('ACCOUNT', [
        _SettingsEntry('👤', 'Edit Profile', '/settings/edit-profile'),
        _SettingsEntry('📍', 'Manage Addresses', '/settings/addresses'),
        _SettingsEntry('🔒', 'Change Password', '/settings/change-password'),
      ]),
      _SettingsGroup('PREFERENCES', [
        _SettingsEntry('🔔', 'Notifications', '/settings/notifications'),
      ]),
      _SettingsGroup('SUPPORT', [
        _SettingsEntry('ℹ️', 'About & Help', '/settings/about'),
      ]),
      _SettingsGroup('DANGER ZONE', [
        _SettingsEntry('🗑️', 'Delete Account', '/settings/delete-account',
            danger: true),
      ]),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: sections.length,
          itemBuilder: (context, i) => _buildGroup(context, sections[i]),
        ),
      ),
    );
  }

  Widget _buildGroup(BuildContext context, _SettingsGroup group) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              group.title,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
                color: AppColors.textTertiary,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  blurRadius: 5,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              children: List.generate(group.entries.length, (i) {
                final entry = group.entries[i];
                final isLast = i == group.entries.length - 1;
                return InkWell(
                  onTap: () => context.push(entry.route),
                  borderRadius: BorderRadius.vertical(
                    top: i == 0 ? const Radius.circular(16) : Radius.zero,
                    bottom: isLast ? const Radius.circular(16) : Radius.zero,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 13),
                    decoration: BoxDecoration(
                      border: isLast
                          ? null
                          : const Border(
                        bottom:
                        BorderSide(color: AppColors.divider, width: 1),
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 22,
                          child: Text(entry.icon,
                              style: const TextStyle(fontSize: 16)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            entry.label,
                            style: TextStyle(
                              fontSize: 13,
                              color: entry.danger
                                  ? AppColors.errorText
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Icon(Icons.chevron_right,
                            size: 18,
                            color: entry.danger
                                ? AppColors.errorText.withValues(alpha: 0.6)
                                : AppColors.neutral200),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsGroup {
  final String title;
  final List<_SettingsEntry> entries;
  const _SettingsGroup(this.title, this.entries);
}

class _SettingsEntry {
  final String icon;
  final String label;
  final String route;
  final bool danger;
  const _SettingsEntry(this.icon, this.label, this.route, {this.danger = false});
}
