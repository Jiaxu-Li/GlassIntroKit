# Making the Preview Video

The screenshots and the side-by-side video in the README are recordings of the demo app, put into Apple's device frames by a small Swift tool in this repository, `Documentation/Tools/Framing`. No video editor is involved. This page shows how to make them again, for example after the intro changes.

## What you need

- Xcode, with an iOS Simulator for an iPhone 18 Pro or similar.
- A Mac you can record a window on. macOS asks for Screen Recording permission for your terminal the first time.
- The device frames: the **iPhone 18 Pro** and **MacBook Pro 14-inch** bezels from [Apple Design Resources](https://developer.apple.com/design/resources/). They are not in the repository; download them from Apple. Export the portrait iPhone in Black and the MacBook Pro in Space Black as PNGs into one folder:

```
bezels/
  iPhone 18 Pro - Black - Portrait.png
  MacBook Pro M5 14-inch Space Black.png
```

## 1. Record the iPhone

Boot the Simulator, run the demo on it, and set a clean status bar:

```sh
xcrun simctl status_bar booted override --time 9:41 --batteryState charged --batteryLevel 100 --cellularBars 4 --wifiBars 3
```

Start recording, press **Play** in the demo, tap through every page, and stop with Control-C once the app has appeared:

```sh
xcrun simctl io booted recordVideo recordings/ios.mov
```

## 2. Record the Mac

Run the demo on the Mac, and size and place its window where you want it. Find the window's frame in screen points (`x,y,width,height`), then record that rectangle for about a minute and press **Play** soon after it starts:

```sh
screencapture -v -V 60 -x -R 200,150,1100,760 recordings/mac.mov
```

Close other windows behind the demo first; the first moments of a capture can show what is around the window.

## 3. Write down the timing

Watch each recording and note, in seconds:

- when the intro starts (the moment **Play** is pressed),
- the moments you want as screenshots,
- for the Mac, the first moment the recording shows only the window.

Save them as `recordings/timing.json`:

```json
{
  "iosStart": 4.4, "macStart": 1.6, "macCleanFrom": 2.45, "duration": 57,
  "ios": { "settings": 1.0, "launch": 8.0, "greeting": 14.0, "mark": 18.0, "symbols": 22.0,
           "scene": 28.0, "graph": 34.0, "physics": 37.0, "icon": 41.0, "last-page": 44.0,
           "ending": 46.0, "colour": 54.0, "app": 60.0 },
  "mac": { "settings": 2.55, "launch": 3.6, "greeting": 11.0, "scene": 24.5,
           "graph": 30.0, "ending": 43.5, "app": 54.5 }
}
```

`duration` is how long the side-by-side video runs from the intro's start. The screenshot names are the files' names; the README and the diagrams use the ones above.

## 4. Frame them

```sh
swift run -c release --package-path Documentation/Tools/Framing Framing bezels recordings output
```

The tool reads each bezel's screen opening and corner shape, and for every frame:

1. takes the frame from the recording with AVFoundation,
2. clips it to the screen's rounded corners and draws the bezel over it with Core Graphics,
3. for the Mac, puts the window on a plain blue desktop first,
4. for the video, stands the MacBook Pro and the iPhone side by side at their true relative size,
5. encodes the result with `AVAssetWriter`.

It writes into `output`:

| File | What it is |
|---|---|
| `screenshot-<name>.png` | The iPhone at each moment in `ios` |
| `mac-<name>.png` | The MacBook Pro at each moment in `mac` |
| `storyboard.png` | Every picture in turn, from the iPhone screenshots |
| `intro.mp4` | Both devices side by side, 1440 wide, 30 fps |
| `intro-preview.gif` | A quicker loop of the same, for the README |
| `devices.jpg` | One still of both |

The storyboard can also be redrawn on its own from screenshots already framed:

```sh
swift run -c release --package-path Documentation/Tools/Framing Framing storyboard output
```

## 5. Put them in place

Copy the files into `Sources/GlassIntroKit/GlassIntroKit.docc/Resources`; the README, the guides, and the DocC catalog all use them from there. Then redraw the diagrams, since some of them use the screenshots:

```sh
swift run --package-path Documentation/Tools/Diagrams
```

Check the GIF stays small, under 2 MB or so, since the README loads it first.

## Tips

- **A cleaner start.** If the first seconds of the Mac recording show the desktop, move `macCleanFrom` later; earlier moments then hold that frame.
- **Sharper or smoother.** The video's size, frame rate, and bitrate are set where `intro.mp4` is written, in `Documentation/Tools/Framing/Sources/Framing/main.swift`. 1920 wide at 60 fps looks better on a large screen and makes a much larger file.
- **Music and titles.** The tool writes a silent video. Add music or an end card in any editor, or with `AVMutableComposition`, which can join clips and a soundtrack without encoding the video again.
