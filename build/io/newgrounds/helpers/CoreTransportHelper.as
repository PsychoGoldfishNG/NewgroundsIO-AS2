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
			core.reportNetworkActivity("request", requestString);

			// In AS2, we use getURL with a POST form submission
			// Build a form POST URL
			getURL(io.newgrounds.Core.GATEWAY_URL + "?request=" + escape(requestString), browserTarget);
		} catch (e) {
			if (core.debugNetworkCalls) {
				trace("NETWORK: Error opening browser window - " + e);
			}
			core.reportNetworkActivity("error", "Error opening browser window - " + e);
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

		// The real HTTP status, when the player can tell us one.
		//
		// onHTTPStatus exists on LoadVars in Flash Player 8+, but it only reports
		// a code when the HOST supplies one. In a browser that usually works; in
		// the standalone player and the IDE test movie it is commonly never
		// called, or called with 0. So this stays UNKNOWN_STATUS unless we
		// genuinely learn otherwise, and both branches below say "no status"
		// rather than inventing one.
		//
		// Worth capturing even though it is often absent: it is the only way a
		// 429 can be told apart from a 503 or a dead connection. Seeing a rate
		// limit AS a rate limit is what lets a caller back off, instead of
		// retrying into a longer lockout.
		var httpStatus:Number = io.newgrounds.helpers.HttpStatusHelper.UNKNOWN_STATUS;

		// Fires before onData. The parameter is named `status`, not `httpStatus`,
		// so it does not shadow the captured variable above - AS2 closures capture
		// enclosing locals, and a same-named parameter would quietly write to the
		// argument instead.
		receiveLV.onHTTPStatus = function(status:Number):Void {
			if (status != undefined && status != null && status > 0) {
				httpStatus = status;
			}
		};

		if (core.debugNetworkCalls) {
			trace("NETWORK: Sending request to " + io.newgrounds.Core.GATEWAY_URL);
			trace("         Request Data: " + requestString);
		}
		core.reportNetworkActivity("request", requestString);

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
				coreRef.reportNetworkActivity("response", src);

				// A body arrived, so the exchange worked. Fall back to 200 when no
				// status was reported - passing UNKNOWN_STATUS here would send a
				// perfectly good response down the error path.
				//
				// Note this differs from AS3, where COMPLETE only fires for a 2xx.
				// AS2 hands us the body whatever the status, so a genuine non-2xx
				// that carried a body is now reported as the error it was, instead
				// of being parsed as if it had succeeded.
				coreRef.forwardHTTPResponse(
					(httpStatus != io.newgrounds.helpers.HttpStatusHelper.UNKNOWN_STATUS) ? httpStatus : 200,
					src, callback, thisArg
				);
			} else {
				if (coreRef.debugNetworkCalls) {
					trace("NETWORK: Load failed" + io.newgrounds.helpers.CoreTransportHelper.describeStatus(httpStatus));
				}

				// Report whatever the player told us, and UNKNOWN_STATUS when it
				// told us nothing.
				//
				// This used to synthesise 500, which Core turned into "An
				// unexpected error has occurred on the server. If error persists,
				// contact support." - blaming the server for what may well be a
				// request that never left the machine. UNKNOWN_STATUS maps to
				// INVALID_RESPONSE instead, and says plainly that no status was
				// reported.
				coreRef.reportNetworkActivity("error",
					"Load failed - no data received from " + io.newgrounds.Core.GATEWAY_URL +
					io.newgrounds.helpers.CoreTransportHelper.describeStatus(httpStatus));
				coreRef.forwardHTTPResponse(httpStatus, null, callback, thisArg);
			}
		};

		sendLV.sendAndLoad(io.newgrounds.Core.GATEWAY_URL, receiveLV, "POST");
	}

	/**
	 * " (HTTP 429)" when a status was reported, "" when none was.
	 *
	 * PUBLIC, and always called fully qualified, because the onData closure above
	 * has to reach it. ActionScript 2 cannot resolve a private static from inside
	 * a nested function - and an unqualified call would not find it either, since
	 * the closure does not carry the class scope.
	 */
	public static function describeStatus(httpStatus:Number):String {
		if (httpStatus == io.newgrounds.helpers.HttpStatusHelper.UNKNOWN_STATUS) {
			return "";
		}
		return " (HTTP " + httpStatus + ")";
	}

	/**
	 * Resolves browser target for redirect-capable components.
	 */
	private static function resolveBrowserTarget(toExecute):String {
		var browserTarget:String = "_blank";

		if (toExecute != null && !(toExecute instanceof Array)) {
			var component:io.newgrounds.BaseComponent = null;

			if (toExecute.componentModel != undefined) {
				component = toExecute.componentModel;
			} else if (toExecute.component != undefined) {
				component = toExecute.component;
			}

			if (component != null && component.browserTarget != undefined && component.browserTarget != null) {
				browserTarget = component.browserTarget;
			}
		}

		return browserTarget;
	}
}
