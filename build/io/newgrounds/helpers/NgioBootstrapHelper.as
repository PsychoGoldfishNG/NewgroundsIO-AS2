/**
 * NgioBootstrapHelper
 *
 * Helper class for bootstrapping core, appState, timers and startup sequence to NGIO class.
 */
import io.newgrounds.Core;
import io.newgrounds.models.objects.ObjectFactory;

class io.newgrounds.helpers.NgioBootstrapHelper {

	/**
	 * Initializes the core and performs the necessary bootstrap sequence.
	 *
	 * @param appId Your app's unique identifier from Newgrounds
	 * @param encryptionKey The encryption key from Newgrounds
	 * @param buildVersion Your app's version number in XX.XX.XXXX format (optional)
	 * @param useDebugMode If true, API calls won't actually save to the server (optional)
	 * @return The initialized Core instance
	 */
	public static function doInitializationSequence(appId:String, encryptionKey:String, buildVersion:String, useDebugMode:Boolean):io.newgrounds.Core {
		if (buildVersion == undefined) buildVersion = null;
		if (useDebugMode == undefined) useDebugMode = false;

		var core:io.newgrounds.Core = new io.newgrounds.Core(appId, encryptionKey, buildVersion, useDebugMode);
		logInitialView(core);

		return core;
	}

	/**
	 * Logs the initial view of the app for analytics purposes
	 */
	public static function logInitialView(core:io.newgrounds.Core):Void {
		var logViewComponent = io.newgrounds.models.objects.ObjectFactory.CreateComponent("App", "logView", null, core);
		if (logViewComponent == null) {
			throw new Error("Could not create App.logView component");
		}
		logViewComponent.host = (core.appState.host !== null) ? core.appState.host : "N/A";
		core.executeComponent(logViewComponent, null);
	}

	/**
	 * Sets up an automatic interval that pings the server periodically
	 * This keeps active user sessions from expiring
	 *
	 * @param keepAliveTimeSeconds How often to ping (in seconds)
	 * @param onKeepAliveTick Function to call on each tick
	 * @return The interval ID (use clearInterval to stop)
	 */
	public static function startKeepAlive(keepAliveTimeSeconds:Number, onKeepAliveTick:Function):Number {
		return setInterval(function():Void {
			if (onKeepAliveTick != null) {
				onKeepAliveTick.call(null);
			}
		}, keepAliveTimeSeconds * 1000);
	}
}
