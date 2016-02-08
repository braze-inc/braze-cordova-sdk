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
    document.getElementById("submitFeedbackBtn").addEventListener("click", submitFeedback);
    document.getElementById("setCustomUserAttributeBtn").addEventListener("click", setCustomUserAttribute);
    document.getElementById("setUserPropertiesBtn").addEventListener("click", setUserProperties);
    document.getElementById("launchNewsFeedBtn").addEventListener("click", launchNewsFeed);
    document.getElementById("launchFeedbackBtn").addEventListener("click", launchFeedback);
    document.getElementById("unsetCustomUserAttributeBtn").addEventListener("click", unsetCustomUserAttribute);
    document.getElementById("setCustomUserAttributeArrayBtn").addEventListener("click", setCustomUserAttributeArray);
    document.getElementById("incrementCustomUserAttributeBtn").addEventListener("click", incrementCustomUserAttribute);
    document.getElementById("addToCustomUserAttributeArrayBtn").addEventListener("click", addToCustomUserAttributeArray);
    document.getElementById("removeFromCustomUserAttributeArrayBtn").addEventListener("click", removeFromCustomUserAttributeArray);
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
}
function logCustomEvent() {
    var properties = {};
    properties["One"] = "That's the Way of the World";
    properties["Two"] = "After the Love Has Gone";
    properties["Three"] = "Can't Hide Love";
    AppboyPlugin.logCustomEvent("cordovaCustomEventWithProperties", properties);
    AppboyPlugin.logCustomEvent("cordovaCustomEventWithoutProperties");
}
function logPurchase() {
    var properties = {};
    properties["One"] = "Apple";
    properties["Two"] = "Orange";
    properties["Three"] = "Peach";
    AppboyPlugin.logPurchase("testPurchase", 10, "USD", 5, properties);
    AppboyPlugin.logPurchase("testPurchaseWithNullCurrency", 10, null, 5, properties);
    AppboyPlugin.logPurchase("testPurchaseWithNullQuantity", 10, "USD");
    AppboyPlugin.logPurchase("testPurchaseWithoutProperties", 1500, "JPY", 2);
}
function submitFeedback() {
    AppboyPlugin.submitFeedback("cordova@test.com", "nice app!", true);
}
// Appboy User methods
function setCustomUserAttribute() {
    AppboyPlugin.setCustomUserAttribute("cordovaCustomAttributeKey", "cordovaCustomAttributeValue");
    AppboyPlugin.incrementCustomUserAttribute("cordovaIncrementCustomAttributeKey", 1);
}
function setCustomUserAttributeArray() {
    AppboyPlugin.setCustomUserAttribute("cordovaAttributeArrayButton", ["a", "b"]);
}
function incrementCustomUserAttribute() {
    AppboyPlugin.incrementCustomUserAttribute("cordovaIncrementCustomAttributeKey", 2);
}
function addToCustomUserAttributeArray() {
    AppboyPlugin.addToCustomUserAttributeArray("cordovaAttributeArrayButton", "c");
}
function removeFromCustomUserAttributeArray() {
    AppboyPlugin.removeFromCustomUserAttributeArray("cordovaAttributeArrayButton", "b");
}
function unsetCustomUserAttribute() {
    AppboyPlugin.unsetCustomUserAttribute("double");
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
    AppboyPlugin.setAvatarImageUrl("https://raw.githubusercontent.com/Appboy/appboy-android-sdk/master/Appboy_Logo_400x100.png");
    AppboyPlugin.setPushNotificationSubscriptionType(AppboyPlugin.NotificationSubscriptionTypes.OPTED_IN);
    AppboyPlugin.setEmailNotificationSubscriptionType(AppboyPlugin.NotificationSubscriptionTypes.OPTED_IN);
    AppboyPlugin.setCustomUserAttribute("string", "stringValue");
    AppboyPlugin.setCustomUserAttribute("double", 1.2);
    AppboyPlugin.setCustomUserAttribute("int", 5);
    AppboyPlugin.setCustomUserAttribute("bool", true);
    AppboyPlugin.setCustomUserAttribute("date", new Date());    
}
// Other
function launchNewsFeed() {
    AppboyPlugin.launchNewsFeed();
}
function launchFeedback() {
    AppboyPlugin.launchFeedback();
}
