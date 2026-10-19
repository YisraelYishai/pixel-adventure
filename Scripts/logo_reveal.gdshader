shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float softness : hint_range(0.01, 1.0) = 0.3;  // edge feather
uniform vec2 direction = vec2(-1.0, 1.0);              // wipe direction

void fragment() {
    vec2 d = normalize(direction);
    // Project UV onto the direction, normalized to 0..1 across the image
    float lo = min(0.0, d.x) + min(0.0, d.y);
    float hi = max(0.0, d.x) + max(0.0, d.y);
    float pos = (dot(UV, d) - lo) / (hi - lo);

    float edge = progress * (1.0 + softness);
    float a = clamp((edge - pos) / softness, 0.0, 1.0);

    COLOR = texture(TEXTURE, UV);
    COLOR.a *= a;
}