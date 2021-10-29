
var AppboyPlugin = function () {

	/*
		Added to fix deep links. This is not from out of the box Appboy BE CAREFUL on updates
		Fix deep links on android
		Modified to allow native to js communications
	*/
	var _this = this;
   
	this.handlers = {
		notification: [],
	};
   
   
	this.emit = function (...args) {
	const eventName = args.shift();

	if (!Object.prototype.hasOwnProperty.call(_this.handlers, eventName)) {
		return false;
	}

	for (let i = 0, { length } = _this.handlers[eventName]; i < length; i += 1) {
		const callback = _this.handlers[eventName][i];
		if (typeof callback === "function") {
			callback(...args);
		} else {
			console.log(`event handler: ${eventName} must be a function`);
		}
		}

		return true;
	};

	// triggered on notification
	var success = function (result) {

	if (result && typeof result.deeplink !== "undefined") {
		setTimeout(function () {
		_this.emit("notification", result);
		}, 1000);
	}
	};

	this.on = function (eventName, callback) {
	if (!Object.prototype.hasOwnProperty.call(_this.handlers, eventName)) {
		_this.handlers[eventName] = [];
	}
	_this.handlers[eventName].push(callback);
	};

	this.off = function (eventName, handle) {
	if (Object.prototype.hasOwnProperty.call(_this.handlers, eventName)) {
		const handleIndex = _this.handlers[eventName].indexOf(handle);
		if (handleIndex >= 0) {
		_this.handlers[eventName].splice(handleIndex, 1);
		}
	}
	};

	this.startNotifications = function () {
		cordova.exec(success, null, "AppboyPlugin", "startNotifications");
	};
	/*
		End of Modified to allow native to js communications
	*/
};
   
