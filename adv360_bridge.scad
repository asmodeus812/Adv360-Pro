//
// Kinesis Advantage360 rectangular bridge
// - Single file
// - Two clamshell halves
// - Inboard clamp grooves seat onto the steel bracket with 1.5 mm inset per half
//
// Units: mm
//

$fa = 3;
$fs = 0.5;

eps = 0.05;

// ------------------------------------------------------------
// Render control
// ------------------------------------------------------------
// "top"      -> one shell
// "bottom"   -> one shell
// "assembly" -> both shells with bracket preview
render_part = is_undef(render_part) ? "assembly" : render_part;

show_bracket_preview = is_undef(show_bracket_preview) ? true : show_bracket_preview;

// ------------------------------------------------------------
// User-facing bridge geometry
// ------------------------------------------------------------
// Requested bridge length, excluding the extra extension at both ends.
bridge_length = 200;

// Extra solid material added on each end beyond bridge_length.
// The clamp grooves begin after this extension, so the outer lip stays full thickness.
// Example: 100 mm bridge_length + 15 mm per side => 130 mm overall.
end_extension = 15;

// Thickness of each printed half.
shell_body_thickness = 6;

// Extra bridge material on each side of the clamp groove.
bridge_side_margin = 0;

// Small outer rounding for the bridge body, kept within the same outer size.
bridge_corner_r = 1.5;

// Hard cap for overall bridge width.
bridge_width_max = 75;

// ------------------------------------------------------------
// Bracket clamp geometry
// ------------------------------------------------------------
bracket_length = 75;
clamp_zone_depth = 25;
bracket_thickness = 3;

// Width of the groove / bracket contact area across the bridge.
groove_width = bracket_length;

// Each shell removes 1.5 mm so the two halves seat around the 3 mm steel bracket.
clamp_inset_per_shell = 1.5;

// Fit leeway for the bracket grooves.
bracket_width_clearance = 0.10;
bracket_depth_clearance = 0.05;

// Clamp groove starts this far inboard from each outer edge.
clamp_offset_from_end = end_extension;

// ------------------------------------------------------------
// Reinforcement bars
// ------------------------------------------------------------
reinforcement_enable = true;

// Off-the-shelf flat-bar default.
reinforcement_bar_width = 15;
reinforcement_bar_thickness = 2;

// One central full-length internal slit in each shell.
// The assembled bridge forms a pass-through slot for a flat bar along the centerline.
reinforcement_width_clearance = 0.10;
reinforcement_depth_clearance = 0.05;
reinforcement_offset_from_clamp_face = clamp_inset_per_shell + bracket_depth_clearance;

// ------------------------------------------------------------
// Center fasteners
// ------------------------------------------------------------
outer_bolt_inset_from_groove = 15;
m3_clear_d = 3.4;
m3_head_d = 6.2;
m3_head_depth = 3.0;
m3_nut_af = 5.8;
m3_nut_depth = 2.6;
m3_nut_clearance = 0.2;

// ------------------------------------------------------------
// Derived geometry
// ------------------------------------------------------------
overall_length = bridge_length + 2 * end_extension;
bridge_width = groove_width + 2 * bridge_side_margin;

left_pocket_x = -overall_length/2 + clamp_offset_from_end + clamp_zone_depth/2;
right_pocket_x = overall_length/2 - clamp_offset_from_end - clamp_zone_depth/2;

left_groove_inner_x = left_pocket_x + clamp_zone_depth/2;
right_groove_inner_x = right_pocket_x - clamp_zone_depth/2;
center_span = right_groove_inner_x - left_groove_inner_x;
reinforcement_bar_length = overall_length;
reinforcement_slit_depth = reinforcement_bar_thickness + reinforcement_depth_clearance;
reinforcement_channel_y = 0;

left_lip_bolt_x = -overall_length/2 + end_extension/2;
left_bolt_x = left_groove_inner_x + outer_bolt_inset_from_groove;
center_bolt_x = 0;
right_bolt_x = right_groove_inner_x - outer_bolt_inset_from_groove;
right_lip_bolt_x = overall_length/2 - end_extension/2;

assert(bridge_width <= bridge_width_max,
    str("bridge_width=", bridge_width, " exceeds bridge_width_max=", bridge_width_max));

assert(left_bolt_x < center_bolt_x && center_bolt_x < right_bolt_x,
    "Center bolt layout invalid; adjust outer_bolt_inset_from_groove.");

assert(reinforcement_bar_width <= bridge_width,
    "Reinforcement bar does not fit within bridge_width.");

assert(reinforcement_offset_from_clamp_face + reinforcement_slit_depth < shell_body_thickness,
    "Reinforcement slit does not fit within shell thickness.");

// ------------------------------------------------------------
// Helpers
// ------------------------------------------------------------
module rounded_rect_2d(sx, sy, r) {
    rr = min(max(r, 0), min(sx, sy) / 2);
    if (rr <= 0) {
        square([sx, sy], center = true);
    } else {
        offset(r = rr)
            square([sx - 2*rr, sy - 2*rr], center = true);
    }
}

module rounded_prism(sx, sy, sz, r) {
    linear_extrude(height = sz, center = true, convexity = 10)
        rounded_rect_2d(sx, sy, r);
}

