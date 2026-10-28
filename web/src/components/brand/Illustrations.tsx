// On-brand animated SVG illustrations for the auth panel and onboarding.
// The auth scene uses fixed colours (it always sits on the navy panel); the
// onboarding scenes use theme tokens so they work in light and dark.

import { cn } from "@/lib/utils/cn";

const PAPER = "#F7F4EE";
const CORAL = "#E7623C";
const INKLINE = "#C8C2B4";

function Sparkle({
  x,
  y,
  s = 6,
  delay = 0,
  fill = CORAL,
}: {
  x: number;
  y: number;
  s?: number;
  delay?: number;
  fill?: string;
}) {
  return (
    <path
      d={`M${x} ${y - s} C ${x} ${y - s * 0.25} ${x + s * 0.25} ${y} ${x + s} ${y} C ${x + s * 0.25} ${y} ${x} ${y + s * 0.25} ${x} ${y + s} C ${x} ${y + s * 0.25} ${x - s * 0.25} ${y} ${x - s} ${y} C ${x - s * 0.25} ${y} ${x} ${y - s * 0.25} ${x} ${y - s} Z`}
      fill={fill}
      style={{
        transformOrigin: `${x}px ${y}px`,
        animation: `twinkle 2.4s ease-in-out ${delay}s infinite`,
      }}
    />
  );
}

/* ---------------- Auth panel scene (fixed colours on navy) --------------- */

export function AuthIllustration({ className }: { className?: string }) {
  const chips: Array<[number, number, string, number, number]> = [
    // x, y, color, width, delay
    [40, 96, "#2A9D8F", 66, 0],
    [176, 70, "#7C5CD3", 54, 1.1],
    [96, 54, CORAL, 48, 2.2],
    [182, 150, "#3B82C4", 58, 1.7],
  ];
  return (
    <svg
      viewBox="0 0 300 300"
      className={cn("h-auto w-full max-w-[340px]", className)}
      role="img"
      aria-label="Scan a page and it becomes flashcards"
    >
      <defs>
        <linearGradient id="auth-scan" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor={CORAL} stopOpacity="0" />
          <stop offset="50%" stopColor={CORAL} stopOpacity="1" />
          <stop offset="100%" stopColor={CORAL} stopOpacity="0" />
        </linearGradient>
        <clipPath id="auth-card-clip">
          <rect x="88" y="104" width="124" height="150" rx="14" />
        </clipPath>
      </defs>

      {/* soft glow */}
      <circle cx="150" cy="168" r="120" fill="#ffffff" opacity="0.04" />

      {/* floating word chips */}
      {chips.map(([x, y, c, w, d], i) => (
        <g key={i} style={{ animation: `drift-up 4.2s ease-in-out ${d}s infinite` }}>
          <rect x={x} y={y} width={w} height="18" rx="9" fill={c} />
          <rect x={x + 9} y={y + 7} width={w - 26} height="4" rx="2" fill="#ffffff" opacity="0.8" />
        </g>
      ))}

      {/* back card */}
      <g transform="rotate(-7 150 180)">
        <rect x="96" y="120" width="124" height="150" rx="14" fill={PAPER} opacity="0.5" />
      </g>

      {/* front flashcard */}
      <g style={{ transformOrigin: "150px 180px", animation: "bob 5s ease-in-out infinite" }}>
        <rect x="88" y="104" width="124" height="150" rx="14" fill={PAPER} />
        {/* coral folded corner — logo motif */}
        <path d="M212 104 L212 128 L188 104 Z" fill={CORAL} />
        {/* text lines */}
        <rect x="104" y="134" width="70" height="7" rx="3.5" fill={INKLINE} />
        <rect x="104" y="150" width="92" height="7" rx="3.5" fill={CORAL} opacity="0.9" />
        <rect x="104" y="166" width="80" height="7" rx="3.5" fill={INKLINE} />
        <rect x="104" y="188" width="90" height="7" rx="3.5" fill={INKLINE} />
        <rect x="104" y="204" width="60" height="7" rx="3.5" fill={INKLINE} />
        <rect x="104" y="226" width="84" height="7" rx="3.5" fill={INKLINE} />

        {/* sweeping scan bar, clipped to the card */}
        <g clipPath="url(#auth-card-clip)">
          <g style={{ animation: "scan-sweep 3.4s ease-in-out infinite" }}>
            <rect x="92" y="172" width="116" height="14" rx="7" fill="url(#auth-scan)" opacity="0.55" />
            <rect x="96" y="178" width="108" height="3.5" rx="1.75" fill={CORAL} />
          </g>
        </g>
      </g>

      <Sparkle x={66} y={150} s={7} delay={0.3} fill="#F3BC6A" />
      <Sparkle x={236} y={120} s={6} delay={1.2} fill="#ffffff" />
      <Sparkle x={244} y={210} s={5} delay={2} fill={CORAL} />
    </svg>
  );
}

