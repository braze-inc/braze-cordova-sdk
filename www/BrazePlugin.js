var BrazePlugin = function () {
}

// Braze methods
/**
 * When a user first uses Braze on a device they are considered "anonymous". Use this method to identify a user
 *    with a unique ID, which enables the following:
 *
 *    - If the same user is identified on another device, their user profile, usage history and event history will
 *        be shared across devices.
 *    - If your app is used on the same device by multiple people, you can assign each of them a unique identifier
 *        to track them separately. Only the most recent user on a particular browser will receive push
 *        notifications and in-app messages.
 *
 * When you request a user switch (which is any call to changeUser where the new user ID is not the same as the
 *    existing user ID), the current session for the previous user (anonymous or not) is automatically ended and
 *    a new session is started. Similarly, following a call to changeUser, any events which fire are guaranteed to
 *    be for the new user -- if an in-flight server request completes for the old user after the user switch no
 *    events will fire, so you do not need to worry about filtering out events from Braze for old users.
 *
 * Additionally, if you identify a user which has never been identified on another device, the entire history of
 *    that user as an "anonymous" user on this device will be preserved and associated with the newly identified
 *    user. However, if you identify a user which *has* been identified in another app, any history which was
 *    already flushed to the server for the anonymous user on this device will become orphaned and will not be
 *    associated with any future users. These orphaned users are not considered in your user counts and will not
 *    be messaged.
 *
 * Note: Once you identify a user, you cannot revert to the "anonymous" user. The transition from anonymous to
 *    identified tracking is only allowed once because the initial anonymous user receives special treatment to
 *    allow for preservation of their history. As a result, we recommend against changing the user ID just because
 *    your app has entered a "logged out" state because it makes you unable to target the previously logged out user
 *    with re-engagement campaigns. If you anticipate multiple users on the same device, but only want to target one
 *    of them when your app is in a logged out state, we recommend separately keeping track of the user ID you want
 *    to target while logged out and switching back to that user ID as part of your app's logout process.
 *
 * @param {string} userId - A unique identifier for this user.
 * @param {string} sdkAuthenticationToken - A JWT token used for SDK Authentication.
 */
BrazePlugin.prototype.changeUser = function (userId, sdkAuthenticationToken) {
	cordova.exec(null, null, "BrazePlugin", "changeUser", [userId, sdkAuthenticationToken]);
}

/**
* ** ANDROID ONLY**
*
* Registers the device as eligible to receive push notifications from Braze.
*
* @param {string} pushToken - The registration ID / push token.
*/
BrazePlugin.prototype.setRegisteredPushToken = function (pushToken) {
	cordova.exec(null, null, "BrazePlugin", "setRegisteredPushToken", [pushToken]);
}

/**
* ** ANDROID ONLY**
*
* Requests the push permission prompt to be shown to the user.
*/
BrazePlugin.prototype.requestPushPermission = function () {
	cordova.exec(null, null, "BrazePlugin", "requestPushPermission");
}

/**
 * Reports that the current user performed a custom named event.
 * @param {string} eventName - The identifier for the event to track. Best practice is to track generic events
 *      useful for segmenting, instead of specific user actions (i.e. track watched_sports_video instead of
 *      watched_video_adrian_peterson_td_mnf). Value is limited to 255 characters in length, cannot begin with a $,
 *      and can only contain alphanumeric characters and punctuation.
 * @param {object} [eventProperties] - Hash of properties for this event. Keys are limited to 255
 *      characters in length, cannot begin with a $, and can only contain alphanumeric characters and punctuation.
 *      Values can be numeric, boolean, or strings 255 characters or shorter.
 */
BrazePlugin.prototype.logCustomEvent = function (eventName, eventProperties) {
	cordova.exec(null, null, "BrazePlugin", "logCustomEvent", [eventName, eventProperties]);
}

