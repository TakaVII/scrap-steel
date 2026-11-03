"""
Scrap & Steel - economy balance simulator v4 (Monte Carlo). Based on balance_sim.py.
v4 changes: part quality = QF[tier] + (1 - QF[tier]) * score (BalanceConfig.quality_floor_by_tier), payout x0.90 (PAYSCALE), champion quality gate CHAMP.
Set QF = {1:.5,2:.5,3:.5} to reproduce the old behaviour. Not modeled: material grades, daily market, new barter terms, minigame difficulty by grade.
Usage:  python3 balance_sim_v4.py
"""

import random, statistics as st, sys, json

# ---------------- PARAMETERS (tunable) ----------------
P = dict(
    start_credits=2000, start_debt=10000, interest=0.02, rent=150,
    max_ap=6, days=30, offers_per_day=4,
    rate={1:304,2:395.2,3:516.8},        # payout per AP by tier
    cost_frac=0.50,                  # nominal wholesale as fraction of payout
    budget_cap=0.65,
    ot_cost=150, ot_ap=2, ot_next_ap_pen=1,
    weekly_min=(400,0.08), strikes_max=3, due_days=(8,15,22,29), seize_debt=25000,
    final_cost=9000, rep_reserve=9000, rep_avg=0.80,
    late_fee=0.10,
    paths_weight=0.50,
)
UPG = { # name: (credits, tp)
 'supplier':(800,2),'tools':(1500,3),'bench':(2500,4),'insurance':(600,2),'rolodex':(1400,3)}
TYPES=['CAR','MECH','CYBER']
PARTS={'CAR':['calibrate','calibrate','assemble','forge'],
       'MECH':['calibrate','forge','forge','calibrate'],
       'CYBER':['forge','assemble','calibrate','assemble']}
AP={'forge':2,'calibrate':2,'assemble':1}

WATCH=True
QF={1:0.42,2:0.34,3:0.26}  # keep in sync with BalanceConfig.quality_floor_by_tier
STATS={'parts':0,'low60':0,'del':0,'low50':0,'qsum':0.0}
PAYSCALE=0.9
CHAMP=0.80

FORCE=[]
NORD=False
def RES(day,debt):
    if not WATCH: return 0
    ds=[d for d in P['due_days'] if d>day]
    if not ds: return 0
    nxt=min(ds)
    return (max(P['weekly_min'][0],P['weekly_min'][1]*debt)+P['rent']*2) if nxt-day<=2 else 0
def tier_for(day):
    r=random.random()
    if day<=7:  return 1 if r<.8 else 2
    if day<=16: return 1 if r<.3 else (2 if r<.85 else 3)
    return 1 if r<.1 else (2 if r<.5 else 3)

def mk_offer(day,path,rng_types):
    w={t:(1-P['paths_weight'])/2 for t in TYPES}
    if path: w[path]=P['paths_weight']
    t=random.choices(TYPES,[w[x] for x in TYPES])[0]
    n=2 if random.random()<.65 else 3
    parts=random.sample(PARTS[t],n)
    tier=tier_for(day)
    ap=sum(AP[p] for p in parts)
    payout=ap*P['rate'][tier]*PAYSCALE*random.uniform(.9,1.1)
    return dict(type=t,parts=parts,tier=tier,ap=ap,payout=payout,deadline=random.choice([2,2,3]),
                budget=payout*P['budget_cap'],mat=payout*P['cost_frac'])

def qual(s,tier):
    f=QF[tier]; return f+(1-f)*s
def score(skill,bonus):
    s=random.gauss(skill,0.13)+bonus
    return min(1,max(0,s))

