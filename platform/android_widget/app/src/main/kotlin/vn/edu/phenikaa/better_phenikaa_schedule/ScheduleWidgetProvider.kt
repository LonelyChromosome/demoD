package vn.edu.phenikaa.better_phenikaa_schedule

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class ScheduleWidgetProvider : HomeWidgetProvider() {
    companion object {
        private const val ACTION_PREVIOUS =
            "vn.edu.phenikaa.better_phenikaa_schedule.WIDGET_PREVIOUS"
        private const val ACTION_NEXT =
            "vn.edu.phenikaa.better_phenikaa_schedule.WIDGET_NEXT"
        private const val EXTRA_WIDGET_ID = "widgetId"
        private const val EXTRA_INDEX = "index"
        private const val SNAPSHOT_PREFS = "FlutterSharedPreferences"
        private const val SNAPSHOT_KEY = "flutter.better_phenikaa_snapshot_v1"
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            render(context, appWidgetManager, widgetId, 0)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action != ACTION_PREVIOUS && intent.action != ACTION_NEXT) {
            return
        }

        val widgetId = intent.getIntExtra(EXTRA_WIDGET_ID, AppWidgetManager.INVALID_APPWIDGET_ID)
        if (widgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            return
        }

        val items = readUpcomingClasses(context)
        if (items.isEmpty()) {
            render(context, AppWidgetManager.getInstance(context), widgetId, 0)
            return
        }

        val current = intent.getIntExtra(EXTRA_INDEX, 0).coerceIn(items.indices)
        val nextIndex = if (intent.action == ACTION_NEXT) {
            (current + 1) % items.size
        } else {
            (current - 1 + items.size) % items.size
        }
        render(context, AppWidgetManager.getInstance(context), widgetId, nextIndex)
    }

    private fun render(
        context: Context,
        appWidgetManager: AppWidgetManager,
        widgetId: Int,
        requestedIndex: Int,
    ) {
        val views = RemoteViews(context.packageName, R.layout.schedule_widget)
        val items = readUpcomingClasses(context)
        val index = if (items.isEmpty()) 0 else requestedIndex.coerceIn(items.indices)
        val item = items.getOrNull(index)

        views.setTextViewText(
            R.id.widget_subject,
            item?.subject ?: "Không có lịch học sắp tới",
        )
        views.setTextViewText(R.id.widget_room, item?.room.orEmpty())
        views.setTextViewText(R.id.widget_time, item?.time.orEmpty())
        views.setTextViewText(
            R.id.widget_counter,
            if (items.size > 1) "${index + 1}/${items.size}" else "",
        )

        val navigationVisibility = if (items.size > 1) View.VISIBLE else View.INVISIBLE
        views.setViewVisibility(R.id.widget_previous, navigationVisibility)
        views.setViewVisibility(R.id.widget_next, navigationVisibility)

        views.setOnClickPendingIntent(
            R.id.widget_previous,
            navigationIntent(context, widgetId, index, ACTION_PREVIOUS),
        )
        views.setOnClickPendingIntent(
            R.id.widget_next,
            navigationIntent(context, widgetId, index, ACTION_NEXT),
        )

        context.packageManager.getLaunchIntentForPackage(context.packageName)?.let { launchIntent ->
            launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            val openApp = PendingIntent.getActivity(
                context,
                widgetId,
                launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            views.setOnClickPendingIntent(R.id.widget_content, openApp)
        }

        appWidgetManager.updateAppWidget(widgetId, views)
    }

    private fun navigationIntent(
        context: Context,
        widgetId: Int,
        index: Int,
        action: String,
    ): PendingIntent {
        val intent = Intent(context, ScheduleWidgetProvider::class.java).apply {
            this.action = action
            putExtra(EXTRA_WIDGET_ID, widgetId)
            putExtra(EXTRA_INDEX, index)
            data = Uri.parse("better-phenikaa://widget/$widgetId/$action/$index")
        }
        val requestCode = widgetId * 10 + if (action == ACTION_NEXT) 1 else 2
        return PendingIntent.getBroadcast(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun readUpcomingClasses(context: Context): List<WidgetClass> {
        val raw = context
            .getSharedPreferences(SNAPSHOT_PREFS, Context.MODE_PRIVATE)
            .getString(SNAPSHOT_KEY, null)
            ?: return emptyList()

        return try {
            val now = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", Locale.US).format(Date())
            val records = JSONObject(raw).optJSONArray("records") ?: return emptyList()
            val result = ArrayList<WidgetClass>(records.length())
            for (i in 0 until records.length()) {
                val record = records.optJSONObject(i) ?: continue
                if (record.optBoolean("isExam", false)) {
                    continue
                }
                val startAt = record.optString("startAt")
                val endAt = record.optString("endAt")
                if (startAt.length < 16 || endAt.length < 16) {
                    continue
                }
                val comparableEnd = endAt.take(19)
                if (comparableEnd < now) {
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
                result.add(
                    WidgetClass(
                        subject = record.optString("subjectName").ifBlank {
                            "Lịch học Phenikaa"
                        },
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
        val subject: String,
        val room: String,
        val time: String,
        val startAt: String,
    )
}