/**
 * Reports that the current user made an in-app purchase. Useful for tracking and segmenting users.
 * @param {string} productId - A string identifier for the product purchased, e.g. an SKU. Value is limited to
 *      255 characters in length, cannot begin with a $, and can only contain alphanumeric characters and punctuation.
 * @param {float} price - The price paid. Base units depend on the currency. As an example, USD should be
 *      reported as Dollars.Cents, whereas JPY should be reported as a whole number of Yen. All provided
 *      values will be rounded to two digits with toFixed(2)
 * @param {string} [currencyCode=USD] - Currencies should be represented as an ISO 4217 currency code. Supported
 *      currency symbols include: AED, AFN, ALL, AMD, ANG, AOA, ARS, AUD, AWG, AZN, BAM, BBD, BDT, BGN, BHD, BIF,
 *      BMD, BND, BOB, BRL, BSD, BTC, BTN, BWP, BYR, BZD, CAD, CDF, CHF, CLF, CLP, CNY, COP, CRC, CUC, CUP, CVE,
 *      CZK, DJF, DKK, DOP, DZD, EEK, EGP, ERN, ETB, EUR, FJD, FKP, GBP, GEL, GGP, GHS, GIP, GMD, GNF, GTQ, GYD,
 *      HKD, HNL, HRK, HTG, HUF, IDR, ILS, IMP, INR, IQD, IRR, ISK, JEP, JMD, JOD, JPY, KES, KGS, KHR, KMF, KPW,
 *      KRW, KWD, KYD, KZT, LAK, LBP, LKR, LRD, LSL, LTL, LVL, LYD, MAD, MDL, MGA, MKD, MMK, MNT, MOP, MRO, MTL,
 *      MUR, MVR, MWK, MXN, MYR, MZN, NAD, NGN, NIO, NOK, NPR, NZD, OMR, PAB, PEN, PGK, PHP, PKR, PLN, PYG, QAR,
 *      RON, RSD, RUB, RWF, SAR, SBD, SCR, SDG, SEK, SGD, SHP, SLL, SOS, SRD, STD, SVC, SYP, SZL, THB, TJS, TMT,
 *      TND, TOP, TRY, TTD, TWD, TZS, UAH, UGX, USD, UYU, UZS, VEF, VND, VUV, WST, XAF, XAG, XAU, XCD, XDR, XOF,
 *      XPD, XPF, XPT, YER, ZAR, ZMK, ZMW, and ZWL. Any other provided currency symbol will result in a logged
 *      warning and no other action taken by the SDK.
 * @param {integer} [quantity=1] - The quantity of items purchased expressed as a whole number. Must be at least 1
 *      and at most 100.
 * @param {object} [purchaseProperties] - Hash of properties for this purchase. Keys are limited to 255
 *      characters in length, cannot begin with a $, and can only contain alphanumeric characters and punctuation.
 *      Values can be numeric, boolean, or strings 255 characters or shorter.
 */
BrazePlugin.prototype.logPurchase = function (productId, price, currencyCode, quantity, purchaseProperties) {
	cordova.exec(null, null, "BrazePlugin", "logPurchase", [productId, price, currencyCode, quantity, purchaseProperties]);
}

/**
 * Sets the attribution information for the user. For in apps that have an install tracking integration.
 */
BrazePlugin.prototype.setUserAttributionData = function (network, campaign, adgroup, creative) {
	cordova.exec(null, null, "BrazePlugin", "setUserAttributionData", [network, campaign, adgroup, creative]);
}

/**
 * Sets a custom user attribute. This can be any key/value pair and is used to collect extra information about the
 *    user.
 * @param {string} key - The identifier of the custom attribute. Limited to 255 characters in length, cannot begin with
 *    a $, and can only contain alphanumeric characters and punctuation.
 * @param value - Can be numeric, boolean, a Date object, a string, or an array of strings. Strings are limited to
 *    255 characters in length, cannot begin with a $, and can only contain alphanumeric characters and punctuation.
 *    Passing a null value will remove this custom attribute from the user.
 */
