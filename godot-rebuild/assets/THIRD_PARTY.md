# Third-party assets — integration status

Kenney Nature Kit: https://kenney.nl/assets/nature-kit
License: CC0 1.0 (commercial use permitted, attribution optional).
The kit is a candidate source, **not currently included in the web build**.

The automated download/import step added in commit 3b912d4 caused failed GitHub Actions runs and was reverted in commit 90b54ad. The earlier document incorrectly described these models as imported; no downloaded nature GLBs are currently packaged.

Verified archive metadata from an independent source:
- https://kenney.nl/media/pages/assets/nature-kit/37ac38a37b-1677698939/kenney_nature-kit.zip
- SHA-256 fa7974a0d342bfe63c38664ba9f8ec1a4aab8ea25f099bdc56870e33588c4d9d
- Confirmed archive filenames include Models/GLTF format/tree_oak.glb, tree_default.glb, and rock_largeA.glb.
- The earlier build attempted to extract tree_pine.glb without verifying its presence.

Do not claim assets are integrated until GitHub Actions succeeds and the actual web render is checked.
