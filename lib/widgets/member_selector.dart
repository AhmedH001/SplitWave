import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'member_avatar.dart';

class MemberSelector extends StatelessWidget {
  final Map<String, String> memberNames; // uid → name
  final Map<String, String>? memberEmojis; // uid → emoji
  final List<String> selectedIds;
  final ValueChanged<List<String>> onChanged;

  const MemberSelector({
    super.key,
    required this.memberNames,
    this.memberEmojis,
    required this.selectedIds,
    required this.onChanged,
  });

  void _toggleMember(String uid) {
    final updated = List<String>.from(selectedIds);
    if (updated.contains(uid)) {
      // Don't allow deselecting all — at least 1 must remain.
      if (updated.length > 1) {
        updated.remove(uid);
      }
    } else {
      updated.add(uid);
    }
    onChanged(updated);
  }

  void _selectAll() {
    onChanged(memberNames.keys.toList());
  }

  @override
  Widget build(BuildContext context) {
    final allSelected = selectedIds.length == memberNames.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            const Text(
              'Split with',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: allSelected ? null : _selectAll,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: allSelected
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : AppColors.glassFill,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: allSelected
                        ? AppColors.primary.withValues(alpha: 0.3)
                        : AppColors.glassBorder,
                  ),
                ),
                child: Text(
                  allSelected ? '✓ All selected' : 'Select all',
                  style: TextStyle(
                    color: allSelected ? AppColors.primary : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Member chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: memberNames.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: MemberAvatar(
                  name: entry.value,
                  emoji: memberEmojis?[entry.key] ?? '🏖️',
                  size: 48,
                  showName: true,
                  isSelected: selectedIds.contains(entry.key),
                  onTap: () => _toggleMember(entry.key),
                ),
              );
            }).toList(),
          ),
        ),

        if (!allSelected) ...[
          const SizedBox(height: 8),
          Text(
            '${selectedIds.length} of ${memberNames.length} selected',
            style: const TextStyle(
              color: AppColors.textTertiary,
              fontSize: 11,
            ),
          ),
        ],
      ],
    );
  }
}