module exact_rounded_rect_2d(sx, sy, r) {
    rr = min(max(r, 0), min(sx, sy) / 2 - eps);
    if (rr <= 0) {
        square([sx, sy], center = true);
    } else {
        offset(r = rr)
            offset(delta = -rr)
                square([sx, sy], center = true);
    }
}

module exact_rounded_prism(sx, sy, sz, r) {
    linear_extrude(height = sz, center = true, convexity = 10)
        exact_rounded_rect_2d(sx, sy, r);
}

module rect_prism(sx, sy, sz) {
    cube([sx, sy, sz], center = true);
}

module hex_prism_af(af, h) {
    cylinder(h = h, r = af / sqrt(3), $fn = 6, center = true);
}

module pocket_cut_at(px) {
    translate([px, 0, shell_body_thickness/2 - (clamp_inset_per_shell + bracket_depth_clearance)/2 + eps])
        rect_prism(
            clamp_zone_depth + bracket_width_clearance,
            groove_width + bracket_width_clearance,
            clamp_inset_per_shell + bracket_depth_clearance + 2*eps
        );
}

module reinforcement_channel_at(py) {
    translate([
        0,
        py,
        shell_body_thickness/2 - reinforcement_offset_from_clamp_face - reinforcement_slit_depth/2
    ])
        rect_prism(
            reinforcement_bar_length,
            reinforcement_bar_width + reinforcement_width_clearance,
            reinforcement_slit_depth + 2*eps
        );
}

module reinforcement_channel_cuts(part) {
    if (reinforcement_enable) {
        reinforcement_channel_at(reinforcement_channel_y);
    }
}

module center_bolt_positions() {
    translate([left_bolt_x, 0, 0]) children();
    translate([center_bolt_x, 0, 0]) children();
    translate([right_bolt_x, 0, 0]) children();
}

module lip_bolt_positions() {
    translate([left_lip_bolt_x, 0, 0]) children();
    translate([right_lip_bolt_x, 0, 0]) children();
}

module center_bolt_clear_cuts() {
    center_bolt_positions()
        cylinder(h = shell_body_thickness + 2*eps, d = m3_clear_d, center = true);
}

module lip_bolt_clear_cuts() {
    lip_bolt_positions()
        cylinder(h = shell_body_thickness + 2*eps, d = m3_clear_d, center = true);
}

module center_bolt_head_recess_cuts() {
    center_bolt_positions()
        translate([0, 0, -shell_body_thickness/2 + m3_head_depth/2 + eps])
            cylinder(h = m3_head_depth + 2*eps, d = m3_head_d, center = true);
}

module lip_bolt_head_recess_cuts() {
    lip_bolt_positions()
        translate([0, 0, -shell_body_thickness/2 + m3_head_depth/2 + eps])
            cylinder(h = m3_head_depth + 2*eps, d = m3_head_d, center = true);
}

module center_bolt_nut_trap_cuts() {
    center_bolt_positions()
        translate([0, 0, -shell_body_thickness/2 + m3_nut_depth/2 + eps])
            hex_prism_af(m3_nut_af + m3_nut_clearance, m3_nut_depth + 2*eps);
}

module lip_bolt_nut_trap_cuts() {
    lip_bolt_positions()
        translate([0, 0, -shell_body_thickness/2 + m3_nut_depth/2 + eps])
            hex_prism_af(m3_nut_af + m3_nut_clearance, m3_nut_depth + 2*eps);
}

// ------------------------------------------------------------
// One shell
// ------------------------------------------------------------
module shell_blank() {
    exact_rounded_prism(overall_length, bridge_width, shell_body_thickness, bridge_corner_r);
}

module shell(part = "top") {
    difference() {
        shell_blank();
        pocket_cut_at(left_pocket_x);
        pocket_cut_at(right_pocket_x);
        reinforcement_channel_cuts(part);
        center_bolt_clear_cuts();
        lip_bolt_clear_cuts();

        if (part == "top") {
            center_bolt_head_recess_cuts();
            lip_bolt_head_recess_cuts();
        } else if (part == "bottom") {
            center_bolt_nut_trap_cuts();
            lip_bolt_nut_trap_cuts();
        }
    }
}

module bracket_preview() {
    color([0.65, 0.68, 0.72, 1.0]) {
        translate([left_pocket_x, 0, 0])
            rect_prism(clamp_zone_depth, groove_width, bracket_thickness);

        translate([right_pocket_x, 0, 0])
            rect_prism(clamp_zone_depth, groove_width, bracket_thickness);
    }
}

module assembly() {
    if (show_bracket_preview) {
        bracket_preview();
    }

    color([0.92, 0.63, 0.28, 0.95])
        translate([0, 0, -bracket_thickness/2 - shell_body_thickness/2])
            shell("bottom");

    color([0.82, 0.47, 0.19, 0.95])
        translate([0, 0, bracket_thickness/2 + shell_body_thickness/2])
            mirror([0, 0, 1])
                shell("top");
}

// ------------------------------------------------------------
// Output
// ------------------------------------------------------------
if (render_part == "top") {
    shell("top");
} else if (render_part == "bottom") {
    shell("bottom");
} else {
    assembly();
}
