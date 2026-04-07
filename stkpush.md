# M-PESA STK Push — Complete Developer Guide

> **App:** Mombasa County Enforcer App (Flutter)  
> **Module:** Offloading (Cess Fee Collection)  
> **Backend:** `https://eportal.mombasa.go.ke/mobile/android/cess/V2/`  
> **Payment Gateway:** M-PESA STK Push (via backend)

---

## Table of Contents

1. [Overview](#1-overview)
2. [Architecture & Key Files](#2-architecture--key-files)
3. [Step-by-Step Flow](#3-step-by-step-flow)
   - [Step 1 – Entry Point: offBoarding Screen](#step-1--entry-point-offboarding-screen)
   - [Step 2 – Prompt Payment Form (promptOffLoadingPayment)](#step-2--prompt-payment-form-promptoffloadingpayment)
   - [Step 3 – Enter Goods Details (goodDetailsAdd)](#step-3--enter-goods-details-gooddetailsadd)
   - [Step 4 – Create Application & Trigger STK Push (postOffloadingItems)](#step-4--create-application--trigger-stk-push-postoffloadingitems)
   - [Step 5 – Payment Dialog Shown to User (CheckPaymentDialog)](#step-5--payment-dialog-shown-to-user-checkpaymentdialog)
   - [Step 6 – Payment Status Polling (_checkOffLoaidngPaymentStatusRepeatedly)](#step-6--payment-status-polling-_checkoffloaidngpaymentstatusrepeatedly)
   - [Step 7 – Retry on Failure (_showRetryPhoneDialog)](#step-7--retry-on-failure-_showretryphonedialog)
   - [Step 8 – Application ID Recovery (_recoverApplicationId)](#step-8--application-id-recovery-_recoverapplicationid)
4. [API Endpoints Reference](#4-api-endpoints-reference)
5. [Backend Request/Response Contracts](#5-backend-requestresponse-contracts)
6. [Data Models](#6-data-models)
7. [Error Handling & Retry Logic](#7-error-handling--retry-logic)
8. [UI Components](#8-ui-components)
9. [Callback Chain (CheckPaymentDialogCallback)](#9-callback-chain-checkpaymentdialogcallback)
10. [Implementing This in Your Own App](#10-implementing-this-in-your-own-app)
11. [Full Code Snippets](#11-full-code-snippets)
12. [Backend Implementation: M-PESA Daraja API](#12-backend-implementation-m-pesa-daraja-api)
    - [12.1 Prerequisites & Credentials](#121-prerequisites--credentials)
    - [12.2 Step 1 – Get OAuth Access Token](#122-step-1--get-oauth-access-token)
    - [12.3 Step 2 – Build the STK Push Request](#123-step-2--build-the-stk-push-request)
    - [12.4 Step 3 – Send STK Push to Safaricom](#124-step-3--send-stk-push-to-safaricom)
    - [12.5 Step 4 – Handle the Callback (M-PESA → Your Server)](#125-step-4--handle-the-callback-m-pesa--your-server)
    - [12.6 Step 5 – Expose Check Payment Status to the App](#126-step-5--expose-check-payment-status-to-the-app)
    - [12.7 Full Node.js Implementation](#127-full-nodejs-implementation)
    - [12.8 PHP Implementation](#128-php-implementation)
    - [12.9 Database Schema](#129-database-schema)
    - [12.10 Testing with ngrok](#1210-testing-with-ngrok)
    - [12.11 Environment: Sandbox vs Production](#1211-environment-sandbox-vs-production)
    - [12.12 Security Checklist](#1212-security-checklist)
13. [Alternative: Flutter-Side PaymentService (No Backend)](#13-alternative-flutter-side-paymentservice-no-backend)
    - [13.1 When to Use This Approach](#131-when-to-use-this-approach)
    - [13.2 Full MpesaPaymentService Class](#132-full-mpesapaymentservice-class)
    - [13.3 Using It in Your Widget](#133-using-it-in-your-widget)
    - [13.4 The Callback Problem](#134-the-callback-problem)
    - [13.5 STK Push Query (Polling Alternative)](#135-stk-push-query-polling-alternative)
    - [13.6 Backend vs Flutter-Side — Comparison](#136-backend-vs-flutter-side--comparison)
14. [Multi-Tenant M-PESA (Per-Tenant Paybill/Till)](#14-multi-tenant-m-pesa-per-tenant-paybilltill)
    - [14.1 Architecture Overview](#141-architecture-overview)
    - [14.2 Tenant Credentials Model](#142-tenant-credentials-model)
    - [14.3 Backend Approach (Recommended)](#143-backend-approach-recommended)
    - [14.4 Flutter-Side Approach (Dynamic PaymentService)](#144-flutter-side-approach-dynamic-paymentservice)
    - [14.5 Tenant-Aware Callback Routing](#145-tenant-aware-callback-routing)
    - [14.6 Security Considerations](#146-security-considerations)
15. [Simplified Tenant Configuration ("Just Enter Your Paybill")](#15-simplified-tenant-configuration-just-enter-your-paybill)
    - [15.1 The Reality of M-PESA Credentials](#151-the-reality-of-m-pesa-credentials)
    - [15.2 Approach A — Aggregator Model (One Paybill, Many Tenants)](#152-approach-a--aggregator-model-one-paybill-many-tenants)
    - [15.3 Approach B — Tenant Enters Paybill + You Provision Credentials](#153-approach-b--tenant-enters-paybill--you-provision-credentials)
    - [15.4 Approach C — C2B Payment (No STK Push)](#154-approach-c--c2b-payment-no-stk-push)
    - [15.5 Flutter Configuration Screen](#155-flutter-configuration-screen)
    - [15.6 Storing Tenant Config in Firestore](#156-storing-tenant-config-in-firestore)
    - [15.7 Using the Tenant’s Paybill at Payment Time](#157-using-the-tenants-paybill-at-payment-time)
    - [15.8 Which Approach Should You Use?](#158-which-approach-should-you-use)
16. [Scaling to 100+ Tenants (The Aggregator Pattern)](#16-scaling-to-100-tenants-the-aggregator-pattern)
    - [16.1 The "100 Apps" Problem](#161-the-100-apps-problem)
    - [16.2 Solution 1: Use an Aggregator (Highly Recommended)](#162-solution-1-use-an-aggregator-highly-recommended)
    - [16.3 Solution 2: Daraja Multi-Shortcode Pattern](#163-solution-2-daraja-multi-shortcode-pattern)
    - [16.4 Automatic Reconciliation (Routing Payments)](#164-automatic-reconciliation-routing-payments)
    - [16.5 Automated Disbursements (Payouts)](#165-automated-disbursements-payouts)

---

## 1. Overview

The STK Push in this app is **M-PESA's Lipa Na M-PESA Online API** (commonly called STK Push / C2B Push). When a payment is required:

1. The **Flutter app collects** the client's phone number and cess goods details.
2. The app **POST**s to the backend to **create an application** — the backend then calls M-PESA's STK Push API and sends a payment prompt to the client's phone.
3. The backend returns a `tracking_id` (a unique reference for this transaction).
4. The Flutter app **polls** the backend every 5 seconds (for up to 30 seconds) using that `tracking_id` to check if the user approved or rejected the prompt on their phone.
5. Based on the poll result the app shows success/failure and allows **up to 3 retries**.

**The STK Push itself is entirely backend-driven** — the Flutter app never communicates with M-PESA directly. All M-PESA API credentials live on the server.

---

## 2. Architecture & Key Files

```
lib/
├── Api/
│   ├── api_provider.dart       ← All HTTP calls (Dio). STK-related methods here.
│   └── endpoints.dart          ← All base URLs and endpoint constants
├── Screens/
│   └── OffLoading/
│       ├── off_loading.dart            ← Main screen. Owns CheckPaymentDialog & polling logic.
│       ├── promptPayment.dart          ← Step 1 form: vehicle, zone, client info, phone
│       ├── enterGoodDetails.dart       ← Step 2 form: items, UOM, quantity. Submits application.
│       ├── penalizePromptPayment.dart  ← Same flow but for penalized vehicles
│       ├── PenalizedEnterGoodDetails.dart ← Penalized version of enterGoodDetails
│       ├── offLoadingDetails.dart      ← View existing application, re-trigger payment
│       ├── DailyoffLoadingApplicationDeatils.dart ← Re-trigger STK for saved applications
│       └── off-loading-list.dart       ← List of daily applications
└── widgets/
    └── payment_dialog.dart     ← Animated "Payment Initiated. Please wait..." dialog
```

**Key classes and their responsibilities:**

| Class / Method | File | Responsibility |
|---|---|---|
| `offBoarding` | `off_loading.dart` | Main screen, owns `CheckPaymentDialog` |
| `CheckPaymentDialog()` | `off_loading.dart` | Shows loading UI, starts polling |
| `_checkOffLoaidngPaymentStatusRepeatedly()` | `off_loading.dart` | Polls backend every 5s, 30s timeout |
| `_showRetryPhoneDialog()` | `off_loading.dart` | Confirms phone number, re-triggers STK |
| `_recoverApplicationId()` | `off_loading.dart` | Two-tier fallback to recover application ID |
| `promptOffLoadingPayment` | `promptPayment.dart` | Collects vehicle & client data |
| `goodDetailsAdd` | `enterGoodDetails.dart` | Collects goods, submits to backend |
| `ApiProvider.postOffloadingItems()` | `api_provider.dart` | Creates application + triggers STK push |
| `ApiProvider.promptPaymentOfSavedApplications()` | `api_provider.dart` | Re-triggers STK for existing application |
| `ApiProvider.checkOffLoadingPaymentStatus()` | `api_provider.dart` | Polls payment status by tracking ID |
| `ApiProvider.getLastpaymentCess()` | `api_provider.dart` | Gets last payment record for a plate |
| `paymentDialog` | `widgets/payment_dialog.dart` | Animated "waiting" dialog with Lottie + typewriter |

---

## 3. Step-by-Step Flow

### Step 1 – Entry Point: offBoarding Screen

**File:** `lib/Screens/OffLoading/off_loading.dart`

The user lands on the Offloading screen. On `initState()`:

```dart
permissionsFuture = ApiProvider().checkPermission(
  permissionType: 'Access OffLoading',
  token: widget.token,
);
offLoadingStatsFuture = ApiProvider().getOffLoadingStats(token: widget.token);
```

The `FutureBuilder` gates access — if `permissionResult['access'] == true`, the user sees the full UI. Otherwise access is denied.

The screen provides a `CheckPaymentDialog` method (see Step 5) that is passed down as a callback to all child screens. **This callback is the entry point for the STK Push UI.**

The screen can trigger a new payment from two sources:
1. **New application** → navigates to `promptOffLoadingPayment`
2. **Existing application** → calls `promptPaymentOfSavedApplications` then `CheckPaymentDialog`

---

### Step 2 – Prompt Payment Form (promptOffLoadingPayment)

**File:** `lib/Screens/OffLoading/promptPayment.dart`  
**Class:** `promptOffLoadingPayment`

This screen collects vehicle and client information before payment can be processed.

**Fields collected:**

| Field | Type | Validation |
|---|---|---|
| Origin | Dropdown (String) | List of 47 Kenyan counties |
| Destination | Fixed `"Mombasa"` | Read-only, not changeable |
| Zone | Dropdown from API (`getZones`) | Required |
| Vehicle Type | Dropdown from API (`getVehicleTypes`) | Required |
| Plate Number | Text field | Regex: `^[a-zA-Z]{3}\d{3}[a-zA-Z]$` |
| Client First Name | Text field | `>= 3 chars, no digits` |
| Client Last Name | Text field | `>= 3 chars, no digits` |
| Client Phone | International phone input (KE only) | `intl_phone_number_input` package |

**Constructor parameters passed in:**

```dart
promptOffLoadingPayment({
  required this.token,                    // Bearer token for API calls
  required this.CheckPaymentDialogCallback, // The callback from off_loading.dart
  required this.capturedPlate,            // Pre-filled plate (or null)
  required this.capturedOrigin,           // Pre-filled origin (or null)
  required this.capturedClientName,       // Pre-filled name (or null)
  required this.capturedVehicleId,        // Pre-filled vehicle type ID (or null)
  required this.capturedPhone,            // Pre-filled phone (or null)
  required this.capturedApplicationId,    // Existing app ID if re-prompting
  this.navigateBackAgain = "Once",        // How many screens to pop after success
})
```

The `navigateBackAgain` parameter controls how many `Navigator.pop()` calls happen after a successful payment. Values: `"Once"`, `"Thrice"`, `"Four"`.

**On Submit:** Validates the form, then navigates to `goodDetailsAdd`.

---

### Step 3 – Enter Goods Details (goodDetailsAdd)

**File:** `lib/Screens/OffLoading/enterGoodDetails.dart`  
**Class:** `goodDetailsAdd`

The user selects one or more goods (items), their Unit of Measure (UOM), and quantity. Each item's total is calculated as `rate × quantity`. Items accumulate in a `selectedProductsList`.

**On `initState()`:**
```dart
itemsFuture = ApiProvider().getOffLoadingItems(token: widget.token);
```

**Item selection rules:**
- Flat Rate UOMs are mutually exclusive with per-unit UOMs for the same item.
- Flat Rate UOM sets quantity = 1 automatically (read-only).
- Vehicle type must match the selected Flat Rate option (e.g., "Pick Up" vehicle can only select Flat Rate UOM containing "Pick").

**On Submit (`_submitForm()`):**

1. Validates: `selectedProductsList` not empty + declaration checkbox checked.
2. Builds the `postData` list:
   ```dart
   List<Map<String, dynamic>> postData = selectedProductsList.map((product) {
     return {
       'id': product.itemChosen!.itemId,
       'amount': product.itemChosen!.rate,
       'quantity': product.quantity,
     };
   }).toList();
   ```
3. Calls `ApiProvider().postOffloadingItems(...)` — this **creates the application and triggers the STK Push** on the backend.
4. On **success** (`value['status'] == "success"`):
   - Pops screens according to `navigateBackAgain`.
   - Extracts `newAppId` from the response (tries multiple keys for robustness).
   - Calls **`widget.CheckPaymentDialogCallback!(...)`** with:
     - `trackingId` — the backend's tracking reference
     - `applicationId` — the application's DB ID
     - `clientPhone` — the phone that was STK-pushed
     - `plateNumber`
     - `resubmitCallback` — a function to re-run `_submitForm()` with a new phone number
5. On **failure**: Shows `_showRetrySubmitPhoneDialog()` — allows user to fix phone number and retry form submission (which triggers a fresh STK push).

---

### Step 4 – Create Application & Trigger STK Push (postOffloadingItems)

**File:** `lib/Api/api_provider.dart`  
**Method:** `postOffloadingItems()`

This is where the actual STK Push is initiated. The Flutter app sends all application data to the backend, and the backend handles the M-PESA API call.

```dart
Future<Map<String, dynamic>> postOffloadingItems({
  required String token,
  required String vehicleType,
  required String plateNumber,
  required String clientName,
  required String clientPhone,   // ← This phone receives the STK Push
  required String zone,
  required List<Map<String, dynamic>> items,
  required int penalty,
}) async {
  result = await Dio().post(
    Endpoints.OFFLOADING_URL,  // https://eportal.mombasa.go.ke/mobile/android/cess/V2/
    data: {
      "appType": "createApplication",
      "origin": "Mombasa",
      "destination": "Mombasa",
      "vehicleType": vehicleType,
      "plateNumber": plateNumber,
      "clientName": clientName,
      "clientPhoneNumber": clientPhone,
      "zone": zone,
      "items": items,
      "penalty": penalty,
    },
    options: Options(
      preserveHeaderCase: true,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    ),
  );
}
```

**Expected successful response:**
```json
{
  "status": "success",
  "tracking_id": "ABC123XYZ",
  "application_id": 4521,
  "data": { ... }
}
```

The `tracking_id` is what you use to poll payment status. The `application_id` is the DB record for this cess application.

---

### Step 5 – Payment Dialog Shown to User (CheckPaymentDialog)

**File:** `lib/Screens/OffLoading/off_loading.dart`  
**Method:** `CheckPaymentDialog()`

This method is **owned by `offBoarding`** (the top-level screen) and passed down as a callback. It is the "entry point" for the UI side of the STK Push.

```dart
Future<void> CheckPaymentDialog({
  trackingId,
  applicationId,
  clientPhone,
  String? plateNumber,
  int promptCount = 1,             // Tracks retry attempts (max 3)
  Function(String newPhone)? resubmitCallback,
}) async {
  // 1. Show non-dismissable loading dialog
  showDialog(
    barrierDismissible: false,
    context: context,
    builder: (ctx) => WillPopScope(
      onWillPop: () async => false,
      child: paymentDialog(message: "Payment Initiated. Please wait...."),
    ),
  );

  // 2. Start polling
  await _checkOffLoaidngPaymentStatusRepeatedly(
    trackingId: trackingId,
    applicationId: applicationId,
    clientPhone: clientPhone,
    plateNumber: plateNumber,
    promptCount: promptCount,
    resubmitCallback: resubmitCallback,
  );
}
```

The `paymentDialog` widget (`lib/widgets/payment_dialog.dart`) shows:
- A Lottie loading animation (`assets/lotti/loadingPayment1.json`)
- A typewriter-animated message ("Payment Initiated. Please wait....")
- No dismiss button — user cannot close it

---

### Step 6 – Payment Status Polling (_checkOffLoaidngPaymentStatusRepeatedly)

**File:** `lib/Screens/OffLoading/off_loading.dart`  
**Method:** `_checkOffLoaidngPaymentStatusRepeatedly()`

This is the core polling loop.

```
Timeout: 30 seconds
Poll interval: 5 seconds (on each "still pending" response)
Max retries: 3
```

**Logic:**

```dart
final startTime = DateTime.now();
const timeout = Duration(seconds: 30);

while (DateTime.now().difference(startTime) < timeout) {
  try {
    Map<String, dynamic> checkstatus = await ApiProvider()
        .checkOffLoadingPaymentStatus(
          token: widget.token,
          trackingId: trackingId,
        );

    if (checkstatus['status'] == "success") {
      // Try to recover applicationId from status response if missing
      if (applicationId == null || applicationId.toString() == 'null') {
        applicationId = checkstatus['application_id']?.toString()
            ?? checkstatus['id']?.toString()
            ?? checkstatus['applicationId']?.toString();
      }

      if (checkstatus['data'] == "Completed") {
        // ✅ PAYMENT SUCCESS
        Navigator.of(context).pop();       // Dismiss loading dialog
        _showSuccessDialog("Fee Payment Successfully Received");
        return;

      } else if (checkstatus['data'] == "Failed") {
        // ❌ PAYMENT FAILED → offer retry (up to 3 times)
        Navigator.of(context).pop();
        if (applicationId == null) applicationId = await _recoverApplicationId(plateNumber);
        if (promptCount < 3 && clientPhone != null) {
          _showRetryPhoneDialog(applicationId, clientPhone, promptCount, ...);
        } else {
          _showErrorDialog(checkstatus['message'] ?? "Payment Failed");
        }
        return;

      } else {
        // ⏳ Still pending
        await Future.delayed(Duration(seconds: 5));
      }

    } else {
      // Status API returned non-success → treat as failure → retry
      Navigator.of(context).pop();
      if (applicationId == null) applicationId = await _recoverApplicationId(plateNumber);
      if (promptCount < 3) {
        _showRetryPhoneDialog(...);
      } else {
        _showErrorDialog(checkstatus['message']);
      }
      return;
    }

  } catch (e) {
    // Network error → retry if under limit
    Navigator.of(context).pop();
    if (applicationId == null) applicationId = await _recoverApplicationId(plateNumber);
    if (promptCount < 3) {
      _showRetryPhoneDialog(...);
    } else {
      _showErrorDialog(e.toString());
    }
    return;
  }
}

// ⏱ 30-second timeout reached
Navigator.of(context).pop();
if (applicationId == null) applicationId = await _recoverApplicationId(plateNumber);
if (promptCount < 3) {
  _showRetryPhoneDialog(...);
} else {
  _showErrorDialog("Connection Timed Out Without payment Confirmation");
}
```

**Status poll API (`checkOffLoadingPaymentStatus`):**

```dart
GET Endpoints.OFFLOADING_URL
  ?appType=checkPaymentStatus
  &trackingId={trackingId}
Authorization: Bearer {token}
```

**Response shape:**
```json
{
  "status": "success",
  "data": "Completed"     // or "Failed" or "Pending"
}
```

---

### Step 7 – Retry on Failure (_showRetryPhoneDialog)

**File:** `lib/Screens/OffLoading/off_loading.dart`  
**Method:** `_showRetryPhoneDialog()`

This dialog is shown when payment fails. It increments `promptCount`. The dialog:
- Shows the current client phone number in an editable `InternationalPhoneNumberInput`
- Has a **"Prompt"** button and a **"Cancel"** button

**Two scenarios when "Prompt" is pressed:**

#### Scenario A — New Application (no `applicationId` yet)
Used when the original application creation failed to return an ID. Uses `resubmitCallback` to **re-run the entire `_submitForm()`** from `enterGoodDetails.dart` with the corrected phone. This creates a fresh application and a new STK Push.

```dart
if (applicationId == null && resubmitCallback != null) {
  resubmitCallback(_fullPhoneNumber);  // Re-runs _submitForm() with new phone
  return;
}
```

#### Scenario B — Existing Application (has `applicationId`)
Used when the application was created successfully but the STK push failed/timed out. Calls `promptPaymentOfSavedApplications` to re-trigger the STK push for the existing application without creating a new record.

```dart
var value = await ApiProvider().promptPaymentOfSavedApplications(
  token: widget.token,
  applicationId: int.tryParse(applicationId) ?? 0,
  clientPhone: _fullPhoneNumber,
);

if (value['status'] == "success") {
  CheckPaymentDialog(
    trackingId: value['tracking_id'].toString(),
    applicationId: applicationId,
    clientPhone: _fullPhoneNumber,
    promptCount: promptCount + 1,    // Increment retry counter
    resubmitCallback: resubmitCallback,
  );
}
```

**Re-prompt API:**
```json
POST Endpoints.OFFLOADING_URL
{
  "appType": "promptOffloadingApplicationPayment",
  "applicationId": 4521,
  "clientPhoneNumber": "+254712345678"
}
```

---

### Step 8 – Application ID Recovery (_recoverApplicationId)

**File:** `lib/Screens/OffLoading/off_loading.dart`  
**Method:** `_recoverApplicationId()`

Sometimes the `applicationId` is not returned in the initial `postOffloadingItems` response, or gets lost in navigation. This two-tier fallback system attempts to recover it before allowing a retry.

**Tier 1 — Direct "last record" API:**
```dart
GetVehicleLastPaymentCess lastApp = await ApiProvider().getLastpaymentCess(
  token: widget.token,
  plateNumber: plateNumber,
);
if (lastApp.status == "success" && lastApp.data != null) {
  return lastApp.data?.applicationId?.toString();
}
```

**Tier 2 — Full daily applications list scan (highest reliability):**
```dart
GetDailyOffloadingApplications dailyApps = await ApiProvider()
    .getDailyOffloadingApplications(token: widget.token);

dailyApps.data.sort((a, b) => b.id.compareTo(a.id)); // Newest first

final match = dailyApps.data.firstWhereOrNull(
    (app) => app.plateNo?.toUpperCase() == plateNumber.toUpperCase()
);
if (match != null) return match.id.toString();
```

---

## 4. API Endpoints Reference

All endpoints share the base URL defined in `lib/Api/endpoints.dart`:

```dart
static const String MAIN_URL = "https://eportal.mombasa.go.ke/mobile/android/";
static const String OFFLOADING_URL = "${MAIN_URL}cess/V2/";
static const String PERMISSION_URL = "${MAIN_URL}staff/checkAppPermission.php";
```

| Operation | Method | URL | `appType` param |
|---|---|---|---|
| Check permission | POST | `OFFLOADING_URL` | — (uses separate endpoint) |
| Get offloading stats | GET | `OFFLOADING_URL` | `getStats` |
| Get zones | GET | `OFFLOADING_URL` | `getZones` |
| Get vehicle types | GET | `OFFLOADING_URL` | `getVehicleTypes` |
| Get cess items | GET | `OFFLOADING_URL` | `getItems` |
| Get penalty rates | GET | `OFFLOADING_URL` | `getPenaltyRates` |
| Get last cess payment | GET | `OFFLOADING_URL` | `checkStatus` + `plateNumber` |
| Get daily applications | GET | `OFFLOADING_URL` | `getTasks` |
| **Create application (→ STK Push)** | **POST** | **`OFFLOADING_URL`** | **`createApplication`** |
| **Re-prompt payment** | **POST** | **`OFFLOADING_URL`** | **`promptOffloadingApplicationPayment`** |
| **Check payment status** | **GET** | **`OFFLOADING_URL`** | **`checkPaymentStatus`** |

---

## 5. Backend Request/Response Contracts

### 5.1 Create Application (triggers STK Push)

**Request:**
```json
POST https://eportal.mombasa.go.ke/mobile/android/cess/V2/
Authorization: Bearer {token}
Content-Type: application/json

{
  "appType": "createApplication",
  "origin": "Kisumu",
  "destination": "Mombasa",
  "vehicleType": "3",
  "plateNumber": "KAA123B",
  "clientName": "John Doe",
  "clientPhoneNumber": "+254712345678",
  "zone": "2",
  "items": [
    {
      "id": "15",
      "amount": 500.0,
      "quantity": "10"
    }
  ],
  "penalty": 0
}
```

**Success Response:**
```json
{
  "status": "success",
  "tracking_id": "WS_CO_04112024131424_241924_254712345678",
  "application_id": 4521,
  "message": "STK Push sent successfully"
}
```

**Failure Response:**
```json
{
  "status": "error",
  "message": "The number 0712345678 is not a valid Safaricom number"
}
```

---

### 5.2 Re-prompt Payment (for existing application)

**Request:**
```json
POST https://eportal.mombasa.go.ke/mobile/android/cess/V2/
Authorization: Bearer {token}
Content-Type: application/json

{
  "appType": "promptOffloadingApplicationPayment",
  "applicationId": 4521,
  "clientPhoneNumber": "+254712345678"
}
```

**Success Response:**
```json
{
  "status": "success",
  "tracking_id": "WS_CO_04112024131600_241925_254712345678",
  "message": "STK Push re-sent"
}
```

---

### 5.3 Check Payment Status

**Request:**
```
GET https://eportal.mombasa.go.ke/mobile/android/cess/V2/
  ?appType=checkPaymentStatus
  &trackingId=WS_CO_04112024131424_241924_254712345678
Authorization: Bearer {token}
```

**Response (still pending):**
```json
{
  "status": "success",
  "data": "Pending"
}
```

**Response (completed):**
```json
{
  "status": "success",
  "data": "Completed",
  "application_id": 4521
}
```

**Response (failed):**
```json
{
  "status": "success",
  "data": "Failed",
  "message": "Request cancelled by user"
}
```

---

## 6. Data Models

### GetVehicleLastPaymentCess
**File:** `lib/Models/Offloading/getLastCessMadeApplication.dart`

```dart
class GetVehicleLastPaymentCess {
  String? status;
  VehicleLastPaymentData? data;
  // data.applicationId ← the ID we need for re-prompting
}
```

### GetDailyOffloadingApplications
**File:** `lib/Models/Offloading/getDailyOffloadingApplications.dart`

```dart
class GetDailyOffloadingApplications {
  String? status;
  List<DailyOffloadingApplication> data;
  // Each item has: .id, .plateNo, .clientName, .status
}
```

### GetOffloadingItems
**File:** `lib/Models/Offloading/getOffloadingItems.dart`

```dart
class GetOffloadingItems {
  Map<String, List<OffLoadingItemsDatum>>? data;
  // Map key = item category name
  // Each datum has: itemId, itemName, uom, rate
}
```

### OffLoadingItemsDatum

| Field | Type | Description |
|---|---|---|
| `itemId` | `int` | Sent in POST as `id` |
| `itemName` | `String` | Display name |
| `uom` | `String` | Unit of Measure. "Flat Rate" items use fixed qty 1 |
| `rate` | `double` | Price per unit. `total = rate × quantity` |

---

## 7. Error Handling & Retry Logic

### Retry Limits

| Scenario | Max Retries |
|---|---|
| Payment fails (M-PESA declined/cancelled) | 3 |
| Network error during status poll | 3 |
| 30-second timeout without confirmation | 3 |
| Failed initial form submission (bad phone) | Unlimited (no cap) |

### promptCount Logic

`promptCount` starts at `1`. Each time `CheckPaymentDialog` is re-called (via `_showRetryPhoneDialog`), it is called with `promptCount + 1`.

```dart
if (promptCount < 3 && clientPhone != null) {
  _showRetryPhoneDialog(applicationId, clientPhone, promptCount, ...);
} else {
  _showErrorDialog("Connection Timed Out Without payment Confirmation");
}
```

When `promptCount >= 3` the user sees a final error dialog with no retry option.

### Error Triggers

| Trigger | Condition |
|---|---|
| `_showErrorDialog` | promptCount >= 3 OR user cancels retry dialog |
| `_showRetryPhoneDialog` | Any failure with promptCount < 3 |
| `_showSuccessDialog` | `checkstatus['data'] == "Completed"` |

### Headers — preserveHeaderCase

All Dio calls in this app use `preserveHeaderCase: true` to prevent Dio from lowercasing the `Authorization` header (which causes 401 errors on some servers):

```dart
options: Options(
  preserveHeaderCase: true,
  headers: {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  },
),
```

---

## 8. UI Components

### paymentDialog
**File:** `lib/widgets/payment_dialog.dart`

```dart
paymentDialog({
  required String message,
  String dialogLotti = 'assets/lotti/loadingPayment1.json',
})
```

- Shows a `Lottie.asset()` animation (100×100)
- Uses `AnimatedTextKit` with `TypewriterAnimatedText` for the message
- Typewriter speed: 100ms per character, repeats 3 times
- Wrapped in `WillPopScope(onWillPop: () async => false)` — user cannot dismiss

### _showSuccessDialog / _showErrorDialog

Both use the `FailedDialog` widget. For success, a different `dialogLotti` path is provided:

```dart
void _showSuccessDialog(String message) {
  showDialog(context: context, builder: (ctx) => FailedDialog(
    dialogLotti: 'assets/lotti/success.json',
    message: message,
  ));
}

void _showErrorDialog(String message) {
  showDialog(context: context, builder: (ctx) => FailedDialog(
    message: message,
  ));
}
```

### _showRetryPhoneDialog (inside off_loading.dart and enterGoodDetails.dart)

- Uses `InternationalPhoneNumberInput` with `countries: ["KE"]`
- Pre-fills the current `clientPhone`
- Has "Cancel" (red) and "Prompt" / "Retry Request" (green) buttons
- Validates phone before allowing retry

---

## 9. Callback Chain (CheckPaymentDialogCallback)

`CheckPaymentDialog` is the method on the top-level `offBoarding` widget. It is passed **down** through the navigation stack as a `Function?` callback so child screens remain decoupled.

```
offBoarding (off_loading.dart)
  └── defines: CheckPaymentDialog()
      │
      ├── promptOffLoadingPayment (promptPayment.dart)
      │     └── passes CheckPaymentDialogCallback down
      │         └── goodDetailsAdd (enterGoodDetails.dart)
      │               └── calls widget.CheckPaymentDialogCallback!(...)
      │
      ├── offLoadingList (off-loading-list.dart)
      │     └── passes CheckPaymentDialogCallback down
      │         └── offLoadingDetails (offLoadingDetails.dart)
      │               └── calls widget.CheckPaymentDialogCallback!(...)
      │
      ├── penalizePromptPayment (penalizePromptPayment.dart)
      │     └── passes CheckPaymentDialogCallback down
      │         └── PenalizedEnterGoodDetails
      │               └── calls widget.CheckPaymentDialogCallback!(...)
      │
      └── DailyoffLoadingApplicationDeatils
            └── calls widget.CheckPaymentDialogCallback!(...)
```

**Callback signature:**
```dart
widget.CheckPaymentDialogCallback!(
  trackingId: value['tracking_id'].toString(),
  applicationId: newAppId,
  clientPhone: widget.clientPhone,
  plateNumber: widget.plateNumber,
  resubmitCallback: (String newPhone) {
    if (mounted) {
      setState(() => widget.clientPhone = newPhone);
      _submitForm();
    }
  },
);
```

---

## 10. Implementing This in Your Own App

Follow these steps to replicate this STK Push flow in a Flutter app:

### Step 1: Set Up Backend

You need a backend that:
1. Accepts `createApplication` POST → calls M-PESA STK Push API → saves application to DB → returns `tracking_id` and `application_id`.
2. Accepts `checkPaymentStatus` GET with `trackingId` → checks M-PESA callback result in DB → returns `"Completed"`, `"Pending"`, or `"Failed"`.
3. Accepts `promptOffloadingApplicationPayment` POST → re-triggers STK for existing application.  

M-PESA STK Push (Daraja API) requires:
- Business Short Code
- Passkey
- Consumer Key + Secret (for OAuth token)
- Callback URL registered with Safaricom

### Step 2: Add Dependencies (pubspec.yaml)

```yaml
dependencies:
  dio: ^5.x.x                       # HTTP client
  intl_phone_number_input: ^0.7.x   # Phone number input with country picker
  lottie: ^2.x.x                    # Animated loading/success dialogs
  animated_text_kit: ^4.x.x         # Typewriter animation in dialog
  get: ^4.x.x                       # GetX for snackbars and navigation
  dropdown_search: ^5.x.x           # Searchable dropdowns
  google_fonts: ^5.x.x              # Typography
```

### Step 3: Create the ApiProvider Methods

```dart
// 1. Create application + trigger STK Push
Future<Map<String, dynamic>> createApplication({
  required String token,
  required String clientPhone,
  required String plateNumber,
  required List<Map<String, dynamic>> items,
  // ... other fields
}) async {
  final result = await Dio().post(
    'YOUR_BACKEND_URL',
    data: {
      "appType": "createApplication",
      "clientPhoneNumber": clientPhone,
      "plateNumber": plateNumber,
      "items": items,
      // ...
    },
    options: Options(
      preserveHeaderCase: true,
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
    ),
  );
  return result.data;
}

// 2. Check payment status
Future<Map<String, dynamic>> checkPaymentStatus({
  required String token,
  required String trackingId,
}) async {
  final response = await Dio().get(
    'YOUR_BACKEND_URL',
    queryParameters: {'appType': 'checkPaymentStatus', 'trackingId': trackingId},
    options: Options(
      preserveHeaderCase: true,
      headers: {'Authorization': 'Bearer $token'},
    ),
  );
  return response.data;
}

// 3. Re-trigger STK for existing application
Future<Map<String, dynamic>> repromptPayment({
  required String token,
  required int applicationId,
  required String clientPhone,
}) async {
  final result = await Dio().post(
    'YOUR_BACKEND_URL',
    data: {
      "appType": "promptOffloadingApplicationPayment",
      "applicationId": applicationId,
      "clientPhoneNumber": clientPhone,
    },
    options: Options(
      preserveHeaderCase: true,
      headers: {'Authorization': 'Bearer $token'},
    ),
  );
  return result.data;
}
```

### Step 4: Implement the Polling Loop

```dart
// In your main/parent screen (stateful widget):
Future<void> startPaymentFlow({
  required String trackingId,
  required String? applicationId,
  required String clientPhone,
  int promptCount = 1,
}) async {
  // Show loading dialog (non-dismissable)
  showDialog(
    barrierDismissible: false,
    context: context,
    builder: (ctx) => WillPopScope(
      onWillPop: () async => false,
      child: PaymentLoadingDialog(),
    ),
  );

  // Poll for up to 30 seconds
  final startTime = DateTime.now();
  while (DateTime.now().difference(startTime) < Duration(seconds: 30)) {
    try {
      final status = await ApiProvider().checkPaymentStatus(
        token: yourToken,
        trackingId: trackingId,
      );

      if (status['data'] == 'Completed') {
        Navigator.of(context).pop();
        showSuccessDialog("Payment received!");
        return;
      } else if (status['data'] == 'Failed') {
        Navigator.of(context).pop();
        if (promptCount < 3) {
          showRetryDialog(applicationId, clientPhone, promptCount);
        } else {
          showErrorDialog("Payment failed");
        }
        return;
      }
      // Still pending
      await Future.delayed(Duration(seconds: 5));
    } catch (e) {
      Navigator.of(context).pop();
      if (promptCount < 3) {
        showRetryDialog(applicationId, clientPhone, promptCount);
      } else {
        showErrorDialog(e.toString());
      }
      return;
    }
  }

  // Timeout
  Navigator.of(context).pop();
  if (promptCount < 3) {
    showRetryDialog(applicationId, clientPhone, promptCount);
  } else {
    showErrorDialog("Connection timed out");
  }
}
```

### Step 5: Phone Number Input

Use `intl_phone_number_input` for proper Kenyan phone number handling:

```dart
InternationalPhoneNumberInput(
  countries: ["KE"],
  onInputChanged: (PhoneNumber number) {
    _fullPhoneNumber = number.phoneNumber ?? ''; // e.g. "+254712345678"
  },
  onInputValidated: (isValid) => setState(() => _isValidNumber = isValid),
  selectorConfig: SelectorConfig(
    selectorType: PhoneInputSelectorType.DROPDOWN,
    setSelectorButtonAsPrefixIcon: true,
    useEmoji: true,
  ),
  initialValue: PhoneNumber(isoCode: 'KE'),
  textFieldController: _phoneController,
  formatInput: true,
  errorMessage: 'Please enter a valid phone number',
)
```

The phone number must be sent to M-PESA in Safaricom international format: `+254XXXXXXXXX` (no leading `0`).

### Step 6: Pass Callback Downward

Instead of passing `BuildContext` through screens (which causes issues), define the polling method in the top-level screen and pass it as a `Function?` callback:

```dart
// Parent screen
class MyParentScreen extends StatefulWidget { ... }
class _MyParentScreenState extends State<MyParentScreen> {
  Future<void> openPaymentFlow({trackingId, applicationId, clientPhone, ...}) async {
    // Show dialog + poll ...
  }

  @override
  Widget build(BuildContext context) {
    return ChildScreen(
      paymentCallback: openPaymentFlow,  // Pass this down
    );
  }
}
```

---

## 11. Full Code Snippets

### paymentDialog Widget

```dart
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

class PaymentLoadingDialog extends StatelessWidget {
  final String message;
  final String lottieAsset;

  const PaymentLoadingDialog({
    Key? key,
    this.message = "Payment Initiated. Please wait....",
    this.lottieAsset = 'assets/lotti/loadingPayment1.json',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset(lottieAsset, repeat: true, width: 100, height: 100),
            const SizedBox(height: 25),
            AnimatedTextKit(
              animatedTexts: [
                TypewriterAnimatedText(
                  message,
                  textAlign: TextAlign.center,
                  textStyle: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                  speed: Duration(milliseconds: 100),
                ),
              ],
              totalRepeatCount: 3,
            ),
            const SizedBox(height: 25),
          ],
        ),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}
```

### Retry Phone Dialog Snippet

```dart
Future<void> showRetryDialog(String? applicationId, String clientPhone, int promptCount) async {
  String _fullPhoneNumber = clientPhone;
  bool _isValidNumber = true;

  bool? confirmed = await showDialog<bool>(
    barrierDismissible: false,
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setStateDialog) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Confirm Phone Number", style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Text("Attempt ${promptCount} of 3. Please confirm the client's phone number:"),
            SizedBox(height: 15),
            InternationalPhoneNumberInput(
              countries: ["KE"],
              onInputChanged: (num) => _fullPhoneNumber = num.phoneNumber ?? '',
              onInputValidated: (v) => setStateDialog(() => _isValidNumber = v),
              initialValue: PhoneNumber(phoneNumber: clientPhone, isoCode: 'KE'),
              textFieldController: TextEditingController(text: clientPhone),
              formatInput: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              if (_isValidNumber) Navigator.of(context).pop(true);
            },
            child: Text("Prompt"),
          ),
        ],
      ),
    ),
  );

  if (confirmed == true) {
    if (applicationId != null) {
      // Re-trigger STK for existing application
      final result = await ApiProvider().repromptPayment(
        token: yourToken,
        applicationId: int.parse(applicationId),
        clientPhone: _fullPhoneNumber,
      );
      if (result['status'] == 'success') {
        startPaymentFlow(
          trackingId: result['tracking_id'],
          applicationId: applicationId,
          clientPhone: _fullPhoneNumber,
          promptCount: promptCount + 1,
        );
      }
    }
  } else {
    showErrorDialog("Payment cancelled");
  }
}
```

---

## Summary Flow Diagram

```
User fills form (vehicle, client, goods)
        │
        ▼
postOffloadingItems() → Backend creates DB record
        │               Backend calls M-PESA STK Push API
        │               M-PESA sends notification to client's phone
        ▼
Response: { status: "success", tracking_id: "XYZ", application_id: 4521 }
        │
        ▼
CheckPaymentDialog() → Show non-dismissable loading UI
        │
        ▼
_checkOffLoaidngPaymentStatusRepeatedly()
        │
        │──── poll every 5s ────▶ checkOffLoadingPaymentStatus(trackingId)
        │          │
        │          ├── data=="Completed"  ──▶  ✅ _showSuccessDialog()
        │          │
        │          ├── data=="Failed"     ──┐
        │          │                        │
        │          └── timeout (30s)     ──┘
        │                                   │
        │                    promptCount < 3 ? Yes ──▶ _showRetryPhoneDialog()
        │                                   │                   │
        │                                   │    User confirms phone
        │                                   │                   │
        │                                   │    applicationId exists?
        │                                   │         │           │
        │                                   │        YES         NO
        │                                   │         │           │
        │                                   │  promptPayment  resubmitCallback
        │                                   │  OfSavedApp()  (_submitForm())
        │                                   │         │           │
        │                                   │    new tracking_id  │
        │                                   │         └─────────┘
        │                                   │    CheckPaymentDialog(promptCount+1)
        │                                   │         (loops back)
        │                                   │
        │                    promptCount >= 3? ──▶ ❌ _showErrorDialog()
        │
        └── applicationId missing at any point? ──▶ _recoverApplicationId()
                                                       Tier 1: getLastpaymentCess()
                                                       Tier 2: getDailyOffloadingApplications()
```

---

## 12. Backend Implementation: M-PESA Daraja API

This section documents everything your **backend server** must do to receive a request from the Flutter app, call M-PESA, store the result, and serve the payment status back. The Flutter app never touches Safaricom directly — all STK Push logic lives here.

---

### 12.1 Prerequisites & Credentials

#### Register on Safaricom Daraja Portal

1. Go to: **https://developer.safaricom.co.ke/**
2. Create an account and log in.
3. Click **"Add a new app"** → select **"Lipa Na M-PESA Sandbox"** (for testing) or link your production credentials.
4. After app creation, copy these credentials:

| Credential | Where to Find | Description |
|---|---|---|
| **Consumer Key** | App dashboard → Keys | Public identifier for your app |
| **Consumer Secret** | App dashboard → Keys | Secret key (keep private!) |
| **Passkey** | Daraja Portal → LNM Passkey | Used to generate the request password |
| **BusinessShortCode** | Daraja Portal or given by Safaricom | Your Paybill or Till number |

> **Sandbox test credentials:** Safaricom provides fixed test values on the portal under the "Test Credentials" section.

#### Environment URLs

| Environment | Base URL |
|---|---|
| **Sandbox** | `https://sandbox.safaricom.co.ke` |
| **Production** | `https://api.safaricom.co.ke` |

Switch the base URL when going live — no other code changes needed.

---

### 12.2 Step 1 – Get OAuth Access Token

Every Daraja API call requires a **time-bound OAuth 2.0 bearer token**. Tokens expire after **3600 seconds (1 hour)**. Cache and refresh them server-side.

**Endpoint:**
```
GET https://sandbox.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials
Authorization: Basic base64(ConsumerKey:ConsumerSecret)
```

**Node.js:**
```js
async function getMpesaToken() {
  const creds = Buffer.from(`${CONSUMER_KEY}:${CONSUMER_SECRET}`).toString('base64');
  const { data } = await axios.get(
    `${MPESA_BASE}/oauth/v1/generate?grant_type=client_credentials`,
    { headers: { Authorization: `Basic ${creds}` } }
  );
  return data.access_token; // Cache for up to 3600s
}
```

**Response:**
```json
{
  "access_token": "bQriJJFAdHpY3bWTIzLvT6IbOa2J",
  "expires_in": "3599"
}
```

---

### 12.3 Step 2 – Build the STK Push Request

Before sending to Safaricom, compute two values:

#### Timestamp
```
Format: YYYYMMDDHHmmss  (EAT timezone = UTC+3)
Example: 20241104131424
```

```js
function getTimestamp() {
  const eat = new Date(Date.now() + 3 * 60 * 60 * 1000); // UTC+3
  return eat.toISOString().replace(/[-T:.Z]/g, '').slice(0, 14);
}
```

#### Password
Base64 encoding of: `BusinessShortCode + Passkey + Timestamp`

```js
function getPassword(timestamp) {
  return Buffer.from(`${SHORT_CODE}${PASSKEY}${timestamp}`).toString('base64');
}
```

**Example:**
```
ShortCode : 174379
Passkey   : bfb279f9aa9bdbcf158e97dd71a467cd2e0c893059b10f78e6b72ada1ed2c919
Timestamp : 20241104131424

Raw:      174379bfb279f9...20241104131424
Password: MTc0Mzc5YmZiMjc5... (base64)
```

---

### 12.4 Step 3 – Send STK Push to Safaricom

**Endpoint:**
```
POST https://sandbox.safaricom.co.ke/mpesa/stkpush/v1/processrequest
Authorization: Bearer {access_token}
Content-Type: application/json
```

**Request Payload:**
```json
{
  "BusinessShortCode": "174379",
  "Password": "MTc0Mzc5YmZiMjc5...",
  "Timestamp": "20241104131424",
  "TransactionType": "CustomerPayBillOnline",
  "Amount": "5000",
  "PartyA": "254712345678",
  "PartyB": "174379",
  "PhoneNumber": "254712345678",
  "CallBackURL": "https://yourdomain.com/api/mpesa/callback",
  "AccountReference": "APP-4521",
  "TransactionDesc": "Offloading Fee"
}
```

**Parameter Reference:**

| Parameter | Notes |
|---|---|
| `TransactionType` | `CustomerPayBillOnline` (Paybill) or `CustomerBuyGoodsOnline` (Till) |
| `Amount` | Integer KES — no decimals. Use `Math.ceil()`. |
| `PartyA` / `PhoneNumber` | `254XXXXXXXXX` — no `+`, no leading `0` |
| `CallBackURL` | Must be **HTTPS**. Your server receives payment result here. |
| `AccountReference` | Max 12 chars. Your internal reference (e.g. application ID). |
| `TransactionDesc` | Max 13 chars. Shown on customer's phone. |

**Phone Normalisation:**
```js
function normalisePhone(phone) {
  phone = phone.replace(/[^0-9]/g, '');
  if (phone.startsWith('0'))    phone = '254' + phone.slice(1);
  if (!phone.startsWith('254')) phone = '254' + phone;
  return phone; // "254712345678"
}
```

**Safaricom Response (accepted):**
```json
{
  "CheckoutRequestID": "ws_CO_191220191020363925",
  "ResponseCode": "0",
  "ResponseDescription": "Success. Request accepted for processing"
}
```

Save the `CheckoutRequestID` as your `tracking_id`. This is what the Flutter app polls with.

---

### 12.5 Step 4 – Handle the Callback (M-PESA → Your Server)

After the user approves or rejects the prompt, **Safaricom calls your `CallBackURL`** asynchronously (typically within 10–30 seconds).

**Success Callback:**
```json
{
  "Body": {
    "stkCallback": {
      "MerchantRequestID": "29115-34620561-1",
      "CheckoutRequestID": "ws_CO_191220191020363925",
      "ResultCode": 0,
      "ResultDesc": "The service request is processed successfully.",
      "CallbackMetadata": {
        "Item": [
          { "Name": "Amount",             "Value": 5000 },
          { "Name": "MpesaReceiptNumber", "Value": "NLJ7RT61SV" },
          { "Name": "TransactionDate",    "Value": 20191219102115 },
          { "Name": "PhoneNumber",        "Value": 254712345678 }
        ]
      }
    }
  }
}
```

**Failure Callback (user cancelled):**
```json
{
  "Body": {
    "stkCallback": {
      "CheckoutRequestID": "ws_CO_191220191020363925",
      "ResultCode": 1032,
      "ResultDesc": "Request cancelled by user"
    }
  }
}
```

**Result Codes:**

| ResultCode | Meaning |
|---|---|
| `0` | ✅ Success — payment received |
| `1032` | ❌ Cancelled by user |
| `1037` | ❌ Timeout — user did not respond |
| `1` | ❌ Insufficient funds |
| `2001` | ❌ Wrong PIN entered |

**Your callback handler must:**
1. Extract `CheckoutRequestID` (= your `tracking_id`).
2. Update the `mpesa_transactions` DB row: set `status = 'Completed'` or `'Failed'`, save `MpesaReceiptNumber`.
3. Return **HTTP 200 immediately** — Safaricom retries if you don't.

```js
// Express.js callback handler
app.post('/api/mpesa/callback', async (req, res) => {
  res.status(200).json({ ResultCode: 0, ResultDesc: 'Accepted' }); // Respond FIRST

  const stk = req.body.Body.stkCallback;
  const checkoutId = stk.CheckoutRequestID;

  if (stk.ResultCode === 0) {
    const items = stk.CallbackMetadata.Item;
    const get = (name) => items.find(i => i.Name === name)?.Value;
    await db.query(
      `UPDATE mpesa_transactions SET status='Completed', receipt_number=?, mpesa_amount=?
       WHERE checkout_request_id=?`,
      [get('MpesaReceiptNumber'), get('Amount'), checkoutId]
    );
  } else {
    await db.query(
      `UPDATE mpesa_transactions SET status='Failed', result_desc=?
       WHERE checkout_request_id=?`,
      [stk.ResultDesc, checkoutId]
    );
  }
});
```

---

### 12.6 Step 5 – Expose Check Payment Status to the App

The Flutter app polls your backend every 5 seconds. Your backend reads the DB row updated by the callback:

```js
// GET /cess/V2?appType=checkPaymentStatus&trackingId=ws_CO_xxx
app.get('/cess/V2', async (req, res) => {
  const { appType, trackingId } = req.query;
  if (appType === 'checkPaymentStatus') {
    const [rows] = await db.query(
      'SELECT status, result_desc, application_id FROM mpesa_transactions WHERE checkout_request_id = ?',
      [trackingId]
    );
    if (!rows.length) return res.json({ status: 'error', message: 'Not found' });
    return res.json({
      status: 'success',
      data: rows[0].status,          // "Pending" | "Completed" | "Failed"
      application_id: rows[0].application_id,
      message: rows[0].result_desc,
    });
  }
});
```

- While `data == "Pending"` → Flutter app waits 5s and polls again
- When `data == "Completed"` → Flutter app shows success dialog
- When `data == "Failed"` → Flutter app shows retry dialog

---

### 12.7 Full Node.js Implementation

```js
// mpesa.js — complete Express.js route (MySQL)
const express = require('express');
const axios = require('axios');
const router = express.Router();
const db = require('./db');

const CONSUMER_KEY    = process.env.MPESA_CONSUMER_KEY;
const CONSUMER_SECRET = process.env.MPESA_CONSUMER_SECRET;
const PASSKEY         = process.env.MPESA_PASSKEY;
const SHORT_CODE      = process.env.MPESA_SHORT_CODE;
const CALLBACK_URL    = process.env.MPESA_CALLBACK_URL;
const MPESA_BASE      = process.env.MPESA_ENV === 'production'
  ? 'https://api.safaricom.co.ke'
  : 'https://sandbox.safaricom.co.ke';

// --- Token cache ---
let cachedToken = null, tokenExpiry = 0;
async function getMpesaToken() {
  if (cachedToken && Date.now() < tokenExpiry) return cachedToken;
  const creds = Buffer.from(`${CONSUMER_KEY}:${CONSUMER_SECRET}`).toString('base64');
  const { data } = await axios.get(`${MPESA_BASE}/oauth/v1/generate?grant_type=client_credentials`,
    { headers: { Authorization: `Basic ${creds}` } });
  cachedToken = data.access_token;
  tokenExpiry = Date.now() + (Number(data.expires_in) - 60) * 1000;
  return cachedToken;
}

function getTimestamp() {
  return new Date(Date.now() + 3*60*60*1000).toISOString().replace(/[-T:.Z]/g,'').slice(0,14);
}
function getPassword(ts) { return Buffer.from(`${SHORT_CODE}${PASSKEY}${ts}`).toString('base64'); }
function normalisePhone(p) {
  p = p.replace(/[^0-9]/g,'');
  if (p.startsWith('0')) p = '254'+p.slice(1);
  if (!p.startsWith('254')) p = '254'+p;
  return p;
}

// --- createApplication (triggers STK Push) ---
router.post('/cess/V2', async (req, res) => {
  if (req.body.appType === 'createApplication') {
    const { vehicleType, plateNumber, clientName, clientPhoneNumber, zone, items, penalty } = req.body;
    try {
      const [app] = await db.query(
        `INSERT INTO offloading_applications (plate_number,vehicle_type,client_name,client_phone,zone,penalty,status)
         VALUES (?,?,?,?,?,?,'Pending')`,
        [plateNumber, vehicleType, clientName, clientPhoneNumber, zone, penalty]
      );
      const appId = app.insertId;
      const totalAmount = items.reduce((s, i) => s + parseFloat(i.amount)*parseInt(i.quantity), 0);
      const token = await getMpesaToken();
      const ts = getTimestamp();
      const { data: stk } = await axios.post(
        `${MPESA_BASE}/mpesa/stkpush/v1/processrequest`,
        {
          BusinessShortCode: SHORT_CODE, Password: getPassword(ts), Timestamp: ts,
          TransactionType: 'CustomerPayBillOnline',
          Amount: Math.ceil(totalAmount),
          PartyA: normalisePhone(clientPhoneNumber), PartyB: SHORT_CODE,
          PhoneNumber: normalisePhone(clientPhoneNumber),
          CallBackURL: CALLBACK_URL,
          AccountReference: `APP-${appId}`.slice(0,12),
          TransactionDesc: 'Offloading Fee'.slice(0,13),
        },
        { headers: { Authorization: `Bearer ${token}` } }
      );
      if (stk.ResponseCode !== '0') throw new Error(stk.ResponseDescription);
      await db.query(
        `INSERT INTO mpesa_transactions (application_id,checkout_request_id,amount,phone,status)
         VALUES (?,?,?,?,'Pending')`,
        [appId, stk.CheckoutRequestID, totalAmount, normalisePhone(clientPhoneNumber)]
      );
      return res.json({ status:'success', tracking_id: stk.CheckoutRequestID, application_id: appId });
    } catch (e) { return res.json({ status:'error', message: e.message }); }
  }

  if (req.body.appType === 'promptOffloadingApplicationPayment') {
    const { applicationId, clientPhoneNumber } = req.body;
    try {
      const [rows] = await db.query('SELECT total_amount FROM offloading_applications WHERE id=?', [applicationId]);
      const token = await getMpesaToken(); const ts = getTimestamp();
      const { data: stk } = await axios.post(
        `${MPESA_BASE}/mpesa/stkpush/v1/processrequest`,
        {
          BusinessShortCode: SHORT_CODE, Password: getPassword(ts), Timestamp: ts,
          TransactionType: 'CustomerPayBillOnline', Amount: Math.ceil(rows[0].total_amount),
          PartyA: normalisePhone(clientPhoneNumber), PartyB: SHORT_CODE,
          PhoneNumber: normalisePhone(clientPhoneNumber), CallBackURL: CALLBACK_URL,
          AccountReference: `APP-${applicationId}`.slice(0,12), TransactionDesc: 'Offloading Fee',
        },
        { headers: { Authorization: `Bearer ${token}` } }
      );
      if (stk.ResponseCode !== '0') throw new Error(stk.ResponseDescription);
      await db.query(
        `INSERT INTO mpesa_transactions (application_id,checkout_request_id,phone,status) VALUES (?,?,?,'Pending')`,
        [applicationId, stk.CheckoutRequestID, normalisePhone(clientPhoneNumber)]
      );
      return res.json({ status:'success', tracking_id: stk.CheckoutRequestID });
    } catch (e) { return res.json({ status:'error', message: e.message }); }
  }
});

// --- M-PESA Callback ---
router.post('/api/mpesa/callback', async (req, res) => {
  res.status(200).json({ ResultCode:0, ResultDesc:'Accepted' }); // Respond first!
  const stk = req.body.Body.stkCallback;
  if (stk.ResultCode === 0) {
    const get = (n) => stk.CallbackMetadata.Item.find(i=>i.Name===n)?.Value;
    await db.query(
      `UPDATE mpesa_transactions SET status='Completed',receipt_number=?,mpesa_amount=?,completed_at=NOW()
       WHERE checkout_request_id=?`,
      [get('MpesaReceiptNumber'), get('Amount'), stk.CheckoutRequestID]
    );
  } else {
    await db.query(
      `UPDATE mpesa_transactions SET status='Failed',result_desc=? WHERE checkout_request_id=?`,
      [stk.ResultDesc, stk.CheckoutRequestID]
    );
  }
});

// --- checkPaymentStatus ---
router.get('/cess/V2', async (req, res) => {
  if (req.query.appType === 'checkPaymentStatus') {
    const [rows] = await db.query(
      'SELECT status,result_desc,application_id FROM mpesa_transactions WHERE checkout_request_id=?',
      [req.query.trackingId]
    );
    if (!rows.length) return res.json({ status:'error', message:'Not found' });
    return res.json({ status:'success', data: rows[0].status, application_id: rows[0].application_id, message: rows[0].result_desc });
  }
});

module.exports = router;
```

---

### 12.8 PHP Implementation

```php
<?php
// mpesa_helper.php

define('CONSUMER_KEY',   getenv('MPESA_CONSUMER_KEY'));
define('CONSUMER_SECRET', getenv('MPESA_CONSUMER_SECRET'));
define('PASSKEY',        getenv('MPESA_PASSKEY'));
define('SHORT_CODE',     getenv('MPESA_SHORT_CODE'));
define('CALLBACK_URL',   getenv('MPESA_CALLBACK_URL'));
define('MPESA_BASE',     getenv('MPESA_ENV') === 'production'
    ? 'https://api.safaricom.co.ke'
    : 'https://sandbox.safaricom.co.ke');

function getMpesaToken() {
    $creds = base64_encode(CONSUMER_KEY . ':' . CONSUMER_SECRET);
    $ch = curl_init(MPESA_BASE . '/oauth/v1/generate?grant_type=client_credentials');
    curl_setopt_array($ch, [CURLOPT_RETURNTRANSFER => true,
        CURLOPT_HTTPHEADER => ["Authorization: Basic $creds"]]);
    $res = json_decode(curl_exec($ch)); curl_close($ch);
    return $res->access_token;
}

function getTimestamp() {
    return (new DateTime('now', new DateTimeZone('Africa/Nairobi')))->format('YmdHis');
}

function getMpesaPassword($ts) {
    return base64_encode(SHORT_CODE . PASSKEY . $ts);
}

function normalisePhone($phone) {
    $phone = preg_replace('/[^0-9]/', '', $phone);
    if (substr($phone,0,1) === '0') $phone = '254' . substr($phone, 1);
    if (substr($phone,0,3) !== '254') $phone = '254' . $phone;
    return $phone;
}

function triggerStkPush($phone, $amount, $accountRef, $desc) {
    $token = getMpesaToken();
    $ts    = getTimestamp();
    $payload = json_encode([
        'BusinessShortCode' => SHORT_CODE,
        'Password'          => getMpesaPassword($ts),
        'Timestamp'         => $ts,
        'TransactionType'   => 'CustomerPayBillOnline',
        'Amount'            => (int) ceil($amount),
        'PartyA'            => normalisePhone($phone),
        'PartyB'            => SHORT_CODE,
        'PhoneNumber'       => normalisePhone($phone),
        'CallBackURL'       => CALLBACK_URL,
        'AccountReference'  => substr($accountRef, 0, 12),
        'TransactionDesc'   => substr($desc, 0, 13),
    ]);
    $ch = curl_init(MPESA_BASE . '/mpesa/stkpush/v1/processrequest');
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true, CURLOPT_POST => true, CURLOPT_POSTFIELDS => $payload,
        CURLOPT_HTTPHEADER => ["Authorization: Bearer $token", 'Content-Type: application/json'],
    ]);
    $result = json_decode(curl_exec($ch), true); curl_close($ch);
    return $result; // $result['CheckoutRequestID'] is your tracking_id
}

function handleMpesaCallback($pdo) {
    $body = json_decode(file_get_contents('php://input'), true);
    $stk  = $body['Body']['stkCallback'];
    $checkoutId = $stk['CheckoutRequestID'];

    if ($stk['ResultCode'] == 0) {
        $items = $stk['CallbackMetadata']['Item'];
        $get = fn($n) => array_filter($items, fn($i) => $i['Name'] === $n);
        $receipt = array_values($get('MpesaReceiptNumber'))[0]['Value'] ?? null;
        $pdo->prepare("UPDATE mpesa_transactions SET status='Completed', receipt_number=?
                        WHERE checkout_request_id=?")->execute([$receipt, $checkoutId]);
    } else {
        $pdo->prepare("UPDATE mpesa_transactions SET status='Failed', result_desc=?
                        WHERE checkout_request_id=?")->execute([$stk['ResultDesc'], $checkoutId]);
    }
    http_response_code(200);
    echo json_encode(['ResultCode' => 0, 'ResultDesc' => 'Accepted']);
}
```

---

### 12.9 Database Schema

```sql
-- Application records
CREATE TABLE offloading_applications (
  id             INT AUTO_INCREMENT PRIMARY KEY,
  plate_number   VARCHAR(20)  NOT NULL,
  vehicle_type   VARCHAR(50),
  client_name    VARCHAR(100),
  client_phone   VARCHAR(20),
  zone           VARCHAR(50),
  penalty        INT          DEFAULT 0,
  total_amount   DECIMAL(10,2),
  status         ENUM('Pending','Paid','Failed') DEFAULT 'Pending',
  created_at     DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- One row per STK Push attempt (including retries)
CREATE TABLE mpesa_transactions (
  id                    INT AUTO_INCREMENT PRIMARY KEY,
  application_id        INT          NOT NULL,
  checkout_request_id   VARCHAR(100) NOT NULL UNIQUE,  -- ← This IS the tracking_id
  merchant_request_id   VARCHAR(100),
  phone                 VARCHAR(20),
  amount                DECIMAL(10,2),
  status                ENUM('Pending','Completed','Failed') DEFAULT 'Pending',
  receipt_number        VARCHAR(50),   -- M-PESA receipt # (e.g. NLJ7RT61SV)
  mpesa_amount          DECIMAL(10,2), -- Actual amount M-PESA debited
  result_desc           TEXT,          -- Error message if failed
  completed_at          DATETIME,
  created_at            DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (application_id) REFERENCES offloading_applications(id)
);

CREATE INDEX idx_checkout ON mpesa_transactions(checkout_request_id);
```

**Key point:** One application can have multiple transaction rows (one per STK push attempt). The Flutter app's `tracking_id` maps to `checkout_request_id`.

---

### 12.10 Testing with ngrok

Safaricom requires a public **HTTPS** URL for `CallBackURL`. Use ngrok during local development:

```bash
# Install & authenticate (https://ngrok.com for free account)
ngrok config add-authtoken YOUR_TOKEN

# Expose your local backend (port 3000)
ngrok http 3000
# Output: https://a1b2-102-0-2-99.ngrok-free.app -> http://localhost:3000
```

Set `MPESA_CALLBACK_URL=https://a1b2-102-0-2-99.ngrok-free.app/api/mpesa/callback`

```bash
# Inspect all callbacks in the browser
open http://localhost:4040
```

**Sandbox test values (from Daraja Portal → Test Credentials):**

| Field | Sandbox Value |
|---|---|
| BusinessShortCode | `174379` |
| Passkey | `bfb279f9aa9bdbcf158e97dd71a467cd2e0c893059b10f78e6b72ada1ed2c919` |
| Test Phone | `254708374149` |
| TransactionType | `CustomerPayBillOnline` |

The sandbox auto-completes within ~15 seconds — no real phone prompt is sent.

---

### 12.11 Environment: Sandbox vs Production

| Aspect | Sandbox | Production |
|---|---|---|
| Base URL | `https://sandbox.safaricom.co.ke` | `https://api.safaricom.co.ke` |
| Credentials | Test keys from Daraja portal | Live keys after go-live approval |
| STK Prompt | Not sent; auto-simulated | Real M-PESA prompt on customer's phone |
| Funds | No real money moved | Real KES charged |
| CallbackURL | ngrok or staging server | Must be live HTTPS domain |
| Go-live | N/A | Submit on Daraja portal for Safaricom review |

```bash
# .env (switch MPESA_ENV to go live)
MPESA_ENV=sandbox
MPESA_CONSUMER_KEY=your_key
MPESA_CONSUMER_SECRET=your_secret
MPESA_PASSKEY=your_passkey
MPESA_SHORT_CODE=174379
MPESA_CALLBACK_URL=https://yourdomain.com/api/mpesa/callback
```

---

### 12.12 Security Checklist

Before going live, verify all of the following:

- [ ] **Never put Daraja credentials in the Flutter app** — all M-PESA calls are server-side only
- [ ] **Store credentials in environment variables** (`.env` / cloud secrets), never hardcoded
- [ ] **Respond HTTP 200 immediately** in the callback handler — update the DB asynchronously after responding
- [ ] **Idempotent callback** — check if `checkout_request_id` is already `Completed` before updating (Safaricom may retry callbacks)
- [ ] **Validate `Amount`** in the callback vs. what you stored — reject if mismatched
- [ ] **Use HTTPS only** for `CallBackURL` — HTTP is rejected by Safaricom
- [ ] **Protect your API endpoints** with Bearer token authentication (as this app already does)
- [ ] **Rate-limit `/checkPaymentStatus`** — Flutter polls every 5s per active payment
- [ ] **`Amount` must be an integer** — M-PESA rejects decimals. Always `Math.ceil()` / `intval()`
- [ ] **Log all callback payloads** to a `mpesa_callback_log` table for audit trails
- [ ] **Test cancel + timeout scenarios** in sandbox before production to verify retry UI is correct
- [ ] **Token caching** — reuse the access token for the full 3600s; don't request a new one per transaction

---

## 13. Alternative: Flutter-Side PaymentService (No Backend)

Yes — Flutter **can** call the Daraja API directly by creating a `PaymentService` class. This eliminates the need for a backend server entirely. The Flutter app handles OAuth, password generation, STK Push, and status polling all by itself.

> [!CAUTION]
> **This approach exposes your Consumer Key, Consumer Secret, and Passkey inside the app binary.** Anyone can decompile your APK/IPA and extract them. **Use this only for prototyping, demos, or internal tools — never for production apps distributed to the public.**

---

### 13.1 When to Use This Approach

| Use Case | Recommended? |
|---|---|
| Rapid prototyping / hackathons | ✅ Yes |
| Personal or internal-only tools | ✅ Acceptable |
| Learning / tutorials | ✅ Yes |
| Production apps on Play Store / App Store | ❌ **Never** |
| Apps handling real customer payments | ❌ **Never** |

---

### 13.2 Full MpesaPaymentService Class

Add `dio` to your `pubspec.yaml` (you likely already have it):
```yaml
dependencies:
  dio: ^5.4.0
```

Create `lib/services/mpesa_payment_service.dart`:

```dart
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

class MpesaPaymentService {
  // ⚠️ WARNING: These should NEVER be in a production app.
  // Store them in a backend server instead.
  static const String _consumerKey    = 'YOUR_CONSUMER_KEY';
  static const String _consumerSecret = 'YOUR_CONSUMER_SECRET';
  static const String _passkey        = 'YOUR_PASSKEY';
  static const String _shortCode      = '174379'; // Your Paybill/Till number
  static const String _callbackUrl    = 'https://yourdomain.com/api/mpesa/callback';

  // Switch to 'https://api.safaricom.co.ke' for production
  static const String _baseUrl = 'https://sandbox.safaricom.co.ke';

  final Dio _dio = Dio();

  // Cached token
  String? _accessToken;
  DateTime? _tokenExpiry;

  // ─── Step 1: Get OAuth Access Token ───────────────────────

  Future<String> getAccessToken() async {
    // Return cached token if still valid
    if (_accessToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(_tokenExpiry!)) {
      return _accessToken!;
    }

    final credentials = base64Encode(
      utf8.encode('$_consumerKey:$_consumerSecret'),
    );

    final response = await _dio.get(
      '$_baseUrl/oauth/v1/generate?grant_type=client_credentials',
      options: Options(
        headers: {'Authorization': 'Basic $credentials'},
      ),
    );

    _accessToken = response.data['access_token'];
    _tokenExpiry = DateTime.now().add(
      Duration(seconds: int.parse(response.data['expires_in']) - 60),
    );

    return _accessToken!;
  }

  // ─── Step 2: Generate Timestamp ───────────────────────────

  String _getTimestamp() {
    // M-PESA expects EAT (UTC+3) in format: YYYYMMDDHHmmss
    final now = DateTime.now().toUtc().add(const Duration(hours: 3));
    return DateFormat('yyyyMMddHHmmss').format(now);
  }

  // ─── Step 3: Generate Password ────────────────────────────

  String _getPassword(String timestamp) {
    final raw = '$_shortCode$_passkey$timestamp';
    return base64Encode(utf8.encode(raw));
  }

  // ─── Step 4: Normalise Phone Number ───────────────────────

  String normalisePhone(String phone) {
    // Remove all non-digit characters
    phone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    // Convert 07xx to 2547xx
    if (phone.startsWith('0')) {
      phone = '254${phone.substring(1)}';
    }
    // Ensure it starts with 254
    if (!phone.startsWith('254')) {
      phone = '254$phone';
    }
    return phone;
  }

  // ─── Step 5: Initiate STK Push ────────────────────────────

  /// Sends an STK Push to the customer's phone.
  ///
  /// Returns a Map with:
  /// - `CheckoutRequestID` — use this to poll payment status
  /// - `ResponseCode` — "0" means accepted
  /// - `ResponseDescription`
  /// - `CustomerMessage`
  Future<Map<String, dynamic>> initiateStkPush({
    required String phoneNumber,
    required int amount,
    required String accountReference,
    String transactionDesc = 'Payment',
  }) async {
    final token = await getAccessToken();
    final timestamp = _getTimestamp();
    final password = _getPassword(timestamp);
    final phone = normalisePhone(phoneNumber);

    final response = await _dio.post(
      '$_baseUrl/mpesa/stkpush/v1/processrequest',
      data: {
        'BusinessShortCode': _shortCode,
        'Password': password,
        'Timestamp': timestamp,
        'TransactionType': 'CustomerPayBillOnline',
        'Amount': amount,                      // Must be integer
        'PartyA': phone,
        'PartyB': _shortCode,
        'PhoneNumber': phone,
        'CallBackURL': _callbackUrl,
        'AccountReference': accountReference.length > 12
            ? accountReference.substring(0, 12)
            : accountReference,
        'TransactionDesc': transactionDesc.length > 13
            ? transactionDesc.substring(0, 13)
            : transactionDesc,
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ),
    );

    return response.data;
    // response.data['CheckoutRequestID'] is your tracking_id
  }

  // ─── Step 6: Query STK Push Status ────────────────────────

  /// Checks the status of an STK Push transaction.
  /// Use this as an alternative to relying on callbacks.
  ///
  /// Returns a Map with:
  /// - `ResultCode` — 0 = success
  /// - `ResultDesc` — description
  Future<Map<String, dynamic>> queryStkPushStatus({
    required String checkoutRequestId,
  }) async {
    final token = await getAccessToken();
    final timestamp = _getTimestamp();
    final password = _getPassword(timestamp);

    final response = await _dio.post(
      '$_baseUrl/mpesa/stkpushquery/v1/query',
      data: {
        'BusinessShortCode': _shortCode,
        'Password': password,
        'Timestamp': timestamp,
        'CheckoutRequestID': checkoutRequestId,
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ),
    );

    return response.data;
  }

  // ─── Step 7: Poll Until Completion ────────────────────────

  /// Polls the STK Push status every [pollInterval] for up to [timeout].
  /// Returns the final status map.
  Future<Map<String, dynamic>> pollPaymentStatus({
    required String checkoutRequestId,
    Duration timeout = const Duration(seconds: 30),
    Duration pollInterval = const Duration(seconds: 5),
  }) async {
    final startTime = DateTime.now();

    while (DateTime.now().difference(startTime) < timeout) {
      try {
        final result = await queryStkPushStatus(
          checkoutRequestId: checkoutRequestId,
        );

        final resultCode = result['ResultCode']?.toString();

        if (resultCode == '0') {
          // ✅ Payment successful
          return {'status': 'Completed', 'data': result};
        } else if (resultCode != null && resultCode != '1032') {
          // ❌ Failed (not just "processing")
          return {
            'status': 'Failed',
            'message': result['ResultDesc'] ?? 'Payment failed',
            'data': result,
          };
        }
      } on DioException catch (e) {
        // M-PESA returns an error while still processing — this is normal
        // "The transaction is being processed" comes as a 500 error
        final responseData = e.response?.data;
        if (responseData is Map && responseData['errorCode'] == '500.001.1001') {
          // Still processing — continue polling
        } else {
          rethrow;
        }
      }

      await Future.delayed(pollInterval);
    }

    return {'status': 'Timeout', 'message': 'Payment confirmation timed out'};
  }
}
```

---

### 13.3 Using It in Your Widget

```dart
import 'package:flutter/material.dart';
import '../services/mpesa_payment_service.dart';

class PaymentScreen extends StatefulWidget {
  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _mpesa = MpesaPaymentService();
  bool _isProcessing = false;

  Future<void> _makePayment() async {
    setState(() => _isProcessing = true);

    try {
      // 1. Trigger STK Push
      final stkResult = await _mpesa.initiateStkPush(
        phoneNumber: '0712345678',
        amount: 5000,
        accountReference: 'APP-4521',
        transactionDesc: 'Cess Fee',
      );

      if (stkResult['ResponseCode'] != '0') {
        _showError(stkResult['ResponseDescription'] ?? 'STK Push rejected');
        return;
      }

      final checkoutId = stkResult['CheckoutRequestID'];

      // 2. Show loading dialog
      _showLoadingDialog('Payment sent to phone. Please wait...');

      // 3. Poll for result
      final paymentResult = await _mpesa.pollPaymentStatus(
        checkoutRequestId: checkoutId,
      );

      Navigator.of(context).pop(); // dismiss loading

      // 4. Handle result
      if (paymentResult['status'] == 'Completed') {
        _showSuccess('Payment received successfully!');
      } else if (paymentResult['status'] == 'Timeout') {
        _showError('Payment timed out. Please try again.');
      } else {
        _showError(paymentResult['message'] ?? 'Payment failed');
      }
    } on DioException catch (e) {
      Navigator.of(context, rootNavigator: true).pop();
      _showError(e.response?.data?.toString() ?? e.message ?? 'Network error');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _showLoadingDialog(String msg) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (_) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(msg),
          ],
        ),
      ),
    );
  }

  void _showSuccess(String msg) => showDialog(
    context: context,
    builder: (_) => AlertDialog(title: Text('Success'), content: Text(msg)),
  );

  void _showError(String msg) => showDialog(
    context: context,
    builder: (_) => AlertDialog(title: Text('Error'), content: Text(msg)),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: _isProcessing ? null : _makePayment,
          child: Text(_isProcessing ? 'Processing...' : 'Pay KES 5,000'),
        ),
      ),
    );
  }
}
```

---

### 13.4 The Callback Problem

Even with a Flutter-side `PaymentService`, **M-PESA still requires a `CallbackURL`** — a public HTTPS endpoint that Safaricom POSTs the payment result to. You have three options:

| Option | How It Works | Complexity |
|---|---|---|
| **Ignore the callback** | Set `CallbackURL` to a dummy URL. Rely entirely on `queryStkPushStatus` polling (Section 13.5). | Simple |
| **Use a serverless function** | Deploy a tiny Cloud Function (Firebase, AWS Lambda, Vercel) that receives the callback and writes to Firestore/DynamoDB. Flutter reads the result from there. | Medium |
| **Use a full backend** | At this point, just use the backend approach (Section 12). | Full |

For prototyping, **Option 1 (ignore + poll)** is easiest. The `queryStkPushStatus` endpoint lets you check payment status without receiving a callback.

---

### 13.5 STK Push Query (Polling Alternative)

Safaricom provides a dedicated **query endpoint** that lets you check the status of an STK Push without needing a callback:

```
POST https://sandbox.safaricom.co.ke/mpesa/stkpushquery/v1/query
Authorization: Bearer {access_token}
Content-Type: application/json

{
  "BusinessShortCode": "174379",
  "Password": "MTc0Mzc5YmZi...",
  "Timestamp": "20241104131424",
  "CheckoutRequestID": "ws_CO_191220191020363925"
}
```

**Response (success):**
```json
{
  "ResponseCode": "0",
  "ResponseDescription": "The service request has been accepted successfully",
  "MerchantRequestID": "29115-34620561-1",
  "CheckoutRequestID": "ws_CO_191220191020363925",
  "ResultCode": "0",
  "ResultDesc": "The service request is processed successfully."
}
```

**Response (still processing):**
```json
{
  "ResponseCode": "0",
  "errorCode": "500.001.1001",
  "errorMessage": "The transaction is being processed"
}
```

**Response (cancelled):**
```json
{
  "ResultCode": "1032",
  "ResultDesc": "Request cancelled by user"
}
```

This is already implemented in the `MpesaPaymentService.queryStkPushStatus()` method above. The `pollPaymentStatus()` method calls it every 5 seconds in a loop — identical to how the enforcer app polls its own backend.

---

### 13.6 Backend vs Flutter-Side — Comparison

| Aspect | Backend Approach (Section 12) | Flutter-Side PaymentService (Section 13) |
|---|---|---|
| **Security** | ✅ Credentials stay on server | ❌ Credentials in app binary (extractable) |
| **Callback handling** | ✅ Server receives M-PESA callback directly | ⚠️ Must use STK Query polling or serverless function |
| **Transaction records** | ✅ Stored in server database | ❌ No persistent record (unless you add Firestore/local DB) |
| **Retry logic** | ✅ Server can re-trigger with stored application_id | ⚠️ Flutter must manage state locally |
| **Complexity** | Higher (need to deploy + maintain backend) | Lower (everything in Flutter) |
| **Production-ready** | ✅ Yes | ❌ No — security risk |
| **Good for prototyping** | Overkill for demos | ✅ Perfect for demos |
| **Receipt validation** | ✅ Server validates amount matches | ❌ Client can be tampered with |

> [!IMPORTANT]
> **The enforcer app uses the backend approach (Section 12)** for good reason — it handles real government cess payments with real money. If you're building something similar, use a backend. If you're just learning or prototyping, the Flutter-side `PaymentService` gets you running in minutes.

---

## 14. Multi-Tenant M-PESA (Per-Tenant Paybill/Till)

In a multi-tenant app, each tenant (organization, branch, merchant) has **their own Paybill or Till number** and **their own Daraja credentials**. The payment must be routed to the correct tenant's M-PESA account based on who the logged-in user belongs to.

---

### 14.1 Architecture Overview

The core challenge: **how does the app know which ShortCode + ConsumerKey + Secret + Passkey to use?**

There are two patterns:

| Pattern | Where Credentials Live | How It Works |
|---|---|---|
| **Backend-mediated** (recommended) | Server-side DB / secrets manager | Flutter sends `tenantId` with each payment request. Backend looks up that tenant's Daraja credentials and calls M-PESA. |
| **Flutter-side dynamic** | Cloud DB (Firestore / API) | Flutter fetches the tenant's credentials at login, stores them in memory, and calls Daraja directly. |

```
┌─────────────────────────────────────────────────────────────────┐
│                     Multi-Tenant Flow                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Tenant A (Paybill 600100)     Tenant B (Till 123456)          │
│  ┌──────────────────────┐      ┌──────────────────────┐        │
│  │ consumer_key: aaa... │      │ consumer_key: bbb... │        │
│  │ consumer_secret: ... │      │ consumer_secret: ... │        │
│  │ passkey: ...         │      │ passkey: ...         │        │
│  │ short_code: 600100   │      │ short_code: 123456   │        │
│  │ type: Paybill        │      │ type: Till           │        │
│  └──────────────────────┘      └──────────────────────┘        │
│           │                             │                       │
│           ▼                             ▼                       │
│  ┌─────────────────────────────────────────────────────┐       │
│  │              Your Backend / Firestore               │       │
│  │  Resolves tenantId → credentials → calls Daraja     │       │
│  └─────────────────────────────────────────────────────┘       │
│                          │                                      │
│                          ▼                                      │
│               Safaricom Daraja API                              │
│            STK Push → Customer's Phone                         │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

### 14.2 Tenant Credentials Model

#### Dart Model

```dart
/// Represents a tenant's M-PESA Daraja credentials.
class MpesaTenantConfig {
  final String tenantId;
  final String tenantName;
  final String consumerKey;
  final String consumerSecret;
  final String passkey;
  final String shortCode;
  final String transactionType; // 'CustomerPayBillOnline' or 'CustomerBuyGoodsOnline'
  final String callbackUrl;
  final bool isSandbox;

  MpesaTenantConfig({
    required this.tenantId,
    required this.tenantName,
    required this.consumerKey,
    required this.consumerSecret,
    required this.passkey,
    required this.shortCode,
    required this.transactionType,
    required this.callbackUrl,
    this.isSandbox = true,
  });

  String get baseUrl => isSandbox
      ? 'https://sandbox.safaricom.co.ke'
      : 'https://api.safaricom.co.ke';

  factory MpesaTenantConfig.fromJson(Map<String, dynamic> json) {
    return MpesaTenantConfig(
      tenantId: json['tenant_id'],
      tenantName: json['tenant_name'],
      consumerKey: json['consumer_key'],
      consumerSecret: json['consumer_secret'],
      passkey: json['passkey'],
      shortCode: json['short_code'],
      transactionType: json['transaction_type'] ?? 'CustomerPayBillOnline',
      callbackUrl: json['callback_url'],
      isSandbox: json['is_sandbox'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'tenant_id': tenantId,
    'tenant_name': tenantName,
    'consumer_key': consumerKey,
    'consumer_secret': consumerSecret,
    'passkey': passkey,
    'short_code': shortCode,
    'transaction_type': transactionType,
    'callback_url': callbackUrl,
    'is_sandbox': isSandbox,
  };
}
```

#### Firestore Schema

```
/tenants/{tenantId}
  ├── name: "Mombasa County"
  ├── email: "admin@mombasa.go.ke"
  └── ...

/tenants/{tenantId}/mpesa_config (subcollection, single doc)
  └── {configDocId}
      ├── consumer_key: "encrypted_aaa..."
      ├── consumer_secret: "encrypted_bbb..."
      ├── passkey: "encrypted_ccc..."
      ├── short_code: "600100"
      ├── transaction_type: "CustomerPayBillOnline"
      ├── callback_url: "https://yourdomain.com/api/mpesa/callback/tenant_abc"
      ├── is_sandbox: false
      └── updated_at: Timestamp
```

#### SQL Schema (if using a traditional backend)

```sql
CREATE TABLE tenant_mpesa_config (
  id              INT AUTO_INCREMENT PRIMARY KEY,
  tenant_id       VARCHAR(50) NOT NULL UNIQUE,
  tenant_name     VARCHAR(100),
  consumer_key    VARCHAR(255) NOT NULL,   -- Encrypt at rest!
  consumer_secret VARCHAR(255) NOT NULL,   -- Encrypt at rest!
  passkey         VARCHAR(255) NOT NULL,   -- Encrypt at rest!
  short_code      VARCHAR(20)  NOT NULL,
  transaction_type ENUM('CustomerPayBillOnline','CustomerBuyGoodsOnline') DEFAULT 'CustomerPayBillOnline',
  callback_url    VARCHAR(500),
  is_sandbox      BOOLEAN DEFAULT TRUE,
  created_at      DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at      DATETIME ON UPDATE CURRENT_TIMESTAMP
);

-- Each tenant gets their own row
INSERT INTO tenant_mpesa_config (tenant_id, tenant_name, consumer_key, consumer_secret, passkey, short_code)
VALUES ('tenant_mombasa', 'Mombasa County', 'aaa...', 'bbb...', 'ccc...', '600100');

INSERT INTO tenant_mpesa_config (tenant_id, tenant_name, consumer_key, consumer_secret, passkey, short_code, transaction_type)
VALUES ('tenant_nairobi', 'Nairobi County', 'ddd...', 'eee...', 'fff...', '123456', 'CustomerBuyGoodsOnline');
```

---

### 14.3 Backend Approach (Recommended)

The safest pattern: **Flutter sends the `tenantId`, the backend looks up credentials and calls Daraja.**

#### Backend (Node.js)

```js
// POST /api/payment/stk-push
router.post('/api/payment/stk-push', async (req, res) => {
  const { tenantId, phoneNumber, amount, accountReference } = req.body;

  // 1. Look up this tenant's M-PESA config
  const [configs] = await db.query(
    'SELECT * FROM tenant_mpesa_config WHERE tenant_id = ?', [tenantId]
  );
  if (!configs.length) return res.status(404).json({ error: 'Tenant not found' });

  const config = configs[0];
  const baseUrl = config.is_sandbox
    ? 'https://sandbox.safaricom.co.ke'
    : 'https://api.safaricom.co.ke';

  // 2. Get OAuth token for THIS tenant's credentials
  const creds = Buffer.from(`${config.consumer_key}:${config.consumer_secret}`).toString('base64');
  const { data: tokenData } = await axios.get(
    `${baseUrl}/oauth/v1/generate?grant_type=client_credentials`,
    { headers: { Authorization: `Basic ${creds}` } }
  );

  // 3. Build STK Push with THIS tenant's shortcode + passkey
  const timestamp = getTimestamp();
  const password = Buffer.from(
    `${config.short_code}${config.passkey}${timestamp}`
  ).toString('base64');

  const { data: stkResult } = await axios.post(
    `${baseUrl}/mpesa/stkpush/v1/processrequest`,
    {
      BusinessShortCode: config.short_code,
      Password: password,
      Timestamp: timestamp,
      TransactionType: config.transaction_type,
      Amount: Math.ceil(amount),
      PartyA: normalisePhone(phoneNumber),
      PartyB: config.short_code,
      PhoneNumber: normalisePhone(phoneNumber),
      CallBackURL: config.callback_url,  // Tenant-specific callback URL
      AccountReference: accountReference.slice(0, 12),
      TransactionDesc: 'Payment',
    },
    { headers: { Authorization: `Bearer ${tokenData.access_token}` } }
  );

  // 4. Save transaction with tenant_id
  await db.query(
    `INSERT INTO mpesa_transactions
     (tenant_id, checkout_request_id, phone, amount, status)
     VALUES (?, ?, ?, ?, 'Pending')`,
    [tenantId, stkResult.CheckoutRequestID, normalisePhone(phoneNumber), amount]
  );

  return res.json({
    status: 'success',
    tracking_id: stkResult.CheckoutRequestID,
  });
});
```

#### Flutter (Simple — just pass tenantId)

```dart
class ApiProvider {
  Future<Map<String, dynamic>> triggerStkPush({
    required String token,
    required String tenantId,      // ← The tenant whose Paybill/Till to use
    required String phoneNumber,
    required int amount,
    required String accountReference,
  }) async {
    final result = await Dio().post(
      'https://yourdomain.com/api/payment/stk-push',
      data: {
        'tenantId': tenantId,
        'phoneNumber': phoneNumber,
        'amount': amount,
        'accountReference': accountReference,
      },
      options: Options(
        preserveHeaderCase: true,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ),
    );
    return result.data;
  }
}
```

The Flutter app only knows the `tenantId` — it never sees any Daraja credentials.

---

### 14.4 Flutter-Side Approach (Dynamic PaymentService)

If you must call Daraja from Flutter directly (prototyping / internal tools), refactor `MpesaPaymentService` to accept tenant config dynamically:

```dart
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

class MultiTenantMpesaService {
  final Dio _dio = Dio();

  // Per-tenant token cache: tenantId → (token, expiry)
  final Map<String, _CachedToken> _tokenCache = {};

  /// Get OAuth token for a specific tenant's credentials
  Future<String> _getToken(MpesaTenantConfig config) async {
    final cached = _tokenCache[config.tenantId];
    if (cached != null && DateTime.now().isBefore(cached.expiry)) {
      return cached.token;
    }

    final creds = base64Encode(
      utf8.encode('${config.consumerKey}:${config.consumerSecret}'),
    );

    final response = await _dio.get(
      '${config.baseUrl}/oauth/v1/generate?grant_type=client_credentials',
      options: Options(headers: {'Authorization': 'Basic $creds'}),
    );

    final token = response.data['access_token'] as String;
    final expiresIn = int.parse(response.data['expires_in']) - 60;
    _tokenCache[config.tenantId] = _CachedToken(
      token: token,
      expiry: DateTime.now().add(Duration(seconds: expiresIn)),
    );

    return token;
  }

  String _getTimestamp() {
    final now = DateTime.now().toUtc().add(const Duration(hours: 3));
    return DateFormat('yyyyMMddHHmmss').format(now);
  }

  String _getPassword(String shortCode, String passkey, String timestamp) {
    return base64Encode(utf8.encode('$shortCode$passkey$timestamp'));
  }

  String normalisePhone(String phone) {
    phone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (phone.startsWith('0')) phone = '254${phone.substring(1)}';
    if (!phone.startsWith('254')) phone = '254$phone';
    return phone;
  }

  /// Initiate STK Push using a specific tenant's config
  Future<Map<String, dynamic>> initiateStkPush({
    required MpesaTenantConfig tenantConfig, // ← Pass tenant config
    required String phoneNumber,
    required int amount,
    required String accountReference,
    String transactionDesc = 'Payment',
  }) async {
    final token = await _getToken(tenantConfig);
    final timestamp = _getTimestamp();
    final password = _getPassword(
      tenantConfig.shortCode,
      tenantConfig.passkey,
      timestamp,
    );
    final phone = normalisePhone(phoneNumber);

    final response = await _dio.post(
      '${tenantConfig.baseUrl}/mpesa/stkpush/v1/processrequest',
      data: {
        'BusinessShortCode': tenantConfig.shortCode,
        'Password': password,
        'Timestamp': timestamp,
        'TransactionType': tenantConfig.transactionType,
        'Amount': amount,
        'PartyA': phone,
        'PartyB': tenantConfig.shortCode,
        'PhoneNumber': phone,
        'CallBackURL': tenantConfig.callbackUrl,
        'AccountReference': accountReference.length > 12
            ? accountReference.substring(0, 12)
            : accountReference,
        'TransactionDesc': transactionDesc.length > 13
            ? transactionDesc.substring(0, 13)
            : transactionDesc,
      },
      options: Options(headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      }),
    );

    return response.data;
  }

  /// Query STK Push status for a specific tenant
  Future<Map<String, dynamic>> queryStkPushStatus({
    required MpesaTenantConfig tenantConfig,
    required String checkoutRequestId,
  }) async {
    final token = await _getToken(tenantConfig);
    final timestamp = _getTimestamp();
    final password = _getPassword(
      tenantConfig.shortCode,
      tenantConfig.passkey,
      timestamp,
    );

    final response = await _dio.post(
      '${tenantConfig.baseUrl}/mpesa/stkpushquery/v1/query',
      data: {
        'BusinessShortCode': tenantConfig.shortCode,
        'Password': password,
        'Timestamp': timestamp,
        'CheckoutRequestID': checkoutRequestId,
      },
      options: Options(headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      }),
    );

    return response.data;
  }
}

class _CachedToken {
  final String token;
  final DateTime expiry;
  _CachedToken({required this.token, required this.expiry});
}
```

#### Usage — Loading Tenant Config at Login

```dart
// At login, fetch the tenant's M-PESA config from Firestore or your API
class AppState {
  late MpesaTenantConfig mpesaConfig;

  Future<void> loadTenantConfig(String tenantId) async {
    // Option 1: From Firestore
    final doc = await FirebaseFirestore.instance
        .collection('tenants')
        .doc(tenantId)
        .collection('mpesa_config')
        .limit(1)
        .get();
    mpesaConfig = MpesaTenantConfig.fromJson(doc.docs.first.data());

    // Option 2: From your API
    // final response = await Dio().get('/api/tenants/$tenantId/mpesa-config',
    //   options: Options(headers: {'Authorization': 'Bearer $token'}));
    // mpesaConfig = MpesaTenantConfig.fromJson(response.data);
  }
}

// When making a payment:
final mpesaService = MultiTenantMpesaService();
final result = await mpesaService.initiateStkPush(
  tenantConfig: appState.mpesaConfig,  // ← Tenant's own credentials
  phoneNumber: '0712345678',
  amount: 5000,
  accountReference: 'INV-001',
);
```

---

### 14.5 Tenant-Aware Callback Routing

When Safaricom sends the payment callback, your server must know **which tenant** the transaction belongs to. Two approaches:

#### Approach A: Per-Tenant Callback URLs (Recommended)

Give each tenant a unique callback URL:
```
Tenant A → https://yourdomain.com/api/mpesa/callback/tenant_mombasa
Tenant B → https://yourdomain.com/api/mpesa/callback/tenant_nairobi
```

```js
// Express.js — tenant-specific callback route
router.post('/api/mpesa/callback/:tenantId', async (req, res) => {
  res.status(200).json({ ResultCode: 0, ResultDesc: 'Accepted' });

  const { tenantId } = req.params;
  const stk = req.body.Body.stkCallback;
  const checkoutId = stk.CheckoutRequestID;

  if (stk.ResultCode === 0) {
    const items = stk.CallbackMetadata.Item;
    const get = (n) => items.find(i => i.Name === n)?.Value;
    await db.query(
      `UPDATE mpesa_transactions
       SET status='Completed', receipt_number=?, mpesa_amount=?
       WHERE tenant_id=? AND checkout_request_id=?`,
      [get('MpesaReceiptNumber'), get('Amount'), tenantId, checkoutId]
    );
  } else {
    await db.query(
      `UPDATE mpesa_transactions SET status='Failed', result_desc=?
       WHERE tenant_id=? AND checkout_request_id=?`,
      [stk.ResultDesc, tenantId, checkoutId]
    );
  }
});
```

#### Approach B: Single Callback + CheckoutRequestID Lookup

All tenants share one callback URL. The `CheckoutRequestID` uniquely identifies the transaction, so you can look up the `tenant_id` from the `mpesa_transactions` table:

```js
router.post('/api/mpesa/callback', async (req, res) => {
  res.status(200).json({ ResultCode: 0, ResultDesc: 'Accepted' });
  const stk = req.body.Body.stkCallback;
  // checkoutRequestId is unique — no tenant_id needed in the URL
  await db.query(
    `UPDATE mpesa_transactions SET status=? WHERE checkout_request_id=?`,
    [stk.ResultCode === 0 ? 'Completed' : 'Failed', stk.CheckoutRequestID]
  );
});
```

Approach A is cleaner for auditing; Approach B is simpler to deploy.

---

### 14.6 Security Considerations

| Risk | Mitigation |
|---|---|
| **Credentials in Flutter** | Use the backend approach (14.3). Never store Daraja credentials on the client in production. |
| **Tenant A sees Tenant B's credentials** | Firestore Security Rules: `/tenants/{tenantId}/mpesa_config` readable only by that tenant's admins. |
| **Credentials in DB as plaintext** | Encrypt `consumer_key`, `consumer_secret`, `passkey` at rest using AES-256 or your cloud provider's Key Management Service (AWS KMS, GCP Cloud KMS). |
| **Tenant impersonation** | Validate that the authenticated user belongs to the `tenantId` they are requesting payment for. Never trust client-sent `tenantId` without server-side verification. |
| **Shared callback URL** | If using Approach B (single callback), ensure `CheckoutRequestID` lookup is indexed and returns exactly one row. |
| **Credential rotation** | Build an admin UI or API to update tenant Daraja credentials without app redeployment. |

**Firestore Security Rules Example:**

```js
match /tenants/{tenantId}/mpesa_config/{configId} {
  // Only super-admins and the tenant's own admins can read
  allow read: if request.auth != null &&
    (request.auth.token.role == 'super_admin' ||
     request.auth.token.tenant_id == tenantId);

  // Only super-admins can write (to prevent tenants from modifying their own keys)
  allow write: if request.auth != null &&
    request.auth.token.role == 'super_admin';
}
```

> [!IMPORTANT]
> **For production multi-tenant M-PESA, always use the backend approach (Section 14.3).** The Flutter app should only know the `tenantId` — the backend resolves credentials, calls Daraja, and handles callbacks. This is the only pattern where you can guarantee credential security across multiple tenants.

---

## 15. Simplified Tenant Configuration ("Just Enter Your Paybill")

You want tenants to simply **type in their Paybill or Till number during setup**, and the app automatically routes payments to that number. No complex credential management from the tenant's side.

---

### 15.1 The Reality of M-PESA Credentials

> [!IMPORTANT]
> **M-PESA STK Push requires more than just a Paybill/Till number.** Every STK Push request needs:
> - `BusinessShortCode` (the Paybill/Till)
> - `Consumer Key` + `Consumer Secret` (OAuth credentials tied to that shortcode)
> - `Passkey` (unique to that shortcode)
>
> You **cannot** send an STK Push to an arbitrary Paybill just by knowing its number. The credentials must match.

So when a tenant says "my Paybill is 600100", you still need the Daraja credentials for shortcode 600100 to actually send an STK Push.

Here are the three practical ways to achieve the simple UX you want:

---

### 15.2 Approach A — Aggregator Model (One Paybill, Many Tenants)

**Best for:** You (the app owner) have one Paybill/Till, and all tenant payments go through your account. You track which tenant each payment belongs to using `AccountReference`.

```
Tenant enters their "Paybill" for DISPLAY purposes only.
All actual STK Pushes go to YOUR Paybill with YOUR credentials.
You reconcile later: AccountReference tells you which tenant owns the payment.
```

**How it works:**

```
Tenant A config: { display_paybill: "600100" }
Tenant B config: { display_paybill: "123456" }

                    BUT

All STK Pushes use YOUR credentials:
  BusinessShortCode: YOUR_PAYBILL (e.g. 174379)
  Consumer Key:      YOUR_KEY
  Consumer Secret:   YOUR_SECRET
  Passkey:           YOUR_PASSKEY
  AccountReference:  "TENANT_A-INV001"  ← Identifies the tenant
```

**Pros:**
- Tenant only enters their Paybill (for display on receipts)
- You control all credentials centrally
- One Daraja app, one callback URL

**Cons:**
- All money goes to YOUR account first — you must disburse to tenants
- Tenant's actual Paybill is not used for collection

**Flutter implementation:**
```dart
Future<Map<String, dynamic>> makePayment({
  required String tenantId,  // e.g. "tenant_mombasa"
  required String phone,
  required int amount,
  required String invoiceNumber,
}) async {
  // Always uses YOUR credentials, but tags the tenant in AccountReference
  return await mpesaService.initiateStkPush(
    phoneNumber: phone,
    amount: amount,
    accountReference: '${tenantId.substring(0, 5)}-$invoiceNumber'.substring(0, 12),
    transactionDesc: 'Payment',
  );
}
```

---

### 15.3 Approach B — Tenant Enters Paybill + You Provision Credentials

**Best for:** Each tenant truly collects to their own Paybill/Till. The tenant enters the shortcode in the app; **you (the app owner) provision the Daraja credentials** on the backend.

**How it works:**

```
┌───────────────────────────────────────────────────┐
│  Tenant Setup (in Flutter app)                       │
│  ┌────────────────────────────┐                       │
│  │  Paybill/Till: [ 600100 ]  │  ← Tenant types this  │
│  │  Type: (●) Paybill (○) Till │                       │
│  │  [Save]                    │                       │
│  └────────────────────────────┘                       │
│                                                       │
│  Saved to Firestore:                                  │
│  /tenants/{id}/payment_config                         │
│    short_code: "600100"                                │
│    type: "paybill"                                     │
└───────────────────────────────────────────────────┘
          │
          ▼
┌───────────────────────────────────────────────────┐
│  Your Backend / Admin Panel                           │
│                                                       │
│  You (app owner) sees: "Tenant X has Paybill 600100" │
│  You go to Daraja portal, register that shortcode,    │
│  and store credentials in your backend:                │
│                                                       │
│  tenant_mpesa_credentials:                             │
│    short_code: "600100"                                │
│    consumer_key: "aaa..."    ← You add these           │
│    consumer_secret: "bbb..."                           │
│    passkey: "ccc..."                                   │
└───────────────────────────────────────────────────┘
          │
          ▼
  When payment is triggered:
  Backend looks up short_code "600100" → gets credentials → calls Daraja
```

**The workflow:**
1. **Tenant** enters Paybill/Till in the Flutter app → saved to Firestore
2. **You (app owner)** get notified → register that shortcode on Daraja Portal → store credentials in your backend DB
3. **At payment time** → backend resolves `shortcode` → uses matching credentials → sends STK Push

**This is the best approach because:**
- Tenant UX is simple (just enter Paybill)
- Credentials are secure (only on your backend)
- Each tenant collects to their own account
- You can automate the provisioning later (ask tenants for Daraja API keys via a secure form)

---

### 15.4 Approach C — C2B Payment (No STK Push)

**Best for:** You want tenants to collect to their own Paybill/Till with **zero credential management**.

Instead of STK Push (which requires credentials), use **C2B (Customer to Business)** where the customer manually sends money to the tenant's Paybill/Till:

```
App shows:
  "Pay KES 5,000 to Paybill 600100, Account: INV-001"
  Customer opens M-PESA on their phone and pays manually.
  Your backend receives the C2B confirmation URL callback.
```

**Pros:**
- No Daraja credentials needed per tenant
- Tenant just enters their Paybill/Till
- Money goes directly to tenant's account

**Cons:**
- No automatic phone prompt (worse UX than STK Push)
- Customer must manually type the Paybill + amount
- Higher chance of payment errors (wrong amount, wrong account)

This is a fallback option — STK Push (Approach B) is always better UX.

---

### 15.5 Flutter Configuration Screen

Here's the tenant settings screen where admins enter their Paybill/Till:

```dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentConfigScreen extends StatefulWidget {
  final String tenantId;
  const PaymentConfigScreen({required this.tenantId});
  @override
  State<PaymentConfigScreen> createState() => _PaymentConfigScreenState();
}

class _PaymentConfigScreenState extends State<PaymentConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final _shortCodeController = TextEditingController();
  String _paymentType = 'paybill'; // 'paybill' or 'till'
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    final doc = await FirebaseFirestore.instance
        .collection('tenants')
        .doc(widget.tenantId)
        .get();
    if (doc.exists && doc.data()?['payment_config'] != null) {
      final config = doc.data()!['payment_config'];
      _shortCodeController.text = config['short_code'] ?? '';
      setState(() => _paymentType = config['type'] ?? 'paybill');
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    await FirebaseFirestore.instance
        .collection('tenants')
        .doc(widget.tenantId)
        .set({
          'payment_config': {
            'short_code': _shortCodeController.text.trim(),
            'type': _paymentType,
            // transaction_type is derived from 'type':
            // paybill = CustomerPayBillOnline
            // till    = CustomerBuyGoodsOnline
            'transaction_type': _paymentType == 'paybill'
                ? 'CustomerPayBillOnline'
                : 'CustomerBuyGoodsOnline',
            'configured_at': FieldValue.serverTimestamp(),
            'credentials_provisioned': false, // You flip this to true
          },
        }, SetOptions(merge: true));

    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment configuration saved!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Payment Settings')),
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'M-PESA Configuration',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Enter your Paybill or Till number. Payments will be '
                'collected directly to this account.',
                style: TextStyle(color: Colors.grey[600]),
              ),
              SizedBox(height: 24),

              // Payment type selector
              Text('Payment Type', style: TextStyle(fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
              Row(
                children: [
                  ChoiceChip(
                    label: Text('Paybill'),
                    selected: _paymentType == 'paybill',
                    onSelected: (_) => setState(() => _paymentType = 'paybill'),
                  ),
                  SizedBox(width: 12),
                  ChoiceChip(
                    label: Text('Till Number'),
                    selected: _paymentType == 'till',
                    onSelected: (_) => setState(() => _paymentType = 'till'),
                  ),
                ],
              ),
              SizedBox(height: 24),

              // Shortcode input
              TextFormField(
                controller: _shortCodeController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: _paymentType == 'paybill'
                      ? 'Paybill Number'
                      : 'Till Number',
                  hintText: _paymentType == 'paybill' ? 'e.g. 600100' : 'e.g. 123456',
                  prefixIcon: Icon(Icons.account_balance),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (v.trim().length < 5) return 'Must be at least 5 digits';
                  if (!RegExp(r'^\d+$').hasMatch(v.trim())) return 'Digits only';
                  return null;
                },
              ),
              SizedBox(height: 32),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text('Save Configuration'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _shortCodeController.dispose();
    super.dispose();
  }
}
```

---

### 15.6 Storing Tenant Config in Firestore

After the tenant saves their Paybill/Till:

```
/tenants/{tenantId}
  ├── name: "Mombasa County"
  ├── payment_config:
  │   ├── short_code: "600100"
  │   ├── type: "paybill"
  │   ├── transaction_type: "CustomerPayBillOnline"
  │   ├── configured_at: 2026-04-02T15:00:00Z
  │   └── credentials_provisioned: false    ← YOU flip to true after adding Daraja keys
  └── ...
```

Then you (app owner) see `credentials_provisioned: false`, go to the Daraja portal, register the shortcode, and store the credentials in your **backend database** (not Firestore — credentials should never be in a client-accessible DB):

```sql
-- On your backend, after you register the tenant's shortcode on Daraja:
INSERT INTO tenant_mpesa_credentials
  (tenant_id, short_code, consumer_key, consumer_secret, passkey)
VALUES
  ('tenant_mombasa', '600100', 'aaa...', 'bbb...', 'ccc...');

-- Then update Firestore to flag it as provisioned:
-- (via admin SDK or manually)
```

The **Flutter app only reads** `payment_config.short_code` and `credentials_provisioned`. It never sees the actual credentials.

---

### 15.7 Using the Tenant’s Paybill at Payment Time

#### Backend Route (receives tenantId, resolves credentials)

```js
router.post('/api/payment/stk-push', async (req, res) => {
  const { tenantId, phoneNumber, amount, accountReference } = req.body;

  // 1. Look up credentials by tenant
  const [creds] = await db.query(
    'SELECT * FROM tenant_mpesa_credentials WHERE tenant_id = ?',
    [tenantId]
  );

  if (!creds.length) {
    return res.json({
      status: 'error',
      message: 'Payment not configured. Please contact your administrator.',
    });
  }

  const config = creds[0];
  // 2. Use THIS tenant's short_code + credentials for the STK Push
  // ... (same as Section 14.3 backend code)
});
```

#### Flutter Payment Trigger

```dart
class PaymentProvider {
  /// Checks if the tenant has a configured Paybill, then triggers payment
  Future<Map<String, dynamic>> triggerPayment({
    required String token,
    required String tenantId,
    required String phone,
    required int amount,
    required String reference,
  }) async {
    // 1. Check if payment is configured
    final tenantDoc = await FirebaseFirestore.instance
        .collection('tenants')
        .doc(tenantId)
        .get();

    final config = tenantDoc.data()?['payment_config'];

    if (config == null || config['short_code'] == null) {
      return {
        'status': 'error',
        'message': 'Payment not configured. Go to Settings > Payment to set up your Paybill.',
      };
    }

    if (config['credentials_provisioned'] != true) {
      return {
        'status': 'error',
        'message': 'Your Paybill ${config['short_code']} is pending activation. '
                   'Please contact support.',
      };
    }

    // 2. Send to backend — backend uses the tenant's credentials
    final result = await Dio().post(
      'https://yourdomain.com/api/payment/stk-push',
      data: {
        'tenantId': tenantId,
        'phoneNumber': phone,
        'amount': amount,
        'accountReference': reference,
      },
      options: Options(
        preserveHeaderCase: true,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ),
    );

    return result.data;
  }
}
```

---

### 15.8 Which Approach Should You Use?

| Scenario | Approach | Tenant Enters | Credentials Managed By |
|---|---|---|---|
| You collect ALL payments, distribute to tenants later | **A (Aggregator)** | Paybill (display only) | You (one set) |
| Tenants collect to their OWN Paybill/Till, you manage the infrastructure | **B (Provisioned)** | Paybill/Till number | You (per tenant, on backend) |
| Tenants collect to their own Paybill/Till, zero infrastructure | **C (C2B Manual)** | Paybill/Till number | Nobody (no STK Push) |
| Tenants manage their own Daraja apps | **Section 14** | Full credentials | Tenant themselves |

> [!TIP]
> **For your use case ("tenants type their Paybill, app routes payments"), use Approach B.** The tenant only enters their shortcode. You provision the Daraja credentials on your backend. The Flutter app checks `credentials_provisioned` before allowing payments and routes the `tenantId` to your backend, which resolves the correct credentials and calls Daraja.

---

## 16. Scaling to 100+ Tenants (The Aggregator Pattern)

If you have 100 tenants, you **should not** register 100 separate apps on the Daraja portal. It is unmanageable. Instead, use an **Aggregator Pattern** to scale intelligently.

---

### 16.1 The "100 Apps" Problem

Each Daraja "App" requires manual approval, manual secret management, and manual callback URL configuration. If you try to do this 100 times:
1.  **Maintenance Nightmare:** Updating one setting (like a callback URL) would take 100 manual edits.
2.  **Safaricom Limits:** You may hit limits on the number of apps allowed per developer account.
3.  **Human Error:** One wrong copy-paste of a secret and payments break for that tenant.

---

### 16.2 Solution 1: Use an Aggregator (Highly Recommended)

The most professional way to handle 100+ tenants is to use a **Payment Aggregator** account.

1.  **What is it?** A specialized Safaricom account (or a service like iPay, Pesapal, or Intasend) that is designed to collect money on behalf of others.
2.  **How it works:** You have **one Master Paybill** and **one Daraja App**.
3.  **Tenant Payouts:** The money goes into your Master account, and your system automatically "disburses" (sends) the correct amount to each tenant's individual Paybill/Bank account at the end of the day.

---

### 16.3 Solution 2: Daraja Multi-Shortcode Pattern

If you prefer to collect directly into the tenant's shortcodes, you can link multiple shortcodes to **one single Daraja App**. This allows you to use one set of Consumer Key/Secret to manage multiple Paybills/Tills.

#### 1. The Portal Configuration (Linking)
1.  **Log in** to the [Safaricom Daraja Portal](https://developer.safaricom.co.ke/).
2.  **Go to "My Apps"** and select the production app you want to use.
3.  **Shortcode Association:** Use the "Apply for shortcode linkage" or "Associate Shortcode" feature. You will need the **Organizational Admin** role on the M-PESA G2 Portal to approve this linkage.
4.  **One App, Many Shortcodes:** Once linked, the **same Consumer Key and Secret** from this app will work for all associated shortcodes.

#### 2. Technical Implementation (Dynamic Passkeys)
While the Consumer Key/Secret are unified, each shortcode typically retains its own **Lipa Na M-PESA Online Passkey**. Your backend must dynamically select the correct Passkey to generate the `Password` parameter for the STK Push request.

**Password Formula:** `Base64Encode(BusinessShortCode + Passkey + Timestamp)`

#### 3. Backend Implementation Example (Node.js)

```javascript
// Mapping of Shortcodes to their respective Passkeys
const tenantConfigs = {
  "123456": { passkey: "bfb279f...", name: "Tenant A" },
  "789012": { passkey: "a7d8c9b...", name: "Tenant B" }
};

async function triggerSTKPush(shortCode, phoneNumber, amount) {
  const config = tenantConfigs[shortCode];
  if (!config) throw new Error("Shortcode not configured");

  const timestamp = moment().format('YYYYMMDDHHmmss');
  const password = Buffer.from(shortCode + config.passkey + timestamp).toString('base64');

  const response = await axios.post(STK_PUSH_URL, {
    "BusinessShortCode": shortCode,
    "Password": password,
    "Timestamp": timestamp,
    "TransactionType": "CustomerPayBillOnline",
    "Amount": amount,
    "PartyA": phoneNumber,
    "PartyB": shortCode,
    "PhoneNumber": phoneNumber,
    "CallBackURL": `https://your-api.com/callback?tenantShortCode=${shortCode}`,
    "AccountReference": config.name,
    "TransactionDesc": "Payment for " + config.name
  }, {
    headers: { Authorization: `Bearer ${accessToken}` }
  });

  return response.data;
}
```

> [!TIP]
> **Callback Routing:** Pass the `shortCode` as a query parameter in your `CallBackURL`. This makes it trivial for your backend hook to know which tenant's database to update when the payment notification arrives.

#### 4. Developer Insights: The Edge Case Reality
1. **Passkey Management:** When linking shortcodes to a primary Daraja App, it is critical to realize that each linked shortcode might get a new passkey or retain the old one depending on the exact linkage process by Safaricom support. You MUST build your database schema such that the `passkey` column is unique to each `tenant_shortcode` table record, not application-wide.
2. **Rate Limits Context:** A typical Daraja App can comfortably handle hundreds of transactions per second. Linking 100+ tenants to one app does NOT bottle-neck the payment gateway. However, Safaricom may enforce standard rate limits. Always ensure your error handling gracefully catches STK timeout and `Server Unavailable` errors and relays them back to the Flutter UI for a retry, rather than dropping the packet.
3. **Audit Trails & Security:** Because the single backend application initiates STK pushes on behalf of multiple shortcodes, the backend MUST securely enforce that Tenant A's user cannot trigger a payment to Tenant B's shortcode. Validate the target shortcode against the authenticated user's organization scope before executing the push.

#### 5. Flutter Implementation

To implement this pattern in Flutter, the client app does not need the Consumer Key, Secret, or Passkeys. The app's only responsibility is to dynamically send the destination **Shortcode** alongside the payment payload to the proxy backend.

**A. API Provider Update**
Update your existing `ApiProvider` to accept an optional `tenantShortcode` parameter. If absent, fallback to your default aggregator shortcode.

```dart
// lib/Api/api_provider.dart

Future<Map<String, dynamic>> postTenantOffloadingItems({
  required String token,
  required String vehicleType,
  required String plateNumber,
  required String clientName,
  required String clientPhone,
  required String zone,
  required List<Map<String, dynamic>> items,
  required int penalty,
  required String tenantShortcode, // <--- New Parameter
}) async {
  
  Map<String, dynamic> payload = {
    "appType": "createApplication",
    "origin": "Mombasa",
    "destination": "Mombasa",
    "vehicleType": vehicleType,
    "plateNumber": plateNumber,
    "clientName": clientName,
    "clientPhoneNumber": clientPhone,
    "zone": zone,
    "items": items,
    "penalty": penalty,
    "tenantShortcode": tenantShortcode, // <--- Pass Shortcode to Backend
  };
  
  final result = await Dio().post(
    Endpoints.OFFLOADING_URL,
    data: payload,
    options: Options(
      preserveHeaderCase: true,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    ),
  );
  
  return result.data;
}
```

**B. Flutter UI/State Layer Integration**
In your widget layer, retrieve the active Tenant's shortcode from local storage or authentication context (like Firebase Auth custom claims, local SQLite, or shared preferences). 

```dart
// lib/Screens/OffLoading/enterGoodDetails.dart

Future<void> _submitMultiTenantForm() async {
  // 1. Validate Form & Build Items
  if (selectedProductsList.isEmpty || !_isDeclarationChecked) return;
  
  List<Map<String, dynamic>> postItems = selectedProductsList.map((p) => {
    'id': p.itemChosen!.itemId,
    'amount': p.itemChosen!.rate,
    'quantity': p.quantity,
  }).toList();
  
  // 2. Retrieve the active tenant's shortcode. 
  // This could come from a Provider, Riverpod, or SharedPreferences.
  final String activeShortcode = "123456"; // e.g., Provider.of<TenantState>(context).shortcode;
  
  // 3. Initiate API Call
  // Ensure that the API Provider dynamically maps `tenantShortcode` parameter and sends it to the server.
  var response = await ApiProvider().postTenantOffloadingItems(
    token: widget.token,
    vehicleType: widget.capturedVehicleId!,
    plateNumber: widget.capturedPlate!,
    clientName: widget.capturedClientName!,
    clientPhone: widget.capturedPhone!,
    zone: widget.capturedZone!,
    items: postItems,
    penalty: widget.penaltyFee,
    tenantShortcode: activeShortcode,
  );
  
  if (response['status'] == "success") {
    String trackingId = response['tracking_id']?.toString() ?? "";
    String applicationId = response['newAppId']?.toString() ?? "";
    
    // 4. Trigger STK UI Polling via the CheckPaymentDialogCallback 
    // passed downwards from the main parent module.
    if (widget.CheckPaymentDialogCallback != null) {
      widget.CheckPaymentDialogCallback!(
        trackingId: trackingId,
        applicationId: applicationId,
        clientPhone: widget.capturedPhone!,
        plateNumber: widget.capturedPlate,
        resubmitCallback: ( yeniPhone) { // Example dummy prompt phone loop retry callback.
          // Handle logic
        }
      );
    }
  } else {
    // Show descriptive error gracefully!
  }
}
```

This ensures the Flutter app remains completely agnostic to M-PESA Daraja credentials, preventing reverse engineering while scaling to 100+ unique tenant endpoint shortcodes securely.

---

### 16.4 Automatic Reconciliation (Routing Payments)

To know which tenant gets the money when using one Master Paybill, use the **`AccountReference`** field. This field is returned in the callback.

#### Flutter Triggering (Aggregator Model)
```dart
Future<void> payForTenant(String tenantId, int amount) async {
  // Use a unique reference: prefix it with the Tenant's ID
  final reference = "T${tenantId.substring(0, 5)}_${DateTime.now().millisecondsSinceEpoch}";

  await api.triggerStkPush(
    amount: amount,
    phoneNumber: customerPhone,
    accountReference: reference, // "T_ABC123_171205..."
  );
}
```

#### Backend Reconciliation (Callback)
```js
app.post('/mpesa/callback', (req, res) => {
  const reference = req.body.Body.stkCallback.CallbackMetadata.Item
    .find(i => i.Name === 'AccountReference').Value;

  // Extract the tenant prefix from the reference
  const tenantPrefix = reference.split('_')[0]; // "T_ABC123"

  // Look up which tenant owns this prefix
  const tenant = await db.tenants.findOne({ prefix: tenantPrefix });

  // Credit the correct tenant's balance
  await db.tenantBalances.increment(tenant.id, amount);
});
```

---

### 16.5 Automated Disbursements (Payouts)

To close the loop, you need to send the money from your Master account to the tenant's account. You can automate this via the **B2C (Business to Customer)** or **B2B (Business to Business)** API.

1.  **Daily Settlement:** Every night, your system calculates how much each tenant collected.
2.  **Automated Payout:** Use the B2B API to send that total (minus your platform fee) to the tenant's Paybill.

```js
// Automated Daily Payout (B2B)
async function disburseToTenants() {
  const pendingPayouts = await db.payouts.find({ status: 'pending' });

  for (const payout of pendingPayouts) {
    await daraja.b2bRequest({
      Amount: payout.amount,
      ReceiverShortCode: payout.tenantPaybill,
      Remarks: "Daily Settlement",
      // ... other B2B params
    });
  }
}
```

> [!NOTE]
> **Use Section 16 for scale.** If you have 5-10 clients, Section 15's "Manual Provisioning" is fine. For 100+ clients, the **Aggregator Model** is the only way to stay sane and avoid technical debt.
