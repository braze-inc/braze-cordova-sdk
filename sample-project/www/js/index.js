/*
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */
var app = {
    // Application Constructor
    initialize: function() {
        this.bindEvents();
    },
        // Bind Event Listeners
        //
        // Bind any events that are required on startup. Common events are:
        // 'load', 'deviceready', 'offline', and 'online'.
    bindEvents: function() {
        document.addEventListener('deviceready', this.onDeviceReady, false);
    },
        // deviceready Event Handler
        //
        // The scope of 'this' is the event. In order to call the 'receivedEvent'
        // function, we must explicitly call 'app.receivedEvent(...);'
    onDeviceReady: function() {
        app.receivedEvent('deviceready');
        document.getElementById("getFeatureFlagBtn").addEventListener("click", getFeatureFlag);
        document.getElementById("getAllFeatureFlagsBtn").addEventListener("click", getAllFeatureFlags);
        document.getElementById("refreshFeatureFlagsBtn").addEventListener("click", refreshFeatureFlags);
        document.getElementById("subscribeToFeatureFlagsBtn").addEventListener("click", subscribeToFeatureFlags);
        document.getElementById("getFeatureFlagPropertyBtn").addEventListener("click", getFeatureFlagProperty);
        document.getElementById("logFeatureFlagImpressionBtn").addEventListener("click", logFeatureFlagImpression);
        document.getElementById("changeUserBtn").addEventListener("click", changeUser);
        document.getElementById("getUserIdBtn").addEventListener("click", getUserId);
        document.getElementById("setSdkAuthBtn").addEventListener("click", setSdkAuthenticationSignature);
        document.getElementById("logCustomEventBtn").addEventListener("click", logCustomEvent);
        document.getElementById("logPurchaseBtn").addEventListener("click", logPurchase);
        document.getElementById("setCustomUserAttributeBtn").addEventListener("click", setCustomUserAttribute);
        document.getElementById("mergeCustomUserAttributeBtn").addEventListener("click", mergeCustomUserAttribute);
        document.getElementById("setUserPropertiesBtn").addEventListener("click", setUserProperties);
        document.getElementById("launchNewsFeedBtn").addEventListener("click", launchNewsFeed);
        document.getElementById("launchContentCardsBtn").addEventListener("click", launchContentCards);
        document.getElementById("unsetCustomUserAttributeBtn").addEventListener("click", unsetCustomUserAttribute);
        document.getElementById("setCustomUserAttributeArrayBtn").addEventListener("click", setCustomUserAttributeArray);
        document.getElementById("setCustomUserAttributeObjectArrayBtn").addEventListener("click", setCustomUserAttributeObjectsArray);
        document.getElementById("incrementCustomUserAttributeBtn").addEventListener("click", incrementCustomUserAttribute);
        document.getElementById("addToCustomUserAttributeArrayBtn").addEventListener("click", addToCustomUserAttributeArray);
        document.getElementById("removeFromCustomUserAttributeArrayBtn").addEventListener("click", removeFromCustomUserAttributeArray);
        document.getElementById("setAttributionDataBtn").addEventListener("click", setAttributionData);
        document.getElementById("getNewsFeedUnreadCountBtn").addEventListener("click", getNewsFeedUnreadCount);
        document.getElementById("getNewsFeedCardCountBtn").addEventListener("click", getNewsFeedCardCount);
        document.getElementById("getCardCountForCategoriesBtn").addEventListener("click", getCardCountForCategories);
        document.getElementById("getUnreadCardCountForCategoriesBtn").addEventListener("click", getUnreadCardCountForCategories);
        document.getElementById("getAllNewsFeedCardsBtn").addEventListener("click", getAllNewsFeedCards);
        document.getElementById("getAllContentCardsBtn").addEventListener("click", getContentCardsFromServer);
        document.getElementById("logContentCardAnalyticsBtn").addEventListener("click", logContentCardAnalytics);
        document.getElementById("addAliasBtn").addEventListener("click", addAlias);
        document.getElementById("wipeData").addEventListener("click", wipeData);
        document.getElementById("enableSdk").addEventListener("click", enableSdk);
        document.getElementById("disableSdk").addEventListener("click", disableSdk);
        document.getElementById("requestFlushBtn").addEventListener("click", requestDataFlush);
        document.getElementById("setLanguageBtn").addEventListener("click", setLanguage);
        document.getElementById("setLastKnownLocationBtn").addEventListener("click", setLastKnownLocation);
        document.getElementById("setLocationCustomAttributeBtn").addEventListener("click", setLocationCustomAttribute);
        document.getElementById("getDeviceId").addEventListener("click", getDeviceId);
        document.getElementById("requestPushPermission").addEventListener("click", requestPushPermission);
        document.getElementById("updateTrackingPropertiesBtn").addEventListener("click", updateTrackingProperties);
        document.getElementById("enableAdTrackingBtn").addEventListener("click", enableAdTracking);
        document.getElementById("subscribeToInAppMessageBtn").addEventListener("click", subscribeToInAppMessage);
        document.getElementById("hideCurrentInAppMessageBtn").addEventListener("click", hideCurrentInAppMessage);
        BrazePlugin.subscribeToSdkAuthenticationFailures(customPluginSuccessCallback(), customPluginErrorCallback);
    },
        // Update DOM on a Received Event
    receivedEvent: function(id) {
        var parentElement = document.getElementById(id);
        var listeningElement = parentElement.querySelector('.listening');
        var receivedElement = parentElement.querySelector('.received');

        listeningElement.setAttribute('style', 'display:none;');
        receivedElement.setAttribute('style', 'display:block;');

        console.log('Received Event: ' + id);
    },
        // In-App Message Received Event
    inAppMessageReceived: function(message) {
        console.log('Received in-app message and logging analytics: ' + message);

        // Log In-App Message Events
        BrazePlugin.logInAppMessageClicked(message);
        BrazePlugin.logInAppMessageImpression(message);
        BrazePlugin.logInAppMessageButtonClicked(message, 0);
    }
};

