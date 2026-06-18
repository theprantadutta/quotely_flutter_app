import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quotely_flutter_app/components/author_detail_screen/author_detail_author_bio.dart';
import 'package:quotely_flutter_app/components/author_detail_screen/author_detail_author_quotes.dart';

import '../components/layouts/main_layout.dart';
import '../components/shared/something_went_wrong.dart';
import '../riverpods/get_author_detail_provider.dart';

class AuthorDetailScreen extends ConsumerWidget {
  static const kRouteName = '/author-detail';

  final String authorSlug;

  const AuthorDetailScreen({super.key, required this.authorSlug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authorProvider = ref.watch(fetchAuthorDetailProvider(authorSlug));
    final title = authorProvider.asData?.value?.name ?? 'Author';

    return MainLayout(
      title: title,
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          child: authorProvider.when(
            data: (author) {
              if (author == null) return _buildError(context);
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
            loading: () => const AuthorDetailAuthorBioSkeletor(),
          ),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.8,
      child: const Center(
        child: SomethingWentWrong(title: 'Failed to get Author Detail'),
      ),
    );
  }
}
