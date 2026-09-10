package vn.edu.phenikaa.better_phenikaa_schedule

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.util.SizeF
import android.util.TypedValue
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import java.util.Locale
import kotlin.math.roundToInt

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
        newOptions: Bundle,
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

        val views = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val exactSizes = exactWidgetSizes(options)
            if (exactSizes.isNotEmpty()) {
                val sizedViews = LinkedHashMap<SizeF, RemoteViews>()
                exactSizes.take(MAX_EXACT_LAYOUTS).forEach { size ->
                    sizedViews[size] = buildWidgetViews(
                        context = context,
                        widgetId = widgetId,
                        visualWidthDp = size.width,
                        visualHeightDp = size.height,
                    )
                }
                RemoteViews(sizedViews)
            } else {
                val fallback = legacyWidgetSize(options)
                buildWidgetViews(
                    context = context,
                    widgetId = widgetId,
                    visualWidthDp = fallback.width,
                    visualHeightDp = fallback.height,
                )
            }
        } else {
            val fallback = legacyWidgetSize(options)
            buildWidgetViews(
                context = context,
                widgetId = widgetId,
                visualWidthDp = fallback.width,
                visualHeightDp = fallback.height,
            )
        }

        appWidgetManager.updateAppWidget(widgetId, views)
        appWidgetManager.notifyAppWidgetViewDataChanged(widgetId, R.id.widget_list)
    }

    private fun buildWidgetViews(
        context: Context,
        widgetId: Int,
        visualWidthDp: Float,
        visualHeightDp: Float,
    ): RemoteViews {
        val widthDp = visualWidthDp.coerceAtLeast(1f)
        val heightDp = visualHeightDp.coerceAtLeast(1f)
        val renderWidthDp = widthDp.roundToInt().coerceAtLeast(1)
        val renderHeightDp = heightDp.roundToInt().coerceAtLeast(1)
        val views = RemoteViews(context.packageName, R.layout.schedule_widget)

        // StackView keeps a small perspective/depth inset around its active child.
        // Compensate from the exact host-provided size rather than from a fixed grid
        // assumption, so the visible card still fills the widget on different launchers.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val stackVisualWidthDp = widthDp / STACK_ACTIVE_FRACTION
            val stackVisualHeightDp = heightDp / STACK_ACTIVE_FRACTION

            views.setViewLayoutWidth(
                R.id.widget_list,
                stackVisualWidthDp,
                TypedValue.COMPLEX_UNIT_DIP,
            )
            views.setViewLayoutHeight(
                R.id.widget_list,
                stackVisualHeightDp,
                TypedValue.COMPLEX_UNIT_DIP,
            )

            val density = context.resources.displayMetrics.density
            val translationXPx = ((stackVisualWidthDp - widthDp) / 2f) * density
            val translationYPx = ((stackVisualHeightDp - heightDp) / 2f) * density
            views.setFloat(R.id.widget_list, "setTranslationX", translationXPx)
            views.setFloat(R.id.widget_list, "setTranslationY", translationYPx)

            val calendarSizeDp = (heightDp * CALENDAR_HEIGHT_FRACTION)
                .coerceIn(MIN_CALENDAR_SIZE_DP, MAX_CALENDAR_SIZE_DP)
            views.setViewLayoutWidth(
                R.id.widget_calendar,
                calendarSizeDp,
                TypedValue.COMPLEX_UNIT_DIP,
            )
            views.setViewLayoutHeight(
                R.id.widget_calendar,
                calendarSizeDp,
                TypedValue.COMPLEX_UNIT_DIP,
            )
        }

        val sizeToken = String.format(
            Locale.US,
            "%.1fx%.1f",
            widthDp,
            heightDp,
        )
        val serviceIntent = Intent(context, ScheduleWidgetService::class.java).apply {
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
            putExtra(EXTRA_RENDER_WIDTH_DP, renderWidthDp)
            putExtra(EXTRA_RENDER_HEIGHT_DP, renderHeightDp)
            data = Uri.parse("better-phenikaa://widget/$widgetId/$sizeToken")
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

        val chooseDateIntent = Intent(context, WidgetDatePickerActivity::class.java).apply {
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
            data = Uri.parse("better-phenikaa://widget/$widgetId/date-picker")
        }
        val chooseDate = PendingIntent.getActivity(
            context,
            DATE_PICKER_REQUEST_CODE_BASE + widgetId,
            chooseDateIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        views.setOnClickPendingIntent(R.id.widget_calendar, chooseDate)

        // The selected day (today by default) remains the first item whenever the
        // provider refreshes. Ordinary StackView swipes continue to loop normally.
        views.setDisplayedChild(R.id.widget_list, 0)
        return views
    }

    @Suppress("DEPRECATION")
    private fun exactWidgetSizes(options: Bundle): List<SizeF> {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) {
            return emptyList()
        }
        return options
            .getParcelableArrayList<SizeF>(AppWidgetManager.OPTION_APPWIDGET_SIZES)
            .orEmpty()
            .filter { it.width > 0f && it.height > 0f }
            .distinctBy { size ->
                "${(size.width * 10f).roundToInt()}x${(size.height * 10f).roundToInt()}"
            }
    }

    private fun legacyWidgetSize(options: Bundle): SizeF {
        val minWidth = options
            .getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, DEFAULT_WIDGET_WIDTH_DP)
            .takeIf { it > 0 }
            ?: DEFAULT_WIDGET_WIDTH_DP
        val maxWidth = options
            .getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_WIDTH, minWidth)
            .takeIf { it > 0 }
            ?: minWidth
        val minHeight = options
            .getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, DEFAULT_WIDGET_HEIGHT_DP)
            .takeIf { it > 0 }
            ?: DEFAULT_WIDGET_HEIGHT_DP
        val maxHeight = options
            .getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, minHeight)
            .takeIf { it > 0 }
            ?: minHeight

        // For a one-row horizontal widget, use the widest host bound and the shortest
        // valid height. This is only a fallback for launchers that do not publish the
        // Android 12 exact size list.
        return SizeF(
            maxOf(minWidth, maxWidth).toFloat(),
            minOf(minHeight, maxHeight).toFloat(),
        )
    }

    companion object {
        const val EXTRA_RENDER_WIDTH_DP = "renderWidthDp"
        const val EXTRA_RENDER_HEIGHT_DP = "renderHeightDp"
        const val WIDGET_SELECTION_PREFS = "better_phenikaa_widget_selection"

        fun selectedDateKey(widgetId: Int): String = "selected_date_$widgetId"

        private const val DATE_PICKER_REQUEST_CODE_BASE = 100_000
        private const val MAX_EXACT_LAYOUTS = 16
        private const val STACK_ACTIVE_FRACTION = 0.9f
        private const val CALENDAR_HEIGHT_FRACTION = 0.56f
        private const val MIN_CALENDAR_SIZE_DP = 28f
        private const val MAX_CALENDAR_SIZE_DP = 42f
        private const val DEFAULT_WIDGET_WIDTH_DP = 250
        private const val DEFAULT_WIDGET_HEIGHT_DP = 64
    }
}
