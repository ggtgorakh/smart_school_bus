// test/attendance_rules_emulator_test.js
//
// Emulator tests for the Phase 1 rules.
//
// Covers:
//   - attendanceEvents/$busId/$eventId/.write  (existing, extended checks)
//   - parentEvents/$parentUid/$busId/$studentId/$eventId  (new)
//   - notifications/$uid/$notificationId/.write            (SOS branch)
//
// This test does NOT modify production code or the schema.

const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require('@firebase/rules-unit-testing');
const { ref, set, get } = require('firebase/database');
const { readFileSync } = require('fs');

let testEnv;

const PROJECT_ID = 'smart-school-bus-8e7d1';
const DATABASE_URL = `http://localhost:9000/?ns=${PROJECT_ID}`;

const SEED = {
  users: {
    driver01: { role: 'Driver', busId: 'bus_01' },
    driver02: { role: 'Driver', busId: 'bus_02' },
    conductor01: { role: 'Conductor', busId: 'bus_01' },
    admin01: { role: 'Admin' },
    parent01: { role: 'Parent' },
    parent02: { role: 'Parent' },
  },
  busesFleet: {
    bus_01: { driverUid: 'driver01', status: 'onRoute' },
    bus_02: { driverUid: 'driver02', status: 'onRoute' },
  },
  studentRosters: {
    bus_01: {
      student_01: { name: 'S1', parentUid: 'parent01', status: 'pending' },
      student_02: { name: 'S2', parentUid: null, status: 'pending' },
    },
    bus_02: {
      student_03: { name: 'S3', parentUid: 'parent02', status: 'pending' },
    },
  },
  trips: {
    bus_01: {
      trip_valid_active: {
        tripId: 'trip_valid_active',
        busId: 'bus_01',
        routeId: 'r1',
        driverUid: 'driver01',
        status: 'active',
      },
      trip_valid_preparing: {
        tripId: 'trip_valid_preparing',
        busId: 'bus_01',
        routeId: 'r1',
        driverUid: 'driver01',
        status: 'preparing',
      },
      trip_valid_paused: {
        tripId: 'trip_valid_paused',
        busId: 'bus_01',
        routeId: 'r1',
        driverUid: 'driver01',
        status: 'paused',
      },
      trip_closed: {
        tripId: 'trip_closed',
        busId: 'bus_01',
        routeId: 'r1',
        driverUid: 'driver01',
        status: 'completed',
      },
    },
    bus_02: {
      trip_other_bus: {
        tripId: 'trip_other_bus',
        busId: 'bus_02',
        routeId: 'r2',
        driverUid: 'driver02',
        status: 'active',
      },
    },
  },
  parentChildIndex: {
    parent01: { bus_01: { student_01: true } },
    parent02: { bus_02: { student_03: true } },
  },
  adminIndex: {
    admin01: true,
  },
};

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    database: {
      host: '127.0.0.1',
      port: 9000,
      rules: readFileSync('database.rules.json', 'utf8'),
    },
  });

  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.database();
    await set(ref(db, '/'), SEED);
  });
});

after(async () => {
  await testEnv.cleanup();
});

function makeEvent(overrides = {}) {
  return {
    eventId:
      'event_' + Date.now() + '_' + Math.random().toString(36).slice(2),
    studentId: 'student_01',
    busId: 'bus_01',
    tripId: 'trip_valid_active',
    actorUid: 'driver01',
    status: 'boarded',
    source: 'manual',
    timestamp: Date.now(),
    ...overrides,
  };
}

// ============================================================
// attendanceEvents write rule
// ============================================================