BrazePlugin.prototype.setCustomUserAttribute = function (key, value, merge = false) {
	var valueType = typeof(value);
	if (value instanceof Date) {
  		cordova.exec(null, null, "BrazePlugin", "setDateCustomUserAttribute", [key, Math.floor(value.getTime() / 1000)]);
  	} else if (value instanceof Array) {
		if (value.every(item => typeof(item) === "string")) {
			cordova.exec(null, null, "BrazePlugin", "setCustomUserAttributeArray", [key, value]);
		} else if (value.every(item => item instanceof Object)) {
			cordova.exec(null, null, "BrazePlugin", "setCustomUserAttributeObjectArray", [key, value]);
		} else {
			console.log(`User attribute ${value} was not a valid array. Custom attribute arrays can only contain all strings or all objects.`);
		}
	} else if (value instanceof Object) {
		cordova.exec(null, null, "BrazePlugin", "setCustomUserAttributeObject", [key, value, merge]);
  	} else if (valueType === "boolean") {
  		cordova.exec(null, null, "BrazePlugin", "setBoolCustomUserAttribute", [key, value]);
  	} else if (valueType === "string") {
  		cordova.exec(null, null, "BrazePlugin", "setStringCustomUserAttribute", [key, value]);
  	} else if (valueType === "number") {
  		if (parseInt(value) === parseFloat(value)) {
  			cordova.exec(null, null, "BrazePlugin", "setIntCustomUserAttribute", [key, value]);
  		} else {
  			cordova.exec(null, null, "BrazePlugin", "setDoubleCustomUserAttribute", [key, value]);
  		}
 	}
}

/**
 * Increment/decrement the value of a custom attribute. Only numeric custom attributes can be incremented. Attempts to
 *    increment a custom attribute that is not numeric be ignored. If you increment a custom attribute that has not
 *    previously been set, a custom attribute will be created and assigned the value of incrementValue. To decrement
 *    the value of a custom attribute, use a negative incrementValue.
 * @param {string} key - The identifier of the custom attribute. Limited to 255 characters in length, cannot begin with
 *    a $, and can only contain alphanumeric characters and punctuation.
 * @param {integer} - May be negative to decrement.
 */
BrazePlugin.prototype.incrementCustomUserAttribute = function (key, value) {
	cordova.exec(null, null, "BrazePlugin", "incrementCustomUserAttribute", [key, value]);
}

/**
 * Sets the first name of the user.
 * @param {string} firstName - Limited to 255 characters in length.
 */
BrazePlugin.prototype.setFirstName = function (firstName) {
	cordova.exec(null, null, "BrazePlugin", "setFirstName", [firstName]);
}

/**
 * Sets the last name of the user.
 * @param {string} lastName - Limited to 255 characters in length.
 */
BrazePlugin.prototype.setLastName = function (lastName) {
	cordova.exec(null, null, "BrazePlugin", "setLastName", [lastName]);
}

/**
 * Sets the email address of the user.
 * @param {string} email - Must pass RFC-5322 email address validation.
 */
BrazePlugin.prototype.setEmail = function (email) {
	cordova.exec(null, null, "BrazePlugin", "setEmail", [email]);
}

/**
 * Sets the gender of the user.
 * @param {ab.User.Genders} gender - Generally 'm' or 'f'.
 */
BrazePlugin.prototype.setGender = function (gender) {
	cordova.exec(null, null, "BrazePlugin", "setGender", [gender]);
}

/**
 * Sets the country for the user.
 * @param {string} country - Limited to 255 characters in length.
 */
BrazePlugin.prototype.setCountry = function (country) {
	cordova.exec(null, null, "BrazePlugin", "setCountry", [country]);
}

/**
 * Sets the home city for the user.
 * @param {string} homeCity - Limited to 255 characters in length.
 */
BrazePlugin.prototype.setHomeCity = function (homeCity) {
	cordova.exec(null, null, "BrazePlugin", "setHomeCity", [homeCity]);
}

/**
 * Sets the phone number of the user.
 * @param {string} phoneNumber - A phone number is considered valid if it is no more than 255 characters in length and
 *    contains only numbers, whitespace, and the following special characters +.-()
 */
BrazePlugin.prototype.setPhoneNumber = function (phoneNumber) {
	cordova.exec(null, null, "BrazePlugin", "setPhoneNumber", [phoneNumber]);
}