app.initialize();

// Braze methods
function changeUser() {
    const userId = document.getElementById("changeUserInputId").value;
    const sdkAuthSignature = document.getElementById("sdkAuthSignature").value;
    if (!userId) {
        showTextBubble("User ID not entered.");
        return;
    }
    if (!sdkAuthSignature) {
        BrazePlugin.changeUser(userId);
    } else {
        BrazePlugin.changeUser(userId, sdkAuthSignature);
    }
    showTextBubble(`User changed to ${userId} with auth signature ${sdkAuthSignature}`);
}

async function getUserId() {
    BrazePlugin.getUserId(customPluginSuccessCallback("User ID: "), customPluginErrorCallback);
    const userId = await BrazePlugin.getUserId();
    if (!userId) {
        showTextBubble("User ID not found.");
    } else {
        showTextBubble(`User ID: ${userId}`);
    }
}

function setSdkAuthenticationSignature() {
    const sdkAuthSignature = document.getElementById("sdkAuthSignature").value;
    if (!sdkAuthSignature) {
        showTextBubble("SDK auth signature not entered.");
        return;
    }
    BrazePlugin.setSdkAuthenticationSignature(sdkAuthSignature);
    showTextBubble(`SDK authentication signature set to ${sdkAuthSignature}`);
}

async function getFeatureFlag() {
    try {
        const featureFlagId = document.getElementById("featureFlagInputId").value;
        if (!featureFlagId) {
            showTextBubble('Feature Flag ID not entered.');
            return;
        }
        const featureFlag = await BrazePlugin.getFeatureFlag(featureFlagId);
        if (!featureFlag) {
            showTextBubble(`No Feature Flag found for ID: ${featureFlagId}`);
            return;
        }
        showTextBubble(`Feature Flag: ${JSON.stringify(featureFlag)}`);
    } catch (error) {
        // This method can error out if the Feature Flag fails to serialize at the native layer.
        showTextBubble(JSON.stringify(error));
    }
}

async function getAllFeatureFlags() {
    const featureFlags = await BrazePlugin.getAllFeatureFlags();
    showTextBubble(`All Feature Flags: ${JSON.stringify(featureFlags)}`);
}

