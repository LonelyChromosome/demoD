package vn.edu.phenikaa.better_phenikaa_schedule

import android.app.Activity
import android.app.DatePickerDialog
import android.appwidget.AppWidgetManager
import android.content.Intent
import android.os.Bundle
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

class WidgetDatePickerActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val widgetId = intent.getIntExtra(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID,
        )
        if (widgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            finish()
            return
        }

        val prefs = getSharedPreferences(
            ScheduleWidgetProvider.WIDGET_SELECTION_PREFS,
            MODE_PRIVATE,
        )
        val today = SimpleDateFormat(DATE_PATTERN, Locale.US).format(Date())
        val selected = prefs
            .getString(ScheduleWidgetProvider.selectedDateKey(widgetId), null)
            ?.takeIf(::isIsoDate)
            ?: today

        val calendar = Calendar.getInstance().apply {
            set(Calendar.YEAR, selected.substring(0, 4).toInt())
            set(Calendar.MONTH, selected.substring(5, 7).toInt() - 1)
            set(Calendar.DAY_OF_MONTH, selected.substring(8, 10).toInt())
        }

        val dialog = DatePickerDialog(
            this,
            { _, year, month, day ->
                val date = String.format(
                    Locale.US,
                    "%04d-%02d-%02d",
                    year,
                    month + 1,
                    day,
                )
                prefs.edit()
                    .putString(ScheduleWidgetProvider.selectedDateKey(widgetId), date)
                    .apply()
                refreshWidget(widgetId)
                finish()
            },
            calendar.get(Calendar.YEAR),
            calendar.get(Calendar.MONTH),
            calendar.get(Calendar.DAY_OF_MONTH),
        )
        dialog.setOnCancelListener { finish() }
        dialog.setOnDismissListener {
            if (!isFinishing) {
                finish()
            }
        }
        dialog.show()
    }

    private fun refreshWidget(widgetId: Int) {
        sendBroadcast(
            Intent(this, ScheduleWidgetProvider::class.java).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, intArrayOf(widgetId))
            },
        )
    }
}

private fun isIsoDate(value: String): Boolean =
    value.length == 10 &&
        value[4] == '-' &&
        value[7] == '-' &&
        value.substring(0, 4).all(Char::isDigit) &&
        value.substring(5, 7).all(Char::isDigit) &&
        value.substring(8, 10).all(Char::isDigit)

private const val DATE_PATTERN = "yyyy-MM-dd"
