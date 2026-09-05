Update the existing Smart School Bus Tracking & Student Safety System Flutter project.

IMPORTANT:
- Do NOT rewrite the application from scratch.
- Preserve the existing architecture, Firebase integration, authentication, role-based access, navigation, theme, models, and working features.
- Inspect the existing codebase first and understand the current Parent, Admin, Driver, Conductor, Student, Bus, Route, and Assignment models/services before making changes.
- Follow the existing project conventions and naming patterns.
- Do not introduce fake/mock data.
- Do not add QR/RFID/scanner functionality.
- Do not add unnecessary AI or hardware features.
- Make the implementation production-oriented and consistent with the existing Firebase data structure.

==================================================
OBJECTIVE
==================================================

Improve the PARENT role by restructuring child information and assigned staff information.

The Parent should be able to:

1. Select/view their children.
2. Open a dedicated Child Information section containing the child's complete relevant profile.
3. Open a separate Assigned Staff section showing the DRIVER and CONDUCTOR currently assigned to that child's bus/trip.
4. Open a separate Bus & Route section showing the child's current transportation assignment.
5. Edit only parent-managed information.
6. Clearly distinguish read-only school-controlled information from parent-editable information.
7. Ensure Driver and Conductor only receive the minimum child information required for safe transportation.
8. Ensure private parent information is NOT exposed to Driver/Conductor.
9. Ensure Admin has complete visibility and management capability.

==================================================
PARENT NAVIGATION
==================================================

Replace the current generic "Children & Assigned Staff" experience with a cleaner child-specific structure.

Parent navigation should be approximately:

Parent
│
├── Home
├── My Children
│     │
│     ├── Child Selection
│     │
│     └── Selected Child
│           ├── Child Info
│           ├── Assigned Staff
│           └── Bus & Route
│
├── Live Bus
├── Attendance
├── Notifications
├── Emergency
└── Profile

Do not duplicate existing navigation items if they already exist.
Modify the current implementation instead of creating duplicate screens.

==================================================
1. MY CHILDREN
==================================================

Create/improve the Parent "My Children" screen.

If a parent has multiple children:
- Display each child as a separate card.
- Show basic information:
  - Child name
  - Class
  - Section
  - Student ID where appropriate
  - Assigned bus
  - Current transportation/trip status where available
- Provide a clear "View Details" action.

The screen must only display children actually associated with the authenticated parent.

Do NOT show other students.

==================================================
2. CHILD INFORMATION
==================================================

Create a dedicated "Child Info" section/screen.

The screen should contain approximately 10–12+ meaningful fields, divided into appropriate categories.

A. SCHOOL-CONTROLLED / READ-ONLY INFORMATION

These should normally be read-only for the Parent:

- Full Name
- Student ID / Roll Number
- Date of Birth
- Class
- Section
- School
- Other school-generated identifiers that already exist in the project

These values should come from the existing student/admin-managed data.

Parent must NOT be able to arbitrarily modify these fields.

B. PARENT-MANAGED INFORMATION

Allow the authenticated Parent to submit/update appropriate information such as:

- Home Address
- Pickup Stop
- Drop-off Stop
- Emergency Contact
- Authorized Pickup Person
- Transportation/Special Instructions
- Other appropriate parent-provided information already supported by the application's data model

Do not expose unnecessary private parent information to Driver or Conductor.

==================================================
3. PARENT EDIT PERMISSIONS
==================================================

Clearly distinguish:

READ ONLY:
- School-controlled/student identity information.

EDITABLE:
- Parent-maintained contact/transportation information.

For editable information:
- Provide Edit buttons.
- Validate input.
- Save changes to Firebase using the existing service/repository architecture.
- Show loading state while saving.
- Show success/error feedback.
- Do not allow unauthenticated users to modify data.

IMPORTANT:

For operationally sensitive fields such as:
- Pickup Stop
- Drop-off Stop
- Transportation assignment
- Safety-related information

Do NOT blindly change the official operational assignment if the existing architecture supports admin approval.

Prefer:

Parent submits change
        ↓
Pending / Change Request
        ↓