/**
 * Sets the date of birth of the user.
 * @param {integer} year
 * @param {integer} month - 1-12
 * @param {integer} day
 */
BrazePlugin.prototype.setDateOfBirth = function (year, month, day) {
	cordova.exec(null, null, "BrazePlugin", "setDateOfBirth", [year, month, day]);
}

/**
 * Sets the last known location for this user.
 * @param {double} latitude
 * @param {double} longitude
 * @param {double} altitude (optional)
 * @param {double} horizontalAccuracy (optional for Android)
 * @param {double} verticalAccuracy (optional)
 */
BrazePlugin.prototype.setLastKnownLocation = function (latitude, longitude, altitude, horizontalAccuracy, verticalAccuracy) {
	cordova.exec(null, null, "BrazePlugin", "setLastKnownLocation", [latitude, longitude, altitude, horizontalAccuracy, verticalAccuracy]);
}

/**
 * Sets whether the user should be sent push campaigns.
 * @param {NotificationSubscriptionTypes} notificationSubscriptionType - Notification setting (explicitly
 *    opted-in, subscribed, or unsubscribed).
 */
BrazePlugin.prototype.setPushNotificationSubscriptionType = function (notificationSubscriptionType) {
	cordova.exec(null, null, "BrazePlugin", "setPushNotificationSubscriptionType", [notificationSubscriptionType]);
}

/**
 * Sets whether the user should be sent email campaigns.
 * @param {NotificationSubscriptionTypes} notificationSubscriptionType - Notification setting (explicitly
 *    opted-in, subscribed, or unsubscribed).
 */
BrazePlugin.prototype.setEmailNotificationSubscriptionType = function (notificationSubscriptionType) {
	cordova.exec(null, null, "BrazePlugin", "setEmailNotificationSubscriptionType", [notificationSubscriptionType]);
}

/**
 * Adds a string to a custom atttribute string array, or creates that array if one doesn't exist.
 * @param {string} key - The identifier of the custom attribute. Limited to 255 characters in length, cannot begin with
 *    a $, and can only contain alphanumeric characters and punctuation.
 * @param {string} value - The string to be added to the array. Strings are limited to 255 characters in length, cannot
 *    begin with a $, and can only contain alphanumeric characters and punctuation.
 */
BrazePlugin.prototype.addToCustomUserAttributeArray = function (key, value) {
	cordova.exec(null, null, "BrazePlugin", "addToCustomAttributeArray", [key, value]);
}

/**
 * Removes a string from a custom attribute string array.
 * @param {string} key - The identifier of the custom attribute. Limited to 255 characters in length, cannot begin with
 *    a $, and can only contain alphanumeric characters and punctuation.
 * @param {string} value - The string to be removed from the array. Strings are limited to 255 characters in length,
 *    cannot beging with a $, and can only contain alphanumeric characters and punctuation.
 */
BrazePlugin.prototype.removeFromCustomUserAttributeArray = function (key, value) {
	cordova.exec(null, null, "BrazePlugin", "removeFromCustomAttributeArray", [key, value]);
}

/**
 * Unsets a custom user attribute.
 * @param {string} key - The identifier of the custom attribute. Limited to 255 characters in length, cannot begin with
 *    a $, and can only contain alphanumeric characters and punctuation.
 */
BrazePlugin.prototype.unsetCustomUserAttribute = function (key) {
	cordova.exec(null, null, "BrazePlugin", "unsetCustomUserAttribute", [key]);
}

/**
 * Adds an alias for the user.
 * @param {string} alias - An identifier for this user.
 * @param {string} label - A label for the alias. e.g. the source of the alias, like "internal_id"
 */
BrazePlugin.prototype.addAlias = function (alias, label) {
	cordova.exec(null, null, "BrazePlugin", "addAlias", [alias, label]);
}

// Other
/**
 * Launches the News Feed UI element.
 */
BrazePlugin.prototype.launchNewsFeed = function () {
	cordova.exec(null, null, "BrazePlugin", "launchNewsFeed", []);
}

/**
 * Returns array of serialized card items
 */
