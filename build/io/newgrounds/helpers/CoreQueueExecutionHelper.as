/**
 * CoreQueueExecutionHelper
 *
 * Splits queued Execute wrappers into:
 * - redirect components (executed individually)
 * - components refused locally (never sent; see ComponentValidationHelper)
 * - batchable execute wrappers (sent in one request)
 */
import io.newgrounds.BaseComponent;
import io.newgrounds.Core;
import io.newgrounds.models.objects.Execute;

class io.newgrounds.helpers.CoreQueueExecutionHelper {

	/**
	 * Partitions Core's execute queue for redirect-vs-refused-vs-batch dispatch.
	 *
	 * A batch is partial by nature: the gateway refuses individual components
	 * while running their siblings, which is why loadData asks for medals and
	 * saveSlots together and can get one of them. Local validation has to behave
	 * the same way - refusing the whole batch because one component needs a
	 * session would lose the medals a signed-out title screen legitimately
	 * wanted.
	 */
	public static function partitionExecuteQueue(componentQueue:Array, core:io.newgrounds.Core):Object {
		var redirectComponents:Array = [];
		var batchedExecuteWrappers:Array = [];
		var refusedComponents:Array = [];

		for (var i:Number = 0; i < componentQueue.length; i++) {
			var executeWrapper:io.newgrounds.models.objects.Execute = componentQueue[i];
			var componentModel:io.newgrounds.BaseComponent = executeWrapper.componentModel;
			var redirect:Boolean = (componentModel != null && componentModel.redirect) ? componentModel.redirect : false;

			if (redirect === true) {
				redirectComponents.push(componentModel);
				continue;
			}

			// Refuse what cannot succeed, but keep it in the report - the caller
			// asked for this component and is owed an answer about it, in the
			// same shape the server would have used.
			if (componentModel != null) {
				var validationError = componentModel.getPreflightError();

				if (validationError != null) {
					if (core != null) {
						core.reportNetworkActivity("error", "Refused before sending - " + validationError.message);
					}
					refusedComponents.push({ component: componentModel, error: validationError });
					continue;
				}
			}

			executeWrapper.core = core;
			batchedExecuteWrappers.push(executeWrapper);
		}

		return {
			redirectComponents: redirectComponents,
			batchedExecuteWrappers: batchedExecuteWrappers,
			refusedComponents: refusedComponents
		};
	}

	/**
	 * Adds refused components' results to a response that came back from the
	 * server, so the caller sees one report covering everything it queued.
	 *
	 * Order is not preserved against the original queue - the server's results
	 * come first, then the refusals. Nothing reads results positionally (they
	 * are matched by component name), and pretending to a precise interleaving
	 * the two halves cannot actually guarantee would be worse than being plain
	 * about it.
	 *
	 * @param response The Response the gateway returned, possibly null
	 * @param refusedComponents Array of {component, error} pairs
	 * @param core The Core these belong to
	 * @return The same response, with the refusals merged in
	 */
	public static function mergeRefusalsIntoResponse(response:io.newgrounds.models.objects.Response, refusedComponents:Array, core:io.newgrounds.Core):io.newgrounds.models.objects.Response {
		if (refusedComponents == null || refusedComponents.length == 0) {
			return response;
		}

		// A transport failure means nothing came back to merge into. The
		// refusals are still true, but reporting them on a response that does
		// not exist would dress up a dead network as a partial success - so
		// leave the transport failure to speak for itself.
		if (response == null) {
			return null;
		}

		var refusalResults:Array = io.newgrounds.helpers.ComponentValidationHelper.buildRefusalResults(refusedComponents, core);

		if (refusalResults.length == 0) {
			return response;
		}

		var merged:Array = [];

		if (response.resultIsList()) {
			merged = merged.concat(response.getResultList());
		} else if (response.getResult() != null) {
			merged.push(response.getResult());
		}

		merged = merged.concat(refusalResults);
		response.setResultList(merged);

		return response;
	}
}
