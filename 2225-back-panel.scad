
base_width = 320.0 + 0.25;  // measured mm, plus tweak after fitting
base_height = 123.5;  // measured mm
sleeve_depth = 15.0;  // chosen, overkill
general_thickness = 2.0;  // chosen
sleeve_thickness = 3;
back_face_depth = 12;  // chosen
sleeve_corner_round_radius = 2.5;  // measured mm

mounting_screw_x_inset = 22;  // measured
mounting_screw_hole_diameter = 4;  // #6 thread
mounting_screw_countersink_diameter = 10;  // overkill
mounting_screw_plate_depth = 3.0;  // chosen BUT NOT WELL
mounting_inset_thick = 5;
mounting_inset_width = 25;
mounting_inset_round = 6;

hook_width = 15;
hook_height = 10;
hook_depth = 4;
hook_y_inset = 5;  // measured mm

plate_start = 35;   // measured mm
plate_end = 134;  // measured mm
plate_depth = 8;  // measured mm

line_cord_start = 160.0;
line_cord_end = 190.0;
line_cord_y_clearance = 12.0;

crt_diameter = 70;  // measured mm, not used
crt_clearance_diameter = 75;  // picked
crt_depth = 10.21;  // measured mm, not used
crt_clearance_depth = 12;  // picked
crt_center_from_left = base_width - 70;  // measured mm

side_panel_screw_from_back = 11.5;

case_seam_width = 30;  // measured mm, generous overestimate
case_seam_thick = 1.2;

vent_slot_y_size = 20;
vent_spacing = 10;

epsilon = 0.01;
total_depth = sleeve_depth + back_face_depth;

cutaway_y = line_cord_y_clearance;
cutaway_height = base_height - line_cord_y_clearance * 2;

plastic_tab_from_left_1 = 128;
plastic_tab_from_left_2 = 197;
plastic_tab_clearance_size = [15, 7, 4];

two_pieces_flip();


module two_pieces_flip() {
    rotate([180, 0, 0])
    x_cut((line_cord_start + line_cord_end) / 2)
    main_one_piece();
}

module transition(x1, x2) {
    d = sign(x2 - x1);
    translate([x1, cutaway_y, 0])
    scale([1, -1, 1])
    rotate([90, 0, 0]) {
        linear_extrude(height=cutaway_height)
        polygon([
            [0, -epsilon],
            [x2 - x1, back_face_depth],
            [x2 - x1 + d*epsilon, back_face_depth],
            [x2 - x1 + d*epsilon, -epsilon]]);
        translate([0, 0, 0])
        linear_extrude(height=cutaway_height)
        polygon([
            [-d*epsilon, sleeve_thickness],
            [-d*epsilon, back_face_depth + sleeve_thickness + epsilon * 2],
            [x2 - x1, back_face_depth + sleeve_thickness + epsilon * 2],
            [x2 - x1 + epsilon, back_face_depth + sleeve_thickness + epsilon * 2],
            [0, sleeve_thickness]]);
    }
}

module roundcube_sphere(radius, size) {
    minkowski() {
        translate([radius, radius, radius])
        cube(size - [radius, radius, radius] * 2);
        sphere(r=radius);
    }
}

module roundcube_cylinder(radius, size) {
    minkowski() {
        translate([radius, radius, radius])
        cube(size - [radius, radius, radius] * 2);
        cylinder(r=radius, h=radius * 2, center=true, $fn=16);
    }
}

module left_mounting_screw_negative() {
    translate([mounting_screw_x_inset, base_height / 2, -epsilon])
    cylinder(d=mounting_screw_hole_diameter, h=total_depth);

    // countersink
    translate([mounting_screw_x_inset, base_height / 2, mounting_screw_plate_depth])
    cylinder(d=mounting_screw_countersink_diameter, h=total_depth);
    
    // add'l material clearance
    translate([mounting_inset_thick, mounting_inset_thick, mounting_inset_thick])
    roundcube_sphere(mounting_inset_round, [mounting_inset_width, base_height - mounting_inset_thick * 2, back_face_depth * 2]);
    
    // mounting hook
    translate([mounting_screw_x_inset - hook_width / 2, hook_y_inset, -epsilon])
    cube([hook_width, hook_height, hook_depth + epsilon]);
    
    // side panel attachment screws
    translate([0, base_height / 2, -side_panel_screw_from_back])
    rotate([0, -90, 0])
    hull() {
        screw_cutout_negative();
        translate([-1000, 0, 0])
        screw_cutout_negative();
    }
}

module screw_cutout_negative() {
    // diameter oversized for positioning error
    translate([0, 0, -epsilon])
    cylinder(d=12, h=5);
}

module foot_socket() {
    foot_dia = 14;
    wall = 1;
    depth = 2;
    corner_inset = 8;
    translate([corner_inset, 0, back_face_depth - corner_inset])
    rotate([90, 0, 0]) 
    scale([1, 1, 1]) {
        cylinder(d=foot_dia + wall * 2 + depth * 2, h=sleeve_thickness, $fn=32);

        translate([0, 0, sleeve_thickness]) 
        difference() {
            cylinder(d1=foot_dia + wall * 2 + depth * 2, d2=foot_dia + wall * 2, h=depth, $fn=32);
            cylinder(d=foot_dia, h=depth + epsilon, $fn=32);
        }
    }
}

