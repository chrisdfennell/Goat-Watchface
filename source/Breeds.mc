import Toybox.Lang;

//! One goat's look: coat colours, the shape switches the artist reads (ear
//! style, horn style, beard, face markings), and a couple of proportion dials.
class Breed {
    // Coat
    var coat as Number = 0x6B3F1D;
    var coatDark as Number = 0x40240F;      // silhouette rim + shading
    var coatLight as Number = 0x9A6636;     // cheek / bridge highlight
    var muzzle as Number = 0xB08050;
    var muzzleDark as Number = 0x503016;    // nostrils, mouth
    var earInner as Number = 0x8F5A32;
    var beardColor as Number = 0x40240F;
    var eye as Number = 0xE8B33C;           // iris - goats are mostly amber
    var horn as Number = 0xC9B58A;
    var hornDark as Number = 0x8A7A5C;
    var faceDark as Number = 0x241F1B;      // the dark of a masked face

    // Shape switches (see the constants in module Breeds)
    var ear as Number = 0;
    var horns as Number = 0;
    var beard as Number = 1;
    var marking as Number = 0;
    var markColor as Number = 0xF2EEE3;
    var curly as Boolean = false;           // shaggy fleece
    var wattles as Boolean = false;         // the little tassels under the chin

    // Proportions. The dwarf and miniature breeds keep their kid faces: a
    // shorter muzzle and a bigger eye is most of what reads as "small goat".
    var muzzleLen as Float = 1.0;
    var eyeScale as Float = 1.0;

    // Colour for the date, which is written on the forehead
    var faceInk as Number = 0xF5EFE0;

    function initialize() {
    }
}

//! The herd. Index 0..COUNT-1; the Goat setting stores index + Config.GOAT_FIRST.
module Breeds {

    const COUNT = 16;

    // Ear styles
    const EAR_UPRIGHT = 0;   // alert, angled up and out
    const EAR_DROOP = 1;     // long pendulous Nubian / Boer ears
    const EAR_ELF = 2;       // LaMancha - barely any ear at all
    const EAR_SIDE = 3;      // held out sideways

    // Horn styles
    const HORN_NONE = 0;
    const HORN_SPIKE = 1;    // short and straight
    const HORN_SWEPT = 2;    // medium, curving up and back
    const HORN_IBEX = 3;     // long ridged scimitars
    const HORN_SPIRAL = 4;   // wide corkscrew

    // Beards
    const BEARD_NONE = 0;
    const BEARD_SHORT = 1;
    const BEARD_LONG = 2;

    // Face markings
    const MARK_NONE = 0;
    const MARK_BLAZE = 1;      // wide pale stripe down the face
    const MARK_STRIPES = 2;    // a pale stripe above each eye
    const MARK_MASK = 3;       // dark goggles around the eyes
    const MARK_DARK_FACE = 4;  // dark face; markColor draws the eye stripes over
                               // it, so setting markColor to faceDark hides them

