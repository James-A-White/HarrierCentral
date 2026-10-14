import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { getEvents, getKennelLandingData } from "@/lib/api";
import { getKennelSocialLinks, getMyKennels, getMyRuns, type MyRun } from "@/lib/member-api";
import { parseSocialLinks, type SocialLink } from "@/lib/social-links";
import { requireMember } from "@/lib/member-server";
import { MyKennelPage } from "@/components/member/MyKennelPage";

export async function generateMetadata({ params }: { params: Promise<{ slug: string }> }): Promise<Metadata> {
  const { slug } = await params;
  return { title: slug.toUpperCase() };
}

/**
 * The app's kennel screen, for a web member (E9.F7.S12). Reached from the
 * Kennels tab, a run card, or a history row, exactly as in the app.
 */
export default async function MemberKennelPage({ params, searchParams }: { params: Promise<{ slug: string }>; searchParams: Promise<{ back?: string }> }) {
  const [{ slug }, { back }] = await Promise.all([params, searchParams]);
  const s = await requireMember();
  const [mine, myRuns] = await Promise.all([
    getMyKennels(s).catch(() => []),
    getMyRuns(s).catch(() => [] as MyRun[]),
  ]);
  const kennel = mine.find((k) => k.KennelSlug.toLowerCase() === slug.toLowerCase()) ?? null;
  if (!kennel) notFound();
  const publicKennelId = kennel.PublicKennelId.toLowerCase();
  // Started now so it runs alongside the next-runs fetch below.
  const mineLinksP = getKennelSocialLinks(s, publicKennelId).catch(() => null);

  // Next runs: from my runs when I follow the kennel (they carry my RSVP,
  // bell and envelope); otherwise the kennel's public list.
  let nextRuns: MyRun[] = myRuns.filter((r) => r.PublicKennelId.toLowerCase() === publicKennelId && r.IsPast !== 1);
  if (nextRuns.length === 0) {
    const pub = await getEvents(kennel.PublicKennelId, { isFuture: true, daysOffset: 180 }).catch(() => null);
    nextRuns = (pub?.events ?? []).slice(0, 5).map((e) => ({
      ...(e as unknown as MyRun),
      KennelSlug: kennel.KennelSlug,
      KennelShortName: kennel.KennelShortName,
      KennelName: kennel.KennelName,
      KennelLogo: kennel.KennelLogo,
      PrimaryColor: null,
      AccentColor: null,
      PublicKennelId: kennel.PublicKennelId,
      KennelWebsiteDomain: kennel.KennelWebsiteDomain,
      MyRsvpState: 0, MyAttendenceState: 0, MyIsHare: 0, MyNotificationPref: 0, MyEmailAlertPref: 0, Following: 0, IsMember: 0, IsPast: 0, GoingCount: 0,
      TrackRunnerCount: null, PhotoCount: null, MessageCount: null, DownDownCount: null, DistanceUnitsPref: kennel.DistanceUnitsPref, EventGeographicScope: 1, EventType: null,
    }));
  }

  // Social links (E12.F4.S4): the member's view (members-only entries for
  // the kennel's members and admins); if that call fails, the public list.
  let socialLinks: SocialLink[];
  const mineLinks = await mineLinksP;
  if (mineLinks) {
    socialLinks = parseSocialLinks(mineLinks.json);
  } else {
    const landing = await getKennelLandingData(kennel.KennelSlug).catch(() => null);
    socialLinks = parseSocialLinks(landing?.SocialLinksJson);
  }

  const safeBack = back && back.startsWith("/") && !back.startsWith("//") ? back : "/me/kennels";
  return <MyKennelPage kennel={kennel} nextRuns={nextRuns.slice(0, 5)} back={safeBack} socialLinks={socialLinks} />;
}
