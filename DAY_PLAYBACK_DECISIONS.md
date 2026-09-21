# Day Playback Design Decisions

Use this file to record lasting design decisions for the animated day playback feature.

## Decisions

- Day playback visually represents an already calculated simulation; it does not perform sales or other business calculations minute by minute.
- The initial real-time playback duration will be sixteen seconds and may be adjusted after testing.
- Playback will be skippable.
- Playback will occur within the existing stand scene rather than on a separate screen.
- The stand scene will act as a stage on which the clock, future customers, and other day-related animations can be layered.
- Playback should visually reflect the simulated state of the business. Weather may change the scene, greater market size should produce more potential customers, and greater demand should cause a larger share of those customers to stop at the stand.
- `DayPlaybackState` will own the shared playback lifecycle and normalized progress value.
- Playback progress will range from `0.0` at opening time to `1.0` at closing time.
- The clock and future customer animations will observe the same playback state but will not control it.
- `GameRootView` will remain responsible for coordinating simulation, saving, playback, and presentation of the daily summary.
- The completed day will be simulated, prepared, and saved before playback begins. If the app closes during playback, reopening it should preserve the completed day rather than rerun it.
- The initial clock implementation will be developed with a temporary trigger before it is connected to the production Start Day flow.

## Learning Follow-Up

- Revisit Swift closures after completing the initial playback implementation, including trailing-closure syntax, captured values, escaping closures, and capture lists such as `[weak self]`.
