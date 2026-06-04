package com.cleanstart.akillisletme.security

import android.accessibilityservice.AccessibilityServiceInfo
import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.pm.ApplicationInfo
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.os.Build
import android.provider.Settings
import android.view.accessibility.AccessibilityManager
import java.security.KeyStore
import java.util.Collections

/**
 * Collects on-device security signals that are only reachable through Android
 * platform APIs (not from the Flutter/Dart sandbox).
 *
 * Everything here is read-only and best-effort: each probe is wrapped so a
 * single failure (missing permission, OEM quirk) never aborts the whole scan.
 * The result is a plain map that is sent over the [device_security] channel and
 * turned into security rules on the Dart side.
 */
object SecurityScanner {

    fun buildReport(context: Context): Map<String, Any> {
        return mapOf(
            "accessibilityServices" to enabledAccessibilityServices(context),
            "notificationListeners" to enabledNotificationListeners(context),
            "deviceAdmins" to activeDeviceAdmins(context),
            "developerOptionsEnabled" to developerOptionsEnabled(context),
            "adbEnabled" to adbEnabled(context),
            "adbWifiEnabled" to adbWifiEnabled(context),
            "vpnActive" to vpnActive(context),
            "userCaCerts" to userAddedCaCerts(),
            "suBinaryFound" to suBinaryFound(),
        )
    }

    /**
     * Enabled accessibility services. ~90% of commercial stalkerware abuses this
     * permission for keylogging / on-screen reading, so any unexpected entry here
     * is the single strongest spyware signal we can collect.
     */
    private fun enabledAccessibilityServices(context: Context): List<Map<String, String>> {
        return accessibilityPackages(context).map { appEntry(context, it) }
    }

    /** Apps allowed to read every notification (messages, OTP codes, etc.). */
    private fun enabledNotificationListeners(context: Context): List<Map<String, String>> {
        return notificationPackages(context).map { appEntry(context, it) }
    }

    /**
     * Active device-admin apps. Stalkerware grants itself admin so it cannot be
     * uninstalled by dragging to the trash; the user must revoke admin first.
     */
    private fun activeDeviceAdmins(context: Context): List<Map<String, String>> {
        return deviceAdminPackages(context).map { appEntry(context, it) }
    }

    // ── Capability package sets (shared by the report and the app scan) ──

    private fun accessibilityPackages(context: Context): Set<String> {
        return try {
            val am = context.getSystemService(Context.ACCESSIBILITY_SERVICE) as AccessibilityManager
            am.getEnabledAccessibilityServiceList(AccessibilityServiceInfo.FEEDBACK_ALL_MASK)
                .mapNotNull { it.resolveInfo?.serviceInfo?.packageName }
                .toSet()
        } catch (e: Exception) {
            emptySet()
        }
    }

    private fun notificationPackages(context: Context): Set<String> {
        return try {
            val flat = Settings.Secure.getString(
                context.contentResolver,
                "enabled_notification_listeners",
            ) ?: return emptySet()
            flat.split(":")
                .mapNotNull { ComponentName.unflattenFromString(it)?.packageName }
                .toSet()
        } catch (e: Exception) {
            emptySet()
        }
    }

    private fun deviceAdminPackages(context: Context): Set<String> {
        return try {
            val dpm = context.getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
            dpm.activeAdmins?.map { it.packageName }?.toSet() ?: emptySet()
        } catch (e: Exception) {
            emptySet()
        }
    }

    /** Resolves a package name to a `{package, label}` entry for the UI. */
    private fun appEntry(context: Context, pkg: String): Map<String, String> {
        val label = try {
            val pm = context.packageManager
            pm.getApplicationLabel(pm.getApplicationInfo(pkg, 0)).toString()
        } catch (e: PackageManager.NameNotFoundException) {
            pkg
        } catch (e: Exception) {
            pkg
        }
        return mapOf("package" to pkg, "label" to label)
    }

    private fun developerOptionsEnabled(context: Context): Boolean {
        return globalFlag(context, Settings.Global.DEVELOPMENT_SETTINGS_ENABLED)
    }

    private fun adbEnabled(context: Context): Boolean {
        return globalFlag(context, Settings.Global.ADB_ENABLED)
    }

    /** Wireless debugging (ADB over Wi-Fi) — a remote attack surface when on. */
    private fun adbWifiEnabled(context: Context): Boolean {
        return globalFlag(context, "adb_wifi_enabled")
    }

    private fun globalFlag(context: Context, key: String): Boolean {
        return try {
            Settings.Global.getInt(context.contentResolver, key, 0) == 1
        } catch (e: Exception) {
            false
        }
    }

    /** VPN via the transport capability — far more reliable than interface names. */
    private fun vpnActive(context: Context): Boolean {
        return try {
            val cm = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
            val caps = cm.getNetworkCapabilities(cm.activeNetwork)
            caps?.hasTransport(NetworkCapabilities.TRANSPORT_VPN) == true
        } catch (e: Exception) {
            false
        }
    }

    /**
     * User-added Certificate Authorities. A CA you did not install yourself is a
     * classic man-in-the-middle / traffic-interception setup. Aliases in the
     * AndroidCAStore are prefixed "system:" (built-in) or "user:" (added).
     */
    private fun userAddedCaCerts(): List<String> {
        return try {
            val ks = KeyStore.getInstance("AndroidCAStore")
            ks.load(null, null)
            Collections.list(ks.aliases())
                .filter { it.startsWith("user:") }
                .map { it.removePrefix("user:") }
        } catch (e: Exception) {
            emptyList()
        }
    }

