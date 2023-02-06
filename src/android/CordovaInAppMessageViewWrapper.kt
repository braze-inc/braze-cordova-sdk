package com.braze.cordova

import android.view.View
import android.view.animation.Animation
import com.braze.configuration.BrazeConfigurationProvider
import com.braze.models.inappmessage.IInAppMessage
import com.braze.support.BrazeLogger.Priority.V
import com.braze.support.BrazeLogger.brazelog
import com.braze.ui.inappmessage.DefaultInAppMessageViewWrapper
import com.braze.ui.inappmessage.IInAppMessageViewWrapper
import com.braze.ui.inappmessage.IInAppMessageViewWrapperFactory
import com.braze.ui.inappmessage.listeners.IInAppMessageViewLifecycleListener

class CordovaInAppMessageViewWrapper : DefaultInAppMessageViewWrapper {
    @Suppress("LongParameterList")
    constructor(
        inAppMessageView: View,
        inAppMessage: IInAppMessage,
        inAppMessageViewLifecycleListener: IInAppMessageViewLifecycleListener,
        configurationProvider: BrazeConfigurationProvider,
        openingAnimation: Animation?,
        closingAnimation: Animation?,
        clickableInAppMessageView: View?
    ) : super(
        inAppMessageView,
        inAppMessage,
        inAppMessageViewLifecycleListener,
        configurationProvider,
        openingAnimation,
        closingAnimation,
        clickableInAppMessageView
    )

    @Suppress("LongParameterList")
    constructor(
        inAppMessageView: View,
        inAppMessage: IInAppMessage,
        inAppMessageViewLifecycleListener: IInAppMessageViewLifecycleListener,
        configurationProvider: BrazeConfigurationProvider,
        openingAnimation: Animation?,
        closingAnimation: Animation?,
        clickableInAppMessageView: View?,
        buttonViews: List<View>?,
        closeButton: View?
    ) : super(
        inAppMessageView,
        inAppMessage,
        inAppMessageViewLifecycleListener,
        configurationProvider,
        openingAnimation,
        closingAnimation,
        clickableInAppMessageView,
        buttonViews,
        closeButton
    )

    override fun finalizeViewBeforeDisplay(
        inAppMessage: IInAppMessage,
        inAppMessageView: View,
        inAppMessageViewLifecycleListener: IInAppMessageViewLifecycleListener
    ) {
        brazelog(V) { "Running custom Cordova finalizeViewBeforeDisplay" }
        announceForAccessibilityIfNecessary()
        inAppMessageViewLifecycleListener.afterOpened(inAppMessageView, inAppMessage)
    }

    class CordovaInAppMessageViewWrapperFactory : IInAppMessageViewWrapperFactory {
        override fun createInAppMessageViewWrapper(
            inAppMessageView: View,
            inAppMessage: IInAppMessage,
            inAppMessageViewLifecycleListener: IInAppMessageViewLifecycleListener,
            configurationProvider: BrazeConfigurationProvider,
            openingAnimation: Animation?,
            closingAnimation: Animation?,
            clickableInAppMessageView: View?
        ): IInAppMessageViewWrapper {
            return CordovaInAppMessageViewWrapper(
                inAppMessageView,
                inAppMessage,
                inAppMessageViewLifecycleListener,
                configurationProvider,
                openingAnimation,
                closingAnimation,
                clickableInAppMessageView
            )
        }

        override fun createInAppMessageViewWrapper(
            inAppMessageView: View,
            inAppMessage: IInAppMessage,
            inAppMessageViewLifecycleListener: IInAppMessageViewLifecycleListener,
            configurationProvider: BrazeConfigurationProvider,
            openingAnimation: Animation?,
            closingAnimation: Animation?,
            clickableInAppMessageView: View?,
            buttons: List<View>?,
            closeButton: View?
        ): IInAppMessageViewWrapper {
            return CordovaInAppMessageViewWrapper(
                inAppMessageView,
                inAppMessage,
                inAppMessageViewLifecycleListener,
                configurationProvider,
                openingAnimation,
                closingAnimation,
                clickableInAppMessageView,
                buttons,
                closeButton
            )
        }
    }
}
