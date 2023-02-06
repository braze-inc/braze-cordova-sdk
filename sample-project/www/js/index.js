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
    document.getElementById("changeUserBtn").addEventListener("click", changeUser);
    document.getElementById("logCustomEventBtn").addEventListener("click", logCustomEvent);
    document.getElementById("logPurchaseBtn").addEventListener("click", logPurchase);
    document.getElementById("setCustomUserAttributeBtn").addEventListener("click", setCustomUserAttribute);
    document.getElementById("setUserPropertiesBtn").addEventListener("click", setUserProperties);
    document.getElementById("launchNewsFeedBtn").addEventListener("click", launchNewsFeed);
    document.getElementById("launchContentCardsBtn").addEventListener("click", launchContentCards);
    document.getElementById("unsetCustomUserAttributeBtn").addEventListener("click", unsetCustomUserAttribute);
    document.getElementById("setCustomUserAttributeArrayBtn").addEventListener("click", setCustomUserAttributeArray);
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
    document.getElementById("getDeviceId").addEventListener("click", getDeviceId);
    document.getElementById("requestPushPermission").addEventListener("click", requestPushPermission);

    var success = function(message) {
        alert(message);
    }

    var failure = function() {
        alert("Error calling Hello Plugin");
    }
},
    // Update DOM on a Received Event
receivedEvent: function(id) {
    var parentElement = document.getElementById(id);
    var listeningElement = parentElement.querySelector('.listening');
    var receivedElement = parentElement.querySelector('.received');

    listeningElement.setAttribute('style', 'display:none;');
    receivedElement.setAttribute('style', 'display:block;');

    console.log('Received Event: ' + id);
}
};

app.initialize();

// Appboy methods
function changeUser() {
    AppboyPlugin.changeUser(document.getElementById("changeUserInputId").value);
    showTextBubble("Change user called");
}

