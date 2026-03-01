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

			var error = null;
			if (response !== null) {
				if (response.error !== null) {
					error = response.error;
				} else {
					var result = response.getResult();
					if (result !== null && result.error !== null) {
						error = result.error;
					}
				}
			}
			callback.call(thisArg, error);
		});
	}
}
