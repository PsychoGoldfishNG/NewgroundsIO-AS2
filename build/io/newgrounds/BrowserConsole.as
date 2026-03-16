import flash.external.ExternalInterface;

/**
 * BrowserConsole
 *
 * Utility class for logging messages to the browser's developer console.
 * Falls back to trace() when ExternalInterface is not available.
 */
class io.newgrounds.BrowserConsole {

	/**
	 * Logs a message to the browser console (if available) and optionally to the Flash debug console.
	 * @param message The message to log.
	 * @param traceMessage Whether to also output the message to the Flash debug console using trace (default true)
	 */
	public static function log(message:String, traceMessage:Boolean):Void {
		if (traceMessage == undefined) traceMessage = true;
		if (ExternalInterface.available) {
			ExternalInterface.call("console.log", message);
		}
		if (traceMessage) {
			trace(message);
		}
	}
}
