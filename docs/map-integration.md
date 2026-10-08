# Supplied SDU map integration

## What is implemented

The 765 × 1280 schematic is rendered as vector geometry, with data-driven interactive rooms, service markers and vertical connections. The drawing coordinates are not real-world measurements. Pinch/pan, fit-map, category search, location details and registered-user favourites all use the same catalogue. Guests cannot save places. Registered users may save up to five places; a sixth is rejected by both app and API until one is removed. Existing historical saves are not silently deleted.

The catalogue contains 53 records, of which 43 have supplied schematic positions. Unpositioned records remain searchable without a pin. Opening a saved, positioned place focuses its location. The floor selector shows the floor-1 plan and recorded connections to other floors; it does not invent other floor plans.

## Source and generated artifacts

- `docs/map-source/campus.yaml`: supplied campus facts and positions.
- `docs/map-source/floor-1.svg`: supplied drawing geometry.
- `docs/map-source/routing-draft.yaml`: explicit floor-1 corridor centerlines and approximate terminal connections traced from that geometry.
- `scripts/import_campus_map.py`: reproducible importer, requiring PyYAML.
- `assets/maps/campus.json` and `backend/app/data/campus.json`: identical generated catalogues.
- `assets/maps/floor-1-background.svg`: generated background without duplicate interactive labels/markers.

Regenerate from the repository root:

```bash
python3 scripts/import_campus_map.py docs/map-source
```

Flutter renders fixed block/faculty labels separately because SVG text is not supported by its SVG renderer. API startup imports catalogue locations once, preserving administrator edits on subsequent starts. Existing historical demo records remain in the database to preserve references, but the public map/search/service lists exclude their unconfirmed locations. The API exposes full geometry and floor metadata at `/campus-map`.

## Important facts preserved

- D101–D104 are interactive rectangles, with D101 nearest the main corridor. D105/D106 have no verified rectangle or order.
- Only confirmed main staircase identifiers 1, 3, 4, 5, 6 and 8 are represented.
- Staircase 6 connects floors 1 and 3, skips 2, and serves the third-floor canteen rather than the general corridor.
- Block-end stairs D–H serve -1, 1, 2, 3; E–H have no map position.
- Library floors are -1, 1, 2, with entrances on 1 and 2. Its internal lift and stairs are searchable but not pinned at illustrative coordinates.
- Spiral stairs by the Bochkas serve -1, 1, 2.
- Lifts in the middle of the D, F and H corridors serve -1, 1, 2 and 3, with approximate floor-1 markers. Landing positions and step-free approaches remain unconfirmed.
- Bochka identifiers are temporary top-down identifiers, not official classroom codes. Internal entrances remain unresolved.
- Technopark has no confirmed floor or pin. Faculty labels do not assign adjacent spine facilities to a block.

## Draft routing

The original supplied routing graph was empty. A separately labelled draft has now been traced from the grey floor-1 corridors, including the main entrance, D101–D104 branch, D/F/H lifts and selected public services. Only explicitly attached places are routeable: spatial proximity does not automatically create an edge. Start and destination are selected manually; there is no live indoor positioning.

The API's `/routes` endpoint runs Dijkstra's algorithm over this network. Edge weights are drawing-unit lengths used only to rank paths, never metres or minutes. Responses contain node paths, drawable segments, points and draft directions. Blue segments follow the traced centerlines; gold dashed terminal connections are approximate doorways or lift/stair approaches. The app shows the trace on the same vector coordinate system and allows clearing it or viewing directions.

Requests to unconnected locations return `unmapped` rather than inventing a path. Cross-floor routes remain unavailable, even though lift/stair served-floor information is stored. Avoid-stairs rejects staircase endpoints; no vertical stair edges are present in this floor-1 network. All route responses set `accessibility_verified: false`. A lift alone does not prove a step-free approach. Distance/time remain null. Opening hours/contact details not provided are marked unconfirmed. Timetables and announcements remain demonstration content, not facts from this survey.

## Next survey batch

Check the draft centerlines on site, and record real door positions, entrances and staircase/lift landings on each floor. Link matching landings across floors; record stairs versus lifts, step-free approaches, restricted access, closed doors and lift availability. Then add cross-floor graph routing with stairs excluded when requested. Calibrate segment lengths from real measurements before displaying metres or walking times. Add floor -1 geometry when available.
