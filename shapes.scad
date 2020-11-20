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
module starcyl(h, r, points, depth, twist)
{
    r1 = r;
    r2 = r + depth;
    a1 = 360/points;
    a2 = a1/2;

    pts = [ for (i = [0 : points-1])
        let (a = i*a1,ap = a+a2)
        each [ [r1*cos(a), r1*sin(a)],
              [r2*cos(ap), r2*sin(ap)] ]
    ];

    //echo(pts);

    linear_extrude(height=h, twist=twist)
    polygon(pts);
}

/*
 * Cone version of star
 */
module starcone(h, r, points, depth, twist)
{
    /* DIY extrude */

    if (depth == 0) {
        cylinder(h=h, r1=r, r2=0, center=false, $fn=points);
    } else {

        a1 = 360/points;
        a2 = a1/2;
        slices = (h > twist ? h : twist)/ 2;
        zstep = h / slices;
        astep = -twist / slices;
        rstep = r / slices;
        dstep = depth / slices;

        echo("a1: ", a1, "a2: ", a2, "slices: ", slices, "zstep: ", zstep, "astep: ", astep);

        pts = [
            for (zi = [0 : slices])
                let (z = zi * zstep,            // slice
                     a = zi * astep,            // twist offset
                     r1 = r - zi * rstep,       // radius at current slice
                     r2 = r1 + depth - zi * dstep)  // outer radius
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
}

/*
 * Cone shell version of star
 */
module starcone_shell(h, r, wall, points, depth, twist)
{
    /* DIY extrude */

    a1 = 360/points;
    a2 = a1/2;
    slices = (h > twist ? h : twist)/ 2;
    zstep = h / slices;
    astep = -twist / slices;
    rstep = r / slices;
    dstep = depth / slices;
    hy = sqrt(r*r + h*h);
    xw = wall * hy / h;

    echo("a1: ", a1, "a2: ", a2, "slices: ", slices, "zstep: ", zstep, "astep: ", astep);

    pts = [
        for (zi = [0 : slices-1])
            let (z = zi * zstep,                // slice
                 a = zi * astep,                // twist offset
                 r1 = r - zi * rstep,           // radius at current slice
                 r2 = r1 + depth - zi * dstep,  // outer radius
                 rc = r1 - xw)                  // inner wall
            for (i = [0 : points - 1])          // 
                let (ai = a + i*a1, ap = ai+a2,
                    cosai=cos(ai), sinai=sin(ai),
                    cosap=cos(ap), sinap=sin(ap))
                each [
                    [r1*cosai, r1*sinai, z],
                    [r2*cosap, r2*sinap, z],
                    rc > 0? ([rc*cosai, rc*sinai, z]):([0, 0, z]),
                    rc > 0? ([rc*cosap, rc*sinap, z]):([0, 0, z])
                ],
        // top slice is all the terminal point
        for (i = [0 : points - 1])
            each [[0, 0, h], [0, 0, h], [0, 0, h], [0, 0, h]]
    ];
    //echo(pts);

    // stitch points into paths

    paths = [
        // outer faces
        for (zi = [0 : slices-1])
            let (b0 = zi * 4 * points,
                 b1 = b0 + 4 * points)
            for (i = [0 : points-1])
                let (i0=4*i, i1=i0+1, i2=i0+2, i3=i0+3,
                     i4=(i0+4) % (4*points))
                if (zi == slices-1)
                    // top slice is all [0, 0, h]
                    each [
                        [b0+i0, b0+i1, b1+i1, b0+i0],
                        [b1+i1, b0+i1, b0+i4, b1+i1]
                    ]
                else
                    each [
                        [b0+i0, b0+i1, b1+i1, b1+i0, b0+i0],
                        [b1+i1, b0+i1, b0+i4, b1+i4, b1+i1]
                    ],
/* */

        // interior faces
        for (zi = [0 : slices-1])
            let (b0 = zi * 4 * points,
                 b1 = b0 + 4 * points)
            for (i = [0 : points-1])
                let (i0=4*i, i2=i0+2, i3=i0+3,
                     i4=(i0+4) % (4*points), i6=i4+2)
                if (pts[b0+i2][0] != 0 || pts[b0+i2][1] != 0)
                    if (pts[b1+i2][0] == 0 && pts[b1+i2][1] == 0) 
                        // close the top
                        each [
                            [b1+i2, b0+i3, b0+i2],
                            [b1+i2, b0+i6, b0+i3]
                        ]
                    else
                        each [
                            [b0+i2, b1+i2, b1+i3, b0+i3, b0+i2],
                            [b0+i3, b1+i3, b1+i6, b0+i6, b0+i3]
                        ],

        // bottom wall
        for (i = [ 0 : points-1 ])
            let (i0=4*i, i1=i0+1, i2=i0+2, i3=i0+3,
                 i4=(i0+4) % (4*points), i6=i4+2)
            //[i0, i1, i4, i6, i3, i2, i0]
            //[i0, i2, i3, i6, i4, i1, i0]
            each[[i0, i2, i3], [i0, i3, i1], [i3, i6, i4], [i3, i4, i1]]
            //each[[i0, i3, i2], [i0, i1, i3], [i3, i4, i6], [i3, i1, i4]]

/* */
    ];

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

/*
 * Vertical sine wave stripes on a cylinder
 */
module _cyl_gravy_vert(r, h, angle, wall, wscale, cycles, offset=0, backfill=false, fy=4)
{
    atotal = 360 * cycles;
    steps = h * fy;
    as = atotal / steps;

    rInner = r - wscale - wall;
    rOuter = r - wscale;

    pts = [
        for (i = [0 : steps])
            let(y = i / fy,
                am = i * as + offset,
                sinam = wscale * sin(am),
                rin = rInner + (backfill? -wscale : sinam),
                rout = rOuter + sinam
            )
            each [ [rin, y], [rout, y] ]
        ];

    paths = [
        for (i = [0 : steps-1])
            let (base = 2*i)
            [ base, base + 1, base + 3, base + 2]
        ];

    rotate_extrude(angle=angle)
    polygon(pts, paths);
}

/*
 * _cyl_gravy_horz - horizontal stripes of basket weave on wall of cylinder
 *
 * r - outside radius
 * h - height will be truncated to ribbon count
 * wscale - weave depth multiplier
 * cycles - cycles in circumference
 * twist - just in case
 * backfill - t/f
 *
 */
module _cyl_gravy_horz(r, h, wall, wscale, cycles, twist=0, backfill=false, fy=4)
{
    // reasonable resolution?
    //steps = 30 * cycles;
    steps = 2 * PI * r * fy;

    as = 360/steps;
    ws = cycles * as;

    rInner = r - wscale - wall;
    rOuter = r - wscale;

    //modulate a cylinder with a sin wave

    pts = [
        for (i = [0 : steps])
            let(a = i * as,
                am = i * ws,
                sinam = wscale * sin(am),
                rin = rInner + (backfill? -wscale : sinam),
                rout = rOuter + sinam,
                cosa = cos(a),
                sina = sin(a)
                )
            each [
                [rin * cosa, rin * sina],
                [rout * cosa, rout * sina]
            ]
        ];

    paths = [
        for (i = [0 : steps - 1])
            let(base = 2 * i)
            [base, base + 1, base + 3, base + 2]
    ];

    //echo(pts);

    linear_extrude(height=h, twist=twist)
    polygon(pts, paths);
}

/*
 * _layer - make ribbons into a layer of weave
 *
 * Alternate original and z-mirrored object
 * on n*width Y boundaries, staggered on X by 
 * offset.
 *
 * children(0) - base object
 */
module _layer(count, width, offset)
{
    for (i = [ 0 : count-1 ]) {
        translate([0, 2*i * width, 0]) {
            children(0);
            
            translate([0, width, 0])
            mirror([0,0,1])
                children(0);
        }
    }
}

/*
 * _weave - make a mesh from a wavy ribbon
 *
 * duplicate a layer, rotate one, overlay them
 *
 * width    space used per ribbon
 * gap      space between ribbons
 * period   period of sin wave
 * cycles   number of sin cycles in ribbon
 * count    width of fabric in ribbons
 */
module _weave(width, gap, period, cycles, count)
{
    _layer(count=count/2, width=width+gap, offset=period/2)
    translate([0, width + gap/2, 0])
    rotate([90, 0, 0])
        children(0);
    
    translate([gap/2, period*cycles, 0])
    rotate([0,0,-90])
    _layer(count=count/2, width=width+gap, offset=period/2)
    translate([0, width, 0])
    rotate([90, 0, 0])
        children(0);
}

/*
 * weave - make a mesh
 *
 * Make a wavy ribbon, then pass it to _weave to process
 *
 * yscale   height of sin wave (center of ribbon)
 * gap      space between ribbons
 * period   period of sin wave
 * cycles   number of sin cycles to emit
 * count    width of fabric in ribbons
 * wall     thickness of ribbon
 */
module weave(yscale, gap, period, cycles, count, wall)
{
    width = period/2 - gap;

    _weave(width=width,gap=gap,period=period,cycles=cycles,count=count)
    gravy(wall=wall,
          width=width,
          yscale=yscale,
          period=period,
          cycles=cycles);
}

/*
 * disc_weave - make a weave to fill a cylindrical space
 *
 * h    height of cylinder
 * r    radius
 * yscale   height of sin wave (center of ribbon)
 * gap      space between ribbons
 * period   period of sin wave
 * wall     thickness of ribbon
 *
 * width of ribbon is period/2 - gap
 */
module disc_weave(h, r, yscale, gap, period, wall)
{
    cycles = 2*ceil(r/period);
    count = 4*ceil(r/period);
    rc = period*cycles/2;
    
    intersection() {
        cylinder(h=h, r=r, center=true);
        translate([-rc, -rc, 0])
            weave(yscale=yscale,
                  gap=gap,
                  period=period,
                  cycles=cycles,
                  count=count,
                  wall=wall);
    }
}

module stackrings(count, width, rotate)
{
    for (i = [0 : count - 1]) {
        translate([0, 0, i* width])
        rotate([0, 0, i* rotate])
        children(0);
    }
}

/*
 * vstripe
 * 
 * Take any number of children, and stripe
 * them around the z axis.
 *
 * rotate - angle per stripe
 * angle - total rotation (default 360)
 */
module vstripe(rotate, angle=360)
{
    count = angle/rotate;
    for (i = [0 : count - .01]) {
        rotate([0, 0, i * rotate])
        children(i % $children);
    }
}

module cyl_weave(r, h, wwall, wscale, wcycles, wgap, backfill=false, fy=.25)
{
    vStripes = 2 * wcycles;
    stripeWidth = 2 * PI * r / vStripes;
    hStripes = floor(h / stripeWidth);
    vHeight = hStripes * stripeWidth;

    stackrings(count=hStripes,
               width=stripeWidth,
               rotate=360 / wcycles / 2)
        _cyl_gravy_horz(r=r,
                        h=stripeWidth - wgap,
                        wall=wwall,
                        wscale=wscale,
                        cycles=wcycles,
                        backfill=backfill,
                        fy=fy);

    vwide = 2 * r * PI / vStripes;
    av = 360/vStripes;
    av1 = av - av*wgap/vwide;

    vstripe(rotate=360/wcycles/2) {
        _cyl_gravy_vert(r=r,
                        h=vHeight,
                        angle=av1,
                        wall=wwall,
                        wscale=wscale,
                        cycles=hStripes/2,
                        offset=180,
                        backfill=backfill,
                        fy=fy);
        _cyl_gravy_vert(r=r,
                        h=vHeight,
                        angle=av1,
                        wall=wwall,
                        wscale=wscale,
                        cycles=hStripes/2,
                        offset=0,
                        backfill=backfill,
                        fy=fy);
    }
}