BrazePlugin.prototype.getNewsFeed = function (successCallback, errorCallback) {
  cordova.exec(successCallback, errorCallback, "BrazePlugin", "getNewsFeed", ['all']);
}

// News Feed methods

/**
* Gets the number of unread News Feed Cards. The result is returned as an integer argument to the successCallback function. The card count uses the cards present in the cache. News Feed cards are not refreshed as a result of this call.
*/
BrazePlugin.prototype.getNewsFeedUnreadCount = function (successCallback, errorCallback) {
  cordova.exec(successCallback, errorCallback, "BrazePlugin", "getUnreadCardCountForCategories", ['all']);
}

/**
* Gets the number of News Feed Cards. The result is returned as an integer argument to the successCallback function. The card count uses the cards present in the cache. News Feed cards are not refreshed as a result of this call.
**/
BrazePlugin.prototype.getNewsFeedCardCount = function (successCallback, errorCallback) {
  cordova.exec(successCallback, errorCallback, "BrazePlugin", "getCardCountForCategories", ['all']);
}

/**
* Gets the number of News Feed Cards for a category. The result is returned as an integer argument to the successCallback function. The card count uses the cards present in the cache. News Feed cards are not refreshed as a result of this call.
**/
BrazePlugin.prototype.getCardCountForCategories = function (successCallback, errorCallback, cardCategories) {
  cordova.exec(successCallback, errorCallback, "BrazePlugin", "getCardCountForCategories", cardCategories);
}

/**
* Gets the number of unread News Feed Cards for a category. The result is returned as an integer argument to the successCallback function. The card count uses the cards present in the cache. News Feed cards are not refreshed as a result of this call.
*/
BrazePlugin.prototype.getUnreadCardCountForCategories = function (successCallback, errorCallback, cardCategories) {
  cordova.exec(successCallback, errorCallback, "BrazePlugin", "getUnreadCardCountForCategories", cardCategories);
}

/**
* Wipes Data on the Braze SDK. On iOS, the SDK will be disabled for the rest of the app run.
*/
BrazePlugin.prototype.wipeData = function () {
  cordova.exec(null, null, "BrazePlugin", "wipeData");
}

/**
* Enables the Braze SDK after a previous call to disableSDK().
* On iOS, the SDK will be enabled only after a subsequent call to startWithApiKey().
*/
BrazePlugin.prototype.enableSdk = function () {
  cordova.exec(null, null, "BrazePlugin", "enableSdk");
}

/**
* Disables the Braze SDK immediately.
*/
BrazePlugin.prototype.disableSdk = function () {
  cordova.exec(null, null, "BrazePlugin", "disableSdk");
}

/**
* Requests that the Braze SDK immediately flush any pending data.
*/
BrazePlugin.prototype.requestImmediateDataFlush = function () {
  cordova.exec(null, null, "BrazePlugin", "requestImmediateDataFlush");
}

/**
* Requests the latest Content Cards from the Braze SDK server.
*/
BrazePlugin.prototype.requestContentCardsRefresh = function () {
	cordova.exec(null, null, "BrazePlugin", "requestContentCardsRefresh");
}

/**
* Retrieves Content Cards from the Braze SDK. This will return the latest list of cards from the server.
*/
BrazePlugin.prototype.getContentCardsFromServer = function (successCallback, errorCallback) {
	cordova.exec(successCallback, errorCallback, "BrazePlugin", "getContentCardsFromServer");
}

/**
* Retrieves Content Cards from the Braze SDK. This will return the latest list of cards from the cache.
*/
BrazePlugin.prototype.getContentCardsFromCache = function (successCallback, errorCallback) {
	cordova.exec(successCallback, errorCallback, "BrazePlugin", "getContentCardsFromCache");
}

/**
 * Launches a default Content Cards UI element.
 */
BrazePlugin.prototype.launchContentCards = function () {
	cordova.exec(null, null, "BrazePlugin", "launchContentCards");
}

/**
 * Logs a click for the given Content Card id.
 */
