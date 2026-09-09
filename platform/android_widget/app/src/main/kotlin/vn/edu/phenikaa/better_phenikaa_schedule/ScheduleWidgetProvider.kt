package vn.edu.phenikaa.better_phenikaa_schedule

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class ScheduleWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.schedule_widget)
            val subject = widgetData.getString("subjectName", "") ?: ""
            val room = widgetData.getString("room", "") ?: ""
            val time = widgetData.getString("time", "") ?: ""

            views.setTextViewText(
                R.id.widget_subject,
                subject.ifBlank { "Better Phenikaa App" },
            )
            views.setTextViewText(R.id.widget_room, room)
            views.setTextViewText(R.id.widget_time, time)
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
