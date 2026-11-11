import fs from 'node:fs/promises';
import path from 'node:path';
import { FileBlob, SpreadsheetFile } from '@oai/artifact-tool';

const root='C:/Dev/roblox-idle-miner';
const source='C:/Users/Allmo/OneDrive/Desktop/Roblox Idel Mine game/Balancing.xlsx';
const model=JSON.parse(await fs.readFile(path.join(root,'tools/balancing_20261109/model.json'),'utf8'));
const dateLabel=model.generated_date.split('-').reverse().join('.');
const out=path.join(root,`outputs/balancing-${model.generated_date.replaceAll('-','')}`);
await fs.mkdir(out,{recursive:true});
const wb=await SpreadsheetFile.importXlsx(await FileBlob.load(source));
if(process.argv.includes('--inspect')){
  console.log((await wb.inspect({kind:'sheet',include:'id,name',maxChars:3500})).ndjson);
  for(const [sheet,range] of [['Allgemein','A1:I12'],['Spitzhacken','A1:N7']]){
    console.log((await wb.inspect({kind:'table',range:`'${sheet}'!${range}`,include:'values,formulas',tableMaxRows:7,tableMaxCols:14,maxChars:3500})).ndjson);
    const preview=await wb.render({sheetName:sheet,range,scale:1.1,format:'png'});
    await fs.writeFile(path.join(out,`source-${sheet}.png`),new Uint8Array(await preview.arrayBuffer()));
  }
  process.exit(0);
}
const extras=JSON.parse(await fs.readFile(path.join(root,'tools/balancing_extras_20261109/extras.json'),'utf8'));
const c=model.collections,g=c.general;
const navy='#304F6E', ink='#202D39', amber='#FFF2B3', gray='#F1F3F5';
const inputPairs=[];
const q=s=>`'${s.replaceAll("'","''")}'`;
const col=n=>{let x='';for(let k=n;k>0;k=Math.floor((k-1)/26))x=String.fromCharCode(65+(k-1)%26)+x;return x;};
const get=s=>wb.worksheets.getItem(s);
const put=(s,a,v,track=false)=>{get(s).getRange(a).values=[[v??null]];if(track&&typeof v==='number')inputPairs.push([s,a,v]);};
const formula=(s,a,f)=>{get(s).getRange(a).formulas=[[f]];};
const add=(name,headers,rows,widths=[])=>{
  const sh=wb.worksheets.add(name),n=headers.length;
  sh.showGridLines=false; sh.tabColor=navy;
  sh.getRangeByIndexes(0,0,rows.length+1,n).values=[headers,...rows.map(r=>headers.map((_,i)=>r[i]??null))];
  const area=sh.getRangeByIndexes(0,0,rows.length+1,n);
  area.format.font={name:'Arial',size:10,color:ink}; area.format.rowHeight=21;area.format.verticalAlignment='center';
  sh.getRangeByIndexes(0,0,1,n).format={fill:navy,font:{name:'Arial',size:10,color:'#FFFFFF',bold:true},wrapText:true,rowHeight:36};
  for(let i=0;i<n;i++)sh.getRange(`${col(i+1)}:${col(i+1)}`).format.columnWidth=widths[i]??18;
  sh.freezePanes.freezeRows(1);
  if(rows.length)sh.getRangeByIndexes(1,0,rows.length,n).setNumberFormat('#,##0.00');
  return sh;
};
const record=s=>{let a=s.active_minutes;return typeof a==='number'?a:null;};
const baseline=model.simulations.find(s=>s.profile==='active'&&s.prestige===0&&s.rate_factor===1&&s.trip_factor===1)??model.simulations[0];
if(!baseline)throw new Error('Basissimulation fehlt');

// Bestehende Eingabestruktur: Istwerte bleiben erhalten, gelbe Felder erhalten Vorschläge.
for(const x of c.picks){const r=x.source_row;for(const [cc,k]of[['H','level'],['I','price'],['J','power'],['K','speed']])put('Spitzhacken',`${cc}${r}`,x[k],true);put('Spitzhacken',`N${r}`,'VORSCHLAG; Vorgänger einmal kaufen; bleibt bei Prestige.');}
for(const x of c.packs){const r=x.source_row;for(const [cc,k]of[['H','level'],['I','price'],['J','capacity']])put('Rucksäcke',`${cc}${r}`,x[k],true);put('Rucksäcke',`L${r}`,'VORSCHLAG; 15-min-Ziel; bleibt bei Prestige.');}
for(const x of c.drills){const r=x.source_row;for(const [cc,k]of[['I','level'],['J','price'],['K','units_cycle'],['L','cycle_seconds'],['M','buffer']])put('Drills',`${cc}${r}`,x[k],true);put('Drills',`R${r}`,'VORSCHLAG; Typ-Vorgänger einmalig; MK und Drill-Level getrennt.');}
for(const x of c.vehicles){const r=x.source_row;for(const [cc,k]of[['J','level'],['K','price'],['L','capacity'],['M','speed'],['N','acceleration']])put('Fahrzeuge',`${cc}${r}`,x[k],true);put('Fahrzeuge',`P${r}`,x.available?'VORSCHLAG; künftig Prestige-Reset.':'VORSCHLAG; im Modell enthalten, Kauf im Spiel weiter gesperrt.');}
for(const x of c.elevator){const r=x.source_row;for(const [cc,k]of[['F','capacity'],['G','price'],['H','level']])put('Elevator-Stufen',`${cc}${r}`,x[k],true);put('Elevator-Stufen',`K${r}`,'VORSCHLAG / TESTING_REQUIRED');}
for(const x of [...c.buildings,...c.conveyors]){const r=x.source_row;if(!r)continue;put('Bauschritte',`G${r}`,x.price,true);put('Bauschritte',`H${r}`,x.level,true);put('Bauschritte',`I${r}`,'VORSCHLAG; noch nicht im Spiel.');}
put('Bauschritte','G12',c.conveyors[0].throughput_min,true);
put('Bauschritte','J1','Vorschau Preis ($)');put('Bauschritte','K1','Vorschau Level');
for(let r=2;r<=10;r++){formula('Bauschritte',`J${r}`,`=IF(G${r}="",D${r},G${r})`);formula('Bauschritte',`K${r}`,`=IF(H${r}="",E${r},H${r})`);}
formula('Bauschritte','J12','=IF(G12="",D12,G12)');
for(const x of [...c.ores,...c.bars]){const r=x.source_row;put('Erze & Barren',`H${r}`,x.price,true);put('Erze & Barren',`I${r}`,x.xp,true);put('Erze & Barren',`J${r}`,'VORSCHLAG; fester Einzelwert ersetzt alte Bezugskurve.');}
put('Erze & Barren','K1','Vorschau Wert ($)');put('Erze & Barren','L1','Vorschau XP');
for(const x of [...c.ores,...c.bars]){const r=x.source_row;formula('Erze & Barren',`K${r}`,`=IF(H${r}="",E${r},H${r})`);formula('Erze & Barren',`L${r}`,`=IF(I${r}="",F${r},I${r})`);}
for(const x of c.mines){const r=x.source_row;put('Minen',`F${r}`,x.level,true);put('Minen',`G${r}`,x.price,true);put('Minen',`H${r}`,'VORSCHLAG; Kauf der Reihe nach.');}
put('Minen','I1','Vorschau Level');put('Minen','J1','Vorschau Preis ($)');
for(const x of c.mines){const r=x.source_row;formula('Minen',`I${r}`,`=IF(F${r}="",C${r},F${r})`);formula('Minen',`J${r}`,`=IF(G${r}="",D${r},G${r})`);}

