import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quotely_flutter_app/components/author_detail_screen/author_detail_author_bio.dart';
import 'package:quotely_flutter_app/components/author_detail_screen/author_detail_author_quotes.dart';

import '../components/layouts/main_layout.dart';
import '../components/shared/something_went_wrong.dart';
import '../constants/responsive.dart';
import '../riverpods/get_author_detail_provider.dart';

class AuthorDetailScreen extends ConsumerWidget {
  static const kRouteName = '/author-detail';

  final String authorSlug;

  const AuthorDetailScreen({super.key, required this.authorSlug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authorProvider = ref.watch(fetchAuthorDetailProvider(authorSlug));
    final title = authorProvider.asData?.value?.name ?? 'Author';
    // Tablet landscape: bio on the left, quote carousel on the right, both
    // filling the viewport. Everything else keeps the scrolling column.
    final splitPanes = isTabletLandscape(context);

    return MainLayout(
      title: title,
      scrollable: !splitPanes,
      maxWidth: splitPanes ? kMaxShellWidth : kMaxContentWidth,
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          child: authorProvider.when(
            data: (author) {
              if (author == null) return _buildError(context);
              if (splitPanes) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            AuthorProfileHeader(author: author),
                            if (author.bio.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              AuthorAboutCard(author: author),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 3,
                      child: AuthorDetailAuthorQuotes(
                        author: author,
                        expand: true,
                      ),
                    ),
                  ],
                );
              }
              return Column(
                children: [
                  AuthorProfileHeader(author: author),
                  if (author.bio.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    AuthorAboutCard(author: author),
                  ],
                  const SizedBox(height: 22),
                  AuthorDetailAuthorQuotes(author: author),
                ],
              );
            },
            error: (err, stack) => _buildError(context),
            // In the non-scrolling split layout the skeleton needs its own
            // scroll view so it can't overflow the bounded viewport.
            loading: () => splitPanes
                ? const SingleChildScrollView(
                    child: AuthorDetailAuthorBioSkeletor(),
                  )
                : const AuthorDetailAuthorBioSkeletor(),
          ),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    return SizedBox(
      height: cappedHeight(context, 0.8, max: 600),
      child: const Center(
        child: SomethingWentWrong(title: 'Failed to get Author Detail'),
      ),
    );
  }
}
