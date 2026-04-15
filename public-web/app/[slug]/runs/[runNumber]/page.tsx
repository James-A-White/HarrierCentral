import { redirect } from "next/navigation";

interface PageProps {
  params: Promise<{ slug: string; runNumber: string }>;
}

export default async function RunDetailRedirect({ params }: PageProps) {
  const { slug, runNumber } = await params;
  redirect(`/${slug}/${runNumber}`);
}
