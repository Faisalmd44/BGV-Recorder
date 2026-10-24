package com.example.background_video_recorder

import android.content.ContentUris
import android.content.ContentValues
import android.content.Intent
import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaMetadataRetriever
import android.media.MediaMuxer
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream
import java.nio.ByteBuffer
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class MainActivity : FlutterActivity() {
    private val CHANNEL = "bvr/channel"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startService" -> {
                    val facing = call.argument<String>("cameraFacing") ?: "back"
                    val quality = call.argument<Int>("quality") ?: 1080
                    val intent = Intent(this, ForegroundVideoService::class.java).apply {
                        action = ForegroundVideoService.ACTION_START
                        putExtra(ForegroundVideoService.EXTRA_CAMERA_FACING, facing)
                        putExtra(ForegroundVideoService.EXTRA_QUALITY, quality)
                    }
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) startForegroundService(intent) else startService(intent)
                    result.success(null)
                }
                "stopService" -> {
                    val intent = Intent(this, ForegroundVideoService::class.java).apply { action = ForegroundVideoService.ACTION_STOP }
                    startService(intent)
                    result.success(null)
                }
                "listRecordings" -> {
                    result.success(listRecordings())
                }
                "deleteRecording" -> {
                    val uriStr = call.argument<String>("uri")
                    val path = call.argument<String>("path")
                    val ok = deleteRecording(uriStr, path)
                    result.success(ok)
                }
                "trimVideo" -> {
                    val uriStr = call.argument<String>("uri")
                    val path = call.argument<String>("path")
                    val startMs = (call.argument<Number>("startMs")?.toLong()) ?: 0L
                    val endMs = (call.argument<Number>("endMs")?.toLong()) ?: 0L
                    Thread {
                        try {
                            val savedName = trimVideoNative(uriStr, path, startMs, endMs)
                            runOnUiThread {
                                if (savedName != null) {
                                    result.success(savedName)
                                } else {
                                    result.error("TRIM_FAILED", "Could not trim video segment", null)
                                }
                            }
                        } catch (e: Exception) {
                            runOnUiThread {
                                result.error("TRIM_ERROR", e.message ?: "Unknown error", null)
                            }
                        }
                    }.start()
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun trimVideoNative(uriStr: String?, path: String?, startMs: Long, endMs: Long): String? {
        if (endMs <= startMs) return null

        val tempOut = File(cacheDir, "temp_trim_${System.currentTimeMillis()}.mp4")
        if (tempOut.exists()) tempOut.delete()

        val extractor = MediaExtractor()
        var rotationDegrees = 0

        try {
            if (!uriStr.isNullOrEmpty()) {
                val uri = Uri.parse(uriStr)
                contentResolver.openFileDescriptor(uri, "r")?.use { pfd ->
                    extractor.setDataSource(pfd.fileDescriptor)
                } ?: return null

                try {
                    val retriever = MediaMetadataRetriever()
                    retriever.setDataSource(this, uri)
                    rotationDegrees = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_ROTATION)?.toIntOrNull() ?: 0
                    retriever.release()
                } catch (_: Exception) {}
            } else if (!path.isNullOrEmpty()) {
                extractor.setDataSource(path)
                try {
                    val retriever = MediaMetadataRetriever()
                    retriever.setDataSource(path)
                    rotationDegrees = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_ROTATION)?.toIntOrNull() ?: 0
                    retriever.release()
                } catch (_: Exception) {}
            } else {
                return null
            }

            val trackCount = extractor.trackCount
            val muxer = MediaMuxer(tempOut.absolutePath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
            val indexMap = HashMap<Int, Int>(trackCount)
            var bufferSize = -1

            for (i in 0 until trackCount) {
                val format = extractor.getTrackFormat(i)
                val mime = format.getString(MediaFormat.KEY_MIME) ?: ""
                if (mime.startsWith("video/") || mime.startsWith("audio/")) {
                    extractor.selectTrack(i)
                    val dstIndex = muxer.addTrack(format)
                    indexMap[i] = dstIndex
                    if (format.containsKey(MediaFormat.KEY_MAX_INPUT_SIZE)) {
                        val maxSize = format.getInteger(MediaFormat.KEY_MAX_INPUT_SIZE)
                        if (maxSize > bufferSize) bufferSize = maxSize
                    }
                }
            }

            if (bufferSize <= 0) bufferSize = 1024 * 1024
            val dstBuf = ByteBuffer.allocate(bufferSize)
            val bufferInfo = MediaCodec.BufferInfo()

            if (rotationDegrees > 0) {
                muxer.setOrientationHint(rotationDegrees)
            }

            val startUs = startMs * 1000L
            val endUs = endMs * 1000L

            if (startUs > 0) {
                extractor.seekTo(startUs, MediaExtractor.SEEK_TO_PREVIOUS_SYNC)
            }

            muxer.start()
            var wroteSamples = false
            try {
                while (true) {
                    bufferInfo.offset = 0
                    bufferInfo.size = extractor.readSampleData(dstBuf, 0)
                    if (bufferInfo.size < 0) {
                        bufferInfo.size = 0
                        break
                    } else {
                        val sampleTimeUs = extractor.sampleTime
                        if (endUs > 0 && sampleTimeUs > endUs) {
                            break
                        }
                        if (sampleTimeUs >= startUs) {
                            val trackIndex = extractor.sampleTrackIndex
                            val dstTrack = indexMap[trackIndex]
                            if (dstTrack != null) {
                                bufferInfo.presentationTimeUs = sampleTimeUs - startUs
                                var flags = 0
                                if ((extractor.sampleFlags and MediaExtractor.SAMPLE_FLAG_SYNC) != 0) {
                                    flags = flags or MediaCodec.BUFFER_FLAG_KEY_FRAME
                                }
                                bufferInfo.flags = flags
                                muxer.writeSampleData(dstTrack, dstBuf, bufferInfo)
                                wroteSamples = true
                            }
                        }
                        extractor.advance()
                    }
                }
                if (wroteSamples) {
                    muxer.stop()
                }
            } finally {
                try { muxer.release() } catch (_: Exception) {}
            }

            if (!wroteSamples || !tempOut.exists() || tempOut.length() == 0L) {
                tempOut.delete()
                return null
            }

            val stamp = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.US).format(Date())
            val outFileName = "TRIM_$stamp.mp4"

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val values = ContentValues().apply {
                    put(MediaStore.Video.Media.DISPLAY_NAME, outFileName)
                    put(MediaStore.Video.Media.MIME_TYPE, "video/mp4")
                    put(MediaStore.Video.Media.RELATIVE_PATH, Environment.DIRECTORY_MOVIES + "/BackgroundVideoRecorder")
                    put(MediaStore.Video.Media.IS_PENDING, 1)
                }
                val collection = MediaStore.Video.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
                val itemUri = contentResolver.insert(collection, values) ?: return null

                contentResolver.openOutputStream(itemUri)?.use { outStream ->
                    FileInputStream(tempOut).use { inStream ->
                        inStream.copyTo(outStream)
                    }
                }

                values.clear()
                values.put(MediaStore.Video.Media.IS_PENDING, 0)
                contentResolver.update(itemUri, values, null, null)
                tempOut.delete()
                return outFileName
            } else {
                val dir = getExternalFilesDir(Environment.DIRECTORY_MOVIES)
                dir?.mkdirs()
                val finalFile = File(dir, outFileName)
                tempOut.copyTo(finalFile, overwrite = true)
                tempOut.delete()
                return outFileName
            }
        } finally {
            try { extractor.release() } catch (_: Exception) {}
        }
    }

    private fun listRecordings(): List<Map<String, Any?>> {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val out = mutableListOf<Map<String, Any?>>()
            val projection = arrayOf(
                MediaStore.Video.Media._ID,
                MediaStore.Video.Media.DISPLAY_NAME,
                MediaStore.Video.Media.DATE_ADDED,
                MediaStore.Video.Media.SIZE,
                MediaStore.Video.Media.RELATIVE_PATH
            )
            val selection = MediaStore.Video.Media.RELATIVE_PATH + " LIKE ?"
            val args = arrayOf("%BackgroundVideoRecorder%")
            val sortOrder = MediaStore.Video.Media.DATE_ADDED + " DESC"
            contentResolver.query(
                MediaStore.Video.Media.EXTERNAL_CONTENT_URI,
                projection,
                selection,
                args,
                sortOrder
            )?.use { cursor ->
                val idCol = cursor.getColumnIndexOrThrow(MediaStore.Video.Media._ID)
                val nameCol = cursor.getColumnIndexOrThrow(MediaStore.Video.Media.DISPLAY_NAME)
                val dateCol = cursor.getColumnIndexOrThrow(MediaStore.Video.Media.DATE_ADDED)
                val sizeCol = cursor.getColumnIndexOrThrow(MediaStore.Video.Media.SIZE)
                while (cursor.moveToNext()) {
                    val id = cursor.getLong(idCol)
                    val name = cursor.getString(nameCol)
                    val date = cursor.getLong(dateCol)
                    val size = cursor.getLong(sizeCol)
                    val uri: Uri = ContentUris.withAppendedId(MediaStore.Video.Media.EXTERNAL_CONTENT_URI, id)
                    out.add(mapOf(
                        "uri" to uri.toString(),
                        "path" to null,
                        "name" to name,
                        "date" to date,
                        "size" to size
                    ))
                }
            }
            out
        } else {
            val out = mutableListOf<Map<String, Any?>>()
            val dir = getExternalFilesDir(Environment.DIRECTORY_MOVIES)
            val files = dir?.listFiles { f -> f.isFile && f.name.endsWith(".mp4", true) }?.sortedByDescending { it.lastModified() }
            files?.forEach { file ->
                out.add(mapOf(
                    "uri" to null,
                    "path" to file.absolutePath,
                    "name" to file.name,
                    "date" to (file.lastModified() / 1000),
                    "size" to file.length()
                ))
            }
            out
        }
    }

    private fun deleteRecording(uriStr: String?, path: String?): Boolean {
        return try {
            if (uriStr != null) {
                val uri = Uri.parse(uriStr)
                contentResolver.delete(uri, null, null) > 0
            } else if (path != null) {
                val f = File(path)
                f.exists() && f.delete()
            } else {
                false
            }
        } catch (_: Exception) { false }
    }
}
