import type { Metadata } from "next";
import { getGeography, type Place } from "@/lib/api";
import { mintFormStamp } from "@/lib/kennel-request";
import { GLOBAL_BASE_URL } from "@/lib/seo";
import { AddKennelForm } from "./AddKennelForm";

export const metadata: Metadata = {
  title: "Add your kennel",
  description:
    "Bring your hash kennel to Harrier Central — runs, members, trails and your own page on hashruns.org, free.",
  alternates: { canonical: `${GLOBAL_BASE_URL}/add-kennel` },
};

// The form carries a stamp minted at render time, so the page is never cached.
export const dynamic = "force-dynamic";

/**
 * hashruns.org/add-kennel (E12.F1.S7) — a kennel asks to join Harrier
 * Central. Replaces the harriercentral.com form that posted to the old
 * ProcessWpForm endpoint. Anyone may fill it in: the requester proves their
 * email with a code, and a platform admin approves the request in the portal.
 */
export default async function AddKennelPage() {
  let countries: Place[] = [];
  try {
    countries = await getGeography();
  } catch {
    // The form says so and offers a retry; the rest of the page still renders.
  }
  return (
    <main className="mx-auto max-w-2xl px-4 pb-24">
      <div className="py-8 text-center">
        <h1 className="text-3xl font-bold tracking-tight">Add your kennel</h1>
        <p className="mx-auto mt-2 max-w-xl text-sm text-zinc-300">
          Runs, members, run counts, payments, trails and your own page at hashruns.org — free for every
          kennel. Tell us about yours; we check each request by hand and email you when it is live.
        </p>
      </div>
      <AddKennelForm countries={countries} stamp={mintFormStamp()} />
    </main>
  );
}