Admin reviews
        ↓
Admin approves
        ↓
Official assignment/data changes

If the existing project does not have an approval workflow, implement the safest compatible approach without breaking the existing architecture.

Do not create a complicated approval system unless necessary.

==================================================
4. ASSIGNED STAFF
==================================================

Create a separate "Assigned Staff" section for each selected child.

IMPORTANT:

The screen must show staff assigned to THAT CHILD'S CURRENT BUS/TRIP.

Do NOT simply show all drivers and conductors in the school.

Determine the relationship using the existing:

Child → Bus Assignment → Route/Trip → Driver + Conductor

data structure.

Display the currently assigned:

A. DRIVER
- Name
- Employee ID if already available
- Profile photo if already supported
- Assigned bus
- Current duty/trip status where available
- Relevant professional information only

B. CONDUCTOR
- Name
- Employee ID if already available
- Profile photo if already supported
- Assigned bus
- Current duty/trip status where available
- Relevant professional information only

Do NOT expose private staff information such as:
- Home address
- Government IDs
- Private documents
- Personal/private information
- Any sensitive data not required by the Parent

If contact functionality already exists, use the existing safe school-approved contact mechanism.

Do not invent personal phone numbers or private contact information.

==================================================
5. BUS & ROUTE
==================================================

Create a separate "Bus & Route" section for the selected child.

Show relevant transportation information such as:

- Bus Number
- Route Name/Number
- Pickup Stop
- Drop-off Stop
- Current Trip Status
- Current Bus Location if available
- Next Stop if available
- ETA if already implemented
- Driver
- Conductor

Do not duplicate the complete Live Bus screen.

This section should primarily explain the child's current transportation assignment.

==================================================
6. DRIVER VISIBILITY
==================================================

Implement strict role-based visibility.

Driver should only see the minimum information required to safely transport the student.

Suggested Driver-visible information:

- Student Name
- Student photo only if already supported and permitted
- Class/Section if operationally useful
- Pickup Stop
- Drop-off Stop
- Boarding Status
- Relevant safety/transportation instructions
- Authorized pickup information where operationally required
- Important emergency/safety notes where appropriate

Driver should NOT see:

- Parent's complete profile
- Parent private notes
- Parent's private contact/profile information unless explicitly required and already approved
- Financial information
- Unrelated personal information
- Private medical information that is not relevant to transportation safety

==================================================
7. CONDUCTOR VISIBILITY
==================================================

Conductor should have a similar minimum-information model.

Conductor can see:

- Student Name
- Student photo if supported/permitted
- Class/Section where useful
- Pickup Stop
- Drop-off Stop
- Boarding Status
- Important transportation/safety instructions
- Authorized pickup information where required
- Important safety information necessary for the trip

Conductor should NOT see unrelated private parent information.

==================================================
8. ADMIN VISIBILITY
==================================================

Admin should have the complete operational view.

Admin should be able to:

- View complete student information
- View parent-managed information
- View assigned driver/conductor
- View bus assignment
- View route assignment
- Review parent-submitted changes where applicable
- Manage/approve sensitive transportation changes
- View relevant attendance/trip history
- Manage assignments

Respect the existing Admin architecture instead of creating a duplicate management system.

==================================================
9. DATA MODEL
==================================================

Before changing the database structure:

1. Inspect the existing Student model.
2. Inspect Parent model.
3. Inspect Driver model.
4. Inspect Conductor model.
5. Inspect Bus model.
6. Inspect Route model.
7. Inspect assignment relationships.
8. Inspect FirebaseService/repositories.
9. Inspect Firebase security rules.

Reuse existing fields wherever possible.

Do NOT create duplicate fields such as:

studentName
childName
name

when an existing canonical field already exists.

If a new field is genuinely required, add it consistently to:
- Model
- Firebase read/write logic
- UI
- Validation
- Security rules where required

==================================================
10. FIREBASE SECURITY
==================================================

Do not rely only on UI visibility.

Firebase security must enforce the role boundaries.

Parent:
- Can read their own children's information.
- Can update only permitted parent-managed fields.
- Cannot modify school-controlled fields.
- Cannot read another parent's child.
- Cannot read unrelated students.
- Cannot modify driver/conductor records.

