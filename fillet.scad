

module base_fillet(r1, r2, arc, h)
{
    // r1 is outside radius
    // r2 is torus radius
    // rI is radius to center of tube
    rI = r1 - r2;
    yoff = h + r2;
    
    // Arc
    shape = [ 
        for (a = [-90 : 2 : arc - 90])
            [rI + r2*cos(a), yoff + r2*sin(a)],
        [r1, h],
        [rI, h]
    ];

    rotate_extrude()
        polygon(shape);
}

base_fillet(50, 2, 70, 2);
