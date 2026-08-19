/**
 * NgioGatewayHelper
 *
 * Hosts shared Gateway utility calls for NGIO wrapper methods.
 */
import io.newgrounds.Core;
import io.newgrounds.models.objects.ObjectFactory;

class io.newgrounds.helpers.NgioGatewayHelper {

	private static var RETURN_DATETIME:String = "datetime";
	private static var RETURN_TIMESTAMP:String = "timestamp";
	private static var RETURN_DATE:String = "date";

	/**
	 * Loads server datetime string from Gateway.getDateTime.
	 */
	public static function loadGatewayDateTime(core:io.newgrounds.Core, callback:Function, thisArg):Void {
		if (thisArg == undefined) thisArg = null;
		executeGatewayDateTime(core, callback, thisArg, RETURN_DATETIME);
	}

	/**
	 * Loads server timestamp value from Gateway.getDateTime.
	 */
	public static function loadGatewayTimestamp(core:io.newgrounds.Core, callback:Function, thisArg):Void {
		if (thisArg == undefined) thisArg = null;
		executeGatewayDateTime(core, callback, thisArg, RETURN_TIMESTAMP);
	}

	/**
	 * Loads server time as native Date object.
	 */
	public static function loadGatewayDate(core:io.newgrounds.Core, callback:Function, thisArg):Void {
		if (thisArg == undefined) thisArg = null;
		executeGatewayDateTime(core, callback, thisArg, RETURN_DATE);
	}

	/**
	 * Sends Gateway.ping and returns callback payload (pong/error).
	 */
	public static function sendPing(core:io.newgrounds.Core, callback:Function, thisArg):Void {
		if (callback == undefined) callback = null;
		if (thisArg == undefined) thisArg = null;
		if (core == null) {
			throw new Error("Core not initialized");
		}

		var component = io.newgrounds.models.objects.ObjectFactory.CreateComponent("Gateway", "ping", null, core);
		if (component == null) {
			throw new Error("Could not create Gateway.ping component");
		}

		core.executeComponent(component, function(response):Void {
			if (callback == null) {
				return;
			}

			// All three failure layers, the same pattern Medal.unlock and
			// AppState.loadData use.
			//
			// A null response - no HTTP reply at all - handed the caller
			// (null, null): no pong and no reason, which reads as "the gateway
			// answered with nothing" rather than "nothing answered". The
			// component level was never checked at all, and 'pong' was returned
			// alongside any envelope error rather than instead of it.
			var error = null;

			if (response == null || response.success !== true) {
				error = (response != null && response.error != null)
					? response.error
					: io.newgrounds.Errors.getError(0, null, false);
			} else {
				var result = response.getResult();

				if (result == null) {
					error = io.newgrounds.Errors.getError(io.newgrounds.Errors.INVALID_RESPONSE, null, false);
				} else if (result.success !== true) {
					error = (result.error != null) ? result.error : io.newgrounds.Errors.getError(0, null, false);
				}
			}

			callback.call(thisArg, (error == null) ? 'pong' : null, error);
		});
	}

	private static function executeGatewayDateTime(core:io.newgrounds.Core, callback:Function, thisArg, returnType:String):Void {
		if (core == null) {
			throw new Error("Core not initialized");
		}

		var component = io.newgrounds.models.objects.ObjectFactory.CreateComponent("Gateway", "getDateTime", null, core);
		if (component == null) {
			throw new Error("Could not create Gateway.getDateTime component");
		}

		core.executeComponent(component, function(response):Void {
			// All three failure layers, the same pattern Medal.unlock and
			// AppState.loadData use.
			//
			// A null response - no HTTP reply at all - handed the caller
			// (null, null): no datetime and no reason. A component reporting
			// success:false with no error object did the same, since only
			// result.error was consulted.
			var error = null;
			var result = null;

			if (response == null || response.success !== true) {
				error = (response != null && response.error != null)
					? response.error
					: io.newgrounds.Errors.getError(0, null, false);
			} else {
				result = response.getResult();

				if (result == null) {
					error = io.newgrounds.Errors.getError(io.newgrounds.Errors.INVALID_RESPONSE, null, false);
				} else if (result.success !== true) {
					error = (result.error != null) ? result.error : io.newgrounds.Errors.getError(0, null, false);
				}
			}

			if (callback !== null) {
				if (error !== null || result === null) {
					callback.call(thisArg, null, error);
				} else if (returnType == RETURN_DATETIME) {
					callback.call(thisArg, result.datetime, error);
				} else if (returnType == RETURN_DATE) {
					callback.call(thisArg, new Date(result.timestamp * 1000), error);
				} else {
					callback.call(thisArg, result.timestamp, error);
				}
			}
		});
	}
}