describe('attendanceEvents write rule — dynamic cross-node validation', () => {
  it('ALLOWS: authenticated driver, own bus, student on bus, trip active on same bus', async () => {
    const driver01 = testEnv.authenticatedContext('driver01');
    const db = driver01.database(DATABASE_URL);
    const event = makeEvent();
    await assertSucceeds(
      set(ref(db, `attendanceEvents/bus_01/${event.eventId}`), event),
    );
  });

  it('ALLOWS: trip in preparing state', async () => {
    const driver01 = testEnv.authenticatedContext('driver01');
    const db = driver01.database(DATABASE_URL);
    const event = makeEvent({ tripId: 'trip_valid_preparing' });
    await assertSucceeds(
      set(ref(db, `attendanceEvents/bus_01/${event.eventId}`), event),
    );
  });

  it('ALLOWS: trip in paused state', async () => {
    const driver01 = testEnv.authenticatedContext('driver01');
    const db = driver01.database(DATABASE_URL);
    const event = makeEvent({ tripId: 'trip_valid_paused' });
    await assertSucceeds(
      set(ref(db, `attendanceEvents/bus_01/${event.eventId}`), event),
    );
  });

  it('REJECTS: student belongs to another bus', async () => {
    const driver01 = testEnv.authenticatedContext('driver01');
    const db = driver01.database(DATABASE_URL);
    const event = makeEvent({ studentId: 'student_03' });
    await assertFails(
      set(ref(db, `attendanceEvents/bus_01/${event.eventId}`), event),
    );
  });

  it('REJECTS: trip belongs to another bus', async () => {
    const driver01 = testEnv.authenticatedContext('driver01');
    const db = driver01.database(DATABASE_URL);
    const event = makeEvent({ tripId: 'trip_other_bus' });
    await assertFails(
      set(ref(db, `attendanceEvents/bus_01/${event.eventId}`), event),
    );
  });

  it('REJECTS: trip does not exist', async () => {
    const driver01 = testEnv.authenticatedContext('driver01');
    const db = driver01.database(DATABASE_URL);
    const event = makeEvent({ tripId: 'trip_nonexistent' });
    await assertFails(
      set(ref(db, `attendanceEvents/bus_01/${event.eventId}`), event),
    );
  });

  it('REJECTS: trip status is completed', async () => {
    const driver01 = testEnv.authenticatedContext('driver01');
    const db = driver01.database(DATABASE_URL);
    const event = makeEvent({ tripId: 'trip_closed' });
    await assertFails(
      set(ref(db, `attendanceEvents/bus_01/${event.eventId}`), event),
    );
  });

  it('REJECTS: actorUid does not match authenticated user', async () => {
    const driver02 = testEnv.authenticatedContext('driver02');
    const db = driver02.database(DATABASE_URL);
    const event = makeEvent({
      actorUid: 'driver01',
      busId: 'bus_02',
      tripId: 'trip_other_bus',
      studentId: 'student_03',
    });
    await assertFails(
      set(ref(db, `attendanceEvents/bus_02/${event.eventId}`), event),
    );
  });

  it('REJECTS: driver writes to a bus they are not assigned to', async () => {
    const driver01 = testEnv.authenticatedContext('driver01');
    const db = driver01.database(DATABASE_URL);
    const event = makeEvent({
      busId: 'bus_02',
      tripId: 'trip_other_bus',
      studentId: 'student_03',
      actorUid: 'driver01',
    });
    await assertFails(
      set(ref(db, `attendanceEvents/bus_02/${event.eventId}`), event),
    );
  });
});

// ============================================================
// parentEvents write rule
// ============================================================

describe('parentEvents write rule', () => {
  it('ALLOWS: driver of the bus writes a true index entry', async () => {
    const driver01 = testEnv.authenticatedContext('driver01');
    const db = driver01.database(DATABASE_URL);
    await assertSucceeds(
      set(ref(db, 'parentEvents/parent01/bus_01/student_01/evt_01'), true),
    );
  });

  it('ALLOWS: conductor of the bus writes a true index entry', async () => {
    const conductor01 = testEnv.authenticatedContext('conductor01');
    const db = conductor01.database(DATABASE_URL);
    await assertSucceeds(
      set(ref(db, 'parentEvents/parent01/bus_01/student_01/evt_02'), true),
    );
  });

  it('ALLOWS: admin writes a true index entry', async () => {
    const admin01 = testEnv.authenticatedContext('admin01');
    const db = admin01.database(DATABASE_URL);
    await assertSucceeds(
      set(ref(db, 'parentEvents/parent02/bus_02/student_03/evt_03'), true),
    );
  });

  it('REJECTS: driver of another bus writes into this bus', async () => {
    const driver02 = testEnv.authenticatedContext('driver02');
    const db = driver02.database(DATABASE_URL);
    await assertFails(
      set(ref(db, 'parentEvents/parent01/bus_01/student_01/evt_04'), true),
    );
  });

  it('REJECTS: parent cannot write into their own index', async () => {
    const parent01 = testEnv.authenticatedContext('parent01');
    const db = parent01.database(DATABASE_URL);
    await assertFails(
      set(ref(db, 'parentEvents/parent01/bus_01/student_01/evt_05'), true),
    );
  });

  it('REJECTS: value is not a boolean', async () => {
    const driver01 = testEnv.authenticatedContext('driver01');
    const db = driver01.database(DATABASE_URL);
    await assertFails(
      set(
        ref(db, 'parentEvents/parent01/bus_01/student_01/evt_06'),
        'true',
      ),
    );
  });
});

