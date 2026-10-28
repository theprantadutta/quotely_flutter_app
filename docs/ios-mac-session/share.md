# Share cards: iOS checks

Sharing a quote, scene line or fact opens a small sheet with "Share as
image" (first) and "Share as text". "Share as image" renders a
1080x1350 PNG card offscreen and hands it to the system share sheet with
the share text alongside (`share_plus`, `XFile.fromData`).

## Info.plist

`ios/Runner/Info.plist` now has `NSPhotoLibraryAddUsageDescription`
("Quotely saves the quote cards you share to your photos."). The system
share sheet's "Save Image" action writes to Photos and crashes the app
without this key. No other key is needed: the app never reads the photo
library itself.

## On-device checks

Run on a real iPhone and a real iPad (the iPad popover can't be checked
on an iPhone).

1. **iPad popover anchor.** On iPad, share from:
   - the Today rail's Share button;
   - a bubble's Share pill;
   - the long-press menu ("Share as image" and "Share as text");
   - the Facts screen's True-or-False answer card.

   Each time the popover must open pointing at the tapped control (or
   the long-pressed item), not the screen corner, and must not crash.
   Try portrait and landscape.
2. **Image plus text in WhatsApp.** "Share as image" → WhatsApp → a
   chat. The card arrives as a photo with the share text as its caption
   (or as a following message). Check a quote, a scene line and a fact.
3. **Image plus text in Messages.** Same in Messages: the card and the
   text both arrive.
4. **Save Image.** "Share as image" → "Save Image". On first use iOS
   asks for permission with the string above; after "Allow", the card
   appears in Photos at 1080x1350. Saving again doesn't prompt.
5. **Loading state.** On a slow network (Network Link Conditioner), the
   "Share as image" row shows a spinner and ignores taps until the
   system share sheet opens. Dismissing the Quotely sheet while it spins
   cancels the share.
6. **Theme and background.** The card follows light/dark and
   Appearance → Background: Poster (the scene's or the day's poster,
   glow if none), Glow, Plain.