const generalValues={3:g.start_cash,4:g.offline_max_hours*3600,6:model.xp_curve[0].xp_next,13:g.crate_size,14:g.max_crates,15:g.start_crates,16:c.storage[0].price,17:c.storage[1].price,18:c.storage[2].price,19:1,21:g.worker_hire,22:g.worker_wage_min,23:g.worker_rate_min,24:g.worker_slot_buffer,25:0,26:60,29:g.elevator_start_capacity,30:g.elevator_cycle_seconds,32:g.loading_min_units_second,33:g.loading_full_seconds,35:g.smelter_ore_per_bar,36:g.smelter_seconds_per_bar,37:g.smelter_input_crates,38:g.smelter_output_crates,40:extras.quantity_bonus?.base_chance_per_hit??0.01,41:0.15,55:1,57:extras.luck.max_level,58:extras.luck.relative_bonus_per_level,59:extras.luck.levels[0].price,60:1,61:5,63:g.drill_max_level,64:g.drill_level_bonus,65:g.drill_upgrade_share,66:g.drill_upgrade_growth,68:g.prestige_level,69:g.prestige_money_bonus,70:g.prestige_speed_bonus,71:g.prestige_speed_max,73:c.mines[2].price,74:1,75:1,76:1,77:100,79:1.2,80:50,81:1.2,82:1,83:1.4,84:1.1,86:g.late_price_start,87:g.late_price_growth};
for(const [r,v]of Object.entries(generalValues)){if(Number(r)>=40&&Number(r)<=54)continue;put('Allgemein',`G${r}`,v,true);put('Allgemein',`I${r}`,'VORSCHLAG / TESTING_REQUIRED');}
for(const r of [7,8,9,10,11]){put('Allgemein',`I${r}`,'Altmodell; neue Einzel-XP im Blatt Level-Kurve.');put('Allgemein',`C${r}`,'Historischer Exponent. Das neue Modell nutzt die einzeln kalibrierten XP der Level-Kurve.');}
put('Allgemein','C4','Ansammlungsdauer des neuen Offline-Cash-Modells; 30 % Basisleistung, keine zusätzlichen Materialien/XP.');
put('Allgemein','C19','Altmodell-Faktor deaktiviert. Neue Kistenpreise stehen im Blatt Tabellen: Potenzkurve statt exponentieller Folge.');
put('Allgemein','C59','Neuer erster Luck-Preis. Weitere Preise/Level stehen unter Upgrade-Stufen; keine geometrische Preisformel.');
put('Allgemein','C60','Geometrische alte Luck-Kurve deaktiviert; Einzelwerte unter Upgrade-Stufen maßgeblich.');
put('Allgemein','C61','Historischer Abstand. Neue Mindest-Level sind Einzelwerte unter Upgrade-Stufen.');
for(const r of [73,74,75,76,77])put('Allgemein',`I${r}`,'Neue Minen-Einzelpreise/Level im Blatt Minen maßgeblich.');
for(const r of [79,80,81,82,83,84])put('Allgemein',`I${r}`,'Neue feste Erz-/Barrenwerte im gleichnamigen Blatt maßgeblich.');
for(let r=40;r<=54;r++){put('Allgemein',`G${r}`,null);put('Allgemein',`I${r}`,'ALT: neues Fundmodell mit getrennten Chancen unter Upgrade-Stufen/Sonderfunde.');}
put('Allgemein','C87','Neues Modell ohne zusätzlichen pauschalen Level-Preisaufschlag.');
get('Allgemein').getRange('A89:I89').copyFrom(get('Allgemein').getRange('A85:I85'),'all');
put('Allgemein','A89','Neues Offline-Cash-Modell');
get('Allgemein').getRange('A90:I90').values=[['Offline','Offline.Efficiency','Anteil des automatischen Bruttoertrags; kein zusätzlicher Material-/XP-Anspruch.',null,'Anteil','VORSCHLAG',g.offline_rate,null,'Neue Regel; aktuelle Spielimplementierung noch unverändert.']];
formula('Allgemein','H90','=IF(G90="","n.a.",G90)');inputPairs.push(['Allgemein','G90',g.offline_rate]);
get('Allgemein').getRange('A90:I90').format.font={name:'Arial',size:10,color:ink};get('Allgemein').getRange('A90:I90').format.wrapText=true;get('Allgemein').getRange('A90:I90').format.autofitRows();get('Allgemein').getRange('G90').format.fill=amber;get('Allgemein').getRange('H90').format.fill=gray;get('Allgemein').getRange('G90:H90').setNumberFormat('0.0%');

