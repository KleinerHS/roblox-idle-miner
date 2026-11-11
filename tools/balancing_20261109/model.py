"""Reproduzierbarer Vorschlags-Simulator, keine Spielimplementierung.

Liest bestehende IDs aus XLSX, erzeugt neue Vorschlagszahlen und simuliert
Bestände, Käufe, Produktionsketten und echte Verkaufsereignisse.
"""
from __future__ import annotations
import argparse, bisect, copy, json, math, re, time, zipfile
from collections import defaultdict
from pathlib import Path
import xml.etree.ElementTree as ET

HERE = Path(__file__).resolve().parent
SOURCE = Path(r'C:/Users/Allmo/OneDrive/Desktop/Roblox Idel Mine game/Balancing.xlsx')
NS = {'s':'http://schemas.openxmlformats.org/spreadsheetml/2006/main'}
TARGETS = {1:0, 10:30, 25:120, 50:360, 60:510, 75:820, 90:1200, 100:1590}
MODEL_DATE = '2026-11-11'
SMELTER_SECONDS_PER_BAR = 0.04
CARGO_BY_ID = {
    'vehicle_pickup': 6000,
    'vehicle_van': 12000,
    'vehicle_boxtruck': 24000,
    'vehicle_truck': 110000,
    'vehicle_hauler': 145000,
    'vehicle_roadtrain': 180000,
}
DRILL_LEVELS = [10,12,16,18,20,23,25,28,30,33,35,38,40,43,45,48,50,53,55,58,60,63,65,68,71,75,79,83,87,90]

def target_min(level):
    keys = list(TARGETS)
    if level > 100: return TARGETS[100] + (level-100)*55
    for a,b in zip(keys, keys[1:]):
        if level <= b:
            return TARGETS[a]+(TARGETS[b]-TARGETS[a])*(level-a)/(b-a)
    return 0

def rounded(n):
    if n <= 0: return 0
    scale = 10**max(0, math.floor(math.log10(n))-1)
    return max(1, round(n/scale)*scale)

def pacing_factor(level, start, end, reduction):
    progress = min(1, max(0, level - start) / (end - start))
    return 1 - reduction * progress

def read_source():
    with zipfile.ZipFile(SOURCE) as z:
        strings=[]
        if 'xl/sharedStrings.xml' in z.namelist():
            strings=[''.join(x.itertext()) for x in ET.fromstring(z.read('xl/sharedStrings.xml')).findall('s:si',NS)]
        names=[x.get('name') for x in ET.fromstring(z.read('xl/workbook.xml')).findall('s:sheets/s:sheet',NS)]
        sheets={}
        for i,name in enumerate(names,1):
            rows=[]
            for row in ET.fromstring(z.read(f'xl/worksheets/sheet{i}.xml')).findall('s:sheetData/s:row',NS):
                cells={}
                for c in row:
                    v=c.find('s:v',NS); inline=c.find('s:is',NS)
                    s=''.join(inline.itertext()) if inline is not None else v.text if v is not None else None
                    if c.get('t')=='s' and s is not None: s=strings[int(s)]
                    elif s is not None and c.get('t') not in ('inlineStr','str'):
                        try: s=float(s); s=int(s) if s.is_integer() else s
                        except (ValueError,AttributeError): pass
                    if s is not None: cells[re.sub(r'\d','',c.get('r'))]=s
                if cells: rows.append({'row':int(row.get('r')),**cells})
            sheets[name]=rows
    return sheets