    /** Whether an `su` binary is actually invocable (deeper than path checks). */
    private fun suBinaryFound(): Boolean {
        return try {
            val process = Runtime.getRuntime().exec(arrayOf("which", "su"))
            val output = process.inputStream.bufferedReader().readText().trim()
            process.destroy()
            output.isNotEmpty()
        } catch (e: Exception) {
            false
        }
    }

    // ── Installed-app risk scan ─────────────────────────────────

    /** App stores whose installs are considered "from a trusted source". */
    private val TRUSTED_INSTALLERS = setOf(
        "com.android.vending",            // Google Play
        "com.google.android.feedback",
        "com.sec.android.app.samsungapps", // Samsung Galaxy Store
        "com.amazon.venezia",
        "com.huawei.appmarket",
        "com.xiaomi.market",              // Xiaomi GetApps
        "com.xiaomi.mipicks",
        "com.heytap.market",              // Oppo / Realme
        "com.oppo.market",
        "com.vivo.appstore",
    )

    /** Granted dangerous permissions we surface, mapped to friendly labels. */
    private val DANGEROUS_PERMISSIONS = linkedMapOf(
        "android.permission.CAMERA" to "Camera",
        "android.permission.RECORD_AUDIO" to "Microphone",
        "android.permission.ACCESS_FINE_LOCATION" to "Location",
        "android.permission.ACCESS_BACKGROUND_LOCATION" to "Background location",
        "android.permission.READ_SMS" to "Read SMS",
        "android.permission.SEND_SMS" to "Send SMS",
        "android.permission.READ_CONTACTS" to "Contacts",
        "android.permission.READ_CALL_LOG" to "Call log",
        "android.permission.READ_PHONE_STATE" to "Phone",
        "android.permission.PROCESS_OUTGOING_CALLS" to "Outgoing calls",
        "android.permission.READ_EXTERNAL_STORAGE" to "Storage",
    )

    /**
     * Enumerates installed apps with the signals that matter for a risk verdict:
     * sideload source, sensitive capabilities (accessibility / device-admin /
     * notification / overlay) and granted dangerous permissions. Stock system
     * apps with no sensitive capability are skipped to keep the list focused.
     *
     * Requires the `QUERY_ALL_PACKAGES` permission (a Play-allowed use for a
     * security/antivirus app). The actual risk level is computed on the Dart side.
     */
    fun scanInstalledApps(context: Context): List<Map<String, Any>> {
        val pm = context.packageManager
        val accessibility = accessibilityPackages(context)
        val admins = deviceAdminPackages(context)
        val notif = notificationPackages(context)

        val packages = try {
            pm.getInstalledPackages(PackageManager.GET_PERMISSIONS)
        } catch (e: Exception) {
            return emptyList()
        }

        val result = ArrayList<Map<String, Any>>()
        for (pi in packages) {
            try {
                val ai = pi.applicationInfo ?: continue
                val pkg = pi.packageName
                val isSystem = (ai.flags and ApplicationInfo.FLAG_SYSTEM) != 0
                val hasAccessibility = accessibility.contains(pkg)
                val hasAdmin = admins.contains(pkg)
                val hasNotif = notif.contains(pkg)

                // Keep the list focused on what a user can act on.
                if (isSystem && !hasAccessibility && !hasAdmin && !hasNotif) continue

                val installer = installerOf(context, pkg)
                val sideloaded =
                    !isSystem && (installer == null || installer !in TRUSTED_INSTALLERS)

                result.add(
                    mapOf(
                        "package" to pkg,
                        "label" to label(pm, ai),
                        "installer" to (installer ?: ""),
                        "sideloaded" to sideloaded,
                        "system" to isSystem,
                        "firstInstall" to pi.firstInstallTime,
                        "accessibility" to hasAccessibility,
                        "deviceAdmin" to hasAdmin,
                        "notificationAccess" to hasNotif,
                        "overlay" to isGranted(pi, "android.permission.SYSTEM_ALERT_WINDOW"),
                        "permissions" to grantedDangerousPermissions(pi),
                    ),
                )
            } catch (e: Exception) {
                // Skip a package we cannot read; never abort the whole scan.
            }
        }
        return result
    }

    private fun label(pm: PackageManager, ai: ApplicationInfo): String {
        return try {
            pm.getApplicationLabel(ai).toString()
        } catch (e: Exception) {
            ai.packageName
        }
    }

    private fun installerOf(context: Context, pkg: String): String? {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                context.packageManager.getInstallSourceInfo(pkg).installingPackageName
            } else {
                @Suppress("DEPRECATION")
                context.packageManager.getInstallerPackageName(pkg)
            }
        } catch (e: Exception) {
            null
        }
    }

    private fun grantedDangerousPermissions(pi: PackageInfo): List<String> {
        val requested = pi.requestedPermissions ?: return emptyList()
        val flags = pi.requestedPermissionsFlags ?: return emptyList()
        val out = ArrayList<String>()
        for (i in requested.indices) {
            if (i >= flags.size) break
            val granted = (flags[i] and PackageInfo.REQUESTED_PERMISSION_GRANTED) != 0
            if (granted) DANGEROUS_PERMISSIONS[requested[i]]?.let { out.add(it) }
        }
        return out.distinct()
    }

    private fun isGranted(pi: PackageInfo, permission: String): Boolean {
        val requested = pi.requestedPermissions ?: return false
        val flags = pi.requestedPermissionsFlags ?: return false
        val idx = requested.indexOf(permission)
        if (idx < 0 || idx >= flags.size) return false
        return (flags[idx] and PackageInfo.REQUESTED_PERMISSION_GRANTED) != 0
    }
}
