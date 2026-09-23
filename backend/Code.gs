/**
 * Department-wise Online Services Dashboard — Backend
 * Serves TWO things from the same Apps Script deployment:
 *   1. A JSON REST API (used by the Flutter mobile app)
 *   2. The old browser-based HTML page (kept for quick testing/admin use)
 *
 * SHEETS (auto-created by setupSheets()):
 *  1. "Departments" -> DeptID | DeptName | Username | PasswordHash | Icon
 *  2. "Services"    -> ServiceID | DeptID | ServiceName | Description | URL | DateAdded
 *
 * JSON API — after deploying as a Web App, your base URL looks like:
 *   https://script.google.com/macros/s/XXXXXXXX/exec
 *
 *  GET  ?action=departments
 *  GET  ?action=services&deptId=D123...
 *  POST body: {"action":"login","username":"...","password":"..."}
 *  POST body: {"action":"addService","deptId":"...","name":"...","description":"...","url":"..."}
 *  POST body: {"action":"updateService","deptId":"...","serviceId":"...","name":"...","description":"...","url":"..."}
 *  POST body: {"action":"deleteService","deptId":"...","serviceId":"..."}
 */

var SS = SpreadsheetApp.getActiveSpreadsheet();
var DEPT_SHEET = 'Departments';
var SERVICE_SHEET = 'Services';

// ---------------------------------------------------------------------
// ENTRY POINTS
// ---------------------------------------------------------------------
function doGet(e) {
  var action = e.parameter.action;

  if (!action) {
    // No action param -> serve the old browser HTML page (handy for testing)
    return HtmlService.createTemplateFromFile('index')
      .evaluate()
      .setTitle('Puducherry e-Services Directory')
      .addMetaTag('viewport', 'width=device-width, initial-scale=1, viewport-fit=cover');
  }

  try {
    if (action === 'departments') {
      return jsonOut_({ success: true, data: getDepartments() });
    }
    if (action === 'services') {
      var deptId = e.parameter.deptId;
      if (!deptId) return jsonOut_({ success: false, message: 'deptId is required' });
      return jsonOut_({ success: true, data: getServicesForDept(deptId) });
    }
    return jsonOut_({ success: false, message: 'Unknown action: ' + action });
  } catch (err) {
    return jsonOut_({ success: false, message: err.message });
  }
}

function doPost(e) {
  try {
    var body = JSON.parse(e.postData.contents);
    var action = body.action;

    if (action === 'login') {
      return jsonOut_(loginDept(body.username, body.password));
    }
    if (action === 'addService') {
      return jsonOut_(addService(body.deptId, body.name, body.description, body.url));
    }
    if (action === 'updateService') {
      return jsonOut_(updateService(body.deptId, body.serviceId, body.name, body.description, body.url));
    }
    if (action === 'deleteService') {
      return jsonOut_(deleteService(body.deptId, body.serviceId));
    }
    return jsonOut_({ success: false, message: 'Unknown action: ' + action });
  } catch (err) {
    return jsonOut_({ success: false, message: err.message });
  }
}

function jsonOut_(obj) {
  return ContentService.createTextOutput(JSON.stringify(obj))
    .setMimeType(ContentService.MimeType.JSON);
}

function include(filename) {
  return HtmlService.createHtmlOutputFromFile(filename).getContent();
}

// ---------------------------------------------------------------------
// ONE-TIME SETUP — run manually once from the Apps Script editor
// ---------------------------------------------------------------------
function setupSheets() {
  var deptSheet = SS.getSheetByName(DEPT_SHEET);
  if (!deptSheet) {
    deptSheet = SS.insertSheet(DEPT_SHEET);
    deptSheet.appendRow(['DeptID', 'DeptName', 'Username', 'PasswordHash', 'Icon']);
    deptSheet.setFrozenRows(1);
  }

  var svcSheet = SS.getSheetByName(SERVICE_SHEET);
  if (!svcSheet) {
    svcSheet = SS.insertSheet(SERVICE_SHEET);
    svcSheet.appendRow(['ServiceID', 'DeptID', 'ServiceName', 'Description', 'URL', 'DateAdded']);
    svcSheet.setFrozenRows(1);
  }

  var sheet1 = SS.getSheetByName('Sheet1');
  if (sheet1 && sheet1.getLastRow() === 0) {
    SS.deleteSheet(sheet1);
  }

  SpreadsheetApp.flush();
  return 'Setup complete. Now add departments with addDepartmentHelper().';
}

function addDepartmentHelper() {
  addDepartment('Revenue Department', 'revenue_admin', 'ChangeThisPassword123', '🏛️');
}

