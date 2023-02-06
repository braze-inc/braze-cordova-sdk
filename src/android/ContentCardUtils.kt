package com.braze.cordova

import com.braze.enums.CardType.*
import com.braze.models.cards.*
import com.braze.support.BrazeLogger.Priority.E
import com.braze.support.BrazeLogger.brazelog
import org.json.JSONArray
import org.json.JSONException
import org.json.JSONObject

object ContentCardUtils {

    /**
     * @return The card in the list with a matching id or null if not found.
     */
    fun getCardById(cards: List<Card>?, id: String?): Card? =
        cards?.firstOrNull { it.id == id }

    fun mapContentCards(cardsList: List<Card>): JSONArray {
        val cards = JSONArray()
        for (card in cardsList) {
            try {
                cards.put(mapContentCardFields(card))
            } catch (e: JSONException) {
                brazelog(E, e) { "Failed to map content card fields to JSON. Card: $card" }
            }
        }
        return cards
    }

    private fun mapContentCardFields(card: Card): JSONObject {
        val mappedCardJson = JSONObject().apply {
            put("id", card.id)
            put("created", card.created)
            put("expiresAt", card.expiresAt)
            put("viewed", card.viewed)
            put("clicked", card.isClicked)
            put("pinned", card.isPinned)
            put("dismissed", card.isDismissed)
            put("dismissible", card.isDismissibleByUser)
            put("url", card.url)
            put("openURLInWebView", card.openUriInWebView)
            put("extras", JSONObject(card.extras))
        }
        when (card.cardType) {
            BANNER -> mapBannerImageCardFields(mappedCardJson, card as BannerImageCard)
            CAPTIONED_IMAGE -> mapCaptionedImageCardFields(mappedCardJson, card as CaptionedImageCard)
            SHORT_NEWS -> mapShortNewsCardFields(mappedCardJson, card as ShortNewsCard)
            TEXT_ANNOUNCEMENT -> mapTextAnnouncementCardFields(mappedCardJson, card as TextAnnouncementCard)
            else -> {}
        }
        return mappedCardJson
    }

    private fun mapCaptionedImageCardFields(mappedCard: JSONObject, card: CaptionedImageCard) {
        mappedCard.apply {
            put("image", card.imageUrl)
            put("imageAspectRatio", card.aspectRatio.toDouble())
            put("title", card.title)
            put("cardDescription", card.description)
            put("domain", card.domain)
            put("type", "Captioned")
        }
    }

    private fun mapShortNewsCardFields(mappedCard: JSONObject, card: ShortNewsCard) {
        mappedCard.apply {
            put("image", card.imageUrl)
            put("title", card.title)
            put("cardDescription", card.description)
            put("domain", card.domain)
            put("type", "Classic")
        }
    }

    private fun mapTextAnnouncementCardFields(mappedCard: JSONObject, card: TextAnnouncementCard) {
        mappedCard.apply {
            put("title", card.title)
            put("cardDescription", card.description)
            put("domain", card.domain)
            put("type", "Classic")
        }
    }

    private fun mapBannerImageCardFields(mappedCard: JSONObject, card: BannerImageCard) {
        mappedCard.apply {
            put("image", card.imageUrl)
            put("imageAspectRatio", card.aspectRatio.toDouble())
            put("domain", card.domain)
            put("type", "Banner")
        }
    }
}