function refreshFeatureFlags() {
    BrazePlugin.refreshFeatureFlags();
    showTextBubble("Refresh feature flags");
}

function subscribeToFeatureFlags() {
    BrazePlugin.subscribeToFeatureFlagsUpdates(featureFlagsUpdated);
    showTextBubble("Subscribed to Feature Flags");
}

async function getFeatureFlagProperty() {
    const featureFlagId = document.getElementById("featureFlagInputId").value;
    const propertyKey = document.getElementById("featureFlagPropertyKey").value;
    const propertyType = document.getElementById("featureFlagPropertyType").value;
    if (!featureFlagId) {
        showTextBubble("Feature Flag ID not entered.");
        return;
    }
    if (!propertyKey) {
        showTextBubble("Property key not entered.");
        return;
    }
    switch (propertyType) {
        case 'boolean':
            const booleanProperty = await BrazePlugin.getFeatureFlagBooleanProperty(featureFlagId, propertyKey);
            showTextBubble(`Got boolean property: ${booleanProperty}`);
            break;
        case 'number':
            const numberProperty = await BrazePlugin.getFeatureFlagNumberProperty(featureFlagId, propertyKey);
            showTextBubble(`Got number property: ${numberProperty}`);
            break;
        case 'string':
            const stringProperty = await BrazePlugin.getFeatureFlagStringProperty(featureFlagId, propertyKey);
            showTextBubble(`Got string property: ${stringProperty}`);
            break;
        case 'timestamp':
            const timestampProperty = await BrazePlugin.getFeatureFlagTimestampProperty(featureFlagId, propertyKey);
            showTextBubble(`Got timestamp property: ${timestampProperty}`);
            break;
        case 'jsonobject':
            const jsonProperty = await BrazePlugin.getFeatureFlagJSONProperty(featureFlagId, propertyKey);
            showTextBubble(`Got JSON property: ${JSON.stringify(jsonProperty)}`);
            break;
        case 'image':
            const imageProperty = await BrazePlugin.getFeatureFlagImageProperty(featureFlagId, propertyKey);
            showTextBubble(`Got image property: ${imageProperty}`);
            break;
        default:
            showTextBubble("No property type selected.");
    }
}

function logFeatureFlagImpression() {
    const featureFlagId = document.getElementById("featureFlagInputId").value;
    if (!featureFlagId) {
        showTextBubble("Feature Flag ID not entered.");
        return;
    }
    BrazePlugin.logFeatureFlagImpression(featureFlagId);
    showTextBubble(`Impression logged for FF ${featureFlagId}`);
}

function logCustomEvent() {
    const customEventID = document.getElementById("logCustomEventId").value;
    BrazePlugin.logCustomEvent(customEventID);
    showTextBubble(`Logged custom event ${customEventID}`);

    /* TODO: Add properties input for custom events and purchases */
    var properties = {};
    properties["One"] = "That's the Way of the World";
    properties["Two"] = "After the Love Has Gone";
    properties["Three"] = "Can't Hide Love";
    BrazePlugin.logCustomEvent("cordovaCustomEventWithProperties", properties);
    BrazePlugin.logCustomEvent("cordovaCustomEventWithoutProperties");
    BrazePlugin.logCustomEvent("cordovaCustomEventWithFloatProperties", {
        "Cart Value": 4.95,
        "Cart Item Name": "Spicy Chicken Bites 5 pack"
    });
    BrazePlugin.logCustomEvent("cordovaCustomEventWithNestedProperties", {
        "array key": [1, "2", false],
        "object key": {
            "k1": "1",
            "k2": 2,
            "k3": false,
        },
        "deep key": {
            "key": [1, "2", true]
        }
    });
}