// Die neue XP-Tabelle ist die einzige aktuelle XP-Eingabe; alte Formeln werden ersetzt.
const lv=get('Level-Kurve');lv.getRange('A1:D123').clear({applyTo:'contents'});
lv.getRange('A1:D1').values=[['Level','Neue XP bis nächstes Level','Kumulierte neue XP','Zeit-Ziel aktiv (Minuten)']];
for(const x of model.xp_curve){const r=x.level+1;put('Level-Kurve',`A${r}`,x.level);put('Level-Kurve',`B${r}`,x.xp_next,true);formula('Level-Kurve',`C${r}`,r===2?'=0':`=C${r-1}+B${r-1}`);put('Level-Kurve',`D${r}`,x.level<=100?x.target_active_min:null);}
put('Level-Kurve','A123','L1–100 kalibriert; L101–120 Fortsetzungsentwurf ohne freigeschaltete neue Inhalte.');
lv.getRange('A:A').format.columnWidth=13;lv.getRange('B:D').format.columnWidth=26;
lv.getRange('B2:B121').format.fill=amber;lv.getRange('B2:C121').setNumberFormat('#,##0');

const recipeRows=c.recipes.map(r=>{const ore=c.ores.find(o=>o.id===r.input_id),bar=c.bars.find(o=>o.id===r.output_id);return[r.id,r.input_id,r.input_qty,r.output_id,r.output_qty,r.seconds,null,null,null,ore.source_row,bar.source_row];});
add('Rezepte neu',['Rezept-ID','Input-ID','Inputmenge','Output-ID','Outputmenge','Sekunden / Barren','Inputwert ($)','Outputwert ($)','Mehrwert','Quellzeile Erz','Quellzeile Barren'],recipeRows,[30,25,13,26,14,20,18,18,14,16,18]);
for(let i=0;i<recipeRows.length;i++){const r=i+2;formula('Rezepte neu',`G${r}`,`=C${r}*'Erze & Barren'!K${recipeRows[i][9]}`);formula('Rezepte neu',`H${r}`,`=E${r}*'Erze & Barren'!K${recipeRows[i][10]}`);formula('Rezepte neu',`I${r}`,`=H${r}/G${r}-1`);}
get('Rezepte neu').getRange(`I2:I${recipeRows.length+1}`).setNumberFormat('0.0%');

const assumptions=[['Stand','2026-11-09','Neue Vorschlagswerte, keine Spielumstellung'],['Status','TESTING_REQUIRED','Zielbild am 09.11.2026 mit weiter freigegeben'],['Simulation','Ereignis-/Zeitschrittmodell','Die gespeicherten Läufe werden bei Zelländerungen nicht neu simuliert'],['Zelländerungen','Vorschauen rechnen direkt','Vollständige Spieldurchläufe nach Änderungen neu berechnen'],['Start-Cash',g.start_cash,'$'],['Manueller Verkaufsweg',g.manual_trip_seconds,'Sekunden; angenommener Weg, in Studio messen'],['Fahrzeug-Rundfahrt',g.vehicle_trip_seconds,'Sekunden; angenommen, in Studio messen'],['Offline-Leistung',g.offline_rate,'Anteil installierter automatischer Bruttoleistung'],['Offline-Limit',g.offline_max_hours,'Stunden; keine XP, kein zusätzliches Material'],['Typische Drill-Strategie',2,'Neueste zwei gekauften Typen betreiben; keine neue Slotbegrenzung'],['Automationsprofil',4,'Vier platzierte Drills statt zwei; übrige bleiben im Inventar'],['Handel / Robux','Ausgeschlossen','Keine Geschenke oder bezahlten Boni in Referenzläufen'],['Seltene Jackpotfunde','Referenz ohne Jackpot','Feste tierbezogene Fundpreise separat unter Sonderfunde'],['Nach Prestige','Pickaxe + Backpack behalten','Sofort nutzbar; Fahrzeuge, Luck und Firma zurückgesetzt'],['Normale Hitmenge','Logische Produktion','Keine physischen Teile je Erzeinheit simuliert'],['Kaufregeln','Vorgänger einmalig','Modellannahme; benötigt spätere Spielumsetzung'],['Einheiten','Cash und Mining-XP getrennt','XP ausschließlich auf tatsächlich aktiv verkaufte Materialien'],['Quelle','Balancing.xlsx, Stand 02.11.2026','Alte Daten stehen weiter in den Ist-Spalten'],['Designauftrag','Chat 08.–09.11.2026','docs/BALANCING_ZIELBILD_2026-11-08.md'],['Referenz','Grow a Garden','https://www.roblox.com/games/126884695634066/Grow-a-Garden'],['Gestaltungsgrundlage','Roblox Retention','https://create.roblox.com/docs/production/analytics/retention']];
for(const x of model.assumptions??[])assumptions.push(['Modellannahme',typeof x==='string'?x:JSON.stringify(x),'']);
for(const x of model.limitations??[])assumptions.push(['Modellgrenze',typeof x==='string'?x:JSON.stringify(x),'']);
assumptions.push(['Designkonflikt','Offline-Cash übertrifft langes untätiges Online-Stehen','Kein neues Online-Autosell eingeführt; vor Spielumsetzung entscheiden.']);
assumptions.push(['Endkriterium','Mining-Level 100 / Prestige verfügbar',`Referenz endet mit Mine ${baseline.snapshots.at(-1).mine}; die übrigen Minen sind zusätzliche Cashziele, nicht bereits gekauft.`]);
assumptions.push(['Extrembelegung','200 Slots mit maximalen Drills','Gesonderter Belastungstest; 15-Minuten-Autonomie gilt dafür nicht. Alte Erztiers können Transport priorisieren und wertvolle Erze verdrängen.']);
assumptions[0][1]=model.generated_date;
add('Modellannahmen',['Thema','Wert / Annahme','Erläuterung / Quelle'],assumptions,[30,75,95]);
formula('Modellannahmen','B9',"='Allgemein'!H90");get('Modellannahmen').getRange('B9').setNumberFormat('0.0%');
get('Modellannahmen').getRange(`A2:C${assumptions.length+1}`).format.wrapText=true;get('Modellannahmen').getRange(`A2:C${assumptions.length+1}`).format.autofitRows();

