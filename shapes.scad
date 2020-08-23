/*
 * shapes.scad
 *
 * Misc shapes
 *
 * (C)Copyright 2020 Kent Forschmiedt, All Rights Reserved
 * Licensed under Creative Commons
 */

module cyl_rounded(height, radius, redge, toponly=true, center=false,
                   fa=$fa, fs=$fs, fn=$fn)
{
    $fa=fa;
    $fs=fs;
    $fn=fn;

    translate([0,0,center? 0: height/2])
    difference() {
        cylinder(h=height, r=radius, center=true);

        translate([0,0,height/2 - redge])
        difference() {
            cylinder(h=redge+1, r=radius+redge, center=false);

            translate([0,0,-1])
                cylinder(h=redge+1, r=radius-redge, center=false);

            translate([0, 0, -redge+.01])
                cylinder(h=redge, r=radius, center=false);

            rotate_extrude() {
                translate([radius-redge, 0, 0])
                    circle(r=redge);
            }
        }
    }
}
 
module cyl_shell(h, r, wall, center=false)
{
    difference() {
        cylinder(h=h, r=r, center=center);
        translate([0,0,center?0:-1])
        cylinder(h=h+2, r=r-wall, center=center);
    }
}

/*
 * Make cylinder by extruding star
 */
module starcyl(height, radius, points, depth, twist)
{
    r1 = radius;
    r2 = radius + depth;
    a1 = 360/points;
    a2 = a1/2;

    pts = [ for (i = [0 : points-1])
        let (a = i*a1,ap = a+a2)
        each [ [r1*cos(a), r1*sin(a)],
              [r2*cos(ap), r2*sin(ap)] ]
    ];

    //echo(pts);

    linear_extrude(height=height, twist=twist)
    polygon(pts);
}

/*
 * Cone version of star
 */
module starcone(height, radius, points, depth, twist)
{
    /* DIY extrude */

    a1 = 360/points;
    a2 = a1/2;
    slices = (height > twist ? height : twist)/ 2;
    zstep = height / slices;
    astep = -twist / slices;

    echo("a1: ", a1, "a2: ", a2, "slices: ", slices, "zstep: ", zstep, "astep: ", astep);

    pts = [
        for (zi = [0 : slices])
            let (z = zi * zstep,
                 a = zi * astep,
                 r1 = radius - zi * radius/slices,
                 r2 = r1 + depth - zi * depth/slices)
            for (i = [0 : points])
                let (ai = a + i*a1, ap = ai+a2)
                each [
                    [r1*cos(ai), r1*sin(ai), z],
                    [r2*cos(ap), r2*sin(ap), z]
                ]
    ];
    //echo(pts);

    // stitch points into paths
    // every path is a parallelogram between adjacent layers
    // then close the bottom

    paths = concat([
        for (zi = [0 : slices-1])
            let (base = zi * 2 * (points+1),
                 b1 = base + 2 * (points+1))
            for (i = [0 : 2 * points - 1])
                [ base + i, b1 + i, b1 + i + 1, base + i + 1 ]
        ],
        [[for (i = [0: 2*points]) i ]]
    );

    polyhedron(points=pts, faces=paths);

}

/*
 * cone made by stacked extrusion
 */
module conish(height=160, radius=120, rc=4, step=5, fn=12)
{
    steps = floor(height/step);
    hstep = (radius-rc)/steps;
    
    for (i = [0: 1: steps]) {
        z = step * i;
        x = hstep * i;
        translate([0, 0, z])
        rotate_extrude(angle=360)
            translate([radius - x, 0, 0])
            circle(r=rc, $fn=fn);
    }
}

/*
 * make a sine wave
 */
module gravy(wall=2, 
             width=10,
             yscale=3,
             period=30,
             cycles=3)
{
    xscale = period / 360;
    steps = 360 * cycles * xscale;
    astep = 360 * cycles / steps;
    pts = concat(
        [ for (x = [0 : steps-1]) [x,yscale*sin(x*astep)+wall/2] ],
        [ for (x = [steps-1 : -1 : 0]) [x,yscale*sin(x*astep)-wall/2] ]
    );

    linear_extrude(height=width)
    polygon(pts);
}
