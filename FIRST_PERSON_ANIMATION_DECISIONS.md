# First-Person Animation Design Decisions

## Decisions

- Playback uses a first-person view from inside the stand.
- The background, customer, stand, clock, and Skip control are separate layers.
- Customers appear behind the stand so the counter masks their lower bodies.
- Customer visits are a time-lapse abstraction rather than literal walking animations.
- Each customer needs one front-facing or three-quarter-facing service asset.
- A visit consists of fading and scaling in, remaining for service, and fading and scaling out.
- Customer timing uses elapsed real playback time so it remains independent of the total playback duration.
- The first customer appears at one second, arrives over 0.4 seconds, remains for 1.5 seconds, and departs over 0.4 seconds.
- Only one customer will be visible at a time.
- Visits may use left, center, or right service positions at approximately 34%, 50%, and 66% of scene width.
- The four-customer prototype schedules visits at 1, 5, 9, and 13 seconds so activity is distributed across the full day playback.
- Sales-driven visit counts, seasonal selection, product effects, and additional customer assets are deferred. The proof of concept intentionally shows the same four scheduled customers for every simulated day.
- The initial customer library will contain 20 assets:
  - 6 cold-weather customers.
  - 8 warm-weather customers: 4 general, 2 sports fans, and 2 unmistakable beachgoers.
  - 6 temperate-weather customers: 4 general and 2 sports fans.
- Weather is the primary customer classification. Location-specific appearances are tags within a weather group rather than completely separate customer pools.
- General warm-weather customers may also appear at the beach.
- Sports fans may appear in ordinary environments but will be selected more frequently at the baseball stadium.
- Unmistakable beachgoers will be restricted to the beach location.
- Customer assets should use the first customer as their template: `640 × 960`, transparent PNG, consistent waist-up framing, and a front or slight three-quarter service pose.
