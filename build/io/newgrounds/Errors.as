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
	 * Maps error codes to human-readable error messages
	 */
	private static var errorMessages:Object = {
		0: "An unknown error has occurred.",
		100: "Missing/empty request.",
		101: "Invalid request.",
		102: "Missing required parameter.",
		103: "Invalid parameter.",
		104: "Your session has expired.",
		107: "Maximum number of components, for a single request, has been exceeded. (Maximum is 10)",
		108: "Your request has exceeded the maximum allowed memory use on the server.",
		109: "Your request took too long to complete and timed out.",
		110: "You must be logged in to do that.",
		111: "Your session was cancelled on the server.",
		200: "Invalid App ID.",
		201: "An encrypted object failed to decrypt on the server. Make sure you are using the correct key, cypher, and encoding format.",
		202: "Requested Medal does not exist, or is not associated with this App ID.",
		203: "Requested ScoreBoard does not exist, or is not associated with this App ID.",
		204: "Requested SaveSlot does not exist, or is not associated with this App ID.",
		400: "There was a problem sending your request.",
		403: "Forbidden.",
		404: "Page not found.",
		429: "You are making too many requests.",
		500: "An unexpected error has occurred on the server. If error persists, contact support.",
		503: "The server is currently down, try again later.",
		504: "Unable to reach the server, try again later.",
		505: "Invalid response received from server."
	};

	//==================== PUBLIC STATIC METHODS ====================

	/**
	 * Look up the default error message for a specific error code
	 */
	public static function getDefaultMessage(errorCode:Number):String {
		if (errorCode == undefined) errorCode = 0;
		if (errorMessages.hasOwnProperty(errorCode)) {
			return errorMessages[errorCode];
		} else {
			return errorMessages[0];
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
