// Cursor Smear Effect for Ghostty
// Renders a hue-gradient fading trail when the cursor moves.
// Supports horizontal, vertical, and diagonal cursor movement.
// Duration: 250ms | Peak opacity: ~70%

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
    float duration  = 0.25;

    if (timeSince < 0.0 || timeSince >= duration) return;

    // iCurrentCursor.xy = top-left corner (min X, max Y in OpenGL coords)
    // iCurrentCursor.zw = width, height
    vec2 curr   = iCurrentCursor.xy;
    vec2 currSz = iCurrentCursor.zw;
    vec2 prev   = iPreviousCursor.xy;
    vec2 prevSz = iPreviousCursor.zw;

    // No smear if the cursor hasn't actually moved
    if (distance(curr, prev) < 1.0) return;

    // Compute centers of current and previous cursor positions
    vec2 currCenter = vec2(curr.x + currSz.x * 0.5, curr.y - currSz.y * 0.5);
    vec2 prevCenter = vec2(prev.x + prevSz.x * 0.5, prev.y - prevSz.y * 0.5);

    // Direction vector from current to previous cursor position
    vec2 dir = prevCenter - currCenter;
    float totalDist = length(dir);
    if (totalDist < 0.5) return;

    // Normalized direction and perpendicular
    vec2 dirNorm  = dir / totalDist;
    vec2 perpNorm = vec2(-dirNorm.y, dirNorm.x);

    // Project fragment position onto the trail line
    vec2 fragRel   = fragCoord - currCenter;
    float projAlong = dot(fragRel, dirNorm);
    float projPerp  = abs(dot(fragRel, perpNorm));

    // Corridor half-width based on cursor size
    float halfWidth = max(currSz.x, currSz.y) * 0.5;

    // Discard fragments outside the trail corridor
    if (projPerp > halfWidth) return;
    if (projAlong < 0.0 || projAlong > totalDist + halfWidth) return;

    // smearT: 0.0 = at current cursor, 1.0 = at previous cursor end
    float smearT = clamp(projAlong / totalDist, 0.0, 1.0);

    // Soften edges of the corridor with perpendicular falloff
    float edgeFade = 1.0 - smoothstep(halfWidth * 0.5, halfWidth, projPerp);

    // Fade over time (smoothstep ease-out) and taper toward the trail end
    float timeFade  = 1.0 - smoothstep(0.0, duration, timeSince);
    float alpha     = timeFade * (1.0 - smearT) * edgeFade * 0.7;

    // Gradient: rotate hue 120 degrees from cursor color toward the trail end
    vec3 hsv        = rgb2hsv(iCursorColor);
    hsv.x           = fract(hsv.x + smearT * 0.333);
    vec3 smearColor = hsv2rgb(hsv);

    fragColor.rgb = mix(fragColor.rgb, smearColor, alpha);
}
