export interface MockRun {
  id: string;
  number: number;
  title: string;
  date: string;
  time: string;
  dayOfWeek: string;
  location: string;
  postcode: string;
  hares: string[];
  style: string;
  onAfterPub: string;
  onAfterAddress: string;
  difficulty: "Easy" | "Medium" | "Hard" | "Night Run" | "Pub Crawl";
  heroImageId: string;
  daysUntil: number;
  description: string;
}

export const MOCK_RUNS: MockRun[] = [
  {
    id: "run-1843",
    number: 1843,
    title: "Skyline Shiggy",
    date: "Saturday, 29 March 2026",
    time: "14:00",
    dayOfWeek: "Saturday",
    location: "Hampstead Heath",
    postcode: "NW3 2QB",
    hares: ["On-In", "Tigger"],
    style: "Long / Short",
    onAfterPub: "The Flask",
    onAfterAddress: "14 Flask Walk, NW3 1HE",
    difficulty: "Hard",
    heroImageId: "photo-1517836357463-d25dfeac3438",
    daysUntil: 3,
    description: "A proper shiggy bash through the heath. Expect mud, surprise water crossings, and at least one false trail that will make you question your life choices. Both long and short options. Meet at the Parliament Hill entrance.",
  },
  {
    id: "run-1844",
    number: 1844,
    title: "Red Dress Trail",
    date: "Wednesday, 2 April 2026",
    time: "19:00",
    dayOfWeek: "Wednesday",
    location: "South Bank",
    postcode: "SE1 9PP",
    hares: ["Hash Flash", "Wanker"],
    style: "Pub Crawl",
    onAfterPub: "The Anchor",
    onAfterAddress: "34 Park St, SE1 9EF",
    difficulty: "Pub Crawl",
    heroImageId: "photo-1476480862126-209bfaa8edc8",
    daysUntil: 7,
    description: "Annual Red Dress run along the South Bank. Dress code strictly enforced: red dresses only. Yes, all genders. Especially you.",
  },
  {
    id: "run-1845",
    number: 1845,
    title: "Full Moon Hash",
    date: "Friday, 4 April 2026",
    time: "20:00",
    dayOfWeek: "Friday",
    location: "Richmond Park",
    postcode: "TW10 5HS",
    hares: ["GPS God", "Early Bird"],
    style: "Night Run",
    onAfterPub: "The Dysart Arms",
    onAfterAddress: "135 Petersham Rd, TW10 7AA",
    difficulty: "Night Run",
    heroImageId: "photo-1501854140801-50d01698950b",
    daysUntil: 9,
    description: "Torches required. Headtorches preferred. Following deer tracks by moonlight across Richmond Park — what could possibly go wrong?",
  },
  {
    id: "run-1846",
    number: 1846,
    title: "Easter Egg Hunt Hash",
    date: "Sunday, 6 April 2026",
    time: "11:00",
    dayOfWeek: "Sunday",
    location: "Victoria Park",
    postcode: "E9 7BT",
    hares: ["Eggs Benedict", "Cracker"],
    style: "Family Run",
    onAfterPub: "The Crown",
    onAfterAddress: "223 Grove Rd, E3 5SN",
    difficulty: "Easy",
    heroImageId: "photo-1441974231531-c6227db76b6e",
    daysUntil: 11,
    description: "Family-friendly Easter special. Chocolate eggs hidden along the trail. Children and dogs welcome. Adults must still wear silly hats.",
  },
];

export const MOCK_PHOTOS = [
  { id: "photo-1517836357463-d25dfeac3438", caption: "Run 1840 · Parliament Hill" },
  { id: "photo-1476480862126-209bfaa8edc8", caption: "Run 1839 · South Bank" },
  { id: "photo-1501854140801-50d01698950b", caption: "Run 1838 · Richmond" },
  { id: "photo-1441974231531-c6227db76b6e", caption: "Run 1837 · Victoria Park" },
  { id: "photo-1486218119243-13883505764c", caption: "Run 1836 · Epping Forest" },
  { id: "photo-1547347298-4074fc3086f0", caption: "Run 1835 · Primrose Hill" },
];