function logPurchase() {
    const productID = document.getElementById("productId").value || null;
    const purchaseAmount = document.getElementById("purchaseAmount").value || null;
    const purchaseCurrency = document.getElementById("purchaseCurrency").value || null;
    const purchaseQuantity = document.getElementById("purchaseQuantity").value || null;

    BrazePlugin.logPurchase(productID, purchaseAmount, purchaseCurrency, purchaseQuantity);
    showTextBubble(`Logged purchase: ${productID}`);

    /* TODO: Add properties input for custom events and purchases */
    var properties = {};
    properties["One"] = "Apple";
    properties["Two"] = "Orange";
    properties["Three"] = "Peach";
    BrazePlugin.logPurchase("testPurchase", 10, "USD", 5, properties);
    BrazePlugin.logPurchase("testPurchaseWithDecimal", 13.37, "USD", 5, properties);
    BrazePlugin.logPurchase("testPurchaseWithNullCurrency", 10, null, 5, properties);
    BrazePlugin.logPurchase("testPurchaseWithNullQuantity", 10, "USD");
    BrazePlugin.logPurchase("testPurchaseWithoutProperties", 1500, "JPY", 2);
    BrazePlugin.logPurchase("testPurchaseWithNestedProperties", 10, "USD", 5, {
        "array key": [1, "2", false],
        "object key": {
            "k1": "1",
            "k2": 2,
            "k3": false,
        },
        "deep key": {
            "key": [1, "2", true]
        }
    });
}

// Braze User methods
function setCustomUserAttribute() {
    BrazePlugin.setCustomUserAttribute("cordovaCustomAttributeKey", "cordovaCustomAttributeValue");
    BrazePlugin.incrementCustomUserAttribute("cordovaIncrementCustomAttributeKey", 1);

    BrazePlugin.setCustomUserAttribute("CordovaNCA", {
        "array key": [1, "two", false],
        "object key": {
            "k1": "one",
            "k2": 2,
            "k3": false,
        },
        "deep key": {
            "key": [1, "two", true]
        }
    });

    showTextBubble("Set Custom User Attribute");
}

function mergeCustomUserAttribute() {
    BrazePlugin.setCustomUserAttribute("CordovaNCA", 
    {
        "mergedInt": 1,
        "object key": {
            "mergek1": "1",
            "mergek2": 2,
            "mergek3": false,
        }
    },
    true);
    showTextBubble("Merge Custom User Attribute");
}

function setCustomUserAttributeArray() {
    BrazePlugin.setCustomUserAttribute("cordovaAttributeArrayButton", ["a", "b"]);
    showTextBubble("Set Custom User Attribute Strings Array");
}

function setCustomUserAttributeObjectsArray() {
    BrazePlugin.setCustomUserAttribute("cordovaAttributeArrayButton", [
        { 
          "location": "East Rutherford, New Jersey",
          "nickname": "Giants"
        },
        { 
          "location": "Arlington, Texas",
          "nickname": "Cowboys"
        }  
    ]);
    showTextBubble("Set Custom User Attribute Objects Array");
}

function incrementCustomUserAttribute() {
    BrazePlugin.incrementCustomUserAttribute("cordovaIncrementCustomAttributeKey", 2);
    showTextBubble("Incremented Custom User Attribute");
}

function addToCustomUserAttributeArray() {
    BrazePlugin.addToCustomUserAttributeArray("cordovaAttributeArrayButton", "c");
    showTextBubble("Added To Custom User Attribute Array");
}

function removeFromCustomUserAttributeArray() {
    BrazePlugin.removeFromCustomUserAttributeArray("cordovaAttributeArrayButton", "b");
    showTextBubble("Removed From Custom User Attribute Array");
}

function unsetCustomUserAttribute() {
    BrazePlugin.unsetCustomUserAttribute("double");
    showTextBubble("Unset Custom User Attribute");
}

function setUserProperties() {
    BrazePlugin.setFirstName("firstName");
    BrazePlugin.setLastName("lastName");
    BrazePlugin.setEmail("email@test.com");
    BrazePlugin.setGender(BrazePlugin.Genders.FEMALE);
    BrazePlugin.setCountry("USA");
    BrazePlugin.setHomeCity("New York");
    BrazePlugin.setPhoneNumber("1234567890");
    BrazePlugin.setDateOfBirth(1987, 9, 21);
    BrazePlugin.setPushNotificationSubscriptionType(BrazePlugin.NotificationSubscriptionTypes.OPTED_IN);
    BrazePlugin.setEmailNotificationSubscriptionType(BrazePlugin.NotificationSubscriptionTypes.OPTED_IN);
    BrazePlugin.setCustomUserAttribute("string", "stringValue");
    BrazePlugin.setCustomUserAttribute("double", 1.2);
    BrazePlugin.setCustomUserAttribute("int", 5);
    BrazePlugin.setCustomUserAttribute("bool", true);
    BrazePlugin.setCustomUserAttribute("date", new Date());
    BrazePlugin.addToSubscriptionGroup("12345");
    showTextBubble("Set User Properties");
}

