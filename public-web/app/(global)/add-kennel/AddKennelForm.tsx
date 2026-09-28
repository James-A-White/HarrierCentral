"use client";

import { useEffect, useState } from "react";
import type { Place } from "@/lib/api";

const input =
  "w-full rounded-lg border border-zinc-300 bg-white px-3 py-2.5 text-base text-zinc-900 placeholder:italic placeholder:text-zinc-400 focus:outline-none focus:ring-2 focus:ring-orange-400 disabled:bg-zinc-100";
const label = "mb-1 block text-sm font-medium text-zinc-700";
const labelBad = "mb-1 block text-sm font-semibold text-red-600";
const inputBad = " border-red-500 ring-1 ring-red-500";
const primaryBtn =
  "inline-flex w-full items-center justify-center rounded-full bg-orange-500 px-5 py-3 text-center text-base font-semibold text-white transition-opacity hover:opacity-90 disabled:opacity-50";
const linkBtn = "text-sm text-zinc-600 underline underline-offset-2 hover:text-zinc-900";

type Step = { kind: "form" } | { kind: "code"; requestId: string | null; again: boolean } | { kind: "done"; already: boolean };

const EMPTY = {
  firstName: "", lastName: "", hashName: "", email: "",
  kennelName: "", kennelShortName: "", kennelDescription: "", kennelUrl: "", kennelFacebookUrl: "",
  countryId: "", regionId: "", cityId: "", cityText: "",
  runsPerMonth: "", hashersPerRun: "", hashCash: "", nonMemberPrice: "", membershipFee: "", membershipType: "",
  nextRunNumber: "", howDidYouLearn: "", comments: "",
};
type Fields = typeof EMPTY;

/**
 * A run fee as the box allows it: digits and ONE decimal point, a comma taken
 * as the point, everything else dropped as it is typed — so "two pounds" or
 * "£5" can never reach the server (James, 2026-09-28).
 */
export function moneyOnly(raw: string): string {
  const cleaned = raw.replace(/,/g, ".").replace(/[^0-9.]/g, "");
  const dot = cleaned.indexOf(".");
  const whole = dot < 0 ? cleaned : cleaned.slice(0, dot + 1) + cleaned.slice(dot + 1).replace(/\./g, "");
  // At most two decimals; a fee is money.
  const m = whole.match(/^(\d*)(\.\d{0,2})?/);
  const out = m ? (m[1] ?? "") + (m[2] ?? "") : "";
  // ".5" means 0.50.
  return out.startsWith(".") ? "0" + out : out;
}

/** HC.Kennel.MembershipRenewalMode, in words a kennel will recognise. */
const MEMBERSHIP_TYPES: { value: string; label: string }[] = [
  { value: "1", label: "Annual — each membership runs 12 months from payment" },
  { value: "2", label: "Fixed year — everyone renews on the same date" },
  { value: "3", label: "Lifetime — pay once" },
];

/**
 * The three opt-in questions of the old harriercentral.com form, word for
 * word (James, 2026-09-28). Each needs an answer; the third has only one.
 * The answer TEXT is sent and kept with the request for the reviewer.
 */
const TERMS: { title: string; text: string; options: string[] }[] = [
  {
    title: "#1",
    text: "I understand that Opee and Tuna Melt are offering the basic features of Harrier Central for free because they LOVE Hashing and want to see more people participate in Hashing around the world.",
    options: ["Yes, that makes sense", "No, I'm confused — I haven't had enough beer yet"],
  },
  {
    title: "#2",
    text: "I understand that by using the free version of Harrier Central, I am committing my Kennel to offering Tuna Melt and Opee each one free run per year with our Kennel if they happen to be visiting. We also agree to help them find crash space with a local Hasher to save on hotel costs, and to invite them out for drinks and show them the best local spots (when practical) on nights when the Hash is not running.",
    options: ["Of course — we're happy to show Tuna and Opee a good time!", "We're a pretty boring group… they get a free run, but that's all"],
  },
  {
    title: "#3",
    text: "I understand that Tuna Melt and Opee are paying good money to professionally and securely host Harrier Central on a global cloud platform (Microsoft Azure) and they have to make some money to recover their costs. They're not in this to make a lot of money — but they will have to charge for some advanced features to recoup their out-of-pocket costs, and that's OK.",
    options: ["I understand and that's OK!"],
  },
];