const runs=model.simulations;
const profileLabel=run=>{
  const name=({active:'Aktiv',casual:'Kurzsitzungen + Offline',automation:'Vier-Drill-Firma'}[run.profile]??run.profile);
  return run.vehicle_scope==='all'?`${name} mit Lastzügen`:name;
};
const runRows=runs.map((s,i)=>[i+1,profileLabel(s),s.prestige,s.rate_factor,s.trip_factor,s.status==='reached'?'Level 100 erreicht':s.status,s.active_minutes/60,s.calendar_minutes/60,s.summary.cash_sales,s.summary.cash_offline,s.summary.cash_spent,s.summary.wages,s.summary.cash_end,null,s.summary.cash_rollforward_error,s.summary.material_rollforward_error??null,s.summary.xp_rollforward_error??null,s.summary.production_stalled_minutes]);
add('Simulationsläufe',['Lauf','Profil','Prestige vor Start','Produktionsfaktor','Fahrtfaktor','Ergebnis','Aktiv (h)','Verstrichen (h)','Aktiv verkauft ($)','Offline ($)','Käufe ($)','Löhne ($)','End-Cash ($)','Cash nach Rechnung','Cash-Differenz','Material-Differenz','XP-Differenz','Rückstau (Min)'],runRows,[10,34,18,19,17,17,15,19,22,20,20,18,22,23,21,21,20,20]);
for(let i=0;i<runRows.length;i++){const r=i+2;formula('Simulationsläufe',`N${r}`,`='Allgemein'!H3+I${r}+J${r}-K${r}-L${r}`);formula('Simulationsläufe',`O${r}`,`=M${r}-N${r}`);}

const snapshots=[];for(let i=0;i<runs.length;i++)for(const s of runs[i].snapshots??[])snapshots.push([i+1,profileLabel(runs[i]),runs[i].prestige,s.level,s.active_min/60,s.cash,s.pick_id,s.pack_id,s.drill_mk,s.placed_drills,s.auto_rate_min,s.manual_raw_rate_min,s.manual_activity_share,s.elevator_rate_min,s.crates,s.storage_capacity,s.vehicle_capacity,s.backpack_autonomy_min,s.vehicle_autonomy_auto_min,s.storage_autonomy_auto_min,s.gross_cash_per_min??null]);
add('Levelstände',['Lauf','Profil','Prestige','Level','Aktiv (h)','Cash ($)','Spitzhacke-ID','Rucksack-ID','Neuester Drill MK','Drills platziert','Auto-Einheiten/min','Manuell roh/min','Manuell-Zeitanteil','Elevator/min','Kisten','Lagerplatz','Frachtplatz','Rucksack (Min)','Fracht Auto (Min)','Lager Auto (Min)','Brutto-Cash/min'],snapshots,[9,17,12,10,14,20,29,31,20,18,21,20,19,18,12,16,16,20,22,22,23]);
get('Levelstände').getRange(`M2:M${snapshots.length+1}`).setNumberFormat('0.0%');

const eventLabel={purchase:'Kauf',sale:'Verkauf',offline_credit:'Offline-Gutschrift'};
const categoryLabel={building:'Gebäude',mine:'Mine',pick:'Spitzhacke',pack:'Rucksack',vehicle:'Fahrzeug',drill:'Drill',drill_upgrade:'Drill-Level',crate:'Lagerkiste',elevator:'Elevator',conveyor:'Förderband',worker:'Worker'};
const evs=[];for(let i=0;i<runs.length;i++)for(const e of runs[i].events??[])evs.push([i+1,e.active_min,e.calendar_min,e.level,eventLabel[e.kind]??e.kind,categoryLabel[e.category]??e.category??'',e.item_id??'',e.price??0,e.revenue??e.cash_credit??e.amount??0,e.xp??0,e.quantity??0,e.cash,e.cash_sales_to_date??null,e.cash_offline_to_date??null,e.cash_spent_to_date??null,e.wages_to_date??null]);
add('Kauf- und Verkaufslog',['Lauf','Aktiv (Min)','Verstrichen (Min)','Level','Ereignis','Kategorie','ID','Kaufpreis ($)','Verkauf / Gutschrift ($)','Verkaufs-XP','Verkaufte Menge','Cash danach ($)','Aktivumsatz kum.','Offline kum.','Käufe kum.','Löhne kum.'],evs,[9,17,21,10,20,18,35,20,27,20,20,23,23,21,21,20]);

const upRows=[];
upRows.push(['Mengenbonus','Basis',1,null,extras.quantity_bonus.base_probability_per_hit,null,'Chance je gültigem Hit vor Luck; exklusiver Ergebniswurf']);
upRows.push(['Nächstes Erz','Basis',1,null,extras.next_tier_ore_bonus.base_probability_per_hit??extras.next_tier_ore_bonus.base_chance_per_hit??null,null,'Chance je Hit; nächstes 1–4 Erztiers, kein Jackpot']);
for(const x of extras.luck.levels)upRows.push(['Luck',x.level,x.required_level,x.price,x.relative_chance_factor,x.cost_reference_gross_minutes,'Vorgängerstufe; Prestige-Reset']);
for(const x of extras.offline.efficiency_upgrades)upRows.push(['Offline-Effizienz',x.id,x.required_level,x.price,x.efficiency??x.rate??null,x.cost_reference_gross_minutes,'Anteil automatischer Bruttoleistung; Prestige-Reset']);
for(const x of extras.offline.duration_upgrades)upRows.push(['Offline-Dauer',x.id,x.required_level,x.price,x.cap_hours,x.cost_reference_gross_minutes,'Stunden Ansammlung; Prestige-Reset']);
const dlevels=extras.drill_upgrades.levels??extras.drill_upgrades.rows??[];
for(const x of dlevels)upRows.push(['Drill-Level',x.level,null,null,x.production_factor??x.production_multiplier,null,'Preisbeispiel MK1; bei anderem Typ mit dessen Kaufpreis rechnen']);
add('Upgrade-Stufen',['System','Stufe / ID','Mining-Level','Preis ($)','Effekt / Faktor','Cash-Minuten Referenz','Hinweis'],upRows,[24,27,18,23,22,25,75]);
get('Upgrade-Stufen').getRange(`D2:E${upRows.length+1}`).format.fill=amber;
get('Upgrade-Stufen').getRange(`B2:D${upRows.length+1}`).setNumberFormat('#,##0');
for(let i=0;i<upRows.length;i++){const r=i+2,x=upRows[i];if(i<2||x[0]==='Offline-Effizienz')get('Upgrade-Stufen').getRange(`E${r}`).setNumberFormat('0.00%');if(x[0]==='Drill-Level'){formula('Upgrade-Stufen',`D${r}`,x[1]===1?'=0':`='Drills'!N2*'Tabellen'!I${x[1]}`);formula('Upgrade-Stufen',`E${r}`,`='Tabellen'!H${x[1]+1}`);}}

