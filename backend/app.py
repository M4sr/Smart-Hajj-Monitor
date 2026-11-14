from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

# Database and models imports to trigger MySQL schema initialization
from core.database import engine
import models
from routers import auth, assessments, users, notifications, tts, sos

# Create tables
models.Base.metadata.create_all(bind=engine)

# Dynamically migrate is_temp_password column if it doesn't exist
from sqlalchemy import text
try:
    with engine.connect() as connection:
        result = connection.execute(text("SHOW COLUMNS FROM users LIKE 'is_temp_password'")).fetchone()
        if not result:
            connection.execute(text("ALTER TABLE users ADD COLUMN is_temp_password INT DEFAULT 0"))
            print("Successfully migrated: Added column 'is_temp_password' to 'users' table.")
            
        email_result = connection.execute(text("SHOW COLUMNS FROM users LIKE 'email'")).fetchone()
        if not email_result:
            connection.execute(text("ALTER TABLE users ADD COLUMN email VARCHAR(100) UNIQUE NULL"))
            print("Successfully migrated: Added column 'email' to 'users' table.")
            
        provider_result = connection.execute(text("SHOW COLUMNS FROM users LIKE 'auth_provider'")).fetchone()
        if not provider_result:
            connection.execute(text("ALTER TABLE users ADD COLUMN auth_provider VARCHAR(20) DEFAULT 'local' NOT NULL"))
            print("Successfully migrated: Added column 'auth_provider' to 'users' table.")
except Exception as e:
    print(f"Warning: Dynamic migration failed: {e}")

app = FastAPI(
    title="Smart Hajj & Umrah Monitor API",
    description="Backend API for Jemaah self-assessment and medical monitoring using ML.",
    version="1.0.0"
)

# CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(auth.router)
app.include_router(assessments.router)
app.include_router(users.router)
app.include_router(notifications.router)
app.include_router(tts.router)
app.include_router(sos.router)
from fastapi.staticfiles import StaticFiles
import os

vps_apk_dir = "/www/wwwroot/app-haji-monitoring.my.id/apk"
local_apk_dir = "apk"

if os.path.exists(vps_apk_dir):
    apk_directory = vps_apk_dir
else:
    apk_directory = local_apk_dir
    if not os.path.exists(apk_directory):
        os.makedirs(apk_directory)

app.mount("/apk", StaticFiles(directory=apk_directory), name="apk")

uploads_directory = os.path.join(os.path.dirname(__file__), "uploads", "profiles")
if not os.path.exists(uploads_directory):
    os.makedirs(uploads_directory)

app.mount("/uploads", StaticFiles(directory=os.path.join(os.path.dirname(__file__), "uploads")), name="uploads")

from fastapi.responses import HTMLResponse

