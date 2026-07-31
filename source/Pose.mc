import Toybox.Lang;
import Toybox.Math;

//! Where every part of the goat is *this* second.
//!
//! A watch face is redrawn once a second while the watch is awake and once a
//! minute when it is asleep, so the whole animation is a pure function of the
//! clock: same second, same pose. Nothing is stored between frames, which means
//! the goat picks up mid-fidget no matter when the screen wakes.
//!
//! Motion comes in two layers. Underneath, an idle layer always running -
//! breathing, the beard swinging, the head rocking, cud being chewed in bouts.
//! On top, one *gesture* per five-second bucket, chosen by hashing the bucket
//! number. A gesture knows which second of itself it is on, so it can have a
//! shape: an ear flicks hard and settles back over three seconds, a yawn opens
//! and closes, a tongue goes out and comes back in.
class Pose {

    // Gestures, chosen once per BUCKET seconds
    static const G_NONE = 0;
    static const G_EAR = 1;      // one ear flicks and settles
    static const G_TONGUE = 2;   // tongue out and back in
    static const G_YAWN = 3;     // jaw wide, eyes screwed shut
    static const G_SHAKE = 4;    // quick head shake
    static const G_LOOK = 5;     // glances off to one side and holds it

    static const BUCKET = 5;

    var ox as Number = 0;      // head jitter, px
    var oy as Number = 0;
    var tilt as Float = 0.0;   // head rock: px of shift per unit of face height,
                               // hinged at the neck, so the goat wiggles in place
                               // instead of sliding across the screen
    var blink as Float = 0.0;  // 0.0 eyes open .. 1.0 eyes shut
    var earL as Float = 0.0;   // ear twitch, radians
    var earR as Float = 0.0;
    var pupil as Number = 0;   // glance, px
    var jaw as Number = 0;     // chewing, px
    var chew as Number = 0;    // sideways grind, px
    var mouth as Float = 0.0;  // 0.0 shut .. 1.0 yawning
    var breath as Number = 0;  // nostril flare, px
    var beard as Number = 0;   // beard sway, px
    var tongue as Float = 0.0; // 0.0 in .. 1.0 fully lolling out

    function initialize() {
    }

    //! Deterministic hash, 0..32748.
    //!
    //! The multiply-shift-xor rounds matter: a plain `(n * k + c) % m` is linear
    //! enough that taking it modulo a small number (the % 15 below, say) walks a
    //! short repeating cycle that can miss some residues entirely - which is a
    //! goat that never blinks. Input must stay under about 40000 so nothing here
    //! overflows a 32-bit Number.
    static function fizz(n as Number) as Number {
        var x = n * 48271 + 12345;
        x = x ^ (x >> 13);
        x = x * 5;
        x = x ^ (x >> 7);
        return x % 32749;
    }

    //! Which gesture this second belongs to, and how far into it we are.
    static function gestureAt(t as Number) as Number {
        var roll = fizz(t / BUCKET + 991) % 100;
        if (roll < 56) { return G_NONE; }
        if (roll < 72) { return G_EAR; }
        if (roll < 83) { return G_LOOK; }
        if (roll < 91) { return G_TONGUE; }
        if (roll < 97) { return G_SHAKE; }
        return G_YAWN;
    }

    //! t: seconds within the hour. unit: the face's scale (min screen edge).
    //! motion: 0.0 (Still) .. 1.7 (Frisky).
    function update(t as Number, unit as Number, motion as Float) as Void {
        rest();
        if (motion <= 0.0) {
            return;
        }

        var u = unit * motion;
        var phase = t % BUCKET;
        var gesture = gestureAt(t);

        idle(t, u);

        if (gesture == G_EAR) {
            doEar(t, phase);
        } else if (gesture == G_LOOK) {
            doLook(t, phase, u);
        } else if (gesture == G_TONGUE) {
            doTongue(phase);
        } else if (gesture == G_SHAKE) {
            doShake(phase, u);
        } else if (gesture == G_YAWN) {
            doYawn(phase, u);
        }

        // Blinking runs on its own clock rather than as a gesture - it has to be
        // able to happen in the middle of anything else. Except a yawn, which
        // screws the eyes shut on its own.
        if (gesture != G_YAWN) {
            var b = fizz(t + 7) % 17;
            if (b == 0) {
                blink = 1.0;
            } else if (b == 1) {
                blink = 0.45;
            }
        }
    }

