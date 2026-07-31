import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

//! Goat Face - a goat looks back at you from the watch, and fidgets every second
//! the watch redraws: it blinks, chews, twitches an ear, glances sideways.
class GoatFaceApp extends Application.AppBase {

    hidden var mView as GoatFaceView?;

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {
        Config.load();
    }

    function onStop(state as Dictionary?) as Void {
        mView = null;
    }

    function getInitialView() as [Views] or [Views, InputDelegates] {
        mView = new GoatFaceView();
        return [mView];
    }

    //! Settings edited in Connect IQ / Garmin Express land here. Reload the cached
    //! values and force a redraw so the new goat shows up immediately.
    function onSettingsChanged() as Void {
        Config.load();
        var v = mView;
        if (v != null) {
            v.onSettingsUpdated();
        }
        WatchUi.requestUpdate();
    }
}