async function post<T>(url: string, body: unknown): Promise<T> {
  const res = await fetch(url, { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(body) });
  const json = (await res.json().catch(() => ({}))) as T & { error?: string };
  if (!res.ok) throw new Error(json.error ?? "Something went wrong. Please try again.");
  return json;
}

function usePlaces(param: "countryId" | "regionId", id: string): { places: Place[]; loading: boolean } {
  const [state, setState] = useState<{ key: string; places: Place[] }>({ key: "", places: [] });
  useEffect(() => {
    if (!id) return;
    let live = true;
    fetch(`/api/geography?${param}=${encodeURIComponent(id)}`)
      .then((r) => (r.ok ? r.json() : []))
      .then((p: Place[]) => live && setState({ key: id, places: p }))
      .catch(() => live && setState({ key: id, places: [] }));
    return () => { live = false; };
  }, [param, id]);
  return { places: state.key === id ? state.places : [], loading: !!id && state.key !== id };
}

export function AddKennelForm({ countries, stamp }: { countries: Place[]; stamp: string }) {
  const [f, setF] = useState<Fields>(EMPTY);
  const [cityNotListed, setCityNotListed] = useState(false);
  const [honeypot, setHoneypot] = useState("");
  const [terms, setTerms] = useState<string[]>(["", "", ""]);
  const [hasMembership, setHasMembership] = useState(false);
  const [step, setStep] = useState<Step>({ kind: "form" });
  const [code, setCode] = useState("");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  // Send was pressed: from now on, what is missing is shown in red.
  const [tried, setTried] = useState(false);

  const regions = usePlaces("countryId", f.countryId);
  const cities = usePlaces("regionId", f.regionId);

  const setMoney = (k: "hashCash" | "nonMemberPrice" | "membershipFee") => (e: React.ChangeEvent<HTMLInputElement>) =>
    setF((prev) => ({ ...prev, [k]: moneyOnly(e.target.value) }));

  const set = (k: keyof Fields) => (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>) =>
    setF((prev) => ({ ...prev, [k]: e.target.value }));

  // The short name becomes the web address: letters and digits only.
  const setShortName = (e: React.ChangeEvent<HTMLInputElement>) =>
    setF((prev) => ({ ...prev, kennelShortName: e.target.value.toUpperCase().replace(/[^A-Z0-9]/g, "").slice(0, 20) }));

  const pickCountry = (e: React.ChangeEvent<HTMLSelectElement>) =>
    setF((prev) => ({ ...prev, countryId: e.target.value, regionId: "", cityId: "" }));
  const pickRegion = (e: React.ChangeEvent<HTMLSelectElement>) =>
    setF((prev) => ({ ...prev, regionId: e.target.value, cityId: "" }));

  const placeOk = !!f.countryId && (cityNotListed ? f.cityText.trim().length > 0 : !!f.cityId);
  // "5." is still being typed; only a whole number or a number with decimals is a fee.
  const isFee = (v: string) => /^\d+(\.\d{1,2})?$/.test(v);
  // Everything that stops the request, in page order: field key → its name.
  // Membership ticked ⇒ everything in its box is required; unticked ⇒ none
  // of it is, and the one run fee outside is the price for everyone.
  const problems: [string, string][] = [
    ...(f.kennelName.trim() ? [] : [["kennelName", "Kennel name"]]),
    ...(f.kennelShortName ? [] : [["shortName", "Short name"]]),
    ...(f.kennelDescription.trim() ? [] : [["desc", "About the kennel"]]),
    ...(f.countryId ? [] : [["country", "Country"]]),
    ...(!f.countryId || placeOk ? [] : [["city", "City or town"]]),
    ...(hasMembership && !isFee(f.membershipFee) ? [["memberFee", "Membership fee"]] : []),
    ...(hasMembership && !f.membershipType ? [["memberType", "Type of membership"]] : []),
    ...(hasMembership && !isFee(f.hashCash) ? [["feeMember", "Run fee for members"]] : []),
    ...(isFee(f.nonMemberPrice) ? [] : [["feeVisitor", hasMembership ? "Run fee for visitors" : "Run fee"]]),
    ...(f.firstName.trim() ? [] : [["first", "First name"]]),
    ...(f.lastName.trim() ? [] : [["last", "Last name"]]),
    ...(/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(f.email.trim()) ? [] : [["email", "Email"]]),
    ...terms.flatMap((t, i) => (t ? [] : [[`terms${i + 1}`, `Terms question #${i + 1}`]])),
  ] as [string, string][];
  const bad = (k: string) => tried && problems.some(([p]) => p === k);
  const lbl = (k: string) => (bad(k) ? labelBad : label);
  const box = (k: string) => (bad(k) ? input + inputBad : input);

  async function submit() {
    setTried(true);
    if (problems.length > 0) {
      setError(null);
      return;
    }
    setBusy(true);
    setError(null);
    try {
      const r = await post<{ requestId: string | null; alreadySubmitted: boolean; codeSent: boolean }>("/api/kennel-request", {
        ...f,
        cityId: cityNotListed ? "" : f.cityId,
        cityText: cityNotListed ? f.cityText : "",
        stamp,
        website: honeypot,
        hasMembership: hasMembership ? "1" : "0",
        hashCash: hasMembership ? f.hashCash : "",
        membershipFee: hasMembership ? f.membershipFee : "",
        membershipType: hasMembership ? f.membershipType : "",
        terms1: terms[0],
        terms2: terms[1],
        terms3: terms[2],
      });
      // Already confirmed earlier: nothing to type, it is in the queue.
      if (r.alreadySubmitted && !r.codeSent) setStep({ kind: "done", already: true });
      else setStep({ kind: "code", requestId: r.requestId, again: r.alreadySubmitted });
      window.scrollTo({ top: 0, behavior: "smooth" });
    } catch (e) {
      setError((e as Error).message);
    } finally {
      setBusy(false);
    }
  }

  async function confirm(requestId: string | null) {
    setBusy(true);
    setError(null);
    try {
      const r = await post<{ alreadyConfirmed: boolean }>("/api/kennel-request/confirm", { requestId, code });
      setStep({ kind: "done", already: r.alreadyConfirmed });
    } catch (e) {
      setError((e as Error).message);
    } finally {
      setBusy(false);
    }
  }

  const panel = "rounded-2xl bg-white p-5 text-zinc-900 shadow-xl sm:p-7";
  const errorBox = error && <p className="mb-4 rounded-lg bg-red-50 px-3 py-2 text-sm text-red-700">{error}</p>;

  if (step.kind === "done") {
    return (
      <div className={`${panel} text-center`}>
        <h2 className="text-xl font-bold">Thank you — on on!</h2>
        <p className="mt-3 text-zinc-700">
          {step.already
            ? "We already have your request, and it is waiting for review."
            : "Your request is confirmed and waiting for review."}{" "}
          We check each one by hand, usually within a few days, and email <strong>{f.email.trim()}</strong> when
          your kennel is live — with a code to sign in to the Harrier Central app as its admin.
        </p>
      </div>
    );
  }

  if (step.kind === "code") {
    return (
      <form className={`${panel} space-y-4 text-center`} onSubmit={(e) => { e.preventDefault(); if (!busy) void confirm(step.requestId); }}>
        <h2 className="text-xl font-bold">Check your email</h2>
        <p className="text-zinc-700">
          {step.again ? "We already had this request, so we sent a new code" : "We sent a six-digit code"} to{" "}
          <strong>{f.email.trim()}</strong>. Enter it here to confirm the request. It works for 48 hours.
        </p>
        {errorBox}
        <input
          className={`${input} mx-auto max-w-[12rem] text-center text-2xl tracking-[0.4em]`}
          inputMode="numeric" autoComplete="one-time-code" maxLength={6} placeholder="000000"
          value={code} onChange={(e) => setCode(e.target.value.replace(/\D/g, "").slice(0, 6))} autoFocus
        />
        <button type="submit" className={primaryBtn} disabled={busy || code.length !== 6}>
          {busy ? "Checking…" : "Confirm my request"}
        </button>
        <p className="text-sm text-zinc-600">
          No email? Check your spam folder, or{" "}
          <button type="button" className={linkBtn} onClick={() => { setError(null); setCode(""); setStep({ kind: "form" }); }}>
            go back and check the address
          </button>
          .
        </p>
      </form>
    );
  }

  return (
    <form className={`${panel} space-y-6`} onSubmit={(e) => { e.preventDefault(); if (!busy) void submit(); }}>

      {/* Honeypot: people never see it, bots fill it in. */}
      <div aria-hidden="true" style={{ position: "absolute", left: "-10000px", width: 1, height: 1, overflow: "hidden" }}>
        <label>
          Website (leave empty)
          <input tabIndex={-1} autoComplete="off" value={honeypot} onChange={(e) => setHoneypot(e.target.value)} name="website" />
        </label>
      </div>

      <fieldset className="space-y-3">
        <legend className="mb-2 text-lg font-bold">Your kennel</legend>
        <div>
          <label className={lbl("kennelName")} htmlFor="kennelName">Kennel name *</label>
          <input id="kennelName" className={box("kennelName")} maxLength={250} placeholder="e.g. London Hash House Harriers" value={f.kennelName} onChange={set("kennelName")} />
        </div>
        <div>
          <label className={lbl("shortName")} htmlFor="shortName">Short name *</label>
          <input id="shortName" className={box("shortName")} placeholder="e.g. LH3" value={f.kennelShortName} onChange={setShortName} />
          <p className="mt-1 text-xs text-zinc-500">
            Letters and digits. Your page will be at hashruns.org/{(f.kennelShortName || "lh3").toLowerCase()} (or close to it
            if the name is taken).
          </p>
        </div>
        <div>
          <label className={lbl("desc")} htmlFor="desc">Tell hashers about the kennel *</label>
          <textarea id="desc" className={box("desc")} rows={4} maxLength={4000} placeholder="When and where you run, what to expect…" value={f.kennelDescription} onChange={set("kennelDescription")} />
        </div>
        <div className="grid gap-3 sm:grid-cols-2">
          <div>
            <label className={label} htmlFor="url">Website</label>
            <input id="url" className={input} type="url" maxLength={250} placeholder="https://…" value={f.kennelUrl} onChange={set("kennelUrl")} />
          </div>
          <div>
            <label className={label} htmlFor="fb">Facebook page</label>
            <input id="fb" className={input} type="url" maxLength={250} placeholder="https://facebook.com/…" value={f.kennelFacebookUrl} onChange={set("kennelFacebookUrl")} />
          </div>
        </div>
      </fieldset>

      <fieldset className="space-y-3">
        <legend className="mb-2 text-lg font-bold">Where you run</legend>
        {countries.length === 0 && (
          <p className="rounded-lg bg-amber-50 px-3 py-2 text-sm text-amber-800">
            The list of countries did not load. Please reload the page.
          </p>
        )}
        <div>
          <label className={lbl("country")} htmlFor="country">Country *</label>
          <select id="country" className={box("country")} value={f.countryId} onChange={pickCountry}>
            <option value="">Choose…</option>
            {countries.map((c) => <option key={c.id} value={c.id}>{c.name}</option>)}
          </select>
        </div>
        {f.countryId && (
          <div>
            <label className={label} htmlFor="region">Region / state</label>
            <select id="region" className={input} value={f.regionId} onChange={pickRegion} disabled={regions.loading}>
              <option value="">{regions.loading ? "Loading…" : "Choose…"}</option>
              {regions.places.map((r) => <option key={r.id} value={r.id}>{r.name}</option>)}
            </select>
          </div>
        )}
        {f.countryId && (
          cityNotListed || !f.regionId ? (
            <div>
              <label className={lbl("city")} htmlFor="cityText">City or town *</label>
              <input id="cityText" className={box("city")} maxLength={50} value={f.cityText} onChange={set("cityText")} />
              {f.regionId && (
                <button type="button" className={`${linkBtn} mt-1`} onClick={() => setCityNotListed(false)}>
                  Pick from the list instead
                </button>
              )}
            </div>
          ) : (
            <div>
              <label className={lbl("city")} htmlFor="city">City or town *</label>
              <select id="city" className={box("city")} value={f.cityId} onChange={set("cityId")} disabled={cities.loading}>
                <option value="">{cities.loading ? "Loading…" : "Choose…"}</option>
                {cities.places.map((c) => <option key={c.id} value={c.id}>{c.name}</option>)}
              </select>
              <button type="button" className={`${linkBtn} mt-1`} onClick={() => { setCityNotListed(true); setF((p) => ({ ...p, cityId: "" })); }}>
                My city is not listed
              </button>
            </div>
          )
        )}
      </fieldset>

      <fieldset className="space-y-3">
        <legend className="mb-2 text-lg font-bold">Money</legend>
        <p className="text-sm text-zinc-600">In your local currency — numbers only. Enter 0 if something is free.</p>

        {/* The membership box: a checkbox in its border. Unticked, everything
            inside is off; ticked, everything inside is required. */}
        <div className={`relative rounded-xl border-2 px-4 pb-4 pt-6 ${hasMembership ? "border-orange-400" : "border-zinc-300"}`}>
          <label className="absolute -top-3 left-3 flex cursor-pointer items-center gap-2 bg-white px-2 text-base font-semibold text-zinc-900">
            <input
              type="checkbox"
              className="h-5 w-5 accent-orange-500"
              checked={hasMembership}
              onChange={(e) => setHasMembership(e.target.checked)}
            />
            Membership
          </label>
          <fieldset disabled={!hasMembership} className={`grid gap-3 sm:grid-cols-2 ${hasMembership ? "" : "opacity-50"}`}>
            <div>
              <label className={lbl("memberFee")} htmlFor="memberFee">Membership fee{hasMembership ? " *" : ""}</label>
              <input id="memberFee" className={box("memberFee")} inputMode="decimal" autoComplete="off" placeholder="e.g. 20" maxLength={10}
                value={f.membershipFee} onChange={setMoney("membershipFee")} />
            </div>
            <div>
              <label className={lbl("memberType")} htmlFor="memberType">Type of membership{hasMembership ? " *" : ""}</label>
              <select id="memberType" className={box("memberType")} value={f.membershipType} onChange={set("membershipType")}>
                <option value="">Choose…</option>
                {MEMBERSHIP_TYPES.map((t) => <option key={t.value} value={t.value}>{t.label}</option>)}
              </select>
            </div>
            <div className="sm:col-span-2">
              <label className={lbl("feeMember")} htmlFor="feeMember">Run fee for members{hasMembership ? " *" : ""}</label>
              <input id="feeMember" className={box("feeMember")} inputMode="decimal" autoComplete="off" placeholder="e.g. 5" maxLength={10}
                value={f.hashCash} onChange={setMoney("hashCash")} />
            </div>
          </fieldset>
        </div>

        <div>
          <label className={lbl("feeVisitor")} htmlFor="feeVisitor">{hasMembership ? "Run fee for visitors *" : "Run fee *"}</label>
          <input id="feeVisitor" className={box("feeVisitor")} inputMode="decimal" autoComplete="off" placeholder="e.g. 7" maxLength={10}
            value={f.nonMemberPrice} onChange={setMoney("nonMemberPrice")} />
        </div>
      </fieldset>

      <fieldset className="space-y-3">
        <legend className="mb-2 text-lg font-bold">About you</legend>
        <p className="text-sm text-zinc-600">You become the kennel&rsquo;s admin in Harrier Central, and can add others later.</p>
        <div className="grid gap-3 sm:grid-cols-2">
          <div>
            <label className={lbl("first")} htmlFor="first">First name *</label>
            <input id="first" className={box("first")} autoComplete="given-name" maxLength={250} value={f.firstName} onChange={set("firstName")} />
          </div>
          <div>
            <label className={lbl("last")} htmlFor="last">Last name *</label>
            <input id="last" className={box("last")} autoComplete="family-name" maxLength={250} value={f.lastName} onChange={set("lastName")} />
          </div>
        </div>
        <div>
          <label className={label} htmlFor="hash">Hash name</label>
          <input id="hash" className={input} maxLength={250} value={f.hashName} onChange={set("hashName")} />
        </div>
        <div>
          <label className={lbl("email")} htmlFor="email">Email *</label>
          <input id="email" className={box("email")} type="email" inputMode="email" autoComplete="email" maxLength={250} placeholder="you@example.com" value={f.email} onChange={set("email")} />
          <p className="mt-1 text-xs text-zinc-500">We send a code here to confirm it is you.</p>
        </div>
      </fieldset>

      <fieldset className="space-y-3">
        <legend className="mb-2 text-lg font-bold">A few questions <span className="text-sm font-normal text-zinc-500">(optional)</span></legend>
        <div className="grid gap-3 sm:grid-cols-2">
          <div>
            <label className={label} htmlFor="rpm">Runs per month</label>
            <input id="rpm" className={input} maxLength={50} value={f.runsPerMonth} onChange={set("runsPerMonth")} />
          </div>
          <div>
            <label className={label} htmlFor="hpr">Hashers per run</label>
            <input id="hpr" className={input} maxLength={50} value={f.hashersPerRun} onChange={set("hashersPerRun")} />
          </div>
          <div>
            <label className={label} htmlFor="next">Your next run number</label>
            <input id="next" className={input} maxLength={250} value={f.nextRunNumber} onChange={set("nextRunNumber")} />
          </div>
        </div>
        <div>
          <label className={label} htmlFor="how">How did you hear about Harrier Central?</label>
          <input id="how" className={input} maxLength={4000} value={f.howDidYouLearn} onChange={set("howDidYouLearn")} />
        </div>
        <div>
          <label className={label} htmlFor="comments">Anything else?</label>
          <textarea id="comments" className={input} rows={3} maxLength={4000} value={f.comments} onChange={set("comments")} />
        </div>
      </fieldset>

      <fieldset className="space-y-4">
        <legend className="mb-2 text-lg font-bold">Terms &amp; conditions *</legend>
        {TERMS.map((q, i) => (
          <div key={q.title} className={`rounded-xl border bg-zinc-50 p-4 ${bad(`terms${i + 1}`) ? "border-red-500 ring-1 ring-red-500" : "border-zinc-200"}`}>
            <p className="text-sm text-zinc-700">
              <strong className={bad(`terms${i + 1}`) ? "text-red-600" : undefined}>{q.title}</strong> {q.text}
            </p>
            <div className="mt-3 flex flex-col gap-2">
              {q.options.map((o) => (
                <label key={o} className="flex cursor-pointer items-start gap-2 text-sm text-zinc-800">
                  <input
                    type="radio"
                    name={`terms${i + 1}`}
                    className="mt-0.5 h-4 w-4 flex-none accent-orange-500"
                    checked={terms[i] === o}
                    onChange={() => setTerms((prev) => prev.map((t, j) => (j === i ? o : t)))}
                  />
                  {o}
                </label>
              ))}
            </div>
          </div>
        ))}
      </fieldset>

      {/* What is wrong sits beside the button, where the eye already is —
          not at the top of a long form (James, 2026-09-28). */}
      {tried && problems.length > 0 && (
        <p role="alert" className="rounded-lg bg-red-50 px-3 py-2 text-center text-sm font-medium text-red-700">
          Please fill in the fields marked in red: {problems.map(([, n]) => n).join(", ")}.
        </p>
      )}
      {error && <p role="alert" className="rounded-lg bg-red-50 px-3 py-2 text-center text-sm text-red-700">{error}</p>}
      <button type="submit" className={primaryBtn} disabled={busy}>
        {busy ? "Sending…" : "Send my request"}
      </button>
      <p className="text-center text-xs text-zinc-500">* required</p>
    </form>
  );
}
