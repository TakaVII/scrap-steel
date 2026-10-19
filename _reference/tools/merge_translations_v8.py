#!/usr/bin/env python3
"""Repairs Data/translations.csv and adds every key used by update v8 (en, es, ar).

Run from the repo root:   python3 _reference/tools/merge_translations_v8.py

What it does
  1. drops '#' comment lines (Godot's importer takes line 1 as the header "keys,en,es,ar")
  2. replaces/adds every key in KEYS below (this also fixes rows that were cut at an unquoted comma)
  3. drops keys that the old tutorial used and nothing uses anymore (DEPRECATED)
  4. refuses to write if any OTHER row still does not have exactly 4 columns, and lists them
  5. writes with proper quoting; then reimport the CSV in Godot (select it > Import dock > Reimport)

es/ar are machine-translated: keep that disclosure on the itch page and have a native speaker
check the tutorial and HUD strings first.
"""
import csv
import sys

PATH = "Data/translations.csv"

DEPRECATED = {
    "TUTORIAL_BEAT_0_TEXT", "TUTORIAL_BEAT_0_CALLOUT", "TUTORIAL_BEAT_1_TEXT",
    "TUTORIAL_BEAT_1_HUD_HINT", "TUTORIAL_BEAT_2_SELECT", "TUTORIAL_BEAT_2_HINT",
    "TUTORIAL_CONTINUE", "TUTORIAL_PICK_PATHWAY",
}

