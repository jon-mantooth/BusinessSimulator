# Sound Decisions

## Responsibilities

- `SoundPlayer` owns low-level audio playback. It loads audio resources,
  configures `AVAudioPlayer`, caches players for reuse, applies sound-specific
  volume, and supports looping and stopping sounds.
- `SimulationAudioResolver` decides which sounds belong to a simulation from
  its location, product, weather, and calendar context.
- `SimulationAudioController` owns simulation playback timing. It starts and
  stops looping ambience, schedules intermittent cues, and cancels unfinished
  audio work when playback ends, is skipped, or is replaced.
- Selection logic and timing remain outside `SoundPlayer` so the player stays a
  reusable playback service rather than accumulating game-specific rules.

## Shared Playback

- `GameRootView` owns one shared `SoundPlayer` for the active game UI.
- Different sounds may play concurrently. This allows weather ambience, such
  as rain, to play over location ambience and intermittent cues.
- Starting the same sound again restarts that sound rather than creating
  overlapping copies of it.
- Volume is configured by `GameSound`, allowing individual clips to be balanced
  without editing the original audio files.

## Department Sounds

- Production, distribution, marketing, and finance each have an entry sound.
- A department sound plays only the first time that department is opened during
  a game day. The tracking state resets when the day ends.
- Production uses cooking audio for pies and hot dogs and blender audio for
  smoothies.
- Upgrade audio begins with the department scene transition so the sound and
  visible upgrade appear as one event.

## Simulation Audio

- Every simulation receives a `SimulationAudioPlan` containing looping sounds
  and zero or more intermittent cues.
- Location determines the base ambience and location-specific cues.
- Weather is an independent layer. Rain ambience is added without replacing
  the location ambience or its cues.
- Home, the beach, and the farmers market currently use neighborhood ambience.
  The ballpark uses its own ambience.
- Ballpark hits and beach waves play during stages two and four. The farmers
  market bell plays at stage zero.

## Cue Timing

- Simulation playback is divided into five randomized timing stages so cues do
  not always occur at exactly the same instant.
- A cue chooses a random playback point inside its assigned stage.
- Stage zero is a separate deterministic stage that plays immediately and does
  not use random timing.
- A scene may use the same clip in multiple stages or assign different clips to
  each stage.
- Starting a new plan first stops the current plan. Ending or skipping a
  simulation cancels pending cues and stops its looping sounds.

## Transaction Sounds

- The relocation sound plays only after the relocation workflow reports a
  successful completion. Failed or unavailable relocation attempts remain
  silent.

## Asset Format and Size

- Short ambience clips may loop for the duration of the simulation instead of
  storing one long recording.
- Longer scenes can combine a small looping ambience file with short
  intermittent cues, providing variety without a large storage cost.
- WAV assets are compressed to a lower sample rate and mono where the audible
  result remains acceptable on a phone speaker. MP3 may be retained when it is
  already substantially smaller.
- The optimized clip must still be checked in the app before its original is
  discarded because acceptable compression depends on the sound.

## Testability

- Playback conforms to the `SoundPlaying` protocol.
- Tests use an in-memory recording player rather than invoking `AVAudioPlayer`.
- Correctness tests focus on resolver output, weather layering, timing-window
  contracts, immediate cues, cancellation, and replacement of active plans.
- Tests do not attempt to prove speaker output or subjective audio quality;
  those require testing on a physical device.
