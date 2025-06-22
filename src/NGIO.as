class NGIO 
{
    public static var core:io.newgrounds.core;

    // status constants
	public static var STATUS_INITIALIZED = "initialized";
	public static var STATUS_CHECKING_LOCAL_VERSION:String = "checking-local-version";
	public static var STATUS_LOCAL_VERSION_CHECKED:String = "local-version-checked";
	public static var STATUS_PRELOADING_ITEMS:String = "preloading-items";
	public static var STATUS_ITEMS_PRELOADED:String = "items-preloaded";
	public static var STATUS_SESSION_UNINITIALIZED:String = "session-uninitialized";
	public static var STATUS_WAITING_FOR_SERVER:String = "waiting-for-server";
	public static var STATUS_LOGIN_REQUIRED:String = "login-required";
	public static var STATUS_WAITING_FOR_USER:String = "waiting-for-user";
	public static var STATUS_LOGIN_CANCELLED:String = "login-cancelled";
	public static var STATUS_LOGIN_SUCCESSFUL:String = "login-successful";
	public static var STATUS_LOGIN_FAILED:String = "login-failed";
	public static var STATUS_USER_LOGGED_OUT:String = "user-logged-out";
	public static var STATUS_SERVER_UNAVAILABLE:String = "server-unavailable";
	public static var STATUS_EXCEEDED_MAX_ATTEMPTS:String = "exceeded-max-attempts";
	public static var STATUS_UNKNOWN:String = "unknown";
	public static var STATUS_READY:String = "ready";

    public static var session_cache:Number = -1;
    public static var session_cache_timeout:Number = 3000;
    public static var passport_open:Boolean = false;
    public static var localVersion:String = null;

    // the component library can use this to link the medal popup
    public static var medalPopup:MovieClip = null;

    // the component library can use this to link the scoreboard popup
    public static var scoreBoardComponent:MovieClip = null;

    // this will be used as an interval timer for keeping sessions alive
    public static var pingTimer:Number;

    public static var audio:Object = {
        muted: false,
        volume: 100
    };

    /**
    * Initializes the Newgrounds.io API
    * @param app_id Your application's unique ID
    * @param encryption_key Your application's encryption key
    * @param debug Whether or not to enable debug mode
    */
    public static function init(app_id:String, encryption_key:String, localVersion:String, debug:Boolean):Void
    {
        if (debug !== true) debug = false;
        NGIO.localVersion = localVersion ? localVersion : null;
        NGIO.core = new io.newgrounds.core(app_id, encryption_key, debug);
        NGIO.core.executeComponent(new io.newgrounds.models.components.App.logView());
    }

    /**
    * Checks if the core object has been initialized
    * @return Boolean Whether or not the core object has been initialized
    */
    private static function checkCore():Boolean
    {
        if (!NGIO.core) {
            throw new Error("You must call NGIO.init before using any other NGIO functions.");
            return false;
        }
        return true;
    }

    /**
    * Checks if a session has been started
    * @return Boolean Whether or not a session has been started
    */
    public static function hasSession():Boolean
    {
        if (!NGIO.checkCore()) return false;

        if (!NGIO.core.session) {
            trace("You must call NGIO.checkSession before using any other NGIO functions.");
            return false;
        }
        return true;
    }

    /**
    * Checks if a user has been loaded
    * @return Boolean Whether or not a user has been loaded
    */
      public static function hasUser():Boolean {
	if (!NGIO.hasSession) {
		return false;
	}
	return true;
     }

    /**
    * Opens the Newgrounds.io passport in a new window
    */
    public static function openPassport():Void
    {
        if (NGIO.core.session.passport_url) {
            NGIO.passport_open = true;
            getURL(NGIO.core.session.passport_url, "_blank");
        } else {
            trace("You need to run a checkSession call before opening passport.");
        }
    }

    /**
    * Checks the status of a user session.  
    * Sessions ids may have been passsed as FlashVars or saved as shared objects. Ths will check for those first
    * and then make a server call to check the session.  If there is no session, or the session is expired, it will 
    * start a new one.
    *
    * @param callback A function to call when the session check is complete. The callback will receive a response object with the following properties:
    * - status: A string representing the current status of the session
    * - user: A User object representing the current user, or null if no user has been loaded yet
    * - error: An Error object if there was a problem checking the session
    * @param thisArg The scope to call the callback in
    */
    public static function checkSession(callback:Function, thisArg:Object):Void
    {
        var time:Number = (new Date()).getTime();
        var elapsed = time - NGIO.session_cache;

        // If we're in a cached state, or we've already loaded a user, we'll just make a result object
        // and attach the core session object.  No need to make a server call.
        if (elapsed < NGIO.session_cache_timeout || NGIO.core.session.user) {
            var result = new io.newgrounds.models.results.App.checkSession({success:true, session:NGIO.core.session});
            NGIO.onCheckSession(result, {callback:callback, thisArg:thisArg});
            return;
        }

        // update the cached time so we have a small cooldown between server requests
        NGIO.session_cache = (new Date()).getTime();

        // If we're not in a cached state, we'll make a server call to check the session
        var component;
        if (NGIO.core.session && NGIO.core.session.id) {
            component = new io.newgrounds.models.components.App.checkSession();
        } else {
            component = new io.newgrounds.models.components.App.startSession();
        }
        NGIO.core.executeComponent(component, NGIO.onCheckSession, {}, {callback:callback, thisArg:thisArg});
    }

    /**
    * Handles the result of a session check
    * @param result The result of the session check
    * @param data The data object passed to the checkSession call (contains the callback and thisArg passed to checkSession)
    */
    public static function onCheckSession(result:Object, data:Object):Void
    {
        // default response object
        var response = {
            status: NGIO.STATUS_SESSION_UNINITIALIZED,
            user: null,
            error: null
        };

        // if we have no result, something went seriously wrong
        if (!result) {
            response.status = NGIO.STATUS_SERVER_UNAVAILABLE;
            response.error = new io.newgrounds.models.objects.Error({message:"Either the server is unavailable, or something went wrong with the request."});

        // if we have a result, we can see what our status is
        } else {

            // If we got a false result, let's dive into it and try and figure out what status to send
            if (result.success == false)
            {
                // typically we would get a checkSession result object. But if it's a Response object
                // it means we got a higher level error and the entire API call was bad.
                // All we can do here is note that the status is unknown and hope the error object helps
                if (result instanceof io.newgrounds.models.objects.Response) {
                    response.status = NGIO.STATUS_UNKNOWN;
                    response.error = result.error;
                
                // If we get error code 111, the user opened passport and then hit the cancel button.
                } else if (result.error && result.error.code === 111) {
                    response.status = NGIO.STATUS_LOGIN_CANCELLED;
                    response.error = result.error;

                    // in this event, we can note that passport isn't open anymore
                    NGIO.passport_open = false;

                // in pretty much any other false case, the session is just missing or expired, so we can request a new one
                } else {
                    NGIO.startSession(data.callback, data.thisArg);
                    
                    // the new session will trigger the callback, so we can quit now
                    return; 
                }

        
            // if we get here, we have a valid session object, so we can extract our status by looking at that
            } else {

                // we may not have a new session object from the server. If that's the case, use the one currently attached to the core
                var session = result.session ? result.session : NGIO.core.session;

                // whatever we use, let's attach it to the core just in case we check this again during a cached state
                NGIO.core.setSession(session);

                // if we have a user loaded, we're ready to go!
                if (session.user) {
                    response.status = NGIO.STATUS_READY;
                    response.user = session.user;

                    // if the user wants to remember this session, save it in a sharedobject for later
                    if (session.remember) {
                        NGIO.core.saveSession();
                    }

                    // let's run a timer in the background to keep the session alive
                    NGIO.startPingTimer();
                
                // if we've flagged that passport is open, assume we're waiting for the user to finish logging in
                } else if (NGIO.passport_open) {
                    response.status = NGIO.STATUS_WAITING_FOR_USER;
                
                // otherwise, we can report that user needs to ipen passport and log in
                } else {
                    response.status = NGIO.STATUS_LOGIN_REQUIRED;
                }
            }
        }

        // check for a callback and pass the result to it
        if (data.callback) {
            if (data.thisArg) {
                data.callback.call(data.thisArg, response);
            } else {
                data.callback(response);
            }
        }
    }

    /**
    * Starts a new session.
    *
    * @param callback A function to call when the session is started. The callback will receive a response object with the following properties:
    * - status: A string representing the current status of the session
    * - user: A User object representing the current user, or null if no user has been loaded yet
    * - error: An Error object if there was a problem starting the session
    * @param thisArg The scope to call the callback in
    */
    public static function startSession(callback:Function, thisArg:Object):Void
    {
        // send a startSession component, but handle it the same as a checkSession call
        var component = new io.newgrounds.models.components.App.startSession();
        NGIO.core.executeComponent(component, NGIO.onCheckSession, {}, {callback:callback, thisArg:thisArg});
    }

    public static function endSession(callback:Function, thisArg:Object):Void
    {
        if (!NGIO.checkCore()) return;

        NGIO.session_cache = -1;

        if (NGIO.core.session && NGIO.core.session.id) {
            var component = new io.newgrounds.models.components.App.endSession();
            NGIO.core.executeComponent(component, callback, thisArg);
        }
        NGIO.core.clearSession();
    }

    public static function startPingTimer():Void
    {
        if (NGIO.pingTimer) clearInterval(NGIO.pingTimer);
        NGIO.pingTimer = setInterval(NGIO.sendPing, 300000);
    }

    /**
    * Loads all the data and objects associated with the app from the server.
    * This includes the most recent version available, whether this host is licensed to use the app,
    * the list of medals you can unlock, the list of available scoreboards, and the list of cloudsave slots.
    *
    * @param config An array of strings representing the data to load.  Valid values are: 'currentVersion', 'hostApproved', 'saveSlots', 'medals', 'scoreboards'
    * @param callback A function to call when the data load is complete. The callback will receive a response object with the loaded data.
    * @param thisArg The scope to call the callback in
    */
    public static function loadAppData(config:Array, callback:Function, thisArg:Object):Void
    {
        if ((!config instanceof Array) || config.length < 1) return;

        if (!NGIO.checkCore()) return;

        var component, objectName;

        for (var i = 0; i < config.length; i++) {
            
            component = null;

            switch(config[i].toLowerCase()) {
            
                case 'currentversion':
                    component = new io.newgrounds.models.components.App.getCurrentVersion({version:NGIO.localVersion});                    
                    break;

                case 'hostapproved':
                    component = new io.newgrounds.models.components.App.getHostLicense();
                    break;

                case 'saveslots':
                    component = new io.newgrounds.models.components.CloudSave.loadSlots();
                    break;

                case 'medals':
                    component = new io.newgrounds.models.components.Medal.getList();
                    break;

                case 'medalscore':
                    component = new io.newgrounds.models.components.Medal.getMedalScore();
                    break;

                case 'scoreboards':
                    component = new io.newgrounds.models.components.ScoreBoard.getBoards();
                    break;
            }

            if (component) NGIO.core.queueComponent(component);
        }

        if (NGIO.core.hasQueuedComponents()) {
            NGIO.core.executeQueue(NGIO.onLoadAppData, {}, {callback:callback, thisArg:thisArg});
        } else {
            var response = {success:false, error:{message:"Invalid config, no data will be loaded."}};
            NGIO.onLoadAppData(response, {callback:callback, thisArg:thisArg});
        }
    }

    /**
    * Handles the result of an app data load
    * @param result The result of the app data load
    * @param data The data object passed to the loadAppData call (contains the callback and thisArg passed to loadAppData)
    */
    public static function onLoadAppData(results:Array, data:Object):Void
    {
        var response = {};

        var success = false;
        
        if (results instanceof Array) {
            for (var i = 0; i < results.length; i++) {
                var result = results[i];
                
                switch(result.getObjectName()) {
                    case "App.getCurrentVersion":
                        response.currentVersion = result.current_version;
                        response.clientDeprecated = result.client_deprecated;
                        success = true;
                        break;
                    case "App.getHostLicense":
                        response.hostApproved = result.host_approved;
                        success = true;
                        break;
                    case "CloudSave.loadSlots":
                        response.saveSlots = result.slots;
                        success = true;
                        break;
                    case "Medal.getList":
                        response.medals = result.medals;
                        success = true;
                        break;
                    case "Medal.getMedalScore":
                        response.medals = result.medal_score;
                        success = true;
                        break;
                    case "ScoreBoard.getBoards":
                        response.scoreBoards = result.scoreboards;
                        success = true;
                        break;
                }
            }
        }

        response.success = success;

        if (!success) {
            response.error = results.error && results.error.message ? results.error.message : "There was a problem loading the app data.";
            trace("NGIO.loadAppData: " + response.error);
        }

        if (data.callback) {
            if (data.thisArg) {
                data.callback.call(data.thisArg, response);
            } else {
                data.callback(response);
            }
        }
    }

    /**
    * Gets the user associated with the current session, or null if no user is loaded
    * @return User The user object associated with the current session, or null if no user has been loaded
    */
    public static function getUser():io.newgrounds.models.objects.User
    {
        return NGIO.hasUser() ? NGIO.core.session.user : null;
    }

    /**
    * Gets the latest available version number (in x.y.z format) of this app, returns a string result to the provided callback
    * @param callback A function to call when the version number is retrieved
    * @param thisArg The scope to call the callback in
    */
    public static function getCurrentVersion(callback:Function, thisArg:Object):Void
    {
        if (!NGIO.checkCore()) return;

        if (typeof(callback) !== "function") throw new Error("getCurrentVersion requires a callback function");
        if (typeof thisArg === "undefined") thisArg = {};

        if (NGIO.core.currentVersion !== null) {
            NGIO.onGetCurrentVersion({}, {callback:callback, thisArg:thisArg});
        } else {
            var component = new io.newgrounds.models.components.App.getCurrentVersion();
            NGIO.core.executeComponent(component, NGIO.onGetCurrentVersion, {}, {callback:callback, thisArg:thisArg});
        }
    }

    /**
    * Handles the result of a getCurrentVersion call
    * @param result The result of the getCurrentVersion call
    * @param data The data object passed to the getCurrentVersion call (contains the callback and thisArg parameters)
    */
    public static function onGetCurrentVersion(result:Object, data:Object):Void
    {
        // the actual version number will get cached in the core object, so we'll extract from there and ignore the result object
        data.callback.call(data.thisArg, NGIO.core.currentVersion);
    }

    /**
    * Checks if this version of the app client is deprecated, returns a boolean result to the provided callback
    * @param callback A function to call when the version number is retrieved
    * @param thisArg The scope to call the callback in
    */
    public static function getClientDeprecated(callback:Function, thisArg:Object):Void
    {
        if (!NGIO.checkCore()) return;

        if (typeof(callback) !== "function") throw new Error("getClientDeprecated requires a callback function");
        if (typeof thisArg === "undefined") thisArg = {};
        
        if (NGIO.core.clientDeprecated !== null) {
            NGIO.onGetClientDeprecated({}, {callback:callback, thisArg:thisArg});
        } else {
            var component = new io.newgrounds.models.components.App.getCurrentVersion();
            NGIO.core.executeComponent(component, NGIO.onGetClientDeprecated, {}, {callback:callback, thisArg:thisArg});
        }
    }

    /**
    * Handles the result of a getClientDeprecated call
    * @param result The result of the getClientDeprecated call
    * @param data The data object passed to the getClientDeprecated call (contains the callback and thisArg parameters)
    */
    public static function onGetClientDeprecated(result:Object, data:Object):Void
    {
        // the actual deprecation value will get cached in the core object, so we'll extract from there and ignore the result object
        data.callback.call(data.thisArg, NGIO.core.clientDeprecated);
    }

    /**
    * Checks if this host is licensed to use this app, returns a boolean result to the provided callback
    * @param callback A function to call when the version number is retrieved
    * @param thisArg The scope to call the callback in
    */
    public static function getHostApproved(callback:Function, thisArg:Object):Void
    {
        if (!NGIO.checkCore()) return;

        if (typeof(callback) !== "function") throw new Error("getHostApproved requires a callback function");
        if (typeof thisArg === "undefined") thisArg = {};

        if (NGIO.core.hostApproved !== null) {
            NGIO.onGetHostApproved({}, {callback:callback, thisArg:thisArg});
        } else {
            var component = new io.newgrounds.models.components.App.getHostLicense();
            NGIO.core.executeComponent(component, NGIO.onGetHostApproved, {}, {callback:callback, thisArg:thisArg});
        }
    }

    /**
    * Handles the result of a getHostApproved call
    * @param result The result of the getHostApproved call
    * @param data The data object passed to the getHostApproved call (contains the callback and thisArg parameters)
    */
    public static function onGetHostApproved(result:Object, data:Object):Void
    {
        // the actual approved value will get cached in the core object, so we'll extract from there and ignore the result object
        data.callback.call(data.thisArg, NGIO.core.hostApproved);
    }

    /**
    * Gets the list of medals available for this app, returns an array of Medal objects to the provided callback
    * @param callback A function to call when the medal list retrieved
    * @param thisArg The scope to call the callback in
    * @param refresh Whether or not to force a refresh of the medals list
    */
    public static function getMedals(callback:Function, thisArg:Object, refresh:Boolean):Void
    {
        if (!NGIO.checkCore()) return;

        if (typeof(callback) !== "function") throw new Error("getMedals requires a callback function");
        if (typeof thisArg === "undefined") thisArg = {};

        if (NGIO.core.medals !== null && refresh !== true) {
            NGIO.onGetMedals({}, {callback:callback, thisArg:thisArg});
        } else {
            var component = new io.newgrounds.models.components.Medal.getList();
            NGIO.core.executeComponent(component, NGIO.onGetMedals, {}, {callback:callback, thisArg:thisArg});
        }
    }

    /**
    * Handles the result of a getMedals call
    * @param result The result of the getMedals call
    * @param data The data object passed to the getMedals call (contains the callback and thisArg parameters)
    */
    public static function onGetMedals(result:Object, data:Object):Void
    {
        // the actual medal list will get cached in the core object, so we'll extract from there and ignore the result object
        data.callback.call(data.thisArg, NGIO.core.medals);
    }

    /**
    * Gets the user's current medal score.
    * @param callback A function to call when the medal score is retrieved
    * @param thisArg The scope to call the callback in
    * @param refresh Whether or not to force a refresh of the medal score
    */
    public static function getMedalScore(callback:Function, thisArg:Object, refresh:Boolean):Void
    {
        if (!NGIO.checkCore()) return;

        if (typeof(callback) !== "function") throw new Error("getMedalScore requires a callback function");
        if (typeof thisArg === "undefined") thisArg = {};

        if (NGIO.core.medalScore !== null && refresh !== true) {
            NGIO.onGetMedalScore({}, {callback:callback, thisArg:thisArg});
        } else {
            var component = new io.newgrounds.models.components.Medal.getMedalScore();
            NGIO.core.executeComponent(component, NGIO.onGetMedalScore, {}, {callback:callback, thisArg:thisArg});
        }
    }

    /**
    * Handles the result of a getMedalScore call
    * @param result The result of the getMedalScore call
    * @param data The data object passed to the getMedalScore call (contains the callback and thisArg parameters)
    */
    public static function onGetMedalScore(result:Object, data:Object):Void
    {
        // the actual medal score will get cached in the core object, so we'll extract from there and ignore the result object
        data.callback.call(data.thisArg, NGIO.core.medalScore ? NGIO.core.medalScore : 0);
    }

    /**
    * Gets the list of cloud save slots available for this app, returns an array of CloudSaveSlot objects to the provided callback
    * @param callback A function to call when the list of save slots is retrieved
    * @param thisArg The scope to call the callback in
    * @param refresh Whether or not to force a refresh of the save slots list
    */
    public static function getSaveSlots(callback:Function, thisArg:Object, refresh:Boolean):Void
    {
        if (!NGIO.checkCore()) return;

        if (typeof(callback) !== "function") throw new Error("getSaveSlots requires a callback function");
        if (typeof thisArg === "undefined") thisArg = {};

        if (NGIO.core.saveSlots !== null && refresh !== true) {
            NGIO.onGetSaveSlots({}, {callback:callback, thisArg:thisArg});
        } else {
            var component = new io.newgrounds.models.components.CloudSave.loadSlots();
            NGIO.core.executeComponent(component, NGIO.onGetSaveSlots, {}, {callback:callback, thisArg:thisArg});
        }
    }

    /**
    * Handles the result of a getSaveSlots call
    * @param result The result of the getSaveSlots call
    * @param data The data object passed to the getSaveSlots call (contains the callback and thisArg parameters)
    */
    public static function onGetSaveSlots(result:Object, data:Object):Void
    {
        // the actual save slot list will get cached in the core object, so we'll extract from there and ignore the result object
        data.callback.call(data.thisArg, NGIO.core.saveSlots);
    }

    /**
    * Gets a specific save slot by ID
    * @param id The ID of the save slot to retrieve
    * @return SaveSlot The save slot object with the provided ID
    */
    public static function getSaveSlot(id:Number) {

        if (!NGIO.checkCore()) return;

        var saveSlots = NGIO.core.saveSlots;

        if (!saveSlots) {
            throw new Error("Save slots have not been loaded yet.  Call getSaveSlots or loadAppData first.");
        }

        for (var i = 0; i < saveSlots.length; i++) {
            if (saveSlots[i].id === id) {
                return saveSlots[i];
            }
        }

        return null;
    }

    /**
    * Gets a specific medal by ID
    * @param id The ID of the medal to retrieve
    * @return Medal The medal object with the provided ID
    */
    public static function getMedal(id:Number) {

        if (!NGIO.checkCore()) return;

        var medals = NGIO.core.medals;

        if (!medals) {
            throw new Error("Medals have not been loaded yet.  Call getMedals or loadAppData first.");
        }

        for (var i = 0; i < medals.length; i++) {
            if (medals[i].id === id) {
                return medals[i];
            }
        }

        return null;
    }

    /**
    * Gets the list of scoreboards available for this app, returns an array of ScoreBoard objects to the provided callback
    * @param callback A function to call when the version number is retrieved
    * @param thisArg The scope to call the callback in
    */
    public static function getScoreBoards(callback:Function, thisArg:Object):Void
    {
        if (!NGIO.checkCore()) return;

        if (typeof(callback) !== "function") throw new Error("getScoreBoards requires a callback function");
        if (typeof thisArg === "undefined") thisArg = {};

        if (NGIO.core.scoreBoards !== null) {
            NGIO.onGetScoreBoards({}, {callback:callback, thisArg:thisArg});
        } else {
            var component = new io.newgrounds.models.components.ScoreBoard.getBoards();
            NGIO.core.executeComponent(component, NGIO.onGetScoreBoards, {}, {callback:callback, thisArg:thisArg});
        }
    }

    /**
    * Handles the result of a getScoreBoards call
    * @param result The result of the getScoreBoards call
    * @param data The data object passed to the getScoreBoards call (contains the callback and thisArg parameters)
    */
    public static function onGetScoreBoards(result:Object, data:Object):Void
    {
        // the actual version number will get cached in the core object, so we'll extract from there and ignore the result object
        data.callback.call(data.thisArg, NGIO.core.scoreBoards);
    }

    /**
    * Gets a specific scoreboard by ID
    * @param id The ID of the scoreboard to retrieve
    * @return ScoreBoard The scoreboard object with the provided ID
    */
    public static function getScoreBoard(id:Number) {

        if (!NGIO.checkCore()) return;

        var scoreBoards = NGIO.core.scoreBoards;

        if (!scoreBoards) {
            throw new Error("Scoreboards have not been loaded yet.  Call getScoreBoards or loadAppData first.");
        }

        for (var i = 0; i < scoreBoards.length; i++) {
            if (scoreBoards[i].id === id) {
                return scoreBoards[i];
            }
        }

        return null;
    }

    public static function logEvent(event_name:String, callback:Function, thisArg:Object):Void
    {
        if (!NGIO.checkCore()) return;

        var component = new io.newgrounds.models.components.Event.logEvent({event_name:event_name});
        NGIO.core.executeComponent(component, callback, thisArg);
    }

    public static function getGatewayDateTime(callback:Function, thisArg:Object):Void
    {
        if (!NGIO.checkCore()) return;

        var component = new io.newgrounds.models.components.Gateway.getDatetime();
        NGIO.core.executeComponent(component, callback, thisArg);
    }

    public static function getGatewayVersion(callback:Function, thisArg:Object):Void
    {
        if (!NGIO.checkCore()) return;

        var component = new io.newgrounds.models.components.Gateway.getVersion();
        NGIO.core.executeComponent(component, callback, thisArg);
    }

    public static function sendPing(callback:Function, thisArg:Object):Void
    {
        if (!NGIO.checkCore()) return;

        var component = new io.newgrounds.models.components.Gateway.ping();
        NGIO.core.executeComponent(component, callback, thisArg);
    }

    public static function loadAuthorUrl():Void
    {
        if (!NGIO.checkCore()) return;

        var component = new io.newgrounds.models.components.Loader.loadAuthorUrl();
        NGIO.core.executeComponent(component);
    }

    public static function loadMoreGames():Void
    {
        if (!NGIO.checkCore()) return;

        var component = new io.newgrounds.models.components.Loader.loadMoreGames();
        NGIO.core.executeComponent(component);
    }

    public static function loadNewgrounds():Void
    {
        if (!NGIO.checkCore()) return;

        var component = new io.newgrounds.models.components.Loader.loadNewgrounds();
        NGIO.core.executeComponent(component);
    }

    public static function loadOfficialUrl():Void
    {
        if (!NGIO.checkCore()) return;

        var component = new io.newgrounds.models.components.Loader.loadOfficialUrl();
        NGIO.core.executeComponent(component);
    }

    public static function loadReferral(referral_name:String):Void
    {
        if (!NGIO.checkCore()) return;

        var component = new io.newgrounds.models.components.Loader.loadReferral({referral_name:referral_name});
        NGIO.core.executeComponent(component);
    }
}
