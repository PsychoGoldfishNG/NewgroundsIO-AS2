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

		for (var i:Number = 0; i < redirectComponents.length; i++) {
			executeComponent(redirectComponents[i], callback, thisArg);
		}

		componentQueue = [];

		if (toExecute.length == 0) {
			if (callback != null) {
				callback.call(thisArg, null);
			}
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

		var executeModel = io.newgrounds.models.objects.ObjectFactory.CreateObject("Execute", null, this);
		executeModel.core = this;
		executeModel.setComponent(componentModel);

		var isRedirect:Boolean = componentModel.redirect;
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
			responseModel.error = io.newgrounds.Errors.getError(statusCode);
		} else {
			var jsonObject:Object = null;
			try {
				jsonObject = io.newgrounds.encoders.JSON.decode(responseText);
			} catch (error) {
				trace("JSON parsing error - " + error);

				responseModel.error = io.newgrounds.Errors.getError(
					io.newgrounds.Errors.INVALID_REQUEST,
					"Unable to parse JSON response"
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
