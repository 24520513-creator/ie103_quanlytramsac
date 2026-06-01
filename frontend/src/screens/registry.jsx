import React from 'react';
import { GenericScreen } from './GenericScreen';
import { getGroupIcon } from '../components/Icons';
import { customerSections } from './customer';
import { operationsSections } from './operations';
import { businessSections } from './business';
import { franchiseSections } from './franchise';
import { adminSections } from './admin';

/** Per-role bespoke section builders: roleCode -> (catalog, helpers) => Section[] */
const builders = {
  Customer: customerSections,
  OperationsStaff: operationsSections,
  BusinessManager: businessSections,
  FranchisePartner: franchiseSections,
  SystemAdmin: adminSections
};

/** Helper passed to builders so screens can locate their catalog actions. */
export function makeHelpers(actions) {
  const byId = Object.fromEntries(actions.map((a) => [a.id, a]));
  return {
    actions,
    byId,
    get: (id) => byId[id],
    has: (id) => Boolean(byId[id])
  };
}

/** A Section: { id, label, icon, group?, render(ctx) } where ctx = { token, user, onToast } */
export function sectionsFor(roleCode, actions) {
  const helpers = makeHelpers(actions);
  const builder = builders[roleCode];
  const sections = builder ? builder(helpers) : [];
  if (sections.length) return sections;
  return autoSections(actions);
}

/** Fallback: one GenericScreen section per catalog action, grouped by groupLabel. */
function autoSections(actions) {
  return actions.map((action) => ({
    id: action.id,
    label: action.title,
    group: action.groupLabel,
    icon: getGroupIcon(action.group, { size: 18 }),
    render: ({ token, user, onToast }) => (
      <GenericScreen action={action} token={token} user={user} onToast={onToast} />
    )
  }));
}
