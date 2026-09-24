import '../../dtos/ai_fact_dto.dart';
import '../../dtos/quote_dto.dart';
import '../../dtos/scene_quote_dto.dart';
import '../../services/drift_collection_service.dart';

enum MessageKind { quote, scene, fact }

/// Render model for every bubble in the app. A quote is a message from its
/// author, a scene from its character, a fact from "Quotely". The original
/// DTO rides along so actions (save, share, report) work on the real object.
class ThreadMessage {
  final MessageKind kind;
  final String text;
  final String sender;
  final String? senderImageUrl;

  /// Author slug (quotes only) for Author detail.
  final String? authorSlug;

  final QuoteDto? quote;
  final SceneQuoteDto? scene;
  final AiFactDto? fact;

  /// When this was delivered ("of the day" archives, Today groups).
  final DateTime? date;

  const ThreadMessage._({
    required this.kind,
    required this.text,
    required this.sender,
    this.senderImageUrl,
    this.authorSlug,
    this.quote,
    this.scene,
    this.fact,
    this.date,
  });

  factory ThreadMessage.fromQuote(QuoteDto quote, {DateTime? date}) =>
      ThreadMessage._(
        kind: MessageKind.quote,
        text: quote.content,
        sender: quote.author,
        authorSlug: quote.authorSlug,
        quote: quote,
        date: date,
      );

  factory ThreadMessage.fromScene(SceneQuoteDto scene, {DateTime? date}) =>
      ThreadMessage._(
        kind: MessageKind.scene,
        text: scene.content,
        sender: scene.characterName,
        senderImageUrl: scene.characterAvatarUrl,
        scene: scene,
        date: date,
      );

  factory ThreadMessage.fromFact(AiFactDto fact, {DateTime? date}) =>
      ThreadMessage._(
        kind: MessageKind.fact,
        text: fact.content,
        sender: 'Quotely',
        fact: fact,
        date: date,
      );

  /// The item's own id (fact ids are ints, stringified).
  String get itemId => switch (kind) {
    MessageKind.quote => quote!.id,
    MessageKind.scene => scene!.id,
    MessageKind.fact => fact!.id.toString(),
  };

  /// Unique across kinds, for widget keys and highlight targets.
  String get key => '${kind.name}:$itemId';

  CollectionItemType get collectionType => switch (kind) {
    MessageKind.quote => CollectionItemType.quote,
    MessageKind.scene => CollectionItemType.scene,
    MessageKind.fact => CollectionItemType.fact,
  };

  /// "Who · Source" for the Saved cards and archive rows.
  String get sourceLine => switch (kind) {
    MessageKind.quote =>
      quote!.tags.isEmpty
          ? sender
          : '$sender · ${_titleCase(quote!.tags.first)}',
    MessageKind.scene => '$sender · ${scene!.titleName}',
    MessageKind.fact => 'Quotely · ${fact!.aiFactCategory}',
  };

  static String _titleCase(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
