import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;

//! Draws the goat.
//!
//! Every feature is laid out in fractions of `S` - the shorter screen edge -
//! measured from the centre of the display, so the same code fills a 218x218
//! fenix and a 454x454 AMOLED with no per-device art. Filled shapes are kept
//! convex (ellipses, trapezoids, triangles) because that is what fillPolygon is
//! reliable with across the whole device range.
//!
//! Points go through mx()/my(), which apply the pose: a jitter plus a shear
//! hinged near the neck, so the head rocks in place rather than sliding sideways.
class GoatArtist {

    // The green steps are drawn in, shared with the STEPS data field so the ring
    // and the number under it are plainly the same measurement. Lands on
    // 0xAAFFAA in the 64-colour MIP palette.
    static const STEP_INK = 0xA6DDA6;

    // Screen
    var w as Number = 0;
    var h as Number = 0;
    var cx as Number = 0;
    var cy as Number = 0;
    var S as Number = 0;         // unit: min(width, height)
    var fine as Boolean = true;  // draw the extra detail passes (stitching, ridges, curls)

    // Halter geometry, set by the view once it has picked the time font
    var strapCy as Number = 0;
    var strapH as Number = 0;

    // The head rocks about this height - roughly where the neck would be.
    hidden const HINGE = 0.34;

    hidden var pw as Number = 2;    // thin pen
    hidden var pwFat as Number = 3; // outline pen

    // Ear normal, shared between drawEar and earSlab. It lives here rather than
    // in the argument list because pre-4.0 devices cap methods at nine arguments.
    hidden var earNX as Float = 0.0;
    hidden var earNY as Float = 0.0;

    // Muzzle length of the goat being drawn, as a multiplier on every fraction
    // below the eyes. Under 1.0 gives the short kid face the dwarf breeds keep.
    hidden var mz as Float = 1.0;

    function initialize() {
    }

    function setSize(dcWidth as Number, dcHeight as Number) as Void {
        w = dcWidth;
        h = dcHeight;
        cx = w / 2;
        cy = h / 2;
        S = (w < h) ? w : h;
        fine = (S >= 300);
        pw = f(0.006);
        if (pw < 1) { pw = 1; }
        pwFat = f(0.011);
        if (pwFat < 2) { pwFat = 2; }
        strapCy = cy + f(0.060);
        strapH = f(0.175);
    }

    // ---------------------------------------------------------------- helpers

    //! Fraction of the unit, in whole pixels.
    hidden function f(frac as Float) as Number {
        return (frac * S).toNumber();
    }

    //! Fraction-space x, posed.
    hidden function mx(p as Pose, xf as Float, yf as Float) as Number {
        return (cx + p.ox + p.tilt * (HINGE - yf) + xf * S).toNumber();
    }

    //! Fraction-space y, posed.
    hidden function my(p as Pose, yf as Float) as Number {
        return (cy + p.oy + yf * S).toNumber();
    }

    hidden function mp(p as Pose, xf as Float, yf as Float) as Graphics.Point2D {
        return [mx(p, xf, yf), my(p, yf)];
    }

    hidden function pt(x as Number, y as Number) as Graphics.Point2D {
        return [x, y];
    }

