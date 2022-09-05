package com.appboy.cordova;

import android.util.Log;

import com.appboy.models.cards.BannerImageCard;
import com.appboy.models.cards.CaptionedImageCard;
import com.appboy.models.cards.Card;
import com.appboy.models.cards.ShortNewsCard;
import com.appboy.models.cards.TextAnnouncementCard;
import com.braze.support.BrazeLogger;
import com.braze.support.StringUtils;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.List;

public class ContentCardUtils {
  private static final String TAG = BrazeLogger.getBrazeLogTag(ContentCardUtils.class);

  /**
   * @return The card in the list with a matching id or null if not found.
   */
  public static Card getCardById(List<Card> cards, String id) {
    if (StringUtils.isNullOrEmpty(id)) {
      Log.w(TAG, "Cannot get card by null or empty card id. Returning null.");
      return null;
    }

    if (cards == null || cards.isEmpty()) {
      Log.w(TAG, "Cannot find card in null or empty card list. Returning null.");
      return null;
    }

    for (Card card : cards) {
      if (card.getId().equals(id)) {
        return card;
      }
    }

    Log.w(TAG, "Failed to find card by id " + id + " in list of cards: " + cards + "\nReturning null.");
    return null;
  }

  public static JSONArray mapContentCards(List<Card> cardsList) {
    JSONArray cards = new JSONArray();
    for (Card card : cardsList) {
      try {
        cards.put(mapContentCardFields(card));
      } catch (JSONException e) {
        BrazeLogger.e(TAG, "Failed to map content card fields to JSON. Card: " + card, e);
      }
    }
    return cards;
  }

  private static JSONObject mapContentCardFields(Card card) throws JSONException {
    JSONObject mappedCardJson = new JSONObject();
    mappedCardJson.put("id", card.getId());
    mappedCardJson.put("created", card.getCreated());
    mappedCardJson.put("expiresAt", card.getExpiresAt());
    mappedCardJson.put("viewed", card.getViewed());
    mappedCardJson.put("clicked", card.isClicked());
    mappedCardJson.put("pinned", card.isPinned());
    mappedCardJson.put("dismissed", card.isDismissed());
    mappedCardJson.put("dismissible", card.isDismissibleByUser());
    mappedCardJson.put("url", card.getUrl());
    mappedCardJson.put("openURLInWebView", card.getOpenUriInWebView());
    mappedCardJson.put("extras", new JSONObject(card.getExtras()));

    // Map the card specific fields
    switch (card.getCardType()) {
      case BANNER:
        mapBannerImageCardFields(mappedCardJson, (BannerImageCard) card);
        break;
      case CAPTIONED_IMAGE:
        mapCaptionedImageCardFields(mappedCardJson, (CaptionedImageCard) card);
        break;
      case SHORT_NEWS:
        mapShortNewsCardFields(mappedCardJson, (ShortNewsCard) card);
        break;
      case TEXT_ANNOUNCEMENT:
        mapTextAnnouncementCardFields(mappedCardJson, (TextAnnouncementCard) card);
        break;
      default:
        break;
    }

    return mappedCardJson;
  }

  private static void mapCaptionedImageCardFields(JSONObject mappedCard, CaptionedImageCard card) throws JSONException {
    mappedCard.put("image", card.getImageUrl());
    mappedCard.put("imageAspectRatio", card.getAspectRatio());
    mappedCard.put("title", card.getTitle());
    mappedCard.put("cardDescription", card.getDescription());
    mappedCard.put("domain", card.getDomain());
    mappedCard.put("type", "Captioned");
  }

  private static void mapShortNewsCardFields(JSONObject mappedCard, ShortNewsCard card) throws JSONException {
    mappedCard.put("image", card.getImageUrl());
    mappedCard.put("title", card.getTitle());
    mappedCard.put("cardDescription", card.getDescription());
    mappedCard.put("domain", card.getDomain());
    mappedCard.put("type", "Classic");
  }

  private static void mapTextAnnouncementCardFields(JSONObject mappedCard, TextAnnouncementCard card) throws JSONException {
    mappedCard.put("title", card.getTitle());
    mappedCard.put("cardDescription", card.getDescription());
    mappedCard.put("domain", card.getDomain());
    mappedCard.put("type", "Classic");
  }

  private static void mapBannerImageCardFields(JSONObject mappedCard, BannerImageCard card) throws JSONException {
    mappedCard.put("image", card.getImageUrl());
    mappedCard.put("imageAspectRatio", card.getAspectRatio());
    mappedCard.put("domain", card.getDomain());
    mappedCard.put("type", "Banner");
  }
}
