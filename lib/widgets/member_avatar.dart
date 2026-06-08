import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MemberAvatar extends StatelessWidget {
  final String name;
  final String emoji;
  final double size;
  final bool showName;
  final bool isSelected;
  final VoidCallback? onTap;

  const MemberAvatar({
    super.key,
    required this.name,
    this.emoji = '🏖️',
    this.size = 40,
    this.showName = false,
    this.isSelected = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isSelected ? 1.0 : 0.4,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isSelected ? AppColors.primaryGradient : null,
                color: isSelected ? null : AppColors.glassFill,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.5)
                      : AppColors.glassBorder,
                  width: 2,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  emoji,
                  style: TextStyle(fontSize: size * 0.45),
                ),
              ),
            ),
            if (showName) ...[
              const SizedBox(height: 4),
              SizedBox(
                width: size + 16,
                child: Text(
                  name,
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.textPrimary
                        : AppColors.textTertiary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A row of overlapping member avatars (for compact display).
class MemberAvatarStack extends StatelessWidget {
  final Map<String, String> memberNames;
  final Map<String, String>? memberEmojis;
  final double avatarSize;
  final int maxDisplay;

  const MemberAvatarStack({
    super.key,
    required this.memberNames,
    this.memberEmojis,
    this.avatarSize = 28,
    this.maxDisplay = 5,
  });

  @override
  Widget build(BuildContext context) {
    final entries = memberNames.entries.take(maxDisplay).toList();
    final overflow = memberNames.length - maxDisplay;

    return SizedBox(
      height: avatarSize,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...entries.asMap().entries.map((e) {
            final index = e.key;
            final entry = e.value;
            return Transform.translate(
              offset: Offset(-index * (avatarSize * 0.3), 0),
              child: Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.background, width: 2),
                  gradient: AppColors.primaryGradient,
                ),
                child: Center(
                  child: Text(
                    memberEmojis?[entry.key] ?? '🏖️',
                    style: TextStyle(fontSize: avatarSize * 0.4),
                  ),
                ),
              ),
            );
          }),
          if (overflow > 0)
            Transform.translate(
              offset: Offset(-entries.length * (avatarSize * 0.3), 0),
              child: Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.glassFill,
                  border: Border.all(color: AppColors.glassBorder, width: 2),
                ),
                child: Center(
                  child: Text(
                    '+$overflow',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: avatarSize * 0.32,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
