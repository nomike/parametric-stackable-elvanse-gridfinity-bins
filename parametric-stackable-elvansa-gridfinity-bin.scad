use <gridfinity-rebuilt-openscad/src/core/gridfinity-rebuilt-utility.scad>
use <gridfinity-rebuilt-openscad/src/core/gridfinity-rebuilt-holes.scad>
include <gridfinity-rebuilt-openscad/src/core/standard.scad>

// ===== PARAMETERS ===== //

/* [Setup Parameters] */
$fn = 128;
epsilon = 0.001;

/* [General Settings] */
// number of bases along x-axis
gridx = 1;
// number of bases along y-axis
gridy = 1;
// bin height. See bin height information and "gridz_define" below.
gridz = 64; //.1

/* [Linear Compartments] */
// number of X Divisions (set to zero to have solid bin)
divx = 0;
// number of Y Divisions (set to zero to have solid bin)
divy = 0;

/* [Cylindrical Compartments] */
// number of cylindrical X Divisions (mutually exclusive to Linear Compartments)
cdivx = gridx;
// number of cylindrical Y Divisions (mutually exclusive to Linear Compartments)
cdivy = gridy;
// orientation
c_orientation = 2; // [0: x direction, 1: y direction, 2: z direction]
// diameter of cylindrical cut outs
cd = 37.7; // .1
// cylinder height
ch = 84;  //.1
// spacing to lid
c_depth = 1;
// chamfer around the top rim of the holes
c_chamfer = 0.5; // .1
c_fillet_radius = 4; // .1

/* [Height] */
// determine what the variable "gridz" applies to based on your use case
gridz_define = 1; // [0:gridz is the height of bins in units of 7mm increments - Zack's method,1:gridz is the internal height in millimeters, 2:gridz is the overall external height of the bin in millimeters]
// overrides internal block height of bin (for solid containers). Leave zero for default height. Units: mm
height_internal = 0;
// snap gridz height to nearest 7mm increment
enable_zsnap = true;

/* [Features] */
// the type of tabs
style_tab = 0; //[0:Full,1:Auto,2:Left,3:Center,4:Right,5:None]
// which divisions have tabs
place_tab = 0; // [0:Everywhere-Normal,1:Top-Left Division]
// how should the top lip act
style_lip = 0; //[0: Regular lip, 1:remove lip subtractively, 2: remove lip and retain height]
// scoop weight percentage. 0 disables scoop, 1 is regular scoop. Any real number will scale the scoop.
scoop = 0; //[0:0.1:1]

/* [Base Hole Options] */
// only cut magnet/screw holes at the corners of the bin to save uneccesary print time
only_corners = false;
//Use gridfinity refined hole style. Not compatible with magnet_holes!
refined_holes = true;
// Base will have holes for 6mm Diameter x 2mm high magnets.
magnet_holes = false;
// Base will have holes for M3 screws.
screw_holes = false;
// Magnet holes will have crush ribs to hold the magnet.
crush_ribs = true;
// Magnet/Screw holes will have a chamfer to ease insertion.
chamfer_holes = true;
// Magnet/Screw holes will be printed so supports are not needed.
printable_hole_top = true;
// Enable "gridfinity-refined" thumbscrew hole in the center of each base: https://www.printables.com/model/413761-gridfinity-refined
enable_thumbscrew = false;

hole_options = bundle_hole_options(refined_holes, magnet_holes, screw_holes, crush_ribs, chamfer_holes, printable_hole_top);

cutout_width = 17.5; // .1

/* [Hidden] */
base_height = 6.95;
lip_height = 4.55;

module cutout(cutout_width) {
    translate([-GRID_DIMENSIONS_MM[0]/2 - epsilon, -cutout_width/2, 0])
    cube([GRID_DIMENSIONS_MM[0] + (2 * epsilon), cutout_width, height(gridz, gridz_define, style_lip, enable_zsnap) + epsilon + lip_height]);
    translate([-cutout_width/2, -GRID_DIMENSIONS_MM[1]/2 - epsilon, 0])
    cube([cutout_width, GRID_DIMENSIONS_MM[1] + (2 * epsilon), height(gridz, gridz_define, style_lip, enable_zsnap) + epsilon + lip_height]);
}

x_offset = ((gridx % 2) ? 0 : GRID_DIMENSIONS_MM[0] / 2) - floor(gridx / 2) * GRID_DIMENSIONS_MM[0];
y_offset = ((gridy % 2) ? 0 : GRID_DIMENSIONS_MM[1] / 2) - floor(gridy / 2) * GRID_DIMENSIONS_MM[1];


// ===== IMPLEMENTATION ===== //
difference() {
    union() {
        union() {
            gridfinityInit(gridx, gridy, height(gridz, gridz_define, style_lip, enable_zsnap), height_internal, sl=style_lip) {

                if (divx > 0 && divy > 0) {

                    cutEqual(n_divx = divx, n_divy = divy, style_tab = style_tab, scoop_weight = scoop, place_tab = place_tab);

                } else if (cdivx > 0 && cdivy > 0) {

                    cutCylinders(n_divx=cdivx, n_divy=cdivy, cylinder_diameter=cd, cylinder_height=ch, coutout_depth=c_depth, orientation=c_orientation, chamfer=c_chamfer);
                }
            }
            gridfinityBase([gridx, gridy], hole_options=hole_options, only_corners=only_corners, thumbscrew=enable_thumbscrew);
        }
        
        // fillet
        color("Tomato") translate([x_offset, y_offset, base_height]) union() {
            for (j = [0:gridy-1]) {
                for (i = [0:gridx-1]) {
                    translate([i*GRID_DIMENSIONS_MM[0] - epsilon, j*GRID_DIMENSIONS_MM[1] - epsilon, 0]) {
                        difference() {
                            rotate_extrude(convexity = 10)
                            translate([(cd / 2) - c_fillet_radius, 0, 0]) square([c_fillet_radius, c_fillet_radius]);
                            rotate_extrude(convexity = 10)
                            translate([cd / 2 - c_fillet_radius, c_fillet_radius, epsilon]) circle(r=c_fillet_radius);
                        }
                    }
                }
            }
        }
    }

    // cutout
    color("Turquoise") translate([x_offset, y_offset, base_height + epsilon]) union() {
        for (j = [0:gridy-1])
            for (i = [0:gridx-1])
                translate([i*GRID_DIMENSIONS_MM[0], j*GRID_DIMENSIONS_MM[1], 0]) cutout(cutout_width);
    }
}