    hidden function ink(dc as Dc, color as Number) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
    }

    //! Scale a colour's brightness. factor > 1 lightens, < 1 darkens.
    static function tint(color as Number, factor as Float) as Number {
        var r = (((color >> 16) & 0xFF) * factor).toNumber();
        var g = (((color >> 8) & 0xFF) * factor).toNumber();
        var b = ((color & 0xFF) * factor).toNumber();
        if (r > 255) { r = 255; }
        if (g > 255) { g = 255; }
        if (b > 255) { b = 255; }
        if (r < 0) { r = 0; }
        if (g < 0) { g = 0; }
        if (b < 0) { b = 0; }
        return (r << 16) | (g << 8) | b;
    }

    // ------------------------------------------------------------- backdrop

    //! progress: how much of the step goal is done, 0.0 .. 1.0, or a negative
    //! number for no ring at all.
    function drawBackdrop(dc as Dc, color as Number, progress as Float) as Void {
        dc.setColor(color, color);
        dc.clear();

        if (fine) {
            // A soft vignette so the head reads against the rim on round panels.
            var r = S / 2;
            var ring = f(0.030);
            if (ring < 3) { ring = 3; }
            dc.setPenWidth(ring);
            ink(dc, tint(color, 0.80));
            dc.drawCircle(cx, cy, r - ring / 2);
            dc.setPenWidth(1);
        }

        if (progress >= 0.0) {
            drawGoalRing(dc, color, progress);
        }
    }

    //! The step goal round the rim: an unlit track the whole way round, and a
    //! lit arc for the part that is done, running clockwise from twelve.
    hidden function drawGoalRing(dc as Dc, back as Number, progress as Float) as Void {
        var pen = f(0.022);
        if (pen < 3) { pen = 3; }
        var rad = S / 2 - pen / 2 - 1;

        dc.setPenWidth(pen);
        ink(dc, tint(back, 0.62));
        dc.drawCircle(cx, cy, rad);

        // Below a percent the arc is shorter than the pen is wide, and Garmin
        // reads a zero-length arc as a whole circle - which would show the goal
        // already met.
        if (progress >= 0.01) {
            ink(dc, STEP_INK);
            if (progress >= 1.0) {
                dc.drawCircle(cx, cy, rad);
            } else {
                // Arc degrees run counter-clockwise from three o'clock.
                var end = 90 - (progress * 360).toNumber();
                if (end < 0) { end += 360; }
                dc.drawArc(cx, cy, rad, Graphics.ARC_CLOCKWISE, 90, end);
            }
        }
        dc.setPenWidth(1);
    }

    // ------------------------------------------------------------ the goat

    function draw(dc as Dc, b as Breed, p as Pose) as Void {
        mz = b.muzzleLen;

        drawHorn(dc, b, p, -1);
        drawHorn(dc, b, p, 1);

        // Ears go behind the head so they can never cut across the eyes; long
        // pendulous ones are cut long enough to reappear below the halter, which
        // reads as the strap passing over them.
        drawEar(dc, b, p, -1, p.earL);
        drawEar(dc, b, p, 1, p.earR);

        drawHead(dc, b, p);
        drawMarkings(dc, b, p);

        if (b.curly && fine) {
            drawFleece(dc, b, p);
        }

        drawEyes(dc, b, p);
        drawMuzzle(dc, b, p);
        drawBeard(dc, b, p);
        drawWattles(dc, b, p);
        drawTongue(dc, b, p);
    }

    // -------------------------------------------------------------- horns

    hidden function drawHorn(dc as Dc, b as Breed, p as Pose, side as Number) as Void {
        if (b.horns == Breeds.HORN_NONE) {
            return;
        }

        // Base sits inside the skull so the join is hidden behind the head.
        var bx = 0.100;
        var by = -0.290;
        var c1x = 0.125;
        var c1y = -0.370;
        var ex = 0.148;
        var ey = -0.428;
        var w0 = 0.030;
        var w1 = 0.008;
        var segs = 4;
        var ridged = false;

        if (b.horns == Breeds.HORN_SWEPT) {
            c1x = 0.14; c1y = -0.43; ex = 0.245; ey = -0.385;
            w0 = 0.036; w1 = 0.010; segs = 6;
        } else if (b.horns == Breeds.HORN_IBEX) {
            c1x = 0.12; c1y = -0.45; ex = 0.300; ey = -0.350;
            w0 = 0.048; w1 = 0.014; segs = 8; ridged = true;
        } else if (b.horns == Breeds.HORN_SPIRAL) {
            c1x = 0.25; c1y = -0.39; ex = 0.365; ey = -0.265;
            w0 = 0.038; w1 = 0.011; segs = 8; ridged = true;
        }

        var x0 = side * bx;
        var y0 = by;
        var x1 = side * c1x;
        var y1 = c1y;
        var x2 = side * ex;
        var y2 = ey;

        var plx = 0.0;
        var ply = 0.0;
        var prx = 0.0;
        var pry = 0.0;

        dc.setPenWidth(pw);
        for (var i = 0; i <= segs; i++) {
            var t = i * 1.0 / segs;
            var mt = 1.0 - t;
            var qx = mt * mt * x0 + 2.0 * mt * t * x1 + t * t * x2;
            var qy = mt * mt * y0 + 2.0 * mt * t * y1 + t * t * y2;

            // Tangent of the quadratic, turned 90 degrees for the half-width.
            var tx = 2.0 * mt * (x1 - x0) + 2.0 * t * (x2 - x1);
            var ty = 2.0 * mt * (y1 - y0) + 2.0 * t * (y2 - y1);
            var len = Math.sqrt(tx * tx + ty * ty);
            if (len < 0.0001) {
                len = 0.0001;
            }
            var half = w0 + (w1 - w0) * t;
            var nx = -ty / len * half;
            var ny = tx / len * half;

            var lx = qx + nx;
            var ly = qy + ny;
            var rx = qx - nx;
            var ry = qy - ny;

            if (i > 0) {
                ink(dc, b.horn);
                dc.fillPolygon([mp(p, plx, ply), mp(p, lx, ly),
                                mp(p, rx, ry), mp(p, prx, pry)]);
                if (ridged && fine) {
                    ink(dc, b.hornDark);
                    dc.drawLine(mx(p, lx, ly), my(p, ly), mx(p, rx, ry), my(p, ry));
                }
            }
            plx = lx; ply = ly; prx = rx; pry = ry;
        }

        // Rounded tip.
        ink(dc, b.hornDark);
        dc.fillCircle(mx(p, x2, y2), my(p, y2), f(w1) + 1);
        dc.setPenWidth(1);
    }

    // ---------------------------------------------------------------- ears

    hidden function drawEar(dc as Dc, b as Breed, p as Pose, side as Number, twist as Float) as Void {
        // Ear as a tapered slab swung out from a pivot on the side of the skull,
        // capped with a circle so the tip is round whatever the angle.
        // Goat ears are broad leaves held out to the side, not spikes.
        var theta = -0.50;   // radians from horizontal, negative is up
        var len = 0.185;
        var t0 = 0.072;
        var t1 = 0.030;
        var px = 0.165;
        var py = -0.215;

        if (b.ear == Breeds.EAR_DROOP) {
            // Drawn in two segments with a bend, so a pendulous ear hangs in a
            // curve instead of sticking out like a plank.
            drawDroopEar(dc, b, p, side, twist);
            return;
        } else if (b.ear == Breeds.EAR_ELF) {
            theta = -0.35; len = 0.055; t0 = 0.038; t1 = 0.028; px = 0.205; py = -0.190;
        } else if (b.ear == Breeds.EAR_SIDE) {
            theta = -0.22; len = 0.180; t0 = 0.058; t1 = 0.022; px = 0.190; py = -0.185;
        }

        var a = theta + twist;
        var ca = Math.cos(a);
        var sa = Math.sin(a);

        var bxf = side * px;
        var byf = py;

        // Axis points outward (mirrored by side); the normal is it turned 90 degrees.
        var axX = side * ca;
        var axY = sa;
        var nX = -sa;
        var nY = side * ca;

        earNX = nX;
        earNY = nY;

        var tipX = bxf + axX * len;
        var tipY = byf + axY * len;

        ink(dc, b.coatDark);
        earSlab(dc, p, bxf, byf, tipX, tipY, t0, t1);

        // Inner ear, inset so a rim of coat shows around it.
        var iX = bxf + axX * len * 0.86;
        var iY = byf + axY * len * 0.86;
        ink(dc, b.coat);
        earSlab(dc, p, bxf, byf, iX, iY, t0 * 0.66, t1 * 0.60);

        var jX = bxf + axX * len * 0.72;
        var jY = byf + axY * len * 0.72;
        ink(dc, b.earInner);
        earSlab(dc, p, bxf, byf, jX, jY, t0 * 0.34, t1 * 0.30);
    }

    //! A long pendulous ear: an upper segment off the skull, then a lower one
    //! bent further in, so it hangs in a curve and the tip turns outward.
    hidden function drawDroopEar(dc as Dc, b as Breed, p as Pose, side as Number, twist as Float) as Void {
        var a1 = 1.12 + twist;
        var a2 = 1.48 + twist * 0.55;
        var bxf = side * 0.215;
        var byf = -0.235;

        var m1x = bxf + side * Math.cos(a1) * 0.215;
        var m1y = byf + Math.sin(a1) * 0.215;
        var tipx = m1x + side * Math.cos(a2) * 0.235;
        var tipy = m1y + Math.sin(a2) * 0.235;

        for (var pass = 0; pass < 3; pass++) {
            var scale = (pass == 0) ? 1.0 : ((pass == 1) ? 0.66 : 0.34);
            var color = (pass == 0) ? b.coatDark : ((pass == 1) ? b.coat : b.earInner);
            var reach = (pass == 0) ? 1.0 : ((pass == 1) ? 0.90 : 0.76);
            ink(dc, color);

            earNX = -Math.sin(a1);
            earNY = side * Math.cos(a1);
            earSlab(dc, p, bxf, byf, m1x, m1y, 0.062 * scale, 0.056 * scale);

            earNX = -Math.sin(a2);
            earNY = side * Math.cos(a2);
            var ex = m1x + (tipx - m1x) * reach;
            var ey = m1y + (tipy - m1y) * reach;
            earSlab(dc, p, m1x, m1y, ex, ey, 0.056 * scale, 0.044 * scale);
        }
    }

    hidden function earSlab(dc as Dc, p as Pose, x0 as Float, y0 as Float, x1 as Float, y1 as Float,
                            h0 as Float, h1 as Float) as Void {
        var nX = earNX;
        var nY = earNY;
        dc.fillPolygon([mp(p, x0 + nX * h0, y0 + nY * h0),
                        mp(p, x1 + nX * h1, y1 + nY * h1),
                        mp(p, x1 - nX * h1, y1 - nY * h1),
                        mp(p, x0 - nX * h0, y0 - nY * h0)]);
        dc.fillCircle(mx(p, x1, y1), my(p, y1), f(h1));
    }

    // ---------------------------------------------------------------- head

    //! Skull, jaw, a tapering muzzle and a rounded chin - long and narrow, which
    //! is what stops a goat reading as a bear.
    hidden function headShapes(dc as Dc, p as Pose, d as Number) as Void {
        dc.fillEllipse(mx(p, 0.0, -0.185), my(p, -0.185), f(0.245) + d, f(0.190) + d);
        dc.fillEllipse(mx(p, 0.0, -0.010), my(p, -0.010), f(0.205) + d, f(0.170) + d);
        var wedge = 0.320 * mz;
        var chin = 0.315 * mz;
        dc.fillPolygon([pt(mx(p, -0.190, -0.050) - d, my(p, -0.050)),
                        pt(mx(p, 0.190, -0.050) + d, my(p, -0.050)),
                        pt(mx(p, 0.125, wedge) + d, my(p, wedge) + d),
                        pt(mx(p, -0.125, wedge) - d, my(p, wedge) + d)]);
        dc.fillEllipse(mx(p, 0.0, chin), my(p, chin), f(0.125) + d, f(0.090) + d);
    }

    hidden function drawHead(dc as Dc, b as Breed, p as Pose) as Void {
        // Silhouette first, slightly fat, to give the head a dark rim.
        ink(dc, b.coatDark);
        headShapes(dc, p, pwFat);
        ink(dc, b.coat);
        headShapes(dc, p, 0);

        // Cheek highlights, and a shadow where the chin recedes under the muzzle.
        ink(dc, b.coatLight);
        dc.fillEllipse(mx(p, -0.142, 0.030), my(p, 0.030), f(0.050), f(0.072));
        dc.fillEllipse(mx(p, 0.142, 0.030), my(p, 0.030), f(0.050), f(0.072));
        ink(dc, tint(b.coat, 0.84));
        dc.fillEllipse(mx(p, 0.0, 0.352 * mz), my(p, 0.352 * mz), f(0.112), f(0.042));
    }

    hidden function drawMarkings(dc as Dc, b as Breed, p as Pose) as Void {
        if (b.marking == Breeds.MARK_BLAZE) {
            ink(dc, b.markColor);
            dc.fillPolygon([mp(p, -0.075, -0.360), mp(p, 0.075, -0.360),
                            mp(p, 0.104, 0.320 * mz), mp(p, -0.104, 0.320 * mz)]);

        } else if (b.marking == Breeds.MARK_STRIPES) {
            ink(dc, b.markColor);
            for (var s = -1; s <= 1; s += 2) {
                dc.fillPolygon([mp(p, s * 0.186, -0.320), mp(p, s * 0.136, -0.320),
                                mp(p, s * 0.100, 0.270 * mz), mp(p, s * 0.140, 0.270 * mz)]);
            }

        } else if (b.marking == Breeds.MARK_MASK) {
            ink(dc, b.markColor);
            dc.fillEllipse(mx(p, -0.150, -0.150), my(p, -0.150), f(0.112), f(0.082));
            dc.fillEllipse(mx(p, 0.150, -0.150), my(p, -0.150), f(0.112), f(0.082));
            dc.fillPolygon([mp(p, -0.095, -0.360), mp(p, 0.095, -0.360),
                            mp(p, 0.058, -0.120), mp(p, -0.058, -0.120)]);

        } else if (b.marking == Breeds.MARK_DARK_FACE) {
            ink(dc, b.faceDark);
            dc.fillEllipse(mx(p, 0.0, -0.150), my(p, -0.150), f(0.196), f(0.222));
            dc.fillPolygon([mp(p, -0.180, -0.010), mp(p, 0.180, -0.010),
                            mp(p, 0.120, 0.310 * mz), mp(p, -0.120, 0.310 * mz)]);
            ink(dc, b.markColor);
            for (var s2 = -1; s2 <= 1; s2 += 2) {
                dc.fillPolygon([mp(p, s2 * 0.188, -0.300), mp(p, s2 * 0.124, -0.300),
                                mp(p, s2 * 0.096, 0.150), mp(p, s2 * 0.144, 0.150)]);
            }
        }
    }

    //! Angora ringlets: a deterministic scatter of pale curls around the crown.
    hidden function drawFleece(dc as Dc, b as Breed, p as Pose) as Void {
        var r = f(0.030);
        if (r < 3) { r = 3; }
        for (var i = 0; i < 16; i++) {
            var ang = 3.1416 + i * 0.2094;                    // a ring across the crown
            var rad = 0.205 + (Pose.fizz(i) % 5) * 0.008;
            var xf = Math.cos(ang) * rad;
            var yf = -0.165 + Math.sin(ang) * rad * 0.90;
            ink(dc, (i % 2 == 0) ? b.coatLight : b.coatDark);
            dc.fillCircle(mx(p, xf, yf), my(p, yf), r);
        }
        // Fringe over the forehead.
        ink(dc, b.coatLight);
        for (var j = -2; j <= 2; j++) {
            dc.fillCircle(mx(p, j * 0.068, -0.300), my(p, -0.300), f(0.046));
        }
    }

    // ---------------------------------------------------------------- eyes

    hidden function drawEyes(dc as Dc, b as Breed, p as Pose) as Void {
        // Colour the eyelid with whatever the face is locally, so a blink does
        // not punch a coat-coloured hole through a mask or a dark face.
        var lid = b.coat;
        if (b.marking == Breeds.MARK_MASK) {
            lid = b.markColor;
        } else if (b.marking == Breeds.MARK_DARK_FACE) {
            lid = b.faceDark;
        }

        drawEye(dc, b, p, mx(p, -0.150, -0.150), my(p, -0.150), lid);
        drawEye(dc, b, p, mx(p, 0.150, -0.150), my(p, -0.150), lid);
    }

    hidden function drawEye(dc as Dc, b as Breed, p as Pose, ex as Number, ey as Number, lid as Number) as Void {
        var a = (0.070 * b.eyeScale * S).toNumber();
        var bb = (0.046 * b.eyeScale * S).toNumber();

        ink(dc, tint(b.coatDark, 0.75));
        dc.fillEllipse(ex, ey, a + pw, bb + pw);
        ink(dc, b.eye);
        dc.fillEllipse(ex, ey, a, bb);

        // The giveaway: a goat's pupil is a horizontal slot.
        var pupW = (0.104 * b.eyeScale * S).toNumber();
        var pupH = (0.026 * b.eyeScale * S).toNumber();
        if (pupH < 3) { pupH = 3; }
        ink(dc, 0x101010);
        dc.fillRoundedRectangle(ex - pupW / 2 + p.pupil, ey - pupH / 2, pupW, pupH, pupH / 2);

        ink(dc, 0xFFFFFF);
        var hl = f(0.011);
        if (hl < 2) { hl = 2; }
        dc.fillCircle(ex - f(0.030) + p.pupil, ey - f(0.018), hl);

        if (p.blink > 0.0) {
            var full = (bb + pw) * 2 + 2;
            var drop = (full * p.blink).toNumber();
            ink(dc, lid);
            dc.fillRectangle(ex - a - pw, ey - bb - pw - 1, (a + pw) * 2, drop);
            ink(dc, tint(b.coatDark, 0.8));
            dc.setPenWidth(pw);
            dc.drawLine(ex - a, ey - bb - pw - 1 + drop, ex + a, ey - bb - pw - 1 + drop);
            dc.setPenWidth(1);
        }
    }

    // -------------------------------------------------------------- muzzle

    hidden function drawMuzzle(dc as Dc, b as Breed, p as Pose) as Void {
        var pad = 0.305 * mz;
        var nose = 0.278 * mz;
        var lip = 0.318 * mz;

        ink(dc, b.muzzle);
        dc.fillEllipse(mx(p, 0.0, pad), my(p, pad), f(0.142), f(0.098));

        ink(dc, b.muzzleDark);
        var nr = f(0.028);
        var nb = f(0.020);
        dc.fillEllipse(mx(p, -0.055, nose), my(p, nose) - p.breath, nr, nb);
        dc.fillEllipse(mx(p, 0.055, nose), my(p, nose) - p.breath, nr, nb);

        dc.setPenWidth(pw);
        dc.drawLine(mx(p, 0.0, 0.298 * mz), my(p, 0.298 * mz),
                    mx(p, 0.0, 0.332 * mz), my(p, 0.332 * mz) + p.jaw);
        dc.drawArc(mx(p, 0.0, lip) + p.chew, my(p, lip) + p.jaw, f(0.070),
                   Graphics.ARC_COUNTER_CLOCKWISE, 215, 325);
        dc.setPenWidth(1);

        // An open mouth, for yawning and for the tongue to come out of.
        if (p.mouth > 0.0) {
            var gape = 0.340 * mz;
            var openH = (0.072 * p.mouth * S).toNumber();
            if (openH < 2) { openH = 2; }
            var openW = f(0.062) + (0.030 * p.mouth * S).toNumber();
            var gy = my(p, gape) + p.jaw;
            ink(dc, tint(b.muzzleDark, 0.55));
            dc.fillEllipse(mx(p, 0.0, gape) + p.chew, gy, openW, openH);
            ink(dc, tint(b.muzzleDark, 1.6));
            dc.setPenWidth(pw);
            dc.drawArc(mx(p, 0.0, gape) + p.chew, gy, openW,
                       Graphics.ARC_COUNTER_CLOCKWISE, 200, 340);
            dc.setPenWidth(1);
        }
    }

    // --------------------------------------------------------------- beard

    hidden function drawBeard(dc as Dc, b as Breed, p as Pose) as Void {
        if (b.beard == Breeds.BEARD_NONE) {
            return;
        }
        var lenf = (b.beard == Breeds.BEARD_LONG) ? 0.135 : 0.085;
        var topf = 0.378 * mz;
        var botf = topf + lenf;
        var sway = p.beard;

        ink(dc, b.beardColor);
        dc.fillPolygon([mp(p, -0.060, topf), mp(p, 0.060, topf),
                        pt(mx(p, 0.032, botf) + sway, my(p, botf)),
                        pt(mx(p, -0.032, botf) + sway, my(p, botf))]);
        dc.fillCircle(mx(p, 0.0, botf) + sway, my(p, botf), f(0.032));

        if (fine) {
            ink(dc, tint(b.beardColor, 1.35));
            dc.setPenWidth(pw);
            dc.drawLine(mx(p, -0.020, topf + 0.015), my(p, topf + 0.015),
                        mx(p, -0.010, botf - 0.010) + sway, my(p, botf - 0.010));
            dc.drawLine(mx(p, 0.022, topf + 0.015), my(p, topf + 0.015),
                        mx(p, 0.014, botf - 0.010) + sway, my(p, botf - 0.010));
            dc.setPenWidth(1);
        }
    }

    // -------------------------------------------------------------- wattles

    //! The two little tassels that hang under a goat's chin. Not every goat has
    //! them; the ones that do look unmistakably like a goat.
    hidden function drawWattles(dc as Dc, b as Breed, p as Pose) as Void {
        if (!b.wattles) {
            return;
        }
        var topf = 0.360 * mz;
        var botf = topf + 0.060;
        var sway = p.beard / 2;
        var r = f(0.020);
        if (r < 2) { r = 2; }
        for (var s = -1; s <= 1; s += 2) {
            ink(dc, b.coatDark);
            dc.fillPolygon([mp(p, s * 0.078, topf), mp(p, s * 0.106, topf),
                            pt(mx(p, s * 0.100, botf) + sway, my(p, botf)),
                            pt(mx(p, s * 0.084, botf) + sway, my(p, botf))]);
            dc.fillCircle(mx(p, s * 0.092, botf) + sway, my(p, botf), r);
            ink(dc, b.coat);
            dc.fillCircle(mx(p, s * 0.092, botf) + sway, my(p, botf), r - pw);
        }
    }

    // -------------------------------------------------------------- tongue

    //! Pink, and only out for a second at a time. Drawn last so it sits in front
    //! of the beard, the way a real one does.
    hidden function drawTongue(dc as Dc, b as Breed, p as Pose) as Void {
        if (p.tongue <= 0.0) {
            return;
        }
        var topf = 0.354 * mz;
        var xC = mx(p, 0.0, topf) + p.chew;
        var yTop = my(p, topf) + p.jaw;
        var len = (0.070 * p.tongue * S).toNumber();
        var half = f(0.030);

        // The mouth has to be open for a tongue to come out of it.
        ink(dc, b.muzzleDark);
        dc.fillEllipse(xC, yTop, f(0.048), f(0.020));

        ink(dc, 0xE87A93);
        dc.fillRoundedRectangle(xC - half, yTop - f(0.008), half * 2, len + f(0.016), half);
        ink(dc, 0xC85B78);
        dc.setPenWidth(pw);
        dc.drawLine(xC, yTop + f(0.010), xC, yTop + len - f(0.006));
        dc.setPenWidth(1);
    }

    // --------------------------------------------------------------- halter

    //! The leather noseband the time is stamped into. Drawn edge to edge so it
    //! reads as a strap that carries on around the head.
    function drawHalter(dc as Dc) as Void {
        var leather = 0x46301E;
        var top = strapCy - strapH / 2;
        var edge = f(0.009);
        if (edge < 2) { edge = 2; }

        ink(dc, leather);
        dc.fillRectangle(0, top, w, strapH);
        ink(dc, tint(leather, 1.55));
        dc.fillRectangle(0, top, w, edge);
        ink(dc, tint(leather, 0.55));
        dc.fillRectangle(0, top + strapH - edge, w, edge);

        if (fine) {
            // Saddle stitching along both edges.
            ink(dc, 0xC9A96A);
            dc.setPenWidth(pw);
            var y1 = top + edge + f(0.018);
            var y2 = top + strapH - edge - f(0.018);
            var step = f(0.055);
            var dash = f(0.022);
            for (var sx = step / 2; sx < w; sx += step) {
                dc.drawLine(sx, y1, sx + dash, y1);
                dc.drawLine(sx, y2, sx + dash, y2);
            }
            dc.setPenWidth(1);
        }
    }

    // ------------------------------------------------- always-on line art

    //! Burn-in-safe goat: outlines only, a few percent of pixels lit.
    function drawOutline(dc as Dc, b as Breed, ox as Number, oy as Number, color as Number) as Void {
        var x = cx + ox;
        var y = cy + oy;

        ink(dc, color);
        dc.setPenWidth(pw);

        dc.drawEllipse(x, y - f(0.185), f(0.245), f(0.190));
        dc.drawLine(x - f(0.190), y + f(0.020), x - f(0.125), y + f(0.320));
        dc.drawLine(x + f(0.190), y + f(0.020), x + f(0.125), y + f(0.320));
        dc.drawEllipse(x, y + f(0.305), f(0.142), f(0.098));

        // Eyes: outline plus the slot pupil, which is what makes it read as a goat.
        for (var s = -1; s <= 1; s += 2) {
            var ex = x + s * f(0.150);
            var ey = y - f(0.150);
            dc.drawEllipse(ex, ey, f(0.070), f(0.046));
            dc.drawLine(ex - f(0.044), ey, ex + f(0.044), ey);
        }

        // Ears and horns as single strokes.
        for (var s2 = -1; s2 <= 1; s2 += 2) {
            if (b.ear != Breeds.EAR_ELF) {
                var el = (b.ear == Breeds.EAR_DROOP) ? f(0.170) : f(0.115);
                var ey2 = (b.ear == Breeds.EAR_DROOP) ? f(0.300) : -f(0.165);
                dc.drawLine(x + s2 * f(0.180), y - f(0.205), x + s2 * (f(0.180) + el), y - f(0.205) + ey2);
            }
            if (b.horns != Breeds.HORN_NONE) {
                dc.drawLine(x + s2 * f(0.100), y - f(0.290), x + s2 * f(0.240), y - f(0.400));
            }
        }

        if (b.beard != Breeds.BEARD_NONE) {
            dc.drawLine(x - f(0.035), y + f(0.385), x, y + f(0.465));
            dc.drawLine(x + f(0.035), y + f(0.385), x, y + f(0.465));
        }
        dc.setPenWidth(1);
    }
}
