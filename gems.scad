/*
 * gems.scad
 * Various gem shapes
 *
 * (C)Copyright 2020 Kent Forschmiedt, All Rights Reserved
 */

module gem(sides, ldiv, r)
{
    adiv = 360 / sides;
    ngram = [ for (a = [0 : adiv : 359])
                [r * cos(a), r * sin(a) ]];

    pts = concat(
        [ [0, 0, 0] ],
        [ for (i = [0 : sides-1])
                [ngram[i][0], ngram[i][1], ldiv[0]] ],
        [ [0, 0, ldiv[1]] ]);
        
    faces = [ for (i = [0 : sides-1])
                each [ [ 0, i+1, (i+1)%sides+1 ],
                       [ (i+1)%sides+1, i+1, sides+1 ] ]
    ];

    echo(pts);
    echo(faces);

    polyhedron(pts, faces);
}