const rareRows=extras.jackpot_variants.map(x=>[x.id,x.base_ore_id,x.rarity,x.required_level,x.chance_per_hit,x.sell_value,x.xp,x.reference_income_minutes,'VORSCHLAG; nur manuell, vorerst nicht handelbar']);
add('Sonderfunde',['Neue ID','Quellerz-ID','Seltenheit','Mining-Level','Chance je Hit','Fester Wert ($)','XP je Fund','Referenz-Minuten','Status / Regel'],rareRows,[40,28,18,18,21,23,18,23,65]);
get('Sonderfunde').getRange(`E2:E${rareRows.length+1}`).setNumberFormat('0.00000%');
get('Sonderfunde').getRange(`F2:G${rareRows.length+1}`).format.fill=amber;
const waits=extras.jackpot_waiting_time_rows;
add('Fundwahrscheinlichkeiten',['Seltenheit','Gültige Hits / Sekunde','Luck-Faktor','Effektive Chance je Hit','Mittlere Wartezeit (Min)','Median-Wartezeit (Min)','90%-Wartezeit (Min)','Fundchance in 15 Min','Fundchance in 30 h'],waits.map(x=>[x.rarity,x.hits_per_second,x.luck_factor,null,null,null,null,null,null]),[19,25,19,25,27,27,25,26,26]);
const waitSheet=get('Fundwahrscheinlichkeiten');waitSheet.getRange('A1:I1').format.rowHeight=48;
for(let i=0;i<waits.length;i++){const r=i+2,sourceRow=rareRows.findIndex(x=>x[2]===waits[i].rarity)+2;formula('Fundwahrscheinlichkeiten',`D${r}`,`='Sonderfunde'!E${sourceRow}*C${r}`);formula('Fundwahrscheinlichkeiten',`E${r}`,`=1/(D${r}*B${r}*60)`);formula('Fundwahrscheinlichkeiten',`F${r}`,`=CEILING(LN(0.5)/LN(1-D${r}),1)/(B${r}*60)`);formula('Fundwahrscheinlichkeiten',`G${r}`,`=CEILING(LN(0.1)/LN(1-D${r}),1)/(B${r}*60)`);formula('Fundwahrscheinlichkeiten',`H${r}`,`=1-(1-D${r})^(B${r}*60*15)`);formula('Fundwahrscheinlichkeiten',`I${r}`,`=1-(1-D${r})^(B${r}*60*1800)`);}
waitSheet.getRange(`D2:D${waits.length+1}`).setNumberFormat('0.00000%');waitSheet.getRange(`H2:I${waits.length+1}`).setNumberFormat('0.0%');waitSheet.getRange(`B2:C${waits.length+1}`).format.fill=amber;

// Kisten-/Luck-/Drilltabellen vollständig an die neuen Vorschläge binden.
const tables=get('Tabellen');tables.getUsedRange().clear({applyTo:'all'});
const tablesHeaders=['Kiste','Platz je Kiste','Kaufpreis ($)','Gesamtplatz','Kumulierte Kosten ($)'];
tables.getRange('A1:E1').values=[tablesHeaders];
tables.getRange(`A2:E${c.storage.length+1}`).values=c.storage.map(x=>[x.number,x.capacity,x.price,null,null]);
for(let i=0;i<c.storage.length;i++){const r=i+2;formula('Tabellen',`D${r}`,`=A${r}*B${r}`);formula('Tabellen',`E${r}`,r===2?`=C${r}`:`=E${r-1}+C${r}`);inputPairs.push(['Tabellen',`C${r}`,c.storage[i].price]);}
tables.getRange('A1:E1').format={fill:navy,font:{name:'Arial',size:10,bold:true,color:'#FFFFFF'},rowHeight:34,wrapText:true};
tables.getRange('A2:E193').format.font={name:'Arial',size:10,color:ink};tables.getRange('A:E').format.columnWidth=24;tables.getRange('B2:C193').format.fill=amber;tables.getRange('A2:E193').setNumberFormat('#,##0');tables.freezePanes.freezeRows(1);
put('Tabellen','G1','Drill-Level');put('Tabellen','H1','Produktionsfaktor');put('Tabellen','I1','Nächster Kaufanteil');put('Tabellen','J1','Kumulierte Kaufanteile');
for(let i=0;i<10;i++){const r=i+2;put('Tabellen',`G${r}`,i+1);formula('Tabellen',`H${r}`,`=1+(G${r}-1)*'Allgemein'!H64`);formula('Tabellen',`I${r}`,i===9?'=0':`='Allgemein'!H65*'Allgemein'!H66^(G${r}-1)`);formula('Tabellen',`J${r}`,i===0?'=0':`=J${r-1}+I${r-1}`);}
tables.getRange('G:J').format.columnWidth=25;tables.getRange('G1:J1').format={fill:navy,font:{name:'Arial',size:10,bold:true,color:'#FFFFFF'},rowHeight:34,wrapText:true};tables.getRange('I2:J11').setNumberFormat('0.0%');

// Aktuell berechenbare Kapazitätsvorschau je Ausrüstung, unabhängig vom gespeicherten Lauf.
const capRows=c.picks.map(x=>{const p=c.packs.filter(p=>p.level<=x.level).at(-1)??c.packs[0];return[x.id,x.level,x.source_row,p.id,p.source_row,null,null,null,null,null];});
add('Kapazitätsvorschau',['Spitzhacke-ID','Level','Quellzeile Pick','Passender Rucksack','Quellzeile Pack','Erz / Minute','Rucksackplatz','Minuten roh','15-Min-Ziel','Leistungszuwachs'],capRows,[31,12,20,34,22,20,20,20,20,22]);
for(let i=0;i<capRows.length;i++){const r=i+2;formula('Kapazitätsvorschau',`F${r}`,`='Spitzhacken'!M${capRows[i][2]}*60`);formula('Kapazitätsvorschau',`G${r}`,`=IF('Rucksäcke'!J${capRows[i][4]}="",'Rucksäcke'!E${capRows[i][4]},'Rucksäcke'!J${capRows[i][4]})`);formula('Kapazitätsvorschau',`H${r}`,`=G${r}/F${r}`);formula('Kapazitätsvorschau',`I${r}`,`=IF(H${r}>=15,"erfüllt","unter 15 Minuten")`);formula('Kapazitätsvorschau',`J${r}`,i===0?'=0':`=F${r}/F${r-1}-1`);}
get('Kapazitätsvorschau').getRange('J2:J26').setNumberFormat('0.0%');
get('Kapazitätsvorschau').getRange('H2:H26').conditionalFormats.add('cellIs',{operator:'lessThan',formula:15,format:{fill:'#FDE8E7',font:{color:'#9E2121',bold:true}}});

