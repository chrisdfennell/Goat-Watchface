import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

//! The watch face itself: picks today's goat, poses it for this second, and
//! writes the time onto the halter strap across its nose.
class GoatFaceView extends WatchUi.WatchFace {

    hidden var mArtist as GoatArtist;
    hidden var mPose as Pose;
    hidden var mBreed as Breed?;
    hidden var mBreedIdx as Number = -1;

    hidden var mTimeFont as FontType = Graphics.FONT_NUMBER_MEDIUM;
    hidden var mSmallFont as FontType = Graphics.FONT_XTINY;

    hidden var mLowPower as Boolean = false;
    hidden var mBurnIn as Boolean = false;

    // Text ink options for the time, in the order the setting lists them.
    hidden const INKS = [0xF3E7CC, 0xFFFFFF, 0xF5C542, 0x9FE0C0, 0x9FD0F0] as Array<Number>;
    hidden const FIELD_INK = 0xF2E8D5;

    function initialize() {
        WatchFace.initialize();
        mArtist = new GoatArtist();
        mPose = new Pose();
        Config.load();
    }

    function onLayout(dc as Dc) as Void {
        mArtist.setSize(dc.getWidth(), dc.getHeight());

        var settings = System.getDeviceSettings();
        if (settings has :requiresBurnInProtection) {
            var r = settings.requiresBurnInProtection;
            mBurnIn = (r != null) && r;
        }

        // Biggest numeric font that still fits inside a believable noseband.
        var candidates = [Graphics.FONT_NUMBER_THAI_HOT, Graphics.FONT_NUMBER_HOT,
                          Graphics.FONT_NUMBER_MEDIUM, Graphics.FONT_NUMBER_MILD,
                          Graphics.FONT_LARGE, Graphics.FONT_MEDIUM];
        var maxH = (mArtist.S * 0.155).toNumber();
        var maxW = (mArtist.w * 0.70).toNumber();
        mTimeFont = Graphics.FONT_MEDIUM;
        for (var i = 0; i < candidates.size(); i++) {
            var fnt = candidates[i];
            if (dc.getFontHeight(fnt) <= maxH && dc.getTextWidthInPixels("88:88", fnt) <= maxW) {
                mTimeFont = fnt;
                break;
            }
        }

        var fh = dc.getFontHeight(mTimeFont);
        var strap = (fh * 1.18).toNumber();
        var cap = (mArtist.S * 0.185).toNumber();
        if (strap > cap) {
            strap = cap;
        }
        if (strap < fh + 4) {
            strap = fh + 4;
        }
        mArtist.strapH = strap;
    }

    function onSettingsUpdated() as Void {
        mBreedIdx = -1;  // force the goat to be rebuilt with the new setting
    }

    function onUpdate(dc as Dc) as Void {
        dc.clearClip();
        if (dc has :setAntiAlias) {
            dc.setAntiAlias(true);
        }

        var clock = System.getClockTime();
        var breed = currentBreed();

        if (mLowPower && mBurnIn) {
            drawAlwaysOn(dc, breed, clock);
            return;
        }

        // One second of the clock is one frame of the animation.
        var t = clock.min * 60 + clock.sec;
        mPose.update(t, mArtist.S, mLowPower ? 0.0 : Config.motion());

        mArtist.drawBackdrop(dc, backdropColor(clock.hour));
        mArtist.draw(dc, breed, mPose);

        if (Config.showDate) {
            drawDate(dc, breed);
        }

        if (Config.halter) {
            mArtist.drawHalter(dc);
        }
        drawTime(dc, clock);
        drawFields(dc);
    }

    function onEnterSleep() as Void {
        mLowPower = true;
        WatchUi.requestUpdate();
    }

    function onExitSleep() as Void {
        mLowPower = false;
        WatchUi.requestUpdate();
    }

    // ------------------------------------------------------------ the goat

    hidden function currentBreed() as Breed {
        var idx = pickBreedIndex();
        if (mBreed == null || idx != mBreedIdx) {
            mBreed = Breeds.get(idx);
            mBreedIdx = idx;
        }
        return mBreed;
    }

    hidden function pickBreedIndex() as Number {
        var g = Config.goat;
        if (g >= Config.GOAT_FIRST) {
            return g - Config.GOAT_FIRST;
        }
        // Keep the counter small so the hash cannot overflow a 32-bit Number.
        var secs = Time.now().value();
        if (g == Config.GOAT_DAILY) {
            return Pose.fizz((secs / 86400) % 4096) % Breeds.COUNT;
        }
        return Pose.fizz((secs / 3600) % 4096) % Breeds.COUNT;
    }