@app.get("/", response_class=HTMLResponse)
def read_root():
    html_content = """
<!DOCTYPE html>
<html lang="id">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Smart Hajj Monitor</title>
<link href="https://fonts.googleapis.com/css2?family=Cinzel:wght@400;600;700;900&family=Plus+Jakarta+Sans:wght@300;400;500;600;700&display=swap" rel="stylesheet">
<style>
/* ═══════════════════════════════════════
   RESET & VARIABLES
═══════════════════════════════════════ */
:root {
  --green-dark: #0b2216;
  --green-mid: #163520;
  --green-card: rgba(16,42,24,0.9);
  --gold: #c9a84c;
  --gold-light: #f0d080;
  --gold-dim: rgba(201,168,76,0.3);
  --text: #e8f5e9;
  --text-muted: rgba(232,245,233,0.6);
  --radius-lg: 20px;
  --radius-md: 14px;
  --radius-sm: 10px;
}
*{margin:0;padding:0;box-sizing:border-box;}
html{scroll-behavior:smooth;}
body{
  font-family:'Plus Jakarta Sans',sans-serif;
  background:var(--green-dark);
  color:var(--text);
  overflow-x:hidden;
  min-height:100vh;
}

/* ═══════════════════════════════════════
   CANVAS & ORNAMENTS
═══════════════════════════════════════ */
#stars-canvas{
  position:fixed;top:0;left:0;
  width:100%;height:100%;
  pointer-events:none;z-index:0;
}
.corner-ornament{
  position:fixed;pointer-events:none;z-index:1;
  opacity:0.13;
  width:160px;height:160px;
}
@media(min-width:768px){.corner-ornament{width:220px;height:220px;opacity:0.18;}}
.corner-ornament svg{width:100%;height:100%;}
.corner-ornament.tl{top:0;left:0;}
.corner-ornament.tr{top:0;right:0;transform:scaleX(-1);}
.corner-ornament.bl{bottom:0;left:0;transform:scaleY(-1);}
.corner-ornament.br{bottom:0;right:0;transform:scale(-1,-1);}

/* ═══════════════════════════════════════
   NAVBAR
═══════════════════════════════════════ */
nav{
  position:fixed;top:0;left:0;right:0;z-index:200;
  display:flex;align-items:center;justify-content:space-between;
  padding:0 16px;height:60px;
  background:rgba(8,20,13,0.95);
  backdrop-filter:blur(16px);
  border-bottom:1px solid var(--gold-dim);
  animation:slideDown .5s ease forwards;
}
@media(min-width:768px){nav{padding:0 40px;height:68px;}}
@keyframes slideDown{from{transform:translateY(-100%);opacity:0}to{transform:translateY(0);opacity:1}}

.nav-logo{display:flex;align-items:center;gap:9px;text-decoration:none;}
.nav-logo-icon{
  width:34px;height:34px;
  background:linear-gradient(135deg,var(--gold),var(--gold-light));
  border-radius:50% 50% 50% 10%;
  display:flex;align-items:center;justify-content:center;
  font-size:16px;
  animation:rotateMoon 8s ease-in-out infinite;
  flex-shrink:0;
}
@media(min-width:768px){.nav-logo-icon{width:38px;height:38px;font-size:18px;}}
@keyframes rotateMoon{0%,100%{transform:rotate(-5deg)}50%{transform:rotate(5deg)}}
.nav-logo-text{line-height:1.1;}
.nav-logo-text span:first-child{
  display:block;font-family:'Cinzel',serif;
  font-size:10px;font-weight:700;
  color:var(--gold);letter-spacing:2px;
}
.nav-logo-text span:last-child{
  display:block;font-family:'Cinzel',serif;
  font-size:9px;font-weight:600;
  color:var(--gold-light);letter-spacing:1.5px;
}

/* Desktop nav links */
.nav-links{display:none;gap:24px;list-style:none;}
@media(min-width:900px){.nav-links{display:flex;}}
.nav-links a{
  color:var(--text-muted);text-decoration:none;font-size:13px;
  letter-spacing:.4px;transition:color .2s;position:relative;
}
.nav-links a::after{
  content:'';position:absolute;bottom:-4px;left:0;right:0;height:1px;
  background:var(--gold);transform:scaleX(0);transition:transform .2s;
}
.nav-links a:hover{color:var(--gold-light);}
.nav-links a:hover::after{transform:scaleX(1);}

.nav-right{display:flex;align-items:center;gap:10px;}
.btn-get-started{
  padding:8px 16px;background:transparent;
  border:1.5px solid var(--gold);color:var(--gold-light);
  font-family:'Cinzel',serif;font-size:10px;font-weight:700;
  letter-spacing:1px;cursor:pointer;border-radius:6px;
  transition:all .25s;white-space:nowrap;
}
@media(min-width:768px){.btn-get-started{padding:9px 20px;font-size:11px;}}
.btn-get-started:hover{
  background:var(--gold);color:var(--green-dark);
  box-shadow:0 0 20px rgba(201,168,76,.5);
}

/* Hamburger */
.hamburger{
  display:flex;flex-direction:column;gap:5px;
  cursor:pointer;padding:4px;background:none;border:none;
}
@media(min-width:900px){.hamburger{display:none;}}
.hamburger span{
  display:block;width:22px;height:2px;
  background:var(--gold);border-radius:2px;
  transition:all .3s;
}
.hamburger.open span:nth-child(1){transform:rotate(45deg) translate(5px,5px);}
.hamburger.open span:nth-child(2){opacity:0;}
.hamburger.open span:nth-child(3){transform:rotate(-45deg) translate(5px,-5px);}

/* Mobile drawer */
.mobile-menu{
  position:fixed;top:60px;left:0;right:0;z-index:190;
  background:rgba(8,22,14,0.98);
  backdrop-filter:blur(20px);
  border-bottom:1px solid var(--gold-dim);
  padding:0 20px;
  max-height:0;overflow:hidden;
  transition:max-height .4s ease, padding .4s ease;
}
.mobile-menu.open{max-height:400px;padding:20px 20px 24px;}
.mobile-menu a{
  display:block;padding:12px 0;
  color:var(--text-muted);text-decoration:none;
  font-size:15px;font-weight:500;
  border-bottom:1px solid rgba(201,168,76,.08);
  transition:color .2s;
}
.mobile-menu a:last-child{border-bottom:none;}
.mobile-menu a:hover{color:var(--gold-light);}

/* ═══════════════════════════════════════
   HERO
═══════════════════════════════════════ */
.hero{
  position:relative;z-index:2;
  min-height:100vh;
  display:flex;flex-direction:column;
  align-items:center;justify-content:center;
  padding:80px 20px 60px;
  text-align:center;
  overflow:hidden;
  gap:40px;
}
@media(min-width:768px){
  .hero{padding:100px 40px 70px;gap:50px;}
}
@media(min-width:1024px){
  .hero{flex-direction:row;text-align:left;padding:100px 60px 60px;gap:0;}
}

/* Mosque silhouette */
.mosque-bg{
  position:absolute;bottom:0;left:0;right:0;
  height:50%;pointer-events:none;
  background:url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 1200 400'%3E%3Cpath fill='%230d2018' d='M0,400 L0,280 L40,280 L40,200 L60,180 L80,160 L100,145 L120,140 L140,145 L160,160 L180,180 L200,200 L200,280 L240,280 L240,250 L260,230 L280,220 L300,230 L320,250 L320,280 L380,280 L380,200 L420,180 L440,160 L460,140 L480,130 L500,120 L520,115 L540,110 L560,115 L580,120 L600,130 L620,140 L640,160 L660,180 L700,200 L700,280 L760,280 L760,250 L780,230 L800,220 L820,230 L840,250 L840,280 L880,280 L880,200 L920,180 L940,160 L960,145 L980,140 L1000,145 L1020,160 L1040,180 L1060,200 L1060,280 L1100,280 L1100,220 L1120,200 L1140,185 L1160,180 L1180,185 L1200,200 L1200,400 Z'/%3E%3Cpath fill='%23122a1a' d='M540,110 L540,40 L545,20 L550,10 L555,5 L560,0 L565,5 L570,10 L575,20 L580,40 L580,110 Z'/%3E%3Ccircle cx='560' cy='8' r='6' fill='%23c9a84c' opacity='0.9'/%3E%3Cpath fill='%23122a1a' d='M100,140 L100,80 L104,65 L108,52 L112,44 L116,38 L120,34 L124,38 L128,44 L132,52 L136,65 L140,80 L140,140 Z'/%3E%3Ccircle cx='120' cy='32' r='5' fill='%23c9a84c' opacity='0.7'/%3E%3Cpath fill='%23122a1a' d='M940,160 L940,100 L944,86 L948,74 L952,66 L956,60 L960,56 L964,60 L968,66 L972,74 L976,86 L980,100 L980,160 Z'/%3E%3Ccircle cx='960' cy='54' r='5' fill='%23c9a84c' opacity='0.7'/%3E%3C/svg%3E") no-repeat bottom center / cover;
  opacity:.9;
}

/* Moon */
.moon{
  position:absolute;top:12%;left:6%;
  width:60px;height:60px;
  animation:moonFloat 6s ease-in-out infinite;
  filter:drop-shadow(0 0 16px rgba(201,168,76,.6));
}
@media(min-width:768px){.moon{width:80px;height:80px;left:10%;}}
@keyframes moonFloat{0%,100%{transform:translateY(0)}50%{transform:translateY(-12px)}}

/* Shooting stars */
.shooting-star{
  position:absolute;width:100px;height:2px;
  background:linear-gradient(90deg,transparent,var(--gold-light),transparent);
  border-radius:50%;opacity:0;
  animation:shoot 4s ease-in-out infinite;
}
.shooting-star:nth-child(1){top:18%;left:20%;transform:rotate(-30deg);animation-delay:0s;}
.shooting-star:nth-child(2){top:28%;left:45%;transform:rotate(-25deg);animation-delay:1.8s;}
.shooting-star:nth-child(3){top:12%;left:62%;transform:rotate(-20deg);animation-delay:3.2s;}
@keyframes shoot{
  0%{opacity:0;transform:translateX(-60px) rotate(-30deg)}
  20%{opacity:1}60%{opacity:1;transform:translateX(60px) rotate(-30deg)}
  100%{opacity:0;transform:translateX(120px) rotate(-30deg)}
}

/* Sparkle dots */
.sparkle-svg{
  position:absolute;top:0;left:0;width:100%;height:100%;
  pointer-events:none;z-index:1;
}

/* Hero content */
.hero-content{
  flex:1;z-index:3;position:relative;
  animation:fadeInUp .8s .3s both;
  max-width:560px;
}
@media(min-width:1024px){.hero-content{padding-right:40px;}}
@keyframes fadeInUp{from{opacity:0;transform:translateY(28px)}to{opacity:1;transform:translateY(0)}}

/* Badge pill */
.hero-badge{
  display:inline-flex;align-items:center;gap:7px;
  background:rgba(201,168,76,.1);
  border:1px solid rgba(201,168,76,.35);
  border-radius:100px;padding:5px 14px;
  font-size:11px;font-weight:600;color:var(--gold-light);
  letter-spacing:.5px;margin-bottom:18px;
}
.hero-badge span{
  width:6px;height:6px;border-radius:50%;
  background:var(--gold);
  animation:badgePulse 1.5s ease-in-out infinite;
}
@keyframes badgePulse{0%,100%{opacity:1}50%{opacity:.3}}

.hero-tagline{
  font-size:clamp(16px,4vw,22px);
  font-weight:300;color:var(--text);
  line-height:1.4;margin-bottom:8px;
}
.hero-title{
  font-family:'Cinzel',serif;
  font-size:clamp(28px,7vw,56px);
  font-weight:900;color:var(--gold);
  text-shadow:0 0 30px rgba(201,168,76,.5),0 0 60px rgba(201,168,76,.2);
  letter-spacing:clamp(1px,2vw,4px);
  line-height:1.05;margin-bottom:18px;
  animation:glowPulse 3s ease-in-out infinite;
}
@keyframes glowPulse{
  0%,100%{text-shadow:0 0 30px rgba(201,168,76,.5),0 0 60px rgba(201,168,76,.2)}
  50%{text-shadow:0 0 40px rgba(201,168,76,.8),0 0 90px rgba(201,168,76,.3)}
}
.hero-sub{
  font-size:clamp(13px,3.5vw,15px);
  line-height:1.8;color:var(--text-muted);
  margin-bottom:32px;
}

/* CTA row */
.hero-cta{
  display:flex;flex-direction:column;align-items:center;gap:16px;
}
@media(min-width:480px){.hero-cta{flex-direction:row;flex-wrap:wrap;justify-content:center;}}
@media(min-width:1024px){.hero-cta{justify-content:flex-start;}}

.btn-download{
  display:inline-flex;align-items:center;gap:8px;
  padding:14px 30px;
  background:linear-gradient(135deg,var(--gold),#a87c28);
  color:var(--green-dark);
  font-family:'Cinzel',serif;font-size:13px;font-weight:700;
  letter-spacing:1.5px;border:none;cursor:pointer;border-radius:8px;
  text-decoration:none;
  transition:all .3s;
  box-shadow:0 4px 24px rgba(201,168,76,.4);
  animation:btnPulse 2.5s ease-in-out infinite;
  white-space:nowrap;
}
@keyframes btnPulse{
  0%,100%{box-shadow:0 4px 24px rgba(201,168,76,.4)}
  50%{box-shadow:0 4px 40px rgba(201,168,76,.7),0 0 60px rgba(201,168,76,.2)}
}
.btn-download:hover{transform:translateY(-2px) scale(1.02);box-shadow:0 8px 40px rgba(201,168,76,.6);}

/* Dropdown styling */
.dropdown {
  position: relative;
  display: inline-block;
}
.dropdown-content {
  display: none;
  position: absolute;
  background-color: rgba(8, 20, 13, 0.95);
  backdrop-filter: blur(10px);
  min-width: 220px;
  box-shadow: 0px 8px 24px 0px rgba(0,0,0,0.6);
  z-index: 100;
  border: 1px solid var(--gold-dim);
  border-radius: 8px;
  overflow: hidden;
  top: 100%;
  left: 50%;
  transform: translateX(-50%);
  margin-top: 10px;
}
.dropdown-content a {
  color: var(--text);
  padding: 12px 16px;
  text-decoration: none;
  display: block;
  font-size: 11px;
  font-family: 'Plus Jakarta Sans', sans-serif;
  border-bottom: 1px solid rgba(201,168,76,.1);
  transition: background-color 0.2s, color 0.2s;
  text-align: left;
}
.dropdown-content a:last-child {
  border-bottom: none;
}
.dropdown-content a:hover {
  background-color: rgba(201,168,76,.15);
  color: var(--gold-light);
}
.dropdown:hover .dropdown-content,
.dropdown.active .dropdown-content {
  display: block;
  animation: dropFadeIn 0.3s forwards;
}
@keyframes dropFadeIn {
  from { opacity: 0; transform: translate(-50%, -10px); }
  to { opacity: 1; transform: translate(-50%, 0); }
}

.store-badges{display:flex;gap:10px;flex-wrap:wrap;justify-content:center;}
@media(min-width:1024px){.store-badges{justify-content:flex-start;}}
.store-badge{
  display:flex;align-items:center;gap:8px;
  padding:9px 14px;
  background:rgba(0,0,0,.45);
  border:1px solid rgba(201,168,76,.3);
  border-radius:8px;cursor:pointer;
  transition:all .2s;text-decoration:none;color:inherit;
}
.store-badge:hover{border-color:var(--gold);background:rgba(201,168,76,.1);}
.store-badge .bi{font-size:18px;}
.store-badge .bt{line-height:1.2;}
.store-badge .bt small{display:block;font-size:8px;color:var(--text-muted);letter-spacing:1px;}
.store-badge .bt strong{font-size:12px;}

/* Stats strip */
.stats-strip{
  display:flex;gap:0;
  background:rgba(201,168,76,.06);
  border:1px solid var(--gold-dim);
  border-radius:14px;overflow:hidden;
  margin-top:28px;width:100%;
}
.stat-item{
  flex:1;padding:14px 10px;text-align:center;
  border-right:1px solid var(--gold-dim);
}
.stat-item:last-child{border-right:none;}
.stat-val{
  font-family:'Cinzel',serif;
  font-size:clamp(16px,4vw,22px);
  font-weight:700;color:var(--gold);
  display:block;
}
.stat-lbl{font-size:9px;color:var(--text-muted);letter-spacing:.5px;margin-top:2px;}

/* ── Phone mockup ── */
.hero-phone{
  flex:0 0 auto;z-index:3;position:relative;
  display:flex;justify-content:center;
  animation:phoneFloat 5s ease-in-out infinite;
}
@keyframes phoneFloat{0%,100%{transform:translateY(0) rotate(1.5deg)}50%{transform:translateY(-14px) rotate(-1deg)}}

.phone-wrap{position:relative;}
.phone-glow-ring{
  position:absolute;border-radius:50%;
  border:1px solid rgba(201,168,76,.15);
  animation:expandRing 3s ease-out infinite;
  pointer-events:none;
}
.phone-glow-ring:nth-child(1){width:280px;height:280px;top:50%;left:50%;transform:translate(-50%,-50%);animation-delay:0s;}
.phone-glow-ring:nth-child(2){width:380px;height:380px;top:50%;left:50%;transform:translate(-50%,-50%);animation-delay:1s;}
.phone-glow-ring:nth-child(3){width:480px;height:480px;top:50%;left:50%;transform:translate(-50%,-50%);animation-delay:2s;}
@keyframes expandRing{
  0%{opacity:.5;transform:translate(-50%,-50%) scale(.85)}
  100%{opacity:0;transform:translate(-50%,-50%) scale(1.3)}
}
.phone-frame{
  width:230px;height:470px;
  background:linear-gradient(160deg,#1a3a24,#0c1e12);
  border-radius:34px;
  border:2px solid rgba(201,168,76,.45);
  box-shadow:
    0 0 0 5px rgba(9,22,13,.9),
    0 0 50px rgba(201,168,76,.2),
    0 24px 70px rgba(0,0,0,.6),
    inset 0 0 28px rgba(201,168,76,.04);
  overflow:hidden;position:relative;
}
@media(min-width:480px){.phone-frame{width:250px;height:510px;}}
@media(min-width:768px){.phone-frame{width:260px;height:530px;}}

.phone-notch{
  width:90px;height:20px;
  background:#090f0b;border-radius:0 0 12px 12px;
  margin:0 auto;position:relative;z-index:5;
}
.phone-screen{padding:7px 12px;height:calc(100% - 20px);overflow:hidden;}
.phone-header{
  display:flex;justify-content:space-between;align-items:center;margin-bottom:8px;
}
.phone-header span{font-size:9px;color:var(--gold-light);font-family:'Cinzel',serif;}
.phone-tabs{display:flex;gap:6px;margin-bottom:10px;}
.phone-tab{
  font-size:8px;padding:3px 7px;border-radius:4px;
  background:rgba(201,168,76,.12);color:rgba(232,245,233,.55);cursor:pointer;
  transition:all .2s;
}
.phone-tab.active{background:var(--gold);color:var(--green-dark);font-weight:700;}
.phone-map{
  width:100%;height:115px;border-radius:9px;
  background:radial-gradient(ellipse at center,#1a4a2a 0%,#0d2018 70%);
  position:relative;overflow:hidden;margin-bottom:9px;
}
.map-grid{
  position:absolute;inset:0;
  background-image:
    linear-gradient(rgba(201,168,76,.07) 1px,transparent 1px),
    linear-gradient(90deg,rgba(201,168,76,.07) 1px,transparent 1px);
  background-size:16px 16px;
}
.kaaba-dot{
  position:absolute;top:43%;left:45%;
  width:16px;height:16px;
  background:var(--gold);border-radius:3px;
  box-shadow:0 0 12px var(--gold-light);
  animation:kaabaPulse 2s ease-in-out infinite;
}
@keyframes kaabaPulse{
  0%,100%{box-shadow:0 0 12px var(--gold-light),0 0 0 0 rgba(201,168,76,.4)}
  50%{box-shadow:0 0 20px var(--gold-light),0 0 0 10px rgba(201,168,76,0)}
}
.pilgrim-dots span{
  position:absolute;width:6px;height:6px;
  background:rgba(100,220,140,.9);border-radius:50%;
  box-shadow:0 0 5px rgba(100,220,140,.8);
}
.health-panel{
  background:rgba(0,0,0,.3);
  border:1px solid rgba(201,168,76,.2);
  border-radius:7px;padding:7px 9px;margin-bottom:7px;
}
.health-panel h4{font-size:8px;color:var(--gold);font-family:'Cinzel',serif;margin-bottom:5px;}
.health-stats{display:flex;gap:8px;}
.health-stat{text-align:center;}
.health-stat .val{font-size:16px;font-weight:700;color:var(--gold-light);line-height:1;}
.health-stat .lbl{font-size:7px;color:var(--text-muted);}
.heart-stat .val{color:#ff6b8a;}
.notif-item{
  display:flex;align-items:center;gap:5px;
  background:rgba(0,0,0,.22);border-radius:5px;
  padding:4px 7px;margin-bottom:3px;
  font-size:7.5px;color:rgba(232,245,233,.7);
  border-left:2px solid var(--gold);
  animation:notifFade 3s ease-in-out infinite;
}
.notif-item:nth-child(2){animation-delay:1.5s;border-left-color:#ff6b8a;}
@keyframes notifFade{0%,100%{opacity:.7}50%{opacity:1}}
.notif-dot{width:5px;height:5px;border-radius:50%;background:var(--gold);flex-shrink:0;}
.notif-dot.red{background:#ff6b8a;}

/* ═══════════════════════════════════════
   DIVIDER
═══════════════════════════════════════ */
.divider{
  position:relative;z-index:2;
  display:flex;align-items:center;justify-content:center;
  padding:8px 20px;
}
.divider-line{flex:1;height:1px;background:linear-gradient(90deg,transparent,var(--gold-dim),transparent);}
.divider-ornament{padding:0 14px;font-size:16px;color:var(--gold);opacity:.6;}

/* ═══════════════════════════════════════
   FEATURES
═══════════════════════════════════════ */
.features{
  position:relative;z-index:2;
  padding:60px 20px 70px;
}
@media(min-width:768px){.features{padding:70px 40px 80px;}}
@media(min-width:1024px){.features{padding:80px 60px 90px;}}

.section-title{
  text-align:center;
  font-family:'Cinzel',serif;
  font-size:clamp(20px,5vw,26px);
  font-weight:700;color:var(--gold);
  margin-bottom:40px;letter-spacing:2px;
  position:relative;
}
.section-title::after{
  content:'';display:block;
  width:60px;height:2px;
  background:linear-gradient(90deg,transparent,var(--gold),transparent);
  margin:10px auto 0;
  animation:expandLine 2s ease-in-out infinite;
}
@keyframes expandLine{0%,100%{width:60px}50%{width:130px}}

.features-grid{
  display:grid;
  grid-template-columns:1fr;
  gap:18px;
  max-width:1050px;margin:0 auto;
}
@media(min-width:580px){.features-grid{grid-template-columns:repeat(2,1fr);}}
@media(min-width:900px){.features-grid{grid-template-columns:repeat(3,1fr);gap:22px;}}

.feature-card{
  background:var(--green-card);
  border:1px solid var(--gold-dim);
  border-radius:var(--radius-lg);
  padding:24px 20px;
  position:relative;overflow:hidden;
  transition:transform .3s,box-shadow .3s;
  cursor:default;
  animation:fadeInUp .7s both;
}
.feature-card::before{
  content:'';position:absolute;inset:0;
  background:linear-gradient(135deg,rgba(201,168,76,.06) 0%,transparent 55%);
  opacity:0;transition:opacity .3s;
}
.feature-card:hover{transform:translateY(-5px);box-shadow:0 16px 48px rgba(0,0,0,.45),0 0 28px rgba(201,168,76,.12);}
.feature-card:hover::before{opacity:1;}
.feature-card:nth-child(1){animation-delay:.1s}
.feature-card:nth-child(2){animation-delay:.22s}
.feature-card:nth-child(3){animation-delay:.34s}

.feature-icons{display:flex;gap:9px;margin-bottom:18px;}
.feature-icon{
  width:42px;height:42px;border-radius:10px;
  background:linear-gradient(135deg,rgba(201,168,76,.22),rgba(201,168,76,.07));
  border:1px solid rgba(201,168,76,.28);
  display:flex;align-items:center;justify-content:center;
  font-size:19px;transition:transform .2s;
}
.feature-card:hover .feature-icon{transform:scale(1.08);}
.feature-title{
  font-family:'Cinzel',serif;font-size:15px;font-weight:700;
  color:var(--text);margin-bottom:9px;line-height:1.3;
}
.feature-desc{font-size:12.5px;color:var(--text-muted);line-height:1.7;margin-bottom:14px;}

/* Mini phone card */
.mini-card{
  width:100%;height:90px;
  background:rgba(0,0,0,.28);
  border-radius:10px;border:1px solid rgba(201,168,76,.18);
  overflow:hidden;position:relative;
  display:flex;align-items:center;justify-content:center;
}

/* Sparkline */
.sparkline{width:90%;height:60px;position:relative;}
.sparkline svg{width:100%;height:100%;}

/* Chat bubbles */
.chat-bubble{
  position:absolute;border-radius:8px;padding:5px 9px;
  font-size:7.5px;line-height:1.3;
  animation:chatBounce 3s ease-in-out infinite;
}
.chat-bubble.incoming{
  background:rgba(201,168,76,.18);color:var(--gold-light);
  border:1px solid rgba(201,168,76,.28);
  left:8px;top:14px;
}
.chat-bubble.outgoing{
  background:rgba(50,140,70,.28);color:#a8e6b8;
  border:1px solid rgba(50,140,70,.28);
  right:8px;bottom:10px;animation-delay:.8s;
}
@keyframes chatBounce{0%,100%{transform:translateY(0)}50%{transform:translateY(-4px)}}

/* Notif card items */
.notif-ci{
  display:flex;align-items:center;gap:6px;
  font-size:8px;color:var(--text-muted);
  padding:5px 10px;border-radius:6px;
  background:rgba(0,0,0,.22);
  border-left:2px solid var(--gold);
  margin:3px 8px;
  animation:notifFade 2.5s ease-in-out infinite;
}
.notif-ci:nth-child(2){border-left-color:#ff6b8a;animation-delay:.5s;}
.notif-ci:nth-child(3){border-left-color:#60c8a0;animation-delay:1s;}

/* ═══════════════════════════════════════
   HOW IT WORKS (bonus section mobile)
═══════════════════════════════════════ */
.how-section{
  position:relative;z-index:2;
  padding:50px 20px 60px;
  background:linear-gradient(180deg,transparent,rgba(8,18,11,.6) 40%,rgba(8,18,11,.6) 100%);
}
@media(min-width:768px){.how-section{padding:60px 40px 70px;}}

.steps-grid{
  display:grid;grid-template-columns:1fr;gap:16px;
  max-width:800px;margin:0 auto;
}
@media(min-width:600px){.steps-grid{grid-template-columns:repeat(3,1fr);}}

.step-card{
  display:flex;flex-direction:column;align-items:center;
  text-align:center;padding:24px 18px;
  background:rgba(16,40,22,.85);
  border:1px solid var(--gold-dim);
  border-radius:var(--radius-lg);
  position:relative;overflow:hidden;
  animation:fadeInUp .7s both;
}
.step-card:nth-child(1){animation-delay:.05s}
.step-card:nth-child(2){animation-delay:.15s}
.step-card:nth-child(3){animation-delay:.25s}

.step-num{
  width:44px;height:44px;border-radius:50%;
  background:linear-gradient(135deg,var(--gold),#a87c28);
  color:var(--green-dark);
  font-family:'Cinzel',serif;font-size:16px;font-weight:900;
  display:flex;align-items:center;justify-content:center;
  margin-bottom:14px;
  box-shadow:0 0 20px rgba(201,168,76,.3);
}
.step-icon{font-size:28px;margin-bottom:12px;}
.step-title{
  font-family:'Cinzel',serif;font-size:13px;font-weight:700;
  color:var(--gold-light);margin-bottom:8px;
}
.step-desc{font-size:12px;color:var(--text-muted);line-height:1.65;}

/* ═══════════════════════════════════════
   DOWNLOAD BANNER
═══════════════════════════════════════ */
.download-banner{
  position:relative;z-index:10;
  margin:0 20px 20px;
  padding:36px 24px;
  background:linear-gradient(135deg,rgba(20,55,30,.95),rgba(10,28,16,.95));
  border:1px solid rgba(201,168,76,.3);
  border-radius:var(--radius-lg);
  text-align:center;
  overflow:visible;
}
@media(min-width:768px){.download-banner{margin:0 40px 20px;padding:50px 40px;}}
.download-banner::before{
  content:'';position:absolute;inset:0;
  border-radius:inherit;
  background:radial-gradient(ellipse at 50% 0%,rgba(201,168,76,.1) 0%,transparent 70%);
}
.download-banner h2{
  font-family:'Cinzel',serif;
  font-size:clamp(20px,5vw,30px);
  color:var(--gold);margin-bottom:10px;
  position:relative;
}
.download-banner p{
  font-size:clamp(13px,3.5vw,15px);
  color:var(--text-muted);margin-bottom:28px;
  position:relative;
}
.download-btns{
  display:flex;flex-direction:column;align-items:center;gap:12px;
  position:relative;
}
@media(min-width:480px){.download-btns{flex-direction:row;justify-content:center;}}

/* ═══════════════════════════════════════
   FOOTER
═══════════════════════════════════════ */
footer{
  position:relative;z-index:2;
  background:rgba(6,16,10,.95);
  border-top:1px solid rgba(201,168,76,.12);
  padding:44px 20px 28px;
}
@media(min-width:768px){footer{padding:52px 40px 32px;}}

.footer-grid{
  display:grid;
  grid-template-columns:1fr 1fr;
  gap:28px;
  margin-bottom:36px;
}
@media(min-width:600px){.footer-grid{grid-template-columns:repeat(3,1fr);}}
@media(min-width:900px){.footer-grid{grid-template-columns:repeat(3,1fr);gap:40px;}}

.footer-col h3{
  font-family:'Cinzel',serif;font-size:12px;font-weight:700;
  color:var(--gold);margin-bottom:14px;letter-spacing:1.5px;
}
.footer-col ul{list-style:none;}
.footer-col ul li{margin-bottom:8px;}
.footer-col ul li a{
  color:var(--text-muted);text-decoration:none;font-size:13px;
  transition:color .2s;
}
.footer-col ul li a:hover{color:var(--gold-light);}

.social-icons{display:flex;gap:10px;flex-wrap:wrap;}
.social-icon{
  width:36px;height:36px;border-radius:9px;
  background:rgba(201,168,76,.1);
  border:1px solid rgba(201,168,76,.22);
  display:flex;align-items:center;justify-content:center;
  font-size:15px;cursor:pointer;transition:all .2s;text-decoration:none;
}
.social-icon:hover{background:rgba(201,168,76,.22);transform:translateY(-2px);}

.footer-bottom{
  text-align:center;font-size:11px;color:rgba(232,245,233,.35);
  padding-top:22px;border-top:1px solid rgba(201,168,76,.07);
  letter-spacing:1.5px;
}

/* ═══════════════════════════════════════
   SCROLL REVEAL
═══════════════════════════════════════ */
.reveal{opacity:0;transform:translateY(22px);transition:opacity .65s ease,transform .65s ease;}
.reveal.visible{opacity:1;transform:translateY(0);}
</style>
</head>
<body>

<canvas id="stars-canvas"></canvas>

<!-- Corner ornaments -->
<div class="corner-ornament tl">
  <svg viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg"><g fill="none" stroke="#c9a84c"><polyline points="0,0 200,0 200,20 20,20 20,200 0,200 0,0"/><circle cx="20" cy="20" r="14"/><polygon points="40,40 60,20 80,40 60,60"/><polygon points="55,55 70,40 85,55 70,70"/></g></svg>
</div>
<div class="corner-ornament tr">
  <svg viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg"><g fill="none" stroke="#c9a84c"><polyline points="0,0 200,0 200,0 200,200 180,200 180,20 0,20 0,0"/><circle cx="180" cy="20" r="14"/><polygon points="120,40 140,20 160,40 140,60"/><polygon points="115,55 130,40 145,55 130,70"/></g></svg>
</div>

<!-- ═══ NAVBAR ═══ -->
<nav id="navbar">
  <a href="#" class="nav-logo">
    <div class="nav-logo-icon">🌙</div>
    <div class="nav-logo-text">
      <span>SMART HAJJ</span>
      <span>MONITOR</span>
    </div>
  </a>
  <ul class="nav-links">
    <li><a href="#">Fitur</a></li>
    <li><a href="#">Kesehatan</a></li>
    <li><a href="#">AI</a></li>
    <li><a href="#">Unduh</a></li>
    <li><a href="#">Dukungan</a></li>
    <li><a href="#">Masuk</a></li>
  </ul>
  <div class="nav-right">
    <button class="btn-get-started">Mulai Sekarang</button>
    <button class="hamburger" id="hamburger" aria-label="Menu">
      <span></span><span></span><span></span>
    </button>
  </div>
</nav>

<!-- Mobile drawer -->
<div class="mobile-menu" id="mobileMenu">
  <a href="#">Fitur</a>
  <a href="#">Kesehatan</a>
  <a href="#">AI</a>
  <a href="#">Unduh</a>
  <a href="#">Dukungan</a>
  <a href="#">Masuk</a>
</div>

<!-- ═══ HERO ═══ -->
<section class="hero">
  <div class="mosque-bg"></div>

  <svg class="moon" viewBox="0 0 80 80" xmlns="http://www.w3.org/2000/svg">
    <defs><radialGradient id="mg" cx="40%" cy="40%"><stop offset="0%" stop-color="#f0d080"/><stop offset="100%" stop-color="#c9a84c"/></radialGradient></defs>
    <path d="M40,8 A32,32 0 1,1 15,60 A24,24 0 1,0 40,8Z" fill="url(#mg)"/>
  </svg>
  <div class="shooting-star"></div>
  <div class="shooting-star"></div>
  <div class="shooting-star"></div>

  <svg class="sparkle-svg" xmlns="http://www.w3.org/2000/svg">
    <circle cx="14%" cy="22%" r="1.8" fill="#f0d080" opacity=".8"><animate attributeName="opacity" values=".8;.15;.8" dur="2.1s" repeatCount="indefinite"/></circle>
    <circle cx="28%" cy="16%" r="1.4" fill="#f0d080" opacity=".6"><animate attributeName="opacity" values=".6;.1;.6" dur="1.7s" repeatCount="indefinite"/></circle>
    <circle cx="55%" cy="10%" r="2" fill="#f0d080" opacity=".7"><animate attributeName="opacity" values=".7;.1;.7" dur="2.5s" repeatCount="indefinite"/></circle>
    <circle cx="72%" cy="19%" r="1.4" fill="#f0d080" opacity=".5"><animate attributeName="opacity" values=".5;.1;.5" dur="3s" repeatCount="indefinite"/></circle>
    <circle cx="88%" cy="13%" r="1.8" fill="#f0d080" opacity=".55"><animate attributeName="opacity" values=".55;.1;.55" dur="1.9s" repeatCount="indefinite"/></circle>
  </svg>

  <!-- Content -->
  <div class="hero-content">
    <div class="hero-badge"><span></span>Aplikasi Haji Terpercaya #1</div>
    <p class="hero-tagline">Rasakan Perjalanan Haji yang<br>Terhubung &amp; Penuh Berkah bersama</p>
    <h1 class="hero-title">SMART HAJJ MONITOR</h1>
    <p class="hero-sub">Panduan Real-Time, Kesehatan &amp; Kesejahteraan untuk Jamaah.<br>Cerdas. Aman. Spiritual.</p>
    <div class="hero-cta">
      <div class="dropdown">
        <button class="btn-download">⬇ Unduh Aplikasi</button>
        <div class="dropdown-content">
          <a href="https://app-haji-monitoring.my.id/apk/app-arm64-v8a-release.apk">ARM64-v8a (Perangkat 64-bit terbaru)</a>
          <a href="https://app-haji-monitoring.my.id/apk/app-armeabi-v7a-release.apk">ARMeabi-v7a (Perangkat 32-bit lama)</a>
          <a href="https://app-haji-monitoring.my.id/apk/app-x86_64-release.apk">x86_64 (Emulator / Desktop)</a>
        </div>
      </div>
      <div class="store-badges">
        <a href="#" class="store-badge">
          <span class="bi">▶</span>
          <div class="bt"><small>DAPATKAN DI</small><strong>Google Play</strong></div>
        </a>
        <a href="#" class="store-badge">
          <span class="bi">🍎</span>
          <div class="bt"><small>UNDUH DI</small><strong>App Store</strong></div>
        </a>
      </div>
    </div>
    <div class="stats-strip">
      <div class="stat-item"><span class="stat-val">500K+</span><div class="stat-lbl">Pengguna</div></div>
      <div class="stat-item"><span class="stat-val">98%</span><div class="stat-lbl">Kepuasan</div></div>
      <div class="stat-item"><span class="stat-val">24/7</span><div class="stat-lbl">Dukungan</div></div>
    </div>
  </div>

  <!-- Phone Mockup -->
  <div class="hero-phone">
    <div class="phone-wrap">
      <div class="phone-glow-ring"></div>
      <div class="phone-glow-ring"></div>
      <div class="phone-glow-ring"></div>
      <div class="phone-frame">
        <div class="phone-notch"></div>
        <div class="phone-screen">
          <div class="phone-header">
            <span>Peta Haji</span>
            <span style="font-size:8px;color:var(--text-muted)">9:41</span>
          </div>
          <div class="phone-tabs">
            <div class="phone-tab active">Tur Haji</div>
            <div class="phone-tab">Kesehatan</div>
            <div class="phone-tab">Notifikasi</div>
          </div>
          <div class="phone-map">
            <div class="map-grid"></div>
            <div class="kaaba-dot"></div>
            <div class="pilgrim-dots">
              <span style="top:28%;left:54%"></span>
              <span style="top:58%;left:37%"></span>
              <span style="top:48%;left:64%"></span>
              <span style="top:33%;left:28%"></span>
            </div>
          </div>
          <div class="health-panel">
            <h4>Statistik Kesehatan</h4>
            <div class="health-stats">
              <div class="health-stat heart-stat"><div class="val">94</div><div class="lbl">Jantung</div></div>
              <div class="health-stat"><div class="val" style="color:#60c8a0">98</div><div class="lbl">SpO2</div></div>
              <div class="health-stat"><div class="val" style="color:#f0d080">36.7°</div><div class="lbl">Suhu</div></div>
              <div class="health-stat"><div class="val" style="color:#a8b4f0">50</div><div class="lbl">Langkah</div></div>
            </div>
          </div>
          <div style="font-size:8px;color:var(--gold);font-family:'Cinzel',serif;margin-bottom:4px">Notifikasi</div>
          <div class="notif-item"><div class="notif-dot"></div>Waktu shalat — Dzuhur segera tiba</div>
          <div class="notif-item"><div class="notif-dot red"></div>Kepadatan tinggi di Jamarat</div>
        </div>
      </div>
    </div>
  </div>
</section>

<!-- ═══ DIVIDER ═══ -->
<div class="divider reveal"><div class="divider-line"></div><div class="divider-ornament">✦</div><div class="divider-line"></div></div>

<!-- ═══ FEATURES ═══ -->
<section class="features">
  <h2 class="section-title reveal">Fitur Unggulan</h2>
  <div class="features-grid">

    <div class="feature-card reveal">
      <div class="feature-icons">
        <div class="feature-icon">❤️</div>
        <div class="feature-icon">⌚</div>
        <div class="feature-icon">🧕</div>
      </div>
      <h3 class="feature-title">Pemantauan Kesehatan &amp; Vital</h3>
      <p class="feature-desc">Pantau detak jantung, kadar oksigen, kelelahan. Ringkasan kesehatan &amp; analisis gerakan secara real-time.</p>
      <div class="mini-card">
        <div class="sparkline">
          <svg viewBox="0 0 160 50" preserveAspectRatio="none">
            <defs>
              <linearGradient id="cg" x1="0" x2="0" y1="0" y2="1">
                <stop offset="0%" stop-color="#ff6b8a" stop-opacity=".5"/>
                <stop offset="100%" stop-color="#ff6b8a" stop-opacity="0"/>
              </linearGradient>
            </defs>
            <path d="M0,35 C20,30 30,15 50,20 C70,25 80,10 100,18 C120,26 130,8 160,12" fill="none" stroke="#ff6b8a" stroke-width="2">
              <animate attributeName="stroke-dashoffset" from="300" to="0" dur="2s" fill="freeze"/>
            </path>
            <path d="M0,35 C20,30 30,15 50,20 C70,25 80,10 100,18 C120,26 130,8 160,12 L160,50 L0,50Z" fill="url(#cg)"/>
            <path d="M0,42 C30,40 60,38 90,36 C120,34 140,32 160,30" fill="none" stroke="#60c8a0" stroke-width="1.5" stroke-dasharray="3,2" opacity=".7"/>
          </svg>
        </div>
        <div style="position:absolute;bottom:6px;right:10px;font-size:8px;color:var(--gold-light);background:rgba(0,0,0,.4);padding:2px 7px;border-radius:4px">❤️ 94 bpm</div>
      </div>
    </div>

    <div class="feature-card reveal" style="animation-delay:.12s">
      <div class="feature-icons">
        <div class="feature-icon">🤖</div>
        <div class="feature-icon">🕌</div>
        <div class="feature-icon">🕋</div>
      </div>
      <h3 class="feature-title">Penilaian &amp; Panduan AI</h3>
      <p class="feature-desc">Saran real-time, bantuan ritual haji, penilaian risiko, dan wawasan personal berbasis kecerdasan buatan.</p>
      <div class="mini-card">
        <div class="chat-bubble incoming">Berapa jauh Muzdalifah? 🕌</div>
        <div class="chat-bubble outgoing">~2,4km, jalan 34 menit ✓</div>
        <svg style="position:absolute;bottom:8px;left:50%;transform:translateX(-50%)" width="50" height="11" viewBox="0 0 50 11">
          <circle cx="8" cy="5.5" r="2.8" fill="rgba(201,168,76,.4)"><animate attributeName="r" values="2.8;4.5;2.8" dur="1s" repeatCount="indefinite"/></circle>
          <circle cx="25" cy="5.5" r="2.8" fill="rgba(201,168,76,.4)"><animate attributeName="r" values="2.8;4.5;2.8" dur="1s" begin=".3s" repeatCount="indefinite"/></circle>
          <circle cx="42" cy="5.5" r="2.8" fill="rgba(201,168,76,.4)"><animate attributeName="r" values="2.8;4.5;2.8" dur="1s" begin=".6s" repeatCount="indefinite"/></circle>
        </svg>
      </div>
    </div>

    <div class="feature-card reveal" style="animation-delay:.24s">
      <div class="feature-icons">
        <div class="feature-icon">🔔</div>
        <div class="feature-icon">⚠️</div>
        <div class="feature-icon">📢</div>
      </div>
      <h3 class="feature-title">Notifikasi Real-Time</h3>
      <p class="feature-desc">Peringatan keselamatan, status kerumunan, waktu shalat, pembaruan penting &amp; peringatan darurat.</p>
      <div class="mini-card" style="flex-direction:column;align-items:stretch;justify-content:center;padding:6px 0">
        <div class="notif-ci">🔔 Shalat Subuh 15 menit lagi</div>
        <div class="notif-ci">⚠️ Kerumunan padat di Gerbang 5</div>
        <div class="notif-ci" style="border-left-color:#60c8a0">✅ Jalur Tawaf aman dilalui</div>
      </div>
    </div>

  </div>
</section>

<!-- ═══ HOW IT WORKS ═══ -->
<div class="divider reveal"><div class="divider-line"></div><div class="divider-ornament">❧</div><div class="divider-line"></div></div>

<section class="how-section">
  <h2 class="section-title reveal">Cara Penggunaan</h2>
  <div class="steps-grid">
    <div class="step-card reveal">
      <div class="step-num">1</div>
      <div class="step-icon">📲</div>
      <div class="step-title">Unduh Aplikasi</div>
      <p class="step-desc">Unduh Smart Hajj Monitor dari Google Play atau App Store secara gratis dalam hitungan detik.</p>
    </div>
    <div class="step-card reveal" style="animation-delay:.1s">
      <div class="step-num">2</div>
      <div class="step-icon">🔗</div>
      <div class="step-title">Hubungkan Perangkat</div>
      <p class="step-desc">Sambungkan smartwatch atau perangkat kesehatan Anda untuk pemantauan vital secara otomatis.</p>
    </div>
    <div class="step-card reveal" style="animation-delay:.2s">
      <div class="step-num">3</div>
      <div class="step-icon">🕋</div>
      <div class="step-title">Mulai Perjalanan</div>
      <p class="step-desc">Nikmati ibadah haji dengan tenang. AI kami memandu setiap langkah perjalanan suci Anda.</p>
    </div>
  </div>
</section>

<!-- ═══ DOWNLOAD BANNER ═══ -->
<div class="divider reveal"><div class="divider-line"></div><div class="divider-ornament">✦</div><div class="divider-line"></div></div>

<section class="download-banner reveal">
  <h2>Siap Memulai Perjalanan Haji?</h2>
  <p>Bergabung bersama 500.000+ jamaah yang telah mempercayai Smart Hajj Monitor</p>
  <div class="download-btns">
    <div class="dropdown">
      <button class="btn-download">⬇ Unduh Gratis Sekarang</button>
      <div class="dropdown-content">
        <a href="https://app-haji-monitoring.my.id/apk/app-arm64-v8a-release.apk">ARM64-v8a (Perangkat 64-bit terbaru)</a>
        <a href="https://app-haji-monitoring.my.id/apk/app-armeabi-v7a-release.apk">ARMeabi-v7a (Perangkat 32-bit lama)</a>
        <a href="https://app-haji-monitoring.my.id/apk/app-x86_64-release.apk">x86_64 (Emulator / Desktop)</a>
      </div>
    </div>
    <a href="#" class="store-badge" style="background:rgba(0,0,0,.5)">
      <span class="bi">▶</span>
      <div class="bt"><small>DAPATKAN DI</small><strong>Google Play</strong></div>
    </a>
    <a href="#" class="store-badge" style="background:rgba(0,0,0,.5)">
      <span class="bi">🍎</span>
      <div class="bt"><small>UNDUH DI</small><strong>App Store</strong></div>
    </a>
  </div>
</section>

<!-- ═══ FOOTER ═══ -->
<div class="divider reveal"><div class="divider-line"></div><div class="divider-ornament">❧</div><div class="divider-line"></div></div>

<footer>
  <div class="footer-grid">
    <div class="footer-col reveal">
      <h3>Tautan Cepat</h3>
      <ul>
        <li><a href="#">Tentang</a></li>
        <li><a href="#">Tentang Kami</a></li>
        <li><a href="#">Kesehatan</a></li>
        <li><a href="#">FAQ</a></li>
        <li><a href="#">Kontak</a></li>
      </ul>
    </div>
    <div class="footer-col reveal" style="animation-delay:.08s">
      <h3>Info Hukum</h3>
      <ul>
        <li><a href="#">Info Hukum</a></li>
        <li><a href="#">Kebijakan Privasi</a></li>
        <li><a href="#">Syarat &amp; Ketentuan</a></li>
      </ul>
    </div>
    <div class="footer-col reveal" style="animation-delay:.16s;grid-column:1/-1;">
      <h3>Media Sosial</h3>
      <div class="social-icons">
        <a href="#" class="social-icon">𝑓</a>
        <a href="#" class="social-icon">𝕏</a>
        <a href="#" class="social-icon">📷</a>
      </div>
    </div>
  </div>
  <div class="footer-bottom">www.smarthajj.com &nbsp;·&nbsp; © 2025 Smart Hajj Monitor</div>
</footer>

<script>
/* ── Stars canvas ── */
const canvas=document.getElementById('stars-canvas'),ctx=canvas.getContext('2d');
let stars=[];
function resize(){canvas.width=innerWidth;canvas.height=innerHeight;}
function init(){stars=[];for(let i=0;i<180;i++)stars.push({x:Math.random()*canvas.width,y:Math.random()*canvas.height,r:Math.random()*1.5+.3,sp:Math.random()*.4+.1,ph:Math.random()*Math.PI*2});}
function draw(t){
  ctx.clearRect(0,0,canvas.width,canvas.height);
  stars.forEach(s=>{
    const a=(Math.sin(t*s.sp+s.ph)+1)/2*.7+.1;
    ctx.beginPath();ctx.arc(s.x,s.y,s.r,0,Math.PI*2);
    ctx.fillStyle=`rgba(240,208,128,${a})`;ctx.fill();
  });
}
window.addEventListener('resize',()=>{resize();init();});
resize();init();
(function loop(t){draw(t/1000);requestAnimationFrame(loop);})(0);

/* ── Scroll reveal ── */
const revEls=document.querySelectorAll('.reveal');
const io=new IntersectionObserver(entries=>{
  entries.forEach(e=>{if(e.isIntersecting){e.target.classList.add('visible');io.unobserve(e.target);}});
},{threshold:.12});
revEls.forEach(el=>io.observe(el));

/* ── Hamburger ── */
const ham=document.getElementById('hamburger');
const menu=document.getElementById('mobileMenu');
ham.addEventListener('click',()=>{
  ham.classList.toggle('open');
  menu.classList.toggle('open');
});
document.querySelectorAll('.mobile-menu a').forEach(a=>a.addEventListener('click',()=>{
  ham.classList.remove('open');menu.classList.remove('open');
}));

/* ── Phone tabs ── */
document.querySelectorAll('.phone-tab').forEach(t=>{
  t.addEventListener('click',()=>{
    document.querySelectorAll('.phone-tab').forEach(x=>x.classList.remove('active'));
    t.classList.add('active');
  });
});

/* ── Pilgrim dot drift ── */
document.querySelectorAll('.pilgrim-dots span').forEach((d,i)=>{
  let a=Math.random()*Math.PI*2;
  setInterval(()=>{a+=.03;d.style.transform=`translate(${Math.sin(a+i)*5}px,${Math.cos(a+i)*4}px)`;},50);
});

/* ── Navbar scroll shadow ── */
window.addEventListener('scroll',()=>{
  document.getElementById('navbar').style.boxShadow=
    scrollY>10?'0 4px 30px rgba(0,0,0,.5)':'none';
});

/* ── Footer social col fix on small ── */
function fixFooter(){
  const col=document.querySelector('.footer-col:last-child');
  if(col){col.style.gridColumn=innerWidth<600?'1/-1':'';}
}
fixFooter();window.addEventListener('resize',fixFooter);

/* ── Dropdown mobile toggle ── */
document.querySelectorAll('.dropdown').forEach(d => {
  const btn = d.querySelector('.btn-download');
  if(btn) {
    btn.addEventListener('click', (e) => {
      e.preventDefault();
      e.stopPropagation();
      document.querySelectorAll('.dropdown').forEach(other => {
        if(other !== d) other.classList.remove('active');
      });
      d.classList.toggle('active');
    });
  }
});
document.addEventListener('click', () => {
  document.querySelectorAll('.dropdown').forEach(d => d.classList.remove('active'));
});
</script>
</body>
</html>
"""
    return HTMLResponse(content=html_content)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app:app", host="0.0.0.0", port=8000, reload=True)
