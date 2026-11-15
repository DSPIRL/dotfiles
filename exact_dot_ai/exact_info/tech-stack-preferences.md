# Affinity Tools (tools I personally like when they are reasonably applicable)
- Environment tooling: `mise` for development tool versions and tasks; `Nix` complements it only for needs mise cannot handle, such as system/native dependencies or reproducible environments beyond tool-version management. Nix may provide mise. Assign one owner for each tool version rather than selecting the same compiler or runtime independently in both.
- Try to avoid adding new technologies that commonly have remote security implications, like SSR (Server Side Rendering).
- TLA+ when applicable.
- LEAN-lang when applicable.

# Affinity Preferences
- Most apps should support feature-flags.
- Most features should have a feature-flag.
