package com.offline.ledger.utils

import java.time.Instant
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.LocalTime
import java.time.YearMonth
import java.time.ZoneId
import java.time.ZoneOffset
import java.time.format.DateTimeFormatter
import java.util.Locale

object DateTimeUtils {
    private val zone: ZoneId = ZoneId.systemDefault()

    private val dateFormatter: DateTimeFormatter =
        DateTimeFormatter.ofPattern("yyyy-MM-dd", Locale.getDefault())

    private val dateTimeFormatter: DateTimeFormatter =
        DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm", Locale.getDefault())

    fun nowMillis(): Long = System.currentTimeMillis()

    fun localDateFromMillis(millis: Long): LocalDate {
        return Instant.ofEpochMilli(millis).atZone(zone).toLocalDate()
    }

    /**
     * Material3 DatePicker uses UTC-based millis; convert it to a calendar date without timezone shift.
     */
    fun localDateFromUtcMillis(utcMillis: Long): LocalDate {
        return Instant.ofEpochMilli(utcMillis).atZone(ZoneOffset.UTC).toLocalDate()
    }

    fun localDateTimeFromMillis(millis: Long): LocalDateTime {
        return Instant.ofEpochMilli(millis).atZone(zone).toLocalDateTime()
    }

    fun millisFromLocalDate(date: LocalDate): Long {
        return date.atStartOfDay(zone).toInstant().toEpochMilli()
    }

    fun millisFromLocalDateTime(date: LocalDate, time: LocalTime): Long {
        return date.atTime(time).atZone(zone).toInstant().toEpochMilli()
    }

    fun startOfMonthMillis(yearMonth: YearMonth): Long {
        return yearMonth.atDay(1).atStartOfDay(zone).toInstant().toEpochMilli()
    }

    fun endOfMonthMillis(yearMonth: YearMonth): Long {
        val end = yearMonth.atEndOfMonth().plusDays(1).atStartOfDay(zone).toInstant().toEpochMilli()
        return end - 1
    }

    fun formatDate(millis: Long): String = dateFormatter.format(localDateFromMillis(millis))

    fun formatDateTime(millis: Long): String = dateTimeFormatter.format(localDateTimeFromMillis(millis))
}
