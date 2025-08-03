import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    // For now, returning a simple circle avatar.
    // In the future, this can be extended to fetch and display a user's profile picture.
    return const CircleAvatar(
      child: Icon(Icons.person),
    );
  }
}
