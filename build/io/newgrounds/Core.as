/**
 * Core
 *
 * Handles core API communication, encryption, and app state management
 *
 * This class is the heart of the Newgrounds.io library. It handles:
 * - Network communication with the Newgrounds servers
 * - Encrypting secure components to prevent cheating
 * - Managing a queue of components to send in batch requests
 * - Parsing server responses and updating the app state
 */
import io.newgrounds.encoders.RC4;
import io.newgrounds.encoders.JSON;
import io.newgrounds.models.objects.Session;
import io.newgrounds.models.objects.ObjectFactory;
import io.newgrounds.helpers.CoreComponentCallHelper;
import io.newgrounds.helpers.CoreQueueExecutionHelper;
import io.newgrounds.helpers.HttpRequestHelper;
import io.newgrounds.helpers.HttpResponseHelper;
import io.newgrounds.helpers.CoreTransportHelper;
import io.newgrounds.BrowserConsole;

class io.newgrounds.Core {

	//==================== CONSTANTS ====================

	/**
	 * The server endpoint where all API calls are sent
	 */
	public static var GATEWAY_URL:String = "https://www.newgrounds.io/gateway_v3.php";

	/**
	 * The crossdomain.xml policy file URL for Flash socket policy
	 */
	public static var POLICY_FILE_URL:String = "https://www.newgrounds.io/crossdomain.xml";

	/**
	 * Maximum number of components that can be bundled in a single request
	 */
	public static var MAX_QUEUE_SIZE:Number = 10;

	/**
	 * The version of the library - used for debugging and error reporting
	 */
	public static var LIBRARY_VERSION:String = "1.0.3b";

	//==================== PUBLIC PROPERTIES ====================

	/**
	 * Set to true to show packets going to and from the server
	 */
	public var debugNetworkCalls:Boolean = false;

	/**
	 * Optional observer for raw gateway traffic, as
	 * function(direction:String, detail:String):Void
	 *
	 * Where debugNetworkCalls only traces, this hands the packets to your own
	 * code, so they can be attached to a log entry, shown in-game, or held
	 * against a failing test. Independent of debugNetworkCalls - either, both
	 * or neither may be enabled.
	 *
	 * `direction` is one of "request", "response" or "error".
	 */
	public var networkObserver:Function = null;

	/**
	 * Stores the app ID provided at initialization
	 */
	public var appId:String;

	/**
	 * Stores the app's version number provided at initialization
	 */
	public var buildVersion:String = null;

	/**
	 * Stores cached data loaded from the server (medals, scoreboards, etc.)
	 */
	public var appState:io.newgrounds.AppState;

	/**
	 * If true, API calls don't actually save to the server
	 */
	public var useDebugMode:Boolean = false;

	//==================== PRIVATE PROPERTIES ====================

	/**
	 * Stores the Base64 encryption key string (stored as-is for RC4)
	 */
	private var _encryptionKey:String;

	/**
	 * Temporary storage for components waiting to be sent to the server
	 */
	private var componentQueue:Array = [];

	//==================== CONSTRUCTOR ====================

	/**
	 * Initialize the Core object with the settings needed to communicate with the server
	 *
	 * @param appId The unique identifier for the app (from Newgrounds)
	 * @param encryptionKey The key used for encryption (from Newgrounds, Base64)
	 * @param buildVersion The app's version number in XX.XX.XXXX format (optional)
	 * @param useDebugMode Whether to run in test mode (optional, default: false)
	 */
	public function Core(appId:String, encryptionKey:String, buildVersion:String, useDebugMode:Boolean) {
		if (buildVersion == undefined) buildVersion = null;
		if (useDebugMode == undefined) useDebugMode = false;

		this.appId = appId;
		// Store Base64 key as-is; RC4.encrypt decodes it internally
		if (encryptionKey == null || encryptionKey.length == 0) {
			trace("Encryption Error: Missing Base64 encryption key");
			this._encryptionKey = "";
		} else {
			this._encryptionKey = encryptionKey;
		}
		this.buildVersion = buildVersion;
		this.useDebugMode = useDebugMode;

		this.componentQueue = [];

		this.appState = new io.newgrounds.AppState(this);

		// Load the crossdomain policy file to allow HTTPS connections
		System.security.loadPolicyFile(io.newgrounds.Core.POLICY_FILE_URL);

		BrowserConsole.log("Newgrounds.io Core initialized with appId: " + appId + ", buildVersion: " + buildVersion + ", useDebugMode: " + useDebugMode + ", libraryVersion: " + LIBRARY_VERSION + " (AS2), hasEncryptionKey: " + (encryptionKey != null && encryptionKey.length > 0), false);
	}

