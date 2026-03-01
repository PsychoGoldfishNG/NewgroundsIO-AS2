/**
 * CoreQueueExecutionHelper
 *
 * Splits queued Execute wrappers into:
 * - redirect components (executed individually)
 * - batchable execute wrappers (sent in one request)
 */
import io.newgrounds.BaseComponent;
import io.newgrounds.Core;
import io.newgrounds.models.objects.Execute;

class io.newgrounds.helpers.CoreQueueExecutionHelper {

	/**
	 * Partitions Core's execute queue for redirect-vs-batch dispatch.
	 */
	public static function partitionExecuteQueue(componentQueue:Array, core:io.newgrounds.Core):Object {
		var redirectComponents:Array = [];
		var batchedExecuteWrappers:Array = [];

		for (var i:Number = 0; i < componentQueue.length; i++) {
			var executeWrapper:io.newgrounds.models.objects.Execute = componentQueue[i];
			var componentModel:io.newgrounds.BaseComponent = executeWrapper.componentModel;
			var redirect:Boolean = (componentModel != null && componentModel.redirect) ? componentModel.redirect : false;

			if (redirect === true) {
				redirectComponents.push(componentModel);
				continue;
			}

			executeWrapper.core = core;
			batchedExecuteWrappers.push(executeWrapper);
		}

		return {
			redirectComponents: redirectComponents,
			batchedExecuteWrappers: batchedExecuteWrappers
		};
	}
}
