# Keep Room entities/dao
-keep class androidx.room.** { *; }
-dontwarn androidx.room.**

# Kotlinx serialization
-keepclassmembers class ** {
    *** Companion;
}
-keepclasseswithmembers class ** {
    kotlinx.serialization.KSerializer serializer(...);
}

# Hilt
-keep class dagger.hilt.** { *; }
-dontwarn dagger.hilt.**

