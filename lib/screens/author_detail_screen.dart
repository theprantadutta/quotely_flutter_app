import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quotely_flutter_app/components/author_detail_screen/author_detail_author_bio.dart';
import 'package:quotely_flutter_app/components/author_detail_screen/author_detail_author_quotes.dart';

import '../components/layouts/main_layout.dart';
import '../components/shared/something_went_wrong.dart';
import '../riverpods/get_author_detail_provider.dart';

class AuthorDetailScreen extends ConsumerStatefulWidget {
  static const kRouteName = '/author-detail';

  // final AuthorDetailScreenArguments authorDetailScreenArguments;
  final String authorSlug;

  const AuthorDetailScreen({
    super.key,
    required this.authorSlug,
    // required this.authorDetailScreenArguments,
  });

  @override
  ConsumerState<AuthorDetailScreen> createState() => _AuthorDetailScreenState();
}

class _AuthorDetailScreenState extends ConsumerState<AuthorDetailScreen> {
  bool isAuthorBioSelected = true;

  @override
  Widget build(BuildContext context) {
    // final author = widget.authorDetailScreenArguments.author;
    final authorProvider =
        ref.watch(fetchAuthorDetailProvider(widget.authorSlug));
    return MainLayout(
      title: 'Author Detail',
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 8,
            horizontal: 10,
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    SingleAuthorDetailButton(
                      title: 'Author Bio',
                      isSelected: isAuthorBioSelected,
                      onTap: () => setState(() => isAuthorBioSelected = true),
                    ),
                    SingleAuthorDetailButton(
                      title: 'Author Quotes',
                      isSelected: !isAuthorBioSelected,
                      onTap: () => setState(() => isAuthorBioSelected = false),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                authorProvider.when(
                  data: (author) {
                    if (author == null) _buildErrorWidget();
                    return isAuthorBioSelected
                        ? AuthorDetailAuthorBio(
                            author: author!,
                          )
                        : AuthorDetailAuthorQuotes(
                            author: author!,
                          );
                  },
                  error: (err, stack) => _buildErrorWidget(),
                  loading: () => AuthorDetailAuthorBioSkeletor(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.8,
      child: const Center(
        child: SomethingWentWrong(
          title: 'Failed to get Author Detail',
        ),
      ),
    );
  }
}

class SingleAuthorDetailButton extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const SingleAuthorDetailButton({
    super.key,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final kPrimaryColor = Theme.of(context).primaryColor;
    return Flexible(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 5),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? kPrimaryColor.withValues(alpha: 0.8)
                : kPrimaryColor.withValues(alpha: 0.2),
            border: Border.all(
              color: kPrimaryColor.withValues(alpha: 0.2),
            ),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : kPrimaryColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
