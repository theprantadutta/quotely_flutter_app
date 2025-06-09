import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quotely_flutter_app/components/shared/circle_avatar_with_fallback.dart';
import 'package:quotely_flutter_app/dtos/author_dto.dart';
import 'package:skeletonizer/skeletonizer.dart';

class AuthorDetailAuthorBio extends StatelessWidget {
  final AuthorDto author;

  const AuthorDetailAuthorBio({super.key, required this.author});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkTheme = theme.brightness == Brightness.dark;
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Container(
      width: MediaQuery.sizeOf(context).width * 0.92,
      height: MediaQuery.sizeOf(context).height * 0.8,
      constraints: BoxConstraints(
        maxHeight: screenHeight * 0.8,
        minHeight: screenHeight * 0.5,
      ),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkTheme ? Colors.grey[900]!.withOpacity(0.6) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: theme.primaryColor.withOpacity(0.1),
          width: 1.5,
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar with decorative ring
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.primaryColor.withOpacity(0.3),
                  width: 3,
                ),
              ),
              child: CircleAvatarWithFallback(
                name: author.name,
                radius: 60,
                imageUrl: author.imageUrl,
              ),
            ),

            const SizedBox(height: 20),

            // Name with subtle divider
            Column(
              children: [
                Text(
                  author.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 80,
                  height: 2,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    gradient: LinearGradient(
                      colors: [
                        theme.primaryColor.withOpacity(0.2),
                        theme.primaryColor,
                        theme.primaryColor.withOpacity(0.2),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Description in emphasized style
            if (author.description.isNotEmpty) ...[
              Text(
                author.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: theme.primaryColor,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Bio in readable format
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                author.bio,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  fontWeight: FontWeight.w400,
                  color: isDarkTheme ? Colors.grey[300] : Colors.grey[700],
                ),
              ),
            ),

            // Metadata at bottom
            const SizedBox(height: 24),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 16,
              runSpacing: 8,
              children: [
                if (author.link.isNotEmpty)
                  _buildMetaChip(
                    context,
                    Icons.calendar_today,
                    'Created At ${DateFormat.yMMMd().format(author.dateAdded)}',
                  ),
                _buildMetaChip(
                  context,
                  Icons.edit,
                  'Updated At ${DateFormat.yMMMd().format(author.dateModified)}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaChip(BuildContext context, IconData icon, String text,
      {VoidCallback? onTap}) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: theme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: theme.primaryColor,
            ),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: theme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AuthorDetailAuthorBioSkeletor extends StatelessWidget {
  const AuthorDetailAuthorBioSkeletor({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkTheme = theme.brightness == Brightness.dark;
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Skeletonizer(
      child: Container(
        width: MediaQuery.sizeOf(context).width * 0.92,
        height: MediaQuery.sizeOf(context).height * 0.8,
        constraints: BoxConstraints(
          maxHeight: screenHeight * 0.8,
          minHeight: screenHeight * 0.5,
        ),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color:
              isDarkTheme ? Colors.grey[900]!.withOpacity(0.6) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(
            color: theme.primaryColor.withOpacity(0.1),
            width: 1.5,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar with decorative ring
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.primaryColor.withOpacity(0.3),
                    width: 3,
                  ),
                ),
                child: CircleAvatarWithFallback(
                  name: 'Abraham Lincoln',
                  radius: 60,
                  imageUrl: null,
                ),
              ),

              const SizedBox(height: 20),

              // Name with subtle divider
              Column(
                children: [
                  Text(
                    'Abraham Lincoln',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 80,
                    height: 2,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      gradient: LinearGradient(
                        colors: [
                          theme.primaryColor.withOpacity(0.2),
                          theme.primaryColor,
                          theme.primaryColor.withOpacity(0.2),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Description in emphasized style
              ...[
                Text(
                  'American President',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: theme.primaryColor,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Bio in readable format
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'American politician who served as the 16th president of the United States from 1861 to 1865.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    fontWeight: FontWeight.w400,
                    color: isDarkTheme ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
              ),

              // Metadata at bottom
              const SizedBox(height: 24),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 16,
                runSpacing: 8,
                children: [
                  _buildMetaChip(
                    context,
                    Icons.calendar_today,
                    'Since ${DateFormat.yMMMd().format(DateTime.now())}',
                  ),
                  _buildMetaChip(
                    context,
                    Icons.edit,
                    'Updated ${DateFormat.yMMMd().format(DateTime.now())}',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetaChip(BuildContext context, IconData icon, String text,
      {VoidCallback? onTap}) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: theme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: theme.primaryColor,
            ),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: theme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
