/**
 * NgioEventHelper
 *
 * Executes Event.* component calls on behalf of NGIO wrapper methods.
 */
import io.newgrounds.Core;
import io.newgrounds.models.objects.ObjectFactory;

class io.newgrounds.helpers.NgioEventHelper {

	/**
	 * Sends Event.logEvent with host and event name fields.
	 */
	public static function logEvent(core:io.newgrounds.Core, eventName:String, callback:Function, thisArg):Void {
		if (callback == undefined) callback = null;
		if (thisArg == undefined) thisArg = null;
		if (core == null) {
			throw new Error("Core not initialized");
		}

		var component = io.newgrounds.models.objects.ObjectFactory.CreateComponent("Event", "logEvent", null, core);
		if (component == null) {
			throw new Error("Could not create Event.logEvent component");
		}

		component.host = (core.appState.host !== null) ? core.appState.host : "N/A";
		component.event_name = eventName;

		core.executeComponent(component, function(response):Void {
			if (callback == null) {
				return;
			}

			// All three failure layers, the same pattern Medal.unlock and
			// AppState.loadData use.
			//
			// A null response - no HTTP reply at all - left `error` null and so
			// reported the event as logged. A component reporting success:false
			// with no error object did the same. Both are silent failures: the
			// caller is told the event reached the gateway when nothing did.
			var error = null;

			if (response === null || response.success !== true) {
				error = (response !== null && response.error !== null)
					? response.error
					: io.newgrounds.Errors.getError(0, null, false);
			} else {
				var result = response.getResult();

				if (result === null) {
					error = io.newgrounds.Errors.getError(io.newgrounds.Errors.INVALID_RESPONSE, null, false);
				} else if (result.success !== true) {
					error = (result.error !== null) ? result.error : io.newgrounds.Errors.getError(0, null, false);
				}
			}

			callback.call(thisArg, error);
		});
	}
}