module vertical_slot(x) {
    translate([x, -general_thickness * 2, 0])
        cube([general_thickness, vent_slot_y_size + sleeve_thickness * 2, back_face_depth * 3 - sleeve_thickness]);
    translate([x, base_height - vent_slot_y_size, 0]) 
        cube([general_thickness, vent_slot_y_size + sleeve_thickness * 2, back_face_depth * 3 - sleeve_thickness]);
}

module plastic_tab_clearance(x) {
        translate([x - plastic_tab_clearance_size.x / 2, base_height, -epsilon])
        mirror([0, 1, 0])
        #cube(plastic_tab_clearance_size);
}

module main_one_piece() {
    crt_area_start = crt_center_from_left - crt_clearance_diameter / 2;
    
    // 45 degree slopes
    before_line_cord = max(plate_end, line_cord_start - back_face_depth);
    after_line_cord = min(crt_area_start, line_cord_end + back_face_depth);
    
    difference() {
        union() {
            // sleeve & surround
            translate([0, 0, -sleeve_depth + sleeve_thickness])
            minkowski() {
                roundcube_cylinder(sleeve_corner_round_radius, [
                    base_width,
                    base_height,
                    total_depth - sleeve_thickness]);
                sphere(r=sleeve_thickness);
            }
            
            // rubber foot cutout
            foot_socket();
            translate([base_width, 0, 0]) mirror([1, 0, 0]) foot_socket();
        }
        
        // hollow in sleeve for main body
        color("white")
        translate([0, 0, -sleeve_depth - epsilon])
          roundcube_cylinder(sleeve_corner_round_radius, [base_width, base_height, sleeve_depth + epsilon]);
        
        // mounting screws & matching things
        left_mounting_screw_negative();
        translate([base_width, 0, 0]) mirror([1, 0, 0]) left_mounting_screw_negative();
        
        // power transformer plate
        // using before_line_cord instead of plate_end to line up
        translate([plate_start, 0, -epsilon]) cube([before_line_cord - plate_start, base_height, max(plate_depth, back_face_depth) + epsilon]);
        
        // thinning out line cord area
        translate([line_cord_start, cutaway_y, sleeve_thickness]) cube([line_cord_end - line_cord_start, cutaway_height, back_face_depth + epsilon]);
        
        // hole punch for line cord (rough, not exact fitting)
        translate([line_cord_start, line_cord_y_clearance, -epsilon]) cube([line_cord_end - line_cord_start, base_height - line_cord_y_clearance * 2, back_face_depth + epsilon]);
        
        // CRT end -- fallback enforce-clearance
        translate([crt_center_from_left, base_height / 2, -epsilon])
            cylinder(r=crt_clearance_diameter / 2, h=crt_clearance_depth + epsilon);
        // CRT end -- broad material clearing
        translate([after_line_cord, 0, -epsilon]) cube([crt_clearance_diameter - after_line_cord + crt_area_start, base_height, back_face_depth + epsilon]);
        
        // ventilation slots
        for (i = [plate_start + 5/*fudge*/:vent_spacing:plate_end]) {
            vertical_slot(i);
        }
        for (i = [-crt_diameter / 2 + 5/*fudge*/:vent_spacing:crt_diameter / 2]) {
            vertical_slot(crt_center_from_left + i);
        }
        
        transition(line_cord_start, before_line_cord);
        transition(line_cord_end, after_line_cord);
        
        // heatsink screw near plate
        translate([31, 31.2, 0])
        screw_cutout_negative();
        // heatsink screws near crt
        translate([base_width - 27.51, 17.45, 0]) {
            screw_cutout_negative();
            translate([-25.2, 0, 0])
            screw_cutout_negative();
        }
        
        // plastic tabs sticking out back
        plastic_tab_clearance(plastic_tab_from_left_1);
        plastic_tab_clearance(plastic_tab_from_left_2);
        
        // case overlap seam
        translate([base_width / 2 - case_seam_width / 2, -case_seam_thick + epsilon, -sleeve_depth])
        cube([case_seam_width, case_seam_thick, sleeve_depth]);
        
        // don't have spaces for those upper side plastic frame tabs -- no, not needed as long as we are doing the 'airy' version
    }
}

// --- generic helpers 

module x_cut(x) {
    translate([1, 0, 0])
    intersection() {
        translate([x, 0, 0]) x_face();
        children();
    }
    
    translate([-1, 0, 0])
    difference() {
        children();
        translate([x, 0, 0]) x_face();
    }
}

module x_face() {
    zag = 3;
    
    translate([zag / 2, -5000, -5000])
    cube([10000, 10000, 10000]);
    
    for (i = [-10:zag * 2:400]) {
        translate([zag / 2, i, 0])
        cylinder(r=zag, h=10000, center=true, $fn=4);
    }
}