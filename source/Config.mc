import Toybox.Application;
import Toybox.Lang;

//! Cached watch face settings.
//!
//! Property values come back from the settings editor in whatever type the editor
//! felt like sending - a list choice can arrive as a Number, a Long or even the
//! String "3", and a toggle can arrive as a Number. Everything is funnelled through
//! numberOf()/boolOf() so a stray type can never silently reset the face to defaults.
module Config {

    // Goat setting: 0 = surprise hourly, 1 = surprise daily, 2.. = Breeds index + 2
    const GOAT_HOURLY = 0;
    const GOAT_DAILY = 1;
    const GOAT_FIRST = 2;

    // Backdrop
    const BACK_AUTO = 0;
    const BACK_MEADOW = 1;
    const BACK_SLATE = 2;
    const BACK_BLACK = 3;

    // Data fields
    const FIELD_NONE = 0;
    const FIELD_STEPS = 1;
    const FIELD_HEART = 2;
    const FIELD_CALORIES = 3;
    const FIELD_BATTERY = 4;
    const FIELD_BODY_BATTERY = 5;
    const FIELD_NOTIFICATIONS = 6;
    const FIELD_DISTANCE = 7;
    const FIELD_ACTIVE = 8;
    const FIELD_MAX = 8;

    // Liveliness
    const LIVE_STILL = 0;
    const LIVE_NORMAL = 1;
    const LIVE_FRISKY = 2;

    var goat as Number = GOAT_HOURLY;
    var backdrop as Number = BACK_AUTO;
    var halter as Boolean = true;
    var timeInk as Number = 0;
    var fieldLeft as Number = FIELD_STEPS;
    var fieldRight as Number = FIELD_BATTERY;
    var showDate as Boolean = true;
    var minimal as Boolean = false;
    var goalRing as Boolean = true;
    var mood as Boolean = true;
    var liveliness as Number = LIVE_NORMAL;

    function load() as Void {
        goat = numberOf("Goat", GOAT_HOURLY, 0, GOAT_FIRST + Breeds.COUNT - 1);
        backdrop = numberOf("Backdrop", BACK_AUTO, 0, 3);
        halter = boolOf("Halter", true);
        timeInk = numberOf("TimeInk", 0, 0, 4);
        fieldLeft = numberOf("FieldLeft", FIELD_STEPS, 0, FIELD_MAX);
        fieldRight = numberOf("FieldRight", FIELD_BATTERY, 0, FIELD_MAX);
        showDate = boolOf("ShowDate", true);
        minimal = boolOf("Minimal", false);
        goalRing = boolOf("GoalRing", true);
        mood = boolOf("Mood", true);
        liveliness = numberOf("Liveliness", LIVE_NORMAL, 0, 2);
    }

    // ------------------------------------------------------ what is on screen
    //
    // "Just the goat" is a master switch rather than a fourth way of saying the
    // same thing, so it is applied here and every reader goes through these.
    // The underlying settings keep their values and come back when it is off.

    function dateVisible() as Boolean {
        return showDate && !minimal;
    }

    function leftField() as Number {
        return minimal ? FIELD_NONE : fieldLeft;
    }

    function rightField() as Number {
        return minimal ? FIELD_NONE : fieldRight;
    }

    function ringVisible() as Boolean {
        return goalRing && !minimal;
    }

    //! Motion multiplier for the fidget animation.
    function motion() as Float {
        if (liveliness == LIVE_STILL) {
            return 0.0;
        } else if (liveliness == LIVE_FRISKY) {
            return 1.7;
        }
        return 1.0;
    }

    function raw(key as String) as Application.PropertyValueType {
        try {
            return Properties.getValue(key);
        } catch (e) {
            return null;
        }
    }

    function numberOf(key as String, def as Number, lo as Number, hi as Number) as Number {
        var v = raw(key);
        var n = def;
        if (v instanceof Number) {
            n = v;
        } else if (v instanceof Float || v instanceof Double || v instanceof Long) {
            n = v.toNumber();
        } else if (v instanceof String) {
            var parsed = v.toNumber();
            if (parsed != null) {
                n = parsed;
            }
        } else if (v instanceof Boolean) {
            n = v ? 1 : 0;
        }
        if (n < lo) {
            n = lo;
        } else if (n > hi) {
            n = hi;
        }
        return n;
    }

    function boolOf(key as String, def as Boolean) as Boolean {
        var v = raw(key);
        if (v instanceof Boolean) {
            return v;
        } else if (v instanceof Number) {
            return v != 0;
        } else if (v instanceof Float || v instanceof Double || v instanceof Long) {
            return v.toNumber() != 0;
        } else if (v instanceof String) {
            var s = v.toLower();
            if (s.equals("true") || s.equals("1")) {
                return true;
            }
            if (s.equals("false") || s.equals("0")) {
                return false;
            }
        }
        return def;
    }
}
