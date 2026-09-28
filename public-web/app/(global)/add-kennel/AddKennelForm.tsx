"use client";

import { useEffect, useState } from "react";
import type { Place } from "@/lib/api";

const input =
  "w-full rounded-lg border border-zinc-300 bg-white px-3 py-2.5 text-base text-zinc-900 placeholder:text-zinc-400 focus:outline-none focus:ring-2 focus:ring-orange-400 disabled:bg-zinc-100";
const label = "mb-1 block text-sm font-medium text-zinc-700";
const primaryBtn =
  "inline-flex w-full items-center justify-center rounded-full bg-orange-500 px-5 py-3 text-center text-base font-semibold text-white transition-opacity hover:opacity-90 disabled:opacity-50";
const linkBtn = "text-sm text-zinc-600 underline underline-offset-2 hover:text-zinc-900";

type Step = { kind: "form" } | { kind: "code"; requestId: string | null; again: boolean } | { kind: "done"; already: boolean };

const EMPTY = {
  firstName: "", lastName: "", hashName: "", email: "",
  kennelName: "", kennelShortName: "", kennelDescription: "", kennelUrl: "", kennelFacebookUrl: "",
  countryId: "", regionId: "", cityId: "", cityText: "",
  runsPerMonth: "", hashersPerRun: "", hashCash: "", nextRunNumber: "", howDidYouLearn: "", comments: "",
};
type Fields = typeof EMPTY;

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
  const [step, setStep] = useState<Step>({ kind: "form" });
  const [code, setCode] = useState("");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const regions = usePlaces("countryId", f.countryId);
  const cities = usePlaces("regionId", f.regionId);

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
  const ready =
    f.firstName.trim() && f.lastName.trim() && f.email.trim() && f.kennelName.trim() &&
    f.kennelShortName && f.kennelDescription.trim() && placeOk;

  async function submit() {
    setBusy(true);
    setError(null);
    try {
      const r = await post<{ requestId: string | null; alreadySubmitted: boolean; codeSent: boolean }>("/api/kennel-request", {
        ...f,
        cityId: cityNotListed ? "" : f.cityId,
        cityText: cityNotListed ? f.cityText : "",
        stamp,
        website: honeypot,
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
    <form className={`${panel} space-y-6`} onSubmit={(e) => { e.preventDefault(); if (!busy && ready) void submit(); }}>
      {errorBox}

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
          <label className={label} htmlFor="kennelName">Kennel name *</label>
          <input id="kennelName" className={input} maxLength={250} placeholder="London Hash House Harriers" value={f.kennelName} onChange={set("kennelName")} />
        </div>
        <div>
          <label className={label} htmlFor="shortName">Short name *</label>
          <input id="shortName" className={input} placeholder="LH3" value={f.kennelShortName} onChange={setShortName} />
          <p className="mt-1 text-xs text-zinc-500">
            Letters and digits. Your page will be at hashruns.org/{(f.kennelShortName || "lh3").toLowerCase()} (or close to it
            if the name is taken).
          </p>
        </div>
        <div>
          <label className={label} htmlFor="desc">Tell hashers about the kennel *</label>
          <textarea id="desc" className={input} rows={4} maxLength={4000} placeholder="When and where you run, what to expect…" value={f.kennelDescription} onChange={set("kennelDescription")} />
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
          <label className={label} htmlFor="country">Country *</label>
          <select id="country" className={input} value={f.countryId} onChange={pickCountry}>
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
              <label className={label} htmlFor="cityText">City or town *</label>
              <input id="cityText" className={input} maxLength={50} value={f.cityText} onChange={set("cityText")} />
              {f.regionId && (
                <button type="button" className={`${linkBtn} mt-1`} onClick={() => setCityNotListed(false)}>
                  Pick from the list instead
                </button>
              )}
            </div>
          ) : (
            <div>
              <label className={label} htmlFor="city">City or town *</label>
              <select id="city" className={input} value={f.cityId} onChange={set("cityId")} disabled={cities.loading}>
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
        <legend className="mb-2 text-lg font-bold">About you</legend>
        <p className="text-sm text-zinc-600">You become the kennel&rsquo;s admin in Harrier Central, and can add others later.</p>
        <div className="grid gap-3 sm:grid-cols-2">
          <div>
            <label className={label} htmlFor="first">First name *</label>
            <input id="first" className={input} autoComplete="given-name" maxLength={250} value={f.firstName} onChange={set("firstName")} />
          </div>
          <div>
            <label className={label} htmlFor="last">Last name *</label>
            <input id="last" className={input} autoComplete="family-name" maxLength={250} value={f.lastName} onChange={set("lastName")} />
          </div>
        </div>
        <div>
          <label className={label} htmlFor="hash">Hash name</label>
          <input id="hash" className={input} maxLength={250} value={f.hashName} onChange={set("hashName")} />
        </div>
        <div>
          <label className={label} htmlFor="email">Email *</label>
          <input id="email" className={input} type="email" inputMode="email" autoComplete="email" maxLength={250} placeholder="you@example.com" value={f.email} onChange={set("email")} />
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
            <label className={label} htmlFor="cash">Hash cash (price of a run)</label>
            <input id="cash" className={input} maxLength={50} placeholder="5" value={f.hashCash} onChange={set("hashCash")} />
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

      <button type="submit" className={primaryBtn} disabled={busy || !ready}>
        {busy ? "Sending…" : "Send my request"}
      </button>
      <p className="text-center text-xs text-zinc-500">* required</p>
    </form>
  );
}