function setAttributionData() {
    BrazePlugin.setUserAttributionData("networkval", "campaignval", "adgroupval", "creativeval");
    showTextBubble("Set Attribution Data");
}

function wipeData() {
    BrazePlugin.wipeData();
    showTextBubble("Wiped SDK Data");
}

function enableSdk() {
    BrazePlugin.enableSdk();
    showTextBubble("Enabling the Braze SDK");
}

function disableSdk() {
    BrazePlugin.disableSdk();
    showTextBubble("Disabling the Braze SDK");
}

function requestDataFlush() {
    BrazePlugin.requestImmediateDataFlush();
    showTextBubble("Requesting data flush");
}

// Launch functions
function launchNewsFeed() {
    BrazePlugin.launchNewsFeed();
}

function launchContentCards() {
    BrazePlugin.launchContentCards();
}

// News feed functions
function getNewsFeedUnreadCount() {
    BrazePlugin.getNewsFeedUnreadCount(customPluginSuccessCallback("get Unread News Feed Count is : "), customPluginErrorCallback);
}

function getNewsFeedCardCount() {
    BrazePlugin.getNewsFeedCardCount(customPluginSuccessCallback("get News Feed Card Count is : "), customPluginErrorCallback);
}

function getCardCountForCategories() {
    BrazePlugin.getCardCountForCategories(customPluginSuccessCallback("get Card Count For Categories is : "), customPluginErrorCallback,
        [BrazePlugin.CardCategories.ADVERTISING, BrazePlugin.CardCategories.SOCIAL]);
}

function getUnreadCardCountForCategories() {
    BrazePlugin.getUnreadCardCountForCategories(customPluginSuccessCallback("get Unread Card Count For Categories is : "), customPluginErrorCallback,
        [BrazePlugin.CardCategories.NEWS, BrazePlugin.CardCategories.ANNOUNCEMENTS]);
}

function getAllNewsFeedCards() {
    BrazePlugin.getNewsFeed(customPluginSuccessArrayCallback("test"), customPluginErrorCallback);
}

function getContentCardsFromServer() {
    BrazePlugin.getContentCardsFromServer(customPluginSuccessArrayCallback("test"), customPluginErrorCallback);
}

function logContentCardAnalytics() {
    // Log all the analytics methods for the first returned card
    BrazePlugin.getContentCardsFromServer(function(cards) {
        if (cards.length < 1) {
            return;
        }

        var firstCardId = cards[0]["id"];
        BrazePlugin.logContentCardClicked(firstCardId);
        BrazePlugin.logContentCardImpression(firstCardId);
        BrazePlugin.logContentCardDismissed(firstCardId);
    });
}

function subscribeToInAppMessage() {
    BrazePlugin.subscribeToInAppMessage(true);
    showTextBubble("Subscribed to In-App Messages");
}

function hideCurrentInAppMessage() {
    BrazePlugin.hideCurrentInAppMessage();
}

function addAlias() {
    const aliasName = document.getElementById("aliasName").value;
    const aliasLabel = document.getElementById("aliasLabel").value;
    BrazePlugin.addAlias(aliasName, aliasLabel);
    showTextBubble(`Add alias name ${aliasName} with label ${aliasLabel}`);
}

function setLanguage() {
    const languageCode = document.getElementById("languageCode").value;
    BrazePlugin.setLanguage(languageCode);
    showTextBubble(`Language set to ${languageCode}`);
}