Driver:
- Can read only students assigned to their current bus/trip as permitted.
- Cannot access unrelated student records.

Conductor:
- Can read only students assigned to their current bus/trip as permitted.
- Can update attendance only according to the existing attendance permissions.

Admin:
- Retain existing administrative permissions.

Review the existing database.rules.json before modifying it.

Do not weaken existing security rules.

==================================================
11. UI/UX REQUIREMENTS
==================================================

The Parent experience should be clean and easy to understand.

Use clear sections/cards:

My Children
↓
Select Child
↓
┌──────────────────────────────┐
│ Child Info                   │
│ Complete child information   │
└──────────────────────────────┘

┌──────────────────────────────┐
│ Assigned Staff               │
│ Driver + Conductor           │
└──────────────────────────────┘

┌──────────────────────────────┐
│ Bus & Route                  │
│ Bus + Route + Stops + Status │
└──────────────────────────────┘

Follow the existing application theme and reusable widgets.

Do not introduce a completely different visual design.

Handle:
- Loading
- Empty state
- Error state
- No assigned bus
- No assigned driver
- No assigned conductor
- Multiple children
- Offline state if applicable

==================================================
12. IMPORTANT EDGE CASES
==================================================

Handle these correctly:

1. Parent has no children.
2. Parent has multiple children.
3. Child has no bus assignment.
4. Child has a bus but no driver assigned.
5. Child has a bus but no conductor assigned.
6. Driver changes between trips.
7. Conductor changes between trips.
8. Child changes bus/route.
9. Parent submits an editable information change.
10. Firebase data is unavailable.
11. User logs out.
12. Parent attempts to access another student's ID directly.

Never fall back to a hardcoded bus such as:
bus_01

Assignments must come from authenticated/user-specific data.

==================================================
13. DO NOT BREAK EXISTING FEATURES
==================================================

Preserve:

- Authentication
- Role-based login
- Parent dashboard
- Driver workflow
- Conductor workflow
- Manual attendance
- Trip lifecycle
- Live GPS architecture
- Notifications
- Firebase integration
- Existing Admin features
- Existing security model
- Existing navigation unless changes are required for this feature

Do not reintroduce:
- QR scanner
- Badge scanner
- Scan animation
- RFID
- NFC
- Fake GPS
- Fake student/staff data

==================================================
14. IMPLEMENTATION PROCESS
==================================================

Before editing:

1. Inspect the existing codebase.
2. Identify relevant Parent screens.
3. Identify existing Student/Parent/Driver/Conductor models.
4. Identify Bus/Route/Trip assignment relationships.
5. Identify Firebase paths.
6. Identify Firebase security rules.
7. Identify reusable UI components.

Then implement the changes.

After implementation:

1. Run Flutter analyzer.
2. Fix all compilation errors.
3. Fix relevant warnings.
4. Verify imports after any file renaming.
5. Verify navigation.
6. Verify Firebase reads/writes.
7. Verify role-based access.
8. Verify Parent cannot access another child's information.
9. Verify Driver/Conductor visibility.
10. Verify Admin visibility.
11. Ensure no hardcoded bus/student IDs remain.
12. Check that the removed scanner system has not been reintroduced.

==================================================
FINAL RESULT
==================================================

The final Parent experience should communicate:

"My Children"
        ↓
Select Child
        ↓
┌──────────────┬────────────────┬──────────────┐
│ Child Info   │ Assigned Staff │ Bus & Route  │
└──────────────┴────────────────┴──────────────┘

Child Info:
Complete child profile with read-only + parent-editable fields.

Assigned Staff:
Only the Driver + Conductor currently assigned to that child's transportation.

Bus & Route:
Current bus, route, stops, trip status and relevant live information.

Privacy:
Parent → Full information about their own child.
Admin → Full operational information.
Driver → Minimum information required for safe transportation.
Conductor → Minimum information required for safe transportation.

The implementation must be clean, secure, role-aware, Firebase-compatible, and consistent with the existing project architecture.