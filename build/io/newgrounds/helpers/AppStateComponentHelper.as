/**
 * AppStateComponentHelper
 *
 * Maps AppState property names to the component calls required to load them.
 */
import io.newgrounds.Core;
import io.newgrounds.BaseComponent;
import io.newgrounds.models.objects.ObjectFactory;

class io.newgrounds.helpers.AppStateComponentHelper {

	/**
	 * Builds the list of components needed to load requested AppState properties.
	 */
	public static function buildComponentsForProperties(propertyNames:Array, core:io.newgrounds.Core, host:String):Array {
		var components:Array = [];

		for (var i:Number = 0; i < propertyNames.length; i++) {
			var propertyName:String = propertyNames[i];
			var component:io.newgrounds.BaseComponent = null;

			switch (propertyName) {
				case "gatewayVersion":
					component = io.newgrounds.models.objects.ObjectFactory.CreateComponent("Gateway", "getVersion", null, core);
					break;

				case "currentVersion":
					component = io.newgrounds.models.objects.ObjectFactory.CreateComponent("App", "getCurrentVersion", null, core);
					if (component != null) {
						component["version"] = core.buildVersion;
					}
					break;

				case "hostApproved":
					component = io.newgrounds.models.objects.ObjectFactory.CreateComponent("App", "getHostLicense", null, core);
					if (component != null) {
						component["host"] = host;
					}
					break;

				case "saveSlots":
					component = io.newgrounds.models.objects.ObjectFactory.CreateComponent("CloudSave", "loadSlots", null, core);
					break;

				case "medals":
					component = io.newgrounds.models.objects.ObjectFactory.CreateComponent("Medal", "getList", null, core);
					break;

				case "medalScore":
					component = io.newgrounds.models.objects.ObjectFactory.CreateComponent("Medal", "getMedalScore", null, core);
					break;

				case "scoreBoards":
					component = io.newgrounds.models.objects.ObjectFactory.CreateComponent("ScoreBoard", "getBoards", null, core);
					break;
			}

			if (component != null) {
				components.push(component);
			}
		}

		return components;
	}
}
