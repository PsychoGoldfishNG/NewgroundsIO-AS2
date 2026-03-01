/**
 * NgioLoaderHelper
 *
 * Centralizes Loader.* URL component execution for open/load NGIO methods.
 */
import io.newgrounds.Core;
import io.newgrounds.models.objects.ObjectFactory;

class io.newgrounds.helpers.NgioLoaderHelper {

	/**
	 * Executes a loader component configured for redirect/browser open behavior.
	 */
	public static function openUrl(core:io.newgrounds.Core, operation:String, target:String, logStat:Boolean, referralName:String):Void {
		if (target == undefined) target = "_blank";
		if (logStat == undefined) logStat = true;
		if (referralName == undefined) referralName = null;
		var component = createLoaderComponent(core, operation, referralName);
		component.browserTarget = target;
		component.log_stat = logStat;
		component.redirect = true;
		core.executeComponent(component, null);
	}

	/**
	 * Executes a loader component configured to return a URL via callback.
	 */
	public static function loadUrl(core:io.newgrounds.Core, operation:String, logStat:Boolean, callback:Function, thisArg, referralName:String):Void {
		if (logStat == undefined) logStat = true;
		if (callback == undefined) callback = null;
		if (thisArg == undefined) thisArg = null;
		if (referralName == undefined) referralName = null;
		var component = createLoaderComponent(core, operation, referralName);
		component.log_stat = logStat;
		component.redirect = false;

		core.executeComponent(component, function(response):Void {

			if (callback !== null) {
				var url:String = null;
				var error = null;

				if (response !== null) {
					var result = response.getResult();
					if (result !== null) {
						url = result.url;
						if (result.error !== null) {
							error = result.error;
						}
					}
				}

				callback.call(thisArg, url, error);
			}
		});
	}

	private static function createLoaderComponent(core:io.newgrounds.Core, operation:String, referralName:String) {
		if (core == null) {
			throw new Error("Core not initialized");
		}

		var component = io.newgrounds.models.objects.ObjectFactory.CreateComponent("Loader", operation, null, core);
		if (component == null) {
			throw new Error("Could not create Loader." + operation + " component");
		}

		component.host = (core.appState.host !== null) ? core.appState.host : "N/A";
		if (referralName !== null) {
			component.referral_name = referralName;
		}

		return component;
	}
}
