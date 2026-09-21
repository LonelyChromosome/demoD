package vn.edu.phenikaa.better_phenikaa_schedule

import java.util.Calendar
import java.util.TimeZone
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class NativeSchedulingTest {
    @Test
    fun beforeSixTargetsSixOnTheSameLocalDay() {
        val now = localTime("Asia/Ho_Chi_Minh", 2026, Calendar.SEPTEMBER, 21, 5, 40)
        val target = targetFor(now)

        assertEquals(2026, target.get(Calendar.YEAR))
        assertEquals(Calendar.SEPTEMBER, target.get(Calendar.MONTH))
        assertEquals(21, target.get(Calendar.DAY_OF_MONTH))
        assertEquals(6, target.get(Calendar.HOUR_OF_DAY))
        assertEquals(0, target.get(Calendar.MINUTE))
    }

    @Test
    fun atSixTargetsTheNextLocalDay() {
        val now = localTime("Asia/Ho_Chi_Minh", 2026, Calendar.SEPTEMBER, 21, 6, 0)
        val target = targetFor(now)

        assertEquals(22, target.get(Calendar.DAY_OF_MONTH))
        assertEquals(6, target.get(Calendar.HOUR_OF_DAY))
    }

    @Test
    fun daylightSavingChangeStillTargetsLocalSixRatherThanFixed24Hours() {
        val now = localTime("America/New_York", 2026, Calendar.MARCH, 7, 7, 0)
        val delay = DailySyncScheduler.delayUntilNextSixAm(now)
        val target = (now.clone() as Calendar).apply {
            timeInMillis += delay
        }

        assertEquals(8, target.get(Calendar.DAY_OF_MONTH))
        assertEquals(6, target.get(Calendar.HOUR_OF_DAY))
        assertTrue(delay < 24L * 60L * 60L * 1_000L)
    }

    @Test
    fun widgetSelectionKeepsOlderAndNewerRecordsAroundTheDisplayedIndex() {
        val selectedDate = "2026-09-21"
        val collection = WidgetTimeline.arrange(
            sourceItems = listOf(
                widgetClass("future", "2026-09-22T07:00:00.000", "2026-09-22T09:00:00.000"),
                widgetClass("selected-upcoming", "2026-09-21T09:00:00.000", "2026-09-21T11:00:00.000"),
                widgetClass("past", "2026-09-20T07:00:00.000", "2026-09-20T09:00:00.000"),
                widgetClass("selected-finished", "2026-09-21T06:00:00.000", "2026-09-21T07:00:00.000"),
            ),
            selectedDate = selectedDate,
            today = selectedDate,
            now = "2026-09-21T08:00:00",
        )

        assertEquals("selected-upcoming", collection.items[collection.selectedIndex].id)
        assertTrue(collection.selectedIndex > 0)
        assertTrue(collection.selectedIndex < collection.items.lastIndex)
        assertEquals(listOf("past", "selected-finished", "selected-upcoming", "future"), collection.items.map { it.id })
    }

    private fun targetFor(now: Calendar): Calendar {
        val delay = DailySyncScheduler.delayUntilNextSixAm(now)
        return (now.clone() as Calendar).apply {
            timeInMillis += delay
        }
    }

    private fun localTime(
        zoneId: String,
        year: Int,
        month: Int,
        day: Int,
        hour: Int,
        minute: Int,
    ): Calendar = Calendar.getInstance(TimeZone.getTimeZone(zoneId)).apply {
        clear()
        set(year, month, day, hour, minute, 0)
    }

    private fun widgetClass(id: String, startAt: String, endAt: String) = WidgetClass(
        id = id,
        subject = id,
        room = "A6-205",
        time = "",
        startAt = startAt,
        endAt = endAt,
        dateKey = startAt.take(10),
    )
}