	//==================== PUBLIC METHODS ====================

	/**
	 * Check if the user has an active session
	 */
	public function hasSession():Boolean {
		return (appState != null &&
				appState.session != null &&
				appState.session.id != null &&
				appState.session.id.length > 0);
	}

	/**
	 * Get the session ID
	 */
	public function get sessionId():String {
		if (appState != null && appState.session != null) {
			return appState.session.id;
		}
		return null;
	}

	public function set sessionId(value:String):Void {
		if (appState != null) {
			if (appState.session == null) {
				appState.session = new io.newgrounds.models.objects.Session();
			}
			appState.session.id = value;
		}
	}

	/**
	 * Convenience method to call a component directly with parameters
	 */
	public function callComponent(componentPath:String, componentParams:Object, callback:Function, thisArg, callbackParams:Object):Void {
		if (componentParams == undefined) componentParams = null;
		if (callback == undefined) callback = null;
		if (thisArg == undefined) thisArg = null;
		if (callbackParams == undefined) callbackParams = null;
		io.newgrounds.helpers.CoreComponentCallHelper.callComponent(this, componentPath, componentParams, callback, thisArg, callbackParams);
	}

	/**
	 * Add a component to the queue of components to send
	 */
	public function queueComponent(componentModel:io.newgrounds.BaseComponent):Void {
		if (componentQueue.length < io.newgrounds.Core.MAX_QUEUE_SIZE) {
			var executeModel = io.newgrounds.models.objects.ObjectFactory.CreateObject("Execute", null, this);
			executeModel.setComponent(componentModel);
			componentQueue.push(executeModel);
		} else {
			throw new Error("Component queue limit exceeded");
		}
	}

	/**
	 * Send all queued components to the server in a single request
	 */
	public function executeQueue(callback:Function, thisArg):Void {
		if (callback == undefined) callback = null;
		if (thisArg == undefined) thisArg = null;

		if (componentQueue.length == 0) {
			if (callback != null) {
				callback.call(thisArg, null);
			}
			return;
		}

		var partitionedQueue:Object = io.newgrounds.helpers.CoreQueueExecutionHelper.partitionExecuteQueue(componentQueue, this);
		var redirectComponents:Array = partitionedQueue.redirectComponents;
		var toExecute:Array = partitionedQueue.batchedExecuteWrappers;
		var refusedComponents:Array = partitionedQueue.refusedComponents;

		// Dispatch redirects WITHOUT the caller's callback.
		//
		// A redirect exchanges no JSON - it navigates the browser and then fires its
		// callback with null. Passing the caller's callback here means a queue holding
		// one redirect plus one normal component invokes that callback TWICE: once
		// with null from the redirect, then once with the real Response from the
		// batch below.
		//
		// Callers cannot defend against that, because the empty-queue case above
		// legitimately calls back with null too - so a careful caller reads the first
		// invocation as "nothing to do" and discards the real response.
		//
		// executeQueue() invokes the caller's callback EXACTLY ONCE, with either null
		// or a Response. Redirects are fire-and-forget.
		for (var i:Number = 0; i < redirectComponents.length; i++) {
			executeComponent(redirectComponents[i], null, null);
		}

		componentQueue = [];

		if (toExecute.length == 0) {
			// Unless everything in the queue was refused locally, in which case
			// the caller is owed a report saying so. Answering null here would
			// mean "nothing to do", which is the one thing that did not happen.
			if (refusedComponents != null && refusedComponents.length > 0) {
				if (callback != null) {
					callback.call(thisArg, io.newgrounds.helpers.ComponentValidationHelper.buildRefusalResponseList(refusedComponents, this));
				}
				return;
			}

			if (callback != null) {
				callback.call(thisArg, null);
			}
			return;
		}

		// Some components were refused but others are going out. Send the valid
		// ones, then fold the refusals into the response so the caller gets ONE
		// report covering everything it queued - which is how the gateway would
		// have answered had it done the refusing.
		if (refusedComponents != null && refusedComponents.length > 0) {
			// AS2 closures do not capture `this` - everything the wrapper needs
			// has to be captured in locals first.
			var self:io.newgrounds.Core = this;
			var outerCallback:Function = callback;
			var outerThisArg = thisArg;
			var pendingRefusals:Array = refusedComponents;

			sendRequest(toExecute, false, function(response):Void {
				if (outerCallback != null) {
					outerCallback.call(outerThisArg, io.newgrounds.helpers.CoreQueueExecutionHelper.mergeRefusalsIntoResponse(response, pendingRefusals, self));
				}
			}, null);
			return;
		}

		sendRequest(toExecute, false, callback, thisArg);
	}

