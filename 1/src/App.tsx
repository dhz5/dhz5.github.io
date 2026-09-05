import { useState, useMemo, useRef, useEffect } from "react";
import { categories, type Tip, type Category } from "./data/tips";

// ─── helpers ────────────────────────────────────────────────────────────────
function highlight(text: string, q: string) {
  if (!q.trim()) return <>{text}</>;
  const regex = new RegExp(`(${q.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")})`, "gi");
  const parts = text.split(regex);
  return (
    <>
      {parts.map((p, i) =>
        regex.test(p) ? (
          <mark key={i} className="bg-yellow-400/40 text-yellow-200 rounded px-0.5">
            {p}
          </mark>
        ) : (
          p
        )
      )}
    </>
  );
}

function typeBadge(type: Tip["type"]) {
  const map: Record<Tip["type"], { label: string; cls: string }> = {
    cmd: { label: "CMD", cls: "bg-gray-700 text-gray-200 border-gray-600" },
    powershell: { label: "PowerShell", cls: "bg-blue-900/60 text-blue-300 border-blue-700" },
    run: { label: "Win+R", cls: "bg-violet-900/60 text-violet-300 border-violet-700" },
    app: { label: "Phần mềm", cls: "bg-emerald-900/60 text-emerald-300 border-emerald-700" },
    web: { label: "Website", cls: "bg-sky-900/60 text-sky-300 border-sky-700" },
    shortcut: { label: "Phím tắt", cls: "bg-orange-900/60 text-orange-300 border-orange-700" },
    android: { label: "Android", cls: "bg-green-900/60 text-green-300 border-green-700" },
    mac: { label: "MacBook", cls: "bg-zinc-700 text-zinc-200 border-zinc-600" },
  };
  const { label, cls } = map[type] ?? map.cmd;
  return (
    <span className={`text-[10px] font-bold px-2 py-0.5 rounded-full border uppercase tracking-wider ${cls}`}>
      {label}
    </span>
  );
}

// ─── Copy button ─────────────────────────────────────────────────────────────
function CopyBtn({ text }: { text: string }) {
  const [copied, setCopied] = useState(false);
  const copy = () => {
    navigator.clipboard.writeText(text).catch(() => {});
    setCopied(true);
    setTimeout(() => setCopied(false), 1800);
  };
  return (
    <button
      onClick={copy}
      title="Copy"
      className="ml-2 shrink-0 p-1 rounded text-gray-500 hover:text-gray-200 hover:bg-white/10 transition-all"
    >
      {copied ? (
        <svg className="w-3.5 h-3.5 text-green-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
        </svg>
      ) : (
        <svg className="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z" />
        </svg>
      )}
    </button>
  );
}

