
base_width = 320.0;  // measured mm
base_height = 123.0;  // measured mm
sleeve_depth = 15.0;  // chosen, overkill
general_thickness = 2.0;  // chosen
sleeve_thickness = general_thickness;
back_face_depth = 25.0;  // chosen

mounting_screw_x_inset = 22;  // measured
mounting_screw_hole_diameter = 2;  // NOT MEASURED
mounting_screw_countersink_diameter = 10;  // NOT MEASURED
mounting_screw_plate_depth = 4.0;  // chosen BUT NOT WELL

hook_width = 10;  // NOT MEASURED
hook_height = 10;
hook_depth = 10;
hook_y_inset = 5;  // measured mm

plate_start = 32;   // NOT MEASURED
plate_end = 134;  // measured mm
plate_depth = 15;  // NOT MEASURED

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

module left_mounting_screw_negative() {
    translate([mounting_screw_x_inset, base_height / 2, -epsilon]) cylinder(r=mounting_screw_hole_diameter, h=total_depth);

    // countersink 
    translate([mounting_screw_x_inset, base_height / 2, mounting_screw_plate_depth]) cylinder(r=mounting_screw_countersink_diameter, h=total_depth);
    
    // mounting hook
    translate([mounting_screw_x_inset, hook_y_inset, -epsilon]) cube([hook_width, hook_height, hook_depth + epsilon]);
}

module vertical_slot(x) {
    translate([x, -general_thickness * 2, 0])
        cube([general_thickness, vent_slot_y_size + sleeve_thickness * 2, back_face_depth * 3 - sleeve_thickness]);
    translate([x, base_height - vent_slot_y_size, 0]) 
        cube([general_thickness, vent_slot_y_size + sleeve_thickness * 2, back_face_depth * 3 - sleeve_thickness]);
}

difference() {
    // sleeve & surround
    translate([0, 0, -sleeve_depth + sleeve_thickness])
    minkowski() {
        cube([base_width, base_height, total_depth - sleeve_thickness * 2]);
        sphere(r=sleeve_thickness);
    }
    // hollow in sleeve for main body
    color("white")
    translate([0, 0, -sleeve_depth - epsilon])
      cube([base_width, base_height, sleeve_depth + epsilon]);
    
    // mounting screws & matching things
    left_mounting_screw_negative();
    translate([base_width, 0, 0]) mirror([1, 0, 0]) left_mounting_screw_negative();
    
    // power transformer plate
    translate([plate_start, 0, -epsilon]) cube([plate_end - plate_start, base_height, plate_depth + epsilon]);
    
    // thinning out line cord area
    translate([line_cord_start, -2*sleeve_thickness, general_thickness]) cube([line_cord_end - line_cord_start, base_height + 4*sleeve_thickness, back_face_depth + epsilon]);
    
    // hole punch for line cord (NOT MEASURED IN ENOUGH DETAIL)
    translate([line_cord_start, line_cord_y_clearance, -epsilon]) cube([line_cord_end - line_cord_start, base_height - line_cord_y_clearance * 2, back_face_depth + epsilon]);
    
    // CRT end
    translate([crt_center_from_left, base_height / 2, -epsilon])
        cylinder(r=crt_clearance_diameter / 2, h=crt_clearance_depth + epsilon);
    
    // ventilation slots
    for (i = [plate_start:vent_spacing:plate_end]) {
        vertical_slot(i);
    }
    for (i = [-crt_diameter / 2:vent_spacing:crt_diameter / 2]) {
        vertical_slot(crt_center_from_left + i);
    }
    
    // TODO: spaces for those screws in one corner
    // TODO: holes for side-panel screws (do they pass through or do they need slide-in clearance?
    // TODO: spaces for those upper side plastic frame tabs
    // TODO: ventilation slots
}