KEYS = {
    # ---- fixes carried over from fix_translations.py ----
    "CLIENT_BORIS_GREET": ["Heavy steel, heavy work. Don't cut corners.", "Acero pesado, trabajo duro. No recortes gastos.", "حديد ثقيل وعمل جاد. لا تختصر."],
    "CLIENT_BORIS_SATISFIED": ["Solid weld. You earned your fee, mechanic.", "Soldadura sólida. Te ganaste la paga, mecánico.", "لحام متين. استحققت أجرك يا ميكانيكي."],
    "SETTINGS_PRESET_STANDARD": ["Standard Preset (10k Debt, 2% Int)", "Estándar (Deuda 10k, 2% Int)", "النمط القياسي (دين 10 آلاف، فائدة 2%)"],
    "SETTINGS_PRESET_ASSIST": ["Assist Preset (7k Debt, 1% Int)", "Modo Asistido (Deuda 7k, 1% Int)", "نمط المساعدة (دين 7 آلاف، فائدة 1%)"],
    "SETTINGS_SLOW_MODE": ["Slow Mode (0.75x Speed, 1.25x Windows)", "Modo Lento (0.75x Vel, 1.25x Margen)", "الوضع البطيء (سرعة 0.75، نافذة 1.25)"],
    "NIGHT_FEEDBACK_INTEREST": ["Syndicate interest cost you %d cr today. Keep paying down the principal.", "El interés del sindicato te costó %d cr hoy. Sigue amortizando el capital.", "كلفتك فائدة النقابة %d رصيد اليوم. استمر في سداد أصل الدين."],
    "NIGHT_RENT": ["Shop Lease & Overtime", "Alquiler y Horas Extra", "الإيجار والعمل الإضافي"],
    "LEDGER_LATE_PENALTY": ["Late delivery penalty", "Penalización por entrega tardía", "غرامة التأخير في التسليم"],
    "WORKSHOP_NO_AP": ["Not enough AP for this part.", "No hay PA suficientes para esta pieza.", "لا توجد نقاط عمل كافية لهذه القطعة."],
    "WORKSHOP_NO_FUNDS": ["Not enough credits for the materials.", "No hay créditos para los materiales.", "لا يوجد رصيد كاف للمواد."],
    "WORKSHOP_NO_BUDGET": ["Materials would exceed the client budget cap.", "Los materiales superarían el límite del cliente.", "المواد ستتجاوز حد ميزانية العميل."],
    "WORKSHOP_REFORGE_BTN": ["Re-forge", "Reforjar", "إعادة التشكيل"],
    "WORKSHOP_NO_JOBS": ["No active contracts. Accept offers in the morning.", "Sin contratos activos. Acepta ofertas por la mañana.", "لا توجد عقود نشطة. اقبل العروض في الصباح."],
    "WORKSHOP_LAUNCH_FAILED": ["Could not start the minigame.", "No se pudo iniciar el minijuego.", "تعذر بدء اللعبة المصغرة."],
    "MORNING_HINT": ["Pick a contract, then open the workshop.", "Elige un contrato y abre el taller.", "اختر عقداً ثم افتح الورشة."],
    "MORNING_MAX_JOBS": ["Workshop full. Finish a job first.", "Taller lleno. Termina un trabajo primero.", "الورشة ممتلئة. أنهِ مهمة أولاً."],
    "MORNING_NEGOTIATIONS_USED": ["No negotiations left today.", "No quedan negociaciones hoy.", "لا مفاوضات متبقية اليوم."],

    # ---- morning screen / offers ----
    "MORNING_OFFERS": ["Offers", "Ofertas", "العروض"],
    "MORNING_JOBS": ["Jobs", "Trabajos", "المهام"],
    "MORNING_DETAILS": ["Details", "Detalles", "التفاصيل"],
    "MORNING_NO_OFFERS": ["No offers left today.", "No quedan ofertas hoy.", "لا عروض متبقية اليوم."],
    "OFFER_PAY": ["Pay", "Pago", "الأجر"],
    "OFFER_WORK": ["Work", "Trabajo", "العمل"],
    "OFFER_DEADLINE": ["Deadline", "Plazo", "الموعد"],
    "OFFER_MARGIN": ["Est. margin", "Margen est.", "الهامش المقدر"],
    "OFFER_PER_AP": ["Pay per AP", "Pago por PA", "الأجر لكل نقطة"],
    "OFFER_POWER": ["Power limit", "Límite de energía", "حد الطاقة"],
    "OFFER_BUDGET": ["Material budget", "Presupuesto de material", "ميزانية المواد"],
    "BTN_ACCEPT": ["Accept", "Aceptar", "قبول"],
    "BTN_BARTER": ["Barter", "Negociar", "مساومة"],
    "TYPE_CAR": ["Drift car", "Coche drift", "سيارة درفت"],
    "TYPE_MECH": ["Mech", "Mech", "آلي"],
    "TYPE_CYBER": ["Cyberware", "Ciberware", "سيبروير"],

    # ---- HUD / ledger / minigames ----
    "HUD_PER_DAY": ["/day", "/día", "/يوم"],
    "HUD_TIP_DEBT": ["Interest adds {interest} to your debt every night.", "El interés suma {interest} a tu deuda cada noche.", "تضيف الفائدة {interest} إلى دينك كل ليلة."],
    "LEDGER_F_ALL": ["All", "Todo", "الكل"],
    "LEDGER_F_INCOME": ["Income", "Ingresos", "الإيرادات"],
    "LEDGER_F_MATERIALS": ["Materials", "Materiales", "المواد"],
    "LEDGER_F_RENT": ["Rent", "Alquiler", "الإيجار"],
    "LEDGER_F_FINES": ["Fines", "Multas", "الغرامات"],
    "LEDGER_F_DEBT": ["Debt", "Deuda", "الدين"],
    "MINIGAME_ASSEMBLER_HAZARDS": ["Hazards", "Peligros", "المخاطر"],
    "MINIGAME_ASSEMBLER_NODES": ["Nodes", "Nodos", "العقد"],
    "MINIGAME_ASSEMBLER_NEED_NODES": ["Connect every node first.", "Conecta todos los nodos primero.", "صِل كل العقد أولاً."],
    "MINIGAME_FORGE_STRIKE_COUNT": ["Strike {n} / {total}", "Golpe {n} / {total}", "ضربة {n} / {total}"],

    # ---- tutorial / dialogue UI ----
    "DIALOGUE_CONTINUE": ["Click or Space", "Clic o Espacio", "انقر أو مسافة"],
    "TUT_SKIP": ["Skip tutorial", "Saltar tutorial", "تخطي الشرح"],
    "TUT_CHOOSE": ["Choose your road", "Elige tu camino", "اختر طريقك"],
    "PATH_REP_DESC": ["50% cyberware jobs. Win on Day 30: no debt, {reserve} in cash and a 5-star shop rating ({quality}%+ quality).", "50% trabajos de ciberware. Gana el Día 30: sin deuda, {reserve} en caja y 5 estrellas ({quality}%+ de calidad).", "50% وظائف سيبروير. الفوز في اليوم 30: بلا دين و{reserve} نقداً وتقييم 5 نجوم (جودة {quality}%+)."],
    "PATH_MECH_DESC": ["50% mech jobs. Win on Day 30: no debt and the Champion Build done (Day {unlock}-{deadline}, quality {quality}%+, {fee} entry fee).", "50% trabajos de mech. Gana el Día 30: sin deuda y el Montaje Campeón hecho (Día {unlock}-{deadline}, calidad {quality}%+, inscripción {fee}).", "50% وظائف آليات. الفوز في اليوم 30: بلا دين وإنجاز تجميعة البطل (اليوم {unlock}-{deadline}، جودة {quality}%+، رسوم {fee})."],
    "PATH_DRIFT_DESC": ["50% car jobs. Win on Day 30: no debt and the Champion Build done (Day {unlock}-{deadline}, quality {quality}%+, {fee} entry fee).", "50% trabajos de coches. Gana el Día 30: sin deuda y el Montaje Campeón hecho (Día {unlock}-{deadline}, calidad {quality}%+, inscripción {fee}).", "50% وظائف السيارات. الفوز في اليوم 30: بلا دين وإنجاز تجميعة البطل (اليوم {unlock}-{deadline}، جودة {quality}%+، رسوم {fee})."],

    # ---- clients (new client #12) ----
    "CLIENT_JUNO_GREET": ["Fixers talk. They say you do clean work.", "Los intermediarios hablan. Dicen que trabajas limpio.", "الوسطاء يتحدثون. يقولون إنك تعمل بنظافة."],
    "CLIENT_JUNO_SATISFIED": ["Smooth install. I will send friends.", "Instalación fina. Mandaré amigos.", "تركيب سلس. سأرسل أصدقاء."],
    "CLIENT_JUNO_UNHAPPY": ["Glitchy and slow. Not what I paid for.", "Falla y va lento. No es lo que pagué.", "متعثر وبطيء. ليس ما دفعت ثمنه."],

    # ---- prologue ----
    "TUT_P1": ["Astra City. Neon rain on cold steel. And a garage that is now yours.", "Astra City. Lluvia de neón sobre acero frío. Y un taller que ahora es tuyo.", "مدينة أسترا. مطر النيون فوق الفولاذ البارد. وورشة أصبحت لك الآن."],
    "TUT_P2": ["Your friend Dax built Scrap & Steel by hand. Then he vanished. He left only a note.", "Tu amigo Dax levantó Scrap & Steel con sus manos. Luego desapareció. Solo dejó una nota.", "بنى صديقك داكس ورشة الخردة والصلب بيديه. ثم اختفى. ولم يترك سوى ملاحظة."],
    "TUT_P3": ["'Fix what they bring you. Never miss a payment. Sorry, kid. - Dax'", "'Arregla lo que te traigan. Nunca faltes a un pago. Perdona, chaval. - Dax'", "'أصلح ما يحضرونه لك. لا تتأخر عن أي دفعة. آسف يا فتى. - داكس'"],
    "TUT_P4": ["The bench still works. Let's see if you do.", "El banco aún funciona. Veamos si tú también.", "طاولة العمل ما زالت تعمل. لنرَ إن كنت تعمل أنت أيضاً."],

    # ---- guided first job ----
    "TUT_J1": ["You must be Dax's friend. Forge me this bracket. First one is a favor. After that, I pay.", "Debes ser amigo de Dax. Forja este soporte. El primero es un favor. Luego, yo pago.", "لا بد أنك صديق داكس. اصنع لي هذا الحامل. الأول معروف. بعده سأدفع."],
    "TUT_J2": ["Press Space or click to strike when the cursor is inside the glowing zone.", "Pulsa Espacio o haz clic para golpear cuando el cursor esté en la zona brillante.", "اضغط مسافة أو انقر للضرب عندما يكون المؤشر داخل المنطقة المضيئة."],
    "TUT_J3": ["Every clean strike shrinks the zone. Center hits score best.", "Cada golpe limpio reduce la zona. Los golpes al centro puntúan más.", "كل ضربة نظيفة تصغّر المنطقة. الضربات في المركز تعطي أعلى نتيجة."],
    "TUT_J4G": ["Clean work. Dax would be grinning.", "Trabajo limpio. Dax estaría sonriendo.", "عمل نظيف. كان داكس سيبتسم."],
    "TUT_J4O": ["Rough, but it holds. You will improve.", "Tosco, pero aguanta. Mejorarás.", "خشن لكنه متين. ستتحسن."],
    "TUT_J4L": ["Hm. It will hold. Barely. Keep practicing.", "Hm. Aguantará. Por poco. Sigue practicando.", "همم. سيصمد بالكاد. واصل التدرب."],
    "TUT_J5": ["That is the loop: spend Action Points (AP) on parts, hit the marks, get paid. Better quality pays more.", "Ese es el ciclo: gasta Puntos de Acción (PA) en piezas, acierta las marcas y cobra. Más calidad, más pago.", "هذه هي الحلقة: أنفق نقاط العمل على القطع، أصب الأهداف، واقبض. الجودة الأعلى تدفع أكثر."],

    # ---- Kane meeting ----
    "TUT_K1": ["The door slams. A tall man in a gray coat shakes the rain off his sleeves.", "La puerta se cierra de golpe. Un hombre alto con abrigo gris sacude la lluvia de sus mangas.", "ينغلق الباب بعنف. رجل طويل بمعطف رمادي ينفض المطر عن كميه."],
    "TUT_K2": ["Collector Kane. Scraphound Syndicate. Dax borrowed. Dax ran. Now it is your problem.", "Cobrador Kane. Sindicato Scraphound. Dax pidió prestado. Dax huyó. Ahora es tu problema.", "المحصّل كين. نقابة سكرابهاوند. داكس اقترض. داكس هرب. والآن المشكلة مشكلتك."],
    "TUT_K3": ["Your debt is {debt}. Look at the top bar. That number never sleeps.", "Tu deuda es {debt}. Mira la barra superior. Ese número nunca duerme.", "دينك {debt}. انظر إلى الشريط العلوي. هذا الرقم لا ينام أبداً."],
    "TUT_K4": ["Interest: {rate}% a day. Tonight alone that adds {interest}.", "Interés: {rate}% al día. Solo esta noche suma {interest}.", "الفائدة: {rate}% يومياً. هذه الليلة وحدها تضيف {interest}."],
    "TUT_K5": ["First installment: {due} on Day {due_day}. Pay in full or take a strike.", "Primera cuota: {due} el Día {due_day}. Págala completa o recibes una falta.", "القسط الأول: {due} في اليوم {due_day}. ادفعه كاملاً أو تنل إنذاراً."],
    "TUT_K6": ["Three strikes, or debt above {limit}, and the garage is ours.", "Tres faltas, o una deuda superior a {limit}, y el taller es nuestro.", "ثلاثة إنذارات، أو دين فوق {limit}، وتصبح الورشة لنا."],
    "TUT_K7": ["Rent is {rent} every morning. Money in, money out. Press L any time to see the ledger.", "El alquiler es {rent} cada mañana. Entra dinero, sale dinero. Pulsa L para ver el libro mayor.", "الإيجار {rent} كل صباح. مال يدخل ومال يخرج. اضغط L لرؤية دفتر الحسابات."],
    "TUT_K8": ["Choose your road, mechanic. The city pays for what it respects.", "Elige tu camino, mecánico. La ciudad paga por lo que respeta.", "اختر طريقك أيها الميكانيكي. المدينة تدفع مقابل ما تحترمه."],
    "TUT_PATH_REP": ["Cyberware and a spotless name. Reputation pays slowly, but it pays.", "Ciberware y un nombre impecable. La reputación paga despacio, pero paga.", "سيبروير وسمعة نظيفة. السمعة تدفع ببطء لكنها تدفع."],
    "TUT_PATH_MECH": ["Mechs. Heavy iron, heavy money. Do not drop the hammer.", "Mechs. Hierro pesado, dinero pesado. No sueltes el martillo.", "آليات. حديد ثقيل ومال ثقيل. لا تُسقط المطرقة."],
    "TUT_PATH_DRIFT": ["Drift cars. Precision or nothing. Do not spin out.", "Coches de drift. Precisión o nada. No derrapes mal.", "سيارات الدرفت. الدقة أو لا شيء. لا تفقد السيطرة."],

    # ---- story beats ----
    "TIP_D1_1": ["Morning briefing. Pick a contract on the left and read its details.", "Informe matutino. Elige un contrato a la izquierda y lee sus detalles.", "التقرير الصباحي. اختر عقداً من اليسار واقرأ تفاصيله."],
    "TIP_D1_2": ["Check the pay, the AP it needs and the deadline. Then open the workshop.", "Revisa el pago, los PA necesarios y el plazo. Luego abre el taller.", "راجع الأجر ونقاط العمل المطلوبة والموعد. ثم افتح الورشة."],
    "TIP_FIRST": ["Your first payout. Every credit in and out is in the Ledger. Press L.", "Tu primer pago. Cada crédito que entra y sale está en el libro mayor. Pulsa L.", "أول دفعة لك. كل رصيد يدخل ويخرج في دفتر الحسابات. اضغط L."],
    "DAX_1": ["Under the bench, a greasy note: 'Interest never sleeps. Pay the big debt first.' - D", "Bajo el banco, una nota grasienta: 'El interés nunca duerme. Paga primero la deuda grande.' - D", "تحت الطاولة ملاحظة ملطخة بالشحم: 'الفائدة لا تنام. سدّد الدين الكبير أولاً.' - د"],
    "DAX_2": ["A cracked photo of Dax with a kid in a racing jacket. On the back: 'Sorry I ran.'", "Una foto rota de Dax con un chico con chaqueta de carreras. Detrás: 'Perdón por huir.'", "صورة متشققة لداكس مع فتى بسترة سباق. على ظهرها: 'آسف لأني هربت.'"],
    "DAX_3": ["Dax's last note, taped inside the old radio: 'If you read this, you beat me. Finish it.'", "La última nota de Dax, pegada en la vieja radio: 'Si lees esto, me superaste. Termínalo.'", "آخر ملاحظة لداكس داخل الراديو القديم: 'إن قرأت هذا فقد تفوقت علي. أنهِ الأمر.'"],
    "INST_OK": ["Paid in full. Adequate.", "Pagado por completo. Aceptable.", "مدفوع بالكامل. مقبول."],
    "INST_SHORT": ["Short. That is strike {strikes} of {max_strikes}. Do not make it a habit.", "Insuficiente. Es la falta {strikes} de {max_strikes}. No lo conviertas en costumbre.", "ناقص. هذا الإنذار {strikes} من {max_strikes}. لا تجعلها عادة."],
    "CH1_DONE": ["Chapter 1 complete. The real climb starts now.", "Capítulo 1 completo. La verdadera escalada empieza ahora.", "انتهى الفصل الأول. الصعود الحقيقي يبدأ الآن."],
    "PERSONAL": ["It is personal now. The Syndicate wants its money. And your garage.", "Ahora es personal. El sindicato quiere su dinero. Y tu taller.", "أصبح الأمر شخصياً. النقابة تريد مالها. وتريد ورشتك."],
    "D12_COMMON": ["To win on Day 30: clear all your debt and complete your goal.", "Para ganar el Día 30: salda toda tu deuda y cumple tu meta.", "للفوز في اليوم 30: سدّد كل ديونك وحقق هدفك."],
    "D12_REP": ["Astra's elite watch the best shops. Hold {reserve} in cash and a 5-star rating.", "La élite de Astra vigila los mejores talleres. Ten {reserve} en caja y 5 estrellas.", "نخبة أسترا تراقب أفضل الورش. احتفظ بـ {reserve} نقداً وتقييم 5 نجوم."],
    "D12_MECH": ["The Steel Colosseum wants a Champion Build. About {cost} in parts, {fee} to enter. Done by Day {deadline}.", "El Coliseo de Acero quiere un Montaje Campeón. Unos {cost} en piezas y {fee} de inscripción. Para el Día {deadline}.", "ساحة الفولاذ تريد تجميعة البطل. نحو {cost} للقطع و{fee} للتسجيل. قبل اليوم {deadline}."],
    "D12_DRIFT": ["The Neon Circuit wants a Champion Build. About {cost} in parts, {fee} to enter. Done by Day {deadline}.", "El Circuito Neón quiere un Montaje Campeón. Unos {cost} en piezas y {fee} de inscripción. Para el Día {deadline}.", "حلبة النيون تريد تجميعة البطل. نحو {cost} للقطع و{fee} للتسجيل. قبل اليوم {deadline}."],
}


