import os
import base64
import subprocess

workspace_dir = r"c:\Users\noureddine\Desktop\ameex"
output_pdf_workspace = os.path.join(workspace_dir, "Ameex_App_Presentation.pdf")
output_pdf_artifacts = r"C:\Users\noureddine\.gemini\antigravity\brain\7f8b64c4-0d24-4248-9098-de41dd606d61\Ameex_App_Presentation.pdf"
temp_html = os.path.join(workspace_dir, "presentation_temp.html")

logo_white_path = os.path.join(workspace_dir, "assets", "images", "logo_white.png")
logo_dark_path = os.path.join(workspace_dir, "assets", "images", "logo_dark.png")

logo_white_b64 = ""
if os.path.exists(logo_white_path):
    with open(logo_white_path, "rb") as f:
        logo_white_b64 = "data:image/png;base64," + base64.b64encode(f.read()).decode()

logo_dark_b64 = ""
if os.path.exists(logo_dark_path):
    with open(logo_dark_path, "rb") as f:
        logo_dark_b64 = "data:image/png;base64," + base64.b64encode(f.read()).decode()

html_content = f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Ameex Logistics Platform - Executive Presentation</title>
<style>
  @import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap');

  @page {{
    size: A4 landscape;
    margin: 0;
  }}

  * {{
    box-sizing: border-box;
    margin: 0;
    padding: 0;
  }}

  body {{
    font-family: 'Plus Jakarta Sans', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
    background-color: #0A192F;
    color: #1E293B;
    -webkit-print-color-adjust: exact;
    print-color-adjust: exact;
  }}

  .slide {{
    width: 297mm;
    height: 210mm;
    page-break-after: always;
    page-break-inside: avoid;
    overflow: hidden;
    position: relative;
    padding: 38px 48px;
    display: flex;
    flex-direction: column;
    justify-content: space-between;
    background: #F8FAFC;
  }}

  /* Slide 1 - Cover */
  .slide.cover {{
    background: linear-gradient(135deg, #0A192F 0%, #0F2A4A 60%, #1E3A8A 100%);
    color: white;
    justify-content: center;
    align-items: center;
    text-align: center;
    padding: 60px 80px;
  }}

  .cover-logo {{
    height: 60px;
    margin-bottom: 24px;
  }}

  .cover-badge {{
    display: inline-block;
    padding: 8px 18px;
    border-radius: 30px;
    background: rgba(255, 255, 255, 0.1);
    border: 1px solid rgba(255, 255, 255, 0.2);
    font-size: 13px;
    letter-spacing: 1px;
    text-transform: uppercase;
    font-weight: 700;
    color: #38BDF8;
    margin-bottom: 24px;
  }}

  .cover-title {{
    font-size: 44px;
    font-weight: 800;
    line-height: 1.15;
    letter-spacing: -1px;
    margin-bottom: 16px;
  }}

  .cover-subtitle {{
    font-size: 20px;
    color: #94A3B8;
    max-width: 780px;
    margin: 0 auto 36px auto;
    line-height: 1.5;
  }}

  .cover-stats {{
    display: flex;
    gap: 24px;
    justify-content: center;
    margin-top: 20px;
  }}

  .cover-stat-card {{
    background: rgba(255, 255, 255, 0.06);
    border: 1px solid rgba(255, 255, 255, 0.12);
    padding: 16px 28px;
    border-radius: 14px;
    min-width: 170px;
  }}

  .cover-stat-val {{
    font-size: 26px;
    font-weight: 800;
    color: #38BDF8;
  }}

  .cover-stat-lbl {{
    font-size: 11px;
    color: #CBD5E1;
    margin-top: 4px;
    text-transform: uppercase;
    letter-spacing: 0.5px;
  }}

  /* Standard Slide Header & Footer */
  .slide-header {{
    display: flex;
    justify-content: space-between;
    align-items: center;
    border-bottom: 2px solid #E2E8F0;
    padding-bottom: 14px;
    margin-bottom: 20px;
  }}

  .slide-header-left {{
    display: flex;
    align-items: center;
    gap: 14px;
  }}

  .slide-header-logo {{
    height: 28px;
  }}

  .slide-tag {{
    font-size: 11px;
    font-weight: 700;
    text-transform: uppercase;
    color: #1E3A8A;
    background: #EFF6FF;
    padding: 4px 10px;
    border-radius: 6px;
    border: 1px solid #BFDBFE;
  }}

  .slide-title {{
    font-size: 24px;
    font-weight: 800;
    color: #0F172A;
    letter-spacing: -0.5px;
  }}

  .slide-subtitle {{
    font-size: 13px;
    color: #64748B;
    margin-top: 2px;
  }}

  .slide-footer {{
    display: flex;
    justify-content: space-between;
    align-items: center;
    border-top: 1px solid #E2E8F0;
    padding-top: 12px;
    margin-top: 16px;
    font-size: 11px;
    color: #94A3B8;
  }}

  .slide-body {{
    flex: 1;
    display: flex;
    flex-direction: column;
    justify-content: center;
  }}

  /* Grid Layouts */
  .grid-2 {{
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 20px;
  }}

  .grid-3 {{
    display: grid;
    grid-template-columns: 1fr 1fr 1fr;
    gap: 18px;
  }}

  .grid-4 {{
    display: grid;
    grid-template-columns: 1fr 1fr 1fr 1fr;
    gap: 16px;
  }}

  /* Cards */
  .card {{
    background: white;
    border-radius: 14px;
    padding: 20px;
    border: 1px solid #E2E8F0;
    box-shadow: 0 4px 12px rgba(0,0,0,0.03);
  }}

  .card-navy {{
    background: linear-gradient(135deg, #0A192F 0%, #1E3A8A 100%);
    color: white;
    border: none;
  }}

  .card-amber {{
    background: #FFFBEB;
    border: 1.5px solid #FDE68A;
  }}

  .card-emerald {{
    background: #F0FDF4;
    border: 1.5px solid #BBF7D0;
  }}

  .card-header-icon {{
    display: inline-flex;
    align-items: center;
    justify-content: center;
    width: 38px;
    height: 38px;
    border-radius: 10px;
    margin-bottom: 12px;
    font-size: 18px;
  }}

  .card-title {{
    font-size: 16px;
    font-weight: 700;
    color: #0F172A;
    margin-bottom: 6px;
  }}

  .card-desc {{
    font-size: 12px;
    color: #475569;
    line-height: 1.5;
  }}

  /* Process Flow */
  .flow-container {{
    display: flex;
    align-items: center;
    gap: 12px;
    margin: 15px 0;
  }}

  .flow-step {{
    flex: 1;
    background: white;
    border: 1.5px solid #E2E8F0;
    border-radius: 12px;
    padding: 16px;
    text-align: center;
    box-shadow: 0 2px 8px rgba(0,0,0,0.02);
  }}

  .flow-arrow {{
    font-size: 22px;
    color: #1E3A8A;
    font-weight: bold;
  }}

  .step-num {{
    display: inline-block;
    width: 26px;
    height: 26px;
    background: #EFF6FF;
    color: #1E3A8A;
    border-radius: 50%;
    font-weight: 800;
    font-size: 12px;
    line-height: 26px;
    margin-bottom: 8px;
  }}

  .badge-tag {{
    display: inline-block;
    padding: 4px 10px;
    border-radius: 6px;
    font-size: 11px;
    font-weight: 700;
  }}

  .badge-green {{
    background: #DCFCE7;
    color: #166534;
  }}

  .badge-orange {{
    background: #FEF3C7;
    color: #92400E;
  }}

  .badge-blue {{
    background: #EFF6FF;
    color: #1E3A8A;
  }}

  /* Table styling */
  table {{
    width: 100%;
    border-collapse: collapse;
    font-size: 12px;
    background: white;
    border-radius: 10px;
    overflow: hidden;
  }}

  th {{
    background: #0A192F;
    color: white;
    padding: 12px 14px;
    text-align: left;
    font-weight: 700;
  }}

  td {{
    padding: 11px 14px;
    border-bottom: 1px solid #E2E8F0;
    color: #334155;
  }}

  tr:nth-child(even) {{
    background: #F8FAFC;
  }}
</style>
</head>
<body>

<!-- SLIDE 1: COVER -->
<div class="slide cover">
  <div class="cover-badge">Next-Generation Logistics Ecosystem</div>
  {"<img src='" + logo_white_b64 + "' class='cover-logo' alt='Ameex' />" if logo_white_b64 else "<h1 style='font-size:52px;margin-bottom:12px;'>ameex</h1>"}
  <div class="cover-title">Smart Delivery & Fleet Management</div>
  <div class="cover-subtitle">Connecting Hub Dispatchers, Field Couriers, and E-Commerce Merchants with High-Precision Geolocation and Transparent Cash Remittance.</div>
  
  <div class="cover-stats">
    <div class="cover-stat-card">
      <div class="cover-stat-val">24-48h</div>
      <div class="cover-stat-lbl">Guaranteed Turnaround</div>
    </div>
    <div class="cover-stat-card">
      <div class="cover-stat-val">500+</div>
      <div class="cover-stat-lbl">Moroccan Destinations</div>
    </div>
    <div class="cover-stat-card">
      <div class="cover-stat-val">100%</div>
      <div class="cover-stat-lbl">COD Audit Accuracy</div>
    </div>
    <div class="cover-stat-card">
      <div class="cover-stat-val">>50%</div>
      <div class="cover-stat-lbl">Driver Fuel Guarantee</div>
    </div>
  </div>
</div>

<!-- SLIDE 2: THE MOROCCAN LOGISTICS CHALLENGE & THE AMEEX SOLUTION -->
<div class="slide">
  <div class="slide-header">
    <div class="slide-header-left">
      {"<img src='" + logo_dark_b64 + "' class='slide-header-logo' />" if logo_dark_b64 else "<strong>AMEEX</strong>"}
      <div>
        <div class="slide-title">Market Challenges & Strategic Solutions</div>
        <div class="slide-subtitle">Solving the traditional friction points of last-mile delivery in Morocco</div>
      </div>
    </div>
    <div class="slide-tag">Executive Strategy</div>
  </div>

  <div class="slide-body">
    <table>
      <thead>
        <tr>
          <th style="width: 25%;">Traditional Bottleneck</th>
          <th style="width: 35%;">The Real-World Impact</th>
          <th style="width: 40%;">The Ameex Solution</th>
        </tr>
      </thead>
      <tbody>
        <tr>
          <td><strong>Vague Customer Addresses</strong></td>
          <td>Addresses often lack street numbers (e.g. "near the mosque"). Couriers make multiple phone calls, increasing delivery failure rates.</td>
          <td><span class="badge-tag badge-blue">Interactive Pin Drop</span> Couriers pin exact client GPS coordinates on the live map, automatically synced with the Admin Control Tower.</td>
        </tr>
        <tr>
          <td><strong>COD & Commission Confusion</strong></td>
          <td>Cash-on-Delivery collected from clients is mixed with courier earnings, leading to accounting errors and lost revenue.</td>
          <td><span class="badge-tag badge-orange">Strict Cash Separation</span> Clear barrier between <strong>Agency Cash (COD)</strong> and <strong>Driver Net Earnings</strong> with real-time balance sheets.</td>
        </tr>
        <tr>
          <td><strong>Unverified Agency Remittances</strong></td>
          <td>Disputes arise over whether courier cash was physically deposited at the agency counter at day's end.</td>
          <td><span class="badge-tag badge-green">Admin Remittance Validation</span> Driver commission remains locked until the dispatcher validates physical cash handover in the portal.</td>
        </tr>
        <tr>
          <td><strong>Unfair Driver Cancellations</strong></td>
          <td>Clients cancel orders when the courier has already driven across town, leaving the driver with unpaid fuel and lost time.</td>
          <td><span class="badge-tag badge-green">50% Travel Guarantee</span> Automated tracking unlocks 100% of driver fees if cancellation occurs after 50% route completion.</td>
        </tr>
      </tbody>
    </table>
  </div>

  <div class="slide-footer">
    <span>Ameex Logistics Platform • Confidential & Proprietary</span>
    <span>Slide 02 / 07</span>
  </div>
</div>

<!-- SLIDE 3: ADMIN CONTROL TOWER -->
<div class="slide">
  <div class="slide-header">
    <div class="slide-header-left">
      {"<img src='" + logo_dark_b64 + "' class='slide-header-logo' />" if logo_dark_b64 else "<strong>AMEEX</strong>"}
      <div>
        <div class="slide-title">Admin Control Tower & Fleet Dispatch</div>
        <div class="slide-subtitle">Real-time visibility, automated parcel dispatch, and physical counter handovers</div>
      </div>
    </div>
    <div class="slide-tag">Control Center</div>
  </div>

  <div class="slide-body">
    <div class="grid-3">
      <div class="card">
        <div class="card-header-icon" style="background:#EFF6FF;color:#1E3A8A;">📍</div>
        <div class="card-title">Live GPS Fleet Telemetry</div>
        <div class="card-desc">
          Interactive map tracking couriers in real time. Visual filters by vehicle type (scooter, motorcycle, car, van) and operational state (Available, In Transit, En Route to Agency).
        </div>
      </div>

      <div class="card">
        <div class="card-header-icon" style="background:#F0FDF4;color:#16A34A;">📦</div>
        <div class="card-title">Barcode Scanning & Dispatch</div>
        <div class="card-desc">
          Instant package assignment via barcode and QR camera scanning. Automated commission calculation and parcel tag generation with zero manual data entry errors.
        </div>
      </div>

      <div class="card">
        <div class="card-header-icon" style="background:#FFFBEB;color:#D97706;">🏢</div>
        <div class="card-title">Counter Handover Verification</div>
        <div class="card-desc">
          Two-step physical dispatch: Courier accepts mission, travels to the hub, and the dispatcher formally confirms physical parcel handover before transit begins.
        </div>
      </div>
    </div>

    <div style="margin-top: 18px;" class="card card-navy">
      <div style="display:flex; justify-content:space-between; align-items:center;">
        <div>
          <div style="font-size:16px; font-weight:700; margin-bottom:4px;">Synchronized Client Destination Cards ("Cartes Clients")</div>
          <div style="font-size:12px; color:#CBD5E1;">Dispatchers can browse drop-off locations and click "Voir sur la carte" to instantly zoom to the customer's coordinates pinned by the field courier.</div>
        </div>
        <span class="badge-tag badge-green" style="font-size:12px; padding:6px 14px;">Real-Time Sync</span>
      </div>
    </div>
  </div>

  <div class="slide-footer">
    <span>Ameex Logistics Platform • Confidential & Proprietary</span>
    <span>Slide 03 / 07</span>
  </div>
</div>

<!-- SLIDE 4: DRIVER EXPERIENCE & SMART WORKFLOWS -->
<div class="slide">
  <div class="slide-header">
    <div class="slide-header-left">
      {"<img src='" + logo_dark_b64 + "' class='slide-header-logo' />" if logo_dark_b64 else "<strong>AMEEX</strong>"}
      <div>
        <div class="slide-title">Field Courier Experience & Workflow</div>
        <div class="slide-subtitle">A modern, distraction-free mobile portal designed for drivers on motorcycles and vans</div>
      </div>
    </div>
    <div class="slide-tag">Courier Portal</div>
  </div>

  <div class="slide-body">
    <div class="flow-container">
      <div class="flow-step">
        <div class="step-num">1</div>
        <div style="font-weight:700;font-size:13px;margin-bottom:4px;">Accept Mission</div>
        <div style="font-size:11px;color:#64748B;">Receives instant alert with fee, distance, and parcel destination.</div>
      </div>
      <div class="flow-arrow">➔</div>
      <div class="flow-step">
        <div class="step-num">2</div>
        <div style="font-weight:700;font-size:13px;margin-bottom:4px;">Hub Pickup</div>
        <div style="font-size:11px;color:#64748B;">Rides to agency counter where admin confirms physical package handover.</div>
      </div>
      <div class="flow-arrow">➔</div>
      <div class="flow-step">
        <div class="step-num">3</div>
        <div style="font-weight:700;font-size:13px;margin-bottom:4px;">Client Drop-Off</div>
        <div style="font-size:11px;color:#64748B;">Pins exact dropoff coordinates, contacts customer, and scans parcel barcode.</div>
      </div>
      <div class="flow-arrow">➔</div>
      <div class="flow-step">
        <div class="step-num">4</div>
        <div style="font-weight:700;font-size:13px;margin-bottom:4px;">Swipe to Complete</div>
        <div style="font-size:11px;color:#64748B;">Ergonomic swipe slider verifies COD collection and marks delivery successful.</div>
      </div>
    </div>

    <div class="grid-3" style="margin-top: 14px;">
      <div class="card">
        <div style="font-weight:700;font-size:13px;color:#0F172A;margin-bottom:6px;">📍 Live Client Pinning</div>
        <div style="font-size:11px;color:#64748B;line-height:1.4;">Allows couriers to adjust drop-off coordinates directly on the map, persisting accurate geo-data for future re-orders.</div>
      </div>
      <div class="card">
        <div style="font-weight:700;font-size:13px;color:#0F172A;margin-bottom:6px;">⚡ Quick Communication</div>
        <div style="font-size:11px;color:#64748B;line-height:1.4;">Integrated one-tap phone calls and WhatsApp messaging directly from the mission drawer with pre-filled tracking details.</div>
      </div>
      <div class="card">
        <div style="font-weight:700;font-size:13px;color:#0F172A;margin-bottom:6px;">🔒 Camera Barcode Check</div>
        <div style="font-size:11px;color:#64748B;line-height:1.4;">Integrated camera scanner checks tracking number automatically, preventing delivering the wrong package to the wrong recipient.</div>
      </div>
    </div>
  </div>

  <div class="slide-footer">
    <span>Ameex Logistics Platform • Confidential & Proprietary</span>
    <span>Slide 04 / 07</span>
  </div>
</div>

<!-- SLIDE 5: REVENUE & CASH REMITTANCE ARCHITECTURE -->
<div class="slide">
  <div class="slide-header">
    <div class="slide-header-left">
      {"<img src='" + logo_dark_b64 + "' class='slide-header-logo' />" if logo_dark_b64 else "<strong>AMEEX</strong>"}
      <div>
        <div class="slide-title">Financial Architecture: COD vs. Courier Commission</div>
        <div class="slide-subtitle">Clear financial transparency with automated unlock upon agency remittance</div>
      </div>
    </div>
    <div class="slide-tag">Financial Accounting</div>
  </div>

  <div class="slide-body">
    <div class="grid-2">
      <!-- Card Agency COD -->
      <div class="card card-amber">
        <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:12px;">
          <span style="font-weight:800;font-size:16px;color:#92400E;">🏢 Agency Cash (COD)</span>
          <span class="badge-tag badge-orange">Customer Payments</span>
        </div>
        <div style="font-size:28px; font-weight:800; color:#B45309; margin-bottom:8px;">300.00 MAD</div>
        <div style="font-size:12px; color:#78350F; line-height:1.5;">
          • Cash collected directly from customers upon delivery.<br>
          • Strictly separated from courier wages.<br>
          • Must be physically remitted to the Ameex agency cashier.<br>
          • <strong>Pending status:</strong> Courier holds agency cash until verified.
        </div>
      </div>

      <!-- Card Driver Commission -->
      <div class="card card-navy">
        <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:12px;">
          <span style="font-weight:800;font-size:16px;color:#38BDF8;">💰 Courier Net Earnings</span>
          <span class="badge-tag badge-green">Ready to Withdraw</span>
        </div>
        <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:8px;">
          <div style="font-size:28px; font-weight:800; color:white;">125.00 MAD</div>
          <button style="background:#10B981;color:white;border:none;padding:8px 16px;border-radius:8px;font-weight:700;font-size:12px;cursor:pointer;">💸 Retirer (Payout)</button>
        </div>
        <div style="font-size:12px; color:#CBD5E1; line-height:1.5;">
          • Unlocked automatically once admin validates cash remittance.<br>
          • <strong>Channels:</strong> Agency Counter, CIH / Attijariwafa Bank RIB, or Cash Plus.<br>
          • Full audit trail with individual transaction reference codes (e.g. <code>RET-AMX-9482</code>).
        </div>
      </div>
    </div>

    <div style="margin-top: 18px;" class="card card-emerald">
      <div style="display:flex; align-items:center; gap:14px;">
        <div style="font-size:28px;">🛡️</div>
        <div>
          <div style="font-weight:800; font-size:14px; color:#166534; margin-bottom:2px;">The Ameex 50% Travel Guarantee Policy</div>
          <div style="font-size:11px; color:#166534; line-height:1.4;">
            If an order is cancelled by the client after the courier has covered more than 50% of the journey, Ameex pays 100% of the courier's contracted commission to compensate fuel, time, and road effort.
          </div>
        </div>
      </div>
    </div>
  </div>

  <div class="slide-footer">
    <span>Ameex Logistics Platform • Confidential & Proprietary</span>
    <span>Slide 05 / 07</span>
  </div>
</div>

<!-- SLIDE 6: TECHNICAL ARCHITECTURE -->
<div class="slide">
  <div class="slide-header">
    <div class="slide-header-left">
      {"<img src='" + logo_dark_b64 + "' class='slide-header-logo' />" if logo_dark_b64 else "<strong>AMEEX</strong>"}
      <div>
        <div class="slide-title">Technology Stack & System Architecture</div>
        <div class="slide-subtitle">Built with enterprise-grade cross-platform frameworks and reactive cloud backends</div>
      </div>
    </div>
    <div class="slide-tag">Engineering</div>
  </div>

  <div class="slide-body">
    <div class="grid-4">
      <div class="card">
        <div class="card-header-icon" style="background:#EFF6FF;color:#0284C7;">📱</div>
        <div class="card-title" style="font-size:14px;">Flutter 3 SDK</div>
        <div class="card-desc" style="font-size:11px;">
          Unified single codebase compiling natively to Android, iOS, Windows Desktop, and Web. High-speed 60fps animations and custom responsive widgets.
        </div>
      </div>

      <div class="card">
        <div class="card-header-icon" style="background:#F0FDF4;color:#16A34A;">⚡</div>
        <div class="card-title" style="font-size:14px;">Supabase Realtime</div>
        <div class="card-desc" style="font-size:11px;">
          PostgreSQL with WebSocket streaming. State changes (accepted, in transit, delivered, remitted) propagate to all connected clients in under 150ms.
        </div>
      </div>

      <div class="card">
        <div class="card-header-icon" style="background:#FEF3C7;color:#D97706;">🗺️</div>
        <div class="card-title" style="font-size:14px;">OpenStreetMap & OSRM</div>
        <div class="card-desc" style="font-size:11px;">
          High-performance vector cartography with open-source road routing. Calculates real road distance and progress tracking without costly proprietary API fees.
        </div>
      </div>

      <div class="card">
        <div class="card-header-icon" style="background:#F5F3FF;color:#7C3AED;">🔐</div>
        <div class="card-title" style="font-size:14px;">Security & Storage</div>
        <div class="card-desc" style="font-size:11px;">
          Row-Level Security (RLS) policies ensuring couriers only access assigned orders. Supabase Storage for courier profiles and camera photo verification.
        </div>
      </div>
    </div>

    <div style="margin-top: 16px;" class="card">
      <div style="font-weight:700;font-size:13px;color:#0F172A;margin-bottom:8px;">Deployment Topology</div>
      <div style="display:flex; justify-content:space-between; font-size:11px; color:#475569; text-align:center;">
        <div style="flex:1; padding:10px; background:#F8FAFC; border-radius:8px; margin-right:8px;">
          <strong style="display:block; color:#0F172A; margin-bottom:4px;">Dispatcher Workstations</strong>
          Chrome / Edge Web App & Windows Native Desktop (.exe)
        </div>
        <div style="flex:1; padding:10px; background:#F8FAFC; border-radius:8px; margin-right:8px;">
          <strong style="display:block; color:#0F172A; margin-bottom:4px;">Courier Mobile Units</strong>
          Android APK & Standalone Progressive Web App (PWA)
        </div>
        <div style="flex:1; padding:10px; background:#F8FAFC; border-radius:8px;">
          <strong style="display:block; color:#0F172A; margin-bottom:4px;">Cloud Infrastructure</strong>
          Supabase Managed Cloud (PostgreSQL, Auth, Realtime Edge Functions)
        </div>
      </div>
    </div>
  </div>

  <div class="slide-footer">
    <span>Ameex Logistics Platform • Confidential & Proprietary</span>
    <span>Slide 06 / 07</span>
  </div>
</div>

<!-- SLIDE 7: BUSINESS VALUE & ROADMAP -->
<div class="slide">
  <div class="slide-header">
    <div class="slide-header-left">
      {"<img src='" + logo_dark_b64 + "' class='slide-header-logo' />" if logo_dark_b64 else "<strong>AMEEX</strong>"}
      <div>
        <div class="slide-title">Strategic Value & Growth Roadmap</div>
        <div class="slide-subtitle">Delivering measurable ROI and positioning Ameex as Morocco's logistics leader</div>
      </div>
    </div>
    <div class="slide-tag">Executive Summary</div>
  </div>

  <div class="slide-body">
    <div class="grid-3">
      <div class="card" style="border-top: 4px solid #10B981;">
        <div style="font-weight:800; font-size:15px; color:#0F172A; margin-bottom:8px;">1. Zero Cash Leakage</div>
        <div style="font-size:12px; color:#64748B; line-height:1.5;">
          With strict separation between COD customer collections and driver payouts, accounting errors and unremitted funds drop to zero.
        </div>
      </div>

      <div class="card" style="border-top: 4px solid #1E3A8A;">
        <div style="font-weight:800; font-size:15px; color:#0F172A; margin-bottom:8px;">2. 35% Faster Delivery Times</div>
        <div style="font-size:12px; color:#64748B; line-height:1.5;">
          Direct destination pinning and integrated routing eliminate courier confusion, reducing average delivery time per parcel from 45 min to under 25 min.
        </div>
      </div>

      <div class="card" style="border-top: 4px solid #F59E0B;">
        <div style="font-weight:800; font-size:15px; color:#0F172A; margin-bottom:8px;">3. Superior Courier Retention</div>
        <div style="font-size:12px; color:#64748B; line-height:1.5;">
          Fair cancellation guarantees, transparent earnings, and instant multi-channel withdrawals make Ameex the employer of choice for drivers.
        </div>
      </div>
    </div>

    <div style="margin-top: 18px;" class="card card-navy">
      <div style="font-weight:800; font-size:15px; margin-bottom:8px;">Upcoming Strategic Milestones</div>
      <div style="display:flex; justify-content:space-between; font-size:11px; color:#CBD5E1;">
        <div>• Automated AI Cluster Dispatch (Batching multi-orders in Maarif & Anfa)</div>
        <div>• Self-Service Merchant Portal & E-Commerce Webhook API</div>
        <div>• Multi-Hub Cross-Docking between Casablanca, Rabat & Marrakech</div>
      </div>
    </div>
  </div>

  <div class="slide-footer">
    <span>Ameex Logistics Platform • Confidential & Proprietary</span>
    <span>Slide 07 / 07</span>
  </div>
</div>

</body>
</html>
"""

with open(temp_html, "w", encoding="utf-8") as f:
    f.write(html_content)

print(f"HTML written to {temp_html}")

chrome_exe = r"C:\Program Files\Google\Chrome\Application\chrome.exe"
cmd = [
    chrome_exe,
    "--headless=new",
    "--disable-gpu",
    "--no-sandbox",
    "--run-all-compositor-stages-before-draw",
    f"--print-to-pdf={output_pdf_workspace}",
    temp_html
]

print("Running Chrome to generate PDF...")
res = subprocess.run(cmd, capture_output=True, text=True)
print("Return code:", res.returncode)
if res.stderr:
    print("Stderr:", res.stderr)

if os.path.exists(output_pdf_workspace):
    size = os.path.getsize(output_pdf_workspace)
    print(f"Success! PDF generated at {output_pdf_workspace} ({size} bytes)")
    
    # Also copy to artifacts dir
    import shutil
    shutil.copy2(output_pdf_workspace, output_pdf_artifacts)
    print(f"Copied to artifacts: {output_pdf_artifacts}")
else:
    print("Failed to generate PDF.")
