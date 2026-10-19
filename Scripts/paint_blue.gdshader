shader_type canvas_item;

uniform vec4 paint_color : source_color = vec4(1.0);
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec2 origin = vec2(0.0, 1.0);        // bottom-left (UV y points down)
uniform float aspect = 1.7778;               // viewport width / height
uniform float wobble = 0.05;                 // how uneven the paint edge is
uniform float edge_soft = 0.004;

void fragment() {
    vec2 p = (UV - origin) * vec2(aspect, 1.0);
    float dist = length(p);
    float ang = atan(p.y, p.x);

    // Organic edge, faded in so there's no blob at progress 0
    float amt = wobble * min(progress * 5.0, 1.0);
    float w = sin(ang * 6.0 + progress * 6.0) * amt
            + sin(ang * 13.0 - progress * 9.0) * amt * 0.5;

    float max_d = length(vec2(aspect, 1.0));
    float front = progress * (max_d + wobble * 3.0);

    float a = 1.0 - smoothstep(front - edge_soft, front + edge_soft, dist + w);
    COLOR = vec4(paint_color.rgb, a * paint_color.a);
}