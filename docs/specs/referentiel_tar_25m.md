# Référentiel TAR 25 m — épreuves armes de poing (seed NT-100)

> Données extraites du **Règlement TAR FFTir saison 2025-2026** (CNS TAR,
> validé Comité Directeur FFTir du 06/12/2025, diffusion du 12/01/2026) :
> https://www.fftir.org/wp-content/uploads/2026/01/CNS-TAR-Reglement-TAR-2025-2026-Diffusion-20260112.pdf
>
> ⚠️ Le règlement évolue **chaque saison** (ex. 2025-2026 : gong ramené à
> 5 pts pour les armes de poing). Le référentiel embarqué doit être versionné
> par saison (`saison` obligatoire). Ce fichier est le seed de l'asset
> `disciplines_tar.yaml` (NT-100).

## Seed YAML

```yaml
referentiel:
  source: "Règlement TAR FFTir 2025-2026"
  saison: "2025-2026"
  version_doc: "2026-01-12"

epreuves:
  - code: "830"
    nom: "Pistolet / Revolver — armes récentes"
    distance_m: 25
    position: debout
    coups_total: 35
    coups_par_chargeur: 5
    score_max: 200
    contraintes_arme:
      calibre_mm: [7.62, 11.60]
      visee: "fixe et ouverte"
      detente_min_kg: 1.360
      canon_max_cm: {pistolet: 13, revolver: 15.5}
    sequences:
      - {type: essai,     cible: C50,  coups: 5,  tenue: "1 ou 2 mains", temps: "3 min"}
      - {type: precision, cible: C50,  coups: 10, tenue: "1 main bras franc", temps: "7 min", series: "2x5"}
      - {type: vitesse,   cible: gong, coups: 10, tenue: "1 ou 2 mains", temps: "2 x 20 s", series: "2x5"}
      - {type: vitesse,   cible: gong, coups: 10, tenue: "1 ou 2 mains", temps: "2 x 10 s", series: "2x5"}
    scoring: {precision: "pts/zone ISSF", gong_tombe_pts: 5}

  - code: "832"
    nom: "Pistolet / Revolver — armes authentiques"
    identique_a: "830"   # même format ; seule la liste d'armes change (annexe A-832)

  - code: "831"
    nom: "Vitesse réglementaire"
    distance_m: 25
    position: debout
    coups_total: 25
    coups_par_chargeur: 5
    score_max: 200
    sequences:
      - {type: essai,   cible: cible_vitesse_25m, coups: 5,  tenue: "1 ou 2 mains", temps: "20 s"}
      - {type: vitesse, cible: cible_vitesse_25m, coups: 10, tenue: "1 ou 2 mains", temps: "2 x 20 s", series: "2x5"}
      - {type: vitesse, cible: cible_vitesse_25m, coups: 10, tenue: "1 ou 2 mains", temps: "2 x 10 s", series: "2x5"}
    scoring: {tout: "pts/zone"}

cibles:
  C50:
    format_mm: [550, 520]
    zones_diametre_mm:   # diamètres ; pas de zones 1-4 sur la C50
      mouche: 50
      "10": 100
      "9": 180
      "8": 260
      "7": 340
      "6": 420
      "5": 500
  cible_vitesse_25m:
    format_mm: [550, 520]
    zones_diametre_mm:
      mouche: 25
      "10": 50
      "9": 100
      "8": 150
      "7": 200
      "6": 250
      "5": 300
      "4": 350
      "3": 400
      "2": 450
      "1": 500
  gong:
    nombre: 5
    format_mm: [200, 200]
    espacement_bord_a_bord_cm: 20
    hauteur_centre_25m_m: 1.40   # ± 10 cm

regles_comptage:
  jauge: interdite
  hors_zone: "coup manqué (0)"
  cibles_par_match: 2            # essais bouchés, la 1re cible sert au match
  departage_egalite:             # ordre d'application
    - "meilleure série de 10 en vitesse, puis en précision"
    - "nombre de 10, puis de 9, de 8…"
    - "nombre de mouches"
  penalites:
    coup_en_trop: "annulé + -2 pts"
    coup_hors_temps: "compté 0, meilleur impact retiré, -2 pts (précision)"
  position_pret_vitesse: "bras abaissé à 45° max de la verticale"
```

## Notes de modélisation (impacts app)

- Le modèle `Series` actuel (coups, distance, points, groupement, prise) ne
  couvre pas : le **type de séquence** (essai / précision / vitesse — les
  essais ne comptent pas au score), le **temps imparti**, et le **scoring
  binaire sur gongs** (tombé / pas tombé). Ajouts **additifs** Hive uniquement
  (typeIds/index stables), cf. NT-101.
- Les diamètres de zones C50 sont l'entrée clé du prompt serveur pour
  l'analyse photo qualitative (NT-111) : ils permettent de traduire une
  observation visuelle en langage de score. Progression régulière des zones
  C50 : +80 mm par zone → estimation possible d'un score théorique depuis un
  groupement saisi manuellement, sans photo.
- Les **grilles de classement par niveau** (« barèmes » par catégorie) ne
  figurent pas dans le règlement TAR : elles relèvent du **RGS FFTir** —
  sourcing dédié requis pour NT-103.
- Les listes d'armes autorisées (annexes A-830 / A-832 du règlement) ne sont
  pas reprises ici ; à intégrer plus tard si l'app doit valider l'éligibilité
  d'une arme du carnet à une épreuve.
