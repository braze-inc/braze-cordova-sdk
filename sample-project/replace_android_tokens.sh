sed -i -e 's/\$PACKAGE_NAME/com.appboy.hellocordova/g' platforms/android/src/com/appboy/AppboyBroadcastReceiver.java
sed -i -e 's/\$APPBOY_API_KEY/7ef72382-b92f-4258-9be9-9e19e92f3bf1/g' platforms/android/res/values/appboy.xml
sed -i -e 's/\$APPBOY_PUSH_REGISTRATION_ENABLED/true/g' platforms/android/res/values/appboy.xml
sed -i -e 's/\$APPBOY_GCM_SENDER_ID/901477453852/g' platforms/android/res/values/appboy.xml
