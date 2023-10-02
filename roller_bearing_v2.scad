/* NOTE: Looking back, I could have just designed the
 * lower half, negative scaled over the z axis, and
 *  translated to save on rendering time quite a lot.
 */
$fn=30;

// Bearing shell configs
bearing_h=7;
bearing_outer_dia=22;
bearing_inner_dia=8;
gap_size=0.4;
half_gap=gap_size/2;
bearing_outer_r=bearing_outer_dia/2;
bearing_inner_r=bearing_inner_dia/2;

// Roller configs
def_wall_size=true; // Change to define personal wall size
min_wall_thick=0.4;
roller_dist_r=(bearing_outer_r+bearing_inner_r)/2;
roller_h=bearing_h;
roller_space_total=(bearing_outer_r-bearing_inner_r);
roller_dist_circum = 2*3.1416*roller_dist_r;

/*
// Prioritize wall thickness
bearing_wall_thick=0.4;
actual_roller_space=roller_space_total-2*bearing_wall_thick;
new_r=(actual_roller_space/2);
roller_arclen=4*roller_dist_r*(3.1416/180)*asin( new_r/(2*roller_dist_r) );
num_rollers=floor(roller_dist_circum/roller_arclen);

roller_top_bottom_r=new_r;
*/

// Prioritize roller distance
    //TODO: Figure out how to automatically determine roller radius based on outer and inner dia!
// Calculate range of thicknesses to find best roller radius

actual_roller_space=roller_space_total-2*min_wall_thick;
new_r=(actual_roller_space/2);
roller_arclen=4*roller_dist_r*(3.1416/180)*asin( new_r/(2*roller_dist_r) );
num_rollers=floor(roller_dist_circum/roller_arclen)+1;

// Solving for ideal roller radius (num_rollers*arclen=circum, so solve for roller radius (which is in arclen equation))
roller_top_bottom_r=2*roller_dist_r*sin((180/3.1416)*roller_dist_circum/(4*num_rollers*roller_dist_r));

// The radius of the rollers is now optimized for the number of rollers that fit the gap best!

roller_middle_r=(roller_top_bottom_r*6)/10;


module wantCyl(r, h) {
    cylinder(h=h,r=r);
}


module bearingShell() {
    difference() {
    wantCyl(bearing_outer_r, bearing_h);
    wantCyl(bearing_inner_r, bearing_h);
    }
}

module rollerTop(hasGap=false) {
    if (hasGap) {
        translate([0,0,(bearing_h*3)/4])
        wantCyl(roller_top_bottom_r-half_gap,bearing_h/4);
    } else {
        translate([0,0,(bearing_h*3)/4])
        wantCyl(roller_top_bottom_r,bearing_h/4);
    }
}

module rollerTopMid(hasGap=false) {
    if (hasGap) {
        translate([0,0,bearing_h/2])
        cylinder(r2=roller_top_bottom_r-half_gap, r1=roller_middle_r-half_gap, h=bearing_h/4);
    } else {
        translate([0,0,bearing_h/2])
        cylinder(r2=roller_top_bottom_r, r1=roller_middle_r, h=bearing_h/4);
    }
} 

module rollerBottomMid(hasGap=false) {
    if (hasGap) {
        translate([0,0,bearing_h/4])
        cylinder(r1=roller_top_bottom_r-half_gap, r2=roller_middle_r-half_gap, h=bearing_h/4);
    } else {
        translate([0,0,bearing_h/4])
        cylinder(r1=roller_top_bottom_r, r2=roller_middle_r, h=bearing_h/4);
    }
}

module rollerBottom(hasGap=false) {
    if (hasGap) {
        wantCyl(roller_top_bottom_r-half_gap,bearing_h/4);
    } else {
        wantCyl(roller_top_bottom_r,bearing_h/4);
    }
}

module roller(segment=-1) {
    if (segment==-1) {
        union() {
            rollerTop(hasGap=true);
            rollerTopMid(hasGap=true);
            rollerBottomMid(hasGap=true);
            rollerBottom(hasGap=true);
        }
    } else if (segment==0) {
        rollerTop();
    } else if (segment==1) {
        rollerTopMid();
    } else if (segment==2) {
        rollerBottomMid();
    } else if (segment==3) {
        rollerBottom();
    }
}

gap_res=floor(5*$fn/6);
angle_from_res=360/gap_res;
module rollerGap() {
    union() {
    for (i=[0:gap_res-1]) {
        x1=roller_dist_r*cos(i*angle_from_res);
        y1=roller_dist_r*sin(i*angle_from_res);
        x2=roller_dist_r*cos((i+1)*angle_from_res);
        y2=roller_dist_r*sin((i+1)*angle_from_res);
        
        // Separately hull each part of the roller
        for (j=[0:3]) {
            hull() {
                translate([x1,y1,0])
                    roller(j);
                translate([x2,y2,0])
                    roller(j);
            }
        }
    }
}
}

rotate_angle_deg=360/num_rollers;
module rollers() {
    for (i=[0:num_rollers-1]) {
        x=roller_dist_r*cos(i*rotate_angle_deg);
        y=roller_dist_r*sin(i*rotate_angle_deg);
        translate([x,y,0])
        roller();
    }
}

module bearing() {
    difference() {
    union() {
    bearingShell();
    }
    rollerGap();
    }
    rollers();
}

difference() {
bearing();
//cube(100);
}
