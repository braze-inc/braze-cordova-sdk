package com.braze.cordova

import com.braze.models.FeatureFlag
import com.braze.support.BrazeLogger.Priority.E
import com.braze.support.BrazeLogger.brazelog
import org.json.JSONArray
import org.json.JSONException
import org.json.JSONObject

object FeatureFlagUtils {
    fun mapFeatureFlags(ffList: List<FeatureFlag>): JSONArray {
        val featureFlags = JSONArray()
        for (ff in ffList) {
            try {
                featureFlags.put(ff.forJsonPut())
            } catch (e: JSONException) {
                brazelog(E, e) { "Failed to map FeatureFlag to JSON. $ff" }
            }
        }
        return featureFlags
    }
}