// ============================================================
// parentEvents read rule
// ============================================================

describe('parentEvents read rule', () => {
  before(async () => {
    // Seed some index entries so reads have something to find.
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.database();
      await set(ref(db, 'parentEvents/parent01/bus_01/student_01/evt_r1'), true);
      await set(ref(db, 'parentEvents/parent02/bus_02/student_03/evt_r2'), true);
    });
  });

  it('ALLOWS: parent01 reads own index', async () => {
    const parent01 = testEnv.authenticatedContext('parent01');
    const db = parent01.database(DATABASE_URL);
    const snap = await get(ref(db, 'parentEvents/parent01/bus_01/student_01'));
    if (snap.val() === null) {
      throw new Error('Expected parent01 to read their own index, but got null.');
    }
  });

  it('REJECTS: parent01 cannot read parent02\'s index entry', async () => {
    const parent01 = testEnv.authenticatedContext('parent01');
    const db = parent01.database(DATABASE_URL);
    let denied = false;
    try {
      await get(ref(db, 'parentEvents/parent02/bus_02/student_03'));
    } catch (e) {
      denied = true;
    }
    if (!denied) {
      throw new Error(
        'Expected read of parent02\'s index to be denied, but it succeeded.',
      );
    }
  });
});

// ============================================================
// notifications — SOS branch (Branch 5)
// ============================================================

describe('notifications write rule — SOS to Admin', () => {
  const notifId = () => 'n_' + Date.now() + '_' + Math.random().toString(36).slice(2);

  function makeSosNotification(overrides = {}) {
    return {
      id: overrides.id || notifId(),
      kind: 'emergency',
      title: '🚨 SOS from driver',
      message: 'Accident on bus_01',
      timestamp: Date.now(),
      isRead: false,
      busId: 'bus_01',
      ...overrides,
    };
  }

  it('ALLOWS: driver notifies an Admin without requiring a busId match', async () => {
    const driver01 = testEnv.authenticatedContext('driver01');
    const db = driver01.database(DATABASE_URL);
    const n = makeSosNotification();
    await assertSucceeds(
      set(ref(db, `notifications/admin01/${n.id}`), n),
    );
  });

  it('ALLOWS: conductor notifies an Admin', async () => {
    const conductor01 = testEnv.authenticatedContext('conductor01');
    const db = conductor01.database(DATABASE_URL);
    const n = makeSosNotification({ id: notifId() });
    await assertSucceeds(
      set(ref(db, `notifications/admin01/${n.id}`), n),
    );
  });

  it('REJECTS: parent cannot notify an Admin via SOS branch', async () => {
    const parent01 = testEnv.authenticatedContext('parent01');
    const db = parent01.database(DATABASE_URL);
    const n = makeSosNotification({ id: notifId() });
    await assertFails(
      set(ref(db, `notifications/admin01/${n.id}`), n),
    );
  });

  it('REJECTS: driver cannot send a non-emergency notification to an Admin', async () => {
    const driver01 = testEnv.authenticatedContext('driver01');
    const db = driver01.database(DATABASE_URL);
    const n = makeSosNotification({
      id: notifId(),
      kind: 'info',
    });
    await assertFails(
      set(ref(db, `notifications/admin01/${n.id}`), n),
    );
  });

  it('REJECTS: driver cannot send an SOS notification to a non-Admin', async () => {
    const driver01 = testEnv.authenticatedContext('driver01');
    const db = driver01.database(DATABASE_URL);
    const n = makeSosNotification({ id: notifId() });
    await assertFails(
      set(ref(db, `notifications/parent01/${n.id}`), n),
    );
  });
});