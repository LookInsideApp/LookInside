# DerivedSource

This folder is generated.

`Scripts/sync-derived-source.sh` copies `LookinCore`, `LookinCoreImpl` and `LookinServerBase` from `/Sources` here before the app builds. The folder is a synchronized group of the app target, so every source file in it is compiled without a project change.

Edit the source files under `/Sources` (which `Scripts/sync-lookin-core.sh` mirrors from LookInside-Server).
