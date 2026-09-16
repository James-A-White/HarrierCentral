/**
 * The app's light "hash foot" background, for the History pages — the app
 * draws these on Backgrounds.defaultHcBackgroundLight() rather than the
 * jungle. Sits above the layout's jungle layers and below the content.
 */
export function LightBackground() {
  return (
    <div
      className="fixed inset-0 -z-[8] bg-repeat"
      style={{ backgroundImage: "url(/images/hash_foot_background_light.png)", backgroundSize: "512px 512px", backgroundColor: "#eef7e6" }}
    />
  );
}