    hidden function backdropColor(hour as Number) as Number {
        var mode = Config.backdrop;
        if (mode == Config.BACK_MEADOW) {
            return 0x265B26;
        } else if (mode == Config.BACK_SLATE) {
            return 0x2E3338;
        } else if (mode == Config.BACK_BLACK) {
            return 0x000000;
        }
        // Auto: the light outside the barn.
        if (hour >= 5 && hour < 8) {
            return 0x452852;   // dawn
        } else if (hour >= 8 && hour < 17) {
            return 0x1A5E9E;   // daylight
        } else if (hour >= 17 && hour < 21) {
            return 0x632826;   // dusk
        }
        return 0x0E1626;       // night
    }

    // --------------------------------------------------------------- text

    hidden function drawTime(dc as Dc, clock as System.ClockTime) as Void {
        var timeStr = formatTime(clock);
        var y = mArtist.strapCy;
        var ink = INKS[Config.timeInk];

        if (!Config.halter) {
            // No strap to sit on, so give the digits their own shadow.
            dc.setColor(0x141414, Graphics.COLOR_TRANSPARENT);
            dc.drawText(mArtist.cx + 2, y + 2, mTimeFont, timeStr,
                        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
        dc.setColor(ink, Graphics.COLOR_TRANSPARENT);
        dc.drawText(mArtist.cx, y, mTimeFont, timeStr,
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    hidden function formatTime(clock as System.ClockTime) as String {
        var hour = clock.hour;
        if (!System.getDeviceSettings().is24Hour) {
            hour = hour % 12;
            if (hour == 0) {
                hour = 12;
            }
            return hour.format("%d") + ":" + clock.min.format("%02d");
        }
        return hour.format("%02d") + ":" + clock.min.format("%02d");
    }

    //! The date goes on the forehead, above the eyes. Weekday, month and day if
    //! the forehead is wide enough for it, and just the weekday and day if not -
    //! a 218px panel has about half the room a 454 does.
    hidden function drawDate(dc as Dc, breed as Breed) as Void {
        var info = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        var day = info.day_of_week.toString().toUpper();
        var mon = info.month.toString().toUpper();
        var num = info.day.format("%d");

        var text = day + " " + mon + " " + num;
        if (dc.getTextWidthInPixels(text, mSmallFont) > mArtist.S * 0.42) {
            text = day + " " + num;
        }

        var x = mArtist.cx;
        var y = mArtist.cy - (mArtist.S * 0.265).toNumber();
        var just = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;

        // The date is wider than a blaze, so part of it lands on the coat and
        // part on the marking. A one-pixel halo in the opposite tone keeps it
        // legible across the join whatever the goat is wearing.
        var ink = breed.faceInk;
        var lum = (((ink >> 16) & 0xFF) * 2 + ((ink >> 8) & 0xFF) * 3 + (ink & 0xFF)) / 6;
        var halo = (lum > 128) ? 0x121212 : 0xF2F2F2;
        dc.setColor(halo, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x - 1, y, mSmallFont, text, just);
        dc.drawText(x + 1, y, mSmallFont, text, just);
        if (mArtist.fine) {
            dc.drawText(x, y - 1, mSmallFont, text, just);
            dc.drawText(x, y + 1, mSmallFont, text, just);
        }

        dc.setColor(ink, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, mSmallFont, text, just);
    }

    hidden function drawFields(dc as Dc) as Void {
        // On a small panel the smallest font is proportionally much wider, so
        // the fields move in and up to keep clear of the round edge.
        var tight = mArtist.S < 280;
        var y = mArtist.cy + (mArtist.S * (tight ? 0.300 : 0.322)).toNumber();
        var dx = (mArtist.S * (tight ? 0.240 : 0.265)).toNumber();
        drawField(dc, Config.fieldLeft, mArtist.cx - dx, y);
        drawField(dc, Config.fieldRight, mArtist.cx + dx, y);
    }

    //! Short caption for a field, so the numbers at the bottom are not a riddle.
    hidden function fieldLabel(kind as Number) as String {
        if (kind == Config.FIELD_STEPS) { return "STEPS"; }
        if (kind == Config.FIELD_HEART) { return "HR"; }
        if (kind == Config.FIELD_CALORIES) { return "CAL"; }
        if (kind == Config.FIELD_BATTERY) { return "BATT"; }
        if (kind == Config.FIELD_BODY_BATTERY) { return "BODY"; }
        if (kind == Config.FIELD_NOTIFICATIONS) { return "ALERTS"; }
        if (kind == Config.FIELD_ACTIVE) { return "ACTIVE"; }
        if (kind == Config.FIELD_DISTANCE) {
            return (System.getDeviceSettings().distanceUnits == System.UNIT_STATUTE) ? "MILES" : "KM";
        }
        return "";
    }

    hidden function drawField(dc as Dc, kind as Number, x as Number, y as Number) as Void {
        if (kind == Config.FIELD_NONE) {
            return;
        }
        var text = null;
        var color = FIELD_INK;

        if (kind == Config.FIELD_STEPS) {
            var info = ActivityMonitor.getInfo();
            if (info != null && info.steps != null) {
                text = shortCount(info.steps);
            }
            color = 0xA6DDA6;

        } else if (kind == Config.FIELD_HEART) {
            var hr = heartRate();
            if (hr != null) {
                text = hr.format("%d");
            }
            color = 0xF08A8A;

        } else if (kind == Config.FIELD_CALORIES) {
            var info2 = ActivityMonitor.getInfo();
            if (info2 != null && info2.calories != null) {
                text = shortCount(info2.calories);
            }
            color = 0xF0B070;

        } else if (kind == Config.FIELD_BATTERY) {
            var pct = System.getSystemStats().battery.toNumber();
            text = pct.format("%d") + "%";
            if (pct <= 15) {
                color = 0xF07070;
            } else if (pct <= 35) {
                color = 0xF0D070;
            } else {
                color = 0xA6DDA6;
            }

        } else if (kind == Config.FIELD_BODY_BATTERY) {
            var bb = bodyBattery();
            if (bb != null) {
                text = bb.format("%d");
            }
            color = 0x9FD0F0;

        } else if (kind == Config.FIELD_NOTIFICATIONS) {
            var n = System.getDeviceSettings().notificationCount;
            text = (n == null) ? "0" : n.format("%d");
            color = 0xF0E090;

        } else if (kind == Config.FIELD_DISTANCE) {
            var info3 = ActivityMonitor.getInfo();
            if (info3 != null && info3.distance != null) {
                // ActivityMonitor reports centimetres.
                var metres = info3.distance / 100.0;
                if (System.getDeviceSettings().distanceUnits == System.UNIT_STATUTE) {
                    text = (metres / 1609.34).format("%.1f");
                } else {
                    text = (metres / 1000.0).format("%.1f");
                }
            }
            color = 0xB8C8E8;

        } else if (kind == Config.FIELD_ACTIVE) {
            var info4 = ActivityMonitor.getInfo();
            if (info4 != null && info4.activeMinutesDay != null
                && info4.activeMinutesDay.total != null) {
                text = info4.activeMinutesDay.total.format("%d");
            }
            color = 0xE0A6DD;
        }

        if (text == null) {
            text = "--";
        }

        // Caption above, value below - the caption dimmed so the number reads first.
        var lh = dc.getFontHeight(mSmallFont);
        dc.setColor(GoatArtist.tint(color, 0.62), Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y - (lh * 0.44).toNumber(), mSmallFont, fieldLabel(kind),
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y + (lh * 0.42).toNumber(), mSmallFont, text,
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    hidden function shortCount(value as Number) as String {
        if (value < 10000) {
            return value.format("%d");
        }
        return (value / 1000).format("%d") + "." + ((value % 1000) / 100).format("%d") + "k";
    }

    hidden function heartRate() as Number? {
        var act = Activity.getActivityInfo();
        if (act != null && act.currentHeartRate != null) {
            return act.currentHeartRate;
        }
        var hist = ActivityMonitor.getHeartRateHistory(1, true);
        if (hist != null) {
            var sample = hist.next();
            if (sample != null && sample.heartRate != null
                && sample.heartRate != ActivityMonitor.INVALID_HR_SAMPLE) {
                return sample.heartRate;
            }
        }
        return null;
    }

    hidden function bodyBattery() as Number? {
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

    // ------------------------------------------------------------ always on

    //! AMOLED sleep: a dim outline goat that shifts a few pixels every minute so
    //! nothing is ever burnt into the panel.
    hidden function drawAlwaysOn(dc as Dc, breed as Breed, clock as System.ClockTime) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var ox = (clock.min % 7) - 3;
        var oy = ((clock.min / 7) % 5) - 2;

        mArtist.drawOutline(dc, breed, ox, oy, 0x555555);

        dc.setColor(0xAAAAAA, Graphics.COLOR_TRANSPARENT);
        dc.drawText(mArtist.cx + ox, mArtist.strapCy + oy, mTimeFont, formatTime(clock),
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}