/* ---------------- Onboarding scenes (theme tokens) ----------------------- */

const card = "rgb(var(--card))";
const line = "rgb(var(--border))";
const ink = "rgb(var(--ink))";
const muted = "rgb(var(--ink-muted))";
const coral = "rgb(var(--coral))";

function hue(name: string) {
  return `rgb(var(--hue-${name}))`;
}

function Backdrop({ color }: { color: string }) {
  return (
    <>
      <circle cx="100" cy="100" r="86" fill={color} opacity="0.12" />
      <circle cx="100" cy="100" r="62" fill={color} opacity="0.08" />
    </>
  );
}

const svgProps = {
  viewBox: "0 0 200 200",
  className: "h-full w-full",
  role: "img" as const,
};

/** 1 · Scan anything — a document under a camera viewfinder with a scan bar. */
export function ScanScene() {
  return (
    <svg {...svgProps} aria-label="Scan anything">
      <Backdrop color={coral} />
      <defs>
        <clipPath id="ob-scan-clip">
          <rect x="66" y="56" width="68" height="88" rx="10" />
        </clipPath>
        <linearGradient id="ob-scan-grad" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor={coral} stopOpacity="0" />
          <stop offset="50%" stopColor={coral} stopOpacity="0.9" />
          <stop offset="100%" stopColor={coral} stopOpacity="0" />
        </linearGradient>
      </defs>

      <g style={{ transformOrigin: "100px 100px", animation: "bob 5s ease-in-out infinite" }}>
        <rect x="66" y="56" width="68" height="88" rx="10" fill={card} stroke={line} strokeWidth="2" />
        <rect x="78" y="72" width="34" height="5" rx="2.5" fill={muted} />
        <rect x="78" y="84" width="44" height="5" rx="2.5" fill={coral} />
        <rect x="78" y="96" width="38" height="5" rx="2.5" fill={muted} />
        <rect x="78" y="112" width="44" height="5" rx="2.5" fill={muted} />
        <rect x="78" y="124" width="28" height="5" rx="2.5" fill={muted} />
        <g clipPath="url(#ob-scan-clip)">
          <rect
            x="62"
            y="92"
            width="76"
            height="16"
            fill="url(#ob-scan-grad)"
            style={{ animation: "scan-sweep 3s ease-in-out infinite" }}
          />
        </g>
      </g>

      {/* viewfinder corners */}
      {[
        [54, 44, 1, 1],
        [146, 44, -1, 1],
        [54, 156, 1, -1],
        [146, 156, -1, -1],
      ].map(([x, y, sx, sy], i) => (
        <path
          key={i}
          d={`M${x} ${y + 16 * sy} L${x} ${y} L${x + 16 * sx} ${y}`}
          fill="none"
          stroke={coral}
          strokeWidth="4"
          strokeLinecap="round"
        />
      ))}
    </svg>
  );
}

/** 2 · We find the words — words lifting out of a page as chips. */
export function WordsScene() {
  const chips: Array<[number, number, string, number]> = [
    [112, 54, hue("violet"), 0],
    [122, 80, coral, 0.9],
    [106, 104, hue("teal"), 1.8],
  ];
  return (
    <svg {...svgProps} aria-label="We find the words worth learning">
      <Backdrop color={hue("violet")} />
      <g style={{ transformOrigin: "80px 104px", animation: "bob 5.5s ease-in-out infinite" }}>
        <rect x="48" y="58" width="60" height="84" rx="9" fill={card} stroke={line} strokeWidth="2" />
        <rect x="58" y="74" width="30" height="5" rx="2.5" fill={muted} />
        <rect x="58" y="86" width="40" height="5" rx="2.5" fill={muted} />
        <rect x="58" y="98" width="34" height="5" rx="2.5" fill={muted} />
        <rect x="58" y="114" width="40" height="5" rx="2.5" fill={muted} />
        <rect x="58" y="126" width="26" height="5" rx="2.5" fill={muted} />
      </g>
      {chips.map(([x, y, c, d], i) => (
        <g key={i} style={{ transformOrigin: `${x}px ${y}px`, animation: `drift-up 3.6s ease-in-out ${d}s infinite` }}>
          <rect x={x} y={y} width="54" height="20" rx="10" fill={c} />
          <rect x={x + 10} y={y + 8} width="34" height="5" rx="2.5" fill="#fff" opacity="0.85" />
        </g>
      ))}
      <Sparkle x={150} y={118} s={6} delay={0.6} fill={coral} />
    </svg>
  );
}

