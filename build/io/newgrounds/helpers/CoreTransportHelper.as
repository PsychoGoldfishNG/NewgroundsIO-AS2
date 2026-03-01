/**
 * CoreTransportHelper
 *
 * Encapsulates transport-specific delivery for Core requests.
 *
 * - Browser transport: opens URL with getURL()
 * - HTTP transport: LoadVars.sendAndLoad() with onLoad callback
 */
import io.newgrounds.BaseComponent;
import io.newgrounds.Core;

class io.newgrounds.helpers.CoreTransportHelper {

	/**
	 * Sends a request through browser navigation (redirect loaders).
	 */
	public static function sendBrowserRequest(core:io.newgrounds.Core, requestString:String, toExecute, callback:Function, thisArg):Void {
		if (callback == undefined) callback = null;
		if (thisArg == undefined) thisArg = null;

		try {
			var browserTarget:String = resolveBrowserTarget(toExecute);

			if (core.debugNetworkCalls) {
				trace("NETWORK: Opening browser window to " + io.newgrounds.Core.GATEWAY_URL + " with target " + browserTarget);
				trace("         Request Data: " + requestString);
			}

			// In AS2, we use getURL with a POST form submission
			// Build a form POST URL
			getURL(io.newgrounds.Core.GATEWAY_URL + "?request=" + escape(requestString), browserTarget);
		} catch (e) {
			if (core.debugNetworkCalls) {
				trace("NETWORK: Error opening browser window - " + e);
			}
		}

		if (callback != null) {
			callback.call(thisArg, null);
		}
	}

	/**
	 * Sends a request via LoadVars.sendAndLoad() and forwards response to Core.
	 */
	public static function sendHttpRequest(core:io.newgrounds.Core, requestString:String, callback:Function, thisArg):Void {
		if (callback == undefined) callback = null;
		if (thisArg == undefined) thisArg = null;

		System.security.allowDomain("www.newgrounds.io", ".newgrounds.io", "*");

		var sendLV:LoadVars = new LoadVars();
		var receiveLV:LoadVars = new LoadVars();

		sendLV["request"] = requestString;

		var coreRef = core;

		if (core.debugNetworkCalls) {
			trace("NETWORK: Sending request to " + io.newgrounds.Core.GATEWAY_URL);
			trace("         Request Data: " + requestString);
		}

		// Use onData instead of onLoad to capture the raw response text.
		// onData fires before LoadVars URL-decodes the body, giving us the
		// raw string. _rawData is an AS3 URLLoader property that does not
		// exist in AS2 LoadVars.
		receiveLV.onData = function(src:String):Void {
			if (src != undefined && src != null) {
				if (coreRef.debugNetworkCalls) {
					trace("NETWORK: Received response from server");
					trace("         Response Data: " + src);
				}
				coreRef.forwardHTTPResponse(200, src, callback, thisArg);
			} else {
				if (coreRef.debugNetworkCalls) {
					trace("NETWORK: Load failed");
				}
				coreRef.forwardHTTPResponse(500, null, callback, thisArg);
			}
		};

		sendLV.sendAndLoad(io.newgrounds.Core.GATEWAY_URL, receiveLV, "POST");
	}

	/**
	 * Resolves browser target for redirect-capable components.
	 */
	private static function resolveBrowserTarget(toExecute):String {
		var browserTarget:String = "_blank";

		if (toExecute != null && !(toExecute instanceof Array)) {
			var component:io.newgrounds.BaseComponent = null;

			if (toExecute.hasOwnProperty("componentModel")) {
				component = toExecute.componentModel;
			} else if (toExecute.hasOwnProperty("component")) {
				component = toExecute.component;
			}

			if (component != null && component.hasOwnProperty("browserTarget") && component.browserTarget != null) {
				browserTarget = component.browserTarget;
			}
		}

		return browserTarget;
	}
}
