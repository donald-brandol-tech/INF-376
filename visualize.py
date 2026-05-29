#!/usr/bin/env python3
"""
Snort IDS Dashboard - Version Stable
"""
import http.server
import socketserver
import json
import os
from datetime import datetime
from collections import defaultdict

PORT = 8082
ALERT_FILE = '/var/log/snort/snort.alert.fast'

HTML = """<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <title>🌐️ Snort IDS Dashboard</title>
    <meta http-equiv="refresh" content="3">
    <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>
    <style>
        *{margin:0;padding:0;box-sizing:border-box}
        body{background:#0a0a0f;color:#e0e0e0;font-family:Segoe UI,sans-serif;padding:20px}
        .header{background:linear-gradient(135deg,#1a1a2e,#16213e);border:2px solid #00ff00;border-radius:15px;padding:25px;text-align:center;margin-bottom:20px}
        .header h1{color:#00ff00;font-size:2.5em}
        .live-dot{display:inline-block;width:12px;height:12px;background:#00ff00;border-radius:50%;animation:blink 1s infinite;margin-right:10px}
        @keyframes blink{0%,100%{opacity:1}50%{opacity:0.3}}
        .stats{display:grid;grid-template-columns:repeat(4,1fr);gap:15px;margin-bottom:20px}
        .stat-card{background:#1a1a2e;border:1px solid #333;border-radius:12px;padding:20px;text-align:center}
        .stat-val{font-size:3em;font-weight:bold}
        .stat-card.total .stat-val{color:#ff00ff}
        .stat-card.tcp .stat-val{color:#ff4444}
        .stat-card.udp .stat-val{color:#4488ff}
        .stat-card.icmp .stat-val{color:#ffaa00}
        .stat-label{color:#888;text-transform:uppercase;margin-top:5px;letter-spacing:2px;font-size:.9em}
        .charts{display:grid;grid-template-columns:1fr 1fr;gap:15px;margin-bottom:20px}
        .chart-box{background:#1a1a2e;border:1px solid #333;border-radius:12px;padding:20px}
        .chart-box h3{color:#aaa;text-align:center;margin-bottom:15px;border-bottom:1px solid #333;padding-bottom:10px}
        .chart-box canvas{max-height:280px}
        .alerts-box{background:#1a1a2e;border:1px solid #333;border-radius:12px;padding:20px}
        .alerts-box h3{color:#aaa;border-bottom:1px solid #333;padding-bottom:10px;margin-bottom:15px}
        .alert-row{display:grid;grid-template-columns:100px 60px 1fr 1fr;gap:10px;padding:8px;border-bottom:1px solid #222;font-family:monospace;font-size:.8em;align-items:center}
        .alert-row.tcp{border-left:3px solid #ff4444}
        .alert-row.udp{border-left:3px solid #4488ff}
        .alert-row.icmp{border-left:3px solid #ffaa00}
        .badge{padding:2px 8px;border-radius:12px;font-size:.7em;font-weight:bold;text-align:center}
        .badge.tcp{background:rgba(255,68,68,.2);color:#ff4444}
        .badge.udp{background:rgba(68,136,255,.2);color:#4488ff}
        .badge.icmp{background:rgba(255,170,0,.2);color:#ffaa00}
        .no-data{text-align:center;padding:40px;color:#555;font-size:1.2em}
        .footer{text-align:center;color:#555;margin-top:20px;font-size:.8em}
    </style>
</head>
<body>
    <div class="header">
        <h1><span class="live-dot"></span>Snort IDS Dashboard</h1>
        <p style="color:#aaa">Monitoring Temps Réel | PORT_PLACEHOLDER</p>
    </div>
    
    <div class="stats">
        <div class="stat-card total"><div class="stat-val" id="vTotal">0</div><div class="stat-label">Total</div></div>
        <div class="stat-card tcp"><div class="stat-val" id="vTcp">0</div><div class="stat-label">TCP</div></div>
        <div class="stat-card udp"><div class="stat-val" id="vUdp">0</div><div class="stat-label">UDP</div></div>
        <div class="stat-card icmp"><div class="stat-val" id="vIcmp">0</div><div class="stat-label">ICMP</div></div>
    </div>
    
    <div class="charts">
        <div class="chart-box"><h3>📈 Courbe d'alertes</h3><canvas id="chartLine"></canvas></div>
        <div class="chart-box"><h3>🥧 Camembert</h3><canvas id="chartPie"></canvas></div>
    </div>
    <div class="charts">
        <div class="chart-box"><h3>📊 Histogramme</h3><canvas id="chartBar"></canvas></div>
        <div class="chart-box"><h3>📡 Radar</h3><canvas id="chartRadar"></canvas></div>
    </div>
    
    <div class="alerts-box">
        <h3>📋 Dernières Alertes</h3>
        <div id="alertsList"><div class="no-data">Chargement...</div></div>
    </div>
    <div class="footer">Snort IDS Dashboard | Refresh: 2s | TIME_PLACEHOLDER</div>
    
    <script>
        const ctx1=document.getElementById('chartLine').getContext('2d')
        const ctx2=document.getElementById('chartPie').getContext('2d')
        const ctx3=document.getElementById('chartBar').getContext('2d')
        const ctx4=document.getElementById('chartRadar').getContext('2d')
        
        let history=[]
        const MAX=40
        
        const chartLine=new Chart(ctx1,{type:'line',data:{labels:[],datasets:[{label:'Alertes/min',data:[],borderColor:'#667eea',backgroundColor:'rgba(102,126,234,.2)',tension:.4,fill:true}]},options:{responsive:!0,maintainAspectRatio:!1,plugins:{legend:{labels:{color:'#aaa'}}},scales:{y:{beginAtZero:!0,ticks:{color:'#888'},grid:{color:'#222'}},x:{ticks:{color:'#888'},grid:{display:!1}}}}})
        
        const chartPie=new Chart(ctx2,{type:'doughnut',data:{labels:['TCP','UDP','ICMP'],datasets:[{data:[0,0,0],backgroundColor:['#ff4444','#4488ff','#ffaa00'],borderColor:'#1a1a2e',borderWidth:3}]},options:{responsive:!0,maintainAspectRatio:!1,plugins:{legend:{labels:{color:'#aaa'}}}}})
        
        const chartBar=new Chart(ctx3,{type:'bar',data:{labels:['TCP','UDP','ICMP'],datasets:[{data:[0,0,0],backgroundColor:['rgba(255,68,68,.7)','rgba(68,136,255,.7)','rgba(255,170,0,.7)'],borderColor:['#ff4444','#4488ff','#ffaa00'],borderWidth:2,borderRadius:5}]},options:{responsive:!0,maintainAspectRatio:!1,plugins:{legend:{display:!1}},scales:{y:{beginAtZero:!0,ticks:{color:'#888'},grid:{color:'#222'}},x:{ticks:{color:'#888'},grid:{display:!1}}}}})
        
        const chartRadar=new Chart(ctx4,{type:'radar',data:{labels:['TCP','UDP','ICMP'],datasets:[{data:[0,0,0],backgroundColor:'rgba(102,126,234,.2)',borderColor:'#667eea',borderWidth:2}]},options:{responsive:!0,maintainAspectRatio:!1,plugins:{legend:{display:!1}},scales:{r:{beginAtZero:!0,ticks:{color:'#888'},grid:{color:'#333'},pointLabels:{color:'#aaa'}}}}})
        
        async function fetchData(){
            try{
                const r=await fetch('/api/alerts')
                const d=await r.json()
                const s=d.stats
                
                document.getElementById('vTotal').textContent=s.total
                document.getElementById('vTcp').textContent=s.tcp
                document.getElementById('vUdp').textContent=s.udp
                document.getElementById('vIcmp').textContent=s.icmp
                
                const now=new Date().toLocaleTimeString('fr-FR',{hour:'2-digit',minute:'2-digit',second:'2-digit'})
                history.push({time:now,total:s.total})
                if(history.length>MAX) history.shift()
                
                chartLine.data.labels=history.map(d=>d.time)
                chartLine.data.datasets[0].data=history.map(d=>d.total)
                chartLine.update('none')
                
                chartPie.data.datasets[0].data=[s.tcp,s.udp,s.icmp]
                chartPie.update('none')
                
                chartBar.data.datasets[0].data=[s.tcp,s.udp,s.icmp]
                chartBar.update('none')
                
                chartRadar.data.datasets[0].data=[s.tcp,s.udp,s.icmp]
                chartRadar.update('none')
                
                let html=''
                d.alerts.slice(0,20).forEach(a=>{
                    html+=`<div class="alert-row ${a.protocol}"><span style="color:#888">${a.time.split('-')[1]||a.time}</span><span class="badge ${a.protocol}">${a.protocol.toUpperCase()}</span><span>${a.message}</span><span style="color:#999">${a.src} → ${a.dst}</span></div>`
                })
                document.getElementById('alertsList').innerHTML=html||'<div class="no-data">Aucune alerte</div>'
            }catch(e){console.error(e)}
        }
        
        fetchData()
        setInterval(fetchData,3000)
    </script>
</body>
</html>"""

