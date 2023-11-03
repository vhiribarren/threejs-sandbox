// ----------------------------------------------------------------------------
// IMPORTANT - LICENSING
//
// This work was done by watching the work of Inigo Quilez, in the following
// place: https://www.youtube.com/watch?v=Cfe5UQ-1L9Q
//
// The shader was written and adapted by me by watching the video tutorial for
// educational purpose. It largely copies line of codes displayed in the video
// and it reproduces a final piece of code implementing a work of art. As such,
// Inigo Quilez is the sole owner of this art work, you are not allowed to use
// it unless the original author granted you his agreement.
//
// Copyright owner: Inigo Quilez Website: https://iquilezles.org/
// ----------------------------------------------------------------------------

varying vec2 v_uv;
uniform float u_time;
uniform float u_offset_horizontal;

float time;

const uint RAYMARCHING_MAX_STEPS = 200u;
const float RAYMARCHING_RADIUS_MIN = 0.001;
const float RAYMARCHING_RADIUS_MAX = 20.0;
const float SHADOW_BIAS = 0.001;

const uint OBJ_ID_NONE = 0u;
const uint OBJ_ID_FLOOR = 1u;
const uint OBJ_ID_BODY = 2u;
const uint OBJ_ID_EYES = 3u;
const uint OBJ_ID_PUPILS = 4u;

struct CollisionInfo {
    float distance;
    uint collided_obj_id;
};


vec3 material(uint obj_id, vec3 pos) {
    vec3 col = vec3(1.0);
    if (obj_id == OBJ_ID_FLOOR) {
        col = vec3(0.05, 0.09, 0.02);
        float f = -1.0 + 2.0*smoothstep(-0.2, 0.2, sin(18.0*pos.x)+sin(18.0*pos.y)+sin(18.0*pos.z));
        col += 0.2*f*vec3(0.06, 0.06, 0.02);
        return col;
    } else if (obj_id == OBJ_ID_BODY) {
        col = vec3(0.2, 0.1, 0.02);
    } else if (obj_id == OBJ_ID_EYES) {
        col = vec3(0.4, 0.4, 0.4);
    } else if (obj_id == OBJ_ID_PUPILS) {
        col = vec3(0.02);
    }
    return col;
}


float sdf_elipsoid(vec3 pos, vec3 radius) {
    float k0 = length(pos / radius);
    float k1 = length(pos / radius / radius);
    return k0 * (k0 - 1.0) / k1;
}

float sdf_sphere(vec3 pos, float radius) {
    return length(pos) - radius;
}

float sdf_stick(vec3 pos, vec3 a, vec3 b, float ra, float rb) {
    vec3 ba = b-a;
    vec3 pa = pos-a;
    float h = clamp(dot(pa,ba)/dot(ba,ba), 0.0, 1.0);
    float r = mix(ra, rb, h);
    return length(pa-h*ba) - r;
}

float smooth_min(float a, float b, float coeff) {
    float h = max(coeff - abs(a - b), 0.0);
    return min(a, b) - h * h / (coeff * 4.0);
}

float smooth_max(float a, float b, float coeff) {
    float h = max(coeff - abs(a - b), 0.0);
    return max(a, b) + h * h / (coeff * 4.0);
}


CollisionInfo min_collision(CollisionInfo left, CollisionInfo right) {
    if (left.distance < right.distance) {
        return left;
    } else {
        return right;
    };
}