function setLastKnownLocation() {
    const latitude = document.getElementById("latitude").value ? document.getElementById("latitude").value : null;
    const longitude = document.getElementById("longitude").value ? document.getElementById("longitude").value : null;
    const altitude = document.getElementById("altitude").value ? document.getElementById("altitude").value : null;
    const horizontalAccuracy = document.getElementById("horizontalAccuracy").value ? document.getElementById("horizontalAccuracy").value : null;
    const verticalAccuracy = document.getElementById("verticalAccuracy").value ? document.getElementById("verticalAccuracy").value : null;
    BrazePlugin.setLastKnownLocation(latitude, longitude, altitude, horizontalAccuracy, verticalAccuracy);
    if (latitude && longitude) {
        showTextBubble(`Last Known Location set to ${latitude}, ${longitude}`);
    }
}

function setLocationCustomAttribute() {
    BrazePlugin.setLocationCustomAttribute("work", 40.7128, 74.006);
    showTextBubble("Location custom attribute set.");
}

function getDeviceId() {
    BrazePlugin.getDeviceId(customPluginSuccessCallback("Device ID: "), customPluginErrorCallback);
}

function requestPushPermission() {
    BrazePlugin.requestPushPermission();
    showTextBubble("requestPushPermission() called");
}

async function updateTrackingProperties() {
    const allowList = {
        adding: [
            BrazePlugin.TrackingProperty.FIRST_NAME,
            BrazePlugin.TrackingProperty.LAST_NAME,
        ],
        removing: [BrazePlugin.TrackingProperty.DEVICE_DATA],
        addingCustomEvents: ['custom-event1', 'custom-event2'],
        removingCustomAttributes: ['attr-1']
    };
    BrazePlugin.updateTrackingPropertyAllowList(allowList);
    console.log(
        `Update tracking allow list with: ${JSON.stringify(allowList)}`,
    );
    showTextBubble(`Updated tracking allow list: ${JSON.stringify(allowList)}`);
}

function enableAdTracking() {
    const testAdvertisingID = '123';
    BrazePlugin.setAdTrackingEnabled(true, testAdvertisingID);
    showTextBubble(`Ad tracking enabled with ID: ${testAdvertisingID}`);
}

// Other helper functions
function showTextBubble(bubbleMessage) {
    // Get the snackbar DIV
    var bubbleElement = document.getElementById("snackbar");

    // Make the bubble display our message
    bubbleElement.innerHTML = bubbleMessage;

    // Add the "show" class to DIV
    bubbleElement.className = "show";

    // After 3 seconds, remove the show class from DIV
    setTimeout(function(){ bubbleElement.className = bubbleElement.className.replace("show", ""); }, 3000);
}

/**
* Serves as the success callback for the Braze Plugin. Displays a text bubble with a message when called.
**/
function customPluginSuccessCallback(bubbleMessage) {
    return function(callbackResult) { 
        if (typeof callbackResult === 'object') {
            console.log(JSON.stringify(callbackResult));
        } else {
            showTextBubble(bubbleMessage + " " + callbackResult);
        }
    };
}

/**
* Serves as the success callback for the Braze Plugin. Displays a text bubble with a message when called.
**/
function customPluginSuccessJsonCallback(bubbleMessage) {
    return function(callbackResult) { showTextBubble(bubbleMessage + " JSON: " + JSON.stringify(callbackResult)) };
}

/**
* Serves as the success callback for the Braze Plugin. Displays a text bubble with a message when called.
**/
function customPluginSuccessArrayCallback(bubbleMessage) {
    return function(callbackResult) {
        console.log(callbackResult);
        var numElements = callbackResult.length;
        showTextBubble("Logging all " + numElements + " objects")
        for (var i = 0; i < numElements; i++) {
            console.log(JSON.stringify(callbackResult[i]));
        }
 };
}

function featureFlagsUpdated(featureFlags) {
    var numElements = featureFlags.length;
    showTextBubble("Feature Flags Updated: " + numElements + " objects")
    for (var i = 0; i < numElements; i++) {
        console.log(" Feature Flag - " + JSON.stringify(featureFlags[i]));
    }
}

/**
* Serves as the error callback for the Braze Plugin. Displays a text bubble with a message when called.
**/
function customPluginErrorCallback(callbackResult) {
    console.log(callbackResult);
}