    hidden function rest() as Void {
        ox = 0; oy = 0; tilt = 0.0; blink = 0.0; earL = 0.0; earR = 0.0;
        pupil = 0; jaw = 0; chew = 0; mouth = 0.0; breath = 0; beard = 0;
        tongue = 0.0;
    }

    // ------------------------------------------------------------- idle layer

    hidden function idle(t as Number, u as Float) as Void {
        // The head rocks about the neck rather than sliding: the crown swings a
        // few pixels one way, the chin barely moves, which reads as a wiggle.
        tilt = ((fizz(t + 17) % 5) - 2) * 0.011 * u;
        // Plus a pixel of jitter so it never sits perfectly still.
        ox = ((fizz(t) % 3) - 1) * (0.004 * u).toNumber();
        oy = ((fizz(t + 11) % 3) - 1) * (0.004 * u).toNumber();

        breath = (Math.sin(t * 0.9) * 0.005 * u).toNumber();
        beard = (Math.sin(t * 0.4) * 0.014 * u).toNumber() + ox;

        // A held glance that changes every few seconds, so the eyes are not
        // jumping somewhere new every single frame.
        pupil = (((fizz(t / 3 + 61) % 3) - 1) * 0.012 * u).toNumber();

        // Cud is chewed in bouts, and a bout is a rhythm rather than a wobble:
        // three seconds of shut, open, half-open, repeating.
        if ((fizz(t / 8) % 3) != 0) {
            var beat = t % 3;
            if (beat == 0) {
                jaw = 0;
                chew = (-0.010 * u).toNumber();
            } else if (beat == 1) {
                jaw = (0.024 * u).toNumber();
                chew = (0.012 * u).toNumber();
            } else {
                jaw = (0.011 * u).toNumber();
                chew = 0;
            }
        }
    }

    // ---------------------------------------------------------------- gestures

    //! One ear flicks hard, then settles back over the next two seconds.
    hidden function doEar(t as Number, phase as Number) as Void {
        var amp = 0.0;
        if (phase == 0) {
            amp = 0.34;
        } else if (phase == 1) {
            amp = 0.15;
        } else if (phase == 2) {
            amp = 0.05;
        } else {
            return;
        }
        if ((fizz(t / BUCKET + 13) % 2) == 0) {
            earL = amp;
            earR = amp * 0.25;
        } else {
            earR = amp;
            earL = amp * 0.25;
        }
    }

    //! Looks off to one side: the eyes lead, the head follows a beat later.
    hidden function doLook(t as Number, phase as Number, u as Float) as Void {
        var dir = ((fizz(t / BUCKET + 29) % 2) == 0) ? 1 : -1;
        if (phase == 0) {
            pupil = (dir * 0.020 * u).toNumber();
        } else if (phase >= 1 && phase <= 3) {
            pupil = (dir * 0.030 * u).toNumber();
            tilt += dir * 0.014 * u;
        } else {
            pupil = (dir * 0.012 * u).toNumber();
        }
    }

    //! Out, fully lolling, and back in.
    hidden function doTongue(phase as Number) as Void {
        if (phase == 1) {
            tongue = 0.55;
            mouth = 0.35;
        } else if (phase == 2) {
            tongue = 1.0;
            mouth = 0.5;
        } else if (phase == 3) {
            tongue = 0.45;
            mouth = 0.3;
        }
    }

    //! A quick head shake - alternating rock with the ears flapping along.
    hidden function doShake(phase as Number, u as Float) as Void {
        if (phase > 3) {
            return;
        }
        var swing = (phase % 2 == 0) ? 1.0 : -1.0;
        var decay = (phase < 2) ? 1.0 : 0.55;
        tilt = swing * decay * 0.055 * u;
        ox = (swing * decay * 0.012 * u).toNumber();
        earL = swing * decay * 0.30;
        earR = -swing * decay * 0.30;
    }

    //! Jaw wide, eyes screwed shut, head lifted - then back down.
    hidden function doYawn(phase as Number, u as Float) as Void {
        if (phase == 1) {
            mouth = 0.45; blink = 0.55; jaw = (0.030 * u).toNumber();
        } else if (phase == 2) {
            mouth = 1.0; blink = 1.0; jaw = (0.055 * u).toNumber();
            tilt -= 0.020 * u;
            tongue = 0.35;
        } else if (phase == 3) {
            mouth = 0.7; blink = 1.0; jaw = (0.040 * u).toNumber();
            tilt -= 0.012 * u;
            tongue = 0.20;
        } else if (phase == 4) {
            mouth = 0.2; blink = 0.4; jaw = (0.015 * u).toNumber();
        }
        chew = 0;
    }
}