CollisionInfo scene(vec3 pos) {
    float t = fract(time);

    float jump_y = 4.0 * t * (1.0 - t);
    //let dy = 4.0*(1.0- 2.0*t);
    //let u = normalize(vec2(1.0, -dy));
    //let v = vec2(dy, 1.0);
    float i_time = floor(time);
    float f_time = fract(time);
    vec3 center = vec3(
        0.0,
        pow(jump_y, 2.0-jump_y)+0.1,
        i_time + pow(f_time, 0.7));
    float coeff_y = 0.5 + 0.5 * jump_y;
    float coeff_z = 1.0 / coeff_y;
    vec3 radius = vec3(0.25, 0.25 * coeff_y, 0.25 * coeff_z);
    vec3 body_pos = pos - center;
    //q.yz = vec2(dot(u, q.yz), dot(v, q.yz));
    //q.y = dot(u, q.yz);
    //q.z = dot(v, q.yz);

    // Body
    float body = sdf_elipsoid(body_pos, radius);

    // Head
    vec3 head_pos = body_pos;//body_pos - vec3(0.0, 0.28, 0.0);
    vec3 xmirrored_head_pos = vec3(abs(head_pos.x), head_pos.yz);
    float head = sdf_elipsoid(head_pos - vec3(0.0, 0.28, 0.0), vec3(0.15, 0.2, 0.23));
    float back_head = sdf_elipsoid(head_pos - vec3(0.0, 0.28, -0.1), vec3(0.23, 0.2, 0.2));
    
    // Eye & pupils
    float eyes = sdf_sphere(xmirrored_head_pos - vec3(0.08, 0.28, 0.16), 0.05);
    float pupils = sdf_sphere(xmirrored_head_pos - vec3(0.09, 0.28, 0.195), 0.02);
    vec3 eyeylids_pos = xmirrored_head_pos - vec3(0.12, 0.34, 0.15);
    eyeylids_pos.xy = (mat2(3, 4, -4, 3)/5.0)*eyeylids_pos.xy;
    float eyelids = sdf_elipsoid(eyeylids_pos, vec3(0.06, 0.035, 0.05));
    
    // Mouth
    float mouth = sdf_elipsoid(head_pos-vec3(0.0, 0.15+3.0*head_pos.x*head_pos.x, 0.15), vec3(0.1, 0.04, 0.2));

    // Ears
    float ears = sdf_stick(xmirrored_head_pos, vec3(0.1, 0.4, -0.01), vec3(0.2, 0.55, 0.05), 0.01, 0.03);


    // Compute sdf result
    float merged_body = smooth_min(head, back_head, 0.05);
    merged_body = smooth_min(merged_body, body, 0.15);
    merged_body = smooth_min(merged_body, eyelids, 0.04);
    merged_body = smooth_max(merged_body, -mouth, 0.03);
    merged_body = smooth_min(merged_body, ears, 0.03);
    // Wrinkles
    float wrinkles_y = head_pos.y - 0.02 - 2.5*head_pos.x*head_pos.x;
    float wrinkles = 0.001*sin(wrinkles_y*120.0) * (1.0-smoothstep(0.0, 0.1, abs(wrinkles_y)));
    merged_body += wrinkles;


    CollisionInfo merged_eyes = min_collision(
        CollisionInfo(pupils, OBJ_ID_PUPILS),
        CollisionInfo(eyes, OBJ_ID_EYES)
    );
    CollisionInfo guy_collision = min_collision(
        CollisionInfo(merged_body, OBJ_ID_BODY),
                merged_eyes

    );

    // Floor
    float floor_height = -0.1 + 0.05*(sin(2.0*pos.x) + sin(2.0*pos.z));
    CollisionInfo floor_collision = CollisionInfo(pos.y - floor_height, OBJ_ID_FLOOR);

    return min_collision(guy_collision, floor_collision);
}

vec3 collision_normal(vec3 pos) {
    vec2 e = vec2(0.0001, 0.0);
    return normalize(vec3(
        scene(pos + e.xyy).distance - scene(pos - e.xyy).distance,
        scene(pos + e.yxy).distance - scene(pos - e.yxy).distance,
        scene(pos + e.yyx).distance - scene(pos - e.yyx).distance
    ));
}

float cast_shadow(vec3 origin, vec3 direction) {
    float res = 1.0;
    float raymarch_dist = SHADOW_BIAS;
    for (uint i = 0u; i < 100u; i++) {
        vec3 pos = origin + raymarch_dist * direction;
        float collision_distance = scene(pos).distance;
        res = min(res, 16.0 * collision_distance / raymarch_dist);
        if (collision_distance < RAYMARCHING_RADIUS_MIN) {
            break;
        }
        raymarch_dist += collision_distance;
        if (raymarch_dist > RAYMARCHING_RADIUS_MAX) {
            break;
        }
    }
    return clamp(res, 0.0, 1.0);
}