function logCustomEvent() {
    var properties = {};
    properties["One"] = "That's the Way of the World";
    properties["Two"] = "After the Love Has Gone";
    properties["Three"] = "Can't Hide Love";
    AppboyPlugin.logCustomEvent("cordovaCustomEventWithProperties", properties);
    AppboyPlugin.logCustomEvent("cordovaCustomEventWithoutProperties");
    AppboyPlugin.logCustomEvent("cordovaCustomEventWithFloatProperties", {
        "Cart Value": 4.95,
        "Cart Item Name": "Spicy Chicken Bites 5 pack"
    });
    AppboyPlugin.logCustomEvent("cordovaCustomEventWithNestedProperties", {
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
    showTextBubble("Logged custom event");
}

function logPurchase() {
    var properties = {};
    properties["One"] = "Apple";
    properties["Two"] = "Orange";
    properties["Three"] = "Peach";
    AppboyPlugin.logPurchase("testPurchase", 10, "USD", 5, properties);
    AppboyPlugin.logPurchase("testPurchaseWithDecimal", 13.37, "USD", 5, properties);
    AppboyPlugin.logPurchase("testPurchaseWithNullCurrency", 10, null, 5, properties);
    AppboyPlugin.logPurchase("testPurchaseWithNullQuantity", 10, "USD");
    AppboyPlugin.logPurchase("testPurchaseWithoutProperties", 1500, "JPY", 2);
    AppboyPlugin.logPurchase("testPurchaseWithNestedProperties", 10, "USD", 5, {
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
    showTextBubble("Logged purchase");
}

// Appboy User methods
function setCustomUserAttribute() {
    AppboyPlugin.setCustomUserAttribute("cordovaCustomAttributeKey", "cordovaCustomAttributeValue");
    AppboyPlugin.incrementCustomUserAttribute("cordovaIncrementCustomAttributeKey", 1);
    showTextBubble("Set Custom User Attribute");
}

function setCustomUserAttributeArray() {
    AppboyPlugin.setCustomUserAttribute("cordovaAttributeArrayButton", ["a", "b"]);
    showTextBubble("Set Custom User Attribute Array");
}

function incrementCustomUserAttribute() {
    AppboyPlugin.incrementCustomUserAttribute("cordovaIncrementCustomAttributeKey", 2);
    showTextBubble("Incremented Custom User Attribute");
}

function addToCustomUserAttributeArray() {
    AppboyPlugin.addToCustomUserAttributeArray("cordovaAttributeArrayButton", "c");
    showTextBubble("Added To Custom User Attribute Array");
}

function removeFromCustomUserAttributeArray() {
    AppboyPlugin.removeFromCustomUserAttributeArray("cordovaAttributeArrayButton", "b");
    showTextBubble("Removed From Custom User Attribute Array");
}

function unsetCustomUserAttribute() {
    AppboyPlugin.unsetCustomUserAttribute("double");
    showTextBubble("Unset Custom User Attribute");
}

function setUserProperties() {
    AppboyPlugin.setFirstName("firstName");
    AppboyPlugin.setLastName("lastName");
    AppboyPlugin.setEmail("email@test.com");
    AppboyPlugin.setGender(AppboyPlugin.Genders.FEMALE);
    AppboyPlugin.setCountry("USA");
    AppboyPlugin.setHomeCity("New York");
    AppboyPlugin.setPhoneNumber("1234567890");
    AppboyPlugin.setDateOfBirth(1987, 9, 21);
    AppboyPlugin.setPushNotificationSubscriptionType(AppboyPlugin.NotificationSubscriptionTypes.OPTED_IN);
    AppboyPlugin.setEmailNotificationSubscriptionType(AppboyPlugin.NotificationSubscriptionTypes.OPTED_IN);
    AppboyPlugin.setCustomUserAttribute("string", "stringValue");
    AppboyPlugin.setCustomUserAttribute("double", 1.2);
    AppboyPlugin.setCustomUserAttribute("int", 5);
    AppboyPlugin.setCustomUserAttribute("bool", true);
    AppboyPlugin.setCustomUserAttribute("date", new Date());
    AppboyPlugin.addToSubscriptionGroup("12345");
    showTextBubble("Set User Properties");
}

function setAttributionData() {
    AppboyPlugin.setUserAttributionData("networkval", "campaignval", "adgroupval", "creativeval");
    showTextBubble("Set Attribution Data");
}

function wipeData() {
    AppboyPlugin.wipeData();
    showTextBubble("Wiped SDK Data");
}

function enableSdk() {
    AppboyPlugin.enableSdk();
    showTextBubble("Enabling the Braze SDK");
}

function disableSdk() {
    AppboyPlugin.disableSdk();
    showTextBubble("Disabling the Braze SDK");
}

function requestDataFlush() {
    AppboyPlugin.requestImmediateDataFlush();
    showTextBubble("Requesting data flush");
}

// Launch functions
function launchNewsFeed() {
    AppboyPlugin.launchNewsFeed();
}

function launchContentCards() {
    AppboyPlugin.launchContentCards();
}

// News feed functions
function getNewsFeedUnreadCount() {
    AppboyPlugin.getNewsFeedUnreadCount(customPluginSuccessCallback("get Unread News Feed Count is : "), customPluginErrorCallback);
}

function getNewsFeedCardCount() {
    AppboyPlugin.getNewsFeedCardCount(customPluginSuccessCallback("get News Feed Card Count is : "), customPluginErrorCallback);
}

function getCardCountForCategories() {
    AppboyPlugin.getCardCountForCategories(customPluginSuccessCallback("get Card Count For Categories is : "), customPluginErrorCallback,
        [AppboyPlugin.CardCategories.ADVERTISING, AppboyPlugin.CardCategories.SOCIAL]);
}

function getUnreadCardCountForCategories() {
    AppboyPlugin.getUnreadCardCountForCategories(customPluginSuccessCallback("get Unread Card Count For Categories is : "), customPluginErrorCallback,
        [AppboyPlugin.CardCategories.NEWS, AppboyPlugin.CardCategories.ANNOUNCEMENTS]);
}

function getAllNewsFeedCards() {
    AppboyPlugin.getNewsFeed(customPluginSuccessArrayCallback("test"), customPluginErrorCallback);
}

function getContentCardsFromServer() {
    AppboyPlugin.getContentCardsFromServer(customPluginSuccessArrayCallback("test"), customPluginErrorCallback);
}

function logContentCardAnalytics() {
    // Log all the analytics methods for the first returned card
    AppboyPlugin.getContentCardsFromServer(function(cards) {
        if (cards.length < 1) {
            return;
        }

        var firstCardId = cards[0]["id"];
        AppboyPlugin.logContentCardClicked(firstCardId);
        AppboyPlugin.logContentCardImpression(firstCardId);
        AppboyPlugin.logContentCardDismissed(firstCardId);
    });
}

function addAlias() {
    AppboyPlugin.addAlias("foo123", "bar456");
    showTextBubble("Add alias called");
}

function setLanguage() {
    AppboyPlugin.setLanguage("fr");
    showTextBubble("Set Language called");
}

function getDeviceId() {
    AppboyPlugin.getDeviceId(customPluginSuccessCallback("DeviceID: "), customPluginErrorCallback);
}

function requestPushPermission() {
    AppboyPlugin.requestPushPermission();
    showTextBubble("requestPushPermission() called");
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
* Serves as the success callback for the Appboy Plugin. Displays a text bubble with a message when called.
**/
function customPluginSuccessCallback(bubbleMessage) {
    return function(callbackResult) { showTextBubble(bubbleMessage + " " + callbackResult) };
}

/**
* Serves as the success callback for the Appboy Plugin. Displays a text bubble with a message when called.
**/
function customPluginSuccessArrayCallback(bubbleMessage) {
    return function(callbackResult) {
        var numElements = callbackResult.length;
        showTextBubble("Logging all " + numElements + " objects")
        for (var i = 0; i < numElements; i++) {
            console.log(JSON.stringify(callbackResult[i]));
        }
 };
}

/**
* Serves as the error callback for the Appboy Plugin. Displays a text bubble with a message when called.
**/
function customPluginErrorCallback(callbackResult) {
    console.log(callbackResult);
}
