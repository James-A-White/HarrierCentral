import {
  ArrowRight, ChevronRight, ExternalLink,
  Music, Route, MapPin, Calendar, BarChart2, TrendingUp,
  Info, Users, UserPlus,
  Mail, Phone, Globe,
  Download, Plus, Star, Heart, Share2,
} from "lucide-react";
import type { LucideIcon } from "lucide-react";

export const ICON_LIST: { name: string; Icon: LucideIcon; label: string }[] = [
  { name: "ArrowRight",   Icon: ArrowRight,   label: "Arrow right"   },
  { name: "ChevronRight", Icon: ChevronRight,  label: "Chevron"       },
  { name: "ExternalLink", Icon: ExternalLink,  label: "External link" },
  { name: "Music",        Icon: Music,         label: "Songs"         },
  { name: "Route",        Icon: Route,         label: "Runs / trails" },
  { name: "MapPin",       Icon: MapPin,        label: "Location"      },
  { name: "Calendar",     Icon: Calendar,      label: "Events"        },
  { name: "BarChart2",    Icon: BarChart2,     label: "Stats"         },
  { name: "TrendingUp",   Icon: TrendingUp,    label: "Trending"      },
  { name: "Info",         Icon: Info,          label: "About"         },
  { name: "Users",        Icon: Users,         label: "People"        },
  { name: "UserPlus",     Icon: UserPlus,      label: "Join"          },
  { name: "Mail",         Icon: Mail,          label: "Email"         },
  { name: "Phone",        Icon: Phone,         label: "Phone"         },
  { name: "Globe",        Icon: Globe,         label: "Website"       },
  { name: "Download",     Icon: Download,      label: "Download"      },
  { name: "Plus",         Icon: Plus,          label: "Plus"          },
  { name: "Star",         Icon: Star,          label: "Star"          },
  { name: "Heart",        Icon: Heart,         label: "Heart"         },
  { name: "Share2",       Icon: Share2,        label: "Share"         },
];

export const ICON_MAP: Record<string, LucideIcon> = Object.fromEntries(
  ICON_LIST.map(({ name, Icon }) => [name, Icon])
);