CollisionInfo cast_ray(vec3 origin, vec3 direction) {
    float raymarch_dist = 0.0;
    uint collision_id_candidate = OBJ_ID_NONE;
    for (uint i = 0u; i < RAYMARCHING_MAX_STEPS; i++) {
        vec3 scan_pos = origin + raymarch_dist * direction;
        CollisionInfo collision_info = scene(scan_pos);
        collision_id_candidate = collision_info.collided_obj_id;
        if (collision_info.distance < RAYMARCHING_RADIUS_MIN) {
            break;
        }
        raymarch_dist += collision_info.distance;
        if (raymarch_dist > RAYMARCHING_RADIUS_MAX) {
            break;
        }
    }
    if (raymarch_dist > RAYMARCHING_RADIUS_MAX) {
        collision_id_candidate = OBJ_ID_NONE;
        raymarch_dist = -1.0;
    }
    return CollisionInfo(raymarch_dist, collision_id_candidate);
}

vec3 gamma_correction(vec3 color) {
    return pow(color, vec3(0.4545));
}

void main() {
    vec2 size = gl_FragCoord.xy / v_uv;
    float ratio = size.x / size.y;
    time = 0.9* u_time;
    // Shift coords to be in centered right-hand coordinates
    vec2 centered_uv = v_uv - 0.5;
    vec2 canvas_pos = 2.0 * centered_uv * vec2(ratio, 1.0);

    // Camera parameters
    float camera_angle = 1.5 * u_offset_horizontal; // u_time; //
    float camera_distance = 0.0;//0.9*sin(time);
    vec3 camera_target = vec3(0.0, 0.65, 0.4 + time + camera_distance);
    vec3 camera_eye = camera_target + vec3(1.3 * cos(camera_angle), -0.250, 1.3 * sin(camera_angle));
    float canvas_distance = 1.8;
    // Transform canvas coordinates
    vec3 camera_axis_z = normalize(camera_target - camera_eye);
    vec3 camera_axis_x = normalize(cross(camera_axis_z, vec3(0.0, 1.0, 0.0)));
    vec3 camera_axis_y = normalize(cross(camera_axis_x, camera_axis_z));
    mat3x3 camera_transform = mat3x3(camera_axis_x, camera_axis_y, camera_axis_z);
    vec3 direction = normalize(camera_transform * vec3(canvas_pos, canvas_distance));
    // lights
    vec3 sun_dir = normalize(vec3(0.8, 0.4, 0.2));
    vec3 sun_color = vec3(7.0, 4.5, 3.0);
    vec3 sky_dir = normalize(vec3(0.0, 1.0, 0.0));
    vec3 sky_color = vec3(0.0, 0.05, 0.2);
    vec3 bounce_dir = vec3(0.0, -1.0, 0.0);
    vec3 bounce_color = vec3(0.7, 0.3, 0.2);
    // Raymarching
    vec3 horizon_gray_color = vec3(0.7, 0.75, 0.8);
    vec3 output_col = vec3(0.4, 0.75, 1.0) - 0.7 * direction.y;
    output_col = mix(output_col, horizon_gray_color, exp(-10.0 * direction.y));
    CollisionInfo raymarch_result = cast_ray(camera_eye, direction);
    if (raymarch_result.collided_obj_id != OBJ_ID_NONE) {
        vec3 collision_pos = camera_eye + raymarch_result.distance * direction;
        vec3 collision_normal = collision_normal(collision_pos);
        vec3 material_color = material(raymarch_result.collided_obj_id, collision_pos);
        float sun_diffusion = clamp(dot(collision_normal, sun_dir), 0.0, 1.0);
        float sun_shadow = cast_shadow(collision_pos + collision_normal * SHADOW_BIAS, sun_dir);
        float sky_diffusion = clamp(0.5 + 0.5 * dot(collision_normal, sky_dir), 0.0, 1.0);
        float ground_bounce_diffusion = clamp(0.5 + 0.5 * dot(collision_normal, bounce_dir), 0.0, 1.0);
        output_col = material_color * sun_diffusion * sun_color * sun_shadow;
        output_col += material_color * sky_diffusion * sky_color;
        output_col += material_color * ground_bounce_diffusion * bounce_color;
    }
    output_col = gamma_correction(output_col);
    gl_FragColor = vec4(output_col, 1.0);
}