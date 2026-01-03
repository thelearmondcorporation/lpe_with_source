package com.learmond.lpe_with_source

import android.app.Activity
import android.content.Context
import android.content.Intent
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

// Google Pay imports - ensure you add Play Services Wallet dependency in app if you enable this
import com.google.android.gms.wallet.PaymentsClient
import com.google.android.gms.wallet.Wallet
import com.google.android.gms.wallet.WalletConstants
import com.google.android.gms.wallet.PaymentDataRequest
import com.google.android.gms.wallet.PaymentData
import com.google.android.gms.wallet.AutoResolveHelper
import com.google.android.gms.common.api.ApiException

import org.json.JSONObject
import org.json.JSONArray
import java.util.Locale

class LearmondNativePayWithSourcePlugin: FlutterPlugin, MethodCallHandler, ActivityAware {
  private lateinit var channel : MethodChannel
  private var context: Context? = null
  private var activity: Activity? = null
  private var activityBinding: ActivityPluginBinding? = null
  private var pendingResult: Result? = null

  private val LOAD_PAYMENT_DATA_REQUEST_CODE = 991

  override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    context = binding.applicationContext
    channel = MethodChannel(binding.binaryMessenger, "lpe/native_pay")
    channel.setMethodCallHandler(this)
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
    context = null
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
    activityBinding = binding
    binding.addActivityResultListener { requestCode: Int, resultCode: Int, data: Intent? ->
      if (requestCode == LOAD_PAYMENT_DATA_REQUEST_CODE) {
        handleLoadPaymentDataResult(resultCode, data)
        return@addActivityResultListener true
      }
      return@addActivityResultListener false
    }
  }

  override fun onDetachedFromActivityForConfigChanges() {
    activity = null
    activityBinding = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activity = binding.activity
    activityBinding = binding
  }

  override fun onDetachedFromActivity() {
    activity = null
    activityBinding = null
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "presentNativePay" -> handlePresentNativePay(call, result)
      else -> result.notImplemented()
    }
  }

  private fun handlePresentNativePay(call: MethodCall, result: Result) {
    val args = call.arguments as? Map<*, *>
    if (args == null) {
      result.success(mapOf("success" to false, "error" to "invalid_args"))
      return
    }

    val method = args["method"] as? String ?: ""

    when (method) {
      "google_pay" -> presentGooglePay(args, result)
      else -> result.success(mapOf("success" to false, "error" to "unsupported_method"))
    }
  }

  private fun presentGooglePay(args: Map<*, *>, result: Result) {
    android.util.Log.d("LpeNativePay", "presentGooglePay args: $args")
    val ctx = context
    val act = activity
    if (ctx == null || act == null) {
      result.success(mapOf("success" to false, "error" to "no_activity"))
      return
    }

    val isProduction = args["isProduction"] as? Boolean ?: false
    val environment = if (isProduction) WalletConstants.ENVIRONMENT_PRODUCTION else WalletConstants.ENVIRONMENT_TEST
    val paymentsClient: PaymentsClient = Wallet.getPaymentsClient(ctx, Wallet.WalletOptions.Builder()
      .setEnvironment(environment)
      .build())

    try {
      val transactionInfo = JSONObject()
      val currency = (args["currency"] as? String)?.uppercase() ?: "USD"

      var merchantArgs = (args["merchantArgs"] as? Map<*, *>)?.toMutableMap() as MutableMap<Any?, Any?>?
      // If a top-level `totalPriceLabel` was provided, ensure it's present
      // in the merchantArgs map so downstream code that inspects
      // `merchantArgs["totalPriceLabel"]` will see it.
      val totalPriceLabelFromArgs = args["totalPriceLabel"] as? String ?: ""
      if (totalPriceLabelFromArgs.isNotEmpty()) {
        if (merchantArgs == null) merchantArgs = HashMap()
        merchantArgs["totalPriceLabel"] = totalPriceLabelFromArgs
      }

      val merchantNameArg = when {
        merchantArgs?.get("merchantName") is String -> merchantArgs["merchantName"] as String
        else -> (args["merchantName"] as? String) ?: ""
      }
      val merchantInfoArg = when {
        merchantArgs?.get("merchantInfo") is String -> merchantArgs["merchantInfo"] as String
        else -> (args["merchantInfo"] as? String) ?: ""
      }

      var totalCents = (args["amountCents"] as? Number)?.toInt() ?: 0
      var lastSummaryLabel: String = ""
      try {
        val suppliedSummary = (merchantArgs?.get("summaryItems") as? List<*>) ?: (args["summaryItems"] as? List<*>)
        if (suppliedSummary != null && suppliedSummary.isNotEmpty()) {
          var computed = 0
          for (item in suppliedSummary) {
            if (item is Map<*, *>) {
              val cents = (item["amountCents"] as? Number)?.toInt() ?: 0
              computed += cents
            }
          }
          if (computed > 0) totalCents = computed
          // If the last supplied summary item contains a label, prefer
          // that as the totalPriceLabel when rendering native pay sheets.
          try {
            val lastItem = suppliedSummary.last()
            if (lastItem is Map<*, *>) {
              lastSummaryLabel = (lastItem["label"] as? String) ?: ""
            }
          } catch (e: Exception) {
          }
        }
      } catch (e: Exception) {
      }

      val totalPrice = String.format(Locale.US, "%.2f", totalCents / 100.0)
      transactionInfo.put("totalPrice", totalPrice)
      transactionInfo.put("totalPriceStatus", "FINAL")
      transactionInfo.put("currencyCode", currency)

      var totalPriceLabelArg = when {
        merchantArgs?.get("totalPriceLabel") is String -> merchantArgs["totalPriceLabel"] as String
        else -> (args["totalPriceLabel"] as? String) ?: ""
      }
      // If the last summary item's label is present, use that as the
      // total price label (it commonly represents the total line).
      if (lastSummaryLabel.isNotEmpty()) {
        totalPriceLabelArg = lastSummaryLabel
      }
      val totalPriceLabelToUse = if (totalPriceLabelArg.isNotEmpty()) totalPriceLabelArg else if (merchantNameArg.isNotEmpty()) merchantNameArg else "Total"
      transactionInfo.put("totalPriceLabel", totalPriceLabelToUse)
      android.util.Log.d("LpeNativePay", "totalPriceLabel='$totalPriceLabelToUse' totalPrice=$totalPrice")

      try {
        val suppliedSummary = (merchantArgs?.get("summaryItems") as? List<*>) ?: (args["summaryItems"] as? List<*>)
        if (suppliedSummary != null && suppliedSummary.isNotEmpty()) {
          val displayItems = JSONArray()
          for (item in suppliedSummary) {
            if (item is Map<*, *>) {
              val label = (item["label"] as? String) ?: ""
              val cents = (item["amountCents"] as? Number)?.toInt() ?: 0
              val price = String.format(Locale.US, "%.2f", cents / 100.0)
              val di = JSONObject()
              di.put("label", label)
              di.put("type", "LINE_ITEM")
              di.put("price", price)
              displayItems.put(di)
            }
          }
          if (merchantInfoArg.isNotEmpty()) {
            val infoDi = JSONObject()
            infoDi.put("label", merchantInfoArg)
            infoDi.put("type", "LINE_ITEM")
            infoDi.put("price", String.format(Locale.US, "%.2f", 0.0))
            displayItems.put(infoDi)
          }
          val totalDi = JSONObject()
          totalDi.put("label", if (merchantNameArg.isNotEmpty()) merchantNameArg else "Source")
          totalDi.put("type", "LINE_ITEM")
          totalDi.put("price", totalPrice)
          displayItems.put(totalDi)

          android.util.Log.d("LpeNativePay", "displayItems=" + displayItems.toString())
          if (displayItems.length() > 0) {
            transactionInfo.put("totalPriceLabel", totalPriceLabelToUse)
            transactionInfo.put("displayItems", displayItems)
          }
        }
      } catch (e: Exception) {
      }

      val baseRequest = JSONObject()
      baseRequest.put("apiVersion", 2)
      baseRequest.put("apiVersionMinor", 0)

      if (merchantNameArg.isNotEmpty()) {
        val merchantInfo = JSONObject()
        merchantInfo.put("merchantName", merchantNameArg)
        baseRequest.put("merchantInfo", merchantInfo)
      }

      try {
        android.util.Log.d("LpeNativePay", "Computed totalPrice=$totalPrice, merchantName=$merchantNameArg")
      } catch (e: Exception) {
      }

      val cardPaymentMethod = JSONObject()
      cardPaymentMethod.put("type", "CARD")
      val parameters = JSONObject()
      parameters.put("allowedAuthMethods", JSONArray().put("PAN_ONLY").put("CRYPTOGRAM_3DS"))
      parameters.put("allowedCardNetworks", JSONArray().put("AMEX").put("DISCOVER").put("MASTERCARD").put("VISA"))
      cardPaymentMethod.put("parameters", parameters)

      val tokenizationSpec = JSONObject()
      val gateway = (args["gateway"] as? String)?.lowercase() ?: ""
      val apiKey = (args["apiKey"] as? String) ?: ""
      val gatewayMerchantId = (args["gatewayMerchantId"] as? String) ?: ""

      if (apiKey.isNotEmpty()) {
        tokenizationSpec.put("type", "PAYMENT_GATEWAY")
        val tokenParams = JSONObject()
        tokenParams.put("gateway", "stripe")
        tokenParams.put("stripe:apiKey", apiKey)
        tokenParams.put("stripe:version", "2020-08-27")
        if (gatewayMerchantId.isNotEmpty()) tokenParams.put("gatewayMerchantId", gatewayMerchantId)
        tokenizationSpec.put("parameters", tokenParams)
      } else if (gateway.isNotEmpty() && gateway != "example") {
        tokenizationSpec.put("type", "PAYMENT_GATEWAY")
        val tokenParams = JSONObject()
        tokenParams.put("gateway", gateway)
        if (gatewayMerchantId.isNotEmpty()) tokenParams.put("gatewayMerchantId", gatewayMerchantId)
        tokenizationSpec.put("parameters", tokenParams)
      } else {
        tokenizationSpec.put("type", "PAYMENT_GATEWAY")
        val tokenParams = JSONObject()
        tokenParams.put("gateway", "example")
        tokenParams.put("gatewayMerchantId", "exampleMerchantId")
        tokenizationSpec.put("parameters", tokenParams)
      }
      cardPaymentMethod.put("tokenizationSpecification", tokenizationSpec)

      val allowedPaymentMethods = JSONArray()
      allowedPaymentMethods.put(cardPaymentMethod)

      val paymentDataRequestJson = JSONObject(baseRequest.toString())
      paymentDataRequestJson.put("allowedPaymentMethods", allowedPaymentMethods)
      paymentDataRequestJson.put("transactionInfo", transactionInfo)

      val request = PaymentDataRequest.fromJson(paymentDataRequestJson.toString())

      pendingResult = result
      AutoResolveHelper.resolveTask(paymentsClient.loadPaymentData(request), act, LOAD_PAYMENT_DATA_REQUEST_CODE)
    } catch (e: Exception) {
      result.success(mapOf("success" to false, "error" to (e.message ?: "request_build_failed")))
    }
  }

  private fun handleLoadPaymentDataResult(resultCode: Int, data: Intent?) {
    val res = pendingResult ?: return
    try {
      when (resultCode) {
        Activity.RESULT_OK -> {
          val paymentData = data?.let { PaymentData.getFromIntent(it) }
          val paymentJson = paymentData?.toJson()
          if (paymentJson != null) {
            val jo = JSONObject(paymentJson)
            val token = jo.optJSONObject("paymentMethodData")
              ?.optJSONObject("tokenizationData")
              ?.optString("token") ?: ""
            val raw = mapOf("paymentToken" to token, "paymentDataJson" to paymentJson)
            res.success(mapOf("success" to true, "raw" to raw))
          } else {
            res.success(mapOf("success" to false, "error" to "empty_payment_data"))
          }
        }
        Activity.RESULT_CANCELED -> {
          res.success(mapOf("success" to false, "error" to "cancelled"))
        }
        else -> {
          val status = AutoResolveHelper.getStatusFromIntent(data)
          val code = status?.statusCode ?: -1
          res.success(mapOf("success" to false, "error" to "error", "raw" to mapOf("statusCode" to code)))
        }
      }
    } catch (e: ApiException) {
      res.success(mapOf("success" to false, "error" to e.message))
    } catch (e: Exception) {
      res.success(mapOf("success" to false, "error" to e.message))
    } finally {
      pendingResult = null
    }
  }
}