// ─── Tip Card ─────────────────────────────────────────────────────────────────
function TipCard({ tip, q, cat }: { tip: Tip; q: string; cat: Category }) {
  const [open, setOpen] = useState(false);

  return (
    <div
      className={`rounded-xl border bg-gray-800/60 hover:bg-gray-800 transition-all duration-200 ${cat.border} hover:border-opacity-70`}
    >
      {/* Header */}
      <button
        className="w-full text-left p-4 flex items-start gap-3"
        onClick={() => setOpen((o) => !o)}
      >
        <span className="text-xl mt-0.5 shrink-0">{cat.icon}</span>
        <div className="flex-1 min-w-0">
          <div className="flex flex-wrap items-center gap-2 mb-1">
            <span className="font-semibold text-gray-100 text-sm leading-snug">
              {highlight(tip.title, q)}
            </span>
            {typeBadge(tip.type)}
          </div>

          {/* Command preview */}
          {tip.command && (
            <code className={`text-xs font-mono ${cat.color} opacity-80`}>
              {highlight(tip.command, q)}
            </code>
          )}
          {tip.commands && (
            <div className="flex flex-wrap gap-2">
              {tip.commands.map((c) => (
                <code key={c.label} className={`text-xs font-mono ${cat.color} opacity-80`}>
                  {highlight(c.code, q)}
                </code>
              ))}
            </div>
          )}
        </div>
        <span className={`shrink-0 mt-0.5 transition-transform duration-200 text-gray-500 ${open ? "rotate-180" : ""}`}>
          ▾
        </span>
      </button>

      {/* Expandable body */}
      {open && (
        <div className="px-4 pb-4 space-y-3 border-t border-white/5 pt-3">
          {/* Description */}
          <p className="text-gray-300 text-sm leading-relaxed">
            {highlight(tip.description, q)}
          </p>

          {/* Command block(s) */}
          {tip.command && (
  tip.type === "web" ? (
    <a
      href={tip.command}
      target="_blank"
      rel="noopener noreferrer"
      onClick={(e) => e.stopPropagation()}
      className="block rounded-lg bg-gray-900/80 border border-gray-700 overflow-hidden hover:border-sky-500/50 hover:bg-gray-900 transition-all group"
    >
      <div className="flex items-center justify-between px-3 py-1.5 border-b border-gray-700 bg-gray-900">
        <span className="text-[10px] text-gray-500 font-mono uppercase tracking-widest">
          website
        </span>

        <svg
          className="w-3.5 h-3.5 text-gray-500 group-hover:text-sky-400 transition-colors"
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
        >
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            strokeWidth={2}
            d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14"
          />
        </svg>
      </div>

      <div className="px-3 py-2.5 text-sm font-mono text-sky-400 group-hover:text-sky-300 break-all">
        {highlight(tip.command, q)}
      </div>
    </a>
  ) : (
    <div className="rounded-lg bg-gray-900/80 border border-gray-700 overflow-hidden">
      <div className="flex items-center justify-between px-3 py-1.5 border-b border-gray-700 bg-gray-900">
        <span className="text-[10px] text-gray-500 font-mono uppercase tracking-widest">
          lệnh
        </span>
        <CopyBtn text={tip.command} />
      </div>

      <pre
        className={`px-3 py-2.5 text-sm font-mono ${cat.color} overflow-x-auto whitespace-pre-wrap break-all`}
      >
        {tip.command}
      </pre>
    </div>
  )
)}


          {tip.commands && (
            <div className="space-y-2">
              {tip.commands.map((c) => (
                <div key={c.label} className="rounded-lg bg-gray-900/80 border border-gray-700 overflow-hidden">
                  <div className="flex items-center justify-between px-3 py-1.5 border-b border-gray-700 bg-gray-900">
                    <span className="text-[10px] text-gray-500 font-mono uppercase tracking-widest">{c.label}</span>
                    <CopyBtn text={c.code} />
                  </div>
                  <pre className={`px-3 py-2.5 text-sm font-mono ${cat.color} overflow-x-auto whitespace-pre-wrap break-all`}>
                    {c.code}
                  </pre>
                </div>
              ))}
            </div>
          )}

          {/* Usage */}
          {tip.usage && (
            <div className={`flex gap-2 p-3 rounded-lg ${cat.bg} border ${cat.border}`}>
              <span className="shrink-0 text-sm">💡</span>
              <p className="text-xs text-gray-300 leading-relaxed">
                <span className="font-semibold text-gray-200">Cách dùng: </span>
                {highlight(tip.usage, q)}
              </p>
            </div>
          )}

          {/* Tags */}
          <div className="flex flex-wrap gap-1.5 pt-1">
            {tip.tags.map((tag) => (
              <span
                key={tag}
                className="text-[10px] px-2 py-0.5 rounded-full bg-gray-700/60 text-gray-400 border border-gray-600/40"
              >
                #{tag}
              </span>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}

// ─── Category Section ──────────────────────────────────────────────────────
function CategorySection({
  cat,
  tips,
  q,
}: {
  cat: Category;
  tips: Tip[];
  q: string;
}) {
  if (tips.length === 0) return null;
  return (
    <div id={`cat-${cat.id}`} className="scroll-mt-24">
      <div className={`flex items-center gap-3 mb-4 pb-2 border-b border-white/10`}>
        <div className={`w-9 h-9 rounded-xl flex items-center justify-center text-xl ${cat.bg} border ${cat.border}`}>
          {cat.icon}
        </div>
        <div>
          <h2 className={`font-bold text-base ${cat.color}`}>{cat.label}</h2>
          <p className="text-xs text-gray-500">{tips.length} mẹo</p>
        </div>
      </div>
      <div className="grid sm:grid-cols-2 xl:grid-cols-3 gap-3">
        {tips.map((tip) => (
          <TipCard key={tip.id} tip={tip} q={q} cat={cat} />
        ))}
      </div>
    </div>
  );
}

// ─── Sidebar ──────────────────────────────────────────────────────────────
function Sidebar({
  results,
  activeId,
}: {
  results: { cat: Category; tips: Tip[] }[];
  activeId: string;
}) {
  return (
    <aside className="hidden lg:block w-56 shrink-0 sticky top-20 self-start max-h-[calc(100vh-5rem)] overflow-y-auto pr-1 scrollbar-thin">
      <p className="text-xs font-bold uppercase tracking-widest text-gray-500 mb-3 px-2">Danh mục</p>
      <nav className="space-y-0.5">
        {results.map(({ cat, tips }) => (
          <a
            key={cat.id}
            href={`#cat-${cat.id}`}
            onClick={(e) => {
              e.preventDefault();
              document.getElementById(`cat-${cat.id}`)?.scrollIntoView({ behavior: "smooth", block: "start" });
            }}
            className={`flex items-center gap-2.5 px-2.5 py-2 rounded-lg text-sm transition-all group ${
              activeId === cat.id
                ? `${cat.bg} ${cat.color} border ${cat.border}`
                : "text-gray-400 hover:text-gray-200 hover:bg-white/5"
            }`}
          >
            <span className="text-base">{cat.icon}</span>
            <span className="flex-1 leading-tight font-medium">{cat.label}</span>
            <span
              className={`text-xs px-1.5 py-0.5 rounded-full ${
                activeId === cat.id ? cat.bg : "bg-gray-700/60"
              } ${activeId === cat.id ? cat.color : "text-gray-500"}`}
            >
              {tips.length}
            </span>
          </a>
        ))}
      </nav>
    </aside>
  );
}

// ─── Search bar ───────────────────────────────────────────────────────────
function SearchBar({ q, setQ }: { q: string; setQ: (v: string) => void }) {
  const ref = useRef<HTMLInputElement>(null);

  useEffect(() => {
    const handler = (e: KeyboardEvent) => {
      if ((e.ctrlKey || e.metaKey) && e.key === "k") {
        e.preventDefault();
        ref.current?.focus();
      }
      if (e.key === "Escape") ref.current?.blur();
    };
    window.addEventListener("keydown", handler);
    return () => window.removeEventListener("keydown", handler);
  }, []);

  return (
    <div className="relative max-w-2xl mx-auto">
      <div className="absolute inset-y-0 left-4 flex items-center pointer-events-none">
        <svg className="w-5 h-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-4.35-4.35M17 11A6 6 0 1 1 5 11a6 6 0 0 1 12 0z" />
        </svg>
      </div>
      <input
        ref={ref}
        type="text"
        value={q}
        onChange={(e) => setQ(e.target.value)}
        placeholder="Tìm kiếm mẹo, lệnh, từ khóa... (Ctrl+K)"
        className="w-full bg-gray-800 border border-gray-600 focus:border-violet-500 focus:ring-2 focus:ring-violet-500/30 rounded-xl pl-12 pr-12 py-3.5 text-gray-100 placeholder-gray-500 text-sm outline-none transition-all"
      />
      {q && (
        <button
          onClick={() => setQ("")}
          className="absolute inset-y-0 right-4 flex items-center text-gray-400 hover:text-gray-200"
        >
          <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
          </svg>
        </button>
      )}
    </div>
  );
}

// ─── Stats bar ────────────────────────────────────────────────────────────
function StatsBar() {
  const totalTips = categories.reduce((s, c) => s + c.tips.length, 0);
  const catCount = categories.length;
  return (
    <div className="flex flex-wrap justify-center gap-6 text-center">
      {[
        { value: totalTips, label: "Mẹo & Thủ thuật", icon: "💡" },
        { value: catCount, label: "Danh mục", icon: "📂" },
        { value: "100%", label: "Miễn phí", icon: "🆓" },
        { value: "∞", label: "Cập nhật mãi", icon: "🔄" },
      ].map((s) => (
        <div key={s.label} className="flex items-center gap-2 px-4 py-2 rounded-xl bg-gray-800/60 border border-gray-700">
          <span className="text-lg">{s.icon}</span>
          <div className="text-left">
            <div className="text-lg font-bold text-gray-100">{s.value}</div>
            <div className="text-xs text-gray-500">{s.label}</div>
          </div>
        </div>
      ))}
    </div>
  );
}

// ─── Main App ─────────────────────────────────────────────────────────────
export default function App() {
  const [q, setQ] = useState("");
  const [activeId, setActiveId] = useState(categories[0].id);

  // Filter
  const results = useMemo(() => {
    const term = q.toLowerCase().trim();
    return categories.map((cat) => {
      if (!term) return { cat, tips: cat.tips };
      const tips = cat.tips.filter(
        (t) =>
          t.title.toLowerCase().includes(term) ||
          t.description.toLowerCase().includes(term) ||
          (t.command ?? "").toLowerCase().includes(term) ||
          (t.usage ?? "").toLowerCase().includes(term) ||
          t.tags.some((tag) => tag.toLowerCase().includes(term)) ||
          (t.commands ?? []).some(
            (c) => c.code.toLowerCase().includes(term) || c.label.toLowerCase().includes(term)
          )
      );
      return { cat, tips };
    });
  }, [q]);

  const totalFound = results.reduce((s, r) => s + r.tips.length, 0);

  // Scroll spy
  useEffect(() => {
    const observer = new IntersectionObserver(
      (entries) => {
        for (const entry of entries) {
          if (entry.isIntersecting) {
            setActiveId(entry.target.id.replace("cat-", ""));
          }
        }
      },
      { rootMargin: "-20% 0px -70% 0px" }
    );
    categories.forEach((cat) => {
      const el = document.getElementById(`cat-${cat.id}`);
      if (el) observer.observe(el);
    });
    return () => observer.disconnect();
  }, []);

  return (
    <div className="min-h-screen bg-gray-950 text-gray-100" style={{ fontFamily: "'Inter', sans-serif" }}>
      {/* ── Header ── */}
      <header className="sticky top-0 z-40 bg-gray-950/90 backdrop-blur border-b border-white/5">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-3 flex items-center gap-4">
          <div className="shrink-0">
            <div className="flex items-center gap-2">
              <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-violet-600 to-indigo-600 flex items-center justify-center text-base shadow-lg shadow-violet-500/30">
                💡
              </div>
              <div className="hidden sm:block">
                <div className="font-bold text-sm text-white leading-none">MẸO VẶT IT</div>
                <div className="text-[10px] text-gray-500 leading-none mt-0.5">Tips & Tricks</div>
              </div>
            </div>
          </div>

          <div className="flex-1">
            <SearchBar q={q} setQ={setQ} />
          </div>

          {q && (
            <div className="shrink-0 hidden sm:block text-xs text-gray-400 whitespace-nowrap">
              {totalFound} kết quả
            </div>
          )}
        </div>
      </header>

      {/* ── Hero ── */}
      <div className="relative overflow-hidden py-12 px-4">
        <div className="absolute inset-0 pointer-events-none">
          <div className="absolute top-0 left-1/4 w-80 h-80 bg-violet-600/10 rounded-full blur-3xl" />
          <div className="absolute bottom-0 right-1/4 w-80 h-80 bg-indigo-600/10 rounded-full blur-3xl" />
        </div>
        <div className="relative max-w-3xl mx-auto text-center space-y-4">
          <div className="inline-flex items-center gap-2 px-4 py-1.5 rounded-full border border-violet-500/30 bg-violet-500/10 text-violet-300 text-xs font-semibold">
            <span className="w-1.5 h-1.5 rounded-full bg-green-400 animate-pulse" />
            Tổng hợp mẹo vặt IT – Windows – Android – MacBook
          </div>
          <h1 className="text-3xl sm:text-4xl font-extrabold tracking-tight">
            Kho{" "}
            <span className="bg-gradient-to-r from-violet-400 via-purple-400 to-indigo-400 bg-clip-text text-transparent">
              Mẹo Vặt & Thủ Thuật
            </span>{" "}
            Máy Tính
          </h1>
          <p className="text-gray-400 text-sm sm:text-base max-w-xl mx-auto">
            Tổng hợp lệnh CMD, PowerShell, phím tắt, công cụ và website hữu ích — tìm kiếm ngay hoặc duyệt theo danh mục.
          </p>
          <StatsBar />
        </div>
      </div>

      {/* ── Body ── */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 pb-16">
        {/* Category pills (mobile) */}
        <div className="lg:hidden mb-6 flex gap-2 overflow-x-auto pb-2 scrollbar-none">
          {results.filter((r) => r.tips.length > 0).map(({ cat, tips }) => (
            <button
              key={cat.id}
              onClick={() =>
                document.getElementById(`cat-${cat.id}`)?.scrollIntoView({ behavior: "smooth", block: "start" })
              }
              className={`shrink-0 flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-semibold border transition-all ${
                activeId === cat.id
                  ? `${cat.bg} ${cat.color} ${cat.border}`
                  : "bg-gray-800 text-gray-400 border-gray-700 hover:border-gray-500"
              }`}
            >
              {cat.icon} {cat.label}
              <span className="opacity-70">({tips.length})</span>
            </button>
          ))}
        </div>

        <div className="flex gap-8">
          <Sidebar results={results} activeId={activeId} />

          <main className="flex-1 min-w-0 space-y-12">
            {q && totalFound === 0 ? (
              <div className="text-center py-20 space-y-3">
                <div className="text-5xl">🔍</div>
                <p className="text-gray-400">Không tìm thấy kết quả cho "<strong className="text-gray-200">{q}</strong>"</p>
                <p className="text-gray-600 text-sm">Thử từ khóa khác hoặc duyệt theo danh mục</p>
                <button
                  onClick={() => setQ("")}
                  className="mt-2 px-4 py-2 rounded-lg bg-violet-600/20 text-violet-300 border border-violet-600/30 text-sm hover:bg-violet-600/30 transition-all"
                >
                  Xóa tìm kiếm
                </button>
              </div>
            ) : (
              results.map(({ cat, tips }) => (
                <CategorySection key={cat.id} cat={cat} tips={tips} q={q} />
              ))
            )}
          </main>
        </div>
      </div>

      {/* ── Footer ── */}
      <footer className="border-t border-white/5 py-8 px-4 text-center">
        <p className="text-gray-600 text-xs">
          💡 Mẹo Vặt IT · Tổng hợp lệnh, công cụ và thủ thuật hữu ích · Cập nhật liên tục
        </p>
      </footer>
    </div>
  );
}