const stress=add('Belastungstest',['Extrembelegung, keine typische Firma','Wert','Einheit / Auswirkung'],[['Mining-Slots',200,'100 Minen, zwei Slots je Mine'],['Drill-Level',10,'Jeder Slot MK30, maximal aufgewertet'],['Gesamte Rohproduktion',null,'Erz / Minute'],['Elevator maximal',null,'Erz / Minute'],['Ankommender Rohfluss',null,'Erz / Minute, vor Verarbeitung'],['Lager maximal',null,'Platz'],['Größte vorhandene Fracht',null,'Platz'],['Lagerautonomie roh',null,'Minuten'],['Frachtautonomie roh',null,'Minuten'],['Bewertung',null,'Kein Nachweis für 15 Minuten bei Extrembelegung'],['Transportpriorität','Niedrige Erztiers zuerst','Hohe Tiers können bei Extrembelegung verhungern.']],[45,24,65]);
formula('Belastungstest','B4',`=B2*'Drills'!O${c.drills.at(-1).source_row}*'Tabellen'!H11`);
formula('Belastungstest','B5',`='Elevator-Stufen'!J${c.elevator.at(-1).source_row}`);
formula('Belastungstest','B6','=MIN(B4,B5)');formula('Belastungstest','B7',"='Allgemein'!H13*'Allgemein'!H14");formula('Belastungstest','B8',`='Fahrzeuge'!L${c.vehicles.at(-1).source_row}`);formula('Belastungstest','B9','=B7/B6');formula('Belastungstest','B10','=B8/B6');formula('Belastungstest','B11','=IF(MIN(B9:B10)>=15,"15 Minuten erreicht","unter 15 Minuten")');
stress.getRange('B9:B10').conditionalFormats.add('cellIs',{operator:'lessThan',formula:15,format:{fill:'#FDE8E7',font:{color:'#9E2121',bold:true}}});
const fourDrillRun=runs.find(run=>run.profile==='automation'&&run.vehicle_scope==='available');
const fourDrillMinCargo=Math.min(...fourDrillRun.snapshots.map(s=>s.vehicle_autonomy_auto_min).filter(Number.isFinite));
stress.getRange('A14:C16').values=[['Kaufbare Fahrzeugreihe','Minuten','Frachtreserve im Modell'],['Zwei Drills',model.checks.active_min_vehicle_auto_autonomy,'Minimum über die gespeicherten Levelstände'],['Vier Drills',fourDrillMinCargo,'Minimum über die gespeicherten Levelstände']];
stress.getRange('A14:C14').format={fill:navy,font:{name:'Arial',size:10,bold:true,color:'#FFFFFF'},rowHeight:30};
stress.getRange('B15:B16').setNumberFormat('0.00');

// Eingaben gegen den Datenstand der Simulation prüfen, ohne Rückkopplung ins Modell.
const checkRows=inputPairs.map(([s,a,v])=>[s,a,v,null,null]);
add('Prüfungen',['Eingabeblatt','Zelle','Wert im Simulationslauf','Aktueller Excelwert','Abweichung'],checkRows,[27,15,30,28,23]);
for(let i=0;i<inputPairs.length;i++){const r=i+2,[s,a]=inputPairs[i];formula('Prüfungen',`D${r}`,`=${q(s)}!${a}`);formula('Prüfungen',`E${r}`,`=D${r}-C${r}`);}
get('Prüfungen').getRange(`E2:E${checkRows.length+1}`).conditionalFormats.add('cellIs',{operator:'notEqual',formula:0,format:{fill:'#FDE8E7',font:{color:'#9E2121',bold:true}}});

