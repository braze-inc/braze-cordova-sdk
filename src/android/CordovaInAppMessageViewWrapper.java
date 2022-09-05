package com.appboy.cordova;

import android.view.View;
import android.view.animation.Animation;

import com.braze.configuration.BrazeConfigurationProvider;
import com.braze.models.inappmessage.IInAppMessage;
import com.braze.support.BrazeLogger;
import com.braze.ui.inappmessage.DefaultInAppMessageViewWrapper;
import com.braze.ui.inappmessage.IInAppMessageViewWrapper;
import com.braze.ui.inappmessage.IInAppMessageViewWrapperFactory;
import com.braze.ui.inappmessage.listeners.IInAppMessageViewLifecycleListener;

import java.util.List;

public class CordovaInAppMessageViewWrapper extends DefaultInAppMessageViewWrapper {
  private static final String TAG = BrazeLogger.getBrazeLogTag(CordovaInAppMessageViewWrapper.class);

  public CordovaInAppMessageViewWrapper(View inAppMessageView,
                                        IInAppMessage inAppMessage,
                                        IInAppMessageViewLifecycleListener inAppMessageViewLifecycleListener,
                                        BrazeConfigurationProvider configurationProvider,
                                        Animation openingAnimation,
                                        Animation closingAnimation,
                                        View clickableInAppMessageView) {
    super(inAppMessageView,
        inAppMessage,
        inAppMessageViewLifecycleListener,
        configurationProvider,
        openingAnimation,
        closingAnimation,
        clickableInAppMessageView);
  }

  public CordovaInAppMessageViewWrapper(View inAppMessageView,
                                        IInAppMessage inAppMessage,
                                        IInAppMessageViewLifecycleListener inAppMessageViewLifecycleListener,
                                        BrazeConfigurationProvider configurationProvider,
                                        Animation openingAnimation,
                                        Animation closingAnimation,
                                        View clickableInAppMessageView,
                                        List<View> buttonViews,
                                        View closeButton) {
    super(inAppMessageView,
        inAppMessage,
        inAppMessageViewLifecycleListener,
        configurationProvider,
        openingAnimation,
        closingAnimation,
        clickableInAppMessageView,
        buttonViews,
        closeButton);
  }

  @Override
  protected void finalizeViewBeforeDisplay(final IInAppMessage inAppMessage,
                                           final View inAppMessageView,
                                           final IInAppMessageViewLifecycleListener inAppMessageViewLifecycleListener) {
    BrazeLogger.v(TAG, "Running custom Cordova finalizeViewBeforeDisplay");
    announceForAccessibilityIfNecessary();
    inAppMessageViewLifecycleListener.afterOpened(inAppMessageView, inAppMessage);
  }

  public static class CordovaInAppMessageViewWrapperFactory implements IInAppMessageViewWrapperFactory {
    @Override
    public IInAppMessageViewWrapper createInAppMessageViewWrapper(View inAppMessageView,
                                                                  IInAppMessage inAppMessage,
                                                                  IInAppMessageViewLifecycleListener inAppMessageViewLifecycleListener,
                                                                  BrazeConfigurationProvider configurationProvider,
                                                                  Animation openingAnimation,
                                                                  Animation closingAnimation,
                                                                  View clickableInAppMessageView) {
      return new CordovaInAppMessageViewWrapper(inAppMessageView,
          inAppMessage,
          inAppMessageViewLifecycleListener,
          configurationProvider,
          openingAnimation,
          closingAnimation,
          clickableInAppMessageView);
    }

    @Override
    public IInAppMessageViewWrapper createInAppMessageViewWrapper(View inAppMessageView,
                                                                  IInAppMessage inAppMessage,
                                                                  IInAppMessageViewLifecycleListener inAppMessageViewLifecycleListener,
                                                                  BrazeConfigurationProvider configurationProvider,
                                                                  Animation openingAnimation,
                                                                  Animation closingAnimation,
                                                                  View clickableInAppMessageView,
                                                                  List<View> buttons,
                                                                  View closeButton) {
      return new CordovaInAppMessageViewWrapper(inAppMessageView,
          inAppMessage,
          inAppMessageViewLifecycleListener,
          configurationProvider,
          openingAnimation,
          closingAnimation,
          clickableInAppMessageView,
          buttons,
          closeButton);
    }
  }
}