BrazePlugin.prototype.logContentCardClicked = function (cardId) {
	cordova.exec(null, null, "BrazePlugin", "logContentCardClicked", [cardId]);
}

/**
 * Logs an impression for the given Content Card id.
 */
BrazePlugin.prototype.logContentCardImpression = function (cardId) {
	cordova.exec(null, null, "BrazePlugin", "logContentCardImpression", [cardId]);
}

/**
 * Logs a dismissal for the given Content Card id.
 */
BrazePlugin.prototype.logContentCardDismissed = function (cardId) {
	cordova.exec(null, null, "BrazePlugin", "logContentCardDismissed", [cardId]);
}

/**
 * Sets the language for a user. Language Strings should be valid ISO 639-1 language codes. See loc.gov/standards/iso639-2/php/code_list.php.
 */
BrazePlugin.prototype.setLanguage = function (language) {
	cordova.exec(null, null, "BrazePlugin", "setLanguage", [language]);
}

/**
 * Adds user to given subscription group.
 */
BrazePlugin.prototype.addToSubscriptionGroup = function (groupId) {
	cordova.exec(null, null, "BrazePlugin", "addToSubscriptionGroup", [groupId]);
}

/**
 * Removes user from given subscription group.
 */
BrazePlugin.prototype.removeFromSubscriptionGroup = function (groupId) {
	cordova.exec(null, null, "BrazePlugin", "removeFromSubscriptionGroup", [groupId]);
}

/**
 * @return An app specific ID that is stored on the device.
 */
BrazePlugin.prototype.getDeviceId = function (successCallback, errorCallback) {
	cordova.exec(successCallback, errorCallback, "BrazePlugin", "getDeviceId");
}

/**
 * Requests a specific Feature Flags. This will pull the data from a local cache and does
 * not force a refresh.
 *
 * @param id The ID of the Feature Flag to retrieve.
 * @return A promise containing the [FeatureFlag] of the requested ID, or null if the Feature Flag does not exist.
 */
BrazePlugin.prototype.getFeatureFlag = function (id) {
	return new Promise((resolve, reject) => {
		cordova.exec((featureFlag) => {
			resolve(featureFlag);
		}, (error) => {
			reject(error);
		}, "BrazePlugin", "getFeatureFlag", [id]);
	});
}

/**
 * Retrieves the offline/cached list of Feature Flags from offline storage.
 *
 * @return A promise containing the list of cached Feature Flags. Note that this does not request a
 * fresh list of Feature Flags from Braze. If the SDK is disabled or the
 * cached list of feature flags cannot be retrieved, returns empty list.
 */
BrazePlugin.prototype.getAllFeatureFlags = function () {
	return new Promise((resolve, reject) => {
		cordova.exec((featureFlags) => {
			resolve(featureFlags);
		}, (error) => {
			reject(error);
		}, "BrazePlugin", "getAllFeatureFlags");
	});
}

/**
 * Requests a refresh of Feature Flags from the Braze server.
 */
BrazePlugin.prototype.refreshFeatureFlags = function () {
	cordova.exec(null, null, "BrazePlugin", "refreshFeatureFlags");
}

/**
 * Subscribes to Feature Flags events. The subscriber callback will be called when Feature Flags are updated.
 */
BrazePlugin.prototype.subscribeToFeatureFlagsUpdates = function (flagId, propertyKey, successCallback, errorCallback) {
	cordova.exec(successCallback, errorCallback, "BrazePlugin", "subscribeToFeatureFlagUpdates", [flagId, propertyKey]);
}

/**
 * Requests a boolean property for a given Feature Flag ID and a property key.
 * @param {string} flagId - The identifier for the Feature Flag.
 * @param {string} propertyKey - The key for the boolean property.
 * 
 * @return A promise containing the boolean property requested. This will return null if there is no such property or Feature Flag.
 */
BrazePlugin.prototype.getFeatureFlagBooleanProperty = function(flagId, propertyKey) {
	return new Promise((resolve, reject) => {
		cordova.exec((property) => {
			resolve(property);
		}, (error) => {
			reject(error);
		}, "BrazePlugin", "getFeatureFlagBooleanProperty", [flagId, propertyKey]);
	})	
}

