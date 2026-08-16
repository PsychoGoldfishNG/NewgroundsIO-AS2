/**
 * HttpStatusHelper
 *
 * Turns an HTTP status code into a specific NgioError, so a failed load says
 * "the server is down" or "that file is gone" rather than a bare failure.
 *
 * The Errors constants were already chosen to mirror HTTP - 400, 403, 404, 429,
 * 500, 503, 504 - so most codes map straight across.
 *
 * WHAT ACTIONSCRIPT 2 ACTUALLY GIVES US, because this is easy to over-trust and
 * the answer is bleaker than in AS3:
 *
 *  - LoadVars and XML expose NO HTTP status at all. LoadVars.onData receives the
 *    raw body or `undefined`, and onHTTPStatus exists only on XML/LoadVars in
 *    Flash Player 8+ where the host browser exposes a code - which, as in AS3,
 *    is frequently not at all. CoreTransportHelper therefore synthesises 200 for
 *    "a body arrived" and 500 for "it did not".
 *
 *    That is why this helper exists here despite nothing in the transport
 *    calling it yet: it is the piece that would let AS2 report a real status the
 *    day one becomes available, and it keeps the two libraries answering the
 *    same question the same way in the meantime. Callers that DO have a status -
 *    an XML onHTTPStatus handler, or a caller wrapping its own loader - can use
 *    it today.
 *
 *  - Response headers are out of reach entirely. There is no AS2 equivalent of
 *    HTTPStatusEvent.HTTP_RESPONSE_STATUS, so nothing richer than the code is
 *    available even in principle.
 *
 *  - The inverse case gets no help from the status at all: a 200 carrying an
 *    HTML error page, a proxy interstitial or a captive-portal login is a
 *    perfectly good HTTP response. Only inspecting the BODY catches those, which
 *    is why the JSON decoder has to stay strict.
 */
import io.newgrounds.Errors;
import io.newgrounds.models.objects.NgioError;

class io.newgrounds.helpers.HttpStatusHelper {

	/** No status was reported - the common case, and in AS2 close to the only case */
	public static var UNKNOWN_STATUS:Number = 0;

	/**
	 * Builds the most specific error the status supports.
	 *
	 * @param status HTTP status code, or 0 when none was reported
	 * @param context What was being loaded, for the message
	 * @param detail Optional extra text; pass null when there is none
	 */
	public static function errorForStatus(status:Number, context:String, detail:String) {
		if (detail == undefined) detail = null;

		var code:Number = codeForStatus(status);
		var message:String = describe(status, context);

		if (detail != null && detail.length > 0) {
			message += " (" + detail + ")";
		}

		return io.newgrounds.Errors.getError(code, message, false);
	}

	/**
	 * Maps an HTTP status onto the closest Errors constant.
	 *
	 * Unrecognised codes fall back by CLASS rather than to a generic error, so a
	 * 502 still reads as a server problem and a 418 still reads as a bad
	 * request.
	 */
	public static function codeForStatus(status:Number):Number {
		switch (status) {
			case 400: return io.newgrounds.Errors.BAD_REQUEST;
			case 403: return io.newgrounds.Errors.USER_FORBIDDEN;
			case 404: return io.newgrounds.Errors.NOT_FOUND;
			case 429: return io.newgrounds.Errors.TOO_MANY_REQUESTS;
			case 500: return io.newgrounds.Errors.SERVER_ERROR;
			case 503: return io.newgrounds.Errors.SERVER_UNAVAILABLE;
			case 504: return io.newgrounds.Errors.GATEWAY_TIMEOUT;
		}

		if (status >= 500 && status <= 599) {
			return io.newgrounds.Errors.SERVER_ERROR;
		}

		if (status >= 400 && status <= 499) {
			return io.newgrounds.Errors.BAD_REQUEST;
		}

		// Includes 0 (no status reported) and any 2xx that got here, which means
		// the request succeeded and the BODY was the problem.
		return io.newgrounds.Errors.INVALID_RESPONSE;
	}

	/**
	 * A sentence naming what failed and what the server said, if anything.
	 */
	public static function describe(status:Number, context:String):String {
		if (status == io.newgrounds.helpers.HttpStatusHelper.UNKNOWN_STATUS) {
			// Not a fault - the player simply was not handed a code.
			return context + " failed, and no HTTP status was reported";
		}

		if (status >= 200 && status <= 299) {
			return context + " returned HTTP " + status + " but the body was not valid JSON";
		}

		return context + " failed with HTTP " + status;
	}
}
