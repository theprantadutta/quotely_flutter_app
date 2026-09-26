/// Quotely is family-friendly. The backend rejects profanity when it
/// generates content and sweeps it out weekly; this client-side check keeps
/// anything already cached on a device (or served before a sweep) off screen.
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
  r")\b",
  caseSensitive: false,
);

bool isProfane(String text) => _profanity.hasMatch(text);

bool isClean(String text) => !_profanity.hasMatch(text);