/**
 * Requests a string property for a given Feature Flag ID and a property key.
 * @param {string} flagId - The identifier for the Feature Flag.
 * @param {string} propertyKey - The key for the string property.
 * 
 * @return A promise containing the string property requested. This will return null if there is no such property or Feature Flag.
 */
BrazePlugin.prototype.getFeatureFlagStringProperty = function(flagId, propertyKey) {
	return new Promise((resolve, reject) => {
		cordova.exec((stringProperty) => {
			resolve(stringProperty);
		}, (error) => {
			reject(error);
		}, "BrazePlugin", "getFeatureFlagStringProperty", [flagId, propertyKey]);
	})	
}

/**
 * Requests a number property for a given Feature Flag ID and a property key.
 * @param {string} flagId - The identifier for the Feature Flag.
 * @param {string} propertyKey - The key for the number property.
 * 
 * @return A promise containing the number property requested. This will return null if there is no such property or Feature Flag.
 */
BrazePlugin.prototype.getFeatureFlagNumberProperty = function(flagId, propertyKey) {
	return new Promise((resolve, reject) => {
		cordova.exec((numberProperty) => {
			resolve(numberProperty);
		}, (error) => {
			reject(error);
		}, "BrazePlugin", "getFeatureFlagNumberProperty", [flagId, propertyKey]);
	})	
}

/**
 * Log a Feature Flag impression.
 * An impression will only be logged if the feature flag is part of a Braze campaign.
 * A feature flag impression can only be logged once per session for a given ID.
 * @param {string} flagId - The identifier for the Feature Flag.
 */
BrazePlugin.prototype.logFeatureFlagImpression = function(flagId) {
	cordova.exec(null, null, "BrazePlugin", "logFeatureFlagImpression", [flagId]);
}

/**
 * @return Starts SDK session tracking if previously disabled. Only used for Android.
 */
BrazePlugin.prototype.startSessionTracking = function () {
	cordova.exec(null, null, "BrazePlugin", "startSessionTracking");
}

BrazePlugin.prototype['NotificationSubscriptionTypes'] = {
  "OPTED_IN": 'opted_in',
  "SUBSCRIBED": 'subscribed',
  "UNSUBSCRIBED": 'unsubscribed'
};

BrazePlugin.prototype['Genders'] = {
  "FEMALE": 'f',
  "MALE": 'm',
  "NOT_APPLICABLE": 'n',
  "OTHER": 'o',
  "PREFER_NOT_TO_SAY": 'p',
  "UNKNOWN": 'u'
};

BrazePlugin.prototype['CardCategories'] = {
  "ADVERTISING": 'advertising',
  "ANNOUNCEMENTS": 'announcements',
  "NEWS": 'news',
  "SOCIAL": 'social',
  "NO_CATEGORY": 'no_category',
  "ALL" : 'all'
};

BrazePlugin.prototype['ContentCardTypes'] = {
	'CLASSIC': 'Classic',
	'IMAGE_ONLY': 'ImageOnly',
	'CAPTIONED': 'Captioned'
};

/**
 * Sets the signature used for SDK authentication
 * for the currently identified user.
 *
 * @param {string} jwtToken - SDK Authentication JWT token.
 */
BrazePlugin.prototype.setSdkAuthenticationSignature = function (jwtToken) {
	cordova.exec(null, null, "BrazePlugin", "setSdkAuthenticationSignature", [jwtToken]);
}

/**
* Subscribes to SDK Authentication failures.
*
* Reports failures in the following JSON format:
* 	(string) "signature"
* 	(number) "errorCode"
* 	(string) "errorReason"
* 	(string) "userId"
*/
BrazePlugin.prototype.subscribeToSdkAuthenticationFailures = function (successCallback, errorCallback) {
	cordova.exec(successCallback, errorCallback, "BrazePlugin", "subscribeToSdkAuthenticationFailures");
}

var AppboyPlugin = BrazePlugin;

module.exports = new BrazePlugin();
module.exports = new AppboyPlugin();
