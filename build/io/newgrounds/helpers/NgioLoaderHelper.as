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

				// A failed load surfaces at either of two levels, and both have to
				// be checked - the same pattern Medal.unlock and ScoreBoard.getScores
				// use.
				//
				// Only the component level was checked here. When the REQUEST fails
				// there is no result to read an error from, so the block was skipped
				// entirely and the caller got (null, null): no url and no reason. Any
				// transport failure - server down, no network, a stream error - looked
				// identical to success with an empty url.
				if (response === null || response.success !== true) {
					error = (response !== null && response.error !== null)
						? response.error
						: io.newgrounds.Errors.getError(0, null, false);
				} else {
					var result = response.getResult();

					if (result === null) {
						error = io.newgrounds.Errors.getError(io.newgrounds.Errors.INVALID_RESPONSE, null, false);
					} else if (result.error !== null) {
						error = result.error;
					} else {
						url = result.url;
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
