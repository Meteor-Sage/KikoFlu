package com.meteor.kikoeruflutter

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.provider.DocumentsContract
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.IOException
import java.util.ArrayDeque
import java.util.Locale
import java.util.UUID

class SubtitleDirectoryPicker(
    private val activity: Activity,
    messenger: BinaryMessenger
) : MethodChannel.MethodCallHandler {
    companion object {
        const val CHANNEL_NAME = "com.meteor.kikoeruflutter/subtitle_directory_picker"
        const val REQUEST_CODE = 0x5344
        private const val TEMP_DIRECTORY_PREFIX = "subtitle_import_"
    }

    private data class PendingRequest(
        val result: MethodChannel.Result,
        val allowedExtensions: Set<String>
    )

    private data class PendingDirectory(
        val uri: Uri,
        val destination: File
    )

    private data class CopyResult(
        val root: File,
        val selectedDirectory: File,
        val skippedCount: Int,
        val errorCount: Int
    )

    private val channel = MethodChannel(messenger, CHANNEL_NAME)
    private val temporaryRoots = mutableMapOf<String, File>()
    private var pendingRequest: PendingRequest? = null

    init {
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "pickDirectory" -> pickDirectory(call, result)
            "releaseDirectory" -> releaseDirectory(call, result)
            else -> result.notImplemented()
        }
    }

    private fun pickDirectory(call: MethodCall, result: MethodChannel.Result) {
        if (pendingRequest != null) {
            result.error("already_active", "A subtitle directory import is already active.", null)
            return
        }

        val allowedExtensions = call.argument<List<String>>("allowedExtensions")
            ?.map { it.trim().lowercase(Locale.ROOT).removePrefix(".") }
            ?.filter { it.isNotEmpty() }
            ?.toSet()
            .orEmpty()
        if (allowedExtensions.isEmpty()) {
            result.error("invalid_arguments", "No subtitle extensions were provided.", null)
            return
        }

        pendingRequest = PendingRequest(result, allowedExtensions)
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_GRANT_PREFIX_URI_PERMISSION)
        }

        try {
            activity.startActivityForResult(intent, REQUEST_CODE)
        } catch (error: Exception) {
            pendingRequest = null
            result.error("picker_unavailable", error.message, null)
        }
    }

    fun handleActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_CODE) return false

        val request = pendingRequest ?: return true
        val treeUri = data?.data
        if (resultCode != Activity.RESULT_OK || treeUri == null) {
            pendingRequest = null
            request.result.success(null)
            return true
        }

        Thread({
            try {
                val copyResult = copyTreeToCache(treeUri, request.allowedExtensions)
                val token = UUID.randomUUID().toString()
                activity.runOnUiThread {
                    temporaryRoots[token] = copyResult.root
                    pendingRequest = null
                    request.result.success(
                        mapOf(
                            "path" to copyResult.selectedDirectory.path,
                            "token" to token,
                            "skippedCount" to copyResult.skippedCount,
                            "errorCount" to copyResult.errorCount
                        )
                    )
                }
            } catch (error: Exception) {
                activity.runOnUiThread {
                    pendingRequest = null
                    request.result.error("directory_read_failed", error.message, null)
                }
            }
        }, "subtitle-directory-copy").start()

        return true
    }

    private fun releaseDirectory(call: MethodCall, result: MethodChannel.Result) {
        val token = call.argument<String>("token")
        if (token.isNullOrEmpty()) {
            result.error("invalid_arguments", "A temporary directory token is required.", null)
            return
        }

        val root = temporaryRoots.remove(token)
        if (root == null) {
            result.success(null)
            return
        }

        Thread({
            try {
                root.deleteRecursively()
                activity.runOnUiThread { result.success(null) }
            } catch (error: Exception) {
                activity.runOnUiThread {
                    result.error("cleanup_failed", error.message, null)
                }
            }
        }, "subtitle-directory-cleanup").start()
    }

    private fun copyTreeToCache(
        treeUri: Uri,
        allowedExtensions: Set<String>
    ): CopyResult {
        val tempRoot = File(activity.cacheDir, "$TEMP_DIRECTORY_PREFIX${UUID.randomUUID()}")
        if (!tempRoot.mkdirs()) {
            throw IOException("Unable to create the subtitle import cache directory.")
        }

        try {
            val rootDocumentId = DocumentsContract.getTreeDocumentId(treeUri)
            val rootDocumentUri =
                DocumentsContract.buildDocumentUriUsingTree(treeUri, rootDocumentId)
            val selectedName = queryDisplayName(rootDocumentUri)
                ?: rootDocumentId.substringAfterLast('/').substringAfterLast(':')
            val selectedDirectory = File(tempRoot, sanitizeName(selectedName))
            if (!selectedDirectory.mkdirs()) {
                throw IOException("Unable to create the selected subtitle directory cache.")
            }

            var skippedCount = 0
            var errorCount = 0
            val pendingDirectories = ArrayDeque<PendingDirectory>()
            pendingDirectories.add(PendingDirectory(rootDocumentUri, selectedDirectory))

            while (pendingDirectories.isNotEmpty()) {
                val pendingDirectory = pendingDirectories.removeFirst()
                val documentId = DocumentsContract.getDocumentId(pendingDirectory.uri)
                val childrenUri = DocumentsContract.buildChildDocumentsUriUsingTree(
                    pendingDirectory.uri,
                    documentId
                )

                activity.contentResolver.query(
                    childrenUri,
                    arrayOf(
                        DocumentsContract.Document.COLUMN_DOCUMENT_ID,
                        DocumentsContract.Document.COLUMN_DISPLAY_NAME,
                        DocumentsContract.Document.COLUMN_MIME_TYPE
                    ),
                    null,
                    null,
                    null
                )?.use { cursor ->
                    val idColumn = cursor.getColumnIndexOrThrow(
                        DocumentsContract.Document.COLUMN_DOCUMENT_ID
                    )
                    val nameColumn = cursor.getColumnIndexOrThrow(
                        DocumentsContract.Document.COLUMN_DISPLAY_NAME
                    )
                    val mimeTypeColumn = cursor.getColumnIndexOrThrow(
                        DocumentsContract.Document.COLUMN_MIME_TYPE
                    )

                    while (cursor.moveToNext()) {
                        val childId = cursor.getString(idColumn)
                        val childName = cursor.getString(nameColumn) ?: childId.substringAfterLast('/')
                        val mimeType = cursor.getString(mimeTypeColumn)
                        val childUri = DocumentsContract.buildDocumentUriUsingTree(
                            pendingDirectory.uri,
                            childId
                        )
                        val destination = File(
                            pendingDirectory.destination,
                            sanitizeName(childName)
                        )

                        if (mimeType == DocumentsContract.Document.MIME_TYPE_DIR) {
                            if (!destination.exists() && !destination.mkdirs()) {
                                throw IOException("Unable to create directory: $childName")
                            }
                            pendingDirectories.add(PendingDirectory(childUri, destination))
                            continue
                        }

                        val extension = childName.substringAfterLast('.', "")
                            .lowercase(Locale.ROOT)
                        if (extension !in allowedExtensions) {
                            skippedCount++
                            continue
                        }

                        try {
                            val input = activity.contentResolver.openInputStream(childUri)
                                ?: throw IOException("Unable to open: $childName")
                            input.use { source ->
                                destination.outputStream().use { target ->
                                    source.copyTo(target)
                                }
                            }
                        } catch (error: Exception) {
                            destination.delete()
                            errorCount++
                        }
                    }
                } ?: throw IOException("Unable to read the selected directory.")
            }

            return CopyResult(
                root = tempRoot,
                selectedDirectory = selectedDirectory,
                skippedCount = skippedCount,
                errorCount = errorCount
            )
        } catch (error: Exception) {
            tempRoot.deleteRecursively()
            throw error
        }
    }

    private fun queryDisplayName(uri: Uri): String? {
        return try {
            activity.contentResolver.query(
                uri,
                arrayOf(DocumentsContract.Document.COLUMN_DISPLAY_NAME),
                null,
                null,
                null
            )?.use { cursor ->
                if (!cursor.moveToFirst()) return@use null
                val column = cursor.getColumnIndex(
                    DocumentsContract.Document.COLUMN_DISPLAY_NAME
                )
                if (column < 0) null else cursor.getString(column)
            }
        } catch (error: Exception) {
            null
        }
    }

    private fun sanitizeName(name: String): String {
        val sanitized = name.map { character ->
            if (character == '/' || character == '\\' || character == '\u0000') {
                '_'
            } else {
                character
            }
        }.joinToString("").trim()
        return if (sanitized.isEmpty() || sanitized == "." || sanitized == "..") {
            "selected_folder"
        } else {
            sanitized
        }
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        pendingRequest = null
    }
}