class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/':
            self.send_response(200)
            self.send_header('Content-type', 'text/html; charset=utf-8')
            self.end_headers()
            h = HTML.replace('PORT_PLACEHOLDER', f'Port {PORT}').replace('TIME_PLACEHOLDER', datetime.now().strftime('%H:%M:%S'))
            self.wfile.write(h.encode())
        elif self.path == '/api/alerts':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            data = self.get_data()
            self.wfile.write(json.dumps(data).encode())
    
    def get_data(self):
        alerts = []
        stats = {'total': 0, 'tcp': 0, 'udp': 0, 'icmp': 0}
        if os.path.exists(ALERT_FILE):
            with open(ALERT_FILE, 'r') as f:
                for line in f.readlines()[-500:]:
                    if line.strip():
                        a = self.parse(line)
                        if a:
                            alerts.append(a)
                            stats['total'] += 1
                            if a['protocol'] in stats:
                                stats[a['protocol']] += 1
        print(f"[{datetime.now():%H:%M:%S}] TOT:{stats['total']} TCP:{stats['tcp']} UDP:{stats['udp']} ICMP:{stats['icmp']}")
        return {'stats': stats, 'alerts': list(reversed(alerts))[-50:]}
    
    def parse(self, line):
        try:
            proto = 'ip'
            if 'TCP' in line: proto = 'tcp'
            elif 'UDP' in line: proto = 'udp'
            elif 'ICMP' in line: proto = 'icmp'
            msg = 'Alerte'
            if '[**]' in line:
                s = line.find('[**]')+4
                e = line.find('[**]', s)
                if e > s: msg = line[s:e].split(':')[-1].strip()
            src = dst = '--'
            if '->' in line:
                a = line.find('->')
                for p in line[:a].split():
                    if ':' in p: src = p; break
                for p in line[a+2:].split():
                    if ':' in p: dst = p; break
            return {'time': line.split()[0] if line.split() else '--', 'message': msg, 'protocol': proto, 'src': src, 'dst': dst}
        except:
            return None

if __name__ == '__main__':
    print("="*55)
    print("🛡️  SNORT IDS DASHBOARD")
    print("="*55)
    print(f"🌐 http://localhost:{PORT}")
    print(f"📁 {ALERT_FILE}")
    print("="*55)
    socketserver.TCPServer(("0.0.0.0", PORT), Handler).serve_forever()
