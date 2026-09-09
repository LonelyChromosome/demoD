package vn.edu.phenikaa.better_phenikaa_schedule

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.os.Build
import android.util.TypedValue
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
            renderWidget(context, appWidgetManager, widgetId)
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: android.os.Bundle,
    ) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        renderWidget(context, appWidgetManager, appWidgetId)
    }

    private fun renderWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        widgetId: Int,
    ) {
        val options = appWidgetManager.getAppWidgetOptions(widgetId)
        val visualWidthDp = options
            .getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, DEFAULT_WIDGET_WIDTH_DP)
            .coerceAtLeast(MIN_WIDGET_WIDTH_DP)
        val visualHeightDp = options
            .getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, DEFAULT_WIDGET_HEIGHT_DP)
            .coerceAtLeast(MIN_WIDGET_HEIGHT_DP)

        val views = RemoteViews(context.packageName, R.layout.schedule_widget)

        // The collection scrolls vertically in its own coordinates and is rotated
        // by 90 degrees in XML. Swapping its measured width/height makes the
        // transformed touch surface cover the entire visible widget.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            views.setViewLayoutWidth(
                R.id.widget_list,
                visualHeightDp.toFloat(),
                TypedValue.COMPLEX_UNIT_DIP,
            )
            views.setViewLayoutHeight(
                R.id.widget_list,
                visualWidthDp.toFloat(),
                TypedValue.COMPLEX_UNIT_DIP,
            )
        }

        val serviceIntent = Intent(context, ScheduleWidgetService::class.java).apply {
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
            putExtra(EXTRA_RENDER_WIDTH_DP, visualWidthDp)
            putExtra(EXTRA_RENDER_HEIGHT_DP, visualHeightDp)
            data = Uri.parse(
                "better-phenikaa://widget/$widgetId/${visualWidthDp}x$visualHeightDp",
            )
        }
        views.setRemoteAdapter(R.id.widget_list, serviceIntent)
        views.setEmptyView(R.id.widget_list, R.id.widget_empty)

        context.packageManager.getLaunchIntentForPackage(context.packageName)?.let { launchIntent ->
            launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            val openApp = PendingIntent.getActivity(
                context,
                widgetId,
                launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE,
            )
            views.setPendingIntentTemplate(R.id.widget_list, openApp)
            views.setOnClickPendingIntent(R.id.widget_empty, openApp)
        }

        appWidgetManager.updateAppWidget(widgetId, views)
        appWidgetManager.notifyAppWidgetViewDataChanged(widgetId, R.id.widget_list)
    }

    companion object {
        const val EXTRA_RENDER_WIDTH_DP = "renderWidthDp"
        const val EXTRA_RENDER_HEIGHT_DP = "renderHeightDp"

        private const val DEFAULT_WIDGET_WIDTH_DP = 250
        private const val DEFAULT_WIDGET_HEIGHT_DP = 64
        private const val MIN_WIDGET_WIDTH_DP = 220
        private const val MIN_WIDGET_HEIGHT_DP = 56
    }
}
