/// Quotely is family-friendly and only shows finished prose. The backend
/// rejects profanity and broken AI output when it generates content, never
/// picks it for a daily slot, and sweeps it out weekly; this client-side check
/// keeps anything already cached on a device (or served before a sweep) off
/// screen. Mirrors the backend's ProfanityFilter and ContentQuality.
///
/// Whole words only, so "class", "assassin", "Scunthorpe" and "cocktail"
/// are fine. Masked forms like "f*ck" and "sh*t" are caught.
final RegExp _profanity = RegExp(
  r"\b("
  r"f+u+c+k+\w*|f\*+c?k\w*|f\*+\w*k\w*|motherf\w*|"
  r"sh[i*]+t\w*|bullsh[i*]t\w*|"
  r"bitch\w*|bastard\w*|"
  r"ass|asses|asshole\w*|arse|arsehole\w*|jackass\w*|dumbass\w*|"
  r"god-?damn\w*|damn\w*|"
  r"dick|dicks|dickhead\w*|"
  r"piss\w*|crap|crappy|cunt\w*|wanker\w*|bollocks|slut\w*|whore\w*"
  r")\b|\bsh[*@#]{2,}|\bf[*@#]{3}",
  caseSensitive: false,
);

// Broken AI output: code fences, JSON or markdown; a token glued to itself
// ("FactFactFact"); invisible or direction-control characters; scripts that
// never belong in the app's English content.
final RegExp _markup = RegExp(
  r'```|[{}]|"\s*(?:fact|quote|content|text|line)\s*"\s*:|\*\*',
  caseSensitive: false,
);
final RegExp _glued = RegExp(r'([a-zA-Z]{2,}){2,}');
final RegExp _control = RegExp(
  '[\u200B-\u200F\u202A-\u202E\u2060-\u2064\uFEFF\u0000-\u0008]',
);
final RegExp _foreign = RegExp(
  '[\u0400-\u04FF\u0590-\u06FF\u0900-\u097F\u0E00-\u0E7F'
  '\u3040-\u30FF\u4E00-\u9FFF\uAC00-\uD7AF]',
);

/// Longest text the app will show (a runaway answer is thousands of chars).
const kMaxContentLength = 600;

/// Finished prose: not empty, not runaway, no markup or garbage.
bool isWellFormed(String text) {
  final t = text.trim();
  return t.isNotEmpty &&
      t.length <= kMaxContentLength &&
      !_markup.hasMatch(t) &&
      !_glued.hasMatch(t) &&
      !_control.hasMatch(t) &&
      !_foreign.hasMatch(t);
}

bool isProfane(String text) => _profanity.hasMatch(text);

/// Safe to show: no profanity and well formed.
bool isClean(String text) => !_profanity.hasMatch(text) && isWellFormed(text);
