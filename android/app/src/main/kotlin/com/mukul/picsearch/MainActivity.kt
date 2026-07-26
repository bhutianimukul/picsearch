package com.mukul.picsearch

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

/** Hosts a "picsearch/share" channel so images shared *into* the app (from any
 *  other app's share sheet) reach Flutter as on-disk file paths — content:// URIs
 *  are copied into the cache first so ML Kit can read them. */
class MainActivity : FlutterFragmentActivity() {
    private val channelName = "picsearch/share"
    private var channel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
        channel!!.setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialShared" -> result.success(sharedPaths(intent))
                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val paths = sharedPaths(intent)
        if (paths.isNotEmpty()) channel?.invokeMethod("shared", paths)
    }

    private fun sharedPaths(intent: Intent?): List<String> {
        if (intent == null || intent.type?.startsWith("image/") != true) return emptyList()
        val uris: List<Uri> = when (intent.action) {
            Intent.ACTION_SEND -> listOfNotNull(uriExtra(intent))
            Intent.ACTION_SEND_MULTIPLE -> uriListExtra(intent)
            else -> emptyList()
        }
        return uris.mapNotNull(::copyToCache)
    }

    @Suppress("DEPRECATION")
    private fun uriExtra(intent: Intent): Uri? = intent.getParcelableExtra(Intent.EXTRA_STREAM)

    @Suppress("DEPRECATION")
    private fun uriListExtra(intent: Intent): List<Uri> =
        intent.getParcelableArrayListExtra<Uri>(Intent.EXTRA_STREAM) ?: emptyList()

    /** Copy a shared content:// image into the cache and return its file path. */
    private fun copyToCache(uri: Uri): String? = try {
        val dir = File(cacheDir, "shared").apply { mkdirs() }
        val file = File(dir, "share_${System.nanoTime()}.img")
        contentResolver.openInputStream(uri)?.use { input ->
            file.outputStream().use(input::copyTo)
        }
        if (file.length() > 0) file.absolutePath else null
    } catch (_: Exception) {
        null
    }
}
