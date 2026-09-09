package vn.edu.phenikaa.better_phenikaa_schedule

import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.LinearGradient
import android.graphics.Matrix
import android.graphics.Paint
import android.graphics.RectF
import android.graphics.Shader
import android.graphics.Typeface
import android.text.TextPaint
import android.text.TextUtils
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class ScheduleWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory =
        ScheduleWidgetFactory(applicationContext)
}

private class ScheduleWidgetFactory(
    private val context: Context,
) : RemoteViewsService.RemoteViewsFactory {
    private var items: List<WidgetClass> = emptyList()

    override fun onCreate() {
        reload()
    }

    override fun onDataSetChanged() {
        reload()
    }

    override fun onDestroy() {
        items = emptyList()
    }

    override fun getCount(): Int = items.size

    override fun getViewAt(position: Int): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.schedule_widget_item)
        val item = items.getOrNull(position) ?: return views
        views.setImageViewBitmap(
            R.id.widget_slide_image,
            renderSlide(item, position, items.size),
        )
        views.setOnClickFillInIntent(
            R.id.widget_slide_item,
            Intent().apply {
                putExtra("scheduleRecordId", item.id)
            },
        )
        return views
    }

    override fun getLoadingView(): RemoteViews? = null

    override fun getViewTypeCount(): Int = 1

    override fun getItemId(position: Int): Long =
        items.getOrNull(position)?.stableId ?: position.toLong()

    override fun hasStableIds(): Boolean = true

    private fun reload() {
        items = readUpcomingClasses(context)
    }

    private fun renderSlide(
        item: WidgetClass,
        position: Int,
        count: Int,
    ): Bitmap {
        val density = context.resources.displayMetrics.density
        val scaledDensity = context.resources.displayMetrics.scaledDensity
        val width = (320f * density).toInt().coerceAtLeast(1)
        val height = (88f * density).toInt().coerceAtLeast(1)
        val horizontal = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(horizontal)

        // Each StackView card must be visually opaque. Transparent cards expose
        // the neighbouring stacked views underneath and make all subjects look
        // superimposed, especially on Samsung launchers.
        val backgroundPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            shader = LinearGradient(
                0f,
                0f,
                width.toFloat(),
                0f,
                intArrayOf(0xFF1746A2.toInt(), 0xFF3567C8.toInt()),
                null,
                Shader.TileMode.CLAMP,
            )
        }
        val radius = 22f * density
        canvas.drawRoundRect(
            RectF(0f, 0f, width.toFloat(), height.toFloat()),
            radius,
            radius,
            backgroundPaint,
        )

        val left = 20f * density
        val right = width - 20f * density
        val subjectPaint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
            color = 0xFFFFFFFF.toInt()
            textSize = 15f * scaledDensity
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
        }
        val detailPaint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
            color = 0xFFDDE8FF.toInt()
            textSize = 11f * scaledDensity
        }
        val counterPaint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
            color = 0xFFBFD0F5.toInt()
            textSize = 9f * scaledDensity
            textAlign = Paint.Align.RIGHT
        }

        val counter = if (count > 1) "${position + 1}/$count" else ""
        val counterWidth = if (counter.isEmpty()) 0f else counterPaint.measureText(counter) + 10f * density
        val subject = TextUtils.ellipsize(
            item.subject,
            subjectPaint,
            (right - left - counterWidth).coerceAtLeast(24f * density),
            TextUtils.TruncateAt.END,
        )
        canvas.drawText(subject.toString(), left, 34f * density, subjectPaint)
        if (counter.isNotEmpty()) {
            canvas.drawText(counter, right, 29f * density, counterPaint)
        }

        val timeWidth = detailPaint.measureText(item.time)
        val roomMaxWidth = (right - left - timeWidth - 14f * density).coerceAtLeast(24f * density)
        val room = TextUtils.ellipsize(
            item.room,
            detailPaint,
            roomMaxWidth,
            TextUtils.TruncateAt.END,
        )
        canvas.drawText(room.toString(), left, 61f * density, detailPaint)
        canvas.drawText(item.time, right - timeWidth, 61f * density, detailPaint)

        val matrix = Matrix().apply { postRotate(-90f) }
        val rotated = Bitmap.createBitmap(
            horizontal,
            0,
            0,
            horizontal.width,
            horizontal.height,
            matrix,
            true,
        )
        if (rotated !== horizontal) {
            horizontal.recycle()
        }
        return rotated
    }
}

private fun readUpcomingClasses(context: Context): List<WidgetClass> {
    val raw = context
        .getSharedPreferences(SNAPSHOT_PREFS, Context.MODE_PRIVATE)
        .getString(SNAPSHOT_KEY, null)
        ?: return emptyList()

    return try {
        val now = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", Locale.US).format(Date())
        val records = JSONObject(raw).optJSONArray("records") ?: return emptyList()
        val result = ArrayList<WidgetClass>(records.length().coerceAtMost(MAX_WIDGET_ITEMS))
        for (i in 0 until records.length()) {
            if (result.size >= MAX_WIDGET_ITEMS) {
                break
            }
            val record = records.optJSONObject(i) ?: continue
            if (record.optBoolean("isExam", false)) {
                continue
            }
            val startAt = record.optString("startAt")
            val endAt = record.optString("endAt")
            if (startAt.length < 16 || endAt.length < 16) {
                continue
            }
            if (endAt.take(19) < now) {
                continue
            }

            val room = record.optString("room")
            val date = if (startAt.length >= 10) {
                "${startAt.substring(8, 10)}/${startAt.substring(5, 7)}"
            } else {
                ""
            }
            val roomAndDate = listOf(room, date)
                .filter { it.isNotBlank() }
                .joinToString(" • ")
            val startTime = startAt.substring(11, 16)
            val endTime = if (endAt.length >= 16) endAt.substring(11, 16) else ""
            val subject = record.optString("subjectName").ifBlank { "Lịch học Phenikaa" }
            val id = record.optString("id").ifBlank { "$startAt|$subject|$room" }
            result.add(
                WidgetClass(
                    id = id,
                    subject = subject,
                    room = roomAndDate,
                    time = if (endTime.isBlank()) startTime else "$startTime - $endTime",
                    startAt = startAt,
                ),
            )
        }
        result.sortBy { it.startAt }
        result
    } catch (_: Exception) {
        emptyList()
    }
}

private data class WidgetClass(
    val id: String,
    val subject: String,
    val room: String,
    val time: String,
    val startAt: String,
) {
    val stableId: Long
        get() = id.hashCode().toLong()
}

private const val SNAPSHOT_PREFS = "FlutterSharedPreferences"
private const val SNAPSHOT_KEY = "flutter.better_phenikaa_snapshot_v1"
private const val MAX_WIDGET_ITEMS = 40
