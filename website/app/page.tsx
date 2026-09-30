import Hero from "@/components/hero";
import PhoneMockup from "@/components/phone-mockup";
import WhatItDoes from "@/components/what-it-does";
import WhatItBlocks from "@/components/what-it-blocks";
import PrivacySection from "@/components/privacy-section";
import FAQ from "@/components/faq";

export default function Home() {
  return (
    <div className="flex flex-col">
      {/* 1) Hero */}
      <Hero />

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
