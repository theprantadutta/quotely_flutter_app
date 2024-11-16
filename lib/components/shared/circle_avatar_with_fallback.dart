import 'package:flutter/material.dart';

class CircleAvatarWithFallback extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double radius;

  const CircleAvatarWithFallback({
    super.key,
    this.imageUrl,
    required this.name,
    required this.radius,
  });

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    }
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials(name);

    return Hero(
      tag: name,
      child: CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey.shade200,
        backgroundImage: imageUrl != null && imageUrl!.isNotEmpty
            ? NetworkImage(imageUrl!)
            : null,
        foregroundColor: imageUrl == null || imageUrl!.isEmpty
            ? Theme.of(context).primaryColor
            : null,
        child: imageUrl == null || imageUrl!.isEmpty
            ? Text(
                initials,
                style: TextStyle(
                  fontSize: radius / 2, // Adjust font size relative to radius
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              )
            : null,
      ),
    );
  }
}
