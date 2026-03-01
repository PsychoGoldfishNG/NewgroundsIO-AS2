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

			if (response == null) {
				callback.call(thisArg, null, null);
				return;
			}

			var error = (response.error !== null) ? response.error : null;
			callback.call(thisArg, 'pong', error);
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
			if (response == null) {
				if (callback !== null) {
					callback.call(thisArg, null, null);
				}
				return;
			}

			var error = (response.error !== null) ? response.error : null;
			var result = (response !== null && response.success === true) ? response.getResult() : null;

			if (error === null && result !== null && result.error !== null) {
				error = result.error;
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
