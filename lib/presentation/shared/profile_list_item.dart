import 'package:flutter/material.dart';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';

class ProfileListItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final String?
  secondaryText; 
  final VoidCallback? onTap; 
  final bool showArrow; 

  const ProfileListItem({
    Key? key,
    required this.icon,
    required this.text,
    this.secondaryText,
    this.onTap,
    this.showArrow = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: Theme.of(context).textTheme.bodyMedium?.color
                      ?.withOpacity(0.7), 
                  size: 24,
                ),
                const SizedBox(width: 16),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color, 
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
            Row(
              children: [
                if (secondaryText != null && secondaryText!.isNotEmpty)
                  Text(
                    secondaryText!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.color, 
                      fontFamily: 'Poppins',
                    ),
                  ),
                if (showArrow) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Theme.of(
                      context,
                    ).textTheme.bodySmall?.color,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