// Ergebnis zeigt datierte Simulationsmessungen, keine sich selbst neu simulierenden Forecasts.
const summary=add('Ergebnis',['Mining Company Tycoon – Balancing','Ziel aktiv (h)','Simuliert aktiv (h)','Abweichung'],[],[48,22,25,22]);
summary.getRange('A1:D1').clear({applyTo:'all'});put('Ergebnis','A1','Balancing – Mining Company Tycoon');summary.getRange('A1:D1').format.font={name:'Arial',size:14,bold:true,color:ink};summary.getRange('A1:D1').format.rowHeight=32;
put('Ergebnis','A3',`VORSCHLAG / TESTING_REQUIRED – Berechnungsstand ${dateLabel}`);
put('Ergebnis','A4','Läufe gelten für diesen Eingabestand; Zelländerungen brauchen eine neue Simulation.');
put('Ergebnis','A5','Referenz mit kaufbaren Fahrzeugen, ohne Robux, Handelsgeschenke und Jackpotfunde.');
summary.getRange('A7:D7').values=[['Meilenstein','Ziel aktiv (h)','Lauf aktiv (h)','Abweichung']];summary.getRange('A7:D7').format={fill:navy,font:{name:'Arial',bold:true,color:'#FFFFFF'},rowHeight:28};
const goals=[10,25,50,60,75,90,100].map(level=>[level,model.xp_curve[level-1].target_active_min/60]);
for(let i=0;i<goals.length;i++){const r=i+8,[level,hours]=goals[i];put('Ergebnis',`A${r}`,`Level ${level}`);put('Ergebnis',`B${r}`,hours);const si=snapshots.findIndex(s=>s[0]===1&&s[3]===level);if(si>=0)formula('Ergebnis',`C${r}`,`='Levelstände'!E${si+2}`);else put('Ergebnis',`C${r}`,typeof baseline.milestones[`level_${level}`]==='number'?baseline.milestones[`level_${level}`]/60:'n.a.');formula('Ergebnis',`D${r}`,`=IF(ISNUMBER(C${r}),C${r}/B${r}-1,"n.a.")`);}
summary.getRange('B8:C14').setNumberFormat('0.00');summary.getRange('D8:D14').setNumberFormat('0.0%');
const chart=summary.charts.add('line',summary.getRange('A7:C14'));chart.title='Zeit bis zum Meilenstein (aktive Stunden)';chart.setPosition('F7','O23');chart.titleTextStyle.typeface='Arial';chart.titleTextStyle.fontSize=13;chart.legend={position:'top',textStyle:{typeface:'Arial'}};chart.xAxis={axisType:'textAxis',textStyle:{typeface:'Arial',fontSize:10}};chart.yAxis={numberFormatCode:'0.0',numberFormatSourceLinked:false,textStyle:{typeface:'Arial'}};chart.series.items.forEach((s,i)=>s.line={fill:i===0?'#7C8996':'#CE7E28',style:i===0?'dashed':'solid',width:2});
put('Ergebnis','A17','Profilvergleich: tatsächlich gerechnete Läufe');
summary.getRange('A18:D18').values=[['Lauf / Profil','Prestige','Aktiv bis L100 (h)','Verstrichen (h)']];summary.getRange('A18:D18').format={fill:navy,font:{name:'Arial',bold:true,color:'#FFFFFF'},rowHeight:30};
for(let i=0;i<runs.length;i++){const r=i+19,s=runs[i];let label=profileLabel(s);if(s.rate_factor!==1)label+=` / Produktion ${s.rate_factor<1?'−20 %':'+20 %'}`;if(s.trip_factor!==1)label+=` / Fahrt ${s.trip_factor<1?'−20 %':'+20 %'}`;put('Ergebnis',`A${r}`,`${i+1}: ${label}`);put('Ergebnis',`B${r}`,s.prestige);formula('Ergebnis',`C${r}`,`='Simulationsläufe'!G${i+2}`);formula('Ergebnis',`D${r}`,`='Simulationsläufe'!H${i+2}`);}
summary.getRange(`B19:B${runs.length+18}`).setNumberFormat('0');summary.getRange(`C19:D${runs.length+18}`).setNumberFormat('0.00');
const noteStart=Math.max(33,runs.length+22);
const notes=['15 Minuten sind Kapazitätsziel, keine Wartepflicht. Früh freiwillig verkaufen für XP.', 'Preis-/Leistungswerte stehen in gelben Neu-Spalten der ursprünglichen Tabellen.', 'Nur Spitzhacken und Rucksäcke bleiben nach Prestige sofort nutzbar.', 'Neue Sonderfunde und Offline-Upgrades sind Vorschläge, noch nicht im Spiel.', 'Offlinegeld: zunächst 30 % automatischer Firmenleistung für maximal acht Stunden.', 'Offener Designkonflikt: lange Offline-Gutschrift schlägt untätiges Online-Stehen.', `Level 100 erreicht mit Mine ${baseline.snapshots.at(-1).mine}; letzte Minen bleiben zusätzliche Cashziele.`, 'Extrembelegung aller 200 Slots erfüllt das 15-Minuten-Ziel nicht; siehe Belastungstest.', 'Spielcode unverändert. Tatsächliche Wege, Bedienzeiten und Fortschritt in Studio testen.'];
notes.forEach((x,i)=>put('Ergebnis',`A${noteStart+i}`,x));summary.getRange(`A${noteStart}:D${noteStart+notes.length-1}`).format.font={name:'Arial',size:10,color:ink};

// Erste Seite bleibt Anleitung und erhält klare Navigation und neue Regelhinweise.
const guide=get('Anleitung');guide.getUsedRange().clear({applyTo:'contents'});
const guideLines=['Balancing – neuer Vorschlag vom 09.11.2026','Noch nicht im Spiel umgesetzt. Status: TESTING_REQUIRED.','Öffne zuerst das Blatt Ergebnis: Zielzeiten, errechnete Läufe und wichtige Grenzen.','Gelbe Neu-Spalten enthalten die vorgeschlagenen Werte; alte Ist-Spalten bleiben als Quelle erhalten.','Grau hinterlegte Vorschauen rechnen bei Änderungen direkt mit.','Die kompletten Simulationsläufe sind datierte Rechenergebnisse und laufen nicht erneut in Excel.','Nach Änderungen zeigt Prüfungen die Abweichungen zum berechneten Eingabestand. Vollmodell dann neu rechnen.','Level-Kurve enthält die neue einzelne XP-Tabelle; alte Exponenten unter Allgemein sind historisch.','Neue Kistenpreise und Drill-Level-Rechnungen stehen unter Tabellen.','Neue Vorgänger-Kaufregeln, Offline-Cash und Prestige-Reset benötigen spätere Spielumsetzung.','Prestige: Pickaxes und Backpacks bleiben sofort nutzbar; Fahrzeuge und Luck werden zurückgesetzt.','Offline: 30 % installierter Firmenleistung, acht Stunden Limit, ohne zusätzliche Materialien oder XP.','Sonderfunde: feste tierbezogene Preise; keine garantierte Fundzeit; nur manuelles Mining.','Lastzüge sind im Zukunftsmodell enthalten. Die derzeitige Kaufsperre wird dadurch nicht aufgehoben.','Modellannahmen beschreibt Wege, Kaufstrategie und Grenzen. Kauf- und Verkaufslog zeigt reale Modellereignisse.','Studio-Test: frisches Profil; erste Verkäufe/Upgrades messen; 15-min-Puffer; Offline/Prestige prüfen.'];
guideLines[0]=`Balancing – neuer Vorschlag vom ${dateLabel}`;
guideLines[13]='Die Referenz nutzt vier kaufbare Fahrzeuge. Die Läufe mit Lastzügen stehen separat im Ergebnis.';
guideLines.forEach((x,i)=>put('Anleitung',`B${i+1}`,x));guide.getRange('B:B').format.columnWidth=125;guide.getRange('B1:B16').format.font={name:'Arial',size:11,color:ink};guide.getRange('B1').format.font={name:'Arial',size:16,bold:true,color:ink};guide.getRange('B1:B16').format.wrapText=true;guide.getRange('B1:B16').format.autofitRows();
for(const [s,newStart,newEnd]of [['Bauschritte','J','K'],['Erze & Barren','K','L'],['Minen','I','J']]){const sh=get(s);sh.getRange(`${newStart}:${newEnd}`).format.columnWidth=24;sh.getRange(`${newStart}1:${newEnd}1`).format={fill:navy,font:{name:'Arial',size:10,color:'#FFFFFF',bold:true},wrapText:true};sh.getRange(`A1:${newEnd}1`).format.rowHeight=40;}
for(const s of ['Spitzhacken','Rucksäcke','Drills','Fahrzeuge']){get(s).getRange('C:C').format.columnWidth=14;get(s).getRange('A:A').format.columnWidth=35;get(s).getRange('A1:R1').format.rowHeight=40;}
for(const [s,a,f]of [['Spitzhacken','H2:J26','#,##0'],['Spitzhacken','K2:K26','0.000'],['Spitzhacken','M2:M26','0.000'],['Rucksäcke','H2:K23','#,##0'],['Drills','I2:N31','#,##0'],['Drills','O2:P31','#,##0.0'],['Drills','Q2:Q31','0.0'],['Fahrzeuge','J2:M7','#,##0'],['Fahrzeuge','N2:N7','0.00'],['Elevator-Stufen','F2:J11','#,##0'],['Erze & Barren','H2:I75','#,##0.00'],['Erze & Barren','K2:L75','#,##0.00'],['Minen','F2:G101','#,##0'],['Minen','I2:J101','#,##0'],['Bauschritte','G2:H12','#,##0'],['Bauschritte','J2:K12','#,##0'],['Level-Kurve','D2:D121','0.0']])get(s).getRange(a).setNumberFormat(f);
put('Erze & Barren','A77','Neue Einzelwerte sind Vorschläge. Alte Istwerte bleiben erhalten; Vorschauen in K/L.');
put('Minen','A103','Neue Preise in G ohne zusätzlichen Spätspiel-Aufschlag; Vorschauen I/J.');
put('Fahrzeuge','A9','Lastzüge: im Modell enthalten, im Spiel weiterhin bis zum Fahrtest gesperrt; Prestige-Reset vorgeschlagen.');