	/**
	 * Execute a single component immediately (not queued)
	 */
	public function executeComponent(componentModel:io.newgrounds.BaseComponent, callback:Function, thisArg):Void {
		if (callback == undefined) callback = null;
		if (thisArg == undefined) thisArg = null;

		if (componentModel != null && componentModel.core == null) {
			componentModel.core = this;
		}

		var isRedirect:Boolean = componentModel.redirect;

		// Refuse a component that cannot possibly succeed, without spending a
		// request on it. The refusal is shaped exactly like the server's, so
		// callers need no special case - see ComponentValidationHelper.
		//
		// Redirects are exempt: they navigate the browser rather than exchanging
		// JSON, so there is no response to shape. This is the Loader family
		// (Loader.loadOfficialUrl, Loader.loadMoreGames, and similar) - the
		// only components with redirect=true.
		if (!isRedirect) {
			var validationError = componentModel.getPreflightError();

			if (validationError != null) {
				if (debugNetworkCalls) {
					trace("NETWORK: refused locally - " + validationError.message);
				}
				reportNetworkActivity("error", "Refused before sending - " + validationError.message);

				if (callback != null) {
					callback.call(thisArg, io.newgrounds.helpers.ComponentValidationHelper.buildRefusalResponse(componentModel, validationError, this));
				}
				return;
			}
		}

		var executeModel = io.newgrounds.models.objects.ObjectFactory.CreateObject("Execute", null, this);
		executeModel.core = this;
		executeModel.setComponent(componentModel);

		sendRequest(executeModel, isRedirect, callback, thisArg);
	}

	/**
	 * Encrypts a plain object to obfuscate secure components
	 *
	 * Uses RC4 encryption with the Base64 encryption key
	 *
	 * @param obj The plain object to encrypt
	 * @return The encrypted data encoded as Base64 string
	 */
	public function encryptObject(obj:Object):String {
		var jsonString:String;
		try {
			jsonString = io.newgrounds.encoders.JSON.encode(obj);
		} catch (e) {
			trace("Encryption Error: Failed to convert object to JSON - " + e);
			return null;
		}

		try {
			var encryptedString:String = encryptData(jsonString);
		} catch (e) {
			trace("Encryption Error: Failed to encrypt JSON string - " + e);
			return null;
		}

		return encryptedString;
	}

	/**
	 * Encrypts text using RC4 with the stored Base64 key
	 *
	 * @param text The data to encrypt (usually a JSON string)
	 * @return The encrypted data encoded as Base64 string
	 */
	public function encryptData(text:String):String {
		if (this._encryptionKey == null || this._encryptionKey.length == 0) {
			trace("Encryption Error: Encryption key not set");
			return null;
		}
		return io.newgrounds.encoders.RC4.encrypt(text, this._encryptionKey);
	}

	//==================== PRIVATE METHODS ====================

	/**
	 * The core network communication method
	 */
	private function sendRequest(toExecute, openInBrowser:Boolean, callback:Function, thisArg):Void {
		var requestModel = io.newgrounds.models.objects.ObjectFactory.CreateObject("Request", null, this);

		requestModel.core = this;
		requestModel.app_id = this.appId;
		requestModel.debug = this.useDebugMode;

		if (this.appState != null && this.appState.session != null && this.appState.session.id != null) {
			requestModel.session_id = this.appState.session.id;
		}

		if (toExecute != null) {
			if (toExecute instanceof Array) {
				if (toExecute.length > 0) {
					requestModel.setExecuteList(toExecute);
				}
			} else {
				requestModel.setExecute(toExecute);
			}
		}

		var plainObject:Object = io.newgrounds.helpers.HttpRequestHelper.buildGatewayRequestObject(requestModel);
		var requestString:String = io.newgrounds.encoders.JSON.encode(plainObject);

		if (openInBrowser) {
			io.newgrounds.helpers.CoreTransportHelper.sendBrowserRequest(this, requestString, toExecute, callback, thisArg);
			return;
		}

		io.newgrounds.helpers.CoreTransportHelper.sendHttpRequest(this, requestString, callback, thisArg);
	}

