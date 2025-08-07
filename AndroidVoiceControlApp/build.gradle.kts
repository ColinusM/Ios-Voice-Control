// Top-level build file where you can add configuration options common to all sub-projects/modules.
plugins {
    id("com.android.application") version "8.11.1" apply false
    id("org.jetbrains.kotlin.android") version "2.2.0" apply false
    id("org.jetbrains.kotlin.plugin.compose") version "2.2.0" apply false
    id("com.google.gms.google-services") version "4.4.2" apply false
    id("com.google.firebase.crashlytics") version "3.0.1" apply false
    id("com.google.firebase.firebase-perf") version "1.4.2" apply false
    id("com.google.dagger.hilt.android") version "2.54" apply false
    kotlin("plugin.serialization") version "2.2.0" apply false
}

buildscript {
    dependencies {
        classpath("com.google.gms:google-services:4.4.2")
        classpath("com.google.firebase:firebase-crashlytics-gradle:3.0.1")
        classpath("com.google.firebase:perf-plugin:1.4.2")
    }
}