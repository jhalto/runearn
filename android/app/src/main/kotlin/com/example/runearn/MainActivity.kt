package com.jhaltolab.runearn

import android.app.Activity
import android.content.Intent
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private companion object {
        const val STORAGE_CHANNEL = "com.jhaltolab.runearn/file_storage"
        const val CREATE_BACKUP_DOCUMENT = 7301
    }

    private var pendingSaveResult: MethodChannel.Result? = null
    private var pendingContent: ByteArray? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            STORAGE_CHANNEL,
        ).setMethodCallHandler { call, result ->
            if (call.method != "saveExport") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            if (pendingSaveResult != null) {
                result.error("SAVE_IN_PROGRESS", "Another file is being saved.", null)
                return@setMethodCallHandler
            }

            val name = call.argument<String>("name")
            val mimeType = call.argument<String>("mimeType")
            val content = call.argument<String>("content")
            if (name.isNullOrBlank() || mimeType.isNullOrBlank() || content == null) {
                result.error("INVALID_EXPORT", "The export data is incomplete.", null)
                return@setMethodCallHandler
            }

            pendingSaveResult = result
            pendingContent = content.toByteArray(Charsets.UTF_8)
            try {
                startActivityForResult(
                    Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                        addCategory(Intent.CATEGORY_OPENABLE)
                        type = mimeType
                        putExtra(Intent.EXTRA_TITLE, name)
                    },
                    CREATE_BACKUP_DOCUMENT,
                )
            } catch (error: Exception) {
                clearPendingSave()
                result.error("SAVE_UNAVAILABLE", error.message, null)
            }
        }
    }

    @Deprecated("Deprecated in Android, retained for FlutterActivity compatibility")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != CREATE_BACKUP_DOCUMENT) return

        val result = pendingSaveResult
        val content = pendingContent
        if (result == null) {
            clearPendingSave()
            return
        }
        if (resultCode != Activity.RESULT_OK || data?.data == null) {
            clearPendingSave()
            result.success(false)
            return
        }

        try {
            contentResolver.openOutputStream(data.data!!, "w").use { output ->
                requireNotNull(output) { "The selected file could not be opened." }
                output.write(requireNotNull(content))
                output.flush()
            }
            clearPendingSave()
            result.success(true)
        } catch (error: Exception) {
            clearPendingSave()
            result.error("SAVE_FAILED", error.message, null)
        }
    }

    private fun clearPendingSave() {
        pendingSaveResult = null
        pendingContent = null
    }
}