def run(skill=.65,path='MECH',policy='balanced',seed=None,verbose=False):
    if seed is not None: random.seed(seed)
    cr=P['start_credits']; debt=P['start_debt']
    up=set(FORCE); tp=0; strikes=0
    active=[]; recent_q=[]; claims=[]
    final_done=False; final_started=0
    log=[]; debt_clear_day=None
    ap_next_pen=0; ot_used_last=False
    total_profit=0
    for day in range(1,P['days']+1):
        ap=P['max_ap']+(1 if 'bench' in up else 0)-ap_next_pen; ap_next_pen=0
        # warranty claims due
        for c in list(claims):
            if c[0]==day:
                cr-=c[1]; claims.remove(c)
        # morning: rent
        if cr>=P['rent']: cr-=P['rent']
        else:
            short=P['rent']-cr; cr=0; debt+=short*(1+P['late_fee'])
        # weekly syndicate installment (morning bills)
        if day in P['due_days']:
            mn=min(max(P['weekly_min'][0],P['weekly_min'][1]*debt),debt)
            paid=min(cr,mn); cr-=paid; debt-=paid
            if paid<mn-0.01:
                strikes+=1; debt+= (mn-paid)*P['late_fee']
        # offers
        n=P['offers_per_day']+(1 if 'rolodex' in up else 0)
        offers=[mk_offer(day,path if policy!='nopath' else None,None) for _ in range(n)]
        if 'rolodex' in up:
            for o in offers: o['payout']*=1.03
        # final build available from day 18
        if path in('MECH','CAR') and day>=18 and not final_done and final_started==0 and policy!='skipfinal':
            pass
        # choose jobs by profit per AP
        mat_mult=(0.90 if 'supplier' in up else 1.0)
        bonus=0.04 if 'tools' in up else 0
        def est(o):
            return (o['payout']-o['mat']*mat_mult*0.88)/o['ap']
        offers.sort(key=est,reverse=True)
        # accept
        for o in offers:
            if len(active)>=3: break
            # affordable?
            need=o['mat']*mat_mult
            sk=skill+bonus
            # barter policy
            o['barter']=None
            if cr<need*0.9 and True:
                o['barter']='deposit'
                cr+=0.2*o['payout']; o['payout']*=0.9
            elif sk>=.8 and random.random()<.7:
                o['barter']='profit'; o['budget']*=.85
            elif o['deadline']>=2 and random.random()<.15 and sk>.7:
                o['barter']='rush'; o['payout']*=1.25; o['deadline']=1
            if cr<need*0.9: continue
            o['accept_day']=day; o['done_parts']=0; o['scores']=[]; o['paid_mat']=False
            active.append(o)
        # work: allocate AP across active jobs (earliest deadline first)
        def work(ap):
            nonlocal cr
            active.sort(key=lambda o:o['accept_day']+o['deadline'])
            for o in active:
                while o['done_parts']<len(o['parts']):
                    p=o['parts'][o['done_parts']]
                    if ap<AP[p]: break
                    ap-=AP[p]
                    s=score(skill,bonus)
                    cost=o['mat']*mat_mult/len(o['parts'])
                    if p=='forge': cost*=(1-0.30*s)
                    if cost>cr: ap+=AP[p]; break
                    cr-=cost; o['scores'].append((p,s)); o['done_parts']+=1
            return ap
        ap=work(ap)
        # overtime if jobs pending, deadline pressure, and cash ok
        if ap==0 and policy!='noot' and any(o['done_parts']<len(o['parts']) for o in active) and cr>P['ot_cost']+200 and ap_next_pen==0:
            pend=[o for o in active if o['done_parts']<len(o['parts']) and o['accept_day']+o['deadline']<=day+1]
            if pend:
                cr-=P['ot_cost']; ap_next_pen=P['ot_next_ap_pen']
                ap=work(P['ot_ap'])
        # evening: deliver
        tp_gain=0
        for o in list(active):
            if o['done_parts']==len(o['parts']):
                qs=[qual(s,o['tier']) for _,s in o['scores']]
                for x in qs:
                    STATS['parts']+=1; STATS['low60']+= x<0.6
                q=st.mean(qs); STATS['del']+=1; STATS['low50']+= q<0.5; STATS['qsum']+=q
                pay=o['payout']
                if o['barter']=='profit':
                    pay*= 1.30 if q>=.9 else (0.90 if q<.75 else 1.0)
                if q<.5: pay*=.5; 
                elif q<.75: pay*=.85
                elif q>=.9: pay*=1.10
                # power draw penalty
                cs=[s for p,s in o['scores'] if p=='calibrate']
                if cs and min(cs)<random.uniform(.25,.65): pay*=.85
                late = day>o['accept_day']+o['deadline']
                if late: pay*=.8
                cr+=pay; total_profit+=pay
                # warranty
                ass=[s for p,s in o['scores'] if p=='assemble']
                durab=st.mean(ass) if ass else .8
                prob=max(0,(1-durab)*0.5)+(0.4 if q<.5 else 0)
                if random.random()<prob:
                    refund=0.35*pay*(0.5 if 'insurance' in up else 1)
                    claims.append((day+3,refund))
                tp_gain+= 2 if q>=.9 else (1 if q>=.75 else 0)
                recent_q.append(q); active.remove(o)
        # expired jobs
        for o in list(active):
            if day>o['accept_day']+o['deadline']+1: active.remove(o)
        tp+=tp_gain
        # night: interest then decisions
        if debt>0: debt*=1+P['interest']
        # policy: R&D
        order=['supplier','bench','tools','insurance','rolodex'] if policy!='debtfirst' else []
        if policy=='investfirst': order=['supplier','bench','tools','insurance','rolodex']
        for u in ([] if NORD else order):
            if u in up: continue
            c,t=UPG[u]
            lim = day<=18
            if lim and tp>=t and cr>=c+700+RES(day,debt):
                cr-=c; tp-=t; up.add(u)
        # repay debt policy
        buf=600 if policy!='debtfirst' else 200
        if WATCH:
            buf=max(buf,RES(day,debt))
        reserve=0
        if day>=14:
            if path=='CYBER': reserve=0
        if policy in('balanced','nopath','noot','skipfinal','investfirst','debtfirst','minonly'):
            if debt>0:
                pay=max(0,cr-buf)
                # balanced: keep savings for final once debt small
                pay=min(pay,debt)
                if policy=='investfirst': pay*=0.5
                if policy=='minonly': pay=0
                cr-=pay; debt-=pay
        if debt<=1 and debt_clear_day is None: debt=0; debt_clear_day=day
        # final objective
        if path in('MECH','CAR') and not final_done and debt==0 and day>=15 and day<=28 and cr>=P['final_cost']:
            # need AP: spend next day wholesale; model as final build with quality
            fq=st.mean([qual(score(skill,bonus),3) for _ in range(4)])
            if True:
                cr-=P['final_cost']; final_done = fq>=CHAMP
                if not final_done: cr+=0
                if final_done: log.append(('final',day,fq))
                else: pass
        if debt>=P['seize_debt'] or strikes>=P['strikes_max']:
            return dict(win=False,why='seized',day=day,cr=cr,debt=debt,clear=debt_clear_day,up=len(up))
    ok=False
    if path in('MECH','CAR'): ok = final_done and debt==0
    else: ok = debt==0 and cr>=P['rep_reserve'] and len(recent_q)>=8 and st.mean(recent_q[-8:])>=P['rep_avg']
    return dict(win=ok,why=None if ok else 'timeout',day=P['days'],cr=cr,debt=debt,clear=debt_clear_day,up=len(up),final=final_done)

def batch(skill,path,policy='balanced',n=600):
    rs=[run(skill,path,policy) for _ in range(n)]
    w=[r for r in rs if r['win']]
    clear=[r['clear'] for r in rs if r['clear']]
    return dict(win=len(w)/n,seized=sum(1 for r in rs if r.get('why')=='seized')/n,
        timeout=sum(1 for r in rs if r.get('why')=='timeout')/n,
        win_day=round(st.mean([r['day'] for r in w]),1) if w else None,
        clear_day=round(st.mean(clear),1) if clear else None, cleared=len(clear)/n,
        final_cash=round(st.mean([r['cr'] for r in rs])), upg=round(st.mean([r['up'] for r in rs]),1))

if __name__=='__main__':
    for path in ['MECH','CAR','CYBER']:
        for sk,name in [(.45,'novice'),(.60,'casual'),(.75,'good'),(.88,'expert')]:
            print(path,name,batch(sk,path))
