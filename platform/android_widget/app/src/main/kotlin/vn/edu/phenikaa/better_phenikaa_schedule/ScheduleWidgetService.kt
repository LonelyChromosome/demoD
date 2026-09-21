package vn.edu.phenikaa.better_phenikaa_schedule

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.RectF
import android.graphics.Shader
import android.graphics.Typeface
import android.os.Build
import android.text.TextPaint
import android.text.TextUtils
import android.util.TypedValue
import android.widget.RemoteViews
import android.widget.RemoteViewsService

class ScheduleWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory =
        ScheduleWidgetFactory(
            applicationContext,
            intent.getIntExtra(
                AppWidgetManager.EXTRA_APPWIDGET_ID,
                AppWidgetManager.INVALID_APPWIDGET_ID,
            ),
            intent.getIntExtra(
                ScheduleWidgetProvider.EXTRA_RENDER_WIDTH_DP,
                DEFAULT_WIDGET_WIDTH_DP,
            ),
            intent.getIntExtra(
                ScheduleWidgetProvider.EXTRA_RENDER_HEIGHT_DP,
                DEFAULT_WIDGET_HEIGHT_DP,
            ),
        )
}

private class ScheduleWidgetFactory(
    private val context: Context,
    private val widgetId: Int,
    private val renderWidthDp: Int,
    private val renderHeightDp: Int,
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
        val widthDp = renderWidthDp.coerceAtLeast(1)
        val heightDp = renderHeightDp.coerceAtLeast(1)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            views.setViewLayoutWidth(
                R.id.widget_slide_item,
                widthDp.toFloat(),
                TypedValue.COMPLEX_UNIT_DIP,
            )
            views.setViewLayoutHeight(
                R.id.widget_slide_item,
                heightDp.toFloat(),
                TypedValue.COMPLEX_UNIT_DIP,
            )
        }

        views.setImageViewBitmap(
            R.id.widget_slide_image,
            renderSlide(item),
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
        items = WidgetSnapshotStore.read(context, widgetId).items
    }

    private fun renderSlide(item: WidgetClass): Bitmap {
        val density = context.resources.displayMetrics.density
        val widthDp = renderWidthDp.coerceAtLeast(1)
        val heightDp = renderHeightDp.coerceAtLeast(1)
        val width = (widthDp * density).toInt().coerceAtLeast(1)
        val height = (heightDp * density).toInt().coerceAtLeast(1)
        val horizontal = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(horizontal)
        val widthPx = width.toFloat()
        val heightPx = height.toFloat()

        val backgroundPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            shader = LinearGradient(
                0f,
                0f,
                widthPx,
                0f,
                0xFF173A8E.toInt(),
                0xFF315AB5.toInt(),
                Shader.TileMode.CLAMP,
            )
        }
        val radius = heightPx * CORNER_RADIUS_HEIGHT_FRACTION
        canvas.drawRoundRect(
            RectF(0f, 0f, widthPx, heightPx),
            radius,
            radius,
            backgroundPaint,
        )

        // Every coordinate is proportional to the real frame supplied by the host.
        // Keep the visual spacing from the approved layout while leaving the far
        // lower-right edge clear for the StackView peek mask in schedule_widget.xml.
        val left = widthPx * CONTENT_LEFT_FRACTION
        val titleRight = widthPx * TITLE_RIGHT_FRACTION
        val detailRight = widthPx * DETAIL_RIGHT_FRACTION

        val subjectPaint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
            color = 0xFFFFFFFF.toInt()
            textSize = heightPx * SUBJECT_TEXT_HEIGHT_FRACTION
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
        }
        val detailPaint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
            color = 0xFFDDE8FF.toInt()
            textSize = heightPx * DETAIL_TEXT_HEIGHT_FRACTION
        }

        val titleMaxWidth = (titleRight - left).coerceAtLeast(
            widthPx * MIN_TITLE_WIDTH_FRACTION,
        )
        val naturalTitleWidth = subjectPaint.measureText(item.subject)
        if (naturalTitleWidth > titleMaxWidth && naturalTitleWidth > 0f) {
            val fitScale = (titleMaxWidth / naturalTitleWidth)
                .coerceAtLeast(MIN_SUBJECT_FIT_SCALE)
            subjectPaint.textSize *= fitScale
        }
        val subject = TextUtils.ellipsize(
            item.subject,
            subjectPaint,
            titleMaxWidth,
            TextUtils.TruncateAt.END,
        )
        canvas.drawText(
            subject.toString(),
            left,
            heightPx * SUBJECT_BASELINE_HEIGHT_FRACTION,
            subjectPaint,
        )

        val timeWidth = detailPaint.measureText(item.time)
        val roomMaxWidth = (
            detailRight - left - timeWidth - widthPx * DETAIL_GAP_WIDTH_FRACTION
        ).coerceAtLeast(widthPx * MIN_DETAIL_WIDTH_FRACTION)
        val room = TextUtils.ellipsize(
            item.room,
            detailPaint,
            roomMaxWidth,
            TextUtils.TruncateAt.END,
        )
        canvas.drawText(
            room.toString(),
            left,
            heightPx * DETAIL_BASELINE_HEIGHT_FRACTION,
            detailPaint,
        )
        if (item.time.isNotBlank()) {
            canvas.drawText(
                item.time,
                detailRight - timeWidth,
                heightPx * DETAIL_BASELINE_HEIGHT_FRACTION,
                detailPaint,
            )
        }

        return horizontal
    }
}

private const val DEFAULT_WIDGET_WIDTH_DP = 320
private const val DEFAULT_WIDGET_HEIGHT_DP = 64

private const val CORNER_RADIUS_HEIGHT_FRACTION = 0.28f
private const val CONTENT_LEFT_FRACTION = 0.095f
private const val TITLE_RIGHT_FRACTION = 0.86f
private const val DETAIL_RIGHT_FRACTION = 0.86f
private const val SUBJECT_TEXT_HEIGHT_FRACTION = 0.205f
private const val DETAIL_TEXT_HEIGHT_FRACTION = 0.14f
private const val SUBJECT_BASELINE_HEIGHT_FRACTION = 0.39f
private const val DETAIL_BASELINE_HEIGHT_FRACTION = 0.77f
private const val DETAIL_GAP_WIDTH_FRACTION = 0.03f
private const val MIN_TITLE_WIDTH_FRACTION = 0.30f
private const val MIN_DETAIL_WIDTH_FRACTION = 0.12f
private const val MIN_SUBJECT_FIT_SCALE = 0.78f
