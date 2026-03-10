// Cursor Smear Effect for Ghostty
// Renders a hue-gradient fading trail when the cursor moves.
// Duration: 150ms | Peak opacity: ~50%

// --- Color helpers ---

vec3 rgb2hsv(vec3 c) {
    vec4 K = vec4(0.0, -1.0/3.0, 2.0/3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0/3.0, 1.0/3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

// --- Main ---

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    // Pass terminal content through unchanged by default
    vec2 uv = fragCoord / iResolution.xy;
    fragColor = texture(iChannel0, uv);

    // Skip if cursor is hidden
    if (iCursorVisible.x < 0.5) return;

    float timeSince = iTime - iTimeCursorChange;
    float duration  = 0.25; // 150ms

    if (timeSince < 0.0 || timeSince >= duration) return;

    // iCurrentCursor.xy = top-left corner (min X, max Y in OpenGL coords)
    // iCurrentCursor.zw = width, height
    vec2 curr   = iCurrentCursor.xy;
    vec2 currSz = iCurrentCursor.zw;
    vec2 prev   = iPreviousCursor.xy;
    vec2 prevSz = iPreviousCursor.zw;

    // No smear if the cursor hasn't actually moved
    if (distance(curr, prev) < 1.0) return;

    // Only smear along same row or same column — no diagonal trails
    bool sameRow = abs(curr.y - prev.y) < currSz.y * 0.5;
    bool sameCol = abs(curr.x - prev.x) < currSz.x * 0.5;
    if (!sameRow && !sameCol) return;

    // Bounding box covering both cursor positions
    float xMin = min(curr.x, prev.x);
    float xMax = max(curr.x + currSz.x, prev.x + prevSz.x);
    float yMin = min(curr.y - currSz.y, prev.y - prevSz.y);
    float yMax = max(curr.y, prev.y);

    if (fragCoord.x < xMin || fragCoord.x > xMax ||
        fragCoord.y < yMin || fragCoord.y > yMax) return;

    // smearT: 0.0 = at current cursor, 1.0 = at previous cursor end
    float smearT = 0.0;
    if (sameRow) {
        float cx   = curr.x + currSz.x * 0.5;
        float px   = prev.x + prevSz.x * 0.5;
        float span = abs(px - cx);
        if (span > 0.5)
            smearT = clamp(sign(px - cx) * (fragCoord.x - cx) / span, 0.0, 1.0);
    } else {
        float cy   = curr.y - currSz.y * 0.5;
        float py   = prev.y - prevSz.y * 0.5;
        float span = abs(py - cy);
        if (span > 0.5)
            smearT = clamp(sign(py - cy) * (fragCoord.y - cy) / span, 0.0, 1.0);
    }

    // Fade over time (smoothstep ease-out) and taper toward the trail end
    float timeFade  = 1.0 - smoothstep(0.0, duration, timeSince);
    float alpha     = timeFade * (1.0 - smearT) * 0.7; // ~50% peak opacity

    // Gradient: rotate hue 120° from cursor color toward the trail end
    vec3 hsv        = rgb2hsv(iCursorColor);
    hsv.x           = fract(hsv.x + smearT * 0.333); // 0° at cursor → ~120° at tail
    vec3 smearColor = hsv2rgb(hsv);

    fragColor.rgb = mix(fragColor.rgb, smearColor, alpha);
}