def main() -> int:
    with open(PATH, encoding="utf-8-sig", newline="") as f:
        lines = [l for l in f.read().splitlines() if l.strip() and not l.lstrip().startswith("#")]

    rows, bad, seen = [], [], set()
    for line in lines:
        key = line.split(",", 1)[0].strip()
        if key == "keys":
            continue  # header is re-added below
        if key in DEPRECATED:
            continue
        if key in KEYS:
            row = [key] + KEYS[key]
        else:
            row = next(csv.reader([line]))
            if len(row) != 4:
                bad.append((key, len(row)))
        seen.add(key)
        rows.append(row)

    for key, vals in KEYS.items():
        if key not in seen:
            rows.append([key] + vals)

    if bad:
        print("NOT WRITTEN. These rows do not have exactly 4 columns (an unquoted comma inside the text).")
        print("Wrap the text of every language in double quotes, or paste the rows to Claude:")
        for key, n in bad:
            print(f"  {key}: {n} columns")
        return 1

    rows.insert(0, ["keys", "en", "es", "ar"])
    with open(PATH, "w", encoding="utf-8", newline="") as f:
        csv.writer(f, lineterminator="\n").writerows(rows)
    print(f"OK: {len(rows) - 1} keys written to {PATH}. Now reimport it in Godot.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
