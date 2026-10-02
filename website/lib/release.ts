import fs from "fs";
import path from "path";

export interface ReleaseManifest {
  latestVersion: string;
  latestBuild: number;
  minSupportedBuild?: number;
  apkUrl: string;
  apkPath?: string;
  fileName?: string;
  fileSizeBytes?: number;
  fileSizeFormatted?: string;
  sha256?: string;
  changelog?: string;
  releasedAt?: string;
}

export interface ReleaseInfo {
  version: string;
  buildNumber: number;
  apkUrl: string;
  fileSize?: string;
  sha256?: string;
  releasedAt?: string;
  changelog?: string;
}

/**
 * Retrieves the latest release metadata by inspecting website/public/version.json,
 * falling back gracefully to environment variables or safe defaults.
 */
export function getLatestRelease(): ReleaseInfo {
  const candidatePaths = [
    path.join(process.cwd(), "public", "version.json"),
    path.join(process.cwd(), "website", "public", "version.json"),
  ];

  for (const filePath of candidatePaths) {
    try {
      if (fs.existsSync(filePath)) {
        const raw = fs.readFileSync(filePath, "utf-8");
        const manifest: ReleaseManifest = JSON.parse(raw);
        const rawVersion = (manifest.latestVersion || "").trim();
        const formattedVersion = rawVersion
          ? rawVersion.startsWith("v")
            ? rawVersion
            : `v${rawVersion}`
          : "v1.0.0";

        return {
          version: formattedVersion,
          buildNumber: Number(manifest.latestBuild) || 1,
          apkUrl: manifest.apkPath || manifest.apkUrl || "/zeroscroll.apk",
          fileSize: manifest.fileSizeFormatted,
          sha256: manifest.sha256,
          releasedAt: manifest.releasedAt,
          changelog: manifest.changelog,
        };
      }
    } catch {
      // Continue to next candidate or fallback
    }
  }

  const envVersion = (process.env.NEXT_PUBLIC_APP_VERSION || "v1.0.0").trim();
  return {
    version: envVersion.startsWith("v") ? envVersion : `v${envVersion}`,
    buildNumber: 1,
    apkUrl: process.env.NEXT_PUBLIC_APK_URL || "/zeroscroll.apk",
  };
}