wb.recalculate();
const initialPower=get('Spitzhacken').getRange('J2').values[0][0];
const initialRate=get('Spitzhacken').getRange('M2').values[0][0];
const initialAutonomy=get('Kapazitätsvorschau').getRange('H2').values[0][0];
put('Spitzhacken','J2',initialPower*2);wb.recalculate();
if(Math.abs(get('Spitzhacken').getRange('M2').values[0][0]-initialRate*2)>1e-8)throw new Error('Leistungsvorschau reagiert nicht auf Änderung');
if(Math.abs(get('Kapazitätsvorschau').getRange('H2').values[0][0]-initialAutonomy/2)>1e-8)throw new Error('Kapazitätsvorschau reagiert nicht auf Änderung');
const driftRow=inputPairs.findIndex(x=>x[0]==='Spitzhacken'&&x[1]==='J2')+2;
if(get('Prüfungen').getRange(`E${driftRow}`).values[0][0]!==initialPower)throw new Error('Änderung zum Simulationsstand wird nicht erkannt');
put('Spitzhacken','J2',initialPower);wb.recalculate();
const inputDrift=get('Prüfungen').getRange(`E2:E${inputPairs.length+1}`).values.flat().filter(x=>x!==0);
if(inputDrift.length)throw new Error(`Unerwartete Abweichungen zum Simulationsstand: ${inputDrift.slice(0,8)}`);
console.log('INPUT_CHANGE_TEST_PASSED',JSON.stringify({initialRate,initialAutonomy,restored:true,inputDrift:inputDrift.length}));
console.log((await wb.inspect({kind:'table',range:"'Ergebnis'!A7:D14",include:'values,formulas',tableMaxRows:8,tableMaxCols:4,maxChars:3000})).ndjson);
const errors=await wb.inspect({kind:'match',searchTerm:'#REF!|#DIV/0!|#VALUE!|#NAME\\?|#N/A|#NUM!|#NULL!|#SPILL!|#CALC!',options:{useRegex:true,maxResults:40},summary:'final formula error scan',maxChars:3500});console.log(errors.ndjson);
await fs.writeFile(path.join(out,'formula-scan.json'),errors.ndjson);
const renderSheets=process.argv.includes('--review-update')?['Ergebnis','Fahrzeuge','Rezepte neu','Level-Kurve','Belastungstest']:['Ergebnis','Anleitung','Allgemein','Bauschritte','Spitzhacken','Rucksäcke','Drills','Fahrzeuge','Elevator-Stufen','Erze & Barren','Minen','Level-Kurve','Tabellen','Rezepte neu','Modellannahmen','Simulationsläufe','Levelstände','Kauf- und Verkaufslog','Upgrade-Stufen','Sonderfunde','Fundwahrscheinlichkeiten','Kapazitätsvorschau','Belastungstest','Prüfungen'];
for(const s of renderSheets){
  const range=s==='Ergebnis'?`A1:O${noteStart+notes.length}`:s==='Anleitung'?'B1:B16':s==='Modellannahmen'?'A1:C13':s==='Allgemein'?'A1:I12':s==='Kauf- und Verkaufslog'?'A1:L12':s==='Levelstände'?'A1:J10':s==='Simulationsläufe'?'A1:H12':s==='Fundwahrscheinlichkeiten'?'A1:F10':s==='Sonderfunde'?'A1:I9':s==='Rezepte neu'?'A1:I9':s==='Upgrade-Stufen'?'A1:G10':s==='Kapazitätsvorschau'?'A1:J10':s==='Prüfungen'?'A1:E10':s==='Spitzhacken'?'A1:N8':s==='Drills'?'A1:R8':s==='Fahrzeuge'?'A1:P9':s==='Rucksäcke'?'A1:L8':s==='Elevator-Stufen'?'A1:K9':s==='Erze & Barren'?'A1:L9':s==='Minen'?'A1:J10':s==='Tabellen'?'A1:J12':s==='Level-Kurve'?'A1:D12':'A1:K12';
  const blob=await wb.render({sheetName:s,range:s==='Belastungstest'?'A1:C16':range,scale:1,format:'png'});await fs.writeFile(path.join(out,`preview-${s.replaceAll('/','_')}.png`),new Uint8Array(await blob.arrayBuffer()));
}
const exported=await SpreadsheetFile.exportXlsx(wb);await exported.save(path.join(out,'Balancing_Neuentwurf.xlsx'));
await fs.writeFile(path.join(out,'build-metadata.json'),JSON.stringify({inputs:inputPairs.length,simulations:runs.length,eventRows:evs.length,snapshotRows:snapshots.length,sheets:24,baseline_active_hours:baseline.active_minutes/60},null,2));
console.log('EXPORTED',path.join(out,'Balancing_Neuentwurf.xlsx'));
