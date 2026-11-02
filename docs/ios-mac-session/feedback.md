# Feedback, content flags and the review prompt on iOS

Three things were added on Windows and are untested on iOS:

- **"Report this quote"** (and fact, scene) no longer opens Mail. It queues
  the flag in an offline outbox (SharedPreferences, `report-outbox-v1`) and
  sends it to `POST /api/v1/Report/Submit`.
- **You → "Send feedback or report a bug"** queues feedback or a bug the
  same way. **You → "Rate Quotely"** opens the App Store review page (the
  same action as on the Support screen).
- **"Enjoying Quotely?"** shows on Today after about 15 days of use. "Yes!"
  calls `InAppReview.instance.requestReview()` from `in_app_review` 2.x.

## Setup

None. `in_app_review` uses `SKStoreReviewController` / `AppStore.requestReview`
and needs no Info.plist keys, entitlements or capabilities. The plugin is
added by Swift Package Manager like the others: re-resolve packages with the
rest (see `plugins.md`) and check `in_app_review` appears in both
`Package.resolved` files.

## Device checks

1. **Flag offline.** Airplane Mode on. Long-press a quote → Report → pick a
   reason → Send report. Expect "Thanks, we’ll take a look" at once and the
   sheet closing. No Mail app should open.
2. **Delivery.** Airplane Mode off. Within a few seconds (connectivity
   event), or on the next foreground, the flag shows on the dashboard's
   Reports page under Flags, with platform `ios`, the OS version
   (`iOS 26.x`), the device model (`iPhone17,1` style machine id), the app
   version and the screen.
3. **Survives a kill.** Airplane Mode on, send feedback, swipe the app away,
   Airplane Mode off, open the app. The feedback arrives once (not twice).
4. **Feedback sheet.** You → Send feedback or report a bug. Switch to Bug,
   type, leave the email empty, untick "Include device info", Send. On the
   dashboard the report has no device fields. Type a malformed email: the
   sheet refuses with an inline message.
5. **Rate Quotely.** You → Rate Quotely opens the App Store on the write-a-
   review page.
6. **Review prompt.** To see it without waiting 15 days, in a debug build set
   the first-open date back: SharedPreferences key
   `review-prompt-first-open` to an ISO date more than 30 days ago (or
   `review-prompt-active-days` to 15), then relaunch and stay on Today for
   about 8 seconds.
   - It must not appear over another sheet (the widget intro, legal consent)
     or on another tab.
   - "Yes!": in a **development build** iOS shows the rating dialog every
     time (it never submits). In **TestFlight it never shows**; that's Apple's
     rule, not a bug. In the App Store build iOS shows it at most 3 times a
     year and may show nothing.
   - "Not really" opens the feedback sheet titled "What could be better?".
   - "Later" closes it; it comes back no sooner than 30 days later.
7. **Dynamic Type.** At the largest text size the prompt and feedback sheet
   scroll and their buttons stay reachable above the keyboard.
