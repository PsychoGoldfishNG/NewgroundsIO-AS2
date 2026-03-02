/**
 * HttpResponseHelper
 *
 * Keeps HTTP response orchestration out of the Response model class.
 *
 * Responsibilities:
 * - Import top-level response fields into Response
 * - Convert raw result payloads into typed Result models
 * - Propagate response-level error to result models when needed
 * - Push typed results through AppState synchronization
 */
import io.newgrounds.models.objects.ObjectFactory;
import io.newgrounds.models.objects.Response;
import io.newgrounds.encoders.JSON;

class io.newgrounds.helpers.HttpResponseHelper {

	public static function importResponseObject(responseModel:io.newgrounds.models.objects.Response, jsonObject:Object):Void {
		var hasResultProperty:Boolean = (jsonObject != null && jsonObject.result != undefined);
		var typedResults = null;

		var importObject:Object = cloneWithoutResult(jsonObject);
		responseModel.importFromObject(importObject);

		if (hasResultProperty) {
			typedResults = createTypedResults(jsonObject.result, responseModel.core);
			if (typedResults instanceof Array) {
				responseModel.setResultList(typedResults);
			} else if (typedResults != null) {
				responseModel.setResult(typedResults);
			} else {
				responseModel.setResult(null);
			}
		}

		propagateResponseError(responseModel);
		updateAppState(responseModel);
	}

	private static function cloneWithoutResult(source:Object):Object {
		var clone:Object = {};
		if (source == null) {
			return clone;
		}

		for (var key:String in source) {
			if (key != "result") {
				clone[key] = source[key];
			}
		}

		return clone;
	}

	private static function createTypedResults(rawResults, core) {
		if (rawResults == null) {
			return null;
		}

		if (rawResults instanceof Array) {
			var resultList:Array = [];
			for (var i:Number = 0; i < rawResults.length; i++) {
				var typedResult = createSingleTypedResult(rawResults[i], core);
				if (typedResult != null) {
					resultList.push(typedResult);
				}
			}
			return (resultList.length > 0) ? resultList : null;
		}

		return createSingleTypedResult(rawResults, core);
	}

	private static function createSingleTypedResult(rawResult, core) {
		if (rawResult == null || rawResult.component == undefined || rawResult.data == undefined) {
			return null;
		}

		var componentPath:String = String(rawResult.component);
		var dotIndex:Number = componentPath.indexOf(".");
		if (dotIndex <= 0 || dotIndex >= componentPath.length - 1) {
			return null;
		}

		var componentName:String = componentPath.substring(0, dotIndex);
		var methodName:String = componentPath.substring(dotIndex + 1);

		return io.newgrounds.models.objects.ObjectFactory.CreateResult(componentName, methodName, rawResult.data, core);
	}

	private static function propagateResponseError(responseModel:io.newgrounds.models.objects.Response):Void {
		if (responseModel.error == null) {
			return;
		}

		if (responseModel.resultIsList()) {
			var list:Array = responseModel.getResultList();
			for (var i:Number = 0; i < list.length; i++) {
				var resultModel = list[i];
				if (resultModel != null && resultModel.error == null) {
					resultModel.error = responseModel.error;
				}
			}
		} else if (responseModel.getResult() != null && responseModel.getResult().error == null) {
			responseModel.getResult().error = responseModel.error;
		}
	}

	private static function updateAppState(responseModel:io.newgrounds.models.objects.Response):Void {
		if (responseModel.core == null || responseModel.core.appState == null) {
			return;
		}

		if (responseModel.resultIsList()) {
			var list:Array = responseModel.getResultList();
			for (var i:Number = 0; i < list.length; i++) {
				responseModel.core.appState.setValueFromResult(list[i]);
			}
		} else if (responseModel.getResult() != null) {
			responseModel.core.appState.setValueFromResult(responseModel.getResult());
		}
	}
}