	/**
	 * Hands a raw gateway packet to networkObserver, if one is attached.
	 *
	 * Called by the transport helper at the same points that honour
	 * debugNetworkCalls. Failures in an observer are swallowed: a broken
	 * logger must not take a live request down with it.
	 *
	 * @param direction "request", "response" or "error"
	 * @param detail The raw payload, or an error description
	 */
	public function reportNetworkActivity(direction:String, detail:String):Void {
		if (this.networkObserver == null) {
			return;
		}
		try {
			this.networkObserver.call(null, direction, detail);
		} catch (e) {
		}
	}

	/**
	 * Internal forwarding entry for transport helper event callbacks.
	 */
	public function forwardHTTPResponse(statusCode:Number, responseText:String, callback:Function, thisArg):Void {
		onHTTPResponse(statusCode, responseText, callback, thisArg);
	}

	/**
	 * Handle HTTP response from the server
	 */
	private function onHTTPResponse(statusCode:Number, responseText:String, callback:Function, thisArg):Void {
		
		var responseModel = io.newgrounds.models.objects.ObjectFactory.CreateObject("Response", null, this);

		if (statusCode < 200 || statusCode > 299) {
			// Mapped rather than used directly, matching AS3's Core.onHTTPResponse.
			//
			// Errors.getError(statusCode) treated the HTTP status AS an Errors code.
			// That silently produced a plausible-looking lie: LoadVars reports no
			// HTTP status at all, so CoreTransportHelper synthesises 500 when no
			// body arrives, and 500 happens to be a real Errors constant whose
			// message is "An unexpected error has occurred on the server. If error
			// persists, contact support." Every transport failure the library can
			// have - rate limited, offline, DNS, blocked domain, gateway down - told
			// the game the SERVER had failed and sent the player to support.
			//
			// codeForStatus() falls back by CLASS, so an unlisted code like 502
			// still reads as a server problem instead of becoming an unrecognised
			// code with no message.
			//
			// statusCode is UNKNOWN_STATUS (0) whenever the transport could not
			// learn a real one, which in AS2 is most of the time - LoadVars only
			// reports a status when the host supplies it. That maps to
			// INVALID_RESPONSE and the message "The gateway request failed, and no
			// HTTP status was reported", which is the honest answer. It is NOT
			// dressed up as a 500: claiming the server failed when the request may
			// never have left the machine is what this branch used to do, and it
			// sent players to support for their own dropped connections.
			responseModel.error = io.newgrounds.helpers.HttpStatusHelper.errorForStatus(
				statusCode,
				"The gateway request",
				null
			);
		} else {
			var jsonObject:Object = null;
			try {
				jsonObject = io.newgrounds.encoders.JSON.decode(responseText);
			} catch (error) {
				trace("JSON parsing error - " + error);

				// INVALID_RESPONSE (505), not INVALID_REQUEST (101). 101 is a
				// server-side code meaning "your request was malformed" - the opposite
				// of what happened here, where the request was fine and the server's
				// REPLY could not be parsed. 505 is the one code the client raises
				// rather than the server, and the import-failure branch below already
				// uses it correctly.
				//
				// Routed through the same helper as the branch above, again matching
				// AS3. codeForStatus() returns INVALID_RESPONSE for any 2xx - the
				// status was fine and the BODY was the problem, which is what a proxy
				// interstitial, an error page or a truncated reply looks like - so the
				// code is unchanged here too. The message gains the status and quotes
				// the parser, which names the offending character and position.
				//
				// The detail is read defensively because this decoder throws two
				// different shapes: decode()'s _error() throws an object carrying
				// .message, while the background_decode paths throw bare strings.
				// AS3 can just read error.message; here that would be undefined for
				// half the cases. (errorForStatus ignores a null detail, so an
				// unrecognised shape degrades to no detail rather than "undefined".)
				var parseDetail:String = (error.message != undefined) ? error.message : String(error);

				responseModel.error = io.newgrounds.helpers.HttpStatusHelper.errorForStatus(
					statusCode,
					"The gateway request",
					parseDetail
				);

				jsonObject = null;
			}

			if (jsonObject != null) {
				try {
					io.newgrounds.helpers.HttpResponseHelper.importResponseObject(responseModel, jsonObject);
				} catch (importError) {
					trace("IMPORT ERROR: Error importing into Response model: " + importError);

					responseModel.error = io.newgrounds.Errors.getError(
						io.newgrounds.Errors.INVALID_RESPONSE,
						"Error importing response data"
					);
				}
			}
		}

		if (callback != null) {
			callback.call(thisArg, responseModel);
		}
	}
}
