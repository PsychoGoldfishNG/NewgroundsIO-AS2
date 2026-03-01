/**
 * HttpRequestHelper
 *
 * Keeps HTTP request serialization/encryption logic out of Request/Execute model classes.
 *
 * Responsibilities:
 * - Build API-ready request payloads from Request container models
 * - Normalize execute single-vs-array representation
 * - Format Execute items for gateway transmission
 * - Apply secure Execute encryption when required
 */
import io.newgrounds.models.objects.Execute;
import io.newgrounds.models.objects.Request;

class io.newgrounds.helpers.HttpRequestHelper {

	public static function buildGatewayRequestObject(requestModel:io.newgrounds.models.objects.Request):Object {
		var requestObject:Object = {
			app_id: requestModel.app_id
		};

		if (requestModel.session_id != null) {
			requestObject.session_id = requestModel.session_id;
		}

		if (requestModel.debug === true) {
			requestObject.debug = true;
		}

		if (requestModel.echo != null) {
			requestObject.echo = requestModel.echo;
		}

		requestObject.execute = serializeExecuteValue(requestModel);
		return requestObject;
	}

	private static function serializeExecuteValue(requestModel:io.newgrounds.models.objects.Request) {
		if (requestModel.executeIsArray()) {
			var executeArray:Array = [];
			var list:Array = requestModel.getExecuteList();
			for (var i:Number = 0; i < list.length; i++) {
				executeArray.push(serializeExecuteItem(list[i]));
			}
			return executeArray;
		}

		if (requestModel.getExecute() != null) {
			return serializeExecuteItem(requestModel.getExecute());
		}

		return null;
	}

	private static function serializeExecuteItem(executeItem) {
		if (executeItem instanceof io.newgrounds.models.objects.Execute) {
			return serializeExecute(executeItem);
		}

		if (executeItem != null && executeItem.hasOwnProperty("toObject")) {
			return executeItem.toObject();
		}

		return executeItem;
	}

	private static function serializeExecute(executeModel:io.newgrounds.models.objects.Execute):Object {
		var executeObject:Object = {
			component: executeModel.component,
			parameters: executeModel.parameters
		};

		if (executeModel.componentModel != null && executeModel.componentModel.isSecure) {
			if (executeModel.core == null) {
				throw new Error("Core is required for encrypting secure components.");
			}

			var encryptedObject:String = executeModel.core.encryptObject(executeObject);
			return { secure: encryptedObject };
		}

		return executeObject;
	}
}
