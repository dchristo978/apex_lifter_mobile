import 'package:flutter/material.dart';

/// Circle avatar that shows the user's photo when available, otherwise the
/// first letter of their name.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.name,
    this.avatarUrl,
    this.radius = 20,
  });

  final String name;
  final String? avatarUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: radius,
      foregroundImage:
          (avatarUrl != null && avatarUrl!.isNotEmpty) ? NetworkImage(avatarUrl!) : null,
      child: Text(
        initial,
        style: TextStyle(fontSize: radius * 0.8),
      ),
    );
  }
}
