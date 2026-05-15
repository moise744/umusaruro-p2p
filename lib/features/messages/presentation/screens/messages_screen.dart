import 'package:flutter/material.dart';
import 'package:umusaruro_p2p/core/theme/app_colors.dart';
import 'package:umusaruro_p2p/core/theme/app_text_styles.dart';

class _MockConversation {
  final String name;
  final String lastMessage;
  final String time;
  final int unread;
  final IconData icon;
  const _MockConversation({
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.unread,
    required this.icon,
  });
}

final _conversations = [
  const _MockConversation(
    name: 'Kagabo Jean',
    lastMessage: 'The harvest report has been submitted.',
    time: '10:32',
    unread: 2,
    icon: Icons.person_outline,
  ),
  const _MockConversation(
    name: 'Review Team',
    lastMessage: 'Your profile is under review.',
    time: 'Yesterday',
    unread: 0,
    icon: Icons.apartment_outlined,
  ),
  const _MockConversation(
    name: 'Uwimana Alice',
    lastMessage: 'Thank you for your investment!',
    time: 'Mon',
    unread: 0,
    icon: Icons.person_outline,
  ),
  const _MockConversation(
    name: 'Support',
    lastMessage: 'How can we help you today?',
    time: 'Mar 28',
    unread: 0,
    icon: Icons.support_agent_outlined,
  ),
];

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      backgroundColor: AppColors.background,
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _conversations.length,
        itemBuilder: (context, index) {
          final c = _conversations[index];
          return Container(
            color: AppColors.surface,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                radius: 26,
                child: Icon(c.icon, color: AppColors.primary, size: 26),
              ),
              title: Text(c.name, style: AppTextStyles.labelLarge),
              subtitle: Text(
                c.lastMessage,
                style: AppTextStyles.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(c.time, style: AppTextStyles.caption),
                  if (c.unread > 0) ...[
                    const SizedBox(height: 4),
                    Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${c.unread}',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