    function get(index as Number) as Breed {
        var b = new Breed();
        var i = index;
        if (i < 0 || i >= COUNT) {
            i = 0;
        }

        if (i == 0) {
            // Nubian - glossy chocolate, ears past the jaw, naturally polled
            b.coat = 0x6B3F1D;      b.coatDark = 0x3C220E;   b.coatLight = 0x9A6636;
            b.muzzle = 0xB08050;    b.muzzleDark = 0x4A2C13;  b.earInner = 0x8F5A32;
            b.beardColor = 0x3C220E;
            b.ear = EAR_DROOP;      b.horns = HORN_NONE;      b.beard = BEARD_SHORT;
            b.marking = MARK_NONE;

        } else if (i == 1) {
            // Alpine - black face with the two white eye stripes, swept horns
            b.coat = 0x9A7245;      b.coatDark = 0x4E351A;   b.coatLight = 0xC5A175;
            b.muzzle = 0x2E2A26;    b.muzzleDark = 0x131110;  b.earInner = 0x6A4C2E;
            b.beardColor = 0x1C1A18;
            b.ear = EAR_UPRIGHT;    b.horns = HORN_SWEPT;     b.beard = BEARD_SHORT;
            b.marking = MARK_DARK_FACE; b.markColor = 0xF2EEE3;

        } else if (i == 2) {
            // Boer - rust-red head, broad white blaze, heavy floppy ears
            b.coat = 0xA8451C;      b.coatDark = 0x66260E;   b.coatLight = 0xD4703C;
            b.muzzle = 0xE8CDB4;    b.muzzleDark = 0x6B3A22;  b.earInner = 0xC96B44;
            b.beardColor = 0x66260E;
            b.ear = EAR_DROOP;      b.horns = HORN_SWEPT;     b.beard = BEARD_NONE;
            b.marking = MARK_BLAZE; b.markColor = 0xF2EEE3;
            b.faceInk = 0x4A2A16;   // the date is written on the white blaze

        } else if (i == 3) {
            // Angora - cream fleece in ringlets, corkscrew horns, long beard
            b.coat = 0xEFE6D0;      b.coatDark = 0xC2B497;   b.coatLight = 0xFFFAEE;
            b.muzzle = 0xE0B9A6;    b.muzzleDark = 0x8A6252;  b.earInner = 0xD8BFA8;
            b.beardColor = 0xD8CBAF; b.eye = 0x8FA3B8;
            b.horn = 0xD3C09A;      b.hornDark = 0x9A886A;
            b.ear = EAR_UPRIGHT;    b.horns = HORN_SPIRAL;    b.beard = BEARD_LONG;
            b.marking = MARK_NONE;  b.curly = true;
            b.faceInk = 0x5A4A33;

        } else if (i == 4) {
            // Pygmy - agouti grey with a dark bandit mask and stubby horns
            b.coat = 0x7B6D5D;      b.coatDark = 0x453C33;   b.coatLight = 0xA8967F;
            b.muzzle = 0x8E8070;    b.muzzleDark = 0x2A241E;  b.earInner = 0x5E5346;
            b.beardColor = 0x35302A;
            b.ear = EAR_SIDE;       b.horns = HORN_SPIKE;     b.beard = BEARD_SHORT;
            b.marking = MARK_MASK;  b.markColor = 0x2A241E;
            b.muzzleLen = 0.92;     b.eyeScale = 1.12;

        } else if (i == 5) {
            // LaMancha - the earless one; chocolate coat, tiny elf ears
            b.coat = 0x463227;      b.coatDark = 0x241813;   b.coatLight = 0x6E5040;
            b.muzzle = 0x7A5C48;    b.muzzleDark = 0x2A1C14;  b.earInner = 0x5A4034;
            b.beardColor = 0x241813; b.eye = 0xD9A441;
            b.ear = EAR_ELF;        b.horns = HORN_NONE;      b.beard = BEARD_SHORT;
            b.marking = MARK_NONE;

        } else if (i == 6) {
            // Toggenburg - fawn with the two white stripes down the face
            b.coat = 0x8A6B45;      b.coatDark = 0x543D24;   b.coatLight = 0xB59468;
            b.muzzle = 0xF0E8D8;    b.muzzleDark = 0x6A5238;  b.earInner = 0xB08C60;
            b.beardColor = 0x543D24;
            b.ear = EAR_UPRIGHT;    b.horns = HORN_NONE;      b.beard = BEARD_SHORT;
            b.marking = MARK_STRIPES; b.markColor = 0xF2EEE3;
            b.wattles = true;

        } else if (i == 7) {
            // Saanen - all white, pink muzzle, pale eyes
            b.coat = 0xF2EFE2;      b.coatDark = 0xC6C0AE;   b.coatLight = 0xFFFFF6;
            b.muzzle = 0xE9B2A4;    b.muzzleDark = 0x9A6A5E;  b.earInner = 0xE0C9BC;
            b.beardColor = 0xDCD6C4; b.eye = 0x86B4D6;
            b.ear = EAR_UPRIGHT;    b.horns = HORN_NONE;      b.beard = BEARD_SHORT;
            b.marking = MARK_NONE;
            b.faceInk = 0x55503F;

        } else if (i == 8) {
            // Ibex - the wild one, with the horns to prove it
            b.coat = 0xB08B57;      b.coatDark = 0x6A4F2E;   b.coatLight = 0xD8B884;
            b.muzzle = 0xD8C9AC;    b.muzzleDark = 0x5A4530;  b.earInner = 0x8A6A42;
            b.beardColor = 0x2E2118; b.horn = 0x8F7C58;       b.hornDark = 0x5A4C34;
            b.ear = EAR_SIDE;       b.horns = HORN_IBEX;      b.beard = BEARD_LONG;
            b.marking = MARK_MASK;  b.markColor = 0x4A3520;

        } else if (i == 9) {
            // Black Bengal - jet black with amber eyes and short spikes
            b.coat = 0x272727;      b.coatDark = 0x0D0D0D;   b.coatLight = 0x4E4E4E;
            b.muzzle = 0x3C3C3C;    b.muzzleDark = 0x0A0A0A;  b.earInner = 0x333333;
            b.beardColor = 0x141414; b.eye = 0xE8A93C;
            b.horn = 0x8C8272;      b.hornDark = 0x5A5246;
            b.ear = EAR_UPRIGHT;    b.horns = HORN_SPIKE;     b.beard = BEARD_SHORT;
            b.marking = MARK_NONE;

        } else if (i == 10) {
            // Nigerian Dwarf - chocolate and white, blue eyes, wattles, and the
            // short kid face the breed keeps its whole life
            b.coat = 0x4A3226;      b.coatDark = 0x241811;   b.coatLight = 0x7A5642;
            b.muzzle = 0xF0E6DA;    b.muzzleDark = 0x5A4034;  b.earInner = 0x8A6A56;
            b.beardColor = 0x241811; b.eye = 0x7FB6DC;        // the famous blue eye
            b.horn = 0xC0AE8E;      b.hornDark = 0x877A62;
            b.ear = EAR_UPRIGHT;    b.horns = HORN_SPIKE;     b.beard = BEARD_SHORT;
            b.marking = MARK_BLAZE; b.markColor = 0xF4EEE6;
            b.wattles = true;
            b.muzzleLen = 0.88;     b.eyeScale = 1.22;
            b.faceInk = 0x40281C;   // written on the white blaze

        } else if (i == 11) {
            // Oberhasli - deep bay red under a black mask, black points
            b.coat = 0xA0501F;      b.coatDark = 0x5A2A0E;   b.coatLight = 0xC97B3E;
            b.muzzle = 0x2A2320;    b.muzzleDark = 0x100D0C;  b.earInner = 0x6E3A18;
            b.beardColor = 0x181513; b.faceDark = 0x1E1A18;
            b.ear = EAR_UPRIGHT;    b.horns = HORN_SWEPT;     b.beard = BEARD_SHORT;
            b.marking = MARK_DARK_FACE; b.markColor = 0xC97B3E;

        } else if (i == 12) {
            // Valais Blacknose - white ringlets, and a face black to the ears
            b.coat = 0xF4F0E6;      b.coatDark = 0xC9C3B4;   b.coatLight = 0xFFFFFA;
            b.muzzle = 0x1E1C1B;    b.muzzleDark = 0x080807;  b.earInner = 0x2A2624;
            b.beardColor = 0xDED8C8; b.faceDark = 0x1C1A19;
            b.horn = 0xC6B492;      b.hornDark = 0x8E7F63;
            b.ear = EAR_UPRIGHT;    b.horns = HORN_SPIRAL;    b.beard = BEARD_SHORT;
            b.marking = MARK_DARK_FACE; b.markColor = 0x1C1A19;  // no stripes
            b.curly = true;
            b.faceInk = 0x3A3532;   // the date lands on the white fringe, not the black face

        } else if (i == 13) {
            // Markhor - the wild corkscrew, shaggy grey and a beard to the chest
            b.coat = 0x9C8E76;      b.coatDark = 0x5E543F;   b.coatLight = 0xC3B79C;
            b.muzzle = 0xD2C8B2;    b.muzzleDark = 0x4A4234;  b.earInner = 0x7A6E58;
            b.beardColor = 0x3A3226; b.horn = 0x8A7F66;       b.hornDark = 0x574E3C;
            b.ear = EAR_SIDE;       b.horns = HORN_SPIRAL;    b.beard = BEARD_LONG;
            b.marking = MARK_STRIPES; b.markColor = 0xE4DCC8;

        } else if (i == 14) {
            // Golden Guernsey - blonde all over, ears carried a little low
            b.coat = 0xD69B45;      b.coatDark = 0x94631F;   b.coatLight = 0xF0C075;
            b.muzzle = 0xE9C89A;    b.muzzleDark = 0x7A5424;  b.earInner = 0xC08A44;
            b.beardColor = 0x94631F; b.eye = 0xC98A2E;
            b.ear = EAR_SIDE;       b.horns = HORN_NONE;      b.beard = BEARD_SHORT;
            b.marking = MARK_NONE;
            b.wattles = true;
            b.faceInk = 0x4A3212;

        } else {
            // Kiko - hardy cream New Zealander with a big sweep of horn
            b.coat = 0xE6DCC4;      b.coatDark = 0xB0A587;   b.coatLight = 0xF7F1E2;
            b.muzzle = 0xD9BFA6;    b.muzzleDark = 0x7A6450;  b.earInner = 0xC9B294;
            b.beardColor = 0xBFB396; b.eye = 0xD8A441;
            b.ear = EAR_SIDE;       b.horns = HORN_IBEX;      b.beard = BEARD_LONG;
            b.marking = MARK_NONE;
            b.faceInk = 0x5C513A;
        }
        return b;
    }
}
