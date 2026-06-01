import sql from 'mssql';

const maxLookupRows = 80;

const lookupDefinitions = {
  connectorTypes: {
    roles: ['Customer', 'OperationsStaff', 'BusinessManager', 'SystemAdmin'],
    valueType: 'int',
    source: `
      SELECT ConnectorTypeID AS value,
             CONCAT(ConnectorName, N' (', ConnectorCode,
                    CASE WHEN MaxPowerKW IS NULL THEN N'' ELSE CONCAT(N' - ', FORMAT(MaxPowerKW, '0.##'), N' kW') END,
                    N')') AS label,
             ConnectorCode, ConnectorName, MaxPowerKW
      FROM AppView.vw_WebLookupConnectorTypes
    `,
    searchColumns: ['ConnectorCode', 'ConnectorName'],
    orderBy: 'ConnectorName, ConnectorCode'
  },
  customerVehicles: {
    roles: ['Customer'],
    valueType: 'int',
    source: `
      SELECT VehicleID AS value,
             CONCAT(PlateNumber, N' - ', Brand, N' ', Model,
                    CASE WHEN ConnectorName IS NULL THEN N'' ELSE CONCAT(N' - ', ConnectorName) END) AS label,
             VehicleID, PlateNumber, Brand, Model, ConnectorName, IsActive
      FROM AppView.vw_WebLookupCustomerVehicles
      WHERE IsActive = 1
    `,
    searchColumns: ['PlateNumber', 'Brand', 'Model', 'ConnectorName'],
    orderBy: 'PlateNumber, Brand, Model'
  },
  customerAllVehicles: {
    roles: ['Customer'],
    valueType: 'int',
    source: `
      SELECT VehicleID AS value,
             CONCAT(PlateNumber, N' - ', Brand, N' ', Model,
                    CASE WHEN IsActive = 1 THEN N'' ELSE N' - inactive' END) AS label,
             VehicleID, PlateNumber, Brand, Model, ConnectorName, IsActive
      FROM AppView.vw_WebLookupCustomerVehicles
    `,
    searchColumns: ['PlateNumber', 'Brand', 'Model', 'ConnectorName'],
    orderBy: 'IsActive DESC, PlateNumber'
  },
  customerAvailablePoints: {
    roles: ['Customer'],
    valueType: 'int',
    source: `
      SELECT PointID AS value,
             CONCAT(StationName, N' - ', PointCode, N' - ', ConnectorName, N' - ', FORMAT(PowerKW, '0.##'), N' kW') AS label,
             PointID, StationID, StationCode, StationName, PointCode, ConnectorName, PowerKW, RegionName
      FROM AppView.vw_WebLookupAvailablePoints
    `,
    searchColumns: ['RegionName', 'StationCode', 'StationName', 'PointCode', 'ConnectorName'],
    filters: {
      StationID: { column: 'StationID', type: 'int' }
    },
    orderBy: 'StationName, PointCode'
  },
  customerCancelableBookings: {
    roles: ['Customer'],
    valueType: 'bigInt',
    source: `
      SELECT BookingID AS value,
             CONCAT(BookingCode, N' - ', StationName, N' - ', PointCode,
                    CASE WHEN PlateNumber IS NULL THEN N'' ELSE CONCAT(N' - ', PlateNumber) END,
                    N' - ', CONVERT(NVARCHAR(16), BookedFrom, 120)) AS label,
             BookingID, BookingCode, VehicleID, PointID, PlateNumber, StationName, PointCode, BookedFrom, BookedTo, BookingStatus
      FROM AppView.vw_WebLookupCustomerBookings
      WHERE BookingStatus IN (N'Pending', N'Confirmed', N'Active')
    `,
    searchColumns: ['BookingCode', 'PlateNumber', 'StationName', 'PointCode', 'BookingStatus'],
    orderBy: 'BookedFrom DESC, BookingID DESC'
  },
  customerStartableBookings: {
    roles: ['Customer'],
    valueType: 'bigInt',
    source: `
      SELECT BookingID AS value,
             CONCAT(BookingCode, N' - ', StationName, N' - ', PointCode,
                    CASE WHEN PlateNumber IS NULL THEN N'' ELSE CONCAT(N' - ', PlateNumber) END) AS label,
             BookingID, BookingCode, VehicleID, PointID, PlateNumber, StationName, PointCode, BookedFrom, BookedTo, BookingStatus
      FROM AppView.vw_WebLookupCustomerBookings
      WHERE BookingStatus IN (N'Confirmed', N'Active')
    `,
    searchColumns: ['BookingCode', 'PlateNumber', 'StationName', 'PointCode'],
    orderBy: 'BookedFrom DESC, BookingID DESC'
  },
  customerActiveSessions: {
    roles: ['Customer'],
    valueType: 'bigInt',
    source: `
      SELECT SessionID AS value,
             CONCAT(SessionCode, N' - ', StationName, N' - ', PointCode,
                    CASE WHEN PlateNumber IS NULL THEN N'' ELSE CONCAT(N' - ', PlateNumber) END) AS label,
             SessionID, SessionCode, VehicleID, PointID, PlateNumber, StationName, PointCode, StartTime, SessionStatus
      FROM AppView.vw_WebLookupCustomerSessions
      WHERE SessionStatus = N'Charging'
    `,
    searchColumns: ['SessionCode', 'PlateNumber', 'StationName', 'PointCode'],
    orderBy: 'StartTime DESC, SessionID DESC'
  },
  customerPayableSessions: {
    roles: ['Customer'],
    valueType: 'bigInt',
    source: `
      SELECT SessionID AS value,
             CONCAT(SessionCode, N' - ', StationName, N' - ', PointCode, N' - ', FORMAT(CostTotal, 'N0'), N' VND') AS label,
             SessionID, SessionCode, VehicleID, PointID, PlateNumber, StationName, PointCode, CostTotal, StartTime
      FROM AppView.vw_WebLookupCustomerSessions
      WHERE SessionStatus = N'Completed'
        AND ISNULL(HasCompletedPayment, 0) = 0
        AND ISNULL(CostTotal, 0) > 0
    `,
    searchColumns: ['SessionCode', 'PlateNumber', 'StationName', 'PointCode'],
    orderBy: 'StartTime DESC, SessionID DESC'
  },
  customerInvoiceableSessions: {
    roles: ['Customer'],
    valueType: 'bigInt',
    source: `
      SELECT SessionID AS value,
             CONCAT(SessionCode, N' - ', StationName, N' - ', PointCode, N' - ', FORMAT(CostTotal, 'N0'), N' VND') AS label,
             SessionID, SessionCode, VehicleID, PointID, PlateNumber, StationName, PointCode, CostTotal, StartTime
      FROM AppView.vw_WebLookupCustomerSessions
      WHERE SessionStatus = N'Completed'
        AND ISNULL(HasCompletedPayment, 0) = 1
        AND ISNULL(HasInvoice, 0) = 0
    `,
    searchColumns: ['SessionCode', 'PlateNumber', 'StationName', 'PointCode'],
    orderBy: 'StartTime DESC, SessionID DESC'
  },
  operationsStations: {
    roles: ['OperationsStaff'],
    valueType: 'int',
    source: `
      SELECT StationID AS value,
             CONCAT(StationCode, N' - ', StationName, N' - ', StationStatus) AS label,
             StationID, StationCode, StationName, StationStatus
      FROM AppView.vw_WebLookupStations
    `,
    searchColumns: ['StationCode', 'StationName', 'StationStatus'],
    orderBy: 'StationCode'
  },
  operationsPoints: {
    roles: ['OperationsStaff'],
    valueType: 'int',
    source: `
      SELECT PointID AS value,
             CONCAT(StationCode, N' - ', PointCode, N' - ', PointStatus, N'/', HealthStatus) AS label,
             PointID, StationID, StationCode, StationName, PointCode, PointStatus, HealthStatus, ConnectorName
      FROM AppView.vw_WebLookupPoints
    `,
    searchColumns: ['StationCode', 'StationName', 'PointCode', 'PointStatus', 'HealthStatus', 'ConnectorName'],
    filters: {
      StationID: { column: 'StationID', type: 'int' }
    },
    orderBy: 'StationCode, PointCode'
  },
  operationsActiveSessions: {
    roles: ['OperationsStaff'],
    valueType: 'bigInt',
    source: `
      SELECT SessionID AS value,
             CONCAT(SessionCode, N' - ', FullName, N' - ', StationCode, N'/', PointCode) AS label,
             SessionID, SessionCode, FullName, StationCode, PointCode, StartTime, SessionStatus
      FROM AppView.vw_WebLookupActiveSessions
    `,
    searchColumns: ['SessionCode', 'FullName', 'StationCode', 'PointCode'],
    orderBy: 'StartTime DESC, SessionID DESC'
  },
  operationsOpenTickets: {
    roles: ['OperationsStaff'],
    valueType: 'bigInt',
    source: `
      SELECT TicketID AS value,
             CONCAT(TicketCode, N' - ', Priority, N' - ', Title) AS label,
             TicketID, TicketCode, Priority, TicketStatus, Title, StationCode, PointCode
      FROM AppView.vw_WebLookupOpenTickets
    `,
    searchColumns: ['TicketCode', 'Priority', 'TicketStatus', 'Title', 'StationCode', 'PointCode'],
    orderBy: 'OpenedAt DESC, TicketID DESC'
  },
  operationsStaffUsers: {
    roles: ['OperationsStaff'],
    valueType: 'int',
    source: `
      SELECT UserID AS value,
             CONCAT(FullName, N' (', Username, N')') AS label,
             UserID, Username, FullName, Email, AccountStatus
      FROM AppView.vw_WebLookupOperationsStaff
    `,
    searchColumns: ['Username', 'FullName', 'Email'],
    orderBy: 'FullName, Username'
  },
  businessActivePricingPolicies: {
    roles: ['BusinessManager'],
    valueType: 'int',
    source: `
      SELECT PolicyID AS value,
             CONCAT(PolicyCode, N' - ', PolicyName, N' - ', FORMAT(BasePricePerKWh, 'N0'), N' VND/kWh') AS label,
             PolicyID, PolicyCode, PolicyName, BasePricePerKWh, AppliedFrom, AppliedTo
      FROM AppView.vw_WebLookupPricingPolicies
      WHERE IsActive = 1
    `,
    searchColumns: ['PolicyCode', 'PolicyName'],
    orderBy: 'AppliedFrom DESC, PolicyID DESC'
  },
  businessInactivePricingPolicies: {
    roles: ['BusinessManager'],
    valueType: 'int',
    source: `
      SELECT PolicyID AS value,
             CONCAT(PolicyCode, N' - ', PolicyName, N' - ', FORMAT(BasePricePerKWh, 'N0'), N' VND/kWh') AS label,
             PolicyID, PolicyCode, PolicyName, BasePricePerKWh, AppliedFrom, AppliedTo
      FROM AppView.vw_WebLookupPricingPolicies
      WHERE IsActive = 0
    `,
    searchColumns: ['PolicyCode', 'PolicyName'],
    orderBy: 'AppliedFrom DESC, PolicyID DESC'
  },
  businessRevenueSharePolicies: {
    roles: ['BusinessManager'],
    valueType: 'int',
    source: `
      SELECT RevenueSharePolicyID AS value,
             CONCAT(FranchiseCode, N' - ', FranchiseName, N' - ', PolicyCode,
                    N' - ', FORMAT(PartnerShareRate, '0.##'), N'%') AS label,
             RevenueSharePolicyID, FranchiseID, FranchiseCode, FranchiseName, ContractCode, PolicyCode, PartnerShareRate, AppliedFrom, AppliedTo
      FROM AppView.vw_WebLookupRevenueSharePolicies
    `,
    searchColumns: ['FranchiseCode', 'FranchiseName', 'ContractCode', 'PolicyCode'],
    orderBy: 'FranchiseCode, AppliedFrom DESC'
  },
  businessActiveFranchises: {
    roles: ['BusinessManager'],
    valueType: 'int',
    source: `
      SELECT FranchiseID AS value,
             CONCAT(FranchiseCode, N' - ', FranchiseName, N' - ', PartnerStatus) AS label,
             FranchiseID, FranchiseCode, FranchiseName, PartnerStatus
      FROM AppView.vw_WebLookupFranchises
      WHERE PartnerStatus = N'Active'
    `,
    searchColumns: ['FranchiseCode', 'FranchiseName', 'PartnerStatus'],
    orderBy: 'FranchiseCode'
  },
  businessRefundablePayments: {
    roles: ['BusinessManager'],
    valueType: 'bigInt',
    source: `
      SELECT TransactionID AS value,
             CONCAT(TransactionCode, N' - ', FullName, N' - ', FORMAT(Amount, 'N0'), N' VND') AS label,
             TransactionID, TransactionCode, FullName, Amount, PaymentMethod, PaidAt, InvoiceCode, StationName
      FROM AppView.vw_WebLookupRefundablePayments
    `,
    searchColumns: ['TransactionCode', 'FullName', 'InvoiceCode', 'StationName'],
    orderBy: 'PaidAt DESC, TransactionID DESC'
  },
  adminUsers: {
    roles: ['SystemAdmin'],
    valueType: 'int',
    source: `
      SELECT UserID AS value,
             CONCAT(Username, N' - ', FullName, N' - ', AccountStatus,
                    CASE WHEN RoleCodes IS NULL THEN N'' ELSE CONCAT(N' - ', RoleCodes) END) AS label,
             UserID, Username, FullName, Email, Phone, AccountStatus, RoleCodes
      FROM AppView.vw_WebLookupUsers
    `,
    searchColumns: ['Username', 'FullName', 'Email', 'Phone', 'AccountStatus', 'RoleCodes'],
    orderBy: 'Username'
  },
  adminLockableUsers: {
    roles: ['SystemAdmin'],
    valueType: 'int',
    source: `
      SELECT UserID AS value,
             CONCAT(Username, N' - ', FullName, N' - ', AccountStatus) AS label,
             UserID, Username, FullName, Email, AccountStatus, RoleCodes
      FROM AppView.vw_WebLookupUsers
      WHERE AccountStatus NOT IN (N'Locked', N'Suspended')
    `,
    searchColumns: ['Username', 'FullName', 'Email', 'RoleCodes'],
    orderBy: 'Username'
  },
  adminUnlockableUsers: {
    roles: ['SystemAdmin'],
    valueType: 'int',
    source: `
      SELECT UserID AS value,
             CONCAT(Username, N' - ', FullName, N' - ', AccountStatus) AS label,
             UserID, Username, FullName, Email, AccountStatus, RoleCodes
      FROM AppView.vw_WebLookupUsers
      WHERE AccountStatus IN (N'Locked', N'Suspended')
    `,
    searchColumns: ['Username', 'FullName', 'Email', 'RoleCodes'],
    orderBy: 'Username'
  },
  adminAssignableRoles: {
    roles: ['SystemAdmin'],
    valueType: 'nvarchar',
    source: `
      SELECT RoleCode AS value,
             CONCAT(RoleName, N' (', RoleCode, N')') AS label,
             UserID, RoleCode, RoleName
      FROM AppView.vw_WebLookupAssignableRoles
    `,
    searchColumns: ['RoleCode', 'RoleName'],
    filters: {
      UserID: { column: 'UserID', type: 'int', required: true }
    },
    orderBy: 'RoleCode'
  },
  adminRemovableRoles: {
    roles: ['SystemAdmin'],
    valueType: 'nvarchar',
    source: `
      SELECT RoleCode AS value,
             CONCAT(RoleName, N' (', RoleCode, N')') AS label,
             UserID, RoleCode, RoleName
      FROM AppView.vw_WebLookupRemovableRoles
    `,
    searchColumns: ['RoleCode', 'RoleName'],
    filters: {
      UserID: { column: 'UserID', type: 'int', required: true }
    },
    orderBy: 'RoleCode'
  }
};

