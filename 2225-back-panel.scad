
base_width = 320.0;  // measured mm
base_height = 123.5;  // measured mm
sleeve_depth = 15.0;  // chosen, overkill
general_thickness = 2.0;  // chosen
sleeve_thickness = 3;
back_face_depth = 25.0;  // chosen

mounting_screw_x_inset = 22;  // measured
mounting_screw_hole_diameter = 4;  // #6 thread
mounting_screw_countersink_diameter = 10;  // overkill
mounting_screw_plate_depth = 3.0;  // chosen BUT NOT WELL
mounting_inset_thick = 5;
mounting_inset_width = 25;
mounting_inset_round = 10;

hook_width = 15;
hook_height = 10;
hook_depth = 5;
hook_y_inset = 5;  // measured mm

plate_start = 35;   // measured mm
plate_end = 134;  // measured mm
plate_depth = 8;  // measured mm

line_cord_start = 160.0;
line_cord_end = 190.0;
line_cord_y_clearance = 10.0;

crt_diameter = 70;  // measured mm, not used
crt_clearance_diameter = 75;  // picked
crt_depth = 10;  // measured mm, not used
crt_clearance_depth = 20;  // picked
crt_center_from_left = base_width - 70;  // measured mm

vent_slot_y_size = 50;
vent_spacing = 10;

epsilon = 1.0;
total_depth = sleeve_depth + back_face_depth;

module transition(x1, x2) {
    d = sign(x2 - x1);
    translate([x1, 0, 0])
    scale([1, -1, 1])
    rotate([90, 0, 0]) {
        linear_extrude(height=base_height)
        polygon([
            [0, -epsilon],
            [x2 - x1, back_face_depth],
            [x2 - x1 + d*epsilon, back_face_depth],
            [x2 - x1 + d*epsilon, -epsilon]]);
        translate([0, 0, -base_height / 4])
        linear_extrude(height=base_height * 2)
        polygon([
            [-d*epsilon, sleeve_thickness],
            [-d*epsilon, back_face_depth + sleeve_thickness + epsilon * 2],
            [x2 - x1, back_face_depth + sleeve_thickness + epsilon * 2],
            [x2 - x1 + epsilon, back_face_depth + sleeve_thickness + epsilon * 2],
            [0, sleeve_thickness]]);
    }
}

module roundcube(radius, size) {
    minkowski() {
        translate([radius, radius, radius])
        cube(size - [radius, radius, radius] * 2);
        sphere(r=radius);
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
    roundcube(mounting_inset_round, [mounting_inset_width, base_height - mounting_inset_thick * 2, back_face_depth * 2]);
    
    // mounting hook
    translate([mounting_screw_x_inset - hook_width / 2, hook_y_inset, -epsilon])
    cube([hook_width, hook_height, hook_depth + epsilon]);
}

module screw_cutout_negative() {
    // diameter oversized for positioning error
    translate([0, 0, -epsilon])
    cylinder(d=12, h=5);
}

module foot_socket() {
    depth = 2;
    corner_inset = 6;
    translate([corner_inset, 0, back_face_depth - corner_inset])
    rotate([90, 0, 0]) 
    scale([1, 1, 1])
    difference() {
        cylinder(d=16, h=sleeve_thickness + depth, $fn=32);
        translate([0, 0, sleeve_thickness])
        cylinder(d=14, h=depth + epsilon, $fn=32);
    }
}

module vertical_slot(x) {
    translate([x, -general_thickness * 2, 0])
        cube([general_thickness, vent_slot_y_size + sleeve_thickness * 2, back_face_depth * 3 - sleeve_thickness]);
    translate([x, base_height - vent_slot_y_size, 0]) 
        cube([general_thickness, vent_slot_y_size + sleeve_thickness * 2, back_face_depth * 3 - sleeve_thickness]);
}

difference() {
    union() {
        // sleeve & surround
        translate([0, 0, -sleeve_depth + sleeve_thickness])
        minkowski() {
            cube([base_width, base_height, total_depth - sleeve_thickness]);
            sphere(r=sleeve_thickness);
        }
        
        // rubber foot cutout
        foot_socket();
        translate([base_width, 0, 0]) mirror([1, 0, 0]) foot_socket();
    }
    
    // hollow in sleeve for main body
    color("white")
    translate([0, 0, -sleeve_depth - epsilon])
      cube([base_width, base_height, sleeve_depth + epsilon]);
    
    // mounting screws & matching things
    left_mounting_screw_negative();
    translate([base_width, 0, 0]) mirror([1, 0, 0]) left_mounting_screw_negative();
    
    // power transformer plate
    translate([plate_start, 0, -epsilon]) cube([plate_end - plate_start, base_height, max(plate_depth, back_face_depth) + epsilon]);
    
    // thinning out line cord area
    translate([line_cord_start, -2*sleeve_thickness, sleeve_thickness]) cube([line_cord_end - line_cord_start, base_height + 4*sleeve_thickness, back_face_depth + epsilon]);
    
    // hole punch for line cord (NOT MEASURED IN ENOUGH DETAIL)
    translate([line_cord_start, line_cord_y_clearance, -epsilon]) cube([line_cord_end - line_cord_start, base_height - line_cord_y_clearance * 2, back_face_depth + epsilon]);
    
    // CRT end -- fallback enforce-clearance
    translate([crt_center_from_left, base_height / 2, -epsilon])
        cylinder(r=crt_clearance_diameter / 2, h=crt_clearance_depth + epsilon);
    // CRT end -- broad material clearing
    translate([crt_center_from_left - crt_clearance_diameter / 2, 0, -epsilon]) cube([crt_clearance_diameter, base_height, back_face_depth + epsilon]);
    
    // ventilation slots
    for (i = [plate_start + 5/*fudge*/:vent_spacing:plate_end]) {
        vertical_slot(i);
    }
    for (i = [-crt_diameter / 2 + 5/*fudge*/:vent_spacing:crt_diameter / 2]) {
        vertical_slot(crt_center_from_left + i);
    }
    
    transition(line_cord_start, plate_end);
    transition(line_cord_end, crt_center_from_left - crt_clearance_diameter / 2);
    
    // heatsink screw near plate
    translate([31, 31.2, 0])
    screw_cutout_negative();
    // heatsink screws near crt
    translate([base_width - 27.51, 17.45, 0]) {
        screw_cutout_negative();
        translate([-25.2, 0, 0])
        screw_cutout_negative();
    }
    
    // TODO: holes for side-panel screws (do they pass through or do they need slide-in clearance?
    // TODO: spaces for those upper side plastic frame tabs -- no, not needed as long as we are doing the 'airy' version
}

