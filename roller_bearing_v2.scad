$fn=100;

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

// Prioritize roller distance
// Calculate ideal number of rollers
actual_roller_space=roller_space_total-2*min_wall_thick;
new_r=(actual_roller_space/2);
roller_arclen=4*roller_dist_r*(3.1416/180)*asin( new_r/(2*roller_dist_r) );
num_rollers=floor(roller_dist_circum/roller_arclen)+1;

// Solving for ideal roller radius (num_rollers*arclen=circum, so solve for roller radius (which is in arclen equation))
roller_top_bottom_r=2*roller_dist_r*sin((180/3.1416)*roller_dist_circum/(4*num_rollers*roller_dist_r))+(half_gap/4);

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

module rollerHalf(segment=-1) {
    if (segment==-1) {
        union() {
            rollerTop(hasGap=true);
            rollerTopMid(hasGap=true);
        }
    } else if (segment==0) {
        rollerTop();
    } else if (segment==1) {
        rollerTopMid();
    }
}

gap_res=60;
angle_from_res=360/gap_res;
module rollerGapHalf() {
    union() {
    for (i=[0:gap_res-1]) {
        x1=roller_dist_r*cos(i*angle_from_res);
        y1=roller_dist_r*sin(i*angle_from_res);
        x2=roller_dist_r*cos((i+1)*angle_from_res);
        y2=roller_dist_r*sin((i+1)*angle_from_res);
        
        // Separately hull each part of the roller
        for (j=[0:1]) {
            hull() {
                translate([x1,y1,0])
                    rollerHalf(j);
                translate([x2,y2,0])
                    rollerHalf(j);
            }
        }
    }
}
}

module rollerGap() {
    union() {
    rollerGapHalf();
    translate([0,0,bearing_h]) scale([1,1,-1])
        rollerGapHalf();
    }
}

rotate_angle_deg=360/num_rollers;
module rollersHalf() {
    for (i=[0:num_rollers-1]) {
        x=roller_dist_r*cos(i*rotate_angle_deg);
        y=roller_dist_r*sin(i*rotate_angle_deg);
        translate([x,y,0])
        rollerHalf();
    }
}

module rollers() {
    union() {
    rollersHalf();
    translate([0,0,bearing_h]) scale([1,1,-1])
        rollersHalf();
    }
}

module bearing() {
    difference() {
    bearingShell();
    rollerGap();
    }
    rollers();
}


difference() {
bearing();
    /*
translate([0,0,50+bearing_h/4])
cube(100, center=true);*/
}