const sqlTypeByName = {
  int: sql.Int,
  bigInt: sql.BigInt,
  nvarchar: sql.NVarChar(200)
};

function normalizeLookupKey(lookup) {
  if (!lookup) return '';
  return typeof lookup === 'string' ? lookup : lookup.key;
}

function hasRole(definition, user) {
  return definition.roles.includes(user.roleCode);
}

function getDefinition(key, user) {
  const definition = lookupDefinitions[key];
  if (!definition) {
    const error = new Error('Danh sách lựa chọn không tồn tại.');
    error.statusCode = 404;
    throw error;
  }
  if (!hasRole(definition, user)) {
    const error = new Error('Bạn không có quyền xem danh sách lựa chọn này.');
    error.statusCode = 403;
    throw error;
  }
  return definition;
}

function cleanValue(value) {
  return value === undefined || value === '' ? null : value;
}

function coerceByType(type, value) {
  const clean = cleanValue(value);
  if (clean === null) return null;
  if (type === 'int' || type === 'bigInt') return Number(clean);
  return String(clean);
}

function bindLookupInputs(request, definition, body, { includeSearch = true, includeLimit = true } = {}) {
  if (includeLimit) request.input('LookupLimit', sql.Int, Math.min(Math.max(Number(body.limit || 50), 1), maxLookupRows));
  if (includeSearch) {
    const search = String(body.search || '').trim();
    request.input('LookupSearch', sql.NVarChar(200), search ? `%${search}%` : null);
  }

  for (const [name, filter] of Object.entries(definition.filters || {})) {
    const value = coerceByType(filter.type, body[name]);
    if (filter.required && value === null) {
      request.input(`Lookup_${name}`, sqlTypeByName[filter.type] || sql.NVarChar(200), null);
      continue;
    }
    request.input(`Lookup_${name}`, sqlTypeByName[filter.type] || sql.NVarChar(200), value);
  }
}

