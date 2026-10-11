import 'package:flutter/material.dart';
import '../data/app_data_service.dart';
import '../theme/app_theme.dart';
import 'app_card.dart';

class MemberCard extends StatelessWidget {
  final Member member;
  final VoidCallback? onTap;
  const MemberCard({super.key, required this.member, this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      color: Colors.white,
      borderColor: AppColors.border,
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.lightGreen,
            child: Icon(member.isChild ? Icons.child_care : Icons.person,
                color: AppColors.darkGreen),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
                Text(
                    '${member.relation} • ${member.isConnected ? (member.hasLocation ? 'Location available' : 'Connected') : 'Not connected to an account'}',
                    style: const TextStyle(
                        color: AppColors.muted, fontSize: 12)),
              ],
            ),
          ),
          Icon(member.hasLocation ? Icons.location_on : Icons.location_off,
              color: member.hasLocation ? AppColors.green : AppColors.muted),
        ],
      ),
    );
  }
}
