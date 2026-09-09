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

        // Android StackView reserves 10% of both axes for its built-in perspective
        // effect. Because this widget rotates the StackView by 90 degrees to preserve
        // native horizontal swiping, that reserved area becomes a visible left/top
        // offset. Expand the collection by 1 / 0.9 and move the expanded surface so
        // the active 90% child exactly matches the visible widget bounds. Everything
        // is computed from dp and display density, so the same layout stays aligned on
        // HD, FHD and QHD screens instead of relying on device-specific pixels.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val stackVisualWidthDp = visualWidthDp / STACK_ACTIVE_FRACTION
            val stackVisualHeightDp = visualHeightDp / STACK_ACTIVE_FRACTION

            // The collection is rotated by +90 degrees in XML, so its unrotated
            // width/height are the visible height/width respectively.
            views.setViewLayoutWidth(
                R.id.widget_list,
                stackVisualHeightDp,
                TypedValue.COMPLEX_UNIT_DIP,
            )
            views.setViewLayoutHeight(
                R.id.widget_list,
                stackVisualWidthDp,
                TypedValue.COMPLEX_UNIT_DIP,
            )

            val density = context.resources.displayMetrics.density
            val translationXPx =
                ((stackVisualWidthDp - visualWidthDp) / 2f) * density
            val translationYPx =
                ((stackVisualHeightDp - visualHeightDp) / 2f) * density
            views.setFloat(R.id.widget_list, "setTranslationX", translationXPx)
            views.setFloat(R.id.widget_list, "setTranslationY", translationYPx)
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

        private const val STACK_ACTIVE_FRACTION = 0.9f
        private const val DEFAULT_WIDGET_WIDTH_DP = 250
        private const val DEFAULT_WIDGET_HEIGHT_DP = 64
        private const val MIN_WIDGET_WIDTH_DP = 220
        private const val MIN_WIDGET_HEIGHT_DP = 56
    }
}