// Appboy methods
   
   
   
   // Appboy methods
   /**
	* When a user first uses Appboy on a device they are considered "anonymous". Use this method to identify a user
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
	*    events will fire, so you do not need to worry about filtering out events from Appboy for old users.
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
	*/
   AppboyPlugin.prototype.changeUser = function (userId) {
	 cordova.exec(null, null, "AppboyPlugin", "changeUser", [userId]);
   };
   
   /**
	* ** ANDROID ONLY**
	*
	* Registers the device as eligible to receive push notifications from Appboy.
	* Appboy will use the provided For GCM/ADM applications, this takes the GCM/ADM registration ID to send the device GCM/ADM messages.
	* For apps integrating Baidu Cloud Push, this method is used to register the Baidu user with Appboy.
	* This should only be used if you already use GCM/ADM messaging in your app from another provider or are integrating Baidu Cloud Push.
	*
	* @param {string} registrationId - The registration ID, or for apps integrating Baidu Cloud Push, the Baidu user id.
	*/
   AppboyPlugin.prototype.registerAppboyPushMessages = function (
	 gcmRegistrationID
   ) {
	 cordova.exec(null, null, "AppboyPlugin", "registerAppboyPushMessages", [
	   gcmRegistrationID,
	 ]);
   };
   
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
   AppboyPlugin.prototype.logCustomEvent = function (eventName, eventProperties) {
	 cordova.exec(null, null, "AppboyPlugin", "logCustomEvent", [
	   eventName,
	   eventProperties,
	 ]);
   };
   
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
   AppboyPlugin.prototype.logPurchase = function (
	 productId,
	 price,
	 currencyCode,
	 quantity,
	 purchaseProperties
   ) {
	 cordova.exec(null, null, "AppboyPlugin", "logPurchase", [
	   productId,
	   price,
	   currencyCode,
	   quantity,
	   purchaseProperties,
	 ]);
   };
   
   // Appboy user methods
   /**
	* Sets the attribution information for the user. For in apps that have an install tracking integration.
	*/
   AppboyPlugin.prototype.setUserAttributionData = function (
	 network,
	 campaign,
	 adgroup,
	 creative
   ) {
	 cordova.exec(null, null, "AppboyPlugin", "setUserAttributionData", [
	   network,
	   campaign,
	   adgroup,
	   creative,
	 ]);
   };
   
   /**
	* Sets a custom user attribute. This can be any key/value pair and is used to collect extra information about the
	*    user.
	* @param {string} key - The identifier of the custom attribute. Limited to 255 characters in length, cannot begin with
	*    a $, and can only contain alphanumeric characters and punctuation.
	* @param value - Can be numeric, boolean, a Date object, a string, or an array of strings. Strings are limited to
	*    255 characters in length, cannot begin with a $, and can only contain alphanumeric characters and punctuation.
	*    Passing a null value will remove this custom attribute from the user.
	*/
   AppboyPlugin.prototype.setCustomUserAttribute = function (key, value) {
	 var valueType = typeof value;
	 if (value instanceof Date) {
	   cordova.exec(null, null, "AppboyPlugin", "setDateCustomUserAttribute", [
		 key,
		 Math.floor(value.getTime() / 1000),
	   ]);
	 } else if (value instanceof Array) {
	   cordova.exec(null, null, "AppboyPlugin", "setCustomUserAttributeArray", [
		 key,
		 value,
	   ]);
	 } else if (valueType === "boolean") {
	   cordova.exec(null, null, "AppboyPlugin", "setBoolCustomUserAttribute", [
		 key,
		 value,
	   ]);
	 } else if (valueType === "string") {
	   cordova.exec(null, null, "AppboyPlugin", "setStringCustomUserAttribute", [
		 key,
		 value,
	   ]);
	 } else if (valueType === "number") {
	   if (parseInt(value) === parseFloat(value)) {
		 cordova.exec(null, null, "AppboyPlugin", "setIntCustomUserAttribute", [
		   key,
		   value,
		 ]);
	   } else {
		 cordova.exec(null, null, "AppboyPlugin", "setDoubleCustomUserAttribute", [
		   key,
		   value,
		 ]);
	   }
	 }
   };
   
   /**
	* Increment/decrement the value of a custom attribute. Only numeric custom attributes can be incremented. Attempts to
	*    increment a custom attribute that is not numeric be ignored. If you increment a custom attribute that has not
	*    previously been set, a custom attribute will be created and assigned the value of incrementValue. To decrement
	*    the value of a custom attribute, use a negative incrementValue.
	* @param {string} key - The identifier of the custom attribute. Limited to 255 characters in length, cannot begin with
	*    a $, and can only contain alphanumeric characters and punctuation.
	* @param {integer} - May be negative to decrement.
	*/
   AppboyPlugin.prototype.incrementCustomUserAttribute = function (key, value) {
	 cordova.exec(null, null, "AppboyPlugin", "incrementCustomUserAttribute", [
	   key,
	   value,
	 ]);
   };
   
   /**
	* Sets the first name of the user.
	* @param {string} firstName - Limited to 255 characters in length.
	*/
   AppboyPlugin.prototype.setFirstName = function (firstName) {
	 cordova.exec(null, null, "AppboyPlugin", "setFirstName", [firstName]);
   };
   
   /**
	* Sets the last name of the user.
	* @param {string} lastName - Limited to 255 characters in length.
	*/
   AppboyPlugin.prototype.setLastName = function (lastName) {
	 cordova.exec(null, null, "AppboyPlugin", "setLastName", [lastName]);
   };
   
   /**
	* Sets the email address of the user.
	* @param {string} email - Must pass RFC-5322 email address validation.
	*/
   AppboyPlugin.prototype.setEmail = function (email) {
	 cordova.exec(null, null, "AppboyPlugin", "setEmail", [email]);
   };
   
   /**
	* Sets the gender of the user.
	* @param {ab.User.Genders} gender - Generally 'm' or 'f'.
	*/
   AppboyPlugin.prototype.setGender = function (gender) {
	 cordova.exec(null, null, "AppboyPlugin", "setGender", [gender]);
   };
   
   /**
	* Sets the country for the user.
	* @param {string} country - Limited to 255 characters in length.
	*/
   AppboyPlugin.prototype.setCountry = function (country) {
	 cordova.exec(null, null, "AppboyPlugin", "setCountry", [country]);
   };
   
   /**
	* Sets the home city for the user.
	* @param {string} homeCity - Limited to 255 characters in length.
	*/
   AppboyPlugin.prototype.setHomeCity = function (homeCity) {
	 cordova.exec(null, null, "AppboyPlugin", "setHomeCity", [homeCity]);
   };
   
   /**
	* Sets the phone number of the user.
	* @param {string} phoneNumber - A phone number is considered valid if it is no more than 255 characters in length and
	*    contains only numbers, whitespace, and the following special characters +.-()
	*/
   AppboyPlugin.prototype.setPhoneNumber = function (phoneNumber) {
	 cordova.exec(null, null, "AppboyPlugin", "setPhoneNumber", [phoneNumber]);
   };
   
   /**
	* Sets the url for the avatar image for the user, which will be displayed on the user profile and throughout the Appboy
	*    dashboard.
	* @param {string} avatarImageUrl
	*/
   AppboyPlugin.prototype.setAvatarImageUrl = function (avatarImageUrl) {
	 cordova.exec(null, null, "AppboyPlugin", "setAvatarImageUrl", [
	   avatarImageUrl,
	 ]);
   };
   
   /**
	* Sets the date of birth of the user.
	* @param {integer} year
	* @param {integer} month - 1-12
	* @param {integer} day
	*/
   AppboyPlugin.prototype.setDateOfBirth = function (year, month, day) {
	 cordova.exec(null, null, "AppboyPlugin", "setDateOfBirth", [
	   year,
	   month,
	   day,
	 ]);
   };
   
   /**
	* Sets whether the user should be sent push campaigns.
	* @param {NotificationSubscriptionTypes} notificationSubscriptionType - Notification setting (explicitly
	*    opted-in, subscribed, or unsubscribed).
	*/
   AppboyPlugin.prototype.setPushNotificationSubscriptionType = function (
	 notificationSubscriptionType
   ) {
	 cordova.exec(
	   null,
	   null,
	   "AppboyPlugin",
	   "setPushNotificationSubscriptionType",
	   [notificationSubscriptionType]
	 );
   };
   
   /**
	* Sets whether the user should be sent email campaigns.
	* @param {NotificationSubscriptionTypes} notificationSubscriptionType - Notification setting (explicitly
	*    opted-in, subscribed, or unsubscribed).
	*/
   AppboyPlugin.prototype.setEmailNotificationSubscriptionType = function (
	 notificationSubscriptionType
   ) {
	 cordova.exec(
	   null,
	   null,
	   "AppboyPlugin",
	   "setEmailNotificationSubscriptionType",
	   [notificationSubscriptionType]
	 );
   };
   
   /**
	* Adds a string to a custom atttribute string array, or creates that array if one doesn't exist.
	* @param {string} key - The identifier of the custom attribute. Limited to 255 characters in length, cannot begin with
	*    a $, and can only contain alphanumeric characters and punctuation.
	* @param {string} value - The string to be added to the array. Strings are limited to 255 characters in length, cannot
	*    begin with a $, and can only contain alphanumeric characters and punctuation.
	*/
   AppboyPlugin.prototype.addToCustomUserAttributeArray = function (key, value) {
	 cordova.exec(null, null, "AppboyPlugin", "addToCustomAttributeArray", [
	   key,
	   value,
	 ]);
   };
   
   /**
	* Removes a string from a custom attribute string array.
	* @param {string} key - The identifier of the custom attribute. Limited to 255 characters in length, cannot begin with
	*    a $, and can only contain alphanumeric characters and punctuation.
	* @param {string} value - The string to be removed from the array. Strings are limited to 255 characters in length,
	*    cannot beging with a $, and can only contain alphanumeric characters and punctuation.
	*/
   AppboyPlugin.prototype.removeFromCustomUserAttributeArray = function (
	 key,
	 value
   ) {
	 cordova.exec(null, null, "AppboyPlugin", "removeFromCustomAttributeArray", [
	   key,
	   value,
	 ]);
   };
   
   /**
	* Unsets a custom user attribute.
	* @param {string} key - The identifier of the custom attribute. Limited to 255 characters in length, cannot begin with
	*    a $, and can only contain alphanumeric characters and punctuation.
	*/
   AppboyPlugin.prototype.unsetCustomUserAttribute = function (key) {
	 cordova.exec(null, null, "AppboyPlugin", "unsetCustomUserAttribute", [key]);
   };
   
   /**
	* Adds an alias for the user.
	* @param {string} alias - An identifier for this user.
	* @param {string} label - A label for the alias. e.g. the source of the alias, like "internal_id"
	*/
   AppboyPlugin.prototype.addAlias = function (alias, label) {
	 cordova.exec(null, null, "AppboyPlugin", "addAlias", [alias, label]);
   };
   
   // Other
   /**
	* Launches the News Feed UI element.
	*/
   AppboyPlugin.prototype.launchNewsFeed = function () {
	 cordova.exec(null, null, "AppboyPlugin", "launchNewsFeed", []);
   };
   
   /**
	* Returns array of serialized card items
	*/
   AppboyPlugin.prototype.getNewsFeed = function (successCallback, errorCallback) {
	 cordova.exec(successCallback, errorCallback, "AppboyPlugin", "getNewsFeed", [
	   "all",
	 ]);
   };
   
   // News Feed methods
   
   /**
	* Gets the number of unread News Feed Cards. The result is returned as an integer argument to the successCallback function. The card count uses the cards present in the cache. News Feed cards are not refreshed as a result of this call.
	*/
   AppboyPlugin.prototype.getNewsFeedUnreadCount = function (
	 successCallback,
	 errorCallback
   ) {
	 cordova.exec(
	   successCallback,
	   errorCallback,
	   "AppboyPlugin",
	   "getUnreadCardCountForCategories",
	   ["all"]
	 );
   };
   
   /**
	* Gets the number of News Feed Cards. The result is returned as an integer argument to the successCallback function. The card count uses the cards present in the cache. News Feed cards are not refreshed as a result of this call.
	**/
   AppboyPlugin.prototype.getNewsFeedCardCount = function (
	 successCallback,
	 errorCallback
   ) {
	 cordova.exec(
	   successCallback,
	   errorCallback,
	   "AppboyPlugin",
	   "getCardCountForCategories",
	   ["all"]
	 );
   };
   
   /**
	* Gets the number of News Feed Cards for a category. The result is returned as an integer argument to the successCallback function. The card count uses the cards present in the cache. News Feed cards are not refreshed as a result of this call.
	**/
   AppboyPlugin.prototype.getCardCountForCategories = function (
	 successCallback,
	 errorCallback,
	 cardCategories
   ) {
	 cordova.exec(
	   successCallback,
	   errorCallback,
	   "AppboyPlugin",
	   "getCardCountForCategories",
	   cardCategories
	 );
   };
   
   /**
	* Gets the number of unread News Feed Cards for a category. The result is returned as an integer argument to the successCallback function. The card count uses the cards present in the cache. News Feed cards are not refreshed as a result of this call.
	*/
   AppboyPlugin.prototype.getUnreadCardCountForCategories = function (
	 successCallback,
	 errorCallback,
	 cardCategories
   ) {
	 cordova.exec(
	   successCallback,
	   errorCallback,
	   "AppboyPlugin",
	   "getUnreadCardCountForCategories",
	   cardCategories
	 );
   };
   
   /**
	* Wipes Data on the Braze SDK. On iOS, the SDK will be disabled for the rest of the app run.
	*/
   AppboyPlugin.prototype.wipeData = function () {
	 cordova.exec(null, null, "AppboyPlugin", "wipeData");
   };
   
   /**
	* Enables the Braze SDK after a previous call to disableSDK().
	* On iOS, the SDK will be enabled only after a subsequent call to startWithApiKey().
	*/
   AppboyPlugin.prototype.enableSdk = function () {
	 cordova.exec(null, null, "AppboyPlugin", "enableSdk");
   };
   
   /**
	* Disables the Braze SDK immediately.
	*/
   AppboyPlugin.prototype.disableSdk = function () {
	 cordova.exec(null, null, "AppboyPlugin", "disableSdk");
   };
   
   /**
	* Requests that the Braze SDK immediately flush any pending data.
	*/
   AppboyPlugin.prototype.requestImmediateDataFlush = function () {
	 cordova.exec(null, null, "AppboyPlugin", "requestImmediateDataFlush");
   };
   
   /**
	* Requests the latest Content Cards from the Braze SDK server.
	*/
   AppboyPlugin.prototype.requestContentCardsRefresh = function () {
	 cordova.exec(null, null, "AppboyPlugin", "requestContentCardsRefresh");
   };
   
   /**
	* Retrieves Content Cards from the Braze SDK. This will return the latest list of cards from the server.
	*/
   AppboyPlugin.prototype.getContentCardsFromServer = function (
	 successCallback,
	 errorCallback
   ) {
	 cordova.exec(
	   successCallback,
	   errorCallback,
	   "AppboyPlugin",
	   "getContentCardsFromServer"
	 );
   };
   
   /**
	* Retrieves Content Cards from the Braze SDK. This will return the latest list of cards from the cache.
	*/
   AppboyPlugin.prototype.getContentCardsFromCache = function (
	 successCallback,
	 errorCallback
   ) {
	 cordova.exec(
	   successCallback,
	   errorCallback,
	   "AppboyPlugin",
	   "getContentCardsFromCache"
	 );
   };
   
   /**
	* Launches a default Content Cards UI element.
	*/
   AppboyPlugin.prototype.launchContentCards = function () {
	 cordova.exec(null, null, "AppboyPlugin", "launchContentCards");
   };
   
   /**
	* Logs a Content Content feed displayed event.
	*/
   AppboyPlugin.prototype.logContentCardsDisplayed = function () {
	 cordova.exec(null, null, "AppboyPlugin", "logContentCardsDisplayed");
   };
   
   /**
	* Logs a click for the given Content Card id.
	*/
   AppboyPlugin.prototype.logContentCardClicked = function (cardId) {
	 cordova.exec(null, null, "AppboyPlugin", "logContentCardClicked", [cardId]);
   };
   
   /**
	* Logs an impression for the given Content Card id.
	*/
   AppboyPlugin.prototype.logContentCardImpression = function (cardId) {
	 cordova.exec(null, null, "AppboyPlugin", "logContentCardImpression", [
	   cardId,
	 ]);
   };
   
   /**
	* Logs a dismissal for the given Content Card id.
	*/
   AppboyPlugin.prototype.logContentCardDismissed = function (cardId) {
	 cordova.exec(null, null, "AppboyPlugin", "logContentCardDismissed", [cardId]);
   };
   
   /**
	* Sets the language for a user. Language Strings should be valid ISO 639-1 language codes. See loc.gov/standards/iso639-2/php/code_list.php.
	*/
   AppboyPlugin.prototype.setLanguage = function (language) {
	 cordova.exec(null, null, "AppboyPlugin", "setLanguage", [language]);
   };
   
   /**
	* @return An app specific ID that is stored on the device.
	*/
   AppboyPlugin.prototype.getDeviceId = function (successCallback, errorCallback) {
	 cordova.exec(successCallback, errorCallback, "AppboyPlugin", "getDeviceId");
   };
   
   /**
	* @return Starts SDK session tracking if previously disabled. Only used for Android.
	*/
   AppboyPlugin.prototype.startSessionTracking = function () {
	 cordova.exec(null, null, "AppboyPlugin", "startSessionTracking");
   };
   
   
   AppboyPlugin.prototype["NotificationSubscriptionTypes"] = {
	 OPTED_IN: "opted_in",
	 SUBSCRIBED: "subscribed",
	 UNSUBSCRIBED: "unsubscribed",
   };
   
   AppboyPlugin.prototype["Genders"] = {
	 FEMALE: "f",
	 MALE: "m",
	 NOT_APPLICABLE: "n",
	 OTHER: "o",
	 PREFER_NOT_TO_SAY: "p",
	 UNKNOWN: "u",
   };
   
   AppboyPlugin.prototype["CardCategories"] = {
	 ADVERTISING: "advertising",
	 ANNOUNCEMENTS: "announcements",
	 NEWS: "news",
	 SOCIAL: "social",
	 NO_CATEGORY: "no_category",
	 ALL: "all",
   };
   
   AppboyPlugin.prototype["ContentCardTypes"] = {
	 CLASSIC: "Classic",
	 BANNER: "Banner",
	 CAPTIONED: "Captioned",
   };
   
   module.exports = new AppboyPlugin();
   
   