function addDepartment(deptName, username, plainPassword, icon) {
  var sheet = SS.getSheetByName(DEPT_SHEET);
  var deptId = 'D' + new Date().getTime();
  sheet.appendRow([deptId, deptName, username, hashPassword_(plainPassword), icon || '🏢']);
  return deptId;
}

// ---------------------------------------------------------------------
// PASSWORD HASHING
// ---------------------------------------------------------------------
function hashPassword_(plain) {
  var digest = Utilities.computeDigest(Utilities.DigestAlgorithm.SHA_256, plain, Utilities.Charset.UTF_8);
  return digest.map(function (b) { return ('0' + (b & 0xFF).toString(16)).slice(-2); }).join('');
}

// ---------------------------------------------------------------------
// PUBLIC READ FUNCTIONS
// ---------------------------------------------------------------------
function getDepartments() {
  var sheet = SS.getSheetByName(DEPT_SHEET);
  var rows = sheet.getDataRange().getValues();
  var svcCounts = getServiceCountsByDept_();

  var out = [];
  for (var i = 1; i < rows.length; i++) {
    var r = rows[i];
    if (!r[0]) continue;
    out.push({
      id: r[0],
      name: r[1],
      icon: r[4] || '🏢',
      serviceCount: svcCounts[r[0]] || 0
    });
  }
  out.sort(function (a, b) { return a.name.localeCompare(b.name); });
  return out;
}

function getServiceCountsByDept_() {
  var sheet = SS.getSheetByName(SERVICE_SHEET);
  var rows = sheet.getDataRange().getValues();
  var counts = {};
  for (var i = 1; i < rows.length; i++) {
    var deptId = rows[i][1];
    if (!deptId) continue;
    counts[deptId] = (counts[deptId] || 0) + 1;
  }
  return counts;
}

function getServicesForDept(deptId) {
  var sheet = SS.getSheetByName(SERVICE_SHEET);
  var rows = sheet.getDataRange().getValues();
  var out = [];
  for (var i = 1; i < rows.length; i++) {
    var r = rows[i];
    if (r[1] === deptId) {
      out.push({
        id: r[0],
        deptId: r[1],
        name: r[2],
        description: r[3],
        url: r[4],
        dateAdded: r[5] ? new Date(r[5]).toISOString() : ''
      });
    }
  }
  return out;
}

// ---------------------------------------------------------------------
// LOGIN
// ---------------------------------------------------------------------
function loginDept(username, password) {
  var sheet = SS.getSheetByName(DEPT_SHEET);
  var rows = sheet.getDataRange().getValues();
  var hash = hashPassword_(password);

  for (var i = 1; i < rows.length; i++) {
    var r = rows[i];
    if (r[2] === username) {
      if (r[3] === hash) {
        return { success: true, deptId: r[0], deptName: r[1] };
      }
      return { success: false, message: 'Incorrect password.' };
    }
  }
  return { success: false, message: 'No department found with that username.' };
}

// ---------------------------------------------------------------------
// DEPARTMENT-SIDE SERVICE MANAGEMENT
// ---------------------------------------------------------------------
function addService(deptId, name, description, url) {
  if (!deptId || !name || !url) {
    return { success: false, message: 'Service name and URL are required.' };
  }
  if (!/^https?:\/\//i.test(url)) {
    return { success: false, message: 'URL must start with http:// or https://' };
  }
  var sheet = SS.getSheetByName(SERVICE_SHEET);
  var serviceId = 'S' + new Date().getTime();
  sheet.appendRow([serviceId, deptId, name, description, url, new Date()]);
  return { success: true, serviceId: serviceId };
}

function updateService(deptId, serviceId, name, description, url) {
  var sheet = SS.getSheetByName(SERVICE_SHEET);
  var rows = sheet.getDataRange().getValues();
  for (var i = 1; i < rows.length; i++) {
    if (rows[i][0] === serviceId) {
      if (rows[i][1] !== deptId) {
        return { success: false, message: 'Not authorized to edit this service.' };
      }
      sheet.getRange(i + 1, 3).setValue(name);
      sheet.getRange(i + 1, 4).setValue(description);
      sheet.getRange(i + 1, 5).setValue(url);
      return { success: true };
    }
  }
  return { success: false, message: 'Service not found.' };
}

function deleteService(deptId, serviceId) {
  var sheet = SS.getSheetByName(SERVICE_SHEET);
  var rows = sheet.getDataRange().getValues();
  for (var i = 1; i < rows.length; i++) {
    if (rows[i][0] === serviceId) {
      if (rows[i][1] !== deptId) {
        return { success: false, message: 'Not authorized to delete this service.' };
      }
      sheet.deleteRow(i + 1);
      return { success: true };
    }
  }
  return { success: false, message: 'Service not found.' };
}