function buildPredicates(definition, { search = true, filters = true, value = false } = {}) {
  const predicates = [];
  if (search && definition.searchColumns?.length) {
    predicates.push(`(
      @LookupSearch IS NULL OR ${definition.searchColumns
        .map((column) => `CONVERT(NVARCHAR(4000), data.[${column}]) LIKE @LookupSearch`)
        .join(' OR ')}
    )`);
  }

  if (filters) {
    for (const [name, filter] of Object.entries(definition.filters || {})) {
      predicates.push(filter.required
        ? `(@Lookup_${name} IS NOT NULL AND data.[${filter.column}] = @Lookup_${name})`
        : `(@Lookup_${name} IS NULL OR data.[${filter.column}] = @Lookup_${name})`);
    }
  }

  if (value) predicates.push('CONVERT(NVARCHAR(200), data.[value]) = CONVERT(NVARCHAR(200), @LookupValue)');
  return predicates.length ? `WHERE ${predicates.join('\n  AND ')}` : '';
}

function optionFromRow(row) {
  const { value, label, ...meta } = row;
  return {
    value,
    label: String(label ?? value ?? ''),
    meta
  };
}

export async function getLookupOptions(key, user, body = {}, transaction) {
  const definition = getDefinition(key, user);
  const request = new sql.Request(transaction);
  bindLookupInputs(request, definition, body);
  const where = buildPredicates(definition);
  const result = await request.query(`
    SELECT TOP (@LookupLimit) *
    FROM (${definition.source}) AS data
    ${where}
    ORDER BY ${definition.orderBy || 'label'};
  `);
  return {
    key,
    options: (result.recordset || []).map(optionFromRow)
  };
}

