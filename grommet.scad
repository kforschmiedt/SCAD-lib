
/*
 * grommet - Put a screw grommet in something.
 *
 * h - height
 * r - radius
 * thickness - grommet wall
 * offset - location
 *
 * This will punch a hole through any number of objects
 */
module grommet(h, r, thickness, offset=[0,0,0], rotate=[0,0,0])
{
    if ($children == 0) {
        translate(offset)
        rotate(rotate)
        difference() {
            cylinder(h=h, r=r+thickness, center=true);
            cylinder(h=h+1, r=r, center=true);
        }
    } else if (r == 0) {
        children();
    } else {
        difference() {
            union() {
                translate(offset)
                rotate(rotate)
                    cylinder(h=h, r=r+thickness, center=true);
                children();
            }
            translate(offset)
                rotate(rotate)
                cylinder(h=h+1, r=r, center=true);
        }
    }
}

