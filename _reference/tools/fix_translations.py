#!/usr/bin/env python3
"""Repairs Data/translations.csv for Godot's CSV importer.

Run from the repo root:  python3 _reference/tools/fix_translations.py
What it does:
  1. removes the '# Note' comment line (the importer treats line 1 as the header 'keys,en,es,ar')
  2. rewrites rows whose fields contain commas, with proper quoting
  3. fixes NIGHT_FEEDBACK_INTEREST (needs %d) and NIGHT_RENT (lease + overtime)
  4. appends the new keys used by the manual fixes
  5. refuses to write if any row still does not have exactly 4 columns
"""
import csv
import sys

PATH = "Data/translations.csv"

REPLACE = {
    "CLIENT_BORIS_GREET": ["Heavy steel, heavy work. Don't cut corners.", "Acero pesado, trabajo duro. No recortes gastos.", "حديد ثقيل وعمل جاد. لا تختصر."],
    "CLIENT_BORIS_SATISFIED": ["Solid weld. You earned your fee, mechanic.", "Soldadura sólida. Te ganaste la paga, mecánico.", "لحام متين. استحققت أجرك يا ميكانيكي."],
    "SETTINGS_PRESET_STANDARD": ["Standard Preset (10k Debt, 2% Int)", "Estándar (Deuda 10k, 2% Int)", "النمط القياسي (دين 10 آلاف، فائدة 2%)"],
    "SETTINGS_PRESET_ASSIST": ["Assist Preset (7k Debt, 1% Int)", "Modo Asistido (Deuda 7k, 1% Int)", "نمط المساعدة (دين 7 آلاف، فائدة 1%)"],
    "SETTINGS_SLOW_MODE": ["Slow Mode (0.75x Speed, 1.25x Windows)", "Modo Lento (0.75x Vel, 1.25x Margen)", "الوضع البطيء (سرعة 0.75، نافذة 1.25)"],
    "TUTORIAL_BEAT_1_TEXT": [
        "Collector Kane arrives: 'Your friend owed 10,000 cr. Pay 8% installments every 7 days or we seize the shop. Three strikes and you are out.'",
        "Llega el Cobrador Kane: 'Tu amigo debía 10.000 cr. Paga cuotas del 8% cada 7 días o embargamos el taller. Tres faltas y fuera.'",
        "وصل المحصل كين: 'كان صديقك مديناً بـ 10,000 رصيد. ادفع أقساط 8% كل أسبوع أو نصادر الورشة.'"],
    "NIGHT_FEEDBACK_INTEREST": ["Syndicate interest cost you %d cr today. Keep paying down the principal.", "El interés del sindicato te costó %d cr hoy. Sigue amortizando el capital.", "كلفتك فائدة النقابة %d رصيد اليوم. استمر في سداد أصل الدين."],
    "NIGHT_RENT": ["Shop Lease & Overtime", "Alquiler y Horas Extra", "الإيجار والعمل الإضافي"],
}

NEW = {
    "LEDGER_LATE_PENALTY": ["Late delivery penalty", "Penalización por entrega tardía", "غرامة التأخير في التسليم"],
    "WORKSHOP_NO_AP": ["Not enough AP for this part.", "No hay PA suficientes para esta pieza.", "لا توجد نقاط عمل كافية لهذه القطعة."],
    "WORKSHOP_NO_FUNDS": ["Not enough credits for the materials.", "No hay créditos para los materiales.", "لا يوجد رصيد كاف للمواد."],
    "WORKSHOP_NO_BUDGET": ["Materials would exceed the client budget cap.", "Los materiales superarían el límite del cliente.", "المواد ستتجاوز حد ميزانية العميل."],
    "WORKSHOP_REFORGE_BTN": ["Re-forge", "Reforjar", "إعادة التشكيل"],
    "WORKSHOP_NO_JOBS": ["No active contracts. Accept offers in the morning.", "Sin contratos activos. Acepta ofertas por la mañana.", "لا توجد عقود نشطة. اقبل العروض في الصباح."],
    "WORKSHOP_LAUNCH_FAILED": ["Could not start the minigame.", "No se pudo iniciar el minijuego.", "تعذر بدء اللعبة المصغرة."],
    "MORNING_HINT": ["Inspect and accept contracts before opening the workshop.", "Revisa y acepta contratos antes de abrir el taller.", "افحص العقود واقبلها قبل فتح الورشة."],
    "MORNING_MAX_JOBS": ["Workshop full. Finish a job first.", "Taller lleno. Termina un trabajo primero.", "الورشة ممتلئة. أنهِ مهمة أولاً."],
    "MORNING_NEGOTIATIONS_USED": ["No negotiations left today.", "No quedan negociaciones hoy.", "لا مفاوضات متبقية اليوم."],
}

def main() -> int:
    with open(PATH, encoding="utf-8", newline="") as f:
        lines = [l for l in f.read().splitlines() if l.strip() and not l.startswith("#")]
    rows, bad, seen = [], [], set()
    for line in lines:
        key = line.split(",", 1)[0]
        if key in REPLACE:
            row = [key] + REPLACE[key]
        else:
            row = next(csv.reader([line]))
        if len(row) != 4:
            bad.append((key, len(row)))
        seen.add(key)
        rows.append(row)
    for key, vals in NEW.items():
        if key not in seen:
            rows.append([key] + vals)
    if bad:
        print("NOT WRITTEN. Rows without exactly 4 columns (quote the commas):")
        for key, n in bad:
            print(f"  {key}: {n} columns")
        return 1
    with open(PATH, "w", encoding="utf-8", newline="") as f:
        csv.writer(f, lineterminator="\n").writerows(rows)
    print(f"OK: {len(rows)} rows written to {PATH}")
    return 0

if __name__ == "__main__":
    sys.exit(main())
