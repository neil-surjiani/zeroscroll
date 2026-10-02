import Hero from "@/components/hero";
import PhoneMockup from "@/components/phone-mockup";
import WhatItDoes from "@/components/what-it-does";
import WhatItBlocks from "@/components/what-it-blocks";
import PrivacySection from "@/components/privacy-section";
import FAQ from "@/components/faq";
import { getLatestRelease } from "@/lib/release";

export default function Home() {
  const release = getLatestRelease();

  return (
    <div className="flex flex-col">
      {/* 1) Hero */}
      <Hero
        apkUrl={release.apkUrl}
        appVersion={release.version}
        fileSize={release.fileSize}
        sha256={release.sha256}
        releasedAt={release.releasedAt}
      />

      {/* 2) Phone Mockup */}
      <PhoneMockup />

      {/* 3) What it does */}
      <WhatItDoes />

      {/* 4) What it blocks */}
      <WhatItBlocks />

      {/* 5) Privacy */}
      <PrivacySection />

      {/* 6) FAQ */}
      <FAQ />
    </div>
  );
}
