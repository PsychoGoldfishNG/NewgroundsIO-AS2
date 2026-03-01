/**
 * Errors
 *
 * Provides error codes and helper methods for generating Error models
 *
 * NOTE: This is a static class - all properties and methods are accessed at class level
 */
import io.newgrounds.models.objects.ObjectFactory;

class io.newgrounds.Errors {

	//==================== ERROR CODE CONSTANTS ====================

	public static var UNKNOWN:Number = 0;

	public static var MISSING_REQUEST:Number = 100;
	public static var INVALID_REQUEST:Number = 101;
	public static var MISSING_PARAMETER:Number = 102;
	public static var INVALID_PARAMETER:Number = 103;

	public static var EXPIRED_SESSION:Number = 104;

	public static var MAX_COMPONENTS_EXCEEDED:Number = 107;
	public static var MEMORY_EXCEEDED:Number = 108;
	public static var TIMED_OUT:Number = 109;

	public static var LOGIN_REQUIRED:Number = 110;
	public static var CANCELLED_SESSION:Number = 111;

	public static var INVALID_APP_ID:Number = 200;
	public static var INVALID_ENCRYPTION:Number = 201;
	public static var INVALID_MEDAL_ID:Number = 202;
	public static var INVALID_SCOREBOARD_ID:Number = 203;
	public static var INVALID_SAVESLOT_ID:Number = 204;

	public static var BAD_REQUEST:Number = 400;
	public static var USER_FORBIDDEN:Number = 403;
	public static var NOT_FOUND:Number = 404;
	public static var TOO_MANY_REQUESTS:Number = 429;

	public static var SERVER_ERROR:Number = 500;
	public static var SERVER_UNAVAILABLE:Number = 503;
	public static var GATEWAY_TIMEOUT:Number = 504;
	public static var INVALID_RESPONSE:Number = 505;

	//==================== ERROR MESSAGES ====================

	/**
	 * Maps error codes to human-readable error messages.
	 * Lazily initialized because AS2 object literals do not support numeric keys.
	 */
	private static var _errorMessages:Object;

	private static function getErrorMessages():Object {
		if (_errorMessages != null) return _errorMessages;
		_errorMessages = new Object();
		_errorMessages[0]   = "An unknown error has occurred.";
		_errorMessages[100] = "Missing/empty request.";
		_errorMessages[101] = "Invalid request.";
		_errorMessages[102] = "Missing required parameter.";
		_errorMessages[103] = "Invalid parameter.";
		_errorMessages[104] = "Your session has expired.";
		_errorMessages[107] = "Maximum number of components, for a single request, has been exceeded. (Maximum is 10)";
		_errorMessages[108] = "Your request has exceeded the maximum allowed memory use on the server.";
		_errorMessages[109] = "Your request took too long to complete and timed out.";
		_errorMessages[110] = "You must be logged in to do that.";
		_errorMessages[111] = "Your session was cancelled on the server.";
		_errorMessages[200] = "Invalid App ID.";
		_errorMessages[201] = "An encrypted object failed to decrypt on the server. Make sure you are using the correct key, cypher, and encoding format.";
		_errorMessages[202] = "Requested Medal does not exist, or is not associated with this App ID.";
		_errorMessages[203] = "Requested ScoreBoard does not exist, or is not associated with this App ID.";
		_errorMessages[204] = "Requested SaveSlot does not exist, or is not associated with this App ID.";
		_errorMessages[400] = "There was a problem sending your request.";
		_errorMessages[403] = "Forbidden.";
		_errorMessages[404] = "Page not found.";
		_errorMessages[429] = "You are making too many requests.";
		_errorMessages[500] = "An unexpected error has occurred on the server. If error persists, contact support.";
		_errorMessages[503] = "The server is currently down, try again later.";
		_errorMessages[504] = "Unable to reach the server, try again later.";
		_errorMessages[505] = "Invalid response received from server.";
		return _errorMessages;
	}

	//==================== PUBLIC STATIC METHODS ====================

	/**
	 * Look up the default error message for a specific error code
	 */
	public static function getDefaultMessage(errorCode:Number):String {
		if (errorCode == undefined) errorCode = 0;
		var msgs:Object = getErrorMessages();
		if (msgs[errorCode] != undefined) {
			return msgs[errorCode];
		} else {
			return msgs[0];
		}
	}

	/**
	 * Create an Error model with a specified code and custom message
	 */
	public static function getError(errorCode:Number, errorMessage:String, appendMessage:Boolean) {
		if (errorCode == undefined) errorCode = 0;
		if (errorMessage == undefined) errorMessage = null;
		if (appendMessage == undefined) appendMessage = false;

		var errorModel:io.newgrounds.models.objects.NgioError = io.newgrounds.models.objects.ObjectFactory.CreateObject("Error");

		errorModel.code = errorCode;

		if (errorMessage == null || errorMessage.length == 0) {
			errorMessage = getDefaultMessage(errorCode);
			appendMessage = false;
		}

		if (appendMessage) {
			var defaultMessage:String = getDefaultMessage(errorCode);
			errorMessage = defaultMessage + " " + errorMessage;
		}

		errorModel.message = errorMessage;

		return errorModel;
	}
}
