import { redirect } from "next/navigation";

/**
 * /login/UWP:<code> — the QR's URL. With the app installed the OS never
 * shows this page (the universal link opens the app). Without it, the person
 * lands here; the scan text means nothing to a browser, so send them to the
 * sign-in proper.
 */
export default function LoginScanPage() {
  redirect("/login");
}