async function lookupValueExists(key, user, body, rawValue, transaction) {
  const definition = getDefinition(key, user);
  const value = coerceByType(definition.valueType, rawValue);
  if (value === null || Number.isNaN(value)) return false;

  const request = new sql.Request(transaction);
  bindLookupInputs(request, definition, body, { includeSearch: false, includeLimit: false });
  request.input('LookupValue', sqlTypeByName[definition.valueType] || sql.NVarChar(200), value);
  const where = buildPredicates(definition, { search: false, filters: true, value: true });
  const result = await request.query(`
    SELECT TOP (1) 1 AS Found
    FROM (${definition.source}) AS data
    ${where};
  `);
  return Boolean(result.recordset?.[0]?.Found);
}

export async function validateActionLookups(action, user, body = {}, transaction) {
  for (const param of action.params || []) {
    const key = normalizeLookupKey(param.lookup);
    if (!key || param.skipLookupValidation) continue;
    const raw = body[param.name] ?? param.defaultValue;
    if (cleanValue(raw) === null) continue;
    const exists = await lookupValueExists(key, user, body, raw, transaction);
    if (!exists) {
      const error = new Error(`Lựa chọn không hợp lệ hoặc không còn khả dụng: ${param.label || param.name}.`);
      error.statusCode = 400;
      throw error;
    }
  }
}

export function publicLookupKeysFor(roleCode) {
  return Object.entries(lookupDefinitions)
    .filter(([, definition]) => definition.roles.includes(roleCode))
    .map(([key]) => key);
}
