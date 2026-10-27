# Golden test fonts

`Roboto-Regular.ttf` and `Roboto-Bold.ttf` are copied from Flutter 3.41.2's
`bin/cache/artifacts/material_fonts/` directory. The accompanying Apache 2.0
license is preserved as `LICENSE.txt`.

Only golden tests load these fonts. They make text readable in the approved
baselines without depending on fonts installed on a developer or CI machine.
Material icons are loaded from the Flutter asset bundle for the pinned SDK.