def collections(source):
    cols={}
    ore_source=[r for r in source['Erze & Barren'] if str(r.get('A','')).startswith('ore_')]
    ores=[]
    for i,r in enumerate(ore_source):
        ores.append(dict(id=r['A'],name=r['B'],tier=i+1,price=round(2*1.20**i,2),xp=round(1+0.70*i+0.012*i*i,2),source_row=r['row']))
    cols['ores']=ores
    price_at=lambda lv: ores[min(49,max(0,(lv-1)//2))]['price']
    xp_at=lambda lv: ores[min(49,max(0,(lv-1)//2))]['xp']
    picks=[]
    for i,r in enumerate(source['Spitzhacken'][1:]):
        if not str(r.get('A','')).startswith('pickaxe_'):continue
        level=1 if i==0 else 2 if i==1 else round(3+(i-2)*92/22)
        power=i+1
        speed=round(1+0.8*i/24,3)
        rate=power*speed*60
        price=0 if i==0 else rounded(price_at(level)*rate*(1.3+0.16*i))
        if i==1:price=90
        picks.append(dict(id=r['A'],name=r['B'],level=level,price=price,power=power,speed=speed,rate_min=round(rate,2),tier=i+1,prerequisite_id=picks[-1]['id'] if picks else None,source_row=r['row']))
    cols['picks']=picks
    packrows=[r for r in source['Rucksäcke'] if str(r.get('A','')).startswith('backpack_')]
    packs=[]
    for i,r in enumerate(packrows):
        level=1 if i==0 else 2 if i==1 else round(3+(i-2)*92/19)
        nextlevel=2 if i==0 else 3 if i==1 else (round(3+(i-1)*92/19) if i<21 else 101)
        maxrate=max(p['rate_min'] for p in picks if p['level']<nextlevel)
        capacity=math.ceil(maxrate*15*1.25/100)*100
        if i==0:capacity=2400
        if packs:capacity=max(capacity,math.ceil(packs[-1]['capacity']*1.15/100)*100)
        if i==1:capacity=max(capacity,3600)
        price=0 if i==0 else rounded(price_at(level)*maxrate*(0.9+0.10*i))
        if i==1:price=120
        packs.append(dict(id=r['A'],name=r['B'],tier=i+1,level=level,price=price,capacity=capacity,prerequisite_id=packs[-1]['id'] if packs else None,source_row=r['row']))
    cols['packs']=packs
    drillrows=[r for r in source['Drills'] if str(r.get('A','')).startswith('drill_')]
    drills=[]
    for i,r in enumerate(drillrows):
        level=DRILL_LEVELS[i]; rate=max(12,round(48*(1500/48)**(i/29)/12)*12)
        if drills:rate=max(rate,drills[-1]['rate_min']+12)
        price=rounded(price_at(level)*rate*(4.5+0.06*i))
        drills.append(dict(id=r['A'],name=r['B'],tier=i+1,level=level,price=price,units_cycle=rate//12,cycle_seconds=5,rate_min=rate,buffer=rate*5,prerequisite_id=drills[-1]['id'] if drills else None,source_row=r['row']))
    cols['drills']=drills
    vrows=[r for r in source['Fahrzeuge'] if str(r.get('A','')).startswith('vehicle_')]
    vehicles=[]
    for i,r in enumerate(vrows):
        level=[6,15,30,45,65,80][i]; cap=CARGO_BY_ID[r['A']]
        vehicles.append(dict(id=r['A'],name=r['B'],level=level,price=rounded(price_at(level)*[180,550,1300,2300,3500,5000][i]),capacity=cap,speed=[55,52,46,44,33,33][i],acceleration=r.get('G',1),available=r.get('H')!='nein',model_scenario_included=True,source_row=r['row']))
    cols['vehicles']=vehicles
    mine_rows=[r for r in source['Minen'] if isinstance(r.get('A'),int)]
    mines=[]
    for i,r in enumerate(mine_rows):
        level=i+1
        mines.append(dict(id=f'mine_{i+1:03}',number=i+1,ore_id=r['B'],level=level,price=0 if i<2 else rounded(price_at(level)*(20+1.4*level)),source_row=r['row']))
    cols['mines']=mines
    build_values=[('build_office','Office',1,0),('build_elevator','Elevator',1,80),('build_walls','Walls',2,100),('build_roof','Roof',3,180),('build_storage','Storage',3,250),('build_garage','Garage',6,900),('build_smelter','Smelter',10,2800)]
    cols['buildings']=[dict(id=id,name=name,level=lv,price=p,source_row=i+2) for i,(id,name,lv,p) in enumerate(build_values)]
    cols['buildings'].append(dict(id='office_premium',name='Premium Office',level=25,price=rounded(price_at(25)*1200),source_row=9,optional=True))
    cols['conveyors']=[dict(id='conveyor_mk1',name='Conveyor MK1',level=12,price=1200,throughput_min=6000,source_row=10)]
    cols['elevator']=[dict(tier=i+1,level=lv,capacity=[100,160,240,350,500,700,900,1200,1600,2200][i],price=rounded(price_at(lv)*(70+60*i)),source_row=i+2) for i,lv in enumerate([5,10,18,26,35,45,55,65,75,85])]
    bars=[]; recipes=[]
    byid={o['id']:o for o in ores}
    for r in source['Erze & Barren']:
        if not str(r.get('A','')).startswith('bar_'):continue
        oid='ore_'+r['A'][4:]
        if oid not in byid:continue
        o=byid[oid]
        bars.append(dict(id=r['A'],name=r['B'],tier=o['tier'],price=round(o['price']*2*1.4,2),xp=round(o['xp']*2*1.10,2),source_row=r['row']))
        recipes.append(dict(id='recipe_'+r['A'],input_id=oid,input_qty=2,output_id=r['A'],output_qty=1,seconds=SMELTER_SECONDS_PER_BAR,capacity_bars_min=round(60/SMELTER_SECONDS_PER_BAR)))
    cols['bars']=bars;cols['recipes']=recipes
    cols['storage']=[dict(number=i,capacity=1000,price=rounded(60*(i**1.7)),source_row=None) for i in range(1,193)]
    cols['general']={
      'start_cash':80,'worker_hire':180,'worker_wage_min':1,'worker_rate_min':25,'worker_slot_buffer':150,
      'elevator_start_capacity':60,'elevator_cycle_seconds':10,'crate_size':1000,'max_crates':192,'start_crates':0,
      'smelter_ore_per_bar':2,'smelter_seconds_per_bar':SMELTER_SECONDS_PER_BAR,'smelter_input_crates':16,'smelter_output_crates':16,
      'loading_min_units_second':100,'loading_full_seconds':4,'drill_max_level':10,'drill_level_bonus':0.04,
      'drill_upgrade_share':0.03,'drill_upgrade_growth':1.18,'offline_rate':0.30,'offline_max_hours':8,
      'prestige_money_bonus':0.05,'prestige_speed_bonus':0.0,'prestige_speed_max':0.0,'prestige_level':100,
      'late_price_growth':1,'late_price_start':40,'manual_trip_seconds':45,'vehicle_trip_seconds':70,
      'mine_buffer_reserve_minutes':5,'capacity_reserve':1.25,
    }
    # Kaufbudgets stammen aus Einkommensminuten der vorhergehenden Phase.
    # Damit bleiben neue Preise prüfbar mit der tatsächlich verstrichenen Zeit verknüpft.
    def reference_gross(lv):
        lv=max(1,lv);p=max((p for p in picks if p['level']<=lv),key=lambda p:p['level'])
        avail=[d for d in drills if d['level']<=lv]
        auto=sum(d['rate_min']*1.08 for d in avail[-2:])
        share=1 if lv<10 else .6 if lv<25 else .25 if lv<50 else .15
        ore=ores[min(49,(lv-1)//2)];processed=any(r['input_id']==ore['id'] for r in recipes) and lv>=12
        return ore['price']*(p['rate_min']*share+auto*(1.4 if processed else 1))+100
    for key in ['picks','packs','drills','vehicles','elevator','mines']:
        arr=cols[key]
        for i,d in enumerate(arr):
            lv=d['level']
            if lv<20:continue
            previous=arr[i-1]['level'] if i else 1
            phase_min=max(1,target_min(lv)-target_min(previous))
            if key=='mines':phase_min=max(1,target_min(lv+1)-target_min(lv))
            budget={'picks':.06,'packs':.04,'drills':.25,'vehicles':.06,'elevator':.03,'mines':.40}[key]
            if key=='mines' and lv>=90:budget=.70
            desired=reference_gross(max(1,lv-1))*phase_min*budget
            blend=min(1,(lv-18)/12)
            d['price']=rounded((d['price']*(1-blend)+desired*blend)*(1+.35*blend))
            d['reference_gross_min']=round(reference_gross(max(1,lv-1)),2)
            d['reference_interval_min']=round(phase_min,3)
            d['purchase_budget_share']=budget
    # Nach der Drill-QA bleiben die zuletzt geprüften Preisvorschläge unverändert.
    # Die explizite Preis-Eingabedatei verhindert stille Neupreisung durch Rundungskorrekturen.
    price_seed=HERE/'price_seed.json'
    if price_seed.exists():
        fixed=json.loads(price_seed.read_text(encoding='utf-8'))
        for key,arr in cols.items():
            if not isinstance(arr,list):continue
            for item in arr:
                stable=str(item.get('id',item.get('tier',item.get('number',''))))
                if key in fixed and stable in fixed[key]:item['price']=fixed[key][stable]
    # Geringere späte XP-Schwellen brauchen erreichbare Kaufziele im selben Abschnitt.
    for key, start, end, reduction in [('mines', 60, 90, .30), ('drills', 65, 85, .18)]:
        for item in cols[key]:
            factor = pacing_factor(item['level'], start, end, reduction)
            if factor < 1:
                item['price'] = rounded(item['price'] * factor)
    return cols

def initial_xp(cols):
    req=[]
    for lv in range(1,121):
        pp=max(p['rate_min'] for p in cols['picks'] if p['level']<=lv)
        di=max([d['rate_min'] for d in cols['drills'] if d['level']<=lv] or [0])
        manual_fraction=1 if lv<10 else .60 if lv<25 else .25 if lv<50 else .15
        xpv=cols['ores'][min(49,(lv-1)//2)]['xp']
        req.append(max(15,round((target_min(lv+1)-target_min(lv))*(pp*manual_fraction+di*1.8+25)*xpv)))
    return req

class Sim:
    def __init__(self,cols,xp,profile='active',prestige=0,retained=None,rate_factor=1.,trip_factor=1.,log=True):
        self.c=cols;self.xpreq=xp;self.profile=profile;self.prestige=prestige;self.rf=rate_factor;self.tf=trip_factor;self.logging=log
        self.materials={x['id']:x for x in cols['ores']+cols['bars']};self.recipes={x['input_id']:x for x in cols['recipes']}
        self.cash=cols['general']['start_cash'];self.xp=0.;self.level=1;self.active=0.;self.calendar=0.
        self.pick=(retained or {}).get('pick',0);self.pack=(retained or {}).get('pack',0)
        self.vehicle=-1;self.elevator=-1;self.mine=0;self.built=0;self.crates=0;self.drill=-1;self.conveyor=False
        self.owned_drills=[];self.placed=[];self.workers=0;self.workermine=0
        self.backpack=defaultdict(float);self.storage=defaultdict(float);self.minebuffer=defaultdict(float);self.elevbuffer=defaultdict(float)
        self.smelterinput=defaultdict(float);self.smelteroutput=defaultdict(float);self.cargo=defaultdict(float)
        self.mode='mine';self.remaining=0.;self.nextsale=1.;self.lastsale=0.;self.last_session=0.;self.elevclock=0.;self.workers_paid=True;self.payclock=0.
        self.cash_sales=0.;self.cash_offline=0.;self.cash_spent=0.;self.wages=0.;self.produced=0.;self.manual_produced=0.;self.sold_units=0.;self.sold_xp=0.;self.smelted=0.;self.stalled_minutes=0.
        self.maxflow=0.;self.min_free_cash=1e100;self.events=[];self.leveltimes={1:0.};self.snapshots=[];self.milestones={};self.lastlevel=1
        self.drill_usage=defaultdict(lambda:{'placed_minutes':0.,'produced_units':0.})
        self.first_state=None;self.max_materials=0.;self.loaded=0.;self.status='running';self.rate_cache=None
        self.dt=1/6

    def event(self,kind,**kw):
        if self.logging:self.events.append(dict(kind=kind,active_min=round(self.active,3),calendar_min=round(self.calendar,3),level=self.level,cash=round(self.cash,2),cash_sales_to_date=round(self.cash_sales,2),cash_offline_to_date=round(self.cash_offline,2),cash_spent_to_date=round(self.cash_spent,2),wages_to_date=round(self.wages,2),sold_xp_to_date=round(self.sold_xp,2),**kw))

    def spend(self,price,id,kind):
        if self.cash+1e-7<price:return False
        self.cash-=price;self.cash_spent+=price;self.event('purchase',item_id=id,category=kind,price=price)
        if 'first_upgrade' not in self.milestones and kind in ('pick','pack'):self.milestones['first_upgrade']=round(self.active,3)
        if kind=='vehicle':self.milestones.setdefault('first_vehicle',round(self.active,3))
        if id=='build_smelter':self.milestones.setdefault('smelter',round(self.active,3))
        if kind=='drill' and id==self.c['drills'][-1]['id']:self.milestones.setdefault('last_drill',round(self.active,3))
        return True

    def buy(self):
        c=self.c;lv=self.level
        if self.pick==0 and lv>=2:
            p=c['picks'][1]
            if self.spend(p['price'],p['id'],'pick'):self.pick=1
        # Unverzichtbare Baufolge; bei Garage/Ofen vor Ausrüstung priorisieren.
        while self.built<7:
            b=c['buildings'][self.built]
            if self.built==6 and self.drill<0:break
            if lv<b['level'] or not self.spend(b['price'],b['id'],'building'):break
            self.built+=1
        # Jede Mine wird gekauft; auch das Geld billiger Vorgänger wird tatsächlich ausgegeben.
        while self.mine<99:
            m=c['mines'][self.mine+1]
            if lv<m['level'] or not self.spend(m['price'],m['id'],'mine'):break
            self.mine+=1
        # Aktuell freigeschalteter Drill kommt vor optionalen Ausrüstungsnachkäufen.
        while self.drill+1<len(c['drills']):
            d=c['drills'][self.drill+1]
            if d['level']>lv or self.built<5 or self.vehicle<0 or not self.spend(d['price'],d['id'],'drill'):break
            self.drill+=1;self.owned_drills.append({'tier':self.drill,'level':1})
            self.milestones.setdefault('first_drill',round(self.active,3))
        # Zwei frühe Worker, getrennt vom späteren Zwei-/Vier-Drill-Betrieb.
        if self.built>=5:
            if self.crates==0 and self.cash>=c['storage'][0]['price']:
                self.spend(c['storage'][0]['price'],'crate_1','crate');self.crates=1
            while self.workers<2 and self.cash>=c['general']['worker_hire']+60:
                self.spend(c['general']['worker_hire'],f'worker_{self.workers+1}','worker');self.workers+=1
                self.milestones.setdefault('first_worker',round(self.active,3))
            self.workermine=min(self.mine,1)
        # Einmalige Vorgängerkäufe; permanent behaltene Ausrüstung überspringt keinen Besitz.
        for key,attr in [('picks','pick'),('packs','pack')]:
            idx=getattr(self,attr)
            while idx+1<len(c[key]):
                item=c[key][idx+1]
                if item['level']>lv or not self.spend(item['price'],item['id'],attr):break
                idx+=1
            setattr(self,attr,idx)
        # Drills haben vor optionalem Ofen/Lagerausbau Vorrang, sobald ihr Level erreicht ist.
        while self.drill+1<len(c['drills']):
            d=c['drills'][self.drill+1]
            if d['level']>lv or self.built<5 or self.vehicle<0 or not self.spend(d['price'],d['id'],'drill'):break
            self.drill+=1;self.owned_drills.append({'tier':self.drill,'level':1})
            self.milestones.setdefault('first_drill',round(self.active,3))
        # Lager wächst nicht exponentiell. Mindestens zwei Kisten für gemischte frühe Erze.
        estimate=self.estimated_rates()
        units=sum(estimate.values())
        desired=min(192,max(2,math.ceil(units*20/1000)+len(estimate)+2))
        if self.built>=5:
            while self.crates<desired and self.cash>=c['storage'][self.crates]['price']+30:
                self.spend(c['storage'][self.crates]['price'],f'crate_{self.crates+1}','crate');self.crates+=1
        if self.built>=6:
            idx=self.vehicle
            while idx+1<len(c['vehicles']):
                v=c['vehicles'][idx+1]
                if v['level']>lv or not self.spend(v['price'],v['id'],'vehicle'):break
                idx+=1
            self.vehicle=idx
        idx=self.elevator
        while idx+1<len(c['elevator']):
            e=c['elevator'][idx+1]
            if e['level']>lv or not self.spend(e['price'],f'elevator_{e["tier"]}','elevator'):break
            idx+=1
        self.elevator=idx
        if self.built>=7 and not self.conveyor and lv>=12:
            if self.spend(c['conveyors'][0]['price']*2,'conveyor_mk1_x2','conveyor'):self.conveyor=True
        # Alle gekauften Drilltypen bleiben im Inventar; nur neueste 2 bzw.4 sind platziert.
        while self.drill+1<len(c['drills']):
            d=c['drills'][self.drill+1]
            if d['level']>lv or self.built<5 or self.vehicle<0 or not self.spend(d['price'],d['id'],'drill'):break
            self.drill+=1;self.owned_drills.append({'tier':self.drill,'level':1})
            self.milestones.setdefault('first_drill',round(self.active,3))
        count=4 if self.profile=='automation' else 2
        self.placed=list(range(max(0,len(self.owned_drills)-count),len(self.owned_drills)))
        # Frei demontieren/versetzen ist vorhanden; keine alten Maschinen produzieren im Inventar.
        if self.placed:
            self.workermine=0
        # Drill-Level nur kaufen, wenn nächster Typ nicht unmittelbar freigeschaltet ist.
        if self.drill>=0:
            nxt=c['drills'][self.drill+1]['level'] if self.drill<29 else 1000
            for n in self.placed:
                rec=self.owned_drills[n];d=c['drills'][rec['tier']]
                cap=10 if nxt-lv>=5 else 3 if nxt-lv>=2 else 1
                while rec['level']<cap:
                    p=rounded(d['price']*.03*1.18**(rec['level']-1))
                    if self.cash<max(p*2,100) or not self.spend(p,f'{d["id"]}_level_{rec["level"]+1}','drill_upgrade'):break
                    rec['level']+=1
        if self.logging and (self.first_state is None or lv!=self.lastlevel):
            self.snapshots.append(self.snapshot());self.lastlevel=lv
            if self.first_state is None:self.first_state=True

    def manual_fraction(self):
        if self.level<10:return 1.
        if self.profile=='automation':return .10
        return .6 if self.level<25 else .25 if self.level<50 else .15

    def estimated_rates(self):
        rates=defaultdict(float)
        if self.workers and self.workers_paid:
            rates[self.c['mines'][self.workermine]['ore_id']]+=self.workers*self.c['general']['worker_rate_min']*self.rf
        for j,n in enumerate(self.placed):
            rec=self.owned_drills[n];d=self.c['drills'][rec['tier']]
            mine=max(0,self.mine-j//2)
            rates[self.c['mines'][mine]['ore_id']]+=d['rate_min']*(1+(rec['level']-1)*.04)*self.rf
        return rates

    def elevator_capacity(self):
        return self.c['general']['elevator_start_capacity'] if self.elevator<0 else self.c['elevator'][self.elevator]['capacity']

    def storage_free(self,id):
        # Kisten sind sortenrein. Belegte Restkisten und volle Kisten anderer Sorten zählen.
        other=sum(math.ceil(max(0,x)/1000-1e-9) for key,x in self.storage.items() if key!=id and x>0)
        return max(0,(self.crates-other)*1000-self.storage[id])

    def move(self,source,target,id,limit):
        amount=min(source.get(id,0),max(0,limit))
        if amount>0:source[id]-=amount;target[id]+=amount
        return amount

    def chain(self,dt):
        if self.built<5:return
        self.payclock+=dt
        if self.payclock>=1-1e-9:
            self.payclock-=1
            wage=self.workers*self.c['general']['worker_wage_min']
            self.workers_paid=self.cash>=wage
            if self.workers_paid:self.cash-=wage;self.wages+=wage
        rates=self.estimated_rates()
        self.maxflow=max(self.maxflow,sum(rates.values()))
        for id,rate in rates.items():
            cap=max(150,rate*5)
            qty=min(rate*dt,max(0,cap-self.minebuffer[id]));self.minebuffer[id]+=qty;self.produced+=qty
            if qty<rate*dt-1e-9:self.stalled_minutes+=dt
            for j,n in enumerate(self.placed):
                record=self.owned_drills[n];d=self.c['drills'][record['tier']]
                mine=max(0,self.mine-j//2)
                if self.c['mines'][mine]['ore_id']!=id:continue
                usage=self.drill_usage[d['id']];usage['placed_minutes']+=dt
                usage['produced_units']+=qty*(d['rate_min']*(1+(record['level']-1)*.04)*self.rf)/rate
        self.elevclock+=dt*60
        if self.elevclock>=10:
            self.elevclock-=10
            remaining=self.elevator_capacity()
            for id in sorted(rates,key=lambda x:self.materials[x]['tier']):
                n=self.move(self.minebuffer,self.storage,id,min(remaining,self.storage_free(id)))
                remaining-=n
        if self.built>=7 and self.conveyor:
            belt=6000*dt*self.rf
            bars=60/self.c['general']['smelter_seconds_per_bar']*dt*self.rf
            # Ein-/Ausgangspuffer je16 sortenreine1000erKisten, Rezeptauswahl niedrigstes Tier zuerst.
            for id in sorted(self.recipes,key=lambda x:self.materials[x]['tier']):
                inp=self.smelterinput
                other=sum(math.ceil(max(0,v)/1000-1e-9) for k,v in inp.items() if k!=id and v>0)
                moved=self.move(self.storage,inp,id,min(belt,max(0,(16-other)*1000-inp[id])))
                belt-=moved
                outid=self.recipes[id]['output_id'];out=self.smelteroutput
                outother=sum(math.ceil(max(0,v)/1000-1e-9) for k,v in out.items() if k!=outid and v>0)
                amount=min(math.floor(inp[id]/2),bars,max(0,(16-outother)*1000-out[outid]))
                if amount>0:inp[id]-=amount*2;out[outid]+=amount;bars-=amount;self.smelted+=amount
            remain=6000*dt*self.rf
            for id in sorted(self.smelteroutput,key=lambda x:self.materials[x]['tier']):
                moved=self.move(self.smelteroutput,self.storage,id,min(remain,self.storage_free(id)));remain-=moved
        # Online-Lohn: nur solange Geld vorhanden; Modell pausiert Worker bei nächstem Takt.

    def manual(self,dt):
        if self.mode!='mine' or self.profile=='automation' and self.level>=10 and self.active%10<1:return
        rate=self.c['picks'][self.pick]['rate_min']*self.rf*self.manual_fraction()
        cap=self.c['packs'][self.pack]['capacity'];free=cap-sum(self.backpack.values())
        qty=min(rate*dt,max(0,free))
        id=self.c['mines'][self.mine]['ore_id'];self.backpack[id]+=qty;self.manual_produced+=qty

    def sell(self):
        # Ein Verkaufsereignis für die tatsächlich mitgenommene Ladung und Rucksackinhalt.
        qty=0.;cash=0.;xp=0.;items={}
        for store in [self.cargo,self.backpack]:
            for id,n in list(store.items()):
                if n<=1e-8:continue
                n=math.floor(n+1e-7)
                if n<1:continue
                store[id]-=n;qty+=n;cash+=n*self.materials[id]['price'];xp+=n*self.materials[id]['xp'];items[id]=items.get(id,0)+n
        cash=round(cash*(1+.05*self.prestige),2)
        self.cash+=cash;self.cash_sales+=cash;self.sold_units+=qty;self.sold_xp+=xp;self.xp+=xp
        while self.level<=100 and self.xp>=self.xpreq[self.level-1]:
            self.xp-=self.xpreq[self.level-1];self.level+=1;self.leveltimes.setdefault(self.level,self.active)
        self.milestones.setdefault('first_sale',round(self.active,3))
        self.event('sale',quantity=qty,revenue=round(cash,2),xp=round(xp,2),items=items)
        self.lastsale=self.active;self.nextsale=self.active+(3 if self.level<10 else 8 if self.level<50 else 15)

    def start_trip(self):
        if self.vehicle>=0:
            cap=self.c['vehicles'][self.vehicle]['capacity']
            for id in sorted(self.storage,key=lambda x:self.materials[x]['price'],reverse=True):
                n=self.move(self.storage,self.cargo,id,cap-sum(self.cargo.values()))
                self.loaded+=n
            trip=(self.c['general']['vehicle_trip_seconds']+4)*self.tf/60
        else:trip=self.c['general']['manual_trip_seconds']*self.tf/60
        self.mode='trip';self.remaining=trip

    def offline(self,minutes):
        if self.built<5:return
        gross=self.auto_gross()
        value=round(gross*min(minutes,480)*.30*(1+.05*self.prestige),2)
        self.cash+=value;self.cash_offline+=value
        self.event('offline_credit',absence_min=minutes,credited_min=min(minutes,480),eligible_gross_min=round(gross,2),revenue=round(value,2),xp=0,materials=0)
        self.calendar+=minutes

    def auto_gross(self):
        rates=self.estimated_rates();remaining=self.elevator_capacity()*6
        process=60/self.c['general']['smelter_seconds_per_bar']*self.c['general']['smelter_ore_per_bar']*self.rf
        gross=0.
        for id in sorted(rates,key=lambda x:self.materials[x]['tier']):
            rate=min(rates[id],remaining);remaining-=rate
            if self.conveyor and id in self.recipes:
                processed=min(rate,process);process-=processed
                gross+=processed/2*self.materials[self.recipes[id]['output_id']]['price']
                gross+=max(0,rate-processed)*self.materials[id]['price']
            else:gross+=rate*self.materials[id]['price']
        return gross

    def snapshot(self):
        rates=self.estimated_rates();auto=sum(rates.values());manual=self.c['picks'][self.pick]['rate_min']
        cap=self.c['vehicles'][self.vehicle]['capacity'] if self.vehicle>=0 else None
        # Geschätzte verkaufbare Teile/min; Verarbeitungsanteil reduziert Stückzahl.
        sellflow=sum(v*(.5 if self.conveyor and k in self.recipes else 1) for k,v in rates.items())
        manual_gross=manual*self.manual_fraction()*self.materials[self.c['mines'][self.mine]['ore_id']]['price'];automatic_gross=self.auto_gross()
        return dict(level=self.level,active_min=round(self.active,3),cash=round(self.cash,2),pick_id=self.c['picks'][self.pick]['id'],pack_id=self.c['packs'][self.pack]['id'],mine=self.mine+1,drill_mk=self.drill+1,placed_drills=len(self.placed),workers=self.workers,auto_rate_min=round(auto,2),manual_raw_rate_min=round(manual,2),manual_activity_share=self.manual_fraction(),gross_cash_per_min=round(manual_gross+automatic_gross,2),automatic_gross_cash_per_min=round(automatic_gross,2),elevator_rate_min=self.elevator_capacity()*6,crates=self.crates,storage_capacity=self.crates*1000,vehicle_capacity=cap,backpack_autonomy_min=round(self.c['packs'][self.pack]['capacity']/manual,2),vehicle_autonomy_auto_min=round(cap/sellflow,2) if cap and sellflow else None,storage_autonomy_auto_min=round(self.crates*1000/auto,2) if auto else None)

    def run(self,maxminutes=6000):
        while self.level<100 and self.active<maxminutes:
            self.buy()
            dt=self.dt;self.chain(dt);self.manual(dt)
            self.active+=dt;self.calendar+=dt
            if self.mode=='trip':
                self.remaining-=dt
                if self.remaining<=0:self.sell();self.mode='mine'
            elif self.active>=self.nextsale or sum(self.backpack.values())>=self.c['packs'][self.pack]['capacity']-.1:
                self.start_trip()
            if self.profile=='casual' and self.active-self.last_session>=30 and self.mode=='mine':
                self.offline(8*60);self.last_session=self.active
            self.min_free_cash=min(self.min_free_cash,self.cash)
        if self.level>=100:self.buy()
        self.status='reached' if self.level>=100 else 'time_limit'
        # Goldwerte und echte Cashidentität unabhängig prüfen.
        cash_identity=self.c['general']['start_cash']+self.cash_sales+self.cash_offline-self.cash_spent-self.wages-self.cash
        stores={name:{k:round(v,6) for k,v in getattr(self,name).items() if v>1e-7} for name in ['backpack','storage','minebuffer','elevbuffer','smelterinput','smelteroutput','cargo']}
        ending_equivalent=sum(v*(2 if k.startswith('bar_') else 1) for store in stores.values() for k,v in store.items())
        sold_equivalent=sum(sum(v*(2 if k.startswith('bar_') else 1) for k,v in e.get('items',{}).items()) for e in self.events if e['kind']=='sale') if self.logging else None
        material_error=(self.produced+self.manual_produced-ending_equivalent-sold_equivalent) if sold_equivalent is not None else None
        self.snapshots.append(self.snapshot())
        return dict(profile=self.profile,prestige=self.prestige,status=self.status,rate_factor=self.rf,trip_factor=self.tf,
          active_minutes=round(self.active,3),calendar_minutes=round(self.calendar,3),milestones={**self.milestones,**{f'level_{lv}':round(self.leveltimes[lv],3) if lv in self.leveltimes else None for lv in [10,25,50,60,75,90,100]}},
          summary=dict(cash_end=round(self.cash,2),cash_sales=round(self.cash_sales,2),cash_offline=round(self.cash_offline,2),cash_spent=round(self.cash_spent,2),wages=round(self.wages,2),cash_rollforward_error=round(cash_identity,7),material_rollforward_error=round(material_error,6) if material_error is not None else None,material_units_equivalent_end=round(ending_equivalent,6),material_units_equivalent_sold=round(sold_equivalent,6) if sold_equivalent is not None else None,xp_rollforward_error=round(self.sold_xp-sum(self.xpreq[:self.level-1])-self.xp,7),xp_remainder=round(self.xp,6),sold_xp=round(self.sold_xp,2),sold_units=round(self.sold_units,2),manual_units=round(self.manual_produced,6),automatic_units=round(self.produced,6),smelted_bars=round(self.smelted,2),max_auto_flow_min=round(self.maxflow,2),production_stalled_minutes=round(self.stalled_minutes,2),retained_next=dict(pick=self.pick,pack=self.pack),level_end=self.level),
          end_inventories=stores,drill_usage={id:{k:round(v,6) for k,v in values.items()} for id,values in self.drill_usage.items()},snapshots=self.snapshots,events=self.events)

def calibrate(cols,req,iterations=8):
    history=[]
    # 7 zusammenhängende XP-Abschnitte, nach echten simulierten Levelereignissen kalibriert.
    bounds=[1,10,25,50,60,75,90,100]
    for it in range(iterations):
        result=Sim(cols,req,log=False).run()
        times={1:0,**{int(k[6:]):v for k,v in result['milestones'].items() if k.startswith('level_') and v is not None}}
        history.append(dict(iteration=it+1,active_minutes=result['active_minutes'],milestones=result['milestones']))
        for a,b in zip(bounds,bounds[1:]):
            if a not in times or b not in times:continue
            observed=times[b]-times[a];desired=TARGETS[b]-TARGETS[a]
            factor=max(.45,min(1.8,desired/max(observed,.5)))**.65
            for lv in range(a,b):req[lv-1]=max(12,round(req[lv-1]*factor))
        req[0]=45
    return req,history

def main():
    parser=argparse.ArgumentParser();parser.add_argument('--iterations',type=int,default=0);parser.add_argument('--quick',action='store_true');args=parser.parse_args()
    source=read_source();cols=collections(source);req=initial_xp(cols)
    seedpath=HERE/'xp_seed.json'
    if seedpath.exists():
        seed = json.loads(seedpath.read_text(encoding='utf-8'))
        req = []
        for level, amount in enumerate(seed, 1):
            adjusted = round(amount * pacing_factor(level, 60, 90, .35))
            req.append(max(req[-1] if req else 1, adjusted))
    available_cols = {**cols, 'vehicles': [v for v in cols['vehicles'] if v['available']]}
    req,history=calibrate(available_cols,req,args.iterations)
    if not history and (HERE/'calibration_history.json').exists():history=json.loads((HERE/'calibration_history.json').read_text(encoding='utf-8'))
    sims=[]
    active=Sim(available_cols,req).run();sims.append(active)
    for profile in ['casual','automation']:
        sims.append(Sim(available_cols,req,profile=profile).run())
    retained=active['summary']['retained_next']
    for n in range(1,4):
        sim=Sim(available_cols,req,prestige=n,retained=retained).run();sims.append(sim);retained=sim['summary']['retained_next']
    for rate,trip in [(0.8,1),(1.2,1),(1,.8),(1,1.2)]:
        sims.append(Sim(available_cols,req,rate_factor=rate,trip_factor=trip,log=False).run())
    for sim in sims:
        sim['vehicle_scope'] = 'available'
    for profile in ['active', 'automation']:
        future = Sim(cols, req, profile=profile).run()
        future['vehicle_scope'] = 'all'
        sims.append(future)
    cumulative=0;xp=[]
    for lv,amount in enumerate(req,1):
        xp.append(dict(level=lv,xp_next=amount,xp_total=cumulative,target_active_min=target_min(lv)));cumulative+=amount
    extreme_rate=cols['drills'][-1]['rate_min']*1.36*200
    extreme_elevator=cols['elevator'][-1]['capacity']*6
    drill_buys=[e for e in active['events'] if e.get('category')=='drill']
    drill_gaps=[dict(previous_id=a['item_id'],next_id=b['item_id'],use_before_next_min=round(b['active_min']-a['active_min'],3),sales_before_next=sum(a['active_min']<e['active_min']<=b['active_min'] for e in active['events'] if e['kind']=='sale')) for a,b in zip(drill_buys,drill_buys[1:])]
    cargo_max = cols['vehicles'][-1]['capacity']
    out=dict(status='TESTING_REQUIRED',source=str(SOURCE),generated_date=MODEL_DATE,collections=cols,xp_curve=xp,calibration_history=history,simulations=sims,
      baseline_drill_purchase_gaps=drill_gaps,
      stress_test=dict(scenario='200 Drill-Slots mit MK30 Level10 in100Minen',mining_units_min=extreme_rate,elevator_units_min=extreme_elevator,elevator_share=extreme_elevator/extreme_rate,storage_capacity=192000,vehicle_capacity=cargo_max,storage_raw_autonomy_min=round(192000/extreme_elevator,2),vehicle_raw_autonomy_min=round(cargo_max/extreme_elevator,2),conclusion='Extrembelegung bleibt durch den Elevator begrenzt. Vorrang niedriger Erzstufen kann bei Rückstau wertvollere Erze verzögern.'),
      assumptions=[
        'Alle neuen Zahlen sind TODO_BALANCE/VORSCHLAG. Keine behaupteten Roblox-Studio-Messwerte.',
        'Zeitschritt 10s, serverseitige logische Mengen; Verkauf nur nach abgeschlossener Fahrt.',
        'Aktivprofil: manuelle Zeitanteile bis L10 100%, L10-24 60%, L25-49 25%, abL50 15%; übrige Zeit Management/Luck ohne Grundfortschrittsbeitrag.',
        'Typische Firma: zwei frühe Worker plus zwei neueste Drill-Exemplare; Automationsprofil vier neueste Drills. Demontierte Vorgänger liegen im Inventar und produzieren nicht.',
        'Jeder Vorgängertyp wird einmal gekauft, nicht verbraucht; Kaufpreise werden sofort vom Cash abgezogen.',
        'Manuelle Bestände im Rucksack, automatische Bestände über Elevator, sortenreine Lagerkisten, Ofenpuffer und Fahrzeug getrennt.',
        'Die Standardläufe verwenden vier kaufbare Fahrzeuge. Zwei Zusatzläufe zeigen die Reihe mit Lastzügen.',
        'Schmelzerziel: 1.500 Barren/min durch mehrere Barren pro Servertakt. Die reale Verarbeitung muss in Studio gemessen werden.',
        'Ab Level 60 sinken die bisherigen XP-Schwellen stufenweise bis zu 35 %. Späte Minen und Drills werden schrittweise günstiger.',
        'Verkäufe freiwillig anfangs alle3min, nachL10 alle8min, nachL50 alle15min; Rucksackvoll erzwingt frühere Fahrt.',
        'Gelegenheit:30 aktive Minuten je Sitzung und anschließend8h offline; Offlinecash30% Bruttowert installierter automatischer Kette, keine Materialien/XP, keine Offline-Löhne.',
        'Erzpreis steigt moderat um20% jeTier; XP separat quadratisch. Die frühere zusätzliche Spätspiel-Preiskurve entfällt im Vorschlag. AbL20 Kaufbudgets aus typischemBrutto/min mal Zeitfenster, feste referenzierte Preise statt dynamischer Spielerpreise.',
        'Prestige behält nur Pick/Pack unter normaler Ausrüstung; voller Wiederaufbau von Fahrzeugen/Maschinen; +5%Cash jePrestige als anfänglicher Vorschlag.',
      ],limitations=[
        'Feste nachvollziehbare Kaufstrategie, keine globale Optimierung aller möglichen Firmenbelegungen.',
        '10sSchritte und kontinuierliche Teilmengen in Produktionspuffern; echte Spielrundung kann leicht abweichen.',
        'Wege45s zuFuß bzw74s mitFahrzeug als noch ungemessene Annahmen; Fahrzeuggeschwindigkeit wird nicht ausMapgeometrie abgeleitet.',
        'Kosten für Wege zuLäden und Aufbauanimationen nicht separat, Managementzeit in manuellen Zeitanteilen enthalten.',
        'Luck/Jackpot, Handel, Robux fehlen bewusst im regulären Zielzeitmodell; getrennte Extrasmodelle erforderlich.',
        'Offlineleistung ist mathematischer Abnehmer ohne dauerhafte Lagerbegrenzung; bewusst neue Regel, nicht Verhalten aktueller Spielimplementation.',
        'Workerlohn wird einmaljeOnlineMinute gezahlt; beiGeldmangel pausierenWorker bis zur nächsten erfolgreichenAbrechnung. NPCWege sindnichtwirtschaftlichsimuliert.',
        'OptionaleLuck-,Offline-Upgrades undPremiumOffice werden inGrundläufen nichtgekauft; ihreKosten undWirkung sindgetrennteVorschläge undnicht als imCashmodellbereitsbezahltbehauptet.',
        'Cash-onlyOffline kann bei starkemOfflineanteil großenüberschüssigenCash erzeugen. XP undOnlineverkäufe bleiben derFortschrittsengpass; keineaktiveZeitgarantieausCashbonusableiten.',
        'Verkaufszeitpunkte hängen von quantisiertenFahrtenab. EinweggesparterKauf kann durch anderenVerkaufstermin einenLevel geringfügigspätererzeugen; keinmonotonerEffektnachjederEinzeländerunggarantiert.',
      ],checks={
        'counts':{k:len(v) for k,v in cols.items() if isinstance(v,list)},
        'all_cash_rollforwards_reconcile':all(abs(s['summary']['cash_rollforward_error'])<.01 for s in sims),
        'all_logged_material_rollforwards_reconcile':all(abs(s['summary']['material_rollforward_error'])<.001 for s in sims if s['summary']['material_rollforward_error'] is not None),
        'all_xp_rollforwards_reconcile':all(abs(s['summary']['xp_rollforward_error'])<.001 for s in sims),
        'all_simulations_reached_100':all(s['status']=='reached' for s in sims),
        'model_no_random_rare_progression':True,
        'strict_drill_rates_increasing':all(b['rate_min']>a['rate_min'] for a,b in zip(cols['drills'],cols['drills'][1:])),
        'all_baseline_drills_have_produced':len(active['drill_usage'])==30 and all(d['produced_units']>0 for d in active['drill_usage'].values()),
        'all_baseline_drills_have_sale_before_successor':len(drill_gaps)==29 and all(g['sales_before_next']>=1 and g['use_before_next_min']>0 for g in drill_gaps),
        'min_baseline_drill_purchase_gap_min':min(g['use_before_next_min'] for g in drill_gaps),
        'active_min_backpack_autonomy':min(s['backpack_autonomy_min'] for s in active['snapshots']),
        'active_min_vehicle_auto_autonomy':min(s['vehicle_autonomy_auto_min'] for s in active['snapshots'] if s['vehicle_autonomy_auto_min'] is not None),
        'active_min_storage_auto_autonomy':min(s['storage_autonomy_auto_min'] for s in active['snapshots'] if s['storage_autonomy_auto_min'] is not None),
        'active_spending_share_sales':active['summary']['cash_spent']/active['summary']['cash_sales'],
        'second_prestige_time_ratio':sims[3]['active_minutes']/active['active_minutes'],
      })
    HERE.mkdir(parents=True,exist_ok=True)
    (HERE/'model.json').write_text(json.dumps(out,ensure_ascii=False,indent=2),encoding='utf-8')
    (HERE/'definitions.json').write_text(json.dumps(cols,ensure_ascii=False,indent=2),encoding='utf-8')
    print(json.dumps({'history':history,'results':[{k:s[k] for k in ['profile','prestige','rate_factor','trip_factor','active_minutes','status','milestones']} for s in sims],'checks':out['checks']},ensure_ascii=False,indent=2))

if __name__=='__main__':main()
