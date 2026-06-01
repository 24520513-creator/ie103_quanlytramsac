import React, { useCallback, useEffect, useMemo, useState } from 'react';
import { apiGet, logoutRequest } from './lib/api';
import { getInitials } from './lib/format';
import { roleLabels } from './config';
import { AuthPage } from './screens/auth/AuthPage';
import { sectionsFor } from './screens/registry';
import { Badge } from './components/ui';
import { LogoutIcon, MenuIcon, CloseIcon, ChevronLeftIcon, ChevronRightIcon } from './components/Icons';

const LAST_SECTION_KEY = 'evcharge:lastSection';
const NAV_COLLAPSED_KEY = 'evcharge:navCollapsed';

function readHashId() {
  return window.location.hash.replace(/^#\/?/, '').trim();
}

// Restore from the URL hash first (deeplink/refresh), then the last-used section.
function initialSectionId() {
  const fromHash = readHashId();
  if (fromHash) return fromHash;
  try { return localStorage.getItem(LAST_SECTION_KEY) || ''; } catch { return ''; }
}

export default function App() {
  const [token, setToken] = useState('');
  const [authChecked, setAuthChecked] = useState(false);
  const [user, setUser] = useState(null);
  const [actions, setActions] = useState([]);
  const [activeId, setActiveId] = useState(initialSectionId);
  const [toast, setToast] = useState(null);
  const [navOpen, setNavOpen] = useState(false);
  const [navCollapsed, setNavCollapsed] = useState(() => {
    try { return localStorage.getItem(NAV_COLLAPSED_KEY) === '1'; } catch { return false; }
  });

  // Collapse the sidebar to an icon-only rail (desktop); persisted across sessions.
  const toggleNavCollapsed = useCallback(() => {
    setNavCollapsed((v) => {
      const next = !v;
      try { localStorage.setItem(NAV_COLLAPSED_KEY, next ? '1' : '0'); } catch { /* ignore */ }
      return next;
    });
  }, []);

  // User navigation: reflect the section in the URL hash so back/forward and
  // refresh keep the current screen (and bookmarks/deeplinks work).
  const navigate = useCallback((id) => {
    setActiveId(id);
    setNavOpen(false);
    const target = `#/${id}`;
    if (window.location.hash !== target) window.history.pushState(null, '', target);
  }, []);

  // Back/forward → sync the active section from the hash.
  useEffect(() => {
    const onHash = () => {
      const id = readHashId();
      if (id) setActiveId(id);
    };
    window.addEventListener('hashchange', onHash);
    return () => window.removeEventListener('hashchange', onHash);
  }, []);

  // onToast(message, tone) — tone: 'success' (default) | 'error' | 'info'.
  // Backwards compatible: a bare string is treated as success.
  const pushToast = useCallback((message, tone = 'success') => {
    if (!message) { setToast(null); return; }
    setToast({ message: String(message), tone });
  }, []);

  useEffect(() => { loadSession('').finally(() => setAuthChecked(true)); }, []);

  useEffect(() => {
    if (!toast) return undefined;
    // Errors linger so they aren't missed; success/info auto-dismiss quickly.
    const t = setTimeout(() => setToast(null), toast.tone === 'error' ? 9000 : 4000);
    return () => clearTimeout(t);
  }, [toast]);

  async function loadSession(nextToken) {
    const [catalog, me] = await Promise.all([
      apiGet('/api/actions', nextToken),
      apiGet('/api/me', nextToken)
    ]);
    setActions(catalog.actions || []);
    setUser(me.user || catalog.user || null);
  }

  async function logout() {
    await logoutRequest();
    setToken(''); setUser(null); setActions([]); setActiveId('');
    try { window.history.replaceState(null, '', window.location.pathname + window.location.search); } catch { /* ignore */ }
  }

  const sections = useMemo(
    () => (user ? sectionsFor(user.roleCode, actions) : []),
    [user, actions]
  );

  useEffect(() => {
    if (sections.length && !sections.find((s) => s.id === activeId)) {
      setActiveId(sections[0].id);
    }
  }, [sections, activeId]);

  // Persist the last valid section and normalize the URL hash (without adding
  // history entries for auto-selected/initial sections).
  useEffect(() => {
    if (!activeId || !sections.length) return;
    if (!sections.find((s) => s.id === activeId)) return;
    try { localStorage.setItem(LAST_SECTION_KEY, activeId); } catch { /* ignore */ }
    const target = `#/${activeId}`;
    if (window.location.hash !== target) window.history.replaceState(null, '', target);
  }, [activeId, sections]);

  if (!authChecked) {
    return <main className="login"><div className="loginBox"><h1>EVCharge Pro</h1><p>Đang kiểm tra phiên đăng nhập...</p></div></main>;
  }

  if (!user) {
    return <AuthPage onLogin={async (result) => {
      setToken(result.token || '');
      setUser(result.user);
      await loadSession(result.token || '');
    }} />;
  }

  const active = sections.find((s) => s.id === activeId) || sections[0];
  const grouped = groupSections(sections);

  return (
    <div className={`shell ${navCollapsed ? 'nav-collapsed' : ''}`}>
      <div className={`sidebarOverlay ${navOpen ? 'open' : ''}`} onClick={() => setNavOpen(false)} />
      <aside className={`sidebar ${navOpen ? 'open' : ''} ${navCollapsed ? 'collapsed' : ''}`}>
        <div className="brand">
          <div className="brandMark">EV</div>
          <div className="brandInfo">
            <strong>EVCharge Pro</strong>
            <span>Quản lý trạm sạc điện</span>
          </div>
          <button
            className="navCollapseBtn"
            onClick={toggleNavCollapsed}
            aria-label={navCollapsed ? 'Mở rộng thanh chức năng' : 'Thu gọn thanh chức năng'}
            title={navCollapsed ? 'Mở rộng' : 'Thu gọn'}
          >
            {navCollapsed ? <ChevronRightIcon size={18} /> : <ChevronLeftIcon size={18} />}
          </button>
        </div>
        <nav>
          {grouped.map(([groupLabel, items]) => (
            <section key={groupLabel} className="navGroup">
              {groupLabel && <h2>{groupLabel}</h2>}
              {items.map((item) => (
                <button
                  key={item.id}
                  className={active?.id === item.id ? 'active' : ''}
                  onClick={() => navigate(item.id)}
                  title={item.label}
                >
                  {item.icon}
                  <span>{item.label}</span>
                  {item.badge && <small>{item.badge}</small>}
                </button>
              ))}
            </section>
          ))}
        </nav>
        <button className="logout" onClick={logout} title="Đăng xuất"><LogoutIcon size={18} /><span>Đăng xuất</span></button>
      </aside>

      <main className="workspace">
        <header className="topbar">
          <button className="menuButton" onClick={() => setNavOpen((v) => !v)} aria-label="Mở menu">
            {navOpen ? <CloseIcon size={22} /> : <MenuIcon size={22} />}
          </button>
          <div className="topbarTitle">
            <span className="eyebrow">{roleLabels[user.roleCode] || user.roleCode}</span>
            <strong>{user.profile?.FullName || user.fullName || user.username}</strong>
          </div>
          <div className="userPills">
            <span className="pill">{user.profile?.Username || user.username}</span>
            <Badge value={user.profile?.AccountStatus || user.accountStatus || 'Active'} />
            <div className="avatar">{getInitials(user.profile?.FullName || user.fullName || user.username)}</div>
          </div>
        </header>

        <div className="content">
          {toast && (
            <div className={`toast toast-${toast.tone}`} role={toast.tone === 'error' ? 'alert' : 'status'}>
              <span className="toast-msg">{toast.message}</span>
              <button className="ui-iconbtn toast-close" onClick={() => setToast(null)} aria-label="Đóng thông báo"><CloseIcon size={16} /></button>
            </div>
          )}
          {active && <div key={active.id}>{active.render({ token, user, onToast: pushToast })}</div>}
        </div>
      </main>
    </div>
  );
}

function groupSections(sections) {
  const map = new Map();
  for (const s of sections) {
    const key = s.group || '';
    if (!map.has(key)) map.set(key, []);
    map.get(key).push(s);
  }
  return [...map.entries()];
}
