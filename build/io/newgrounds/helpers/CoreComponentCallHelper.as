/**
 * CoreComponentCallHelper
 *
 * Handles convenience call flow for Core.callComponent:
 * path parsing, component creation, parameter import, callback adaptation,
 * and normalized error callback behavior.
 */
import io.newgrounds.Core;
import io.newgrounds.models.objects.ObjectFactory;

class io.newgrounds.helpers.CoreComponentCallHelper {

	public static function callComponent(core:io.newgrounds.Core, componentPath:String, componentParams:Object, callback:Function, thisArg, callbackParams:Object):Void {
		if (componentParams == undefined) componentParams = null;
		if (callback == undefined) callback = null;
		if (thisArg == undefined) thisArg = null;
		if (callbackParams == undefined) callbackParams = null;

		var parts:Array = componentPath.split(".");
		if (parts.length != 2) {
			trace("callComponent Error: Invalid component path - " + componentPath);
			callError(callback, thisArg, callbackParams, "Invalid component path: " + componentPath);
			return;
		}

		var componentName:String = parts[0];
		var methodName:String = parts[1];

		try {
			var component = io.newgrounds.models.objects.ObjectFactory.CreateComponent(componentName, methodName, null, core);
			if (component == null) {
				throw new Error("Component not found: " + componentPath);
			}

			if (componentParams != null) {
				if (typeof(component.importFromObject) == "function") {
					component.importFromObject(componentParams);
				} else {
					for (var key:String in componentParams) {
						if (component[key] != undefined) {
							component[key] = componentParams[key];
						}
					}
				}
			}

			var wrappedCallback:Function = null;
			if (callback != null) {
				wrappedCallback = function(result):Void {
					callback.call(thisArg, result, callbackParams);
				};
			}

			core.executeComponent(component, wrappedCallback);
		} catch (e) {
			trace("callComponent Error: " + e);
			callError(callback, thisArg, callbackParams, "Component not found: " + componentPath);
		}
	}

	private static function callError(callback:Function, thisArg, callbackParams:Object, message:String):Void {
		if (callback != null) {
			var errorResult:Object = { success: false, error: message };
			callback.call(thisArg, errorResult, callbackParams);
		}
	}
}
