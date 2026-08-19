import io.newgrounds.Core;
import io.newgrounds.models.objects.ObjectFactory;

/**
 * ComponentValidationHelper
 *
 * Refuses components that cannot possibly succeed, before they cost a network
 * round trip - and shapes the refusal so callers cannot tell it from the
 * server's own.
 *
 * WHY THIS MATTERS MORE THAN "SAVING A REQUEST":
 *
 * The gateway limits requests per time window. A game that calls medal.unlock()
 * on every scoring event while the player has no session spends that budget on
 * calls whose outcome was knowable before they left the machine - and then a
 * call that COULD have succeeded gets a 429.
 *
 * THE CONTRACT:
 *
 * A locally-refused call is indistinguishable from a server-refused one except
 * by how fast it arrives. Same Response shape, same result shape, same error
 * codes - the ones the live gateway was observed to return for these exact
 * conditions. Nothing downstream needs a special case, and in particular the
 * three-layer error check in AppState.loadData and the NGIO wrappers reads a
 * synthesized refusal exactly as it reads a real one.
 *
 * That is the whole design rule here: DO NOT INVENT A NEW FAILURE SHAPE. A
 * local error that arrives differently from a server error would mean every
 * caller needs two code paths for one condition.
 */
class io.newgrounds.helpers.ComponentValidationHelper {

	/**
	 * Builds the Response the gateway would have returned had it refused this
	 * component itself.
	 *
	 * Envelope-level success is TRUE, because the request was well formed - the
	 * component is what failed. That is exactly how the server reports "you are
	 * not logged in", and it is what puts the error at the layer callers already
	 * check.
	 *
	 * @param component The component that failed validation
	 * @param validationError Why it failed
	 * @param core The Core the response belongs to
	 * @return A Response carrying one failed result
	 */
	public static function buildRefusalResponse(component:io.newgrounds.BaseComponent, validationError, core:io.newgrounds.Core):io.newgrounds.models.objects.Response {
		// Untyped deliberately. The factory is declared to return BaseObject, and
		// AS2 has no implicit downcast and no `as` operator, so annotating this
		// as Response is a compile error. AS3 writes `as Response` here; the
		// rest of this library does the same untyped thing - see Core.as.
		var response = io.newgrounds.models.objects.ObjectFactory.CreateObject("Response", null, core);

		if (response == null) {
			return null;
		}

		response.core = core;
		response.app_id = (core != null) ? core.appId : null;

		// The REQUEST was fine. The component was not. Reporting envelope
		// failure here would say the whole batch was rejected, which is a
		// different and worse claim.
		response.success = true;

		response.setResult(buildRefusalResult(component, validationError, core));

		return response;
	}

	/**
	 * Builds the single failed result for a refused component.
	 *
	 * Returns null when no result model exists for the component name - an
	 * unrecognised name yields null from the factory.
	 */
	public static function buildRefusalResult(component:io.newgrounds.BaseComponent, validationError, core:io.newgrounds.Core):io.newgrounds.BaseResult {
		var result:io.newgrounds.BaseResult = createResultFor(component, core);

		if (result == null) {
			return null;
		}

		result.core = core;
		result.success = false;
		result.error = validationError;

		return result;
	}

	/**
	 * Builds results for a whole queue of refused components.
	 *
	 * @param refusals Array of {component, error} pairs
	 * @param core The Core the results belong to
	 * @return Array of failed result models, in the order given
	 */
	public static function buildRefusalResults(refusals:Array, core:io.newgrounds.Core):Array {
		var results:Array = [];

		if (refusals == null) {
			return results;
		}

		for (var i:Number = 0; i < refusals.length; i++) {
			var result:io.newgrounds.BaseResult = buildRefusalResult(
				refusals[i].component,
				refusals[i].error,
				core
			);

			if (result != null) {
				results.push(result);
			}
		}

		return results;
	}

	/**
	 * Builds a Response holding several refused components' results.
	 *
	 * Used when EVERY component in a queue was refused, so no request is sent at
	 * all.
	 */
	public static function buildRefusalResponseList(refusals:Array, core:io.newgrounds.Core):io.newgrounds.models.objects.Response {
		// Untyped deliberately. The factory is declared to return BaseObject, and
		// AS2 has no implicit downcast and no `as` operator, so annotating this
		// as Response is a compile error. AS3 writes `as Response` here; the
		// rest of this library does the same untyped thing - see Core.as.
		var response = io.newgrounds.models.objects.ObjectFactory.CreateObject("Response", null, core);

		if (response == null) {
			return null;
		}

		response.core = core;
		response.app_id = (core != null) ? core.appId : null;
		response.success = true;
		response.setResultList(buildRefusalResults(refusals, core));

		return response;
	}

	/**
	 * Asks the factory for the result model matching a component.
	 *
	 * A component's objectName is "Component.method" - the same string the
	 * result factory keys on, split back into its two halves.
	 */
	private static function createResultFor(component:io.newgrounds.BaseComponent, core:io.newgrounds.Core):io.newgrounds.BaseResult {
		if (component == null) {
			return null;
		}

		var fullName:String = component.objectName;

		if (fullName == null) {
			return null;
		}

		// String.indexOf DOES exist in AVM1 - it is Array.indexOf that does not.
		var splitAt:Number = fullName.indexOf(".");

		if (splitAt < 1 || splitAt >= fullName.length - 1) {
			return null;
		}

		return io.newgrounds.models.objects.ObjectFactory.CreateResult(
			fullName.substring(0, splitAt),
			fullName.substring(splitAt + 1),
			null,
			core
		);
	}
}
