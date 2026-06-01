import React, { useCallback, useLayoutEffect, useRef, useState } from 'react';
import { createPortal } from 'react-dom';

const TOOLTIP_W = 560;
const GAP = 10;
const HIDE_DELAY = 180;
const EDGE = 8; // min distance from viewport edge

const OP_CLASS = {
  SELECT: 'sq-op-select',
  INSERT: 'sq-op-insert',
  UPDATE: 'sq-op-update',
  DELETE: 'sq-op-delete',
  EXEC:   'sq-op-exec',
  STREAM: 'sq-op-stream',
  RENDER: 'sq-op-stream',
};

const TYPE_META = {
  SP:     { label: 'Stored Procedure', cls: 'sq-type-sp' },
  AUTH:   { label: 'Auth Endpoint',    cls: 'sq-type-auth' },
  EXPORT: { label: 'Export / Report',  cls: 'sq-type-export' },
  VIEW:   { label: 'View Query',       cls: 'sq-type-view' },
  SQL:    { label: 'Raw SQL',          cls: 'sq-type-view' },
};

/**
 * Compute initial tooltip position (viewport-relative, for position:fixed).
 * Picks the side with most space. Vertical clamping happens post-render in
 * TooltipPanel's useLayoutEffect once the actual height is known.
 */
function computePos(r) {
  const spaceRight = window.innerWidth  - r.right  - GAP;
  const spaceLeft  = r.left             - GAP;
  const spaceAbove = r.top              - GAP;
  const spaceBelow = window.innerHeight - r.bottom  - GAP;

  let left, top, placement;

  if (spaceRight >= TOOLTIP_W) {
    left = r.right + GAP;
    top  = r.top;
    placement = 'right';
  } else if (spaceLeft >= TOOLTIP_W) {
    left = r.left - TOOLTIP_W - GAP;
    top  = r.top;
    placement = 'left';
  } else if (spaceAbove >= spaceBelow) {
    // Anchor: bottom of tooltip = top of trigger - GAP (handled in style below)
    left = r.left;
    top  = r.top - GAP;
    placement = 'above';
  } else {
    left = r.left;
    top  = r.bottom + GAP;
    placement = 'below';
  }

  // Pre-clamp horizontal (fine-tuned again post-render)
  left = Math.min(Math.max(left, EDGE), window.innerWidth - TOOLTIP_W - EDGE);

  return { top, left, placement };
}

/**
 * Post-render clamp: measures the rendered tooltip and nudges position so
 * every edge stays within the viewport. Runs as a layout effect (no flicker).
 */
function clampToViewport(tipEl, pos) {
  const r   = tipEl.getBoundingClientRect();
  const vw  = window.innerWidth;
  const vh  = window.innerHeight;

  let { top, left } = pos;
  let changed = false;

  // ── Horizontal ──────────────────────────────────────────────────────────
  if (r.right > vw - EDGE)  { left = vw - r.width - EDGE; changed = true; }
  if (r.left  < EDGE)        { left = EDGE;                changed = true; }

  // ── Vertical (only for non-above placements that use `top`) ────────────
  if (pos.placement !== 'above') {
    if (r.bottom > vh - EDGE) { top = vh - r.height - EDGE; changed = true; }
    if (r.top    < EDGE)       { top = EDGE;                 changed = true; }
  } else {
    // 'above' uses CSS `bottom` — check if it would clip the viewport top
    // bottom css = vh - pos.top  →  tooltip top in viewport = vh - bottomCss - height = pos.top - height
    const tipTop = pos.top - r.height;
    if (tipTop < EDGE) {
      // Not enough space above even after choosing this side; shift down so top = EDGE
      // We can't easily change placement here, just nudge the anchor point
      top = r.height + EDGE; // new pos.top so that tipTop == EDGE
      changed = true;
    }
  }

  return changed ? { ...pos, top, left } : null;
}

/* ─── Tooltip panel ──────────────────────────────────────────────────────── */
function TooltipPanel({ hint, pos, onMouseEnter, onMouseLeave, onReposition }) {
  const tipRef = useRef(null);
  const meta   = TYPE_META[hint.type] || TYPE_META.SQL;

  // Post-render: measure actual size and clamp if overflow
  useLayoutEffect(() => {
    if (!tipRef.current) return;
    const adjusted = clampToViewport(tipRef.current, pos);
    if (adjusted) onReposition(adjusted);
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []); // run once on mount (pos won't change identity here)

  const style = pos.placement === 'above'
    ? { left: pos.left, bottom: `${window.innerHeight - pos.top}px` }
    : { left: pos.left, top: pos.top };

  return (
    <div
      ref={tipRef}
      className={`sq-tip sq-placement-${pos.placement}`}
      style={style}
      onMouseEnter={onMouseEnter}
      onMouseLeave={onMouseLeave}
    >
      {/* Header */}
      <div className="sq-tip-head">
        <span className={`sq-type-badge ${meta.cls}`}>{meta.label}</span>
      </div>

      {/* Main call */}
      <code className="sq-tip-invoke">{hint.invoke}</code>

      {/* Internal steps */}
      {hint.steps?.length > 0 && (
        <div className="sq-tip-section">
          <span className="sq-section-label">Lệnh SQL bên trong</span>
          <div className="sq-steps">
            {hint.steps.map((s, i) => (
              <div key={i} className="sq-step">
                <span className={`sq-op ${OP_CLASS[s.op] || 'sq-op-select'}`}>{s.op}</span>
                <span className="sq-on">{s.on}</span>
                {s.note && <span className="sq-note">{s.note}</span>}
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Triggers */}
      {hint.triggers?.length > 0 && (
        <div className="sq-tip-section sq-triggers-section">
          <span className="sq-section-label sq-trigger-label">⚡ Trigger tự động</span>
          <div className="sq-triggers">
            {hint.triggers.map((t, i) => (
              <div key={i} className="sq-trigger-row">{t}</div>
            ))}
          </div>
        </div>
      )}

      {/* SQL source code */}
      {hint.sql && (
        <div className="sq-tip-section sq-sql-section">
          <span className="sq-section-label">Source SQL</span>
          <pre className="sq-sql-code"><code>{hint.sql}</code></pre>
        </div>
      )}
    </div>
  );
}

/* ─── Public wrapper ─────────────────────────────────────────────────────── */
export function SqlTooltip({ hint, children }) {
  const [pos, setPos]     = useState(null);
  const ref               = useRef(null);
  const hideTimer         = useRef(null);

  const cancelHide = useCallback(() => clearTimeout(hideTimer.current), []);

  const startHide = useCallback(() => {
    hideTimer.current = setTimeout(() => setPos(null), HIDE_DELAY);
  }, []);

  const show = useCallback(() => {
    cancelHide();
    if (!ref.current) return;
    // display:contents spans have no layout box — use first child element
    const target = ref.current.children[0] || ref.current;
    const r = target.getBoundingClientRect();
    if (!r.width && !r.height) return;
    setPos(computePos(r));
  }, [cancelHide]);

  if (!hint) return children;

  return (
    <>
      <span ref={ref} onMouseEnter={show} onMouseLeave={startHide} style={{ display: 'contents' }}>
        {children}
      </span>
      {pos && createPortal(
        <TooltipPanel
          hint={hint}
          pos={pos}
          onMouseEnter={cancelHide}
          onMouseLeave={startHide}
          onReposition={setPos}
        />,
        document.body
      )}
    </>
  );
}
