import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { getEvents, getKennelLandingData } from "@/lib/api";
import { getMyKennels, getMyRuns, type MyKennel, type MyRun } from "@/lib/member-api";
import { requireMember } from "@/lib/member-server";
import { MyKennelPage } from "@/components/member/MyKennelPage";

export async function generateMetadata({ params }: { params: Promise<{ slug: string }> }): Promise<Metadata> {
  const { slug } = await params;
  const k = await getKennelLandingData(slug).catch(() => null);
  return { title: k?.KennelShortName ?? "Kennel" };
}

/**
 * The app's kennel screen, for a web member (E9.F7.S12): description, the
 * info rows (location, my last run, next run, hash cash), the next runs
 * with my RSVP, the mismanagement, and the buttons — website, join the
 * group, leaderboards, songs. Reached from the Kennels tab, a run card, or
 * a history row, exactly as in the app.
 */
export default async function MemberKennelPage({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params;
  const s = await requireMember();
  const landing = await getKennelLandingData(slug).catch(() => null);
  if (!landing) notFound();

  const [mine, myRuns] = await Promise.all([
    getMyKennels(s).catch(() => [] as MyKennel[]),
    getMyRuns(s).catch(() => [] as MyRun[]),
  ]);
  const publicKennelId = landing.PublicKennelId.toLowerCase();
  const kennel = mine.find((k) => k.PublicKennelId.toLowerCase() === publicKennelId) ?? null;

  // Next runs: from my runs when I follow the kennel (they carry my RSVP);
  // otherwise the kennel's public list, without a state to show.
  let nextRuns: MyRun[] = myRuns.filter((r) => r.PublicKennelId.toLowerCase() === publicKennelId && r.IsPast !== 1);
  if (nextRuns.length === 0) {
    const pub = await getEvents(landing.PublicKennelId, { isFuture: true, daysOffset: 180 }).catch(() => null);
    nextRuns = (pub?.events ?? []).slice(0, 5).map((e) => ({
      ...(e as unknown as MyRun),
      KennelSlug: landing.KennelUniqueShortName,
      KennelShortName: landing.KennelShortName,
      KennelName: landing.KennelName,
      KennelLogo: landing.KennelLogo,
      PrimaryColor: landing.PrimaryColor,
      AccentColor: landing.AccentColor,
      PublicKennelId: landing.PublicKennelId,
      KennelWebsiteDomain: landing.CustomDomain,
      MyRsvpState: 0, MyAttendenceState: 0, MyIsHare: 0, IsPast: 0, GoingCount: 0,
      TrackRunnerCount: null, PhotoCount: null, MessageCount: null,
    }));
  }

  return (
    <MyKennelPage
      slug={slug}
      landing={{
        PublicKennelId: landing.PublicKennelId,
        KennelName: landing.KennelName,
        KennelShortName: landing.KennelShortName,
        KennelLogo: landing.KennelLogo,
        KennelDescription: landing.KennelDescription,
        CustomDomain: landing.CustomDomain,
      }}
      kennel={kennel}
      nextRuns={nextRuns.slice(0, 5)}
    />
  );
}
