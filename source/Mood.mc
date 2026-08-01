import Toybox.ActivityMonitor;
import Toybox.Lang;
import Toybox.Time;

//! How the goat is feeling, taken from how *you* are doing.
//!
//! Two signals, because they are the two the watch actually knows and they pull
//! in opposite directions: Body Battery says how much is left in you, and the
//! move bar says how long you have been sat still. A drained goat moves slowly
//! and its lids hang; a goat whose move bar is full gets twitchy.
//!
//! Both are sampled at most once every REFRESH_MIN minutes and cached. Body
//! Battery in particular comes out of a SensorHistory iterator, which is far too
//! expensive to open on a once-a-second redraw, and neither number moves fast
//! enough for a fresher reading to show.
module Mood {

    const REFRESH_MIN = 5;

    var vitality as Float = 1.0;   // 1.0 rested .. 0.0 flat out
    var restless as Float = 0.0;   // 0.0 just moved .. 1.0 sat still too long

    var mBody as Number? = null;
    var mStamp as Number = -1;

    //! Call once per redraw with the current ActivityMonitor info. Cheap unless
    //! the cache has expired.
    function refresh(info as ActivityMonitor.Info?) as Void {
        var minutes = Time.now().value() / 60;
        // `minutes < mStamp` catches the clock being wound backwards.
        if (mStamp >= 0 && minutes >= mStamp && minutes - mStamp < REFRESH_MIN) {
            return;
        }
        mStamp = minutes;

        mBody = wantsBody() ? readBodyBattery() : null;

        var bb = mBody;
        // No Body Battery on this watch means no opinion, not a flat goat.
        vitality = (bb == null) ? 1.0 : clamp01(bb / 100.0);
        restless = moveBar(info);
    }

    //! Latest Body Battery, or null. Shared with the data field so a face using
    //! both only pays for one sample.
    function bodyBattery() as Number? {
        return mBody;
    }

    //! Multiplier on the fidget animation: 0.62 flat out .. 1.30 champing.
    function factor() as Float {
        if (!Config.mood) {
            return 1.0;
        }
        return 0.62 + vitality * 0.38 + restless * 0.30;
    }

    //! How heavy the eyelids sit, as a fraction of a full blink. Deliberately
    //! capped low - a goat with its eyes a third shut looks tired, and one with
    //! them further shut looks broken.
    function weariness() as Float {
        if (!Config.mood || vitality >= 0.45) {
            return 0.0;
        }
        return (0.45 - vitality) / 0.45 * 0.30;
    }

    // ------------------------------------------------------------- sampling

    function wantsBody() as Boolean {
        return Config.mood
            || Config.leftField() == Config.FIELD_BODY_BATTERY
            || Config.rightField() == Config.FIELD_BODY_BATTERY;
    }

    function readBodyBattery() as Number? {
        if (!(Toybox has :SensorHistory)) {
            return null;
        }
        if (!(Toybox.SensorHistory has :getBodyBatteryHistory)) {
            return null;
        }
        var iter = Toybox.SensorHistory.getBodyBatteryHistory({:period => 1});
        if (iter == null) {
            return null;
        }
        var sample = iter.next();
        if (sample != null && sample.data != null) {
            return sample.data.toNumber();
        }
        return null;
    }

    //! Move bar level as 0.0 .. 1.0. The bar starts filling after an hour or so
    //! of sitting, which is exactly when a real goat would be pacing the fence.
    function moveBar(info as ActivityMonitor.Info?) as Float {
        if (info == null || !(info has :moveBarLevel)) {
            return 0.0;
        }
        var level = info.moveBarLevel;
        if (level == null) {
            return 0.0;
        }
        var top = ActivityMonitor.MOVE_BAR_LEVEL_MAX - ActivityMonitor.MOVE_BAR_LEVEL_MIN;
        if (top <= 0) {
            return 0.0;
        }
        return clamp01((level - ActivityMonitor.MOVE_BAR_LEVEL_MIN) * 1.0 / top);
    }

    function clamp01(v as Float) as Float {
        if (v < 0.0) {
            return 0.0;
        }
        if (v > 1.0) {
            return 1.0;
        }
        return v;
    }
}
