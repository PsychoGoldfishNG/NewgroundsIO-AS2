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
    public static var passport_url:String = null;

    /**
    * Initializes the Newgrounds.io API
    * @param app_id Your application's unique ID
    * @param encryption_key Your application's encryption key
    * @param debug Whether or not to enable debug mode
    */
    public static function init(app_id:String, encryption_key:String, debug:Boolean):Void
    {
        if (debug !== true) debug = false;
        NGIO.core = new io.newgrounds.core(app_id, encryption_key, debug);
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
        var component = new io.newgrounds.models.components.App.checkSession();
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
    * Starts a new session.  This is private to prevent users from creating sessions without checking them first.
    *
    * @param callback A function to call when the session is started. The callback will receive a response object with the following properties:
    * - status: A string representing the current status of the session
    * - user: A User object representing the current user, or null if no user has been loaded yet
    * - error: An Error object if there was a problem starting the session
    * @param thisArg The scope to call the callback in
    */
    private static function startSession(callback:Function, thisArg:Object):Void
    {
        // send a startSession component, but handle it the same as a checkSession call
        var component = new io.newgrounds.models.components.App.startSession();
        NGIO.core.executeComponent(component, NGIO.onCheckSession, {}, {callback:callback, thisArg:thisArg});
    }
}