/** 3 · Example sentences — a flashcard with a speech bubble + sound waves. */
export function SentencesScene() {
  return (
    <svg {...svgProps} aria-label="Learn with example sentences you can hear">
      <Backdrop color={hue("teal")} />
      <g style={{ transformOrigin: "100px 118px", animation: "bob 5s ease-in-out infinite" }}>
        <rect x="46" y="94" width="108" height="64" rx="12" fill={card} stroke={line} strokeWidth="2" />
        <text x="62" y="126" fill={ink} fontFamily="'Baloo 2', sans-serif" fontWeight="700" fontSize="18">
          hola
        </text>
        <rect x="62" y="134" width="54" height="5" rx="2.5" fill={coral} />
        {/* sound waves */}
        {[0, 1, 2].map((i) => (
          <rect
            key={i}
            x={126 + i * 9}
            y={116}
            width="5"
            height="20"
            rx="2.5"
            fill={hue("teal")}
            style={{
              transformOrigin: `${128 + i * 9}px 126px`,
              animation: `wiggle 0.9s ease-in-out ${i * 0.15}s infinite alternate`,
            }}
          />
        ))}
      </g>
      {/* speech bubble */}
      <g style={{ transformOrigin: "120px 60px", animation: "pop-soft 0.6s ease-out both, bob 4.5s ease-in-out 0.6s infinite" }}>
        <rect x="70" y="40" width="96" height="40" rx="12" fill={hue("teal")} />
        <path d="M86 78 L86 92 L100 78 Z" fill={hue("teal")} />
        <rect x="80" y="52" width="60" height="5" rx="2.5" fill="#fff" opacity="0.9" />
        <rect x="80" y="63" width="44" height="5" rx="2.5" fill="#fff" opacity="0.6" />
      </g>
    </svg>
  );
}

/** 4 · Study & streak — a flashcard with a check and a streak flame. */
export function StudyScene() {
  return (
    <svg {...svgProps} aria-label="Study with spaced repetition and keep a streak">
      <Backdrop color={coral} />
      {/* back cards */}
      <rect x="58" y="74" width="84" height="96" rx="12" fill={card} stroke={line} strokeWidth="2" transform="rotate(-8 100 120)" opacity="0.6" />
      <g style={{ transformOrigin: "100px 118px", animation: "bob 5s ease-in-out infinite" }}>
        <rect x="56" y="66" width="88" height="98" rx="12" fill={card} stroke={line} strokeWidth="2" />
        <rect x="70" y="84" width="42" height="6" rx="3" fill={muted} />
        <rect x="70" y="98" width="58" height="6" rx="3" fill={coral} />
        {/* check badge */}
        <circle cx="100" cy="134" r="18" fill={hue("moss")} />
        <path
          d="M91 134 l6 6 l12 -13"
          fill="none"
          stroke="#fff"
          strokeWidth="4"
          strokeLinecap="round"
          strokeLinejoin="round"
          style={{ strokeDasharray: 40, "--len": 40, animation: "draw-in 0.8s ease-out 0.3s both" } as React.CSSProperties}
        />
      </g>
      {/* streak flame */}
      <g style={{ transformOrigin: "150px 72px", animation: "pop-soft 0.6s ease-out 0.4s both, bob 3.6s ease-in-out 1s infinite" }}>
        <circle cx="150" cy="66" r="22" fill={coral} />
        <path
          d="M150 54 c3 6 -4 7 -4 12 0 3 2 5 4 5 s4 -2 4 -5 c0 -2 -1 -3 -1 -3 2 1 3 3 3 5 0 4 -3 7 -6 7 -4 0 -7 -3 -7 -7 0 -5 4 -8 7 -14 Z"
          fill="#fff"
        />
      </g>
      <Sparkle x={54} y={54} s={6} delay={0.8} fill={hue("amber")} />
    </svg>
  );
}
