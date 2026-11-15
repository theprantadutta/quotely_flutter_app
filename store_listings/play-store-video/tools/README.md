# Promo video tools

These scripts built `../quotely-promo-landscape.mp4` (1920x1080, light mode, for Play and YouTube). The thumbnail is `assets/brand/store/quotely-video-thumbnail-1280x720.png`: the feature graphic scaled to 1280x720 over a blurred copy of itself. Adapted from snake_classic's `store_listings/play-store-video`.

## 1. Record (Galaxy A24, 1080x2340)

- Other sessions share the A24. Ask them first and check `adb shell pgrep screenrecord`. Never restart adb.
- Switch the phone to light mode with `adb shell cmd uimode night no`, and restore it afterwards.
- Seed the app first: save a few quotes and scenes, add the Quote of the Day widget.
- Record with `screenrecord --bit-rate 8000000 --time-limit 178 /sdcard/recN.mp4` and stop it with `pkill -INT screenrecord`.
- In Git Bash, set `MSYS_NO_PATHCONV=1` before `adb pull /sdcard/...`.
- Raw clips (`rec*.mp4`) are git-ignored. Pick the cuts from a contact sheet (`ffmpeg -vf fps=1`).

## 2. Render

```
FF=<python>/site-packages/imageio_ffmpeg/binaries/ffmpeg-win-x86_64-v7.1.exe
python render_landscape.py $FF scenes.json music.mp3 ../quotely-promo-landscape.mp4
```

`scenes.json` lists each segment: `src`, `a`/`b` trim in seconds, then `chip`/`title`/`sub` for the caption.

## Music

"Gymnopedie No 1" by Kevin MacLeod (incompetech.com), licensed under Creative Commons: By Attribution 4.0 (https://creativecommons.org/licenses/by/4.0/).

Download it from https://incompetech.com/music/royalty-free/mp3-royaltyfree/Gymnopedie%20No%201.mp3 as `music.mp3`; the file is git-ignored. **The credit above must appear in the YouTube description.**

## 3. Publish

- Upload to YouTube (public or unlisted, ads off) with the music credit in the description.
- Put the `youtube.com/watch?v=` URL in Play Console > Main store listing > Video.
