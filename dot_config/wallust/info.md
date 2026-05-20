# Wallust Backends and Color Spaces

Wallust turns a wallpaper into terminal/application colors in a few stages:

1. `backend` decides how pixels are read from the image.
2. `color_space` decides how those colors are compared, grouped, mixed, and sorted.
3. `palette` decides how the gathered colors become final values like `color0` through `color15`.

This file focuses on `backend` and `color_space`, but `palette` matters because some color spaces are designed for specific palettes.

## Backends

`backend` controls how Wallust samples the image before it extracts colors.

### `full`

Reads the whole image and returns all pixels.

Pros:
- Most precise and faithful to the source image.
- Best when you want maximum quality and do not care much about speed.

Cons:
- Slower on large images.
- Can overrepresent huge flat areas, such as sky, walls, or dark backgrounds.

Good for:
- High-quality cached themes.
- Smaller wallpapers.
- When accuracy matters more than speed.

### `resized`

Resizes the image before parsing it while preserving aspect ratio.

Pros:
- Much faster than `full`.
- Keeps the image proportions intact.
- Reliable general-purpose choice.

Cons:
- Slightly less precise than `full`.

Good for:
- Daily wallpaper switching.
- Reliable, fast theme generation.
- Most users most of the time.

### `wal`

Uses ImageMagick `convert` to generate colors, similar to pywal.

Pros:
- Good if you want behavior close to pywal.
- Useful for pywal compatibility expectations.

Cons:
- Depends on ImageMagick behavior.
- Not usually my first choice if using Wallust specifically for its own extraction methods.

Good for:
- Matching old pywal-style output.
- Compatibility with existing pywal habits or expectations.

### `thumb`

Uses a fast hardcoded 512x512 thumbnail approach.

Pros:
- Fast.
- Simple.

Cons:
- Does not preserve aspect ratio.
- Can distort image influence and produce less faithful palettes.

Good for:
- Speed-first setups.
- Cases where exact image proportions do not matter.

### `fastresize`

Uses a much faster SIMD resize algorithm.

Pros:
- Very fast.
- Usually a better speed-focused option than `thumb`.

Cons:
- Wallust notes it can fail on some images where `resized` works.

Good for:
- Fast automatic wallpaper/theme updates.
- Setups where occasional fallback/manual rerun is acceptable.

### `kmeans`

Uses k-means clustering to divide and pick pixels from across the image.

Pros:
- Often gives more diverse palettes.
- Helps avoid one dominant image area controlling the whole theme.
- Good for visually rich wallpapers.

Cons:
- Can feel less strictly representative of the dominant image mood.
- May choose accent colors more aggressively than expected.

Good for:
- Wallpapers with many interesting colors.
- Avoiding dull palettes from images with one dominant background.
- More colorful, varied themes.

## Color Spaces

`color_space` controls how Wallust understands color relationships after the backend has sampled the image.

### `lab`

Uses CIE L*a*b color space.

LAB is perceptual, meaning distances between colors are closer to how humans perceive color differences than plain RGB distances.

Pros:
- Strong general-purpose choice.
- Usually produces sensible, balanced colors.
- Separates lightness from color axes.

Cons:
- Not as hue-oriented as LCH.

Good for:
- Reliable wallpaper matching.
- Natural-looking palettes.

### `labmixed`

A variant of `lab` that mixes gathered similar colors. If there are not enough colors, it falls back to normal `lab` behavior.

Pros:
- Produces cohesive palettes.
- Reduces harsh jumps between similar colors.
- Good when you want the theme to feel unified.

Cons:
- Not recommended for very small/simple images.
- Can smooth away some interesting color contrast.

Good for:
- A polished, cohesive desktop theme.
- Wallpapers with enough color information to mix well.

### `lch`

Uses CIE Lch, which is related to LAB but represents colors as lightness, chroma, and hue.

Pros:
- Often handles hue relationships more naturally.
- Can help with sorting colors by hue/chroma.
- Good for visually pleasing accent selection.

Cons:
- Can feel a bit more stylized depending on the wallpaper and palette.

Good for:
- Attractive desktop themes.
- Wallpapers where hue relationships matter.

### `lchmixed`

A variant of `lch` that mixes similar colors while gathering them.

Pros:
- Combines LCH's hue-aware behavior with smoother grouping.
- Often creates very pleasant, cohesive palettes.
- Good balance between colorful and polished.

Cons:
- May reduce contrast between close accent colors.
- Can be less ideal if you want raw color separation.

Good for:
- Daily visual theming.
- Cohesive but still colorful palettes.

### `lchansi`

An LCH variant designed to preserve ANSI-like terminal color roles: black, red, green, yellow, blue, magenta, cyan, and gray.

Pros:
- Keeps terminal color order more predictable.
- Best option when semantic terminal colors matter.
- Helps tools like `ls`, `grep`, `btop`, and other terminal apps stay understandable.

Cons:
- Best paired with `palette = "ansidark"` or `palette = "ansidark16"`.
- Less free-form than other color spaces.

Good for:
- Terminal-heavy workflows.
- Preserving expected ANSI color meanings.
- Avoiding weird `LS_COLORS` output.

## My Preferred Picks

If I were tuning this setup for daily use, these are the combinations I would reach for first.

### Best Reliable Default

```toml
backend = "resized"
color_space = "lchmixed"
palette = "dark"
```

This is my favorite practical default. `resized` is fast and reliable, while `lchmixed` usually gives better-looking, smoother palettes than plain `lab` without being too unpredictable.

### Best Quality-Oriented Setup

```toml
backend = "full"
color_space = "lchmixed"
palette = "dark"
```

This is what I would use if generation speed is not noticeable or if themes are cached. It keeps maximum image information and uses a color space that tends to produce cohesive, attractive results.

### Best Terminal-Safe Setup

```toml
backend = "resized"
color_space = "lchansi"
palette = "ansidark"
```

This is what I would use if terminal readability matters more than exact wallpaper aesthetics. It keeps colors closer to expected ANSI roles, which is useful for terminal tools and `LS_COLORS`.

### Best Colorful/Diverse Setup

```toml
backend = "kmeans"
color_space = "lchmixed"
palette = "dark16"
```

This is what I would try when wallpapers produce boring palettes. `kmeans` tends to pull a more diverse set of colors, and `dark16` gives more shade variation.

## My Ranking

Backends:

1. `resized` - best default because it is fast, reliable, and preserves aspect ratio.
2. `full` - best quality, but slower.
3. `kmeans` - best when you want more diverse colors.
4. `fastresize` - best speed option, but slightly less trustworthy because it can fail on some images.
5. `wal` - useful for pywal-like compatibility, but not my first choice for Wallust.
6. `thumb` - fast, but aspect-ratio distortion makes it my least preferred.

Color spaces:

1. `lchmixed` - best-looking daily choice in my opinion.
2. `lch` - great if you want clearer hue separation and less mixing.
3. `labmixed` - cohesive and polished; your current config uses this.
4. `lab` - very reliable baseline.
5. `lchansi` - best for terminal semantic colors, but only my top choice when paired with `ansidark`/`ansidark16`.

## Notes For This Config

The current Wallust config uses:

```toml
backend = "full"
color_space = "labmixed"
palette = "dark"
check_contrast = true
threshold = 15
```

That is a quality-oriented and cohesive setup. I would only change it if:

- Generation feels slow: try `backend = "resized"`.
- Colors feel too muted/samey: try `color_space = "lchmixed"`.
- Terminal ANSI colors feel semantically wrong: try `color_space = "lchansi"` with `palette = "ansidark"`.
- Wallpapers produce boring palettes: try `backend = "kmeans"